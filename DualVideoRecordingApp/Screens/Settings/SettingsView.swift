//
//  SettingsView.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 19/12/24.
//

import AVFoundation
import SwiftUI

struct SettingsView: View {
    @StateObject private var navigationModel = NavigationModel()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background layer with an ultra-thin material effect.
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            NavigationStack(path: $navigationModel.navPath) {
                Form {
                    Section {
                        LabelledNavigationLink(
                            route: .videoRecordingSettings,
                            title: "Video Recording",
                            subTitle: "Adjust video recording settings",
                            icon: Image(systemName: "video.fill")
                                .font(.title2)
                                .foregroundStyle(.gray.gradient)
                        )
                        
                        LabelledNavigationLink(
                            route: .cameraPreviewSettings,
                            title: "Camera Preview",
                            subTitle: "Adjust camera preview layout",
                            icon: Image(systemName: "rectangle.3.group.fill")
                                .font(.title2)
                                .foregroundStyle(.gray.gradient)
                        )
                        
                        LabelledNavigationLink(
                            route: .storageSettings,
                            title: "Storage",
                            subTitle: "Check storage status",
                            icon: Image(systemName: "folder.fill")
                                .font(.title2)
                                .foregroundStyle(.gray.gradient)
                        )
                    }
                    //                header: {
                    //                    Text("Settings".uppercased())
                    //                        .font(.headline)
                    //                        .fontWeight(.bold)
                    //                        .fontDesign(.rounded)
                    //                        .padding(.bottom, 5)
                    //                }
                    
                    //                AppDebugSection()
                }
                .tint(.gray)
                .navigationTitle("Settings".uppercased())
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: NavigationRoutes.self) { $0 }
            }
        }
    }
}

fileprivate struct AppDebugSection: View {
    @EnvironmentObject<AppCameraState> private var appCameraState
    
    @State private var deviceNames: [String] = []
    @State private var multicamDeviceNames: [[String]] = []
    
    var body: some View {
        Group {
            Section {
                VStack(alignment: .leading) {
                    Text("Is back camera present?")
                        .font(.headline)
                    
                    Text("\(appCameraState.backCamera == nil ? "No" : "Yes")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Name: \(appCameraState.backCamera?.localizedName ?? "No Camera")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text("Is front camera present?")
                        .font(.headline)
                    
                    Text("\(appCameraState.frontCamera == nil ? "No" : "Yes")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Name: \(appCameraState.frontCamera?.localizedName ?? "No Camera")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text("Is Multicam supported?")
                        .font(.headline)
                    
                    Text("\(AVCaptureMultiCamSession.isMultiCamSupported ? "Yes" : "No")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("App Debug Info".uppercased())
                    .font(.headline)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
            }
            
            Section {
                VStack(alignment: .leading) {
                    Text("All Camera Devices:")
                        .font(.headline)
                    
                    ForEach(deviceNames.indices, id: \.self) { i in
                        let name = deviceNames[i]
                        
                        Text("\(name)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Multicam Camera Devices:")
                        .font(.headline)
                    
                    ForEach(multicamDeviceNames.indices, id: \.self) { i in
                        let names = multicamDeviceNames[i]
                        
                        Text(names.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Were devices added?")
                        .font(.headline)
                    
                    Text(appCameraState.cameraDebug.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Camera Devices".uppercased())
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .onAppear(perform: fetchSupportedDevicesNames)
        }
    }
    
    func fetchSupportedDevicesNames() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        // All camera devices
        let devices = discoverySession.devices
        
        self.deviceNames = devices.map(\.localizedName)
        
        // Multicam camera devices
        let deviceSets = discoverySession.supportedMultiCamDeviceSets
        
        self.multicamDeviceNames = deviceSets.map { $0.map(\.localizedName) }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .preferredColorScheme(.dark)
            .environmentObject(AppCameraState())
    }
}
