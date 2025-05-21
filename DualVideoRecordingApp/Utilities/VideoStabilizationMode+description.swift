//
//  VideoStabilizationMode+description.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 24/02/25.
//

import AVFoundation

extension AVCaptureVideoStabilizationMode: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .off:
            "Off"
        case .standard:
            "Standard"
        case .cinematic:
            "Cinematic"
        case .auto:
            "Auto"
        case .cinematicExtended:
            "Cinematic Extended"
        case .previewOptimized:
            "Preview Optimized"
        case .cinematicExtendedEnhanced:
            "Cinematic Extended Enhanced"
        @unknown default:
            "Unknown"
        }
    }
}
