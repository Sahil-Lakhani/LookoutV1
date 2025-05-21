//
//  View+scenephase.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 24/02/25.
//

import SwiftUI

extension View {
    func onScenePhaseChange(_ action: @escaping (ScenePhase) -> Void) -> some View {
        self.modifier(ScenePhaseViewModifier(onNewValue: action))
    }
}

fileprivate struct ScenePhaseViewModifier: ViewModifier {
    @Environment(\.scenePhase) var scenePhase
    
    var onNewValue: (ScenePhase) -> Void
    
    func body(content: Content) -> some View {
        content.onChange(
            of: scenePhase,
            perform: onNewValue
        )
    }
}
