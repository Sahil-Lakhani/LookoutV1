//
//  TrimmingVideoView.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 24/11/24.
//

import SwiftUI

struct TrimmingVideoView: UIViewControllerRepresentable {
    enum Result {
        case success(URL)
        case failure(CustomError)
        case cancelled
    }
    
    let fileURL: URL
    let completion: (TrimmingVideoView.Result) -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIVideoEditorController {
        let vc = UIVideoEditorController()
        vc.delegate = context.coordinator
        vc.videoPath = fileURL.path
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIVideoEditorController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion, dismiss: dismiss)
    }
    
    class Coordinator: NSObject, UIVideoEditorControllerDelegate, UINavigationControllerDelegate {
        var dismiss: DismissAction
        let completion: (TrimmingVideoView.Result) -> Void
        
        init(_ completion: @escaping (TrimmingVideoView.Result) -> Void, dismiss: DismissAction) {
            self.completion = completion
            self.dismiss = dismiss
        }
        
        func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
            let url = URL(filePath: editedVideoPath)
            completion(.success(url))
            dismiss.callAsFunction()
        }
        
        func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: any Error) {
            let nsError = error as NSError
            let customError: CustomError = .custom(message: nsError.localizedFailureReason ?? "" + nsError.localizedDescription)
            completion(.failure(customError))
            dismiss.callAsFunction()
        }
        
        func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
            completion(.cancelled)
            dismiss.callAsFunction()
        }
    }
}
