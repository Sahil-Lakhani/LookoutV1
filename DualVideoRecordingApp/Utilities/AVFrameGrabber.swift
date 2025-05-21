//
//  AVFrameGrabber.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 01/11/24.
//

import AVFoundation
import OSLog
import SwiftUI

fileprivate let logger = Logger(subsystem: "com.kidastudios.DualVideoRecordingApp", category: "AVFrameGrabber")

enum AVFrameGrabber {
    static func grabFrame(forMovies movies: [MovieMedia]) -> AsyncThrowingStream<(MovieMedia.ID, UIImage), Error> {
        AsyncThrowingStream { continuation in
            Task {
                for movie in movies {
                    do {
                        let image = try await grabFrame(ofURL: movie.mediaFile)
                        continuation.yield((movie.id, image))
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    }
    
    static func grabFrame(for move: MovieMedia) async throws -> (MovieMedia.ID, UIImage) {
        let thumbnail = try await grabFrame(ofURL: move.mediaFile)
        return (move.id, thumbnail)
    }
    
    static func grabFrameIgnoreError(for move: MovieMedia) async -> (MovieMedia.ID, UIImage)? {
        do {
            let thumbnail = try await grabFrame(ofURL: move.mediaFile)
            return (move.id, thumbnail)
        } catch {
            logger.error("Failed to generate thumbnail for movie: \(move.id)")
            return nil
        }
    }
    
    static func makeThumbnail(forURL movieURL: URL) async throws -> UIImage {
        let thumbnailImage = try await grabFrame(ofURL: movieURL)
        return downSize(image: thumbnailImage)
    }
    
    static private func grabFrame(ofURL videoURL: URL) async throws -> UIImage {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let result: CGImage = try await generate(with: generator)
        let thumbnail = downSize(image: UIImage(cgImage: result))
        return thumbnail
    }
    
    static private func generate(with generator: AVAssetImageGenerator) async throws -> CGImage {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CGImage, Error>) in
            generator.generateCGImageAsynchronously(for: .zero) { (cgImageOrNil: CGImage?, _: CMTime, errorOrNil: Error?) in
                switch (cgImageOrNil, errorOrNil) {
                case let (cgImage?, nil):
                    continuation.resume(returning: cgImage)
                case let (_, error?):
                    continuation.resume(throwing: error)
                case (nil, nil):
                    continuation.resume(throwing: AVFrameGrabberError.thumbnailGenerationFailed)
                }
            }
        }
    }
    
    static func downSize(image: UIImage, byFactor: CGFloat = 2) -> UIImage {
        let newSize = CGSize(width: image.size.width / byFactor, height: image.size.height / byFactor)
        let rect = CGRect(origin: .zero, size: newSize)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let newImage = renderer.image { _ in
            image.draw(in: rect)
        }
        return newImage
    }
}

enum AVFrameGrabberError: LocalizedError, CustomStringConvertible {
    case thumbnailGenerationFailed
    
    var errorDescription: String? {
        "An Error has occurred: \(description)."
    }
    
    var description: String {
        switch self {
        case .thumbnailGenerationFailed:
            "Failed to generate thumbnail."
        }
    }
}
