//
//  DualVideoRecordingAppApp.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 26/10/24.
//

import SwiftUI

@main
struct DualVideoRecordingAppApp: App {
    @StateObject var navigationModel = NavigationModel()
    @StateObject var appCameraState = AppCameraState()
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if !hasSeenWelcome {
                WelcomeView()
                    .environmentObject(navigationModel)
                    .environmentObject(appCameraState)
                    .onDisappear {
                        hasSeenWelcome = true
                    }
            } else {
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
}
