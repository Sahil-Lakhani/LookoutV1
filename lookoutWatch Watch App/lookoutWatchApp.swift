//
//  lookoutWatchApp.swift
//  lookoutWatch Watch App
//
//  Created by Sahil on 09/06/25.
//

import SwiftUI
import WatchConnectivity
import os

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
    @Published var lastError: String?
    @Published var isPhoneAppActive: Bool = false
    
    private let logger = Logger(subsystem: "com.kidastudios.lookout.watch", category: "WatchConnectivityManager")
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            logger.info("Watch connectivity manager initialized")
        } else {
            logger.error("Watch connectivity is not supported on this device")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = activationState == .activated
            if let error = error {
                self.lastError = error.localizedDescription
                self.logger.error("Session activation failed: \(error.localizedDescription)")
            } else {
                self.logger.info("Session activated successfully. Reachable: \(self.isReachable)")
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let action = message["action"] as? String {
                self.lastReceivedAction = action
                if action == "appActive" {
                    self.isPhoneAppActive = true
                } else if action == "appInactive" {
                    self.isPhoneAppActive = false
                }
                self.logger.info("Received action from iPhone: \(action)")
            } else {
                self.logger.warning("Received message without action: \(message)")
            }
        }
    }
    
    func session(_ session: WCSession, didFailToSendMessage message: [String : Any], error: Error) {
        DispatchQueue.main.async {
            self.lastError = error.localizedDescription
            self.logger.error("Failed to send message: \(error.localizedDescription)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            if let action = message["action"] as? String {
                self.lastReceivedAction = action
                if action == "appActive" {
                    self.isPhoneAppActive = true
                } else if action == "appInactive" {
                    self.isPhoneAppActive = false
                }
                self.logger.info("Received action with reply handler: \(action)")
            } else {
                self.logger.warning("Received message without action (with reply): \(message)")
            }
            replyHandler(["status": "received"])
        }
    }
}
