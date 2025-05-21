import SwiftUI

struct ContentView: View {
    @EnvironmentObject var navigationModel: NavigationModel
    @EnvironmentObject var appCameraState: AppCameraState
    
    @State private var thermalState: ProcessInfo.ThermalState = .nominal
    
    var body: some View {
        ZStack {
            // Main Camera View
            RecordingView()
                .transition(.opacity)
            
            // Error Overlay
            if let error = appCameraState.error {
//                VStack(spacing: 20) {
//                    Text(error.description)
//                        .font(.headline)
//                        .foregroundStyle(.red)
//                        .fontDesign(.rounded)
//                        .fontWeight(.bold)
//                        .multilineTextAlignment(.center)
//                    
//                    if case .cameraAccessDenied = error {
//                        Link("Grant Access in Settings",
//                             destination: URL(string: UIApplication.openSettingsURLString)!)
//                            .buttonStyle(.borderedProminent)
//                            .accessibilityHint("Opens device settings")
//                    }
//                }
//                .padding()
//                .background(.ultraThickMaterial)
//                .cornerRadius(20)
//                .shadow(radius: 10)
//                .padding()
//                .onTapGesture {
//                    withAnimation {
//                        appCameraState.error = nil
//                    }
//                }
//                .accessibilityElement(children: .combine)
//                .transition(.scale.combined(with: .opacity))
                
                VStack(alignment: .center, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.trianglebadge.exclamationmark.fill")
                            .font(.title3)
                            .foregroundStyle(.red)

                        Text("Error")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                    
                    Text(error.description)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                    
                        if case .cameraAccessDenied = error {
                            Link("Grant Access in Settings",
                                    destination: URL(string: UIApplication.openSettingsURLString)!)
                            .buttonStyle(.borderedProminent)
                            .accessibilityHint("Opens device settings")
                        }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
//                .background(.regularMaterial)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(radius: 10, y: 4)
                .frame(maxWidth: 360)
                .transition(.move(edge: .top).combined(with: .opacity))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Device is overheating. Adjust recording settings if the device performance is significantly impacted. Do not leave the device unattended while it is to overheat.")
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
                )
            }
            
            // Thermal Warning Overlay
            if thermalState == .serious || thermalState == .critical {
                VStack(alignment: .center, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "thermometer.sun.fill")
                            .font(.title3)
                            .foregroundStyle(.red)

                        Text("Device Overheating")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }

                    Text("Recording is paused. Please allow the device to cool down.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
//                .background(.regularMaterial)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(radius: 10, y: 4)
                .frame(maxWidth: 360)
                .transition(.move(edge: .top).combined(with: .opacity))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Device is overheating. Adjust recording settings if the device performance is significantly impacted. Do not leave the device unattended while it is to overheat.")
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
                )
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onDisappear {
            appCameraState.stopSession()
        }
        .task {
            let granted = await appCameraState.checkAndRequestAccess()
            guard granted else {
                appCameraState.error = .cameraAccessDenied
                return
            }
            appCameraState.setupCameras()
            appCameraState.startSession()
        }
        .task {
            for await newState in ThermalStateSequence() {
                await MainActor.run {
                    thermalState = newState
                }
            }
        }
        .animation(.easeInOut, value: appCameraState.error != nil)
        .animation(.easeInOut, value: thermalState)
    }
}

//#Preview {
//    NavigationStack {
//        ContentView()
//            .environmentObject(AppCameraState())
//            .environmentObject(NavigationModel())
//    }
//}

#Preview("iPad") {
    ContentView()
        .environmentObject(AppCameraState())
        .environmentObject(NavigationModel())
}
//.previewDevice("iPad Pro (12.9-inch) (6th generation)")
