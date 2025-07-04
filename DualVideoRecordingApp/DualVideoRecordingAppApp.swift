//
//  DualVideoRecordingAppApp.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 26/10/24.
//

// import SwiftUI
// import WatchConnectivity

// @main
// struct DualVideoRecordingAppApp: App {
//     @StateObject private var navigationModel = NavigationModel()
//     @StateObject private var appCameraState = AppCameraState()
//     @StateObject private var connectivityManager = ConnectivityManager.shared
//     @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = true
    
//     init() {
//         // Initialize the shared connectivity manager
//         _ = ConnectivityManager.shared
//     }
    
//     var body: some Scene {
//         WindowGroup {
//             if !hasSeenWelcome {
//                 WelcomeView()
//                     .environmentObject(navigationModel)
//                     .environmentObject(appCameraState)
//                     .environmentObject(connectivityManager)
//                     .onDisappear {
//                         hasSeenWelcome = true
//                     }
//             } else {
//                 NavigationStack(path: $navigationModel.navPath) {
//                     ContentView()
//                         .navigationDestination(for: NavigationRoutes.self) { $0 }
//                 }
//                 .sheet(isPresented: $navigationModel.isPresentingItem) {
//                     navigationModel.presentedItem?
//                         .interactiveDismissDisabled(false)
//                         .presentationDragIndicator(.hidden)
//                 }
//                 .environmentObject(appCameraState)
//                 .environmentObject(navigationModel)
//                 .environmentObject(connectivityManager)
//                 .preferredColorScheme(.dark)
//                 .task {
//                     // Initialize camera and connect to connectivity manager
//                     if await appCameraState.checkAndRequestAccess() {
//                         appCameraState.startSession()
//                     }
                    
//                     UserDefaults.standard.register(
//                         defaults: [
//                             Constants.frameRateKey.description: 30,
//                             Constants.isHDKey.description: true,
//                             Constants.isAudioEnabledKey.description: true,
//                             Constants.cameraPreviewKey.description: CameraPreview.one.rawValue,
//                             Constants.videoStabilizationMode.description: false,
//                         ]
//                     )
//                 }
//             }
//         }
//     }
// }


import SwiftUI
import WatchConnectivity

@main
struct DualVideoRecordingAppApp: App {
    @StateObject var navigationModel = NavigationModel()
    @StateObject var appCameraState = AppCameraState()
    @StateObject private var connectivityManager = ConnectivityManager.shared
    
    init() {
        // Initialize the shared connectivity manager
        _ = ConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationModel.navPath) {
                ContentView()
                    .navigationDestination(for: NavigationRoutes.self) { $0 }
            }
            .sheet(isPresented: $navigationModel.isPresentingItem) {
                navigationModel.presentedItem?
                    .interactiveDismissDisabled(false)
                    .presentationDragIndicator(.hidden)
            }
            .environmentObject(appCameraState)
            .environmentObject(navigationModel)
            .preferredColorScheme(.dark)
            .onAppear {
                UserDefaults.standard.register(
                    defaults: [
                        Constants.frameRateKey.description: 30,
                        Constants.isHDKey.description: true,
                        Constants.isAudioEnabledKey.description: true,
                        Constants.cameraPreviewKey.description: CameraPreview.one.rawValue,
                        Constants.videoStabilizationMode.description: false,
                    ]
                )
            }
        }
    }
}
