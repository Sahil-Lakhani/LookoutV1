//
//  lookoutWatchApp.swift
//  lookoutWatch Watch App
//
//  Created by Sahil on 09/06/25.
//

import SwiftUI
import WatchConnectivity

@main
struct lookoutWatchApp: App {
    @StateObject private var connectivityManager = WatchConnectivityManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityManager)
        }
    }
}

class WatchConnectivityManager: NSObject, ObservableObject {
    @Published var isReachable = false
    @Published var lastReceivedAction: String?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = activationState == .activated
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let action = message["action"] as? String {
                self.lastReceivedAction = action
                // Handle the action here
                print("Received action: \(action)")
            }
        }
    }
}
