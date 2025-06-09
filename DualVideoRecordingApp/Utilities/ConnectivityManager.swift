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
    @Published var isRecording = false
    
    private var appCameraState: AppCameraState?
    private let logger = Logger(subsystem: "com.kidastudios.DualVideoRecordingApp", category: "ConnectivityManager")
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func setAppCameraState(_ state: AppCameraState) {
        logger.info("Setting AppCameraState")
        self.appCameraState = state
        // Verify camera state is properly set
        if let cameraState = self.appCameraState {
            logger.info("Camera state successfully set. Camera active: \(cameraState.isCameraActive)")
        } else {
            logger.error("Failed to set camera state")
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
                    if let cameraState = self.appCameraState {
                        if cameraState.isCameraActive {
                            cameraState.startRecording()
                            self.isRecording = true
                            self.lastReceivedMessage = "Recording started at \(Date().formatted())"
                            self.logger.info("Recording started successfully")
                        } else {
                            self.lastReceivedMessage = "Error: Camera is not active"
                            self.logger.error("Camera is not active")
                        }
                    } else {
                        self.lastReceivedMessage = "Error: Camera state not initialized"
                        self.logger.error("Camera state is nil")
                    }
                case "stopRecording":
                    if let cameraState = self.appCameraState {
                        cameraState.stopRecording()
                        self.isRecording = false
                        self.lastReceivedMessage = "Recording stopped at \(Date().formatted())"
                        self.logger.info("Recording stopped successfully")
                    } else {
                        self.lastReceivedMessage = "Error: Camera state not initialized"
                        self.logger.error("Camera state is nil")
                    }
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

