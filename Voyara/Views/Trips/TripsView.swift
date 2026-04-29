import SwiftUI

struct TripsView: View {
    @EnvironmentObject var tripViewModel: TripViewModel
    @State private var showCreateTrip = false
    @State private var searchText = ""
    @State private var selectedFilter: TripFilter = .all
    
    enum TripFilter: String, CaseIterable {
        case all = "All"
        case planning = "Planning"
        case ongoing = "Ongoing"
        case completed = "Completed"
    }
    
    var filteredTrips: [Trip] {
        var result = tripViewModel.trips
        switch selectedFilter {
        case .all: break
        case .planning: result = result.filter { $0.status == .planning }
        case .ongoing: result = result.filter { $0.status == .ongoing }
        case .completed: result = result.filter { $0.status == .completed }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.destination.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack(spacing: VoyaraTheme.spacing12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(VoyaraColors.textSecondary)
                        TextField("Search trips...", text: $searchText)
                            .font(VoyaraTypography.bodyMedium)
                    }
                    .padding(VoyaraTheme.spacing12)
                    .background(VoyaraColors.surfaceVariant)
                    .cornerRadius(VoyaraTheme.mediumRadius)
                    .padding(.horizontal, VoyaraTheme.spacing24)
                    .padding(.top, VoyaraTheme.spacing8)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: VoyaraTheme.spacing8) {
                            ForEach(TripFilter.allCases, id: \.self) { filter in
                                FilterChip(title: filter.rawValue, isSelected: selectedFilter == filter) {
                                    withAnimation { selectedFilter = filter }
                                }
                            }
                        }
                        .padding(.horizontal, VoyaraTheme.spacing24)
                        .padding(.vertical, VoyaraTheme.spacing12)
                    }
                    
                    if filteredTrips.isEmpty {
                        Spacer()
                        VStack(spacing: VoyaraTheme.spacing16) {
                            Image(systemName: "airplane.circle")
                                .font(.system(size: 60))
                                .foregroundColor(VoyaraColors.primary.opacity(0.4))
                            Text("No Trips Yet")
                                .font(VoyaraTypography.displayMedium)
                                .foregroundColor(VoyaraColors.text)
                            Text("Start planning your next adventure")
                                .font(VoyaraTypography.bodyMedium)
                                .foregroundColor(VoyaraColors.textSecondary)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: VoyaraTheme.spacing16) {
                                ForEach(filteredTrips) { trip in
                                    NavigationLink(destination: TripDetailView(trip: trip)) {
                                        TripCard(trip: trip)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, VoyaraTheme.spacing24)
                            .padding(.vertical, VoyaraTheme.spacing16)
                            .padding(.bottom, VoyaraTheme.spacing32)
                        }
                    }
                }
            }
            .navigationTitle("My Trips")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showCreateTrip = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(VoyaraColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showCreateTrip) { CreateTripView() }
        }
    }
}

struct TripCard: View {
    let trip: Trip
    @EnvironmentObject var tripViewModel: TripViewModel
    
    var body: some View {
        VoyaraCard {
            VStack(spacing: VoyaraTheme.spacing16) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: VoyaraTheme.mediumRadius)
                        .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 100)
                    VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                        Text(trip.destination)
                            .font(VoyaraTypography.headlineMedium)
                            .foregroundColor(.white)
                        Text(trip.dateRangeString)
                            .font(VoyaraTypography.captionSmall)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(VoyaraTheme.spacing12)
                }
                HStack {
                    VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                        Text(trip.title).font(VoyaraTypography.headlineSmall).foregroundColor(VoyaraColors.text)
                        if let desc = trip.description, !desc.isEmpty {
                            Text(desc).font(VoyaraTypography.bodySmall).foregroundColor(VoyaraColors.textSecondary).lineLimit(2)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: VoyaraTheme.spacing4) {
                        StatusBadge(status: trip.status)
                        Text("\(trip.durationDays) days").font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.textSecondary)
                    }
                }
                HStack {
                    Text("Budget").font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.textSecondary)
                    Spacer()
                    Text("$\(NSDecimalNumber(decimal: trip.budget).intValue)").font(VoyaraTypography.labelSmall).foregroundColor(VoyaraColors.text)
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(VoyaraColors.surfaceVariant).frame(height: 4)
                        RoundedRectangle(cornerRadius: 3).fill(VoyaraColors.primary).frame(width: g.size.width * CGFloat(tripViewModel.budgetPercentageUsed(for: trip) / 100), height: 4)
                    }
                }.frame(height: 4)
            }
        }
    }
    
    private var gradientColors: [Color] {
        switch trip.status {
        case .planning: return [VoyaraColors.primary, VoyaraColors.primaryDark]
        case .ongoing: return [VoyaraColors.success, Color(red: 0.1, green: 0.6, blue: 0.3)]
        case .completed: return [VoyaraColors.accent, Color(red: 0.15, green: 0.7, blue: 0.5)]
        case .cancelled: return [VoyaraColors.error, Color(red: 0.8, green: 0.2, blue: 0.2)]
        }
    }
}

struct CreateTripView: View {
    @EnvironmentObject var tripViewModel: TripViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var destination = ""
    @State private var purpose = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var budget: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: VoyaraTheme.spacing24) {
                        ZStack {
                            Circle().fill(VoyaraColors.primary.opacity(0.1)).frame(width: 80, height: 80)
                            Image(systemName: "airplane.circle.fill").font(.system(size: 40)).foregroundColor(VoyaraColors.primary)
                        }.padding(.top, VoyaraTheme.spacing24)
                        
                        Text("Plan Your Trip").font(VoyaraTypography.displayMedium).foregroundColor(VoyaraColors.text)
                        
                        VStack(spacing: VoyaraTheme.spacing16) {
                            CustomTextField("Trip Name", text: $title, icon: "pencil")
                            CustomTextField("Destination", text: $destination, icon: "mappin.circle")
                            CustomTextField("Purpose (optional)", text: $purpose, icon: "tag")
                            HStack(spacing: VoyaraTheme.spacing12) {
                                Image(systemName: "dollarsign.circle").foregroundColor(VoyaraColors.textSecondary).frame(width: 20)
                                TextField("Budget", text: $budget).font(VoyaraTypography.bodyMedium).keyboardType(.decimalPad)
                            }
                            .padding(VoyaraTheme.spacing16)
                            .background(VoyaraColors.surfaceVariant)
                            .cornerRadius(VoyaraTheme.mediumRadius)
                            
                            VoyaraCard {
                                VStack(spacing: VoyaraTheme.spacing12) {
                                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date).tint(VoyaraColors.primary)
                                    Divider()
                                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date).tint(VoyaraColors.primary)
                                }
                            }
                        }.padding(.horizontal, VoyaraTheme.spacing24)
                        
                        PrimaryButton("Create Trip", isLoading: isLoading) {
                            isLoading = true
                            let budgetVal = Decimal(string: budget) ?? 0
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                tripViewModel.createTrip(title: title, destination: destination, startDate: startDate, endDate: endDate, budget: budgetVal, purpose: purpose)
                                isLoading = false
                                dismiss()
                            }
                        }
                        .padding(.horizontal, VoyaraTheme.spacing24)
                        .disabled(title.isEmpty || destination.isEmpty)
                        .opacity((title.isEmpty || destination.isEmpty) ? 0.5 : 1)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(VoyaraColors.primary)
                }
            }
        }
    }
}
