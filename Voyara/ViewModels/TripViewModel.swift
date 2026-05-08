import Foundation
import Combine
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class TripViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var userId: String?
    
    var upcomingTrips: [Trip] {
        trips.filter { $0.startDate > Date() }.sorted { $0.startDate < $1.startDate }
    }
    
    var pastTrips: [Trip] {
        trips.filter { $0.endDate <= Date() }.sorted { $0.startDate > $1.startDate }
    }
    
    var ongoingTrips: [Trip] {
        trips.filter { $0.status == .ongoing }
    }
    
    var activeTripCount: Int {
        trips.filter { $0.status == .ongoing }.count
    }
    
    var totalBudgetSpent: Decimal {
        trips.flatMap { $0.expenses }.reduce(0) { $0 + $1.amount }
    }
    
    var totalBudget: Decimal {
        trips.reduce(0) { $0 + $1.budget }
    }

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            if let user = user {
                self.userId = user.uid
                self.fetchTrips()
            } else {
                self.userId = nil
                self.trips = []
                self.listenerRegistration?.remove()
            }
        }
    }
    
    deinit {
        listenerRegistration?.remove()
    }

    // MARK: - Firebase Sync
    func fetchTrips() {
        guard let uid = userId else { return }
        
        listenerRegistration?.remove()
        listenerRegistration = db.collection("users").document(uid).collection("trips")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching trips: \(String(describing: error))")
                    return
                }
                
                let fetchedTrips = documents.compactMap { doc -> Trip? in
                    guard let data = try? JSONSerialization.data(withJSONObject: doc.data()) else { return nil }
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .millisecondsSince1970
                    return try? decoder.decode(Trip.self, from: data)
                }
                
                DispatchQueue.main.async {
                    self?.trips = fetchedTrips.sorted { $0.createdAt > $1.createdAt }
                    
                    if fetchedTrips.isEmpty {
                        self?.generateSampleDataToFirebase()
                    }
                }
            }
    }
    
    private func saveTripToFirebase(_ trip: Trip) {
        guard let uid = userId else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            let data = try encoder.encode(trip)
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                db.collection("users").document(uid).collection("trips").document(trip.id).setData(dict)
            }
        } catch {
            print("Error saving trip: \(error.localizedDescription)")
        }
    }

    // MARK: - Trip Management
    func createTrip(title: String, destination: String, destinations: [String] = [], startDate: Date, endDate: Date, budget: Decimal, purpose: String = "") {
        guard let uid = userId else { return }
        
        var newTrip = Trip(
            id: UUID().uuidString,
            userId: uid,
            title: title,
            description: purpose.isEmpty ? nil : purpose,
            destination: destination,
            destinations: destinations.isEmpty ? [destination] : destinations,
            startDate: startDate,
            endDate: endDate,
            budget: budget,
            currency: "USD",
            status: .planning,
            coverImageURL: nil,
            category: nil,
            itineraries: [],
            expenses: [],
            packingItems: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Generate itineraries
        let days = newTrip.durationDays
        for day in 0...max(days, 0) {
            let date = Calendar.current.date(byAdding: .day, value: day, to: newTrip.startDate) ?? Date()
            newTrip.itineraries.append(ItineraryDay(tripId: newTrip.id, dayNumber: day + 1, date: date))
        }
        
        // Generate packing list
        let essentials: [(String, String)] = [
            ("Passport & ID", "Documents"), ("Flight Tickets", "Documents"),
            ("T-shirts", "Clothing"), ("Pants/Shorts", "Clothing"),
            ("Toothbrush", "Toiletries"), ("Toothpaste", "Toiletries"),
            ("Phone Charger", "Electronics"), ("Power Bank", "Electronics"),
            ("Medications", "Other")
        ]
        
        for (name, category) in essentials {
            newTrip.packingItems.append(PackingItem(id: UUID().uuidString, tripId: newTrip.id, name: name, category: category, quantity: 1))
        }

        saveTripToFirebase(newTrip)
    }

    func updateTrip(_ trip: Trip) {
        saveTripToFirebase(trip)
    }

    func deleteTrip(_ trip: Trip) {
        guard let uid = userId else { return }
        db.collection("users").document(uid).collection("trips").document(trip.id).delete()
    }
    
    func changeTripsStatus(_ trip: Trip, to status: TripStatus) {
        var updatedTrip = trip
        updatedTrip.status = status
        saveTripToFirebase(updatedTrip)
    }

    // MARK: - Itinerary Management
    func itineraryDaysForTrip(_ trip: Trip) -> [ItineraryDay] {
        return trip.itineraries.sorted { $0.dayNumber < $1.dayNumber }
    }
    
    func addActivityToDay(_ activity: ItineraryActivity, dayId: String, trip: Trip) {
        var updatedTrip = trip
        if let index = updatedTrip.itineraries.firstIndex(where: { $0.id == dayId }) {
            updatedTrip.itineraries[index].activities.append(activity)
            saveTripToFirebase(updatedTrip)
        }
    }
    
    func deleteActivityFromDay(_ activity: ItineraryActivity, dayId: String, trip: Trip) {
        var updatedTrip = trip
        if let index = updatedTrip.itineraries.firstIndex(where: { $0.id == dayId }) {
            updatedTrip.itineraries[index].activities.removeAll { $0.id == activity.id }
            saveTripToFirebase(updatedTrip)
        }
    }
    
    func updateActivity(_ activity: ItineraryActivity, dayId: String, trip: Trip) {
        var updatedTrip = trip
        if let dayIndex = updatedTrip.itineraries.firstIndex(where: { $0.id == dayId }) {
            if let actIndex = updatedTrip.itineraries[dayIndex].activities.firstIndex(where: { $0.id == activity.id }) {
                updatedTrip.itineraries[dayIndex].activities[actIndex] = activity
                saveTripToFirebase(updatedTrip)
            }
        }
    }
    
    func toggleActivityCompletion(_ activity: ItineraryActivity, dayId: String, trip: Trip) {
        var updatedTrip = trip
        if let dayIndex = updatedTrip.itineraries.firstIndex(where: { $0.id == dayId }) {
            if let actIndex = updatedTrip.itineraries[dayIndex].activities.firstIndex(where: { $0.id == activity.id }) {
                updatedTrip.itineraries[dayIndex].activities[actIndex].isCompleted.toggle()
                saveTripToFirebase(updatedTrip)
            }
        }
    }
    
    func tripCompletionPercentage(_ trip: Trip) -> Double {
        let allActivities = trip.itineraries.flatMap { $0.activities }
        guard !allActivities.isEmpty else { return 0 }
        let completed = allActivities.filter { $0.isCompleted }.count
        return Double(completed) / Double(allActivities.count) * 100
    }
    
    func optimizeItinerary(for trip: Trip) -> OptimizedItinerary {
        let allActivities = trip.itineraries.flatMap { $0.activities }
        let optimized = allActivities.sorted { a, b in
            if a.startTime == b.startTime { return (a.location ?? "") < (b.location ?? "") }
            return a.startTime < b.startTime
        }
        return OptimizedItinerary(
            originalActivities: allActivities, optimizedActivities: optimized,
            optimizationType: .combined, estimatedTimeSaved: Int.random(in: 30...120),
            estimatedCostSaved: Decimal(Double.random(in: 10...100)), efficiency: Double.random(in: 75...95)
        )
    }

    // MARK: - Expense Management
    func addExpense(_ expense: Expense, to trip: Trip) {
        var updatedTrip = trip
        updatedTrip.expenses.append(expense)
        saveTripToFirebase(updatedTrip)
    }
    
    func deleteExpense(_ expense: Expense, from trip: Trip) {
        var updatedTrip = trip
        updatedTrip.expenses.removeAll { $0.id == expense.id }
        saveTripToFirebase(updatedTrip)
    }
    
    func expensesForTrip(_ trip: Trip) -> [Expense] {
        return trip.expenses.sorted { $0.date > $1.date }
    }
    
    func budgetRemainingForTrip(_ trip: Trip) -> Decimal {
        let spent = trip.expenses.reduce(0) { $0 + $1.amount }
        return trip.budget - spent
    }
    
    func budgetPercentageUsed(for trip: Trip) -> Double {
        let spent = trip.expenses.reduce(0) { $0 + $1.amount }
        guard trip.budget > 0 else { return 0 }
        let percentage = Double(truncating: (spent / trip.budget) as NSNumber) * 100
        return min(percentage, 100)
    }
    
    func expensesByCategory(for trip: Trip) -> [(category: ExpenseCategory, amount: Decimal)] {
        var categoryTotals: [ExpenseCategory: Decimal] = [:]
        for expense in trip.expenses {
            if let category = ExpenseCategory(rawValue: expense.category) {
                categoryTotals[category, default: 0] += expense.amount
            }
        }
        return categoryTotals.map { (category: $0.key, amount: $0.value) }.sorted { $0.amount > $1.amount }
    }

    // MARK: - Packing List Management
    func addPackingItem(_ item: PackingItem, to trip: Trip) {
        var updatedTrip = trip
        updatedTrip.packingItems.append(item)
        saveTripToFirebase(updatedTrip)
    }
    
    func togglePackingItem(_ item: PackingItem, in trip: Trip) {
        var updatedTrip = trip
        if let index = updatedTrip.packingItems.firstIndex(where: { $0.id == item.id }) {
            updatedTrip.packingItems[index].isPacked.toggle()
            saveTripToFirebase(updatedTrip)
        }
    }
    
    func deletePackingItem(_ item: PackingItem, from trip: Trip) {
        var updatedTrip = trip
        updatedTrip.packingItems.removeAll { $0.id == item.id }
        saveTripToFirebase(updatedTrip)
    }
    
    func updatePackingItem(_ item: PackingItem, in trip: Trip) {
        var updatedTrip = trip
        if let index = updatedTrip.packingItems.firstIndex(where: { $0.id == item.id }) {
            updatedTrip.packingItems[index] = item
            saveTripToFirebase(updatedTrip)
        }
    }
    
    func packingItemsForTrip(_ trip: Trip) -> [PackingItem] {
        return trip.packingItems
    }
    
    func packingProgressForTrip(_ trip: Trip) -> Double {
        guard !trip.packingItems.isEmpty else { return 0 }
        let packed = trip.packingItems.filter { $0.isPacked }.count
        return Double(packed) / Double(trip.packingItems.count) * 100
    }
    
    func groupedPackingItems(for trip: Trip) -> [(key: String, items: [PackingItem])] {
        let grouped = Dictionary(grouping: trip.packingItems) { $0.category }
        return grouped.map { (key: $0.key, items: $0.value) }.sorted { $0.key < $1.key }
    }
    
    // MARK: - Dummy Data Injection
    func generateSampleDataToFirebase() {
        guard let uid = userId else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // 1. Future Trip: Lisbon
        var lisbon = Trip(
            id: UUID().uuidString, userId: uid, title: "Weekend in Lisbon", description: "Pastéis de nata and sunset at Miradouro da Graça", destination: "Lisbon, Portugal",
            startDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!, endDate: Calendar.current.date(byAdding: .day, value: 18, to: Date())!, budget: 1500, currency: "USD", status: .planning, coverImageURL: nil, category: nil, itineraries: [], expenses: [], packingItems: [], createdAt: Date(), updatedAt: Date()
        )
        lisbon.itineraries = [ItineraryDay(tripId: lisbon.id, dayNumber: 1, date: lisbon.startDate)]
        lisbon.packingItems = [PackingItem(id: UUID().uuidString, tripId: lisbon.id, name: "Passport", category: "Documents", quantity: 1, isPacked: false)]
        
        // 2. Ongoing Trip: Paris
        var paris = Trip(
            id: UUID().uuidString, userId: uid, title: "Summer in Paris", description: "Eiffel Tower, Louvre, and Seine River", destination: "Paris, France",
            startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!, budget: 3500, currency: "USD", status: .ongoing, coverImageURL: nil, category: nil, itineraries: [], expenses: [], packingItems: [], createdAt: Date(), updatedAt: Date()
        )
        let day1Date = paris.startDate
        let day2Date = Calendar.current.date(byAdding: .day, value: 1, to: day1Date)!
        paris.itineraries = [
            ItineraryDay(id: UUID().uuidString, tripId: paris.id, dayNumber: 1, date: day1Date, activities: [
                ItineraryActivity(id: UUID().uuidString, dayId: "day1", title: "Visit Eiffel Tower", startTime: day1Date, endTime: day1Date.addingTimeInterval(7200), location: "Eiffel Tower", description: "Morning visit", category: .sightseeing, estimatedCost: 30, isCompleted: true, priority: .high)
            ]),
            ItineraryDay(id: UUID().uuidString, tripId: paris.id, dayNumber: 2, date: day2Date, activities: [
                ItineraryActivity(id: UUID().uuidString, dayId: "day2", title: "Louvre Museum", startTime: day2Date, endTime: day2Date.addingTimeInterval(14400), location: "Musée du Louvre", description: "Mona Lisa", category: .sightseeing, estimatedCost: 20, isCompleted: false, priority: .high)
            ])
        ]
        paris.expenses = [
            Expense(id: UUID().uuidString, tripId: paris.id, activityId: nil, title: "Flight to Paris", amount: 800, category: ExpenseCategory.transportation.rawValue, date: day1Date),
            Expense(id: UUID().uuidString, tripId: paris.id, activityId: nil, title: "Hotel Le Marais", amount: 1200, category: ExpenseCategory.accommodation.rawValue, date: day1Date),
            Expense(id: UUID().uuidString, tripId: paris.id, activityId: nil, title: "Dinner at Bistro", amount: 120, category: ExpenseCategory.food.rawValue, date: day1Date)
        ]
        paris.packingItems = [
            PackingItem(id: UUID().uuidString, tripId: paris.id, name: "Jacket", category: "Clothing", quantity: 1, isPacked: true),
            PackingItem(id: UUID().uuidString, tripId: paris.id, name: "Camera", category: "Electronics", quantity: 1, isPacked: false)
        ]
        
        // 3. Past Trip: Tokyo (History)
        var tokyo = Trip(
            id: UUID().uuidString, userId: uid, title: "Tokyo Adventure", description: "Japanese culture, temples, and cuisine", destination: "Tokyo, Japan",
            startDate: Calendar.current.date(byAdding: .day, value: -40, to: Date())!, endDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!, budget: 4000, currency: "USD", status: .completed, coverImageURL: nil, category: nil, itineraries: [], expenses: [], packingItems: [], createdAt: Calendar.current.date(byAdding: .day, value: -60, to: Date())!, updatedAt: Date()
        )
        tokyo.expenses = [
            Expense(id: UUID().uuidString, tripId: tokyo.id, activityId: nil, title: "Flight to Tokyo", amount: 1500, category: ExpenseCategory.transportation.rawValue, date: tokyo.startDate),
            Expense(id: UUID().uuidString, tripId: tokyo.id, activityId: nil, title: "Ryokan Stay", amount: 1100, category: ExpenseCategory.accommodation.rawValue, date: tokyo.startDate),
            Expense(id: UUID().uuidString, tripId: tokyo.id, activityId: nil, title: "Sushi Dinner", amount: 200, category: ExpenseCategory.food.rawValue, date: tokyo.startDate)
        ]
        tokyo.itineraries = [ItineraryDay(tripId: tokyo.id, dayNumber: 1, date: tokyo.startDate, activities: [
            ItineraryActivity(id: UUID().uuidString, dayId: "day1_tokyo", title: "Senso-ji Temple", startTime: tokyo.startDate, endTime: tokyo.startDate.addingTimeInterval(3600), location: "Asakusa", description: "Oldest temple", category: .culture, estimatedCost: 0, isCompleted: true, priority: .high)
        ])]
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        
        for trip in [lisbon, paris, tokyo] {
            let docRef = db.collection("users").document(uid).collection("trips").document(trip.id)
            if let data = try? encoder.encode(trip), let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                batch.setData(dict, forDocument: docRef)
            }
        }
        
        batch.commit()
    }
}
