import SwiftUI

// MARK: - Typography (Increased sizes for readability)
struct VoyaraTypography {
    static let displayLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 26, weight: .bold, design: .rounded)
    static let headlineLarge = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headlineSmall = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .rounded)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .rounded)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .rounded)
    static let labelLarge = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let labelMedium = Font.system(size: 15, weight: .medium, design: .rounded)
    static let labelSmall = Font.system(size: 13, weight: .medium, design: .rounded)
    static let captionMedium = Font.system(size: 13, weight: .regular, design: .rounded)
    static let captionSmall = Font.system(size: 12, weight: .regular, design: .rounded)
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false

    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: VoyaraTheme.spacing8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(title)
                    .font(VoyaraTypography.labelLarge)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(VoyaraColors.primary)
            .cornerRadius(VoyaraTheme.cornerRadius)
            .shadow(color: VoyaraColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(VoyaraTypography.labelLarge)
                .foregroundColor(VoyaraColors.error)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(VoyaraColors.error.opacity(0.1))
                .cornerRadius(VoyaraTheme.cornerRadius)
        }
    }
}

// MARK: - Custom TextField
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    @Binding var showPassword: Bool

    init(_ placeholder: String, text: Binding<String>, icon: String = "", isSecure: Bool = false, showPassword: Binding<Bool> = .constant(false)) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
        self._showPassword = showPassword
    }

    var body: some View {
        HStack(spacing: VoyaraTheme.spacing12) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(VoyaraColors.textSecondary)
                    .frame(width: 20)
            }

            if isSecure && !showPassword {
                SecureField(placeholder, text: $text)
                    .font(VoyaraTypography.bodyMedium)
            } else {
                TextField(placeholder, text: $text)
                    .font(VoyaraTypography.bodyMedium)
                    .autocapitalization(.none)
            }

            if isSecure {
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(VoyaraColors.textSecondary)
                }
            }
        }
        .padding(VoyaraTheme.spacing16)
        .background(VoyaraColors.surfaceVariant)
        .cornerRadius(VoyaraTheme.mediumRadius)
    }
}

// MARK: - Voyara Card
struct VoyaraCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(VoyaraTheme.spacing16)
            .background(VoyaraColors.surface)
            .cornerRadius(VoyaraTheme.cornerRadius)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Header View
struct HeaderView: View {
    let title: String
    var showBack: Bool = false
    var onBack: (() -> Void)? = nil

    var body: some View {
        HStack {
            if showBack {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(VoyaraColors.primary)
                }
            }
            Text(title)
                .font(VoyaraTypography.headlineLarge)
                .foregroundColor(VoyaraColors.text)
            Spacer()
        }
        .padding(.horizontal, VoyaraTheme.spacing24)
        .padding(.vertical, VoyaraTheme.spacing16)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(VoyaraTypography.headlineMedium)
                .foregroundColor(VoyaraColors.text)
            Spacer()
            if let actionTitle = actionTitle {
                Button(action: { action?() }) {
                    Text(actionTitle)
                        .font(VoyaraTypography.labelMedium)
                        .foregroundColor(VoyaraColors.primary)
                }
            }
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: TripStatus

    var body: some View {
        HStack(spacing: VoyaraTheme.spacing4) {
            Image(systemName: status.icon)
                .font(.system(size: 10, weight: .semibold))
            Text(status.rawValue)
                .font(VoyaraTypography.labelSmall)
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, VoyaraTheme.spacing8)
        .padding(.vertical, VoyaraTheme.spacing4)
        .background(statusColor.opacity(0.12))
        .cornerRadius(VoyaraTheme.smallRadius)
    }

    var statusColor: Color {
        switch status {
        case .planning: return VoyaraColors.primary
        case .ongoing: return VoyaraColors.success
        case .completed: return VoyaraColors.accent
        case .cancelled: return VoyaraColors.error
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(VoyaraTypography.labelSmall)
                .foregroundColor(isSelected ? .white : VoyaraColors.textSecondary)
                .padding(.horizontal, VoyaraTheme.spacing12)
                .padding(.vertical, VoyaraTheme.spacing6)
                .background(isSelected ? VoyaraColors.primary : VoyaraColors.surfaceVariant)
                .cornerRadius(20)
        }
    }
}

// MARK: - Circular Progress
struct CircularProgressView: View {
    let progress: Double // 0 to 1
    var lineWidth: CGFloat = 8
    var size: CGFloat = 60
    var color: Color = VoyaraColors.primary

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(CGFloat(progress), 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Shimmer modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
