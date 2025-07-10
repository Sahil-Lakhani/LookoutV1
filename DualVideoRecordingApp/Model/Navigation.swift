//
//  NavigationModel.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 26/10/24.
//

import SwiftUI
import SwiftToasts

typealias RouteProtocol = Hashable & View

enum NavigationRoutes: RouteProtocol {
    case recordings
    case settings
    case videoRecordingSettings
    case cameraPreviewSettings
    case storageSettings
    case howToUseIt
//    case watchVideo(MovieMedia)
//    case editVideo(MovieMedia)
    
    var body: some View {
        Group {
            switch self {
            case .recordings:
                WatchRecordings()
            case .settings:
                SettingsView()
            case .videoRecordingSettings:
                VideoRecordingSettingsView()
            case .cameraPreviewSettings:
                CameraPreviewSettingsView()
            case .storageSettings:
                StorageSettingsView()
            case .howToUseIt:
                HowToUseItView()
            }
        }
    }
}

enum ToastIcon: String {
    case warning = "exclamationmark.triangle.fill"
    case success = "checkmark.circle.fill"
}

class NavigationModel: ObservableObject {
    @Published var navPath = [NavigationRoutes]()
    @Published var toasts = [Toast]()
    
    @Published var presentedItem: NavigationRoutes?
    
    var isPresentingItem: Bool {
        get { presentedItem != nil }
        set { presentedItem = nil }
    }
    
    func presentSheet(for route: NavigationRoutes) {
        presentedItem = route
    }
    
    func dismissSheet() {
        presentedItem = nil
    }
    
    func push(to route: NavigationRoutes) {
        if self.navPath.contains(route) { return }
        self.navPath.append(route)
    }
    
    func pop() {
        self.navPath.removeLast()
    }
    
    func goHome() {
        self.navPath.removeAll()
    }
    
    @MainActor
    func showToast(withText text: AttributedString, icon: ToastIcon, shouldRemoveAfter delay: TimeInterval? = nil) {
        let newToast: Toast = .simple(text, systemImage: icon.rawValue)
        
        toasts.append(newToast)
        if let delay {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.toasts.removeAll(where: { $0.id == newToast.id })
            }
        }
    }
}
