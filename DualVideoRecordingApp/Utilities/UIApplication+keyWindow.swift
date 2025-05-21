//
//  UIApplication+keyWindow.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 09/11/24.
//

import UIKit

extension UIApplication {
    @MainActor var keyWindow: UIWindow? {
        let windowScenes: [UIWindowScene] = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let keyWindow: [UIWindow] = windowScenes.compactMap { $0.keyWindow }
        return keyWindow.first
    }
}
