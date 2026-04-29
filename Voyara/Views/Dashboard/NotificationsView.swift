import SwiftUI

// MARK: - Notifications View
struct NotificationsView: View {
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @State private var showingFilter = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HeaderView(title: "Notifications")
                    
                    ScrollView {
                        VStack(spacing: VoyaraTheme.spacing12) {
                            if notificationViewModel.notifications.isEmpty {
                                EmptyNotificationsState()
                            } else {
                                // Mark all as read button
                                if notificationViewModel.unreadCount > 0 {
                                    Button(action: { notificationViewModel.markAllAsRead() }) {
                                        Text("Mark all as read")
                                            .font(VoyaraTypography.labelMedium)
                                            .foregroundColor(VoyaraColors.primary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.horizontal, VoyaraTheme.spacing24)
                                    .padding(.top, VoyaraTheme.spacing16)
                                }
                                
                                ForEach(notificationViewModel.notifications) { notification in
                                    NotificationRow(
                                        notification: notification,
                                        onDelete: { notificationViewModel.deleteNotification(notification) },
                                        onMarkRead: { notificationViewModel.markAsRead(notification) }
                                    )
                                    .padding(.horizontal, VoyaraTheme.spacing24)
                                }
                            }
                        }
                        .padding(.vertical, VoyaraTheme.spacing24)
                    }
                }
            }
        }
    }
}

// MARK: - Empty Notifications State
struct EmptyNotificationsState: View {
    var body: some View {
        VoyaraCard {
            VStack(spacing: VoyaraTheme.spacing16) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 40))
                    .foregroundColor(VoyaraColors.primary.opacity(0.5))
                
                VStack(spacing: VoyaraTheme.spacing8) {
                    Text("No Notifications")
                        .font(VoyaraTypography.headlineSmall)
                        .foregroundColor(VoyaraColors.text)
                    
                    Text("You're all caught up!")
                        .font(VoyaraTypography.bodyMedium)
                        .foregroundColor(VoyaraColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(VoyaraTheme.spacing32)
        }
        .padding(VoyaraTheme.spacing24)
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification
    let onDelete: () -> Void
    let onMarkRead: () -> Void
    
    var body: some View {
        VoyaraCard {
            HStack(spacing: VoyaraTheme.spacing12) {
                VStack {
                    Image(systemName: notification.type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(VoyaraColors.primary)
                        .frame(width: 36, height: 36)
                        .background(
                            notification.isRead ?
                            VoyaraColors.surfaceVariant :
                            VoyaraColors.primary.opacity(0.1)
                        )
                        .cornerRadius(VoyaraTheme.mediumRadius)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                    HStack {
                        Text(notification.title)
                            .font(VoyaraTypography.bodyMedium)
                            .foregroundColor(VoyaraColors.text)
                            .fontWeight(notification.isRead ? .regular : .semibold)
                        
                        if !notification.isRead {
                            Circle()
                                .fill(VoyaraColors.primary)
                                .frame(width: 8, height: 8)
                        }
                        
                        Spacer()
                    }
                    
                    Text(notification.message)
                        .font(VoyaraTypography.bodySmall)
                        .foregroundColor(VoyaraColors.textSecondary)
                        .lineLimit(2)
                    
                    Text(notification.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(VoyaraTypography.labelSmall)
                        .foregroundColor(VoyaraColors.textSecondary.opacity(0.7))
                }
                
                Spacer()
                
                Menu {
                    if !notification.isRead {
                        Button(action: onMarkRead) {
                            Label("Mark as Read", systemImage: "checkmark")
                        }
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(VoyaraColors.textSecondary)
                }
            }
        }
    }
}

#Preview {
    NotificationsView()
        .environmentObject(NotificationViewModel())
}
