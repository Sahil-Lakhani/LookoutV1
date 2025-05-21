//
//  CameraPreviewPropertyWrapper.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 16/01/25.
//

import SwiftUI

@propertyWrapper struct CameraPreviewPropertyWrapper: DynamicProperty {
    var wrappedValue: CameraPreview {
        get { UserDefaults.standard.cameraPreviewOrDefault }
        nonmutating set { UserDefaults.standard.cameraPreviewOrDefault = newValue }
    }
    
    var projectedValue: Binding<CameraPreview> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
    
    func update() {
        UserDefaults.standard.cameraPreviewOrDefault = wrappedValue
    }
}

extension UserDefaults {
    var cameraPreviewOrDefault: CameraPreview {
        get {
            let rawValue = UserDefaults.standard.string(forKey: Constants.cameraPreviewKey.description) ?? CameraPreview.one.rawValue
            return CameraPreview(rawValue: rawValue) ?? .one
        }
        set { UserDefaults.standard.setValue(newValue.rawValue, forKey: Constants.cameraPreviewKey.description) }
    }
}
