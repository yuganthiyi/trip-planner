import SwiftUI

struct ActivityEditPair: Identifiable {
    let id: String
    let activity: ItineraryActivity
    let dayId: String
    
    init(activity: ItineraryActivity, dayId: String) {
        self.id = activity.id
        self.activity = activity
        self.dayId = dayId
    }
}

struct TripDetailView: View {
    let trip: Trip
    @EnvironmentObject var tripViewModel: TripViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @State private var selectedTab = 0
    @State private var showAddActivity = false
    @State private var showAddExpense = false
    @State private var showMap = false
    @State private var showOptimizer = false
    @State private var showSharing = false
    @State private var editingActivity: ActivityEditPair?
    @State private var editingPackingItem: PackingItem?
    @Environment(\.dismiss) var dismiss
    
    var currentTrip: Trip {
        tripViewModel.trips.first(where: { $0.id == trip.id }) ?? trip
    }
    
    var body: some View {
        ZStack {
            VoyaraColors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                heroSection
                tabSelector
                TabView(selection: $selectedTab) {
                    itineraryTab.tag(0)
                    budgetTab.tag(1)
                    packingTab.tag(2)
                    progressTab.tag(3)
                    mapTab.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { showMap = true }) { Label("View on Map", systemImage: "map") }
                    Button(action: { showOptimizer = true }) { Label("Optimize Itinerary", systemImage: "wand.and.stars") }
                    Button(action: { showSharing = true }) { Label("Share Trip", systemImage: "square.and.arrow.up") }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundColor(VoyaraColors.primary)
                }
            }
        }
        .sheet(isPresented: $showAddActivity) { AddActivityView(trip: currentTrip) }
        .sheet(isPresented: $showAddExpense) { AddExpenseView(trip: currentTrip) }
        .sheet(isPresented: $showSharing) { TripSharingView(trip: currentTrip) }
        .sheet(isPresented: $showOptimizer) { OptimizerView(trip: currentTrip) }
        .sheet(item: $editingActivity) { pair in
            EditActivityView(trip: currentTrip, activity: pair.activity, dayId: pair.dayId)
        }
        .sheet(item: $editingPackingItem) { item in
            EditPackingItemView(item: item, trip: currentTrip)
        }
        .fullScreenCover(isPresented: $showMap) {
            NavigationStack {
                MapView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") { showMap = false }.foregroundColor(VoyaraColors.primary)
                        }
                    }
            }
        }
    }
    
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [VoyaraColors.primary, VoyaraColors.primaryDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 140)
            VStack(alignment: .leading, spacing: VoyaraTheme.spacing8) {
                StatusBadge(status: trip.status)
                Text(trip.title).font(VoyaraTypography.displayLarge).foregroundColor(.white)
                HStack(spacing: VoyaraTheme.spacing16) {
                    Label(trip.destination, systemImage: "mappin.circle.fill")
                    Label(trip.dateRangeString, systemImage: "calendar")
                }
                .font(VoyaraTypography.captionSmall).foregroundColor(.white.opacity(0.9))
            }
            .padding(VoyaraTheme.spacing24)
        }
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(["Itinerary", "Budget", "Packing", "Progress", "Map"].indices, id: \.self) { i in
                Button(action: { withAnimation { selectedTab = i } }) {
                    VStack(spacing: VoyaraTheme.spacing4) {
                        Text(["Itinerary", "Budget", "Packing", "Progress", "Map"][i])
                            .font(VoyaraTypography.labelSmall)
                            .foregroundColor(selectedTab == i ? VoyaraColors.primary : VoyaraColors.textSecondary)
                        Rectangle()
                            .fill(selectedTab == i ? VoyaraColors.primary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, VoyaraTheme.spacing24)
        .padding(.top, VoyaraTheme.spacing8)
    }
    
    // MARK: - Itinerary Tab
    private var itineraryTab: some View {
        ScrollView {
            VStack(spacing: VoyaraTheme.spacing16) {
                let days = tripViewModel.itineraryDaysForTrip(currentTrip)
                if days.isEmpty || days.allSatisfy({ $0.activities.isEmpty }) {
                    emptyState(icon: "calendar.badge.plus", title: "No Activities", subtitle: "Add activities to plan your days")
                } else {
                    ForEach(days) { day in
                        if !day.activities.isEmpty {
                            DaySection(day: day, trip: currentTrip, onEditActivity: { act, dId in
                                editingActivity = ActivityEditPair(activity: act, dayId: dId)
                            })
                        }
                    }
                }
                
                Button(action: { showAddActivity = true }) {
                    Label("Add Activity", systemImage: "plus.circle.fill")
                        .font(VoyaraTypography.labelMedium)
                        .foregroundColor(VoyaraColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(VoyaraTheme.spacing16)
                        .background(VoyaraColors.primary.opacity(0.08))
                        .cornerRadius(VoyaraTheme.cornerRadius)
                }
            }
            .padding(VoyaraTheme.spacing24)
        }
    }
    
    // MARK: - Budget Tab
    private var budgetTab: some View {
        ScrollView {
            VStack(spacing: VoyaraTheme.spacing16) {
                // Budget Summary
                VoyaraCard {
                    VStack(spacing: VoyaraTheme.spacing12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Budget").font(VoyaraTypography.bodySmall).foregroundColor(VoyaraColors.textSecondary)
                                Text("$\(NSDecimalNumber(decimal: currentTrip.budget).intValue)").font(VoyaraTypography.displayLarge).foregroundColor(VoyaraColors.text)
                            }
                            Spacer()
                            CircularProgressView(progress: tripViewModel.budgetPercentageUsed(for: currentTrip) / 100, lineWidth: 6, size: 56, color: budgetColor)
                                .overlay(Text("\(Int(tripViewModel.budgetPercentageUsed(for: currentTrip)))%").font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.text))
                        }
                        HStack {
                            Label("Spent: $\(NSDecimalNumber(decimal: currentTrip.budget - tripViewModel.budgetRemainingForTrip(currentTrip)).intValue)", systemImage: "arrow.up.circle").foregroundColor(VoyaraColors.error)
                            Spacer()
                            Label("Left: $\(NSDecimalNumber(decimal: tripViewModel.budgetRemainingForTrip(currentTrip)).intValue)", systemImage: "arrow.down.circle").foregroundColor(VoyaraColors.success)
                        }.font(VoyaraTypography.labelSmall)
                    }
                }
                
                // Expenses
                let expenses = tripViewModel.expensesForTrip(currentTrip)
                if expenses.isEmpty {
                    emptyState(icon: "creditcard", title: "No Expenses", subtitle: "Track your spending")
                } else {
                    ForEach(expenses) { expense in
                        ExpenseRow(expense: expense, onDelete: {
                            tripViewModel.deleteExpense(expense, from: currentTrip)
                        })
                    }
                }
                
                Button(action: { showAddExpense = true }) {
                    Label("Add Expense", systemImage: "plus.circle.fill")
                        .font(VoyaraTypography.labelMedium).foregroundColor(VoyaraColors.primary)
                        .frame(maxWidth: .infinity).padding(VoyaraTheme.spacing16)
                        .background(VoyaraColors.primary.opacity(0.08)).cornerRadius(VoyaraTheme.cornerRadius)
                }
            }
            .padding(VoyaraTheme.spacing24)
        }
    }
    
    private var budgetColor: Color {
        let pct = tripViewModel.budgetPercentageUsed(for: currentTrip)
        if pct > 90 { return VoyaraColors.error }
        if pct > 70 { return VoyaraColors.warning }
        return VoyaraColors.success
    }
    
    // MARK: - Packing Tab
    private var packingTab: some View {
        ScrollView {
            VStack(spacing: VoyaraTheme.spacing16) {
                let progress = tripViewModel.packingProgressForTrip(currentTrip)
                VoyaraCard {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Packing Progress").font(VoyaraTypography.headlineSmall).foregroundColor(VoyaraColors.text)
                            Text("\(tripViewModel.packingItemsForTrip(currentTrip).filter { $0.isPacked }.count)/\(tripViewModel.packingItemsForTrip(currentTrip).count) items packed")
                                .font(VoyaraTypography.bodySmall).foregroundColor(VoyaraColors.textSecondary)
                        }
                        Spacer()
                        CircularProgressView(progress: progress / 100, lineWidth: 6, size: 48, color: VoyaraColors.accent)
                            .overlay(Text("\(Int(progress))%").font(VoyaraTypography.captionSmall))
                    }
                }
                
                let grouped = tripViewModel.groupedPackingItems(for: currentTrip)
                ForEach(grouped, id: \.key) { group in
                    VStack(alignment: .leading, spacing: VoyaraTheme.spacing8) {
                        Text(group.key).font(VoyaraTypography.headlineSmall).foregroundColor(VoyaraColors.text)
                        ForEach(group.items) { item in
                            PackingItemRow(
                                item: item,
                                onToggle: {
                                    tripViewModel.togglePackingItem(item, in: currentTrip)
                                },
                                onDelete: {
                                    tripViewModel.deletePackingItem(item, from: currentTrip)
                                },
                                onEdit: {
                                    editingPackingItem = item
                                }
                            )
                        }
                    }
                }
            }
            .padding(VoyaraTheme.spacing24)
        }
    }
    
    // MARK: - Progress Tab
    private var progressTab: some View {
        ScrollView {
            VStack(spacing: VoyaraTheme.spacing16) {
                let pct = tripViewModel.tripCompletionPercentage(currentTrip)
                VoyaraCard {
                    VStack(spacing: VoyaraTheme.spacing16) {
                        CircularProgressView(progress: pct / 100, lineWidth: 10, size: 100, color: VoyaraColors.primary)
                            .overlay(
                                VStack {
                                    Text("\(Int(pct))%").font(VoyaraTypography.displayMedium).foregroundColor(VoyaraColors.text)
                                    Text("Complete").font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.textSecondary)
                                }
                            )
                        Text("Trip Progress").font(VoyaraTypography.headlineMedium).foregroundColor(VoyaraColors.text)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                let days = tripViewModel.itineraryDaysForTrip(currentTrip)
                ForEach(days) { day in
                    if !day.activities.isEmpty {
                        VoyaraCard {
                            VStack(alignment: .leading, spacing: VoyaraTheme.spacing8) {
                                HStack {
                                    Text("Day \(day.dayNumber)").font(VoyaraTypography.headlineSmall).foregroundColor(VoyaraColors.text)
                                    Spacer()
                                    Text("\(Int(day.completionPercentage))%").font(VoyaraTypography.labelSmall).foregroundColor(VoyaraColors.primary)
                                }
                                GeometryReader { g in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3).fill(VoyaraColors.surfaceVariant).frame(height: 4)
                                        RoundedRectangle(cornerRadius: 3).fill(VoyaraColors.primary).frame(width: g.size.width * CGFloat(day.completionPercentage / 100), height: 4)
                                    }
                                }.frame(height: 4)
                                ForEach(day.activities) { act in
                                    HStack(spacing: VoyaraTheme.spacing8) {
                                        Image(systemName: act.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(act.isCompleted ? VoyaraColors.success : VoyaraColors.textSecondary)
                                        Text(act.title).font(VoyaraTypography.bodySmall)
                                            .foregroundColor(VoyaraColors.text)
                                            .strikethrough(act.isCompleted)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(VoyaraTheme.spacing24)
        }
    }
    
    // MARK: - Map Tab
    private var mapTab: some View {
        MapView()
            .clipShape(RoundedRectangle(cornerRadius: VoyaraTheme.mediumRadius))
            .padding(VoyaraTheme.spacing16)
            .onAppear {
                mapViewModel.fetchPlacesForTrip(currentTrip)
            }
            .onChange(of: currentTrip) { _ in
                mapViewModel.fetchPlacesForTrip(currentTrip)
            }
    }
    
    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VoyaraCard {
            VStack(spacing: VoyaraTheme.spacing12) {
                Image(systemName: icon).font(.system(size: 32)).foregroundColor(VoyaraColors.primary.opacity(0.5))
                Text(title).font(VoyaraTypography.headlineSmall).foregroundColor(VoyaraColors.text)
                Text(subtitle).font(VoyaraTypography.bodySmall).foregroundColor(VoyaraColors.textSecondary)
            }.frame(maxWidth: .infinity).padding(VoyaraTheme.spacing24)
        }
    }
}

// MARK: - Day Section
struct DaySection: View {
    let day: ItineraryDay
    let trip: Trip
    @EnvironmentObject var tripViewModel: TripViewModel
    let onEditActivity: (ItineraryActivity, String) -> Void
    
    var currentTrip: Trip { tripViewModel.trips.first(where: { $0.id == trip.id }) ?? trip }

    var body: some View {
        VStack(alignment: .leading, spacing: VoyaraTheme.spacing8) {
            HStack {
                Text("Day \(day.dayNumber)")
                    .font(VoyaraTypography.headlineMedium).foregroundColor(VoyaraColors.text)
                if day.isToday {
                    Text("TODAY").font(VoyaraTypography.captionSmall).foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(VoyaraColors.primary).cornerRadius(4)
                }
                Spacer()
                Text(day.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.textSecondary)
            }
            
            ForEach(day.activities) { activity in
                ActivityRow(
                    activity: activity,
                    onToggle: {
                        tripViewModel.toggleActivityCompletion(activity, dayId: day.id, trip: currentTrip)
                    },
                    onDelete: {
                        tripViewModel.deleteActivityFromDay(activity, dayId: day.id, trip: trip)
                    },
                    onEdit: {
                        onEditActivity(activity, day.id)
                    }
                )
            }
        }
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let activity: ItineraryActivity
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: VoyaraTheme.spacing12) {
            Rectangle().fill(activity.category.color).frame(width: 3, height: 50).cornerRadius(2)
            
            Button(action: onToggle) {
                Image(systemName: activity.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(activity.isCompleted ? VoyaraColors.success : VoyaraColors.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: VoyaraTheme.spacing2) {
                Text(activity.title).font(VoyaraTypography.bodyMedium).foregroundColor(VoyaraColors.text)
                    .strikethrough(activity.isCompleted)
                HStack(spacing: VoyaraTheme.spacing8) {
                    Text(activity.startTime.formatted(date: .omitted, time: .shortened))
                    if let loc = activity.location { Text("• \(loc)").lineLimit(1) }
                }.font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.textSecondary)
            }
            Spacer()
            if activity.estimatedCost > 0 {
                Text("$\(NSDecimalNumber(decimal: activity.estimatedCost).intValue)")
                    .font(VoyaraTypography.labelSmall).foregroundColor(VoyaraColors.primary)
            }
        }
        .padding(VoyaraTheme.spacing12)
        .background(VoyaraColors.surface)
        .cornerRadius(VoyaraTheme.mediumRadius)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Expense Row
struct ExpenseRow: View {
    let expense: Expense
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: VoyaraTheme.spacing12) {
            let cat = ExpenseCategory(rawValue: expense.category)
            Image(systemName: cat?.icon ?? "ellipsis.circle.fill")
                .foregroundColor(.white).font(.system(size: 14, weight: .semibold))
                .frame(width: 36, height: 36)
                .background(cat?.color ?? VoyaraColors.categoryOther)
                .cornerRadius(VoyaraTheme.smallRadius)
            VStack(alignment: .leading, spacing: VoyaraTheme.spacing2) {
                Text(expense.title).font(VoyaraTypography.bodyMedium).foregroundColor(VoyaraColors.text)
                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.textSecondary)
            }
            Spacer()
            Text("$\(NSDecimalNumber(decimal: expense.amount).intValue)")
                .font(VoyaraTypography.headlineSmall).foregroundColor(VoyaraColors.text)
        }
        .padding(VoyaraTheme.spacing12)
        .background(VoyaraColors.surface)
        .cornerRadius(VoyaraTheme.mediumRadius)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Packing Item Row
struct PackingItemRow: View {
    let item: PackingItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: VoyaraTheme.spacing12) {
                Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isPacked ? VoyaraColors.success : VoyaraColors.textSecondary)
                Text(item.name).font(VoyaraTypography.bodyMedium).foregroundColor(VoyaraColors.text)
                    .strikethrough(item.isPacked)
                Spacer()
                Text("x\(item.quantity)").font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.textSecondary)
            }
            .padding(VoyaraTheme.spacing12)
            .background(VoyaraColors.surface)
            .cornerRadius(VoyaraTheme.smallRadius)
            .contentShape(Rectangle())
            .contextMenu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .buttonStyle(.plain)
    }
}
