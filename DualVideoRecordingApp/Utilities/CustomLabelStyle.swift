//
//  CustomLabelStyle.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 23/03/25.
//

import SwiftUI

struct CustomLabelStyle: LabelStyle {
    let spacing: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: spacing) {
            configuration.icon
                
            configuration.title
        }
    }
}

extension LabelStyle where Self == CustomLabelStyle {
    static func custom(spacing: CGFloat) -> CustomLabelStyle {
        CustomLabelStyle(spacing: spacing)
    }
}
