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
            Spacer()
            HStack(spacing: 25) {
                Button(action: {
                    isRecording.toggle()
                    let action = isRecording ? "startRecording" : "stopRecording"
                    sendMessage(action: action)
                }) {
                    let outerCircleSize: CGFloat = 70
                    let innerCircleSize: CGFloat = outerCircleSize - 0
                    Image(systemName: isRecording ? "stop.fill" : "circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: innerCircleSize, height: innerCircleSize)
                        .background {
                            Circle()
                                .stroke(lineWidth: 2)
                                .fill(.black.opacity(0.25))
                                .frame(width: outerCircleSize, height: outerCircleSize)
                        }
                }
                .tint(.red)
                .frame(width: 70, height: 70)
                // .disabled(!connectivityManager.isPhoneAppActive)

                Button(action: {
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
                    let outerCircleSize: CGFloat = 70
                    let innerCircleSize: CGFloat = outerCircleSize - 0
                    Image(systemName: "camera.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: innerCircleSize, height: innerCircleSize)
                        // .background {
                        //     Circle()
                        //         .stroke(lineWidth: 2)
                        //         .fill(.black.opacity(0.25))
                        //         .frame(width: outerCircleSize, height: outerCircleSize)
                        // }
                }
                .frame(width: 70, height: 70)
                .disabled(!connectivityManager.isPhoneAppActive)
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)

            Spacer() // Push buttons to the center of the screen

            // Bottom Status Text
            VStack(spacing: 8) {
                // if isRecording {
                //     HStack(spacing: 8) {
                //         Circle()
                //             .fill(.red)
                //             .frame(width: 12, height: 12)
                //         Text("Recording")
                //             .font(.headline)
                //             .foregroundColor(.white)
                //     }
                //     .transition(.opacity)
                // }

                // if isScreenshotSaved {
                //     HStack(spacing: 8) {
                //         Circle()
                //             .fill(.green)
                //             .frame(width: 12, height: 12)
                //         Text("Screenshot Saved")
                //             .font(.headline)
                //             .foregroundColor(.white)
                //     }
                //     .transition(.opacity)
                // }
                Group {
    if connectivityManager.isPhoneAppActive {
        HStack(spacing: 8) {
            Circle()
                .fill(.green)
                .frame(width: 12, height: 12)
            Text("app active")
                .font(.headline)
                .foregroundColor(.white)
        }
        .transition(.opacity)
    } else {
        HStack(spacing: 8) {
            Circle()
                .fill(.green)
                .frame(width: 12, height: 12)
            Text("app active")
                .font(.headline)
                .foregroundColor(.white)
        }
        .transition(.opacity)
    }
}

                // Text(connectivityManager.isPhoneAppActive ? 
                    // HStack(spacing: 8) {
                    //     Circle()
                    //         .fill(.green)
                    //         .frame(width: 12, height: 12)
                    //     Text("App active")
                    //         .font(.headline)
                    //         .foregroundColor(.white)
                    // }
                    // .transition(.opacity) 
                //     : HStack(spacing:8){
                //         Circle()
                //             .fill(.green)
                //             .frame(width: 12, height: 12)
                //         Text("App not active")
                //             .font(.headline)
                //             .foregroundColor(.white)
                //     }
                //     .transition(.opacity))
                    .foregroundColor(connectivityManager.isPhoneAppActive ? .gray : .gray)
                    .font(.footnote)
            }
            .padding(.top, 30) // Ensure the text is at the bottom
        }
        .padding()
        .onReceive(connectivityManager.$lastReceivedAction) { action in
            if action == "stopRecording" {
                isRecording = false
            } else if action == "startRecording" {
                isRecording = true
            }
        }
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
