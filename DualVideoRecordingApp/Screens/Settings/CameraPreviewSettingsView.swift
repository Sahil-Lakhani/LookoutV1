//
//  CameraPreviewSettingsView.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 15/01/25.
//

import SwiftUI

struct CameraPreviewSettingsView: View {
    @State var currentPreview: CameraPreview = .one
    
    @State private var tabSelection: CameraPreview = .one
    
    let height: CGFloat = 550
    var cornerRadius: CGFloat { height / 58 }
    
    var body: some View {
        List {
            LabelledListItemCard(title: "Camera Preview") {
                TabView(selection: $tabSelection) {
                    cameraCarousel
                        .padding(.bottom, 60)
                }
                .frame(height: height)
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
            .onChange(of: currentPreview) {
                UserDefaults.standard.cameraPreviewOrDefault = $0
            }
            .onAppear {
                currentPreview = UserDefaults.standard.cameraPreviewOrDefault
                tabSelection = currentPreview
            }
        }
        .navigationTitle("Camera Recording Settings")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.sidebar)
        .listRowSpacing(15)
        .listSectionSeparator(.hidden, edges: .all)
    }
    
    var cameraCarousel: some View {
        ForEach(CameraPreview.allCases, id: \.rawValue) { preview in
            VStack {
                preview.image
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
                    .accessibilityAddTraits(.isButton)
                    .onTapGesture {
                        withAnimation {
                            currentPreview = preview
                        }
                    }
                
                let isSelected = preview.rawValue == currentPreview.rawValue
                
                if isSelected {
                    Button {
                        
                    } label: {
                        Label("Selected", systemImage: "checkmark.circle")
                            .foregroundStyle(.thinMaterial)
                    }
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .tint(.white)
                    .buttonStyle(.borderedProminent)
                    .animation(.smooth(duration: 0.5, extraBounce: 0.33), value: currentPreview)
                } else {
                    Button("Choose", systemImage: "checkmark.circle.fill") {
                        withAnimation {
                            currentPreview = preview
                        }
                    }
                    .tint(.white)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .buttonStyle(.bordered)
                    .animation(.smooth(duration: 0.5, extraBounce: 0.33), value: currentPreview)
                }
            }
            .tag(preview)
            .id(preview.rawValue)
        }
    }
}

enum CameraPreview: String, CaseIterable {
    case one
    case two
    case three
    
    var image: Image {
        switch self {
        case .one:
            Image(.one)
        case .two:
            Image(.two)
        case .three:
            Image(.three)
        }
    }
}

#Preview {
    CameraPreviewSettingsView()
        .preferredColorScheme(.dark)
}
