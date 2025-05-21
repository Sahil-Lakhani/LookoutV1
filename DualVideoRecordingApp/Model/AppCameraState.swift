//
//  AppCameraState.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 26/10/24.
//

import Algorithms
@preconcurrency import AVFoundation
import OSLog
import SwiftUI

fileprivate let logger = Logger(subsystem: "com.kidastudios.DualVideoRecordingApp", category: "AppCameraState")

struct CameraDebug: CustomStringConvertible {
    let didAddBackInput: Bool
    let didAddBackOutput: Bool
    
    let didAddFrontInput: Bool
    let didAddFrontOutput: Bool
    
    let didAddAudio: Bool
    
    static var `default`: CameraDebug {
        CameraDebug(
            didAddBackInput: false,
            didAddBackOutput: false,
            didAddFrontInput: false,
            didAddFrontOutput: false,
            didAddAudio: false
        )
    }
    
    private static func didAddText(_ didAdd: Bool) -> String {
        didAdd ? "Added" : "Not Added"
    }
    
    var description: String {
        var description = "Camera Debug: "
        description += "Back Input: \(Self.didAddText(didAddBackInput)), "
        description += "Front Input: \(Self.didAddText(didAddFrontInput)), "
        description += "Back Output: \(Self.didAddText(didAddBackOutput)), "
        description += "Front Output: \(Self.didAddText(didAddFrontOutput)), "
        description += "Audio: \(Self.didAddText(didAddAudio))"
        return description
    }
}

final class AppCameraState: ObservableObject {
    let session = AVCaptureMultiCamSession()
    
    @Published var isCameraActive: Bool = false
    
    @Published var error: CustomError?
    
    @Published var backCamera: AVCaptureDevice?
    @Published var frontCamera: AVCaptureDevice?
    
    @Published var frameRate: Int = UserDefaults.standard.integer(forKey: Constants.frameRateKey.description)
    
    @Published var cameraDebug: CameraDebug = .default
    
    let frontPreviewLayer = PreviewLayer()
    let backPreviewLayer = PreviewLayer()
    
    private let backVideoDataOutput = VideoDataOutput()
    private let frontVideoDataOutput = VideoDataOutput()
    
    private let backMovieOutput = MovieRecorder()
    private let frontMovieOutput = MovieRecorder()
    
    deinit {
        backVideoDataOutput.cleanup()
        frontVideoDataOutput.cleanup()
    }
    
    var isRecording: Bool {
        backMovieOutput.isRecording
    }
    
    var showError: Bool {
        get { self.error != nil }
        set { self.error = nil }
    }
    
    var formattedResolution: String {
        let dimensions = backCamera?.activeFormat.formatDescription.dimensions
        let format = dimensions?.height == 1080 ? "FHD" : "HD"
        return format
    }
    
    var recordedDuration: TimeInterval {
        backMovieOutput.recordingDuration
    }
    
    func startSession() {
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
            backVideoDataOutput.cleanup()
            frontVideoDataOutput.cleanup()
        }
    }
    
    func captureScreen(completion: @escaping (CustomError?) -> Void) {
        Task { [backVideoDataOutput, frontVideoDataOutput] in
            let date = Date()
            let frontUrl = URL.newPhotoDirectory(fromBackCamera: false, forDate: date)
            let backUrl = URL.newPhotoDirectory(fromBackCamera: true, forDate: date)
            do {
                try await withThrowingTaskGroup(of: (Data, URL).self) { group in
                    group.addTask {
                        let backScreenshot = try await backVideoDataOutput.safeCaptureImage()
                        return (backScreenshot, backUrl)
                    }
                    
                    if AVCaptureMultiCamSession.isMultiCamSupported {
                        group.addTask {
                            let frontScreenshot = try await frontVideoDataOutput.safeCaptureImage()
                            return (frontScreenshot, frontUrl)
                        }
                    }
                    
                    for try await (screenshot, url) in group {
                        try screenshot.write(to: url, options: .atomic)
                    }
                }
                logger.debug("Done!")
                completion(nil)
            } catch {
                logger.error("Error capturing screen: \(error)")
                let nserror = error as NSError
                completion(CustomError.custom(message: nserror.localizedFailureReason ?? nserror.localizedDescription))
            }
        }
    }
    
    func startRecording() {
        let now = Date().truncatedToSecond().ISO8601Format(.iso8601WithTimeZone())
        let backMovieURL = URL.newMovieDirectory(fromBackCamera: true, onDateString: now)
        backMovieOutput.startRecording(at: backMovieURL)
        self.objectWillChange.send()
        
        // MARK: - Recording if isMultiCamSupported
        if AVCaptureMultiCamSession.isMultiCamSupported {
            let frontMovieURL = URL.newMovieDirectory(fromBackCamera: false, onDateString: now)
            frontMovieOutput.mirrorVideo(isMirrored: PiPVideoMaker.flipFFC)
            frontMovieOutput.startRecording(at: frontMovieURL)
        }
    }
    
    func stopRecording() {
        Task {
            do {
                try await backMovieOutput.stopRecording()
            } catch {
                catchError(error: error, prefixMessage: "Error recording from \"Back Camera\"!")
            }
            // MARK: - Recording if isMultiCamSupported
            if AVCaptureMultiCamSession.isMultiCamSupported {
                do {
                    try await frontMovieOutput.stopRecording()
                } catch {
                    catchError(error: error, prefixMessage: "Error recording from \"Front Camera\"!")
                }
            }
            // self.objectWillChange.send()
        }
    }
    
    @MainActor
    func checkAndRequestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            let didGrant = await AVCaptureDevice.requestAccess(for: .video)
            self.isCameraActive = didGrant
            if !didGrant {
                self.error = .cameraAccessDenied
            }
        case .authorized:
            self.isCameraActive = true
        default: // assume camera access was denied
            self.isCameraActive = false
            self.error = .cameraAccessDenied
        }
        return self.isCameraActive
    }
    
    func setupCameras() {
        var didAddBackInput = false
        var didAddBackOutput = false
        var didAddFrontInput = false
        var didAddFrontOutput = false
        var didAddAudio = false
        
        // MARK: - Setting up back camera
        if let ultraWideBackCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            self.backCamera = ultraWideBackCamera
            do {
                let input = try AVCaptureDeviceInput(device: ultraWideBackCamera)
                
                if session.canAddInput(input) {
                    session.addInput(input)
                    didAddBackInput = true
                }
                if session.canAddOutput(backMovieOutput.output) {
                    session.addOutput(backMovieOutput.output)
                    didAddBackOutput = true
                }
            } catch {
                catchError(error: error, prefixMessage: "Error setting up back camera")
            }
            setLoadedFrameRateAndRes(to: self.backCamera)
        } else if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            self.backCamera = backCamera
            do {
                let input = try AVCaptureDeviceInput(device: backCamera)
                
                if session.canAddInput(input) {
                    session.addInput(input)
                    didAddBackInput = true
                }
                if session.canAddOutput(backMovieOutput.output) {
                    session.addOutput(backMovieOutput.output)
                    didAddBackOutput = true
                }
            } catch {
                catchError(error: error, prefixMessage: "Error setting up back camera")
            }
            setLoadedFrameRateAndRes(to: self.backCamera)
        }
        
        // MARK: - Setting up front camera if compatible
        if AVCaptureMultiCamSession.isMultiCamSupported {
            if let ultraWideFrontCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .front) {
                self.frontCamera = frontCamera
                do {
                    let input = try AVCaptureDeviceInput(device: ultraWideFrontCamera)
                    
                    if session.canAddInput(input) {
                        session.addInput(input)
                        didAddFrontInput = true
                    }
                    if session.canAddOutput(frontMovieOutput.output) {
                        session.addOutput(frontMovieOutput.output)
                        didAddFrontOutput = true
                    }
                } catch {
                    catchError(error: error, prefixMessage: "Error setting up front camera")
                }
                setLoadedFrameRateAndRes(to: self.frontCamera)
            } else if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                self.frontCamera = frontCamera
                do {
                    let input = try AVCaptureDeviceInput(device: frontCamera)
                    
                    if session.canAddInput(input) {
                        session.addInput(input)
                        didAddFrontInput = true
                    }
                    if session.canAddOutput(frontMovieOutput.output) {
                        session.addOutput(frontMovieOutput.output)
                        didAddFrontOutput = true
                    }
                } catch {
                    catchError(error: error, prefixMessage: "Error setting up front camera")
                }
                setLoadedFrameRateAndRes(to: self.frontCamera)
            }
        }
        
        // MARK: - Setting up microphone
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            do {
                let input = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(input) {
                    session.addInput(input)
                    didAddAudio = true
                }
                let hasMic = session.inputs.contains(where: { $0.ports.contains(where: { $0.mediaType == .audio }) })
                if !hasMic {
                    throw CustomError.custom(message: "Mic is being used by another app")
                }
            } catch {
                catchError(error: error, prefixMessage: "Error setting up audio device")
            }
        }
        
        self.cameraDebug = CameraDebug(
            didAddBackInput: didAddBackInput,
            didAddBackOutput: didAddBackOutput,
            didAddFrontInput: didAddFrontInput,
            didAddFrontOutput: didAddFrontOutput,
            didAddAudio: didAddAudio
        )
        
        // MARK: - Load isAudioDeviceEnabled preference
        self.isAudioDeviceEnabled = UserDefaults.standard.bool(forKey: Constants.isAudioEnabledKey.description)
        
        // MARK: - Setting up data outputs
        if session.canAddOutput(backVideoDataOutput.output) {
            session.addOutput(backVideoDataOutput.output)
            backVideoDataOutput.setDelegate()
        }
        if AVCaptureMultiCamSession.isMultiCamSupported && session.canAddOutput(frontVideoDataOutput.output) {
            session.addOutput(frontVideoDataOutput.output)
            frontVideoDataOutput.setDelegate()
        }
        
        // MARK: - Set up fro video stabilization
        let isStabilizationSupported = session.connections.first?.isVideoStabilizationSupported
        guard isStabilizationSupported == true else { return }
        
        let prefersVideoStabilization = UserDefaults.standard.bool(forKey: Constants.videoStabilizationMode.description)
        session.connections.forEach { connection in
            connection.preferredVideoStabilizationMode = prefersVideoStabilization ? .auto : .off
        }
    }
    
    func updateFrameRate(to frameRate: Int, on camera: AVCaptureDevice?) {
        do {
            try camera?.lockForConfiguration()
            
            camera?.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            camera?.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            
            camera?.unlockForConfiguration()
            
            Task { @MainActor in
                self.frameRate = frameRate
            }
        } catch {
            print(error)
            catchError(error: error, prefixMessage: "Error setting camera frame rate and resolution")
        }
    }
    
    func updateFormat(to resolution: AVCaptureDevice.Format, on camera: AVCaptureDevice?) {
        do {
            try camera?.lockForConfiguration()
            
            camera?.activeFormat = resolution
            
            camera?.unlockForConfiguration()
        } catch {
            catchError(error: error, prefixMessage: "Error setting camera frame rate and resolution")
        }
    }
    
    func setLoadedFrameRateAndRes(to camera: AVCaptureDevice?) {
        do {
            try camera?.lockForConfiguration()
            
            // MARK: - Find correct resolution
            let resolutions = camera?.formats
                .filter(\.isMultiCamSupported)
                .filter(Self.filterResolution(_:))
                .uniqued(on: Self.formatDescription(for:)) ?? []
            
            let isHD = UserDefaults.standard.bool(forKey: Constants.isHDKey.description)
            
            let dimensionHeight = isHD ? 720 : 1080
            let resolution = resolutions.first(where: { $0.formatDescription.dimensions.height == dimensionHeight })
            
            if let resolution {
                camera?.activeFormat = resolution
            }
            
            // MARK: - Load FPS
            self.frameRate = UserDefaults.standard.integer(forKey: Constants.frameRateKey.description)
            
            camera?.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            camera?.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            
            camera?.unlockForConfiguration()
        } catch {
            catchError(error: error, prefixMessage: "Error setting camera frame rate and resolution")
        }
    }
    
    var isAudioDeviceEnabled: Bool {
        get {
            let audioPorts: [AVCaptureInput.Port] = session.inputs.flatMap(\.ports).filter({ $0.mediaType == .audio })
            return audioPorts.allSatisfy(\.isEnabled)
        } set {
            let audioPorts: [AVCaptureInput.Port] = session.inputs.flatMap(\.ports).filter({ $0.mediaType == .audio })
            for port in audioPorts {
                port.isEnabled = newValue
            }
            Task { @MainActor in
                self.objectWillChange.send()
            }
        }
    }
    
    class func filterResolution(_ format: AVCaptureDevice.Format) -> Bool {
        let resolution = format.formatDescription.dimensions
        let frameRateRanges = format.videoSupportedFrameRateRanges
        
        let resolutionCondition = (resolution.width == 1920 && resolution.height == 1080) || resolution.height == 720
        let fpsCondition = frameRateRanges.contains(where: { $0.maxFrameRate >= 30 })
        
        return resolutionCondition && fpsCondition
    }
    
    class func formatDescription(for format: AVCaptureDevice.Format) -> String {
        let dimensions = format.formatDescription.dimensions
        return "\(dimensions.width)x\(dimensions.height)"
    }
    
    private func catchError(error: Error, prefixMessage: String = "") {
        var message = prefixMessage
        if let locError = error as? LocalizedError {
            message += locError.errorDescription ?? String(describing: locError)
        } else {
            let nsError = error as NSError
            message += nsError.description
        }
        Task { @MainActor in
            self.error = .custom(message: message)
        }
        logger.error("\(message)")
    }
}
