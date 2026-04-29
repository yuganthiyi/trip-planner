import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var tripViewModel: TripViewModel
    @EnvironmentObject var weatherViewModel: WeatherViewModel
    @State private var showSignOutAlert = false
    @State private var showTripHistory = false
    @State private var showImagePicker = false
    @State private var showEditName = false
    @State private var editedName = ""
    @State private var faceIDToggle = false
    @State private var showFaceIDAlert = false
    @State private var faceIDAlertMessage = ""
    @State private var selectedPhoto: PhotosPickerItem?
    
    // Alerts
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileHeader
                        
                        VStack(spacing: VoyaraTheme.spacing20) {
                            tripHistoryCard.padding(.top, VoyaraTheme.spacing20)
                            
                            // Account
                            sectionTitle("Account")
                            VStack(spacing: 0) {
                                settingRow(icon: "person.circle.fill", title: "Name", value: authViewModel.displayName.isEmpty ? "Not set" : authViewModel.displayName) {
                                    editedName = authViewModel.displayName
                                    showEditName = true
                                }
                                Divider().padding(.leading, 60)
                                settingRow(icon: "envelope.fill", title: "Email", value: authViewModel.email.isEmpty ? "Not set" : authViewModel.email) {}
                                Divider().padding(.leading, 60)
                                settingRow(icon: "bell.fill", title: "Notifications", value: "Enabled") {
                                    alertTitle = "Notifications"
                                    alertMessage = "Push notifications are currently enabled in iOS Settings."
                                    showAlert = true
                                }
                                Divider().padding(.leading, 60)
                                settingRow(icon: "lock.shield.fill", title: "Privacy", value: "") {
                                    alertTitle = "Privacy"
                                    alertMessage = "Your data is stored securely and synced with Firebase. We do not track your activity."
                                    showAlert = true
                                }
                                Divider().padding(.leading, 60)
                                
                                // Face ID Toggle
                                HStack(spacing: VoyaraTheme.spacing16) {
                                    Image(systemName: "faceid")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(VoyaraColors.primary)
                                        .frame(width: 32, height: 32)
                                        .background(VoyaraColors.primary.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    Text("Face ID Login")
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .foregroundColor(VoyaraColors.text)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $faceIDToggle)
                                        .labelsHidden()
                                        .tint(VoyaraColors.primary)
                                        .onChange(of: faceIDToggle) { newValue in
                                            if newValue != authViewModel.faceIDEnabled {
                                                authViewModel.toggleFaceID { success in
                                                    if success {
                                                        faceIDAlertMessage = newValue ? "Face ID enabled! You can now sign in with Face ID." : "Face ID disabled."
                                                    } else {
                                                        faceIDToggle = authViewModel.faceIDEnabled
                                                        faceIDAlertMessage = "Could not enable Face ID."
                                                    }
                                                    showFaceIDAlert = true
                                                }
                                            }
                                        }
                                }
                                .padding(.horizontal, VoyaraTheme.spacing16)
                                .padding(.vertical, VoyaraTheme.spacing14)
                            }
                            .background(VoyaraColors.surface)
                            .cornerRadius(VoyaraTheme.cornerRadius)
                            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                            .padding(.horizontal, VoyaraTheme.spacing24)
                            
                            // Preferences
                            sectionTitle("Preferences")
                            VStack(spacing: 0) {
                                settingRow(icon: "moon.stars.fill", title: "Appearance", value: isDarkMode ? "Dark" : "Light") {
                                    withAnimation { isDarkMode.toggle() }
                                }
                                Divider().padding(.leading, 60)
                                settingRow(icon: "globe", title: "Language", value: "English") {
                                    alertTitle = "Language"
                                    alertMessage = "Voyara currently supports English. More languages coming soon!"
                                    showAlert = true
                                }
                                Divider().padding(.leading, 60)
                                settingRow(icon: "location.fill", title: "Location Services", value: weatherViewModel.locationManager.authorizationStatus == .authorizedWhenInUse || weatherViewModel.locationManager.authorizationStatus == .authorizedAlways ? "Enabled" : "Disabled") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                            .background(VoyaraColors.surface)
                            .cornerRadius(VoyaraTheme.cornerRadius)
                            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                            .padding(.horizontal, VoyaraTheme.spacing24)
                            
                            // Support
                            sectionTitle("Support")
                            VStack(spacing: 0) {
                                settingRow(icon: "questionmark.circle.fill", title: "Help & Support", value: "") {
                                    alertTitle = "Help & Support"
                                    alertMessage = "Visit voyara.com/support or email help@voyara.com for assistance."
                                    showAlert = true
                                }
                                Divider().padding(.leading, 60)
                                settingRow(icon: "info.circle.fill", title: "About Voyara", value: "v1.0.0") {
                                    alertTitle = "About Voyara"
                                    alertMessage = "Voyara v1.0.0\nYour smart travel companion built with SwiftUI and Firebase."
                                    showAlert = true
                                }
                                Divider().padding(.leading, 60)
                                settingRow(icon: "star.fill", title: "Rate App", value: "") {
                                    alertTitle = "Rate App"
                                    alertMessage = "Thank you for using Voyara! App Store rating will be available on release."
                                    showAlert = true
                                }
                            }
                            .background(VoyaraColors.surface)
                            .cornerRadius(VoyaraTheme.cornerRadius)
                            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                            .padding(.horizontal, VoyaraTheme.spacing24)
                            
                            // Sign Out
                            Button(action: { showSignOutAlert = true }) {
                                HStack(spacing: VoyaraTheme.spacing12) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right").font(.system(size: 18, weight: .semibold))
                                    Text("Sign Out").font(.system(size: 17, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(VoyaraColors.error)
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(VoyaraColors.error.opacity(0.08))
                                .cornerRadius(VoyaraTheme.cornerRadius)
                            }
                            .padding(.horizontal, VoyaraTheme.spacing24)
                            
                            Text("Voyara v1.0.0 • Made with ❤️")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(VoyaraColors.textSecondary.opacity(0.5))
                                .padding(.top, VoyaraTheme.spacing8)
                            
                            Spacer(minLength: 60)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { faceIDToggle = authViewModel.faceIDEnabled }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) { authViewModel.signOut() }
            } message: { Text("Are you sure you want to sign out?") }
            .alert("Face ID", isPresented: $showFaceIDAlert) {
                Button("OK") {}
            } message: { Text(faceIDAlertMessage) }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: { Text(alertMessage) }
            .sheet(isPresented: $showTripHistory) { TripHistoryView() }
            .alert("Edit Name", isPresented: $showEditName) {
                TextField("Full Name", text: $editedName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    authViewModel.displayName = editedName
                    authViewModel.updateProfileField("displayName", value: editedName)
                }
            } message: { Text("Enter your full name") }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        ZStack {
            LinearGradient(colors: [VoyaraColors.primary, VoyaraColors.primaryDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 300)
            
            VStack(spacing: VoyaraTheme.spacing16) {
                // Avatar with photo picker
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    ZStack {
                        Circle().fill(.white.opacity(0.15)).frame(width: 100, height: 100)
                        Circle().fill(.white.opacity(0.08)).frame(width: 116, height: 116)
                        
                        if let data = authViewModel.profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 72))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Circle()
                            .fill(VoyaraColors.secondary)
                            .frame(width: 32, height: 32)
                            .overlay(Image(systemName: "camera.fill").font(.system(size: 14, weight: .bold)).foregroundColor(.white))
                            .shadow(radius: 4)
                            .offset(x: 38, y: 38)
                    }
                }
                .onChange(of: selectedPhoto) { newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            authViewModel.saveProfileImage(data)
                        }
                    }
                }
                
                VStack(spacing: VoyaraTheme.spacing6) {
                    Text(authViewModel.displayName.isEmpty ? "Traveler" : authViewModel.displayName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(authViewModel.email.isEmpty ? "voyara@app.com" : authViewModel.email)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Stats
                HStack(spacing: 0) {
                    profileStat(value: "\(tripViewModel.trips.count)", label: "Trips")
                    Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 36)
                    profileStat(value: "\(Set(tripViewModel.trips.map { $0.destination }).count)", label: "Places")
                    Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 36)
                    profileStat(value: "\(tripViewModel.trips.reduce(0) { $0 + $1.durationDays })", label: "Days")
                }
                .padding(.horizontal, VoyaraTheme.spacing32)
            }
        }
    }
    
    // MARK: - Helpers
    private func profileStat(value: String, label: String) -> some View {
        VStack(spacing: VoyaraTheme.spacing4) {
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text(label).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.75))
        }.frame(maxWidth: .infinity)
    }
    
    private var tripHistoryCard: some View {
        Button(action: { showTripHistory = true }) {
            HStack(spacing: VoyaraTheme.spacing16) {
                RoundedRectangle(cornerRadius: VoyaraTheme.mediumRadius).fill(VoyaraColors.primary.opacity(0.1)).frame(width: 48, height: 48)
                    .overlay(Image(systemName: "clock.arrow.circlepath").font(.system(size: 22, weight: .semibold)).foregroundColor(VoyaraColors.primary))
                VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                    Text("Trip History").font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundColor(VoyaraColors.text)
                    Text("\(tripViewModel.pastTrips.count) completed trips").font(.system(size: 14, design: .rounded)).foregroundColor(VoyaraColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundColor(VoyaraColors.textSecondary)
            }
            .padding(VoyaraTheme.spacing16)
            .background(VoyaraColors.surface)
            .cornerRadius(VoyaraTheme.cornerRadius)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }.buttonStyle(.plain).padding(.horizontal, VoyaraTheme.spacing24)
    }
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundColor(VoyaraColors.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, VoyaraTheme.spacing24)
    }
    
    private func settingRow(icon: String, title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: VoyaraTheme.spacing16) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(VoyaraColors.primary)
                    .frame(width: 32, height: 32)
                    .background(VoyaraColors.primary.opacity(0.1))
                    .cornerRadius(8)
                Text(title).font(.system(size: 16, design: .rounded)).foregroundColor(VoyaraColors.text)
                Spacer()
                if !value.isEmpty {
                    Text(value).font(.system(size: 14, design: .rounded)).foregroundColor(VoyaraColors.textSecondary).lineLimit(1)
                }
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(VoyaraColors.textSecondary.opacity(0.5))
            }
            .padding(.horizontal, VoyaraTheme.spacing16)
            .padding(.vertical, VoyaraTheme.spacing14)
        }.buttonStyle(.plain)
    }
}

// MARK: - Extra Spacing
extension VoyaraTheme {
    static let spacing14: CGFloat = 14
}

// MARK: - Trip History View
struct TripHistoryView: View {
    @EnvironmentObject var tripViewModel: TripViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: VoyaraTheme.spacing20) {
                        HStack(spacing: VoyaraTheme.spacing12) {
                            let past = tripViewModel.pastTrips
                            historyStat(icon: "airplane", value: "\(past.count)", label: "Trips", color: VoyaraColors.primary)
                            let totalSpent = past.flatMap { $0.expenses }.reduce(0) { $0 + $1.amount }
                            historyStat(icon: "dollarsign.circle", value: "$\(NSDecimalNumber(decimal: totalSpent).intValue)", label: "Spent", color: VoyaraColors.secondary)
                            let totalDays = past.reduce(0) { $0 + $1.durationDays }
                            historyStat(icon: "calendar", value: "\(totalDays)", label: "Days", color: VoyaraColors.accent)
                        }.padding(.horizontal, VoyaraTheme.spacing24)
                        
                        if tripViewModel.pastTrips.isEmpty {
                            VStack(spacing: VoyaraTheme.spacing16) {
                                Spacer(minLength: 60)
                                Image(systemName: "clock").font(.system(size: 50)).foregroundColor(VoyaraColors.primary.opacity(0.3))
                                Text("No completed trips yet").font(VoyaraTypography.headlineMedium).foregroundColor(VoyaraColors.text)
                                Text("Your finished trips will appear here").font(VoyaraTypography.bodyMedium).foregroundColor(VoyaraColors.textSecondary)
                                Spacer(minLength: 60)
                            }
                        } else {
                            ForEach(tripViewModel.pastTrips) { trip in
                                NavigationLink(destination: TripDetailView(trip: trip)) {
                                    TripCard(trip: trip)
                                }.buttonStyle(.plain).padding(.horizontal, VoyaraTheme.spacing24)
                            }
                        }
                        Spacer(minLength: 40)
                    }.padding(.top, VoyaraTheme.spacing16)
                }
            }
            .navigationTitle("Trip History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(VoyaraColors.primary)
                }
            }
        }
    }
    
    private func historyStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: VoyaraTheme.spacing8) {
            Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundColor(color)
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(VoyaraColors.text)
            Text(label).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(VoyaraColors.textSecondary)
        }.frame(maxWidth: .infinity).padding(VoyaraTheme.spacing16).background(color.opacity(0.08)).cornerRadius(VoyaraTheme.mediumRadius)
    }
}
