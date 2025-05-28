import SwiftUI

struct StealthViewiPhoneScreen: View {
    // Binding for overlay mode which drives parent view state.
    @Binding var overlayMode: RecordingView.OverlayMode
    
    @EnvironmentObject var navigationModel: NavigationModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    
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
//            color: .black.opacity(0/100)
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
        if isPad {
            // Fewer columns with better spacing for iPad
            return Array(repeating: GridItem(.flexible(), spacing: 40), count: 4)
        } else {
            // Four columns for portrait; adapt as needed.
            return Array(repeating: GridItem(.flexible(), spacing: 30), count: 4)
        }
    }
    
    // MARK: - Main View
    var body: some View {
        ZStack {
            // Background Image - Use different images for iPad and iPhone
            Group {
                if isPad {
                    Image("ipad")
                        .resizable()
//                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(.backCam)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom Status Bar
                statusBar
                
                // Grid of App Icons
                LazyVGrid(columns: columns, spacing: isPad ? 8 : 20) {
                    ForEach(apps) { app in
                        AppIconButton(app: app, isPad: isPad) {
                            withAnimation {
                                overlayMode = app.mode
                            }
                        }
                    }
                }
                .padding(.horizontal, isPad ? 120 : 20)
                .padding(.top, isPad ? 32 : 40)
                
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
                .font(.system(size: isPad ? 24 : 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, 12)
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.50")
            }
            .font(.system(size: isPad ? 20 : 16))
            .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, isPad ? 12 : 6)
    }
    
    // MARK: - Dock Area View
    private var dockArea: some View {
        HStack(spacing: isPad ? 60 : 20) {
            AppIconButton(
                app: AppItem(
                    title: "",
                    imageName: "xmark.circle.fill",
                    systemImage: true,
                    mode: .none,
                    color: .red
                ),
                isPad: isPad
            ) {
                overlayMode = .none
            }
        }
        .frame(maxWidth: isPad ? 600 : .infinity, maxHeight: isPad ? 80 : 65)
        .padding(.horizontal, isPad ? 50 : 24)
        .padding(.vertical, isPad ? 30 : 15)
        .background(
                RoundedRectangle(cornerRadius: isPad ? 35 : 35, style: .continuous)
                    .fill(.ultraThinMaterial) // Use translucent material
                    .opacity(isPad ? 0.7 : 0.9) // Adjust opacity for translucency
            )        .padding(.horizontal, isPad ? 30 : 16)
        .padding(.bottom, isPad ? 40 : 25)
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
    let isPad: Bool
    let action: () -> Void
    
    // Determine if there is non-empty text (ignoring whitespace)
    private var hasText: Bool {
        !app.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Return icon height based on the availability of text and device type.
    private var iconHeight: CGFloat {
        if isPad {
            return hasText ? 72 : 100
        } else {
            return hasText ? 65 : 75
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: isPad ? 10 : 5) {
                // The icon view uses the computed iconHeight.
                iconView
                    .frame(width: iconHeight, height: iconHeight)
                    .shadow(color: .black.opacity(0.3), radius: isPad ? 6 : 3, x: 0, y: isPad ? 3 : 2)
                
                // Only show text if it's not empty.
                if hasText {
                    Text(app.title)
                        .font(.system(size: isPad ? 18 : 13.25, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.top, isPad ? 3 : 1.5)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: isPad ? 22 : 16, style: .continuous)
                .fill(app.color.gradient)
            
            if app.systemImage {
                Image(systemName: app.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(isPad ? 18 : 14)
                    .foregroundColor(.white)
            } else {
                Image(app.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(
                        RoundedRectangle(cornerRadius: isPad ? 22 : 16, style: .continuous)
                    )
                    .padding(isPad ? 8 : 0)
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
