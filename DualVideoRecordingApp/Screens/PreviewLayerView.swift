//
//  PreviewLayerView.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 26/10/24.
//

@preconcurrency import AVFoundation
import SwiftUI


struct PreviewLayerView: UIViewRepresentable {
    typealias SwipeAction = (UISwipeGestureRecognizer.Direction) -> Void
    
    let session: AVCaptureSession
    let uiView: PreviewLayer
    let frame: CGRect
    let swipeAction: SwipeAction
    let onDoubleTap: () -> Void
    
    init(
        _ session: AVCaptureSession,
        with layer: PreviewLayer,
        in frame: CGRect,
        swipeAction: @escaping SwipeAction = { _ in },
        onDoubleTap: @escaping () -> Void = { }
    ) {
        self.session = session
        self.uiView = layer
        self.frame = frame
        self.swipeAction = swipeAction
        self.onDoubleTap = onDoubleTap
    }
    
    func makeUIView(context: Context) -> PreviewLayer {
        uiView.previewLayer.frame = frame
        uiView.setSession(to: session)
//        setVideoOrientation()
        
        let tapGestureRecognizer = Self.TapInteraction(target: context.coordinator, withTouchCount: 1)
        uiView.addGestureRecognizer(tapGestureRecognizer)
        
        let verticalSwipe1 = Self.SwipeInteraction(target: context.coordinator, in: .up)
        let verticalSwipe2 = Self.SwipeInteraction(target: context.coordinator, in: .down)
        uiView.addGestureRecognizer(verticalSwipe1)
        uiView.addGestureRecognizer(verticalSwipe2)
        
        return uiView
    }
    
    func updateUIView(_ uiView: PreviewLayer, context: Context) {
        uiView.previewLayer.frame = frame
//        setVideoOrientation()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(swipeAction, onDoubleTap: onDoubleTap)
    }
    
    private func setVideoOrientation() {
        if let connection = uiView.previewLayer.connection {
            if connection.inputPorts.contains(where: { $0.sourceDevicePosition == .back }) {
                if #available(iOS 17, *) {
                    uiView.previewLayer.connection?.videoRotationAngle = UIDevice.current.orientation.videoRotationAngle
                } else {
                    uiView.previewLayer.connection?.videoOrientation = UIDevice.current.orientation.videoOrientation
                }
            }
            if connection.inputPorts.contains(where: { $0.sourceDevicePosition == .front }) {
                if #available(iOS 17, *) {
                    uiView.previewLayer.connection?.videoRotationAngle = UIDevice.current.orientation.frontVideoRotationAngle
                } else {
                    uiView.previewLayer.connection?.videoOrientation = UIDevice.current.orientation.videoOrientation
                }
            }
        }
    }
}

extension PreviewLayerView {
    static func TapInteraction(
        target: Any?,
        withTouchCount numberOfTouchesRequired: Int = 1
    ) -> UITapGestureRecognizer {
        let recognizer = UITapGestureRecognizer(
            target: target,
            action: #selector(Coordinator.respondToTap(_:))
        )
        recognizer.numberOfTapsRequired = 2
        recognizer.numberOfTouchesRequired = numberOfTouchesRequired
        
        return recognizer
    }
    
    static func SwipeInteraction(
        target: Any?,
        in direction: UISwipeGestureRecognizer.Direction,
        withTouchCount numberOfTouchesRequired: Int = 1
    ) -> UISwipeGestureRecognizer {
        let recognizer = UISwipeGestureRecognizer(
            target: target,
            action: #selector(Coordinator.respondToGesture)
        )
        recognizer.numberOfTouchesRequired = numberOfTouchesRequired
        recognizer.direction = direction
        
        return recognizer
    }
    
    class Coordinator: NSObject {
        let swipeAction: PreviewLayerView.SwipeAction
        let onDoubleTap: () -> Void
        
        init(
            _ swipeAction: @escaping PreviewLayerView.SwipeAction,
            onDoubleTap: @escaping () -> Void
        ) {
            self.swipeAction = swipeAction
            self.onDoubleTap = onDoubleTap
        }
        
        @objc func respondToTap(_ gesture: UIGestureRecognizer) {
            guard let tapGesture = gesture as? UITapGestureRecognizer else {
                NSLog("Not a tap gesture!")
                return
            }
            
            if tapGesture.numberOfTapsRequired == 2 {
                self.onDoubleTap()
            }
        }
        
        @objc func respondToGesture(_ gesture: UIGestureRecognizer) {
            guard let swipeGesture = gesture as? UISwipeGestureRecognizer else {
                NSLog("Not a swipe gesture!")
                return
            }
            
            let direction = swipeGesture.direction
            
            self.swipeAction(direction)
        }
    }
}

final class PreviewLayer: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        previewLayer.session
    }
    
    func setSession(to session: AVCaptureSession) {
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.session = session
    }
    
    // this function handles touch to AutoExpose and AutoFocus only on the back/rear camera!
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let firstTouch = touches.first else { return }
        let screenSize = bounds.size
        let focusPoint = CGPoint(
            x: firstTouch.location(in: self).y / screenSize.height,
            y: 1.0 - firstTouch.location(in: self).x / screenSize.width
        )
        
        guard let session else { return }
        
        let cameraInputOrNil: AVCaptureInput? = session.inputs.first { (input: AVCaptureInput) in
            let portFilter = { (p: AVCaptureInput.Port) in
                p.mediaType == .video && p.sourceDevicePosition == .back
            }
            return input.ports.contains(where: portFilter)
        }
        
        if let cameraInput = cameraInputOrNil as? AVCaptureDeviceInput {
            do {
                try cameraInput.device.lockForConfiguration()
                if cameraInput.device.isFocusPointOfInterestSupported {
                    cameraInput.device.focusPointOfInterest = focusPoint
                    cameraInput.device.focusMode = .continuousAutoFocus
                }
                if cameraInput.device.isExposurePointOfInterestSupported {
                    cameraInput.device.exposurePointOfInterest = focusPoint
                    cameraInput.device.exposureMode = .continuousAutoExposure
                }
                cameraInput.device.unlockForConfiguration()
            } catch {
                print("Error locking device for focus and exposure: ", error)
            }
        }
    }
}
