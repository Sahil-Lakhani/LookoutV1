//
//  PiPVideoMaker.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 22/12/24.
//

@preconcurrency import AVFoundation
import OSLog
import SwiftUI

fileprivate let logger = Logger(subsystem: "com.kidastudios.DualVideorecordingApp", category: "PiPVideoMaker")

enum PiPVideoMakerError: LocalizedError, CustomStringConvertible {
    case failedToCreateCompositionTracks
    case failedToCreateExportSession
    case exportFailed
    case missingVideoTracks
    case exportCancelled
    case custom(message: String)
    
    var errorDescription: String? { description }
    
    var description: String {
        switch self {
        case .failedToCreateCompositionTracks:
            "Failed to create compostion tracks"
        case .failedToCreateExportSession:
            "Failed to create export session"
        case .exportFailed:
            "Export failed"
        case .missingVideoTracks:
            "Missing Video Tracks"
        case .exportCancelled:
            "Export cancelled"
        case .custom(let message):
            message
        }
    }
}

class PiPVideoMaker {
    enum ProgressStatus: CustomStringConvertible {
        case inProgress(Progress)
        case completed
        
        var description: String {
            switch self {
            case .completed:
                "Completed"
            case .inProgress(let progress):
                "\(progress)"
            }
        }
    }
    
    private static var currentTask: Task<Void, any Error>?
    
    class func makePiPVideo(
        from mainVideoURL: URL,
        and pipVideoURL: URL,
        to outputURL: URL,
        with progressStatus: Binding<ProgressStatus>? = nil
    ) async throws(PiPVideoMakerError) {
        Self.currentTask?.cancel()
        
        let task = Task {
            try await createPictureInPictureVideo(
                mainVideoURL: mainVideoURL,
                pipVideoURL: pipVideoURL,
                outputURL: outputURL,
                progressStatus: progressStatus
            )
        }
        
        Self.currentTask = task
        defer {
            Self.currentTask = nil
        }
        
        do {
            return try await task.value
        } catch {
            if let pipError = error as? PiPVideoMakerError {
                throw pipError
            }
            
            if error is CancellationError {
                throw PiPVideoMakerError.exportCancelled
            }
            
            let nsError = error as NSError
            throw PiPVideoMakerError.custom(message: nsError.localizedFailureReason ?? nsError.localizedDescription)
        }
    }
    
    private class func createPictureInPictureVideo(
        mainVideoURL: URL,
        pipVideoURL: URL,
        outputURL: URL,
        progressStatus: Binding<ProgressStatus>? = nil
    ) async throws {
        try Task.checkCancellation()
        let composition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition()
        
        // 1. Load assets
        let mainAsset = AVURLAsset(url: mainVideoURL)
        let pipAsset = AVURLAsset(url: pipVideoURL)
        
        // 2. Add tracks to composition
        guard let compositionTrack1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let compositionTrack2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw PiPVideoMakerError.failedToCreateCompositionTracks
        }
        
        // 3. Insert main video and audio
        let mainDuration = try await mainAsset.load(.duration)
        let mainVideoTrack = try await mainAsset.loadTracks(withMediaType: .video)[0]
        
        // 3.5. Insert Audio track only if it is available!
        let audioTracks = try await mainAsset.loadTracks(withMediaType: .audio)
        if let mainAudioTrack = audioTracks.first, try await mainAudioTrack.load(.isEnabled),
           let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            try compositionAudioTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: mainDuration),
                of: mainAudioTrack,
                at: .zero
            )
        }
        
        try compositionTrack1.insertTimeRange(CMTimeRange(start: .zero, duration: mainDuration), of: mainVideoTrack, at: .zero)
        
        // 4. Insert PiP video
        let pipVideoTrack = try await pipAsset.loadTracks(withMediaType: .video)[0]
        let pipDuration = try await pipAsset.load(.duration)
        
        try compositionTrack2.insertTimeRange(CMTimeRange(start: .zero, duration: pipDuration), of: pipVideoTrack, at: .zero)
        
        // 5. Prepare video composition
        let mainSize = try await mainVideoTrack.load(.naturalSize)
        let minFrameDuration = try await mainVideoTrack.load(.minFrameDuration)
        
        let _ = CMTime(value: 1, timescale: 30)
        videoComposition.frameDuration = minFrameDuration
        videoComposition.renderSize = CGSize(width: mainSize.height, height: mainSize.width)
        
        // 6. Create instructions
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        
        let layer1Instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack1)
        layer1Instruction.setTransform(Self.rotTransform(for: mainSize), at: .zero)
        
        let layer2Instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack2)
        
        // 7. Configure PiP transform
        let pipSize = CGSize(width: mainSize.width / 3, height: mainSize.height / 3)
        let pipNaturalSize = try await pipVideoTrack.load(.naturalSize)
        
        let xTranslation: CGFloat = Self.flipFFC ? pipSize.width * -0.5 : 0.0
        let pipTransformYFlip: CGFloat = flipFFC ? -1 : 1
        
        let pipTranslation = CGAffineTransformMakeTranslation(xTranslation, mainSize.height * 1.25)
        let pipTransform = CGAffineTransform(
            scaleX: pipSize.width / pipNaturalSize.width,
            y: pipTransformYFlip * pipSize.height / pipNaturalSize.height
        ).concatenating(Self.rotTransform(for: mainSize)).concatenating(pipTranslation)
        
        layer2Instruction.setTransform(pipTransform, at: .zero)
        layer2Instruction.setOpacity(1.0, at: .zero)
        
        instruction.layerInstructions = [layer2Instruction, layer1Instruction]
        videoComposition.instructions = [instruction]
        
        // 8. Export
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw PiPVideoMakerError.failedToCreateExportSession
        }
        
        exportSession.videoComposition = videoComposition
        if #available(iOS 18, *) {
            let task = Task {
                try await exportSession.export(to: outputURL, as: .mov)
            }
            for await newStatus in exportSession.states(updateInterval: 0.33) {
                if Task.isCancelled {
                    task.cancel()
                    progressStatus?.wrappedValue = .completed
                }
                Task { @MainActor in
                    switch newStatus {
                    case .exporting(progress: let progress):
                        logger.info("Working on export: \(progress)")
                        progressStatus?.wrappedValue = .inProgress(progress)
                        break
                    default:
                        progressStatus?.wrappedValue = .completed
                        break
                    }
                }
            }
            Task { @MainActor in
                progressStatus?.wrappedValue = .completed
            }
            try await task.value
        } else {
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mov
            
            let progress = Progress(totalUnitCount: 10)
            progress.completedUnitCount = 5
            Task { @MainActor in
                progressStatus?.wrappedValue = .inProgress(progress)
            }
            if Task.isCancelled {
                Task { @MainActor in
                    progressStatus?.wrappedValue = .completed
                }
                throw CancellationError()
            }
            await exportSession.export()
            
            progress.completedUnitCount = 10
            Task { @MainActor in
                progressStatus?.wrappedValue = .inProgress(progress)
            }
            try? await Task.sleep(for: .milliseconds(500))
            Task { @MainActor in
                progressStatus?.wrappedValue = .completed
            }
        }
        switch exportSession.status {
        case .unknown:
            logger.info("UnKnown")
        case .waiting:
            logger.info("Waiting")
        case .exporting:
            logger.info("Exporting")
        case .completed:
            logger.info("Completed")
        case .failed:
            logger.info("Failed")
        case .cancelled:
            logger.info("Cancelled")
        default:
            break
        }
        if exportSession.status != .completed {
            throw exportSession.error ?? PiPVideoMakerError.exportFailed
        }
    }
    
    private class func rotTransform(for size: CGSize) -> CGAffineTransform {
        let rotTransform = CGAffineTransformMakeRotation(CGFloat(90) * CGFloat.pi / 180)
        let rotTranslate = CGAffineTransformMakeTranslation(size.height, 0)
        return CGAffineTransformConcat(rotTransform, rotTranslate)
    }
}

extension PiPVideoMaker {
    static let flipFFC = true
}
