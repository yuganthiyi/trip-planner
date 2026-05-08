import SwiftUI

struct PackingListsView: View {
    @EnvironmentObject var tripViewModel: TripViewModel
    @State private var selectedTrip: Trip?
    @State private var showAddItem = false
    @State private var editingItem: PackingItem?
    
    private func currentTrip(for trip: Trip) -> Trip {
        tripViewModel.trips.first(where: { $0.id == trip.id }) ?? trip
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                
                if let trip = selectedTrip {
                    packingDetail(currentTrip(for: trip))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: VoyaraTheme.spacing24) {
                            ZStack {
                                Circle().fill(VoyaraColors.primary.opacity(0.1)).frame(width: 80, height: 80)
                                Image(systemName: "bag.fill").font(.system(size: 32)).foregroundColor(VoyaraColors.primary)
                            }.padding(.top, VoyaraTheme.spacing24)
                            
                            Text("Packing Lists").font(VoyaraTypography.displayMedium).foregroundColor(VoyaraColors.text)
                            Text("Organize your travel essentials").font(VoyaraTypography.bodyMedium).foregroundColor(VoyaraColors.textSecondary)
                            
                            if tripViewModel.trips.isEmpty {
                                VoyaraCard {
                                    VStack(spacing: VoyaraTheme.spacing12) {
                                        Image(systemName: "suitcase").font(.system(size: 40)).foregroundColor(VoyaraColors.primary.opacity(0.4))
                                        Text("No trips yet").font(VoyaraTypography.headlineSmall).foregroundColor(VoyaraColors.text)
                                        Text("Create a trip to start packing").font(VoyaraTypography.bodySmall).foregroundColor(VoyaraColors.textSecondary)
                                    }.frame(maxWidth: .infinity).padding(VoyaraTheme.spacing24)
                                }.padding(.horizontal, VoyaraTheme.spacing24)
                            } else {
                                ForEach(tripViewModel.trips) { trip in
                                    let items = tripViewModel.packingItemsForTrip(trip)
                                    let packed = items.filter { $0.isPacked }.count
                                    let progress = items.isEmpty ? 0 : Double(packed) / Double(items.count)
                                    
                                    Button(action: { selectedTrip = trip }) {
                                        VoyaraCard {
                                            VStack(spacing: VoyaraTheme.spacing12) {
                                                HStack {
                                                    VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                                                        Text(trip.title).font(VoyaraTypography.headlineMedium).foregroundColor(VoyaraColors.text)
                                                        Text(trip.destination).font(VoyaraTypography.bodySmall).foregroundColor(VoyaraColors.textSecondary)
                                                    }
                                                    Spacer()
                                                    CircularProgressView(progress: progress, lineWidth: 4, size: 40, color: VoyaraColors.accent)
                                                        .overlay(Text("\(packed)/\(items.count)").font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.text))
                                                }
                                                GeometryReader { g in
                                                    ZStack(alignment: .leading) {
                                                        RoundedRectangle(cornerRadius: 3).fill(VoyaraColors.surfaceVariant).frame(height: 4)
                                                        RoundedRectangle(cornerRadius: 3).fill(VoyaraColors.accent).frame(width: g.size.width * CGFloat(progress), height: 4)
                                                    }
                                                }.frame(height: 4)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, VoyaraTheme.spacing24)
                                }
                            }
                            
                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationTitle("Packing")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedTrip != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { selectedTrip = nil }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }.foregroundColor(VoyaraColors.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                if let trip = selectedTrip {
                    AddPackingItemView(trip: currentTrip(for: trip))
                }
            }
            .sheet(item: $editingItem) { item in
                if let trip = selectedTrip {
                    EditPackingItemView(item: item, trip: currentTrip(for: trip))
                }
            }
        }
    }
    
    private func packingDetail(_ trip: Trip) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: VoyaraTheme.spacing20) {
                // Header
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: [VoyaraColors.accent, VoyaraColors.accent.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 120).cornerRadius(VoyaraTheme.cornerRadius)
                    VStack(alignment: .leading, spacing: VoyaraTheme.spacing8) {
                        Text(trip.title).font(VoyaraTypography.displayMedium).foregroundColor(.white)
                        let items = tripViewModel.packingItemsForTrip(trip)
                        Text("\(items.filter { $0.isPacked }.count)/\(items.count) items packed")
                            .font(VoyaraTypography.bodySmall).foregroundColor(.white.opacity(0.9))
                    }.padding(VoyaraTheme.spacing20)
                }.padding(.horizontal, VoyaraTheme.spacing24)
                
                // Categories
                let grouped = tripViewModel.groupedPackingItems(for: trip)
                ForEach(grouped, id: \.key) { group in
                    VStack(alignment: .leading, spacing: VoyaraTheme.spacing8) {
                        HStack {
                            Image(systemName: categoryIcon(group.key)).foregroundColor(VoyaraColors.primary)
                            Text(group.key).font(VoyaraTypography.headlineSmall).foregroundColor(VoyaraColors.text)
                            Spacer()
                            let packed = group.items.filter { $0.isPacked }.count
                            Text("\(packed)/\(group.items.count)").font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.textSecondary)
                        }
                        
                        ForEach(group.items) { item in
                            PackingItemRow(
                                item: item,
                                onToggle: {
                                    tripViewModel.togglePackingItem(item, in: trip)
                                },
                                onDelete: {
                                    tripViewModel.deletePackingItem(item, from: trip)
                                },
                                onEdit: {
                                    editingItem = item
                                }
                            )
                        }
                    }
                    .padding(.horizontal, VoyaraTheme.spacing24)
                }
                
                // Add Item
                Button(action: {
                    showAddItem = true
                }) {
                    Label("Add Item", systemImage: "plus.circle.fill")
                        .font(VoyaraTypography.labelMedium).foregroundColor(VoyaraColors.primary)
                        .frame(maxWidth: .infinity).padding(VoyaraTheme.spacing16)
                        .background(VoyaraColors.primary.opacity(0.08)).cornerRadius(VoyaraTheme.cornerRadius)
                }.padding(.horizontal, VoyaraTheme.spacing24)
                
                Spacer(minLength: 40)
            }
        }
    }
    
    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Clothing": return "tshirt.fill"
        case "Documents": return "doc.text.fill"
        case "Electronics": return "laptopcomputer"
        case "Toiletries": return "cross.case.fill"
        case "Accessories": return "sunglasses"
        default: return "bag.fill"
        }
    }
}
