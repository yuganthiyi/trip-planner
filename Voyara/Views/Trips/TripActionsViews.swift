import SwiftUI

// MARK: - Add Activity View
struct AddActivityView: View {
    let trip: Trip
    @EnvironmentObject var tripViewModel: TripViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var location = ""
    @State private var description = ""
    @State private var category: ActivityCategory = .sightseeing
    @State private var startTime = Date()
    @State private var endTime = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
    @State private var cost = ""
    @State private var priority: Priority = .medium
    @State private var selectedDayIndex = 0
    
    var currentTrip: Trip { tripViewModel.trips.first(where: { $0.id == trip.id }) ?? trip }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: VoyaraTheme.spacing16) {
                        CustomTextField("Activity Name", text: $title, icon: "star")
                        CustomTextField("Location", text: $location, icon: "mappin")
                        CustomTextField("Description", text: $description, icon: "doc.text")
                        
                        // Category Picker
                        VoyaraCard {
                            VStack(alignment: .leading, spacing: VoyaraTheme.spacing8) {
                                Text("Category").font(VoyaraTypography.labelMedium).foregroundColor(VoyaraColors.text)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: VoyaraTheme.spacing8) {
                                        ForEach(ActivityCategory.allCases, id: \.self) { cat in
                                            Button(action: { category = cat }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: cat.icon).font(.system(size: 12))
                                                    Text(cat.rawValue).font(VoyaraTypography.captionSmall)
                                                }
                                                .foregroundColor(category == cat ? .white : cat.color)
                                                .padding(.horizontal, 10).padding(.vertical, 6)
                                                .background(category == cat ? cat.color : cat.color.opacity(0.1))
                                                .cornerRadius(16)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Day Picker
                        let days = tripViewModel.itineraryDaysForTrip(currentTrip)
                        if !days.isEmpty {
                            VoyaraCard {
                                Picker("Day", selection: $selectedDayIndex) {
                                    ForEach(days.indices, id: \.self) { i in
                                        Text("Day \(days[i].dayNumber)").tag(i)
                                    }
                                }.pickerStyle(.segmented)
                            }
                        }
                        
                        VoyaraCard {
                            VStack(spacing: VoyaraTheme.spacing12) {
                                DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute).tint(VoyaraColors.primary)
                                Divider()
                                DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute).tint(VoyaraColors.primary)
                            }
                        }
                        
                        HStack(spacing: VoyaraTheme.spacing12) {
                            Image(systemName: "dollarsign.circle").foregroundColor(VoyaraColors.textSecondary)
                            TextField("Estimated Cost", text: $cost).keyboardType(.decimalPad)
                        }
                        .padding(VoyaraTheme.spacing16)
                        .background(VoyaraColors.surfaceVariant)
                        .cornerRadius(VoyaraTheme.mediumRadius)
                        
                        PrimaryButton("Add Activity") {
                            let days = tripViewModel.itineraryDaysForTrip(currentTrip)
                            guard selectedDayIndex < days.count else { return }
                            let day = days[selectedDayIndex]
                            let activity = ItineraryActivity(
                                dayId: day.id, title: title, startTime: startTime, endTime: endTime,
                                location: location.isEmpty ? nil : location,
                                description: description.isEmpty ? nil : description,
                                category: category, estimatedCost: Decimal(string: cost) ?? 0,
                                priority: priority
                            )
                            tripViewModel.addActivityToDay(activity, dayId: day.id, trip: currentTrip)
                            dismiss()
                        }
                        .disabled(title.isEmpty)
                        .opacity(title.isEmpty ? 0.5 : 1)
                    }
                    .padding(VoyaraTheme.spacing24)
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(VoyaraColors.primary)
                }
            }
        }
    }
}

// MARK: - Add Expense View
struct AddExpenseView: View {
    let trip: Trip
    @EnvironmentObject var tripViewModel: TripViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var amount = ""
    @State private var category: ExpenseCategory = .food
    @State private var date = Date()
    
    var currentTrip: Trip { tripViewModel.trips.first(where: { $0.id == trip.id }) ?? trip }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: VoyaraTheme.spacing16) {
                        CustomTextField("Expense Title", text: $title, icon: "pencil")
                        
                        HStack(spacing: VoyaraTheme.spacing12) {
                            Image(systemName: "dollarsign.circle").foregroundColor(VoyaraColors.textSecondary)
                            TextField("Amount", text: $amount).keyboardType(.decimalPad)
                        }
                        .padding(VoyaraTheme.spacing16)
                        .background(VoyaraColors.surfaceVariant)
                        .cornerRadius(VoyaraTheme.mediumRadius)
                        
                        VoyaraCard {
                            VStack(alignment: .leading, spacing: VoyaraTheme.spacing8) {
                                Text("Category").font(VoyaraTypography.labelMedium)
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                                    ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                                        Button(action: { category = cat }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: cat.icon).font(.system(size: 12))
                                                Text(cat.rawValue).font(VoyaraTypography.captionSmall).lineLimit(1)
                                            }
                                            .foregroundColor(category == cat ? .white : cat.color)
                                            .padding(.horizontal, 8).padding(.vertical, 6)
                                            .frame(maxWidth: .infinity)
                                            .background(category == cat ? cat.color : cat.color.opacity(0.1))
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        }
                        
                        VoyaraCard {
                            DatePicker("Date", selection: $date, displayedComponents: .date).tint(VoyaraColors.primary)
                        }
                        
                        PrimaryButton("Add Expense") {
                            let expense = Expense(
                                id: UUID().uuidString, tripId: trip.id, activityId: nil,
                                title: title, amount: Decimal(string: amount) ?? 0,
                                category: category.rawValue, date: date
                            )
                            tripViewModel.addExpense(expense, to: currentTrip)
                            dismiss()
                        }
                        .disabled(title.isEmpty || amount.isEmpty)
                        .opacity((title.isEmpty || amount.isEmpty) ? 0.5 : 1)
                    }
                    .padding(VoyaraTheme.spacing24)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(VoyaraColors.primary)
                }
            }
        }
    }
}

// MARK: - Trip Sharing View
struct TripSharingView: View {
    let trip: Trip
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var sharedUsers: [(name: String, role: String)] = [
        ("You", "Owner"),
        ("Emma Watson", "Can Edit"),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: VoyaraTheme.spacing24) {
                        ZStack {
                            Circle().fill(VoyaraColors.primary.opacity(0.1)).frame(width: 80, height: 80)
                            Image(systemName: "person.2.circle.fill").font(.system(size: 40)).foregroundColor(VoyaraColors.primary)
                        }
                        
                        Text("Share \(trip.title)").font(VoyaraTypography.displayMedium).foregroundColor(VoyaraColors.text)
                        
                        HStack(spacing: VoyaraTheme.spacing12) {
                            CustomTextField("Email address", text: $email, icon: "envelope")
                            Button(action: {
                                if !email.isEmpty { sharedUsers.append((name: email, role: "Can View")); email = "" }
                            }) {
                                Image(systemName: "plus.circle.fill").font(.system(size: 28)).foregroundColor(VoyaraColors.primary)
                            }
                        }.padding(.horizontal, VoyaraTheme.spacing24)
                        
                        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
                            Text("Shared With").font(VoyaraTypography.headlineMedium).foregroundColor(VoyaraColors.text)
                            ForEach(sharedUsers.indices, id: \.self) { i in
                                HStack {
                                    Circle().fill(VoyaraColors.primary.opacity(0.2)).frame(width: 36, height: 36)
                                        .overlay(Text(String(sharedUsers[i].name.prefix(1))).font(VoyaraTypography.labelMedium).foregroundColor(VoyaraColors.primary))
                                    VStack(alignment: .leading) {
                                        Text(sharedUsers[i].name).font(VoyaraTypography.bodyMedium).foregroundColor(VoyaraColors.text)
                                        Text(sharedUsers[i].role).font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.textSecondary)
                                    }
                                    Spacer()
                                }
                                .padding(VoyaraTheme.spacing12)
                                .background(VoyaraColors.surface)
                                .cornerRadius(VoyaraTheme.mediumRadius)
                            }
                        }.padding(.horizontal, VoyaraTheme.spacing24)
                    }
                }
            }
            .navigationTitle("Share Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(VoyaraColors.primary)
                }
            }
        }
    }
}

// MARK: - Optimizer View
struct OptimizerView: View {
    let trip: Trip
    @EnvironmentObject var tripViewModel: TripViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isOptimizing = false
    @State private var result: OptimizedItinerary?
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: VoyaraTheme.spacing24) {
                        ZStack {
                            Circle().fill(VoyaraColors.accent.opacity(0.1)).frame(width: 80, height: 80)
                            Image(systemName: "wand.and.stars").font(.system(size: 36)).foregroundColor(VoyaraColors.accent)
                        }.padding(.top, VoyaraTheme.spacing24)
                        
                        Text("Smart Optimizer").font(VoyaraTypography.displayMedium).foregroundColor(VoyaraColors.text)
                        Text("Automatically arrange your activities for the most efficient schedule")
                            .font(VoyaraTypography.bodyMedium).foregroundColor(VoyaraColors.textSecondary).multilineTextAlignment(.center)
                            .padding(.horizontal, VoyaraTheme.spacing24)
                        
                        if let result = result {
                            VStack(spacing: VoyaraTheme.spacing16) {
                                HStack(spacing: VoyaraTheme.spacing16) {
                                    optimizerStat(icon: "clock", value: "\(result.estimatedTimeSaved) min", label: "Time Saved", color: VoyaraColors.primary)
                                    optimizerStat(icon: "dollarsign.circle", value: "$\(NSDecimalNumber(decimal: result.estimatedCostSaved).intValue)", label: "Cost Saved", color: VoyaraColors.success)
                                    optimizerStat(icon: "gauge.high", value: "\(Int(result.efficiency))%", label: "Efficiency", color: VoyaraColors.accent)
                                }
                                .padding(.horizontal, VoyaraTheme.spacing24)
                                
                                VStack(alignment: .leading, spacing: VoyaraTheme.spacing8) {
                                    Text("Optimized Order").font(VoyaraTypography.headlineMedium).foregroundColor(VoyaraColors.text)
                                    ForEach(result.optimizedActivities) { act in
                                        HStack(spacing: VoyaraTheme.spacing8) {
                                            Image(systemName: act.category.icon).foregroundColor(act.category.color).frame(width: 24)
                                            Text(act.title).font(VoyaraTypography.bodyMedium).foregroundColor(VoyaraColors.text)
                                            Spacer()
                                            Text(act.startTime.formatted(date: .omitted, time: .shortened))
                                                .font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.textSecondary)
                                        }
                                        .padding(VoyaraTheme.spacing12).background(VoyaraColors.surface).cornerRadius(VoyaraTheme.smallRadius)
                                    }
                                }.padding(.horizontal, VoyaraTheme.spacing24)
                                
                                PrimaryButton("Apply Optimization") { dismiss() }
                                    .padding(.horizontal, VoyaraTheme.spacing24)
                            }
                        } else {
                            PrimaryButton(isOptimizing ? "Optimizing..." : "Optimize Now", isLoading: isOptimizing) {
                                isOptimizing = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    result = tripViewModel.optimizeItinerary(for: trip)
                                    isOptimizing = false
                                }
                            }.padding(.horizontal, VoyaraTheme.spacing24)
                        }
                    }
                }
            }
            .navigationTitle("Optimizer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(VoyaraColors.primary)
                }
            }
        }
    }
    
    private func optimizerStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: VoyaraTheme.spacing4) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
            Text(value).font(VoyaraTypography.headlineSmall).foregroundColor(VoyaraColors.text)
            Text(label).font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(VoyaraTheme.spacing12)
        .background(color.opacity(0.08))
        .cornerRadius(VoyaraTheme.mediumRadius)
    }
}

// MARK: - Add Packing Item View
struct AddPackingItemView: View {
    let trip: Trip
    @EnvironmentObject var tripViewModel: TripViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var category = "Clothing"
    @State private var quantity = 1
    
    let categories = ["Clothing", "Documents", "Electronics", "Toiletries", "Accessories", "Other"]
    
    var currentTrip: Trip { tripViewModel.trips.first(where: { $0.id == trip.id }) ?? trip }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: VoyaraTheme.spacing16) {
                        CustomTextField("Item Name", text: $name, icon: "bag")
                        
                        VoyaraCard {
                            VStack(alignment: .leading, spacing: VoyaraTheme.spacing8) {
                                Text("Category").font(VoyaraTypography.labelMedium).foregroundColor(VoyaraColors.text)
                                Picker("Category", selection: $category) {
                                    ForEach(categories, id: \.self) { cat in
                                        Text(cat).tag(cat)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(VoyaraColors.primary)
                            }
                        }
                        
                        VoyaraCard {
                            Stepper(value: $quantity, in: 1...20) {
                                HStack {
                                    Text("Quantity").font(VoyaraTypography.bodyMedium).foregroundColor(VoyaraColors.text)
                                    Spacer()
                                    Text("\(quantity)").font(VoyaraTypography.headlineMedium).foregroundColor(VoyaraColors.primary)
                                }
                            }
                        }
                        
                        PrimaryButton("Add Item") {
                            let item = PackingItem(
                                id: UUID().uuidString, tripId: trip.id,
                                name: name, category: category, quantity: quantity
                            )
                            tripViewModel.addPackingItem(item, to: currentTrip)
                            dismiss()
                        }
                        .disabled(name.isEmpty)
                        .opacity(name.isEmpty ? 0.5 : 1)
                    }
                    .padding(VoyaraTheme.spacing24)
                }
            }
            .navigationTitle("Add Packing Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(VoyaraColors.primary)
                }
            }
        }
    }
}
