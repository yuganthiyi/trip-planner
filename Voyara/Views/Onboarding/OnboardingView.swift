import SwiftUI
import Lottie

// MARK: - App Root View with Splash Logic
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var tripViewModel: TripViewModel
    @EnvironmentObject var weatherViewModel: WeatherViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showSplash = true
    @State private var splashOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            if !showSplash {
                // Main App Flow
                if !hasSeenOnboarding {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                } else if authViewModel.isAuthenticated {
                    if authViewModel.isUnlocked {
                        MainTabView()
                    } else {
                        FaceIDLockView()
                    }
                } else {
                    AuthView()
                }
            }
            
            // Splash Screen overlay
            if showSplash {
                SplashScreen()
                    .opacity(splashOpacity)
                    .transition(.opacity)
            }
            
            // In-App Notification Banner
            VStack {
                if notificationViewModel.showBanner, let notif = notificationViewModel.bannerNotification {
                    HStack(spacing: VoyaraTheme.spacing12) {
                        Image(systemName: notif.type.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(VoyaraColors.primary)
                            .cornerRadius(10)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(notif.title)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(VoyaraColors.text)
                                .lineLimit(1)
                            Text(notif.message)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(VoyaraColors.textSecondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation { notificationViewModel.showBanner = false }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(VoyaraColors.textSecondary)
                                .frame(width: 24, height: 24)
                                .background(VoyaraColors.surfaceVariant)
                                .cornerRadius(12)
                        }
                    }
                    .padding(VoyaraTheme.spacing16)
                    .background(
                        RoundedRectangle(cornerRadius: VoyaraTheme.cornerRadius)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
                    )
                    .padding(.horizontal, VoyaraTheme.spacing16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .padding(.top, 50)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.6)) {
                    splashOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Splash Screen
struct SplashScreen: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.4, blue: 0.95),
                    Color(red: 0.2, green: 0.6, blue: 1.0),
                    Color(red: 0.3, green: 0.7, blue: 1.0),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: VoyaraTheme.spacing24) {
                Spacer()
                
                LottieView(name: "Travel", loopMode: .loop)
                    .frame(width: 280, height: 280)
                
                VStack(spacing: VoyaraTheme.spacing12) {
                    Text("Voyara")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Your Journey Starts Here")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                Spacer()
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - Lottie Animation View
struct LottieView: UIViewRepresentable {
    let name: String
    var loopMode: LottieLoopMode = .loop
    var contentMode: UIView.ContentMode = .scaleAspectFit
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView(name: name)
        animationView.loopMode = loopMode
        animationView.contentMode = contentMode
        animationView.play()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

// MARK: - Onboarding Pages View
struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0
    
    let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("airplane.circle.fill", "Plan Your Trip", "Create detailed itineraries with smart suggestions and optimize your travel schedule effortlessly.", Color(red: 0.2, green: 0.6, blue: 1.0)),
        ("map.fill", "Explore Places", "Discover amazing destinations with interactive maps and detailed place information.", Color(red: 0.2, green: 0.85, blue: 0.6)),
        ("creditcard.fill", "Track Budget", "Monitor expenses, manage budgets, and keep your spending on track for every trip.", Color(red: 0.95, green: 0.55, blue: 0.2)),
        ("bag.fill", "Pack Smart", "Generate smart packing lists with weather-based recommendations tailored to your destination.", Color(red: 0.8, green: 0.4, blue: 1.0)),
    ]
    
    var body: some View {
        ZStack {
            VoyaraColors.background.ignoresSafeArea()
            
            VStack(spacing: VoyaraTheme.spacing24) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: VoyaraTheme.spacing32) {
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .fill(pages[i].color.opacity(0.1))
                                    .frame(width: 180, height: 180)
                                Circle()
                                    .fill(pages[i].color.opacity(0.05))
                                    .frame(width: 220, height: 220)
                                Image(systemName: pages[i].icon)
                                    .font(.system(size: 72))
                                    .foregroundColor(pages[i].color)
                            }
                            
                            VStack(spacing: VoyaraTheme.spacing12) {
                                Text(pages[i].title)
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundColor(VoyaraColors.text)
                                
                                Text(pages[i].subtitle)
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(VoyaraColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, VoyaraTheme.spacing32)
                                    .lineSpacing(4)
                            }
                            
                            Spacer()
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page Indicators
                HStack(spacing: VoyaraTheme.spacing8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(currentPage == i ? pages[i].color : VoyaraColors.textSecondary.opacity(0.3))
                            .frame(width: currentPage == i ? 28 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                
                // Button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        hasSeenOnboarding = true
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(pages[currentPage].color)
                        .cornerRadius(VoyaraTheme.cornerRadius)
                        .shadow(color: pages[currentPage].color.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, VoyaraTheme.spacing24)
                
                if currentPage < pages.count - 1 {
                    Button("Skip") { hasSeenOnboarding = true }
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(VoyaraColors.textSecondary)
                }
                
                Spacer(minLength: 20)
            }
        }
    }
}
