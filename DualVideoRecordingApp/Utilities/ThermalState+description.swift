//
//  ThermalState+description.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 01/11/24.
//

import Foundation

extension ProcessInfo.ThermalState: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .nominal:
            "Normal"
        case .fair:
            "Fair"
        case .serious:
            "Serious"
        case .critical:
            "Critical"
        @unknown default:
            "Unknown"
        }
    }
}
