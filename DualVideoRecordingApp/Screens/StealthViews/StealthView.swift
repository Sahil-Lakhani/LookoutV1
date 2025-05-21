//
//  StealthView.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 04/12/24.
//

import SwiftUI

struct StealthView: View {
    @Binding var overlayMode: RecordingView.OverlayMode
    
    @EnvironmentObject<NavigationModel> var navigationModel
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var isPortrait: Bool {
        horizontalSizeClass == .compact && verticalSizeClass == .regular
    }
    
    struct AppItem: Identifiable {
        let id = UUID()
        let title: String
        let imageName: String
        let systemImage: Bool
        let mode: RecordingView.OverlayMode
    }
    
    let apps: [AppItem] = [
        AppItem(
            title: "Blackout",
            imageName: "iphone.slash",
            systemImage: true,
            mode: .blackout
        ),
        AppItem(
            title: "Maps",
            imageName: "maps",
            systemImage: false,
            mode: .maps
        ),
    ]
    
    // Grid layout configuration
    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 100), alignment: .leading),
    ]
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            VStack {
                Text("Stealth Mode")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 30)
                    .padding(.bottom, 20)
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(apps) { app in
                        AppIconButton(app: app) {
                            self.overlayMode = app.mode
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    self.overlayMode = .none
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                        .frame(height: 40)
                }
                .tint(.white)
                .labelStyle(.iconOnly)
                .padding(.bottom)
            }
            .padding(.horizontal, 30)
        }
    }
    
    struct AppIconButton: View {
        let app: StealthView.AppItem
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 10) {
                    ZStack {
                        if app.systemImage {
                            Image(systemName: app.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .padding(14)
                                .foregroundColor(.white)
                        } else {
                            Image(.maps)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .padding(6)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .frame(width: 70, height: 70)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                    
                    Text(app.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var overlayMode: RecordingView.OverlayMode = .options
    
    ZStack {
        Image(.backCam)
            .resizable()
            .scaledToFill()
        
        StealthView(overlayMode: $overlayMode)
            .environmentObject(NavigationModel())
            .onChange(of: overlayMode) { newValue in
                print("Overlay mode changed to \(newValue)")
            }
    }
}
