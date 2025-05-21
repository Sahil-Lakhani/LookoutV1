//
//  LabelledListItemCard.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 15/01/25.
//

import SwiftUI

struct LabelledListItemCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom)
            
            Group(content: content)
        }
        .padding(.vertical)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

#Preview {
    List {
        LabelledListItemCard(title: "Audio") {
            Toggle("Mute", isOn: .constant(true))
        }
    }
    .preferredColorScheme(.dark)
}
