import XCTest
@testable import Voyara

final class AuthViewModelTests: XCTestCase {
    
    var sut: AuthViewModel!
    
    override func setUp() {
        super.setUp()
        sut = AuthViewModel()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Sign In Validation Tests
    
    func testSignInFormValidation_EmptyEmail() {
        sut.email = ""
        sut.password = "password123"
        
        XCTAssertFalse(sut.isSignInFormValid())
    }
    
    func testSignInFormValidation_EmptyPassword() {
        sut.email = "test@example.com"
        sut.password = ""
        
        XCTAssertFalse(sut.isSignInFormValid())
    }
    
    func testSignInFormValidation_ShortPassword() {
        sut.email = "test@example.com"
        sut.password = "short"
        
        XCTAssertFalse(sut.isSignInFormValid())
    }
    
    func testSignInFormValidation_Valid() {
        sut.email = "test@example.com"
        sut.password = "password123"
        
        XCTAssertTrue(sut.isSignInFormValid())
    }
    
    // MARK: - Sign Up Validation Tests
    
    func testSignUpFormValidation_EmptyDisplayName() {
        sut.email = "test@example.com"
        sut.password = "password123"
        sut.displayName = ""
        
        XCTAssertFalse(sut.isSignUpFormValid())
    }
    
    func testSignUpFormValidation_InvalidEmail() {
        sut.email = "invalidemail"
        sut.password = "password123"
        sut.displayName = "John Doe"
        
        XCTAssertFalse(sut.isSignUpFormValid())
    }
    
    func testSignUpFormValidation_Valid() {
        sut.email = "test@example.com"
        sut.password = "password123"
        sut.displayName = "John Doe"
        
        XCTAssertTrue(sut.isSignUpFormValid())
    }
    
    // MARK: - Password Visibility Tests
    
    func testPasswordVisibilityToggle() {
        XCTAssertFalse(sut.showPassword)
        sut.showPassword = true
        XCTAssertTrue(sut.showPassword)
    }
}

// MARK: - Trip ViewModel Tests
final class TripViewModelTests: XCTestCase {
    
    var sut: TripViewModel!
    
    override func setUp() {
        super.setUp()
        sut = TripViewModel()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testFilterTripsEmptyArray() {
        XCTAssertTrue(sut.filteredTrips.isEmpty)
    }
    
    func testUpcomingTrips() {
        // TODO: Implement with mock data
    }
    
    func testTripDeletionRemovesFromList() {
        // TODO: Implement with mock data
    }
}

// MARK: - Budget ViewModel Tests
final class BudgetViewModelTests: XCTestCase {
    
    var sut: BudgetViewModel!
    
    override func setUp() {
        super.setUp()
        sut = BudgetViewModel(tripId: "test_trip", budget: 5000)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testTotalSpentCalculation() {
        XCTAssertEqual(sut.totalSpent, 0)
    }
    
    func testRemainingBudgetCalculation() {
        XCTAssertEqual(sut.remainingBudget, 5000)
    }
    
    func testBudgetPercentageCalculation() {
        XCTAssertEqual(sut.budgetPercentage, 0)
    }
}

// MARK: - Weather Service Tests
final class WeatherServiceTests: XCTestCase {
    
    var sut: WeatherService!
    
    override func setUp() {
        super.setUp()
        sut = WeatherService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testPackingSuggestionsForColdWeather() {
        let coldWeather = WeatherData(
            temperature: 5,
            feelsLike: 2,
            minTemp: 0,
            maxTemp: 8,
            humidity: 50,
            windSpeed: 15,
            cloudCoverage: 80,
            description: "Cloudy",
            icon: "04d"
        )
        
        let suggestions = sut.getPackingSuggestions(weatherData: coldWeather)
        
        XCTAssertTrue(suggestions.contains("Heavy jacket"))
        XCTAssertTrue(suggestions.contains("Warm socks"))
    }
    
    func testPackingSuggestionsForRainyWeather() {
        let rainyWeather = WeatherData(
            temperature: 15,
            feelsLike: 14,
            minTemp: 12,
            maxTemp: 18,
            humidity: 85,
            windSpeed: 10,
            cloudCoverage: 100,
            description: "Light rain",
            icon: "10d"
        )
        
        let suggestions = sut.getPackingSuggestions(weatherData: rainyWeather)
        
        XCTAssertTrue(suggestions.contains("Rain jacket"))
        XCTAssertTrue(suggestions.contains("Umbrella"))
    }
}
