//
//  Constants.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 21/12/24.
//

import Foundation

enum Constants: String, CustomStringConvertible {
    case isHDKey = "is_hd"
    case frameRateKey = "frame_rate"
    case isAudioEnabledKey = "mute_audio"
    case cameraPreviewKey = "camera_preview"
    case selectedUnit = "selected_unit"
    case videoStabilizationMode = "video_stabilization_mode"
    
    var description: String { rawValue }
}
