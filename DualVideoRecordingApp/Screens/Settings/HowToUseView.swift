import SwiftUI

struct HowToUseItView: View {
    var height: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 425 : 550
    }
    var cornerRadius: CGFloat { height / 58 }
    
    var body: some View {
        List {
            LabelledListItemCard(title: "control") {
                TabView() {
                    controlCarousel
                        .padding(.bottom, 60)
                }
                .frame(height: height)
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
        }
        .navigationTitle("How to use LookOut")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.sidebar)
        .listRowSpacing(15)
        .listSectionSeparator(.hidden, edges: .all)
    }
    
    var controlCarousel: some View {
        ForEach(ControlPreview.allCases, id: \.rawValue) { preview in
            VStack {
                preview.image
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
                    .accessibilityAddTraits(.isButton)
                    // .onTapGesture {
                    //     withAnimation {
                    //         currentPreview = preview
                    //     }
                    // }
            }
            // .tag(preview)
            // .id(preview.rawValue)
        }
    }
}

enum ControlPreview: String, CaseIterable {
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
