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
    
    var body: some View {
        VStack(spacing: 10) {
            Text(isRecording ? "Recording..." : "Ready")
                .font(.headline)
            
            Button(action: {
                isRecording.toggle()
                let action = isRecording ? "startRecording" : "stopRecording"
                sendMessage(action: action)
            }) {
                Text(isRecording ? "Stop Recording" : "Start Recording")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isRecording ? .red : .green)
            
            Divider()
                .padding(.vertical, 5)
            
            Button(action: {
                sendMessage(action: "testConnection")
            }) {
                Text("Test Connection")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            
            if !connectivityManager.isReachable {
                Text("iPhone not connected")
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text("Connected to iPhone")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
    
    private func sendMessage(action: String) {
        guard WCSession.default.activationState == .activated else { return }
        
        WCSession.default.sendMessage(["action": action], replyHandler: { reply in
            print("Message sent successfully")
        }, errorHandler: { error in
            print("Error sending message: \(error.localizedDescription)")
            // Revert the recording state if message failed
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
