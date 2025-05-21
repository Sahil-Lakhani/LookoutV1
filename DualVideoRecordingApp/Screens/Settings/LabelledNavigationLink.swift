//
//  LabelledNavigationLink.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 15/01/25.
//

import SwiftUI

struct LabelledNavigationLink<Icon: View>: View {
    let route: NavigationRoutes
    let title: String
    let subTitle: String
    let icon: Icon
    
    var body: some View {
        NavigationLink(value: route) {
            Label {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        
                    Text(subTitle)
                        .font(.subheadline)
                        .fontWeight(.regular)
                        .foregroundStyle(.secondary)
                }
                .fontDesign(.rounded)
            } icon: {
                icon
            }
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            LabelledNavigationLink(
                route: .settings,
                title: "First line",
                subTitle: "Second line",
                icon: Image(systemName: "photo").font(.title).foregroundStyle(.blue.gradient)
            )
        }
    }
    .preferredColorScheme(.dark)
}
