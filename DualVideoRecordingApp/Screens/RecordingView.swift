import AVFoundation
import CoreLocation
import Combine
import OSLog
import SwiftUI
import SwiftToasts

fileprivate let logger = Logger(
    subsystem: "com.kidastudios.DualVideoRecordingApp",
    category: "RecordingView"
)

struct RecordingView: View {
    @EnvironmentObject<NavigationModel> var navigationModel
    @EnvironmentObject<AppCameraState> var appCameraState
    
    @StateObject private var vm = ViewModel()
    @StateObject private var speedTracker = SpeedTracker()
    
    @State private var orientation: UIDeviceOrientation = .portrait
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var isPotrait: Bool { orientation.isPortrait }
    var isIPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    
    var body: some View {
        // Use the same layout for both iPhone and iPad for a consistent experience
        VStack {
            topControls
                .onReceive(vm.timer) { _ in
                    self.vm.recordingDuration = appCameraState.recordedDuration
                }
            
            Group {
#if targetEnvironment(simulator)
                Color.gray
                    .ignoresSafeArea()
                    .padding(isPotrait ? .bottom : .trailing, 5)
#else
                GeometryReader { proxy in
                    cameraPreview(previewFrame: proxy.frame(in: .global))
                }
#endif
            }
            .overlay(alignment: .topLeading) {
                HStack {
                    Text(vm.formattedRecordingDuration)
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(.trailing, 2)
                    Circle()
                        .fill(.red)
                        .frame(width: 15, height: 15)
                        .opacity(vm.isRecording ? 1 : 0)
                }
                .padding(.all, 18)
            }
            
            bottomControls
        }
        .overlay(alignment: .center) {
            Group {
                switch vm.currentOverlayMode {
                case .none:
                    EmptyView()
                case .options:
                    // Adding a move transition from the bottom.
                    StealthViewiPhoneScreen(overlayMode: $vm.currentOverlayMode)
                case .maps:
                    MapView(overlayMode: $vm.currentOverlayMode)
                case .blackout:
                    BlackOutModeView(overlayMode: $vm.currentOverlayMode)
                }
            }
            .animation(.easeOut, value: vm.currentOverlayMode)
        }
        .background(.black)
        .interactiveToasts($navigationModel.toasts)
        .onAppear {
            self.orientation = UIDevice.current.orientation
            UIApplication.shared.isIdleTimerDisabled = true
            speedTracker.startLocationTracking()
        }
        .onDisappear(perform: cleanup)
        .onScenePhaseChange { scenePhase in
            switch scenePhase {
            case .active:
                UIApplication.shared.isIdleTimerDisabled = true
                let isRecording = appCameraState.isRecording
                self.vm.isRecording = isRecording
                self.vm.recordingDuration = isRecording ? appCameraState.recordedDuration : 0
            default:
                cleanup()
            }
        }
        // MARK: - Errors from AppCameraState
        .onReceive(appCameraState.$error) { (errorOrNil: CustomError?) in
            guard let error = errorOrNil else { return }
            let isRecording = appCameraState.isRecording
            self.vm.isRecording = isRecording
            self.vm.recordingDuration = isRecording ? appCameraState.recordedDuration : 0
            var text = AttributedString("Error:")
            text.font = .callout.bold()
            text.append(AttributedString("\(error.errorDescription ?? error.description)"))
            self.navigationModel.showToast(
                withText: text,
                icon: .warning,
                shouldRemoveAfter: 1.5
            )
        }
        // MARK: - Errors from SpeedTracker
        .onReceive(speedTracker.$error) { (errorOrNil: MapLocationError?) in
            guard let mapLocError = errorOrNil else { return }
            
            var text = AttributedString("Location Error:")
            text.font = .callout.bold()
            text.append(AttributedString("\(mapLocError.description)"))
            self.navigationModel.showToast(
                withText: text,
                icon: .warning,
                shouldRemoveAfter: 1.5
            )
        }
        .onOrientationChange { (newOrientation: UIDeviceOrientation) in
            withAnimation {
                self.orientation = newOrientation
            }
        }
        .task {
            UIDevice.current.isBatteryMonitoringEnabled = true
            vm.batteryLevel = UIDevice.current.batteryLevel
            
            let batteryPublisher = NotificationCenter
                .default
                .publisher(for: UIDevice.batteryLevelDidChangeNotification)
                .map { _ in UIDevice.current.batteryLevel }
            
            for await batteryLevel in batteryPublisher.values {
                Task { @MainActor in
                    vm.batteryLevel = batteryLevel
                }
            }
        }
//        .task(priority: .background) { [fetchLatestThumbnail = vm.fetchLatestThumbnail] in
//            do {
//                let uiImage = try await fetchLatestThumbnail()
//                await MainActor.run {
//                    vm.latestThumbnail = Image(uiImage: uiImage)
//                }
//            } catch {
//                logger.error("\(error)")
//            }
//        }
        .overlay(alignment: .bottom) {
            if vm.isRecording {
                // You can adjust the alignment as needed; here, it's centered.
                RecordingIndicatorView()
                    .padding(.bottom, 100) // adjust the padding to position it appropriately
//                    .padding(.leading, 15)
            }
        }
    }
    
//    var flashButton: some View {
//        Button {
//            // Haptic feedback for flash toggle.
//            let generator = UIImpactFeedbackGenerator(style: .medium)
//            generator.impactOccurred()
//            vm.toggleTorch(appCameraState: appCameraState)
//        } label: {
//            let height = 25.0
//            if vm.isTorchOn {
//                Image("custom.bolt.circle")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: height, height: height)
//            } else {
//                Image("custom.bolt.circle.slash")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: height, height: height)
//            }
//        }
//    }
    
    var topControls: some View {
        HStack {
//            SpeedometerText(speedTracker: speedTracker)
            BatteryIndicatorIcon(batteryLevel: vm.batteryLevel)
            Spacer()
            Button {
                guard !vm.isRecording else { return }
                navigationModel.presentSheet(for: .settings)
            } label: {
                let audioInfo: LocalizedStringKey = appCameraState.isAudioDeviceEnabled ? "~~MUTE~~" : "MUTE"
                RecordingInfoText(
                    orientationText: isPotrait ? "PORTRAIT" : "LANDSCAPE",
                    formattedResolution: appCameraState.formattedResolution,
                    frameRate: appCameraState.frameRate,
                    audioInfo: audioInfo
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
    }
    
    var bottomControls: some View {
        HStack {
            HStack(spacing: 15) {
                let landscapeRotationAngle = { () -> Angle in
                    switch orientation {
                    case .portraitUpsideDown:
                        return .degrees(180)
                    case .landscapeLeft:
                        return .degrees(90)
                    case .landscapeRight:
                        return .degrees(-90)
                    default:
                        return .zero
                    }
                }
                
                IconButton(
                    "Options",
                    forMode: .options,
                    with: "lookOutAppIcon",
                    isSystemImage: false,
                    vm: vm
                )
                .rotationEffect(landscapeRotationAngle())
                
                GalleryButton(
                    navigationModel: navigationModel,
                    latestThumbnail: vm.latestThumbnail,
                    isRecording: vm.isRecording
                )
                .rotationEffect(landscapeRotationAngle())
            }
            
            Spacer()
            
            RecordButton(isRecording: vm.isRecording) {
                // Haptic feedback when toggling recording.
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
                vm.toggleRecording(appCameraState)
            }
        }
        .tint(.black)
        .labelStyle(.iconOnly)
        .padding(.horizontal)
        .padding(.vertical, 15)
    }
    
    @ViewBuilder
    func cameraPreview(previewFrame: CGRect) -> some View {
        if appCameraState.isCameraActive {
            RecordingViewPreview(previewFrame: previewFrame) {
                vm.toggleRecording(appCameraState)
            } doubleTap: {
                captureScreen()
            }
        } else {
            Color.black
        }
    }
    fileprivate struct ScreenshotSavedIndicatorView: View {
        var body: some View {
            HStack {
                Circle()
                    .frame(width: 15.5, height: 12.5)
                    .foregroundColor(.green)
                Text("Screenshot Saved")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 6.5)
            .padding(.horizontal, 18)
        }
    }

    
    func captureScreen() {
        // Haptic feedback for screen capture
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        print("Screenshot saved")

        appCameraState.captureScreen { errorOrNil in
            Task { @MainActor in
                guard errorOrNil == nil else {
                    print("Error capturing screenshot: \(errorOrNil?.description ?? "Unknown error")")
                    return
                }

                // Display the Screenshot Saved UI temporarily
                let overlay = ScreenshotSavedIndicatorView()
                    .frame(width: 250, height: 50)
                    .background(.ultraThinMaterial)
                    .cornerRadius(100)
                    .shadow(radius: 5)

                // Add the overlay to the window
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    let overlayView = UIHostingController(rootView: overlay)
                    overlayView.view.backgroundColor = .clear
                    overlayView.view.frame = CGRect(
                        x: (window.bounds.width - 200) / 2,
                        y: window.bounds.height * 0.9,
                        width: 200,
                        height: 50
                    )
                    overlayView.view.alpha = 0.0 // Start invisible
                    window.addSubview(overlayView.view)

                    // Fade in the overlay
                    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                        overlayView.view.alpha = 1.0
                    }, completion: nil)

                    // Fade out and remove the overlay after 1.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                            overlayView.view.alpha = 0.0
                        }, completion: { _ in
                            overlayView.view.removeFromSuperview()
                        })
                    }
                }
            }
        }
    }


    
//    func captureScreen() {
//        // Haptic feedback for screen capture.
//        let generator = UIImpactFeedbackGenerator(style: .light)
//        generator.impactOccurred()
//        print("ss saved")
//        appCameraState.captureScreen { errorOrNil in
//            Task { @MainActor in
//                self.navigationModel.showToast(
//                    withText: AttributedString(
//                        errorOrNil?.description ?? "Screenshot Captured"
//                    ),
//                    icon: errorOrNil == nil ? .success : .warning,
//                    shouldRemoveAfter: 1,
//                )
//            }
//        }
//    }
    
    func cleanup() {
        UIApplication.shared.isIdleTimerDisabled = false
        self.speedTracker.stopLocationTracking()
        vm.isRecording = appCameraState.isRecording
        self.vm.recordingDuration = appCameraState.isRecording ? appCameraState.recordedDuration : 0
    }
}

extension RecordingView {
    enum OverlayMode: Equatable {
        case none
        case options
        case blackout
        case maps
    }
    
    final class SpeedTracker: NSObject, ObservableObject, CLLocationManagerDelegate, @unchecked Sendable {
        let unit: Unit = .kilometersPerHour
        
        @Published var speed: Double = 0.0
        @Published var authorizationStatue: CLAuthorizationStatus = .notDetermined
        @Published var error: MapLocationError?
        
        private let locationManager = CLLocationManager()
        
        override init() {
            super.init()
            locationManager.delegate = self
        }
        
        var speedDescription: String {
            "\(unit.localizedString(for: speed)) \(unit.description)"
        }
        
        private func setSpeed(speedProvidedByDevice: Double) {
            Task { @MainActor in
                speed = unit.calculateSpeed(for: speedProvidedByDevice)
            }
        }
        
        func startLocationTracking() {
            switch locationManager.authorizationStatus {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            default:
                locationManager.startUpdatingLocation()
            }
        }
        
        func stopLocationTracking() {
            locationManager.stopUpdatingLocation()
        }
        
        // MARK: - CLLocationManagerDelegate
        nonisolated func locationManager(
            _ manager: CLLocationManager,
            didUpdateLocations locations: [CLLocation]
        ) {
            guard let latestLocation = locations.last else { return }
            setSpeed(speedProvidedByDevice: latestLocation.speed)
        }
        
        nonisolated func locationManager(
            _ manager: CLLocationManager,
            didFailWithError error: any Error
        ) {
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    Task { @MainActor in
                        self.error = .permissionDenied
                    }
                default:
                    logger.error("CoreLocation Error: \(clError.localizedDescription)")
                    Task { @MainActor in
                        self.error = .custom(clError.localizedDescription)
                    }
                }
                return
            }
            logger.error("CoreLocation Error: \(error.localizedDescription)")
        }
        
        nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            let authorizationStatus = manager.authorizationStatus
            Task { @MainActor in
                self.authorizationStatue = authorizationStatus
            }
            Task { @MainActor in
                switch authorizationStatus {
                case .denied, .restricted:
                    logger.error("Location access denied")
                    error = .locationServicesDisabled
                case .notDetermined:
                    logger.warning("Unexpected case")
                default:
                    logger.info("Location services are available")
                    manager.startUpdatingLocation()
                }
            }
        }
    }
    
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var isRecording: Bool = false
        @Published var isTorchOn: Bool = false
        
        @Published var timer = ViewModel.createTimer()
        @Published var timerHandler: Cancellable?
        
        @Published var recordingDuration: TimeInterval = 0
        @Published var recordDate: Date?
        @Published var currentOverlayMode: OverlayMode = .none
        @Published var latestThumbnail: Image?
        @Published var batteryLevel: Float = 0.51
        
        var formattedRecordingDuration: String {
            ViewModel.formatter(recordingDuration)
        }
        
        func toggleRecording(_ appCameraState: AppCameraState) {
        #if targetEnvironment(simulator)
            withAnimation {
                isRecording.toggle()
            }
        #else
            if appCameraState.isRecording {
                appCameraState.stopRecording()
                withAnimation { isRecording = false }

                // ✅ Fetch thumbnail after recording ends
                Task {
                    do {
                        let uiImage = try await fetchLatestThumbnail()
                        await MainActor.run {
                            self.latestThumbnail = Image(uiImage: uiImage)
                        }
                    } catch {
                        logger.error("Thumbnail Fetch Error: \(error)")
                    }
                }

            } else {
                appCameraState.startRecording()
                withAnimation { isRecording = true }
            }
        #endif
            if let timerHandler {
                timerHandler.cancel()
                self.timerHandler = nil
            } else {
                timer = ViewModel.createTimer()
                timerHandler = timer.connect()
            }

            withAnimation(.spring) {
                self.recordingDuration = 0
            }
        }
        
        func toggleTorch(appCameraState: AppCameraState) {
#if targetEnvironment(simulator)
            withAnimation {
                isTorchOn.toggle()
            }
#else
            do {
                guard let camera = appCameraState.backCamera, camera.hasTorch else {
                    throw CustomError.custom(message: "No back camera or no torch")
                }
                try camera.lockForConfiguration()
                switch camera.torchMode {
                case .off:
                    camera.torchMode = .on
                    withAnimation { isTorchOn = true }
                case .on:
                    camera.torchMode = .off
                    withAnimation { isTorchOn = false }
                default:
                    break
                }
                camera.unlockForConfiguration()
            } catch {
                logger.error("\(error)")
            }
#endif
        }
        
        func fetchLatestThumbnail() async throws -> UIImage {
            let fm = FileManager.default
            let items = try fm.contentsOfDirectory(
                at: URL.documentsDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            let movies = try items
                .filter { $0.pathExtension.lowercased() == "mov" }
                .sorted { (url1, url2) in
                    let value1 = try? url1.resourceValues(forKeys: [.creationDateKey])
                    let date1 = value1?.creationDate ?? .now
                    
                    let value2 = try? url2.resourceValues(forKeys: [.creationDateKey])
                    let date2 = value2?.creationDate ?? .now
                    return date1.compare(date2) == .orderedDescending
                }
            
            guard let latestMovie = movies.first else {
                throw CustomError.custom(message: "No movies found")
            }
            
            return try await AVFrameGrabber.makeThumbnail(forURL: latestMovie)
        }
        
        static func formatter(_ timeIntervalInSeconds: TimeInterval) -> String {
            let hours = Int(timeIntervalInSeconds / 3600)
            let hoursString = hours < 10 ? "0\(hours)" : hours.description
            
            let minutes = Int(timeIntervalInSeconds.truncatingRemainder(dividingBy: 3600) / 60)
            let minutesString = minutes < 10 ? "0\(minutes)" : minutes.description
            
            let seconds = Int(timeIntervalInSeconds.truncatingRemainder(dividingBy: 60))
            let secondsString = seconds < 10 ? "0\(seconds)" : seconds.description
            
            return "\(hoursString):\(minutesString):\(secondsString)"
        }
        
        static func createTimer() -> Timer.TimerPublisher {
            Timer.publish(every: 1, on: .main, in: .default)
        }
    }
}

fileprivate struct RecordingInfoText: View {
    let orientationText: String
    let formattedResolution: String
    let frameRate: Int
    let audioInfo: LocalizedStringKey
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "lock.fill")
            Text(" \(orientationText)")
            Text(" · ")
            Text(formattedResolution)
            Text(" · ")
            Text("\(frameRate) FPS")
            Text(" · ")
            Text(audioInfo)
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundStyle(.white.opacity(0.75))
    }
}

fileprivate struct SpeedometerText: View {
    @ObservedObject var speedTracker: RecordingView.SpeedTracker
    
    var body: some View {
        Label(
            speedTracker.speedDescription,
            systemImage: "gauge.with.dots.needle.67percent"
        )
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundStyle(.white.opacity(0.75))
        .labelStyle(.custom(spacing: 2.5))
    }
}

fileprivate struct BatteryIndicatorIcon: View {
    let batteryLevel: Float
    
    var body: some View {
        Label {
            Text(batteryLevel, format: .percent.precision(.fractionLength(0)))
        } icon: {
            switch (batteryLevel * 100) {
            case 0.0..<25:
                Image(systemName: "battery.0percent")
            case 25..<50:
                Image(systemName: "battery.25percent")
            case 50..<75:
                Image(systemName: "battery.50percent")
            case 75..<100:
                Image(systemName: "battery.75percent")
            default:
                Image(systemName: "battery.100percent")
            }
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundStyle(.white.opacity(0.75))
        .opacity(batteryLevel < 0.01 ? 0.0 : 1)
        .labelStyle(.custom(spacing: 2.5))
    }
}

fileprivate struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            // Haptic feedback has been triggered in the button action.
            action()
        } label: {
            let outerCircleSize: CGFloat = 90
            let innerCircleSize: CGFloat = outerCircleSize - 15
            Image(systemName: isRecording ? "stop.fill" : "circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: innerCircleSize, height: innerCircleSize)
                .scaleEffect(isRecording ? 0.75 : 1)
                .animation(.snappy, value: isRecording)
                .background {
                    Circle()
                        .stroke(lineWidth: 2.5)
                        .fill(.white.opacity(0.25))
                        .frame(width: outerCircleSize, height: outerCircleSize)
                }
                .padding(.trailing, 10)
        }
        .tint(Color.recordingRed)
        .buttonStyle(BorderlessButtonStyle())
    }
}

fileprivate struct GalleryButton: View {
    @ObservedObject var navigationModel: NavigationModel
    let latestThumbnail: Image?
    let isRecording: Bool
    
    var body: some View {
        Button {
            guard !isRecording else { return }
            navigationModel.push(to: .recordings)
        } label: {
            let radius: CGFloat = 52
            let cornerRadius: CGFloat = 50

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(lineWidth: 1.25)
                .fill(Color.white.opacity(1))
                .frame(width: radius, height: radius)
                .overlay {
                    if let thumbnail = latestThumbnail {
                        thumbnail
                            .resizable()
                            .scaledToFill()
                            .frame(width: radius - 5, height: radius - 5)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    } else {
                        Image(systemName: "folder.fill")
                            .font(.headline)
                    }
                }
        }
        .accessibilityLabel("Gallery")
        .tint(.white)
        .font(.system(size: 36, weight: .regular))
        .allowsHitTesting(!isRecording)
        .opacity(isRecording ? 0.0 : 1)
    }
}

//reeeecording
fileprivate struct RecordingIndicatorView: View {
    @State private var animate = false

    var body: some View {
        HStack{
            Circle()
                .frame(width: 12.5, height: 12.5)
                .foregroundColor(Color.red)
            Text("Recording")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(.vertical, 6.5)
        .padding(.horizontal, 18)
        .background(.ultraThinMaterial)
        .cornerRadius(100)
        .scaleEffect(animate ? 1.05 : 0.90)
        .animation(
            Animation.easeInOut(duration: 1)
            .repeatForever(autoreverses: true),
            value: animate
        )
        .onAppear {
            self.animate = true
        }
    }
}


fileprivate struct IconButton: View {
    let title: LocalizedStringKey
    let icon: String
    let isSystemImage: Bool
    let overlayMode: RecordingView.OverlayMode
    
    @ObservedObject var vm: RecordingView.ViewModel
    
    init(
        _ title: LocalizedStringKey,
        forMode overlayMode: RecordingView.OverlayMode,
        with icon: String,
        isSystemImage: Bool = true,
        vm: RecordingView.ViewModel
    ) {
        self.title = title
        self.icon = icon
        self.overlayMode = overlayMode
        self.isSystemImage = isSystemImage
        self.vm = vm
    }
    
    var body: some View {
        Button {
            withAnimation {
                vm.currentOverlayMode = overlayMode
            }
        } label: {
            if isSystemImage {
                Label(title, systemImage: icon)
                    .font(.system(size: 36, weight: .regular))
            } else {
                Label {
                    Text(title)
                } icon: {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 53)
                }
            }
        }
        .accessibilityLabel(title)
        .tint(.white)
        .labelStyle(.iconOnly)
    }
}

fileprivate struct RecordingViewPreview: View {
    let previewFrame: CGRect
    
    let toggleRecording: () -> Void
    let doubleTap: () -> Void
    
    @EnvironmentObject<AppCameraState> private var appCameraState
    @AppStorage(Constants.cameraPreviewKey.description) private var cameraPreviewString: String = "one"
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var isIPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    
    var body: some View {
        ZStack {
            switch cameraPreview {
            case .one:
                if isIPad {
                    iPadOneLayout
                } else {
                    backCamPreview
                        .overlay(alignment: .topTrailing) {
                            frontCamPreview
                                .padding([.top, .trailing], 15)
                        }
                }
            case .two:
                if isIPad {
                    iPadTwoLayout
                } else {
                    VStack(alignment: .center, spacing: 2.5) {
                        backCamPreview
                        frontCamPreview
                    }
                }
            case .three:
                if isIPad {
                    iPadThreeLayout
                } else {
                    VStack {
                        backCamPreview
                            .padding([.top, .trailing], 75)
                    }
                    .overlay(alignment: .topTrailing) {
                        frontCamPreview
                    }
                }
            }
        }
        .ignoresSafeArea(.all, edges: .horizontal)
    }
    
    private var iPadOneLayout: some View {
            backCamPreview
            .overlay(alignment: .topTrailing) {
            frontCamPreview
                    .padding([.top, .trailing], 15)
        }
    }
    
    private var iPadTwoLayout: some View {
        VStack(alignment: .center, spacing: 2.5) {
            backCamPreview
            frontCamPreview
        }
    }
    
    private var iPadThreeLayout: some View {
        VStack {
            backCamPreview
                .padding([.top, .trailing], 75)
        }
        .overlay(alignment: .topTrailing) {
            frontCamPreview
        }
    }
    
    var cameraPreview: CameraPreview {
        CameraPreview(rawValue: cameraPreviewString) ?? .one
    }
    
    var backCamPreview: some View {
        PreviewLayerView(
            appCameraState.session,
            with: appCameraState.backPreviewLayer,
            in: previewFrame
        ) { (d: UISwipeGestureRecognizer.Direction) in
            switch d {
            case .up:
                logger.info("Swipe direction: up")
            case .down:
                logger.info("Swipe direction: down")
            case .left:
                logger.info("Swipe direction: left")
            case .right:
                logger.info("Swipe direction: right")
            default:
                logger.info("Swipe direction: none")
            }
            toggleRecording()
        } onDoubleTap: {
            doubleTap()
        }
        .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
    }
    
    @ViewBuilder
    var frontCamPreview: some View {
        switch cameraPreview {
        case .one:
            let frontPreviewFrame = isIPad ? 
                CGRect(x: 0, y: 0, width: previewFrame.width * 0.35, height: previewFrame.height * 0.45) :
                CGRect(x: 0, y: 0, width: previewFrame.width / 2.5, height: previewFrame.height / 2.5)
            PreviewLayerView(
                appCameraState.session,
                with: appCameraState.frontPreviewLayer,
                in: frontPreviewFrame
            )
            .frame(width: frontPreviewFrame.width, height: frontPreviewFrame.height)
            .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
        case .two:
            PreviewLayerView(
                appCameraState.session,
                with: appCameraState.frontPreviewLayer,
                in: previewFrame
            )
            .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
        case .three:
            let frontPreviewFrame = isIPad ?
                CGRect(x: 0, y: 0, width: previewFrame.width * 0.3, height: previewFrame.height * 0.3) :
                CGRect(x: 0, y: 0, width: previewFrame.width * 0.5, height: previewFrame.height * 0.5)
            PreviewLayerView(
                appCameraState.session,
                with: appCameraState.frontPreviewLayer,
                in: frontPreviewFrame
            )
            .frame(width: frontPreviewFrame.width, height: frontPreviewFrame.height)
            .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
        }
    }
}

#Preview {
    RecordingView()
        .environmentObject(AppCameraState())
        .environmentObject(NavigationModel())
}
