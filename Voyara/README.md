# Voyara - iOS Trip Planning App

A comprehensive SwiftUI-based trip planning application for iOS built with Firebase backend, designed to help users plan, track, and manage their travel adventures.

##  Project Overview

**App Name:** Voyara  
**Language:** Swift / SwiftUI  
**Minimum Deployment Target:** iOS 17.0  
**Architecture:** MVVM (Model-View-ViewModel)  
**State Management:** @StateObject, @EnvironmentObject  
**Testing:** XCTest (Unit Tests + UI Tests)  

##  Project Structure

```
Voyara/
├── Core/
│   ├── Theme/
│   │   ├── Colors.swift           # Color palette & theme configuration
│   │   └── Typography.swift       # Font sizes & text styles
│   └── Components/
│       └── Buttons.swift          # Reusable UI components
├── Models/
│   └── Models.swift               # Data structures (User, Trip, Activity, etc)
├── ViewModels/
│   └── ViewModels.swift           # MVVM ViewModels for state management
├── Views/
│   ├── Auth/
│   │   └── AuthView.swift         # Sign In / Sign Up screens
│   ├── MainTab/
│   │   └── MainTabView.swift      # Tab bar navigation
│   ├── Dashboard/
│   │   └── (DashboardView in MainTabView)
│   ├── Trips/
│   │   └── TripsView.swift        # Trip list & detail screens
│   ├── Budget/
│   │   └── BudgetView.swift       # Budget tracking
│   ├── Packing/
│   │   └── (PackingListsView in BudgetView)
│   └── Profile/
│       └── (ProfileView in BudgetView)
├── Services/
│   ├── AuthService.swift          # Firebase authentication
│   ├── FirebaseService.swift      # Firestore operations
│   └── WeatherService.swift       # Weather API integration
├── Utilities/
│   ├── MockData.swift             # Preview & testing data
│   └── Extensions.swift           # Helper extensions
├── GoogleService-Info.plist       # Firebase configuration 
├── Voyara.xcconfig                # Build configuration & API keys
├── SETUP_GUIDE.swift              # Setup instructions
├── VoyaraApp.swift                # App entry point
└── ContentView.swift              # Deprecated (use MainTabView)
```

##  Features Implemented

### Completed
- **Design System**
  - Complete color palette with dark mode support
  - Typography system (display, headline, body, label, caption)
  - Theme constants (spacing, shadows, corner radii)
  - Reusable UI components (buttons, text fields, cards, chips)

- **Data Models**
  - User model with authentication data
  - Trip management (planning, ongoing, completed, archived)
  - Activity tracking with categories
  - Expense tracking by category
  - Packing list with smart suggestions
  - Weather data integration

- **Architecture**
  - MVVM pattern throughout the app
  - AuthViewModel for authentication flow
  - TripViewModel for trip management
  - ActivityViewModel for activity tracking
  - BudgetViewModel for expense management
  - Proper error handling with custom error types

- **Authentication UI**
  - Sign In screen with email/password
  - Face ID authentication option
  - Sign Up with validation
  - Password visibility toggle
  - Input validation with visual feedback

- **Main App Navigation**
  - Tab-based navigation (Dashboard, Trips, Budget, Packing, Profile)
  - Dashboard with trip statistics
  - Trip list with create/edit/delete
  - Trip detail view with budget overview
  - Profile screen with settings

- **Testing Infrastructure**
  - Unit test structure for ViewModels
  - Weather service tests
  - Test data generators
  - Preview providers on all Views

- **Documentation**
  - Complete setup guide (SETUP_GUIDE.swift)
  - Mock data for previews
  - Code comments throughout
  - Error handling patterns

### 🚀 Ready to Implement
- Firebase integration (services are stubbed)
- Real Firestore data operations
- Cloud Storage for photos
- Weather API integration
- Push notifications
- Offline data caching
- Photo uploading and gallery
- Budget charts and visualizations
- Advanced trip features

##  Configuration

### API Keys
Edit `Voyara.xcconfig`:
```swift
WEATHER_API_KEY = YOUR_OPENWEATHERMAP_API_KEY_HERE
```

### Firebase
- GoogleService-Info.plist is already configured
- Bundle ID: `com.dulaksha.Voyara`
- Firebase Project: `trip-planner-1c895`

### Build Settings
- Deployment Target: iOS 17.0
- Device: iPhone (Universal for iPad support)
- Interface: SwiftUI
- Language: Swift

##  Dependencies (To Be Added)

### Required
- **Firebase iOS SDK**
  - FirebaseAuth
  - FirebaseFirestore
  - FirebaseStorage
  - FirebaseMessaging
  - FirebaseAnalytics

### Optional
- Lottie for onboarding animations
- SDWebImageSwiftUI for image caching

##  Design System

### Colors
- **Primary:** Vibrant Blue (#3399FF)
- **Secondary:** Warm Orange (#FF8C33)
- **Accent:** Teal (#33D99C)
- **Success:** Green (#33CC66)
- **Error:** Red (#FF4D4D)
- **Warning:** Yellow (#FFCC00)

### Typography
- Display: 32pt Bold
- Headline: 16-20pt Semibold
- Body: 12-16pt Regular
- Label: 12-14pt Medium
- Caption: 10-11pt Regular

##  Privacy & Capabilities

### Required Info.plist Entries
```xml
<key>NSFaceIDUsageDescription</key>
<string>Voyara uses Face ID to keep your trips secure</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Voyara uses your location to show nearby places</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Add photos to your trips and profile</string>

<key>NSCameraUsageDescription</key>
<string>Take photos for receipts and trip memories</string>
```

### Capabilities to Enable
- ✓ Push Notifications
- ✓ Background Modes
- ✓ Sign in with Apple (future)
- ✓ Associated Domains (deep links)
- ✓ HealthKit (optional)

##  Views & Navigation Flow

### Authentication
```
AuthView
├── SignInView
│   ├── Email/Password login
│   ├── Face ID option
│   └── Sign up link
└── SignUpView
    ├── Display name input
    ├── Email input
    ├── Password input
    └── Back to sign in
```

### Main App
```
MainTabView
├── Dashboard Tab
│   ├── Welcome message
│   ├── Statistics cards
│   ├── Next trip highlight
│   └── Recent trips list
├── Trips Tab
│   ├── Trip list
│   └── TripDetailView
├── Budget Tab
│   ├── Budget overview
│   └── Expense breakdown
├── Packing Tab
│   ├── Packing list
│   └── Weather suggestions
└── Profile Tab
    ├── User profile
    ├── Settings
    └── Sign out
```

##  Testing

### Test Coverage
- ✓ AuthViewModel (sign in/up validation)
- ✓ TripViewModel (CRUD operations)
- ✓ BudgetViewModel (calculations)
- ✓ WeatherService (API parsing)

### Test Structure
- Unit tests in `VoyaraTests/`
- Preview providers on all Views
- Mock data for testing

##  Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ device or simulator
- Swift Package Manager (for Firebase)

### Setup Steps
1. Open `Voyara.xcodeproj` in Xcode
2. Follow steps in `SETUP_GUIDE.swift`
3. Add Firebase SDK via SPM
4. Configure API keys in `.xcconfig`
5. Enable required capabilities
6. Build and run

##  Code Standards

- No force unwraps (`!`) - use guard/if let
- All async code uses async/await
- @Published for state that drives UI
- @StateObject in root views, @ObservedObject in children
- Every View has #Preview with mock data
- MVVM strictly - no business logic in Views
- Error handling with custom error enums
- Dark mode support throughout

##  State Management

### Observation Pattern
- `AuthViewModel` - Global auth state
- `TripViewModel` - Global trip list state
- `ActivityViewModel` - Trip-specific activities
- `BudgetViewModel` - Trip-specific expenses

### Environment Objects
```swift
@EnvironmentObject var authViewModel: AuthViewModel
@EnvironmentObject var tripViewModel: TripViewModel
```

##  Data Models Hierarchy

```
User
├── id, email, displayName
├── profileImageURL, bio
└── authentication metadata

Trip
├── id, userId, title, description
├── destination, dates, budget
├── status (planning/ongoing/completed/archived)
├── Activities []
├── Expenses []
└── PackingItems []

Activity
├── id, tripId, title
├── category, location
├── dates, costs
└── completion status

Expense
├── id, tripId, activityId
├── title, amount, category
├── payment method
└── receipt image URL

PackingItem
├── id, tripId, name
├── category, quantity
├── packing status
└── weather-suggested flag
```

##  Next Steps for Development

1. **Firebase Integration** (Priority 1)
   - Implement AuthService methods
   - Implement FirebaseService methods
   - Set up Firestore data structure
   - Configure Cloud Storage

2. **Core Features** (Priority 2)
   - Real data fetching and caching
   - Trip creation and management
   - Activity planning
   - Expense tracking

3. **Advanced Features** (Priority 3)
   - Weather-based packing suggestions
   - Photo upload and gallery
   - Budget charts with SwiftUI Charts
   - Sharing trips with other users

4. **Polish & Optimization** (Priority 4)
   - App Store optimization
   - Performance profiling
   - Localization (i18n)
   - Accessibility improvements

##  Version Info

- **App Version:** 1.0.0
- **Build:** 1
- **Category:** Travel
- **Age Rating:** 4+
- **Localization:** English (primary)

##  Support

For setup issues, refer to:
1. SETUP_GUIDE.swift
2. Inline code comments
3. Mock data examples in MockData.swift
4. Preview implementations

---

**Status:** Development Foundation Complete  
**Next:** Integrate Firebase SDK and implement authentication
