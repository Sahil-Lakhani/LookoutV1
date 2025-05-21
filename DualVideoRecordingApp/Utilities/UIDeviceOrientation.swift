//
//  UIDeviceOrientation.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 24/11/24.
//

import AVFoundation
import UIKit

extension UIDeviceOrientation {
    @available(iOS 17.0, *)
    var videoRotationAngle: CGFloat {
        switch self {
        case .portrait:
            90
        case .portraitUpsideDown:
            270
        case .landscapeLeft:
            0
        case .landscapeRight:
            180
        default:
            90
        }
    }
    
    @available(iOS 17.0, *)
    var frontVideoRotationAngle: CGFloat {
        switch self {
        case .landscapeLeft:
            180
        case .landscapeRight:
            0
        default:
            videoRotationAngle
        }
    }
    
    @available(iOS, introduced: 4.0, deprecated: 17.0, message: "Added for legacy purposes.")
    var videoOrientation: AVCaptureVideoOrientation {
        switch self {
        case .portrait:
                .portrait
        case .portraitUpsideDown:
                .portraitUpsideDown
        case .landscapeLeft:
                .landscapeLeft
        case .landscapeRight:
                .landscapeRight
        default:
                .portrait
        }
    }
}
