//
//  OrientationChangeTrial.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 13/01/25.
//

import SwiftUI

extension View {
    func onOrientationChange(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(OrientationChangeViewModifier(onNewValue: action))
    }
}

struct OrientationChangeViewModifier: ViewModifier {
    var onNewValue: (UIDeviceOrientation) -> Void
    
    private let publisher = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
    
    func body(content: Content) -> some View {
        content
            .onReceive(publisher) { (output) in
                guard let uiDevice = output.object as? UIDevice else { return }
                onNewValue(uiDevice.orientation)
            }
    }
}
