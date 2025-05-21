//
//  BlackOutMode.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 05/12/24.
//

import SwiftUI

struct BlackOutModeView: View {
    @Binding var overlayMode: RecordingView.OverlayMode
    
    @State var opacity: Double = 1
    
    var body: some View {
        ZStack(alignment: .center) {
            Color.black
                .ignoresSafeArea(.all, edges: .all)
            
            
            Button {
                self.overlayMode = .none
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
            }
            .tint(.white)
            .opacity(opacity)
            .labelStyle(.iconOnly)
//            .padding(.bottom, 60)
            .allowsHitTesting(true)
        }
        .onAppear {
            withAnimation(.linear(duration: 3)) {
                opacity = 0.1
            }
        }
    }
}

#Preview {
    ZStack {
        Image(.frontCam)
            .resizable()
            .scaledToFit()
        
        BlackOutModeView(overlayMode: .constant(.blackout))
    }
}
