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
        ZStack {
            // Main content (always at zIndex 0)
            VStack {
                Spacer()
                HStack(spacing: 25) {
                    Button(action: {
                        let action = isRecording ? "stopRecording" : "startRecording"
                        sendMessage(action: action)
                    }) {
                        let outerCircleSize: CGFloat = 80
                        let innerCircleSize: CGFloat = outerCircleSize - 0
                        Image(isRecording ? "stopRecordButton" : "recordButton")
                            .resizable()
                            .scaledToFit()
                            .frame(width: innerCircleSize, height: innerCircleSize)
                    }
                    .frame(width: 80, height: 80)
                    .disabled(!connectivityManager.isPhoneAppActive)
                    .buttonStyle(.plain)

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
                    }
                    .frame(width: 70, height: 70)
                    .disabled(!connectivityManager.isPhoneAppActive)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 25)
                .padding(.top, 20)

                Spacer() // Push buttons to the center of the screen

                // Bottom Status Text
                // VStack(spacing: 8) {
                //     Group {
                //         if connectivityManager.isPhoneAppActive {
                //             HStack(spacing: 8) {
                //                 Circle()
                //                     .fill(.green)
                //                     .frame(width: 12, height: 12)
                //                 Text("app active")
                //                     .font(.headline)
                //                     .foregroundColor(.white)
                //             }
                //             .transition(.opacity)
                //         } else {
                //             HStack(spacing: 8) {
                //                 Circle()
                //                     .fill(.gray)
                //                     .frame(width: 12, height: 12)
                //                 Text("app inactive")
                //                     .font(.headline)
                //                     .foregroundColor(.white)
                //             }
                //             .transition(.opacity)
                //         }
                //     }
                //     .foregroundColor(connectivityManager.isPhoneAppActive ? .gray : .gray)
                //     .font(.footnote)
                // }
                // .padding(.top, 30) // Ensure the text is at the bottom
            }
            .padding()
            .onReceive(connectivityManager.$lastReceivedAction) { action in
                if action == "stopRecording" {
                    isRecording = false
                } else if action == "startRecording" {
                    isRecording = true
                }
            }
            .zIndex(0)

            // Overlay (always at zIndex 1, only shown when inactive)
            if !connectivityManager.isPhoneAppActive {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(1)
                VStack(spacing: 16) {
                    Image(systemName: "iphone.slash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                    Text("App is not open on the phone")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    Button(action: {
                        // Attempt to send a message to open the app on the phone
                        sendMessage(action: "openLookout")
                    }) {
                        Text("Open Lookout")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.9))
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(32)
                .background(Color.black.opacity(0.8))
                .cornerRadius(20)
                .shadow(radius: 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.move(edge: .top))
                .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.4), value: !connectivityManager.isPhoneAppActive)
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
