import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    let onSelect: (String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: VoyaraTheme.spacing12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(VoyaraColors.textSecondary)
                    TextField("Search for a destination...", text: $searchText)
                        .font(VoyaraTypography.bodyMedium)
                        .submitLabel(.search)
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = ""; searchResults = [] }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(VoyaraColors.textSecondary)
                        }
                    }
                }
                .padding(VoyaraTheme.spacing12)
                .background(VoyaraColors.surfaceVariant)
                .cornerRadius(VoyaraTheme.mediumRadius)
                .padding(.horizontal, VoyaraTheme.spacing24)
                .padding(.vertical, VoyaraTheme.spacing16)
                
                if isSearching {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                } else {
                    List(searchResults, id: \.self) { item in
                        Button(action: {
                            let name = item.name ?? ""
                            let address = item.placemark.title ?? ""
                            let display = name.contains(address) ? name : "\(name), \(address)"
                            onSelect(display)
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name ?? "Unknown Place")
                                    .font(VoyaraTypography.headlineSmall)
                                    .foregroundColor(VoyaraColors.text)
                                Text(item.placemark.title ?? "")
                                    .font(VoyaraTypography.captionSmall)
                                    .foregroundColor(VoyaraColors.textSecondary)
                            }
                        }
                        .listRowBackground(VoyaraColors.background)
                    }
                    .listStyle(.plain)
                }
            }
            .background(VoyaraColors.background)
            .navigationTitle("Pick Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(VoyaraColors.primary)
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            if let response = response {
                searchResults = response.mapItems
            }
        }
    }
}
