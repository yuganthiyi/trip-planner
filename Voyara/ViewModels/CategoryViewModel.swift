import Foundation
import Combine
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Category ViewModel
class CategoryViewModel: ObservableObject {
    @Published var categories: [ExploreCategory] = []
    @Published var isLoading: Bool = false
    @Published var selectedCategory: ExploreCategory?
    
    var suggestedDestinationsWithColors: [(destination: CategoryDestination, color: Color)] {
        let suggested = Array(categories.flatMap { $0.destinations }.prefix(10))
        return suggested.compactMap { d in
            guard let cat = categories.first(where: { $0.destinations.contains(where: { dest in dest.id == d.id }) }) else { return nil }
            return (d, cat.color)
        }
    }
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var userId: String?
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                self.userId = user.uid
                self.fetchCategories()
            } else {
                self.userId = nil
                self.categories = []
                self.listenerRegistration?.remove()
            }
        }
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    // MARK: - Fetch Categories (Real-time listener)
    func fetchCategories() {
        guard let uid = userId else { return }
        
        isLoading = true
        listenerRegistration?.remove()
        
        listenerRegistration = db.collection("users").document(uid).collection("categories")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching categories: \(String(describing: error))")
                    self?.isLoading = false
                    return
                }
                
                let fetched = documents.compactMap { doc -> ExploreCategory? in
                    guard let data = try? JSONSerialization.data(withJSONObject: doc.data()) else { return nil }
                    return try? JSONDecoder().decode(ExploreCategory.self, from: data)
                }
                
                DispatchQueue.main.async {
                    self?.categories = fetched.sorted { $0.title < $1.title }
                    self?.isLoading = false
                    
                    // Seed if empty
                    if fetched.isEmpty {
                        self?.seedDefaultCategories()
                    }
                }
            }
    }
    
    // MARK: - Seed Default Categories
    private func seedDefaultCategories() {
        Task {
            await FirebaseService.shared.seedCategoriesIfNeeded()
        }
    }
    
    // MARK: - Get category by title
    func category(named title: String) -> ExploreCategory? {
        categories.first { $0.title == title }
    }
    
    // MARK: - Get count for category
    func destinationCount(for categoryTitle: String) -> Int {
        category(named: categoryTitle)?.destinationCount ?? 0
    }
}
