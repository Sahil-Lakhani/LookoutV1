import SwiftUI

struct StealthViewiPhoneScreen: View {
    // Binding for overlay mode which drives parent view state.
    @Binding var overlayMode: RecordingView.OverlayMode
    
    @EnvironmentObject var navigationModel: NavigationModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // Determine orientation based on size classes.
    var isPortrait: Bool {
        horizontalSizeClass == .compact && verticalSizeClass == .regular
    }
    
    @State private var isDragging = false
    
    // MARK: - App Data Model
    struct AppItem: Identifiable {
        let id = UUID()
        let title: String
        let imageName: String
        let systemImage: Bool
        let mode: RecordingView.OverlayMode
        let color: Color
    }
    
    // MARK: - Dummy Apps
    let apps: [AppItem] = [
        AppItem(
            title: "Maps",
            imageName: "maps",
            systemImage: false,
            mode: .maps,
            color: .blue
        ),
        AppItem(
            title: "Overlay",
            imageName: "iphone",
            systemImage: true,
            mode: .blackout,
            color: .orange
        )
    ]
    
    // MARK: - Grid Layout
    private var columns: [GridItem] {
        // Four columns for portrait; adapt as needed.
        Array(repeating: GridItem(.flexible(), spacing: 30), count: 4)
    }
    
    // MARK: - Main View
    var body: some View {
        ZStack {
            // Background Image
            Image(.backCam)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Status Bar
                statusBar
                
                // Grid of App Icons
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(apps) { app in
                        AppIconButton(app: app) {
                            withAnimation {
                                overlayMode = app.mode
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                
                Spacer()
                
                // Dock Area with a single Back button
                dockArea
            }
            .gesture(
                LongPressGesture(minimumDuration: 0.3)
                    .onChanged { _ in isDragging = true }
                    .onEnded { _ in isDragging = false }
            )
        }
    }
    
    // MARK: - Status Bar View
    private var statusBar: some View {
        HStack {
            Text(Date(), formatter: timeFormatter)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, 12)
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.50")
            }
            .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
    
    // MARK: - Dock Area View
    private var dockArea: some View {
        HStack(spacing: 20) {
            AppIconButton(
                app: AppItem(
                    title: "",
                    imageName: "xmark.circle.fill",
                    systemImage: true,
                    mode: .none,
                    color: .red
                )
            ) {
                overlayMode = .none
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 15)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 35, style: .continuous)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 25)
    }
    
    // MARK: - Time Formatter
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
}

// MARK: - App Icon Button View
struct AppIconButton: View {
    let app: StealthViewiPhoneScreen.AppItem
    let action: () -> Void
    
    // Determine if there is non-empty text (ignoring whitespace)
    private var hasText: Bool {
        !app.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Return icon height based on the availability of text.
    // Assuming standard icon height is 65.
    // If there’s no text, add extra space (for example, 15 points) to fill the gap.
    private var iconHeight: CGFloat {
        hasText ? 65 : 65 + 10
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                // The icon view uses the computed iconHeight.
                iconView
                    .frame(width: iconHeight, height: iconHeight)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                
                // Only show text if it’s not empty.
                if hasText {
                    Text(app.title)
                        .font(.system(size: 13.25, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.top, 1.5)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(app.color.gradient)
            
            if app.systemImage {
                Image(systemName: app.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(14)
                    .foregroundColor(.white)
            } else {
                Image(app.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
            }
        }
    }
}


@available(iOS 17.0, *)
#Preview {
    @Previewable @State var overlayMode: RecordingView.OverlayMode = .options
    
    ZStack {
        Image(.backCam)
            .resizable()
            .scaledToFill()
        
        StealthViewiPhoneScreen(overlayMode: $overlayMode)
            .environmentObject(NavigationModel())
            .onChange(of: overlayMode) { newValue in
                print("Overlay mode changed to \(newValue)")
            }
    }
}
