//
//  CustomError.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 26/10/24.
//

import Foundation

enum CustomError: LocalizedError, CustomStringConvertible {
    case cameraAccessDenied
    case imageEncodeFailed
    case custom(message: String)
    case captureCancelled
    
    var errorDescription: String? {
        "An Error has occurred. \(description)"
    }
    
    var description: String {
        switch self {
        case .cameraAccessDenied:
            "Camera access denied. Please grant in settings app."
        case .imageEncodeFailed:
            "Failed to transfer image."
        case .captureCancelled:
            "Capture cancelled."
        case .custom(let message):
            message
        }
    }
}
