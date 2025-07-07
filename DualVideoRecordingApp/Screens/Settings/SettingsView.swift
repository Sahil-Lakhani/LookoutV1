//
//  SettingsView.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 19/12/24.
//  Updated by D1ecast on 04/06/25.
//

import AVFoundation
import SwiftUI
import StorageSenseKit

struct SettingsView: View {
    @StateObject private var navigationModel = NavigationModel()
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject private var appCameraState: AppCameraState
    
    @State private var storageStatus: StorageStatus? = nil
    
    @AppStorage(Constants.isAudioEnabledKey.description) private var isAudioEnabled: Bool = false
    
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
                        .padding(.top , 20)
                        .padding(.leading,5)
                        .padding(.trailing, 6)
                        .listRowBackground(
                           TopCornersRoundedBackground(radius: 20)
                        )
                        
                        LabelledNavigationLink(
                            route: .cameraPreviewSettings,
                            title: "Camera Preview",
                            subTitle: "Adjust camera preview layout",
                            icon: Image(systemName: "rectangle.3.group.fill")
                                .font(.title2)
                                .foregroundStyle(.gray.gradient)
                        )
                        .padding(.bottom , 20)
                        .padding(.leading, 5)
                        .padding(.trailing, 6)
                        .listRowBackground(
                            BottomCornersRoundedBackground(radius: 20)
                        )
                    }

                    // Storage Section (directly shown)
                    Section{
                        LabelledListItemCard(title: "Storage Status"){
                        if let storageStatus = storageStatus {
                            ProgressView(value: storageStatus.usedFraction) {
                        Text("Space Available : \(storageStatus.formattedFreeSpace)")
                            .font(.system(.headline,  weight: .bold))
                            .foregroundStyle(.primary)
                            // .padding(.top, 10)
                    }
                    .progressViewStyle(.linear)
                    .padding(.trailing,11)

                    Text("\(storageStatus.description)")
                        .font(.system(.subheadline,  weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 10)
                    
                    // Text("\(storageStatus.formattedFreeSpace) Available")
                    //     .font(.system(.headline, weight: .bold))
                    //     .foregroundStyle(.primary)
                    //     .padding(.vertical, 10)
                    //     .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Loading...")
                                .font(.system(.headline, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        }
                    }
                    
                    // Audio Section
                    Section {
                        LabelledListItemCard(title: "Audio Settings") {
                            Toggle(isOn: $isAudioEnabled) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Record Camera's Audio")
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                        .foregroundStyle(.primary)
                                    Text("Enable/Disable audio recording from the camera")
                                        .font(.system(.headline, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(.yellow)
                            .toggleStyle(.switch)
                            .onChange(of: isAudioEnabled) { appCameraState.isAudioDeviceEnabled = $0 }
                            .padding(.trailing, 10)
                        }
                    }
                    
                    // App Info Section
                    Section {
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 8) {
                                Image("lookOutAppIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                                
                                VStack(spacing: 2) {
                                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "App Name")
                                        .font(.system(.headline, weight: .bold))
                                        .foregroundStyle(.primary)
                                    
                                    Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                                        .font(.system(.subheadline))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 32)
                        .listRowBackground(Color.clear)
                    }
                }
                .tint(.gray)
                .navigationTitle("Settings".uppercased())
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: NavigationRoutes.self) { $0 }
                .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.primary) // Adapts to light/dark mode
                .padding(8)
                .background(
                    Circle()
                        .fill(Color(.systemGray5).opacity(0.6))
                )
        }
        .accessibilityLabel("Close")
    }
}

            }
        }
        .onAppear {
            do {
                storageStatus = try? .create()
            } catch {
                // Handle error if needed
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
                    // .fontDesign(.rounded)
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

struct TopCornersRoundedBackground: View {
    let radius: CGFloat
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                path.move(to: CGPoint(x: 0, y: radius))
                path.addArc(
                    center: CGPoint(x: radius, y: radius),
                    radius: radius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false
                )
                path.addLine(to: CGPoint(x: w - radius, y: 0))
                path.addArc(
                    center: CGPoint(x: w - radius, y: radius),
                    radius: radius,
                    startAngle: .degrees(270),
                    endAngle: .degrees(0),
                    clockwise: false
                )
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.closeSubpath()
            }
            .fill(.thinMaterial)
        }
    }
}

struct BottomCornersRoundedBackground: View {
    let radius: CGFloat
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w, y: h - radius))
                path.addArc(
                    center: CGPoint(x: w - radius, y: h - radius),
                    radius: radius,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false
                )
                path.addLine(to: CGPoint(x: radius, y: h))
                path.addArc(
                    center: CGPoint(x: radius, y: h - radius),
                    radius: radius,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false
                )
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.closeSubpath()
            }
            .fill(.thinMaterial)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .preferredColorScheme(.dark)
            .environmentObject(AppCameraState())
    }
}
