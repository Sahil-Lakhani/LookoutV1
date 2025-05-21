//
//  SmallUIPresentationDetent.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 15/03/25.
//

import UIKit

extension UISheetPresentationController.Detent.Identifier {
    static let small = Self.init(rawValue: "small")
}

extension UISheetPresentationController.Detent {
    static func small() -> UISheetPresentationController.Detent {
        .custom(
            identifier: .small
        ) { context in
            return 70
        }
    }
}
