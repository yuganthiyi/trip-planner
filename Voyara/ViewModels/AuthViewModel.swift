import Foundation
import Combine
import SwiftUI
import LocalAuthentication
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var displayName: String = ""
    @Published var showPassword: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var error: Error? = nil
    @Published var isAuthenticated: Bool = false
    @Published var biometricType: LABiometryType = .none
    @Published var canUseBiometrics: Bool = false
    @Published var showForgotPassword: Bool = false
    @Published var forgotPasswordEmail: String = ""
    @Published var resetPasswordSent: Bool = false
    @Published var profileImageData: Data? = nil
    
    // Validation
    @Published var emailError: String? = nil
    @Published var passwordError: String? = nil
    @Published var nameError: String? = nil
    @Published var confirmPasswordError: String? = nil
    @Published var isUnlocked: Bool = false
    
    // Face ID
    @AppStorage("faceIDEnabled") var faceIDEnabled: Bool = false
    @AppStorage("savedUserEmail") private var savedUserEmail: String = ""
    
    var hasSavedAccount: Bool { !savedUserEmail.isEmpty && faceIDEnabled }
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        isUnlocked = !UserDefaults.standard.bool(forKey: "faceIDEnabled")
        checkBiometricAvailability()
        loadProfileImage()
        listenToAuthState()
    }
    
    deinit {
        if let listener = authStateListener { Auth.auth().removeStateDidChangeListener(listener) }
    }
    
    // MARK: - Auth State
    private func listenToAuthState() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.isAuthenticated = true
                    self?.displayName = user.displayName ?? ""
                    self?.email = user.email ?? ""
                    self?.savedUserEmail = user.email ?? ""
                    self?.loadUserProfileFromFirestore(uid: user.uid)
                }
            }
        }
    }
    
    // MARK: - Biometrics
    private func checkBiometricAvailability() {
        let context = LAContext()
        var authError: NSError?
        canUseBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError)
        biometricType = context.biometryType
    }
    
    // MARK: - Validation
    func validateEmail() -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let valid = NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
        emailError = email.isEmpty ? "Email is required" : (!valid ? "Enter a valid email address" : nil)
        return valid && !email.isEmpty
    }
    
    func validatePassword() -> Bool {
        if password.isEmpty { passwordError = "Password is required"; return false }
        if password.count < 8 { passwordError = "Must be at least 8 characters"; return false }
        if !password.contains(where: { $0.isUppercase }) { passwordError = "Must contain an uppercase letter"; return false }
        if !password.contains(where: { $0.isNumber }) { passwordError = "Must contain a number"; return false }
        passwordError = nil; return true
    }
    
    func validateName() -> Bool {
        if displayName.trimmingCharacters(in: .whitespaces).isEmpty { nameError = "Full name is required"; return false }
        if displayName.count < 2 { nameError = "Name must be at least 2 characters"; return false }
        nameError = nil; return true
    }
    
    func validateConfirmPassword() -> Bool {
        if confirmPassword != password { confirmPasswordError = "Passwords don't match"; return false }
        confirmPasswordError = nil; return true
    }
    
    func clearErrors() {
        emailError = nil; passwordError = nil; nameError = nil; confirmPasswordError = nil; errorMessage = nil
    }

    // MARK: - Sign In
    func signIn() {
        clearErrors()
        guard validateEmail(), validatePassword() else { return }
        isLoading = true; errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = self?.firebaseErrorMessage(error)
                } else {
                    self?.isAuthenticated = true
                    self?.isUnlocked = true
                    self?.savedUserEmail = self?.email ?? ""
                    self?.displayName = result?.user.displayName ?? self?.displayName ?? ""
                }
            }
        }
    }

    // MARK: - Sign Up
    func signUp() {
        clearErrors()
        guard validateName(), validateEmail(), validatePassword(), validateConfirmPassword() else { return }
        isLoading = true; errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = self?.firebaseErrorMessage(error)
                } else if let user = result?.user {
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = self?.displayName
                    changeRequest.commitChanges { _ in
                        DispatchQueue.main.async {
                            self?.isAuthenticated = true
                            self?.isUnlocked = true
                            self?.savedUserEmail = self?.email ?? ""
                            self?.saveUserProfileToFirestore(uid: user.uid)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Forgot Password
    func sendPasswordReset() {
        let resetEmail = forgotPasswordEmail.isEmpty ? email : forgotPasswordEmail
        guard !resetEmail.isEmpty else { errorMessage = "Please enter your email address"; return }
        isLoading = true; errorMessage = nil
        Auth.auth().sendPasswordReset(withEmail: resetEmail) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error { self?.errorMessage = self?.firebaseErrorMessage(error) }
                else { self?.resetPasswordSent = true }
            }
        }
    }

    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            email = ""; password = ""; confirmPassword = ""; displayName = ""
            clearErrors()
        } catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Face ID Authentication
    func authenticateWithFaceID() {
        guard hasSavedAccount else {
            errorMessage = "Please sign in with email first, then enable Face ID in your profile."
            return
        }
        
        let context = LAContext()
        var authError: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            errorMessage = "Biometric authentication is not available on this device."
            return
        }
        
        let reason = "Sign in to Voyara securely"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evaluateError in
            DispatchQueue.main.async {
                if success {
                    // Biometric matched — check if Firebase session exists
                    if Auth.auth().currentUser != nil {
                        self.isAuthenticated = true
                        self.isUnlocked = true
                    } else {
                        // Session expired, need to re-authenticate
                        self.errorMessage = "Session expired. Please sign in with email and password."
                        self.faceIDEnabled = false
                    }
                } else {
                    if let error = evaluateError as? LAError {
                        switch error.code {
                        case .userCancel:
                            break // User cancelled
                        case .biometryNotEnrolled:
                            self.errorMessage = "No biometrics enrolled. Please set up Face ID in Settings."
                        case .biometryLockout:
                            self.errorMessage = "Biometrics locked. Too many failed attempts."
                        default:
                            self.errorMessage = "Face ID did not match. Please try again or sign in with email."
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Enable/Disable Face ID
    func toggleFaceID(completion: @escaping (Bool) -> Void) {
        if faceIDEnabled {
            faceIDEnabled = false
            completion(true)
            return
        }
        
        let context = LAContext()
        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            errorMessage = "Biometric authentication is not available."
            completion(false)
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Enable Face ID for Voyara") { success, _ in
            DispatchQueue.main.async {
                if success {
                    self.faceIDEnabled = true
                    self.savedUserEmail = Auth.auth().currentUser?.email ?? self.email
                    completion(true)
                } else {
                    self.errorMessage = "Face ID verification failed. Could not enable."
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Profile Image (Local Storage)
    func saveProfileImage(_ imageData: Data) {
        profileImageData = imageData
        let url = Self.profileImageURL
        try? imageData.write(to: url)
    }
    
    func loadProfileImage() {
        let url = Self.profileImageURL
        if let data = try? Data(contentsOf: url) {
            profileImageData = data
        }
    }
    
    func deleteProfileImage() {
        profileImageData = nil
        try? FileManager.default.removeItem(at: Self.profileImageURL)
    }
    
    private static var profileImageURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("voyara_profile_image.jpg")
    }
    
    // MARK: - Firestore User Profile
    func saveUserProfileToFirestore(uid: String) {
        let data: [String: Any] = [
            "displayName": displayName,
            "email": email,
            "faceIDEnabled": faceIDEnabled,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        db.collection("users").document(uid).setData(data, merge: true)
    }
    
    func loadUserProfileFromFirestore(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data(), error == nil else { return }
            DispatchQueue.main.async {
                if let name = data["displayName"] as? String, !name.isEmpty {
                    self?.displayName = name
                }
            }
        }
    }
    
    func updateProfileField(_ field: String, value: Any) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).setData([field: value, "updatedAt": FieldValue.serverTimestamp()], merge: true)
    }
    
    // MARK: - Error Mapping
    private func firebaseErrorMessage(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case AuthErrorCode.wrongPassword.rawValue: return "Incorrect password. Please try again."
        case AuthErrorCode.invalidEmail.rawValue: return "The email address is invalid."
        case AuthErrorCode.userNotFound.rawValue: return "No account found with this email."
        case AuthErrorCode.emailAlreadyInUse.rawValue: return "An account with this email already exists."
        case AuthErrorCode.weakPassword.rawValue: return "Password is too weak. Use at least 8 characters."
        case AuthErrorCode.networkError.rawValue: return "Network error. Check your connection."
        case AuthErrorCode.tooManyRequests.rawValue: return "Too many attempts. Try again later."
        default: return error.localizedDescription
        }
    }
}
