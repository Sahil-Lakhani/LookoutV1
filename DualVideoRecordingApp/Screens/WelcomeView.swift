//import SwiftUI
//
//struct WelcomeView: View {
//    @State private var isShowingMainApp = false
//    
//    @EnvironmentObject var navigationModel: NavigationModel
//    @EnvironmentObject var appCameraState: AppCameraState
//
//    var body: some View {
//        ZStack {
//            // Background color
//            Color.black.ignoresSafeArea()
//            
//            VStack {
//                // Welcome image
//                Image("welcome-image")
//                    .resizable()
//                    .scaledToFit()
//                    .padding()
//                
//                Spacer()
//                
//                // Button to go to the main screen
//                Button(action: {
//                    withAnimation {
//                        isShowingMainApp = true
//                    }
//                }) {
//                    Text("Get Started")
//                        .font(.headline)
//                        .foregroundColor(.white)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(Color.blue)
//                        .cornerRadius(10)
//                        .padding(.horizontal, 40)
//                }
//            }
//            .padding()
//        }
//        .fullScreenCover(isPresented: $isShowingMainApp) {
//            ContentView()
//                .environmentObject(navigationModel) // Provide NavigationModel
//                .environmentObject(appCameraState)  // Provide AppCameraState
//        }
//    }
//}
//
//#Preview {
//    WelcomeView()
//        .environmentObject(AppCameraState())  // Preview setup
//        .environmentObject(NavigationModel()) // Preview setup
//}
import SwiftUI

struct WelcomeView: View {
    @State private var currentPage = 0 // Track the current intro screen
    @State private var isShowingMainApp = false // Track transition to ContentView
    
    @EnvironmentObject var navigationModel: NavigationModel
    @EnvironmentObject var appCameraState: AppCameraState
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                IntroScreen(imageName: "intro1")
                    .tag(0)
                
                IntroScreen(imageName: "intro2")
                    .tag(1)
                
                IntroScreen(imageName: "intro3")
                    .tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            Spacer()
            
            Button(action: {
                if currentPage < 2 {
                    withAnimation {
                        currentPage += 1 // Move to the next intro screen
                    }
                } else {
                    withAnimation {
                        isShowingMainApp = true // Navigate to ContentView
                    }
                }
            }) {
                Text(currentPage < 2 ? "Next" : "Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
            }
        }
        .fullScreenCover(isPresented: $isShowingMainApp) {
            NavigationStack(path: $navigationModel.navPath) {
                ContentView()
                    .navigationDestination(for: NavigationRoutes.self) { $0 }
            }
            .sheet(isPresented: $navigationModel.isPresentingItem) {
                navigationModel.presentedItem?
                    .interactiveDismissDisabled(false)
                    .presentationDragIndicator(.hidden)
            }
            .environmentObject(appCameraState)
            .environmentObject(navigationModel)
            .preferredColorScheme(.dark)
            .onAppear {
                UserDefaults.standard.register(
                    defaults: [
                        Constants.frameRateKey.description: 30,
                        Constants.isHDKey.description: true,
                        Constants.isAudioEnabledKey.description: true,
                        Constants.cameraPreviewKey.description: CameraPreview.one.rawValue,
                        Constants.videoStabilizationMode.description: false,
                    ]
                )
            }
        }
    }
}

struct IntroScreen: View {
    let imageName: String // Image for the intro screen
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .padding()
            
            Spacer()
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppCameraState())
        .environmentObject(NavigationModel())
}
