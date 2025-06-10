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
            let error = NSError(domain: "ConnectivityManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "WCSession is not activated"])
            logger.error("Failed to send message: WCSession is not activated")
            completion?(error)
            return
        }
        
        #if os(iOS)
        guard WCSession.default.isWatchAppInstalled else {
            let error = NSError(domain: "ConnectivityManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Watch app is not installed"])
            logger.error("Failed to send message: Watch app is not installed")
            completion?(error)
            return
        }
        #endif
        
        logger.info("Sending message to Watch: \(action)")
        WCSession.default.sendMessage(["action": action], replyHandler: { reply in
            self.logger.info("Message sent successfully. Reply: \(reply)")
            completion?(nil)
        }, errorHandler: { error in
            self.logger.error("Error sending message: \(error.localizedDescription)")
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
                self.logger.info("Session activated successfully. Reachable: \(self.isReachable)")
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
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleReceivedMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleReceivedMessage(message)
        logger.info("Sending reply to Watch")
        replyHandler(["status": "received"])
    }
    
    private func handleReceivedMessage(_ message: [String : Any]) {
        DispatchQueue.main.async {
            if let action = message["action"] as? String {
                self.logger.info("Received action from Watch: \(action)")
                
                switch action {
                case "testConnection":
                    self.lastReceivedMessage = "Watch button clicked at \(Date().formatted())"
                    self.logger.info("Test connection received")
                case "startRecording":
                    NotificationCenter.default.post(name: .startRecording, object: nil)
                    self.lastReceivedMessage = "Recording started at \(Date().formatted())"
                    self.logger.info("Start recording command received")
                case "stopRecording":
                    NotificationCenter.default.post(name: .stopRecording, object: nil)
                    self.lastReceivedMessage = "Recording stopped at \(Date().formatted())"
                    self.logger.info("Stop recording command received")
                case "captureScreenshot":
                    NotificationCenter.default.post(name: .captureScreenshot, object: nil)
                    self.lastReceivedMessage = "Screenshot captured at \(Date().formatted())"
                    self.logger.info("Screenshot command received")
                default:
                    self.lastReceivedMessage = "Unknown action received: \(action)"
                    self.logger.warning("Unknown action received from Watch: \(action)")
                }
                self.logger.info("Message processed: \(self.lastReceivedMessage)")
            } else {
                self.logger.warning("Received message without action: \(message)")
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

extension Notification.Name {
    static let startRecording = Notification.Name("startRecording")
    static let stopRecording = Notification.Name("stopRecording")
    static let captureScreenshot = Notification.Name("captureScreenshot")
}

