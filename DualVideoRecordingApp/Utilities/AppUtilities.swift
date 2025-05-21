//
//  AppUtilities.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 26/10/24.
//

@preconcurrency import AVFoundation
import OSLog
import SwiftUI

fileprivate let logger = Logger(subsystem: "com.kidastudios.DualVideorecordingApp", category: "AppUtilities")

final class MovieRecorder: NSObject, AVCaptureFileOutputRecordingDelegate {
    let output = AVCaptureMovieFileOutput()
    
    var isRecording: Bool {
        output.isRecording
    }
    
    var recordingDuration: TimeInterval {
        output.recordedDuration.seconds
    }
    
    private var continuation: CheckedContinuation<Void, any Error>?
    
    func mirrorVideo(isMirrored: Bool) {
        output.connection(with: .video)?.isVideoMirrored = isMirrored
    }
    
    func startRecording(at url: URL) {
        output.startRecording(to: url, recordingDelegate: self)
    }
    
    func stopRecording() async throws {
        guard self.continuation == nil else {
            self.continuation?.resume(throwing: CustomError.captureCancelled)
            logger.log(level: .error, "Continuation exists, probably still recording?")
            return
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) -> Void in
            self.continuation = continuation
            output.stopRecording()
        }
    }
    
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: (any Error)?
    ) {
        if let error {
            logger.error("Recording complete with error: \(error)")
            self.continuation?.resume(throwing: CustomError.custom(message: error.localizedDescription))
            self.continuation = nil
        } else {
            logger.info("Recording complete at: \(outputFileURL)")
            self.continuation?.resume()
            self.continuation = nil
        }
    }
}

struct ThermalStateSequence: AsyncSequence {
    func makeAsyncIterator() -> AsyncStream<ProcessInfo.ThermalState>.Iterator {
        AsyncStream { continuation in
            let observer = NotificationCenter.default.addObserver(
                forName: ProcessInfo.thermalStateDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                continuation.yield(ProcessInfo.processInfo.thermalState)
            }
            
            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer)
            }
            
            // Start by yielding the current thermal state
            continuation.yield(ProcessInfo.processInfo.thermalState)
        }.makeAsyncIterator()
    }
}

final class VideoDataOutput: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let output = AVCaptureVideoDataOutput()
    
    private let queue = DispatchQueue(label: "CaptureQueue")
    private var continuation: CheckedContinuation<Data, Error>?
    
    // Add task management
    private var currentCaptureTask: Task<Data, Error>?
    private let lockQueue = DispatchQueue(label: "com.capture.lock")
    
    func setDelegate() {
        self.output.setSampleBufferDelegate(self, queue: queue)
    }
    
    private func capture() async throws -> Data {
        return try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Data, Error>) in
            guard let self = self else {
                continuation.resume(throwing: CustomError.imageEncodeFailed)
                return
            }
            
            // Ensure we're not already capturing
            lockQueue.sync {
                // Cancel any existing capture
                if self.continuation != nil {
                    self.cleanup()
                }
                
                self.continuation = continuation
                self.output.alwaysDiscardsLateVideoFrames = true
                
                Task { @MainActor in
                    self.output.setSampleBufferDelegate(self, queue: self.queue)
                }
            }
        }
    }
    
    // Wrapper method to handle concurrent calls
    func safeCaptureImage() async throws -> Data {
        // Cancel any existing task
        currentCaptureTask?.cancel()
        
        // Create and store new task
        let task: Task<Data, Error> = Task { [weak self] in
            guard let self = self else {
                throw CustomError.imageEncodeFailed
            }
            
            // Check if task was cancelled
            try Task.checkCancellation()
            
            return try await self.capture()
        }
        
        currentCaptureTask = task
        
        do {
            let result = try await task.value
            currentCaptureTask = nil
            return result
        } catch {
            currentCaptureTask = nil
            throw error
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let currentContinuation = continuation else { return }
        
        // Clear continuation first
        continuation = nil
        
        do {
            // Check if the task was cancelled
            if let task = currentCaptureTask, task.isCancelled {
                throw CustomError.captureCancelled
            }
            
            guard let imageBuffer = sampleBuffer.imageBuffer else {
                throw CustomError.imageEncodeFailed
            }
            
            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            let context = CIContext()
            
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                throw CustomError.imageEncodeFailed
            }
            
            let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
            
            guard let imageData = image.pngData() else {
                throw CustomError.imageEncodeFailed
            }
            
            self.output.setSampleBufferDelegate(nil, queue: self.queue)
            currentContinuation.resume(returning: imageData)
            
        } catch {
            currentContinuation.resume(throwing: error)
            self.output.setSampleBufferDelegate(nil, queue: self.queue)
        }
    }
    
    func cleanup() {
        output.setSampleBufferDelegate(nil, queue: queue)
        continuation?.resume(throwing: CustomError.captureCancelled)
        continuation = nil
        currentCaptureTask?.cancel()
        currentCaptureTask = nil
    }
}
