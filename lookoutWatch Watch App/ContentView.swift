//
//  ContentView.swift
//  lookoutWatch Watch App
//
//  Created by Sahil on 09/06/25.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @EnvironmentObject private var connectivityManager: WatchConnectivityManager
    @State private var isRecording = false
    @State private var isScreenshotSaved = false

    var body: some View {
        VStack {
            Button(action: {
                sendMessage(action: "testConnection")
            }) {
                Text("Test Connection")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            .padding(.bottom, 20)

            Spacer()

            if isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.red)
                        .frame(width: 12, height: 12)
                    Text("Recording")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .cornerRadius(100)
                .transition(.opacity)
            }

            if isScreenshotSaved {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                    Text("Screenshot Saved")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .cornerRadius(100)
                .transition(.opacity)
            }

            Spacer()

            HStack(spacing: 40) {
                Button(action: {
                    isRecording.toggle()
                    let action = isRecording ? "startRecording" : "stopRecording"
                    sendMessage(action: action)
                }) {
                    let outerCircleSize: CGFloat = 60
                    let innerCircleSize: CGFloat = outerCircleSize - 10
                    Image(systemName: isRecording ? "stop.fill" : "circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: innerCircleSize, height: innerCircleSize)
                        .background {
                            Circle()
                                .stroke(lineWidth: 2)
                                .fill(.white.opacity(0.25))
                                .frame(width: outerCircleSize, height: outerCircleSize)
                        }
                }
                .tint(.red)

                Button(action: {
                    // Haptic feedback for screenshot
                    WKInterfaceDevice.current().play(.click)
                    sendMessage(action: "captureScreenshot")
                    withAnimation {
                        isScreenshotSaved = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            isScreenshotSaved = false
                        }
                    }
                }) {
                    let outerCircleSize: CGFloat = 60
                    let innerCircleSize: CGFloat = outerCircleSize - 10
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: innerCircleSize, height: innerCircleSize)
                        .background {
                            Circle()
                                .stroke(lineWidth: 2)
                                .fill(.white.opacity(0.25))
                                .frame(width: outerCircleSize, height: outerCircleSize)
                        }
                }
                .tint(.blue)
            }
            .padding(.horizontal, 30)
        }
        .padding()
    }

    private func sendMessage(action: String) {
        guard WCSession.default.activationState == .activated else { return }

        WCSession.default.sendMessage(["action": action], replyHandler: { reply in
            print("Message sent successfully")
        }, errorHandler: { error in
            print("Error sending message: \(error.localizedDescription)")
            if action.contains("Recording") {
                DispatchQueue.main.async {
                    isRecording.toggle()
                }
            }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WatchConnectivityManager())
    }
}
