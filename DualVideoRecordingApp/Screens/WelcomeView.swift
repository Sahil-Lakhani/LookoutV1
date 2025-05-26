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
            VStack {
                // TabView for Intro Screens
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
                // .padding(.vertical, 20)
                
                // Navigation Button
                Button(action: {
                    if currentPage < 2 {
                        withAnimation(.easeInOut) { currentPage += 1 }
                    } else {
                        withAnimation(.easeInOut) { isShowingMainApp = true }
                    }
                }) {
                    Text(currentPage < 2 ? "Next" : "Get Started")
                        .font(.headline)
                        .fontWeight(.medium)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 30)
            }
            
            // Skip Button
            if currentPage < 2 {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut) { isShowingMainApp = true }
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                                .padding(10)
                                .background(Color.white.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 50)
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill available space
        .ignoresSafeArea()
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
        VStack(spacing: 10) {
            Text("Dual Capture, Double the Perspective")
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Text("Effortlessly record your front and rear views at the same time. Perfect for capturing every angle, seamlessly.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Image("firstImage")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300, maxHeight: 450)
                .padding(.bottom, 30)
        }
    }
}

// MARK: - Second Intro Screen
struct SecondIntroScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Capture Every Moment")
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Text("Your memories, captured in stunning detail with advanced dual camera support.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
            
            Image("intro2")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 250, maxHeight: 350)
                .padding(.bottom, 40)
        }
    }
}

// MARK: - Third Intro Screen
struct ThirdIntroScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Ready to Get Started?")
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Text("Let’s dive in and explore the full potential of dual camera technology.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
            
            Image("intro3")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 250, maxHeight: 350)
                .padding(.bottom, 40)
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppCameraState())
        .environmentObject(NavigationModel())
}
