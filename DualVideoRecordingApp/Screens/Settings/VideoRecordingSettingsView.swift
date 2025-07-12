//
//  VideoRecordingSettingsView.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 15/01/25.
//

import Algorithms
import AVFoundation
import SwiftUI

@propertyWrapper fileprivate struct AVFormat: DynamicProperty {
    @State private var value: AVCaptureDevice.Format?

    var wrappedValue: AVCaptureDevice.Format? {
        get { value }
        nonmutating set {
            value = newValue
            save(newValue: newValue)
        }
    }

    var projectedValue: Binding<AVCaptureDevice.Format?> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    private func save(newValue: AVCaptureDevice.Format?) {
        guard let format = newValue else { return }
        let isHD = format.formatDescription.dimensions.height == 720
        UserDefaults.standard.setValue(isHD, forKey: Constants.isHDKey.description)
    }
}

struct VideoRecordingSettingsView: View {
    @EnvironmentObject private var appCameraState: AppCameraState
    @Environment(\.dismiss) private var dismiss  // 👈 Added for custom back button

    @State private var supportedVideoFormats: [AVCaptureDevice.Format] = []
    @AVFormat private var currentVideoFormat: AVCaptureDevice.Format?

    @AppStorage(Constants.frameRateKey.description) private var frameRate: Int = 30
    @AppStorage(Constants.isAudioEnabledKey.description) private var isAudioEnabled: Bool = false

    @State private var supportsVideoStabilization: Bool = false
    @State private var connections: [AVCaptureConnection] = []
    @State private var currentVideoStabilizationMode: AVCaptureVideoStabilizationMode = .auto
    @AppStorage(Constants.videoStabilizationMode.description) private var isStabilizationOn: Bool = false

    @State private var isBusy = false

    var body: some View {
        List {
            LabelledListItemCard(title: "Video Format Settings") {
                VStack(spacing: 15) {
                    let spacing: CGFloat = 15
                    VStack(alignment: .leading, spacing: spacing) {
                        Text("Video Resolution")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)

                        recordingFormatPicker
                    }

                    VStack(alignment: .leading, spacing: spacing) {
                        Text("Video Frame Rate")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)

                        frameRatePicker
                    }
                }

                VStack(alignment: .leading, spacing: 15) {
                    Text("Video Stabilization")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)

                    if supportsVideoStabilization {
                        // Text("Current Stabilization Mode:\n'\(currentVideoStabilizationMode.description)\'")
                        //     .font(.system(.headline, design: .rounded))
                        //     .foregroundStyle(.secondary)
                        
                        Toggle("Video Stabilization: ", isOn: $isStabilizationOn)
                            .onChange(of: isStabilizationOn) { currentVideoStabilizationMode = $0 ? .auto : .off }
                            .onChange(of: currentVideoStabilizationMode, perform: changeVideoStabilizationMode(to:))
                            .tint(.orange)

                        if isStabilizationOn {
                            Text("""
                            **Note:** It uses additional processing power.
                            """)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.orange)
                        }
                    } else {
                        Text("Video stabilization is not supported on this device.")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .overlay(alignment: .center) {
                if isBusy {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()

                        ProgressView()
                    }
                }
            }
            
            // LabelledListItemCard(title: "Audio Settings") {
            //     muteToggle
            // }
        }
        .navigationTitle("Video Recording Settings")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.sidebar)
        .listRowSpacing(15)
        .listSectionSeparator(.hidden, edges: .all)
        .navigationBarBackButtonHidden(true) // 👈 Hide default back button
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.orange) // 👈 Orange back button text
                }
            }
        }
        .onAppear {
            loadSupportedVideoFormats()
            loadVideoStabilizationSettings()
        }
    }

    var recordingFormatPicker: some View {
        Picker("Recording Format", selection: $currentVideoFormat) {
            ForEach(supportedVideoFormats, id: \.self) { format in
                Text(resolutionLabel(for: format))
                // Text(AppCameraState.formatDescription(for: format))
                    .tag(format)
            }
        }
        .tint(.orange)
        .pickerStyle(.segmented)
        .onChange(of: self.currentVideoFormat, perform: changeVideoFormat(format:))
    }

    private func resolutionLabel(for format: AVCaptureDevice.Format) -> String {
        let dimensions = format.formatDescription.dimensions
        if dimensions.width == 1280 && dimensions.height == 720 {
            return "Low Res"
        } else if dimensions.width == 1920 && dimensions.height == 1080 {
            return "High Res"
        } else {
            return AppCameraState.formatDescription(for: format)
        }
    }

    var frameRatePicker: some View {
        Picker("Recording Frame Rate", selection: $frameRate) {
            let options = [1, 5, 15, 24, 30]
            ForEach(options, id: \.self) { fps in
                Text("\(fps) FPS")
                    .tag(fps)
            }
        }
        .pickerStyle(.wheel)
        

    //             .onChange(
    //         of: self.frameRate,
    //         perform: changeFrameRate(frameRate:)
    //     )
    // }
    
    // var muteToggle: some View {
    //     Toggle(isOn: $isAudioEnabled) {
    //         VStack(alignment: .leading, spacing: 5) {
    //             Text("Record Camera's Audio")
    //                 .font(.system(.headline, design: .rounded, weight: .bold))
    //                 .foregroundStyle(.primary)
                
    //             Text("Enable/Disable audio recording from the camera")
    //                 .font(.system(.headline, design: .rounded))
    //                 .foregroundStyle(.secondary)
    //         }
    //     }
    //     .tint(.yellow)
    //     .toggleStyle(.switch)
    //     .onChange(of: isAudioEnabled) { appCameraState.isAudioDeviceEnabled = $0 }



        .onChange(of: self.frameRate, perform: changeFrameRate(frameRate:))
    }

    private func changeVideoFormat(format: AVCaptureDevice.Format?) {
        guard let format else { return }

        appCameraState.updateFormat(to: format, on: appCameraState.backCamera)

        guard AVCaptureMultiCamSession.isMultiCamSupported else { return }
        
        // finds for front cam
        guard let device = appCameraState.frontCamera else { return }
        let resolutions = device.formats
            .filter(\.isMultiCamSupported)
            .filter(AppCameraState.filterResolution(_:))
            .uniqued(on: AppCameraState.formatDescription(for:))
        let isHD = format.formatDescription.dimensions.height == 720
        let dimensionHeight = isHD ? 720 : 1080
        let resolution = resolutions.first(where: { $0.formatDescription.dimensions.height == dimensionHeight })

        if let resolution {
            appCameraState.updateFormat(to: resolution, on: appCameraState.frontCamera)
        }
        loadVideoStabilizationSettings()
    }

    private func changeFrameRate(frameRate: Int) {
        appCameraState.updateFrameRate(to: frameRate, on: appCameraState.backCamera)
        if AVCaptureMultiCamSession.isMultiCamSupported {
            appCameraState.updateFrameRate(to: frameRate, on: appCameraState.frontCamera)
        }
        loadVideoStabilizationSettings()
    }

    private func loadSupportedVideoFormats() {
        guard let device = appCameraState.backCamera else { return }
        self.supportedVideoFormats = device.formats
            .filter(\.isMultiCamSupported)
            .filter(AppCameraState.filterResolution(_:))
            .uniqued(on: AppCameraState.formatDescription(for:))

        self.currentVideoFormat = device.activeFormat
    }

    private func loadVideoStabilizationSettings() {
        let firstConnection = appCameraState.session.connections.first
        self.supportsVideoStabilization = firstConnection?.isVideoStabilizationSupported ?? false
        self.currentVideoStabilizationMode = firstConnection?.activeVideoStabilizationMode ?? .auto
        self.isStabilizationOn = currentVideoStabilizationMode != .off
    }

    private func changeVideoStabilizationMode(to mode: AVCaptureVideoStabilizationMode) {
        isBusy = true
        appCameraState.session.connections.forEach {
            $0.preferredVideoStabilizationMode = mode
        }
        loadVideoStabilizationSettings()
        isBusy = false
    }
}

#Preview {
    NavigationStack {
        VideoRecordingSettingsView()
            .preferredColorScheme(.dark)
            .environmentObject(AppCameraState())
    }
}
