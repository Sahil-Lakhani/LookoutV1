import SwiftUI

struct StealthViewiPhoneScreen: View {
    @Binding var overlayMode: RecordingView.OverlayMode

    @EnvironmentObject var navigationModel: NavigationModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

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
        AppItem(title: "Maps", imageName: "maps", systemImage: false, mode: .maps, color: .blue),
        AppItem(title: "Overlay", imageName: "iphone", systemImage: true, mode: .blackout, color: .orange)
    ]

    // MARK: - Grid Layout
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: isPad ? 40 : 30), count: isPad ? 5 : 4)
    }

    // MARK: - Main View
    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 0) {
                statusBar
                appGrid
                Spacer()
                dockArea
            }
            .gesture(
                LongPressGesture(minimumDuration: 0.3)
                    .onChanged { _ in isDragging = true }
                    .onEnded { _ in isDragging = false }
            )
        }
    }

    // MARK: - Background View
    private var backgroundView: some View {
        Group {
            if isPad {
                Image("ipad")
                    .resizable()
            } else {
                Image(.backCam)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
    }

    // MARK: - Status Bar View
    private var statusBar: some View {
        HStack {
            Text(Date(), formatter: timeFormatter)
                .font(.system(size: isPad ? 14 : 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, 12)

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "wifi")
                Image(systemName: "battery.50")
            }
            .font(.system(size: isPad ? 12 : 16))
            .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, isPad ? 12 : 6)
    }

    // MARK: - App Grid
    private var appGrid: some View {
        LazyVGrid(columns: columns, spacing: isPad ? 10 : 20) {
            ForEach(apps) { app in
                appButton(for: app)
            }
        }
        .padding(.horizontal, isPad ? 100 : 20)
        .padding(.top, isPad ? 65 : 40)
    }

    private func appButton(for app: AppItem) -> some View {
        AppIconButton(app: app, isPad: isPad) {
            withAnimation {
                overlayMode = app.mode
            }
        }
    }

    // MARK: - Dock Button View
    struct DockButton: View {
        let app: StealthViewiPhoneScreen.AppItem
        let size: CGFloat
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                        .fill(app.color)
                        .frame(width: size, height: size)

                    if app.systemImage {
                        Image(systemName: app.imageName)
                            .resizable()
                            .scaledToFit()
                            .padding(size * 0.2)
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }


    
    // MARK: - Dock Area View
    private var dockArea: some View {
        HStack(spacing: isPad ? 60 : 20) {
            DockButton(
                app: AppItem(
                    title: "",
                    imageName: "xmark.circle.fill",
                    systemImage: true,
                    mode: .none,
                    color: .red
                ),
                size: isPad ? 64 : 56 // Adjust size for iPad and iPhone
            ) {
                overlayMode = .none
            }
        }
        .frame(maxWidth: isPad ? 405 : .infinity, maxHeight: isPad ? 75 : 65)
        .padding(.horizontal, isPad ? 50 : 24)
        .padding(.vertical, isPad ? 10 : 15)
        .background(
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(isPad ? 0.7 : 0.9)
        )
        .padding(.horizontal, isPad ? 30 : 16)
        .padding(.bottom, isPad ? 0 : 25)
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

    private var hasText: Bool {
        !app.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var iconHeight: CGFloat {
        if isPad {
            return hasText ? 62 : 100
        } else {
            return hasText ? 65 : 75
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: isPad ? 10 : 5) {
                iconView
                    .frame(width: iconHeight, height: iconHeight)
                    .shadow(color: .black.opacity(0.3), radius: isPad ? 6 : 3, x: 0, y: isPad ? 3 : 2)

                if hasText {
                    Text(app.title)
                        .font(.system(size: isPad ? 12 : 13.25, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.top, isPad ? 0 : 1.5)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var iconView: some View {
        if app.systemImage {
        ZStack {
                RoundedRectangle(cornerRadius: isPad ? 15 : 16, style: .continuous)
                .fill(app.color.gradient)

                
                Image(systemName: app.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(isPad ? 18 : 14)
                    .foregroundColor(.white)
            }
            }
            else {
                Image(app.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(
                        RoundedRectangle(cornerRadius: isPad ? 2 : 16, style: .continuous)
                    )
                    .padding(isPad ? 0 : 0)
            }
        }
    }

