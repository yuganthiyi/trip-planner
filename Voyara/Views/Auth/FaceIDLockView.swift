import SwiftUI

struct FaceIDLockView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            VoyaraColors.background.ignoresSafeArea()
            
            VStack(spacing: VoyaraTheme.spacing32) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(VoyaraColors.primary.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "faceid")
                        .font(.system(size: 60))
                        .foregroundColor(VoyaraColors.primary)
                }
                
                VStack(spacing: VoyaraTheme.spacing8) {
                    Text("App Locked")
                        .font(VoyaraTypography.displayMedium)
                        .foregroundColor(VoyaraColors.text)
                    
                    Text("Unlock Voyara to view your trips.")
                        .font(VoyaraTypography.bodyMedium)
                        .foregroundColor(VoyaraColors.textSecondary)
                }
                
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(VoyaraTypography.captionSmall)
                        .foregroundColor(VoyaraColors.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                PrimaryButton("Unlock with Face ID") {
                    authViewModel.authenticateWithFaceID()
                }
                .padding(.horizontal, VoyaraTheme.spacing24)
                
                Button(action: {
                    authViewModel.signOut()
                }) {
                    Text("Sign Out")
                        .font(VoyaraTypography.labelMedium)
                        .foregroundColor(VoyaraColors.error)
                }
                .padding(.bottom, VoyaraTheme.spacing32)
            }
        }
        .onAppear {
            authViewModel.authenticateWithFaceID()
        }
    }
}
