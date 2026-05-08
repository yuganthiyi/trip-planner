import SwiftUI
import LocalAuthentication

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSignUp = false
    @State private var animate = false
    
    var body: some View {
        ZStack {
            VoyaraColors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: VoyaraTheme.spacing32) {
                    // Logo
                    VStack(spacing: VoyaraTheme.spacing16) {
                        ZStack {
                            Circle()
                                .fill(VoyaraColors.primary.opacity(0.1))
                                .frame(width: 110, height: 110)
                                .scaleEffect(animate ? 1.08 : 1.0)
                                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animate)
                            
                            Image(systemName: "airplane.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(VoyaraColors.primary)
                        }
                        
                        Text("Voyara")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(VoyaraColors.text)
                        
                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundColor(VoyaraColors.textSecondary)
                    }
                    .padding(.top, 50)
                    
                    // Form
                    VStack(spacing: VoyaraTheme.spacing16) {
                        if isSignUp {
                            VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                                CustomTextField("Full Name", text: $authViewModel.displayName, icon: "person")
                                    .onChange(of: authViewModel.displayName) { _ in authViewModel.nameError = nil }
                                if let err = authViewModel.nameError {
                                    errorLabel(err)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                            CustomTextField("Email Address", text: $authViewModel.email, icon: "envelope")
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .onChange(of: authViewModel.email) { _ in authViewModel.emailError = nil }
                            if let err = authViewModel.emailError {
                                errorLabel(err)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                            CustomTextField("Password", text: $authViewModel.password, icon: "lock", isSecure: true, showPassword: $authViewModel.showPassword)
                                .textContentType(isSignUp ? .newPassword : .password)
                                .onChange(of: authViewModel.password) { _ in authViewModel.passwordError = nil }
                            if let err = authViewModel.passwordError {
                                errorLabel(err)
                            }
                            if isSignUp {
                                passwordStrengthIndicator
                            }
                        }
                        
                        if isSignUp {
                            VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                                CustomTextField("Confirm Password", text: $authViewModel.confirmPassword, icon: "lock.shield", isSecure: true)
                                    .onChange(of: authViewModel.confirmPassword) { _ in authViewModel.confirmPasswordError = nil }
                                if let err = authViewModel.confirmPasswordError {
                                    errorLabel(err)
                                }
                            }
                        }
                        
                        // Global error
                        if let msg = authViewModel.errorMessage {
                            HStack(spacing: VoyaraTheme.spacing8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(VoyaraColors.error)
                                Text(msg)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(VoyaraColors.error)
                            }
                            .padding(VoyaraTheme.spacing12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(VoyaraColors.error.opacity(0.08))
                            .cornerRadius(VoyaraTheme.smallRadius)
                        }
                    }
                    .padding(.horizontal, VoyaraTheme.spacing24)
                    
                    // Forgot Password (sign in only)
                    if !isSignUp {
                        HStack {
                            Spacer()
                            Button(action: { authViewModel.showForgotPassword = true }) {
                                Text("Forgot Password?")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(VoyaraColors.primary)
                            }
                        }
                        .padding(.horizontal, VoyaraTheme.spacing24)
                        .padding(.top, -VoyaraTheme.spacing8) // Adjust spacing to look better
                    }
                    
                    // Actions
                    VStack(spacing: VoyaraTheme.spacing16) {
                        PrimaryButton(
                            isSignUp ? "Create Account" : "Sign In",
                            isLoading: authViewModel.isLoading
                        ) {
                            if isSignUp { authViewModel.signUp() } else { authViewModel.signIn() }
                        }
                        
                        // Face ID / Touch ID
                        if !isSignUp {
                            Button(action: { authViewModel.authenticateWithFaceID() }) {
                                HStack(spacing: VoyaraTheme.spacing12) {
                                    Image(systemName: authViewModel.biometricType == .faceID ? "faceid" : "touchid")
                                        .font(.system(size: 26))
                                    Text(authViewModel.biometricType == .faceID ? "Sign in with Face ID" : "Sign in with Biometrics")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(VoyaraColors.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(VoyaraColors.primary.opacity(0.08))
                                .cornerRadius(VoyaraTheme.cornerRadius)
                            }
                        }
                        
                        // Divider
                        HStack {
                            Rectangle().fill(VoyaraColors.divider).frame(height: 1)
                            Text("or").font(.system(size: 14, design: .rounded)).foregroundColor(VoyaraColors.textSecondary)
                            Rectangle().fill(VoyaraColors.divider).frame(height: 1)
                        }
                        
                        // Toggle Sign In / Sign Up
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSignUp.toggle()
                                authViewModel.clearErrors()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundColor(VoyaraColors.textSecondary)
                                Text(isSignUp ? "Sign In" : "Sign Up")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(VoyaraColors.primary)
                            }
                        }
                    }
                    .padding(.horizontal, VoyaraTheme.spacing24)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear { animate = true }
        .sheet(isPresented: $authViewModel.showForgotPassword) {
            ForgotPasswordView()
                .environmentObject(authViewModel)
        }
    }
    
    // MARK: - Error Label
    private func errorLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
        }
        .foregroundColor(VoyaraColors.error)
        .padding(.leading, VoyaraTheme.spacing4)
    }
    
    // MARK: - Password Strength
    private var passwordStrengthIndicator: some View {
        let strength = passwordStrength
        return VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(VoyaraColors.surfaceVariant).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2).fill(strength.color)
                        .frame(width: g.size.width * strength.progress, height: 4)
                        .animation(.easeInOut, value: authViewModel.password)
                }
            }.frame(height: 4)
            Text(strength.label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(strength.color)
        }
    }
    
    private var passwordStrength: (label: String, color: Color, progress: CGFloat) {
        let p = authViewModel.password
        if p.isEmpty { return ("", VoyaraColors.textSecondary, 0) }
        var score = 0
        if p.count >= 8 { score += 1 }
        if p.count >= 12 { score += 1 }
        if p.contains(where: { $0.isUppercase }) { score += 1 }
        if p.contains(where: { $0.isNumber }) { score += 1 }
        if p.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) }) { score += 1 }
        
        switch score {
        case 0...1: return ("Weak", VoyaraColors.error, 0.2)
        case 2: return ("Fair", VoyaraColors.warning, 0.4)
        case 3: return ("Good", VoyaraColors.secondary, 0.6)
        case 4: return ("Strong", VoyaraColors.success, 0.8)
        default: return ("Very Strong", VoyaraColors.success, 1.0)
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                
                VStack(spacing: VoyaraTheme.spacing32) {
                    Spacer()
                    
                    // Icon
                    ZStack {
                        Circle().fill(VoyaraColors.primary.opacity(0.1)).frame(width: 100, height: 100)
                        Image(systemName: authViewModel.resetPasswordSent ? "checkmark.circle.fill" : "lock.rotation")
                            .font(.system(size: 48))
                            .foregroundColor(authViewModel.resetPasswordSent ? VoyaraColors.success : VoyaraColors.primary)
                    }
                    
                    VStack(spacing: VoyaraTheme.spacing12) {
                        Text(authViewModel.resetPasswordSent ? "Email Sent!" : "Reset Password")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(VoyaraColors.text)
                        
                        Text(authViewModel.resetPasswordSent
                             ? "We've sent a password reset link to your email. Check your inbox."
                             : "Enter your email address and we'll send you a link to reset your password.")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(VoyaraColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, VoyaraTheme.spacing16)
                    }
                    
                    if !authViewModel.resetPasswordSent {
                        VStack(spacing: VoyaraTheme.spacing16) {
                            CustomTextField("Email Address", text: $authViewModel.forgotPasswordEmail, icon: "envelope")
                            
                            if let err = authViewModel.errorMessage {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(VoyaraColors.error)
                                    Text(err).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(VoyaraColors.error)
                                }
                                .padding(VoyaraTheme.spacing12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(VoyaraColors.error.opacity(0.08))
                                .cornerRadius(VoyaraTheme.smallRadius)
                            }
                            
                            PrimaryButton("Send Reset Link", isLoading: authViewModel.isLoading) {
                                authViewModel.sendPasswordReset()
                            }
                        }
                        .padding(.horizontal, VoyaraTheme.spacing24)
                    } else {
                        PrimaryButton("Back to Sign In") {
                            authViewModel.resetPasswordSent = false
                            authViewModel.forgotPasswordEmail = ""
                            dismiss()
                        }
                        .padding(.horizontal, VoyaraTheme.spacing24)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        authViewModel.resetPasswordSent = false
                        authViewModel.errorMessage = nil
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(VoyaraColors.primary)
                }
            }
        }
    }
}
