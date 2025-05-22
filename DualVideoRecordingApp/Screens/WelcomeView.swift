// import SwiftUI

// struct WelcomeView: View {
//     @State private var currentPage = 0 // Track the current intro screen
//     @State private var isShowingMainApp = false // Track transition to ContentView
    
//     @EnvironmentObject var navigationModel: NavigationModel
//     @EnvironmentObject var appCameraState: AppCameraState
    
//     var body: some View {
//         VStack {
//             TabView(selection: $currentPage) {
//                 IntroScreen(imageName: "intro1")
//                     .tag(0)
                
//                 IntroScreen(imageName: "intro2")
//                     .tag(1)
                
//                 IntroScreen(imageName: "intro3")
//                     .tag(2)
//             }
//             .tabViewStyle(.page)
//             .indexViewStyle(.page(backgroundDisplayMode: .always))
            
//             Spacer()
            
//             Button(action: {
//                 if currentPage < 2 {
//                     withAnimation {
//                         currentPage += 1 // Move to the next intro screen
//                     }
//                 } else {
//                     withAnimation {
//                         isShowingMainApp = true // Navigate to ContentView
//                     }
//                 }
//             }) {
//                 Text(currentPage < 2 ? "Next" : "Get Started")
//                     .font(.headline)
//                     .foregroundColor(.white)
//                     .padding()
//                     .frame(maxWidth: .infinity)
//                     .background(Color.blue)
//                     .cornerRadius(10)
//                     .padding(.horizontal, 40)
//             }
//         }
//         .fullScreenCover(isPresented: $isShowingMainApp) {
//             NavigationStack(path: $navigationModel.navPath) {
//                 ContentView()
//                     .navigationDestination(for: NavigationRoutes.self) { $0 }
//             }
//             .sheet(isPresented: $navigationModel.isPresentingItem) {
//                 navigationModel.presentedItem?
//                     .interactiveDismissDisabled(false)
//                     .presentationDragIndicator(.hidden)
//             }
//             .environmentObject(appCameraState)
//             .environmentObject(navigationModel)
//             .preferredColorScheme(.dark)
//             .onAppear {
//                 UserDefaults.standard.register(
//                     defaults: [
//                         Constants.frameRateKey.description: 30,
//                         Constants.isHDKey.description: true,
//                         Constants.isAudioEnabledKey.description: true,
//                         Constants.cameraPreviewKey.description: CameraPreview.one.rawValue,
//                         Constants.videoStabilizationMode.description: false,
//                     ]
//                 )
//             }
//         }
//     }
// }

// struct IntroScreen: View {
//     let imageName: String // Image for the intro screen
    
//     var body: some View {
//         VStack {
//             Spacer()
            
//             Image(imageName)
//                 .resizable()
//                 .scaledToFit()
//                 .padding()
            
//             Spacer()
//         }
//     }
// }

// #Preview {
//     WelcomeView()
//         .environmentObject(AppCameraState())
//         .environmentObject(NavigationModel())
// }

import SwiftUI

struct WelcomeView: View {
    @State private var currentPage = 0 // Track the current intro screen
    @State private var isShowingMainApp = false // Track transition to ContentView
    
    @EnvironmentObject var navigationModel: NavigationModel
    @EnvironmentObject var appCameraState: AppCameraState
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    FirstIntroScreen()
                        .tag(0)
                    
                    SecondIntroScreen()
                        .tag(1)
                    
                    ThirdIntroScreen()
                        .tag(2)
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Bottom section with Next button
                VStack(spacing: 20) {
                    Button(action: {
                        if currentPage < 2 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1 // Move to the next intro screen
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isShowingMainApp = true // Navigate to ContentView
                            }
                        }
                    }) {
                        Text(currentPage < 2 ? "Next" : "Get Started")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 40)
            }
            
            // Skip button in top right corner (only for first two screens)
            if currentPage < 2 {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isShowingMainApp = true
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 10)
                    }
                    Spacer()
                }
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

// MARK: - First Intro Screen
struct FirstIntroScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            // Title Section
            VStack(alignment: .center, spacing: 8) {
                Text("Dual Capture, Double the Perspective")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Effortlessly record your front and rear views at the same time. Perfect for capturing every angle, seamlessly.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Image Section
            ZStack {
                Image("firstImage")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 400)
            }
        }
    }
}

// MARK: - Second Intro Screen
struct SecondIntroScreen: View {
    var body: some View {
        VStack {
            // Add your custom UI here for screen 2
            Text("Second Screen")
            Image("intro2")
                .resizable()
                .scaledToFit()
        }
    }
}

// MARK: - Third Intro Screen
struct ThirdIntroScreen: View {
    var body: some View {
        VStack {
            // Add your custom UI here for screen 3
            Text("Third Screen")
            Image("intro3")
                .resizable()
                .scaledToFit()
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppCameraState())
        .environmentObject(NavigationModel())
}