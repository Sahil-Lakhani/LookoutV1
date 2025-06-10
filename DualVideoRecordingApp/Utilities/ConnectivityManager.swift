//
//  ConnectivityManager.swift
//  DualVideoRecordingApp
//
//  Created by Sahil on 09/06/25.
//

import Foundation
import WatchConnectivity
import SwiftUI
import OSLog

class ConnectivityManager: NSObject, ObservableObject {
    static let shared = ConnectivityManager()
    @Published var isReachable = false
    @Published var lastReceivedMessage: String = ""
    
    private let logger = Logger(subsystem: "com.kidastudios.DualVideoRecordingApp", category: "ConnectivityManager")
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func sendMessage(_ action: String, completion: ((Error?) -> Void)? = nil) {
        guard WCSession.default.activationState == .activated else {
            completion?(NSError(domain: "ConnectivityManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "WCSession is not activated"]))
            return
        }
        
        #if os(iOS)
        guard WCSession.default.isWatchAppInstalled else {
            completion?(NSError(domain: "ConnectivityManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Watch app is not installed"]))
            return
        }
        #endif
        
        WCSession.default.sendMessage(["action": action], replyHandler: { reply in
            completion?(nil)
        }, errorHandler: { error in
            completion?(error)
        })
    }
}

extension ConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = activationState == .activated
            if let error = error {
                self.logger.error("Session activation failed with error: \(error.localizedDescription)")
            } else {
                self.logger.info("Session activated successfully")
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = false
            self.logger.info("Session became inactive")
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = false
            self.logger.info("Session deactivated")
        }
        // Reactivate session if needed
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleReceivedMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleReceivedMessage(message)
        // Always send a reply to acknowledge receipt
        replyHandler(["status": "received"])
    }
    
    private func handleReceivedMessage(_ message: [String : Any]) {
        DispatchQueue.main.async {
            if let action = message["action"] as? String {
                self.logger.info("Received action: \(action)")
                
                switch action {
                case "testConnection":
                    self.lastReceivedMessage = "Watch button clicked at \(Date().formatted())"
                case "startRecording":
                    // Post notification to start recording
                    NotificationCenter.default.post(name: .startRecording, object: nil)
                    self.lastReceivedMessage = "Recording started at \(Date().formatted())"
                case "stopRecording":
                    // Post notification to stop recording
                    NotificationCenter.default.post(name: .stopRecording, object: nil)
                    self.lastReceivedMessage = "Recording stopped at \(Date().formatted())"
                default:
                    self.lastReceivedMessage = "Unknown action received: \(action)"
                    self.logger.warning("Unknown action received: \(action)")
                }
                print("Received message: \(self.lastReceivedMessage)")
            }
        }
    }
    
    #if os(iOS)
    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            self.logger.info("Watch state changed. Reachable: \(session.isReachable)")
        }
    }
    #endif
}

// Add notification names
extension Notification.Name {
    static let startRecording = Notification.Name("startRecording")
    static let stopRecording = Notification.Name("stopRecording")
}

