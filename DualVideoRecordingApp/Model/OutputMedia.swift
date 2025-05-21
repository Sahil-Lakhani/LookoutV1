//
//  OutputMedia.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 29/10/24.
//

import SwiftUI

enum MediaFileWrapper: Identifiable, Hashable {
    case movie(MovieMedia)
    case photo(PhotoMedia)
    
    var id: UUID {
        switch self {
        case .movie(let movieMedia):
            movieMedia.id
        case .photo(let photoMedia):
            photoMedia.id
        }
    }
}

protocol MediaProtocol: Identifiable, Hashable, Transferable {
    var id: UUID { get }
    var displayName: String { get }
    var mediaFile: URL { get }
    var creationDate: Date { get }
    
    var sharePreview: SharePreview<Image, Never> { get }
    
    var menuLabel: Label<Text, Image> { get }
}

struct MovieMedia: MediaProtocol, Comparable {
    let id = UUID()
    let displayName: String
    let mediaFile: URL
    let creationDate: Date
    var uiImage: UIImage?
    
    mutating func setThumbnail(_ uiImage: UIImage) {
        self.uiImage = uiImage
    }
    
    var sharePreview: SharePreview<Image, Never> {
        SharePreview(
            displayName,
            image: Image(uiImage: uiImage ?? UIImage(systemName: "movieclapper.fill")!)
        )
    }
    
    var menuLabel: Label<Text, Image> {
        Label {
            Text(displayName)
        } icon: {
            Image(uiImage: uiImage ?? UIImage(systemName: "movieclapper.fill")!)
        }
    }
    
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.mediaFile)
    }
    
    static func < (lhs: MovieMedia, rhs: MovieMedia) -> Bool {
        lhs.creationDate < rhs.creationDate
    }
}

struct PhotoMedia: MediaProtocol, Comparable {
    let id = UUID()
    let displayName: String
    let mediaFile: URL
    let creationDate: Date
    
    var mediaImage: Image {
        let data = try! Data(contentsOf: mediaFile)
        let uiImage = UIImage(data: data) ?? UIImage(systemName: "photo.fill")!
        return Image(uiImage: uiImage)
    }
    
    var sharePreview: SharePreview<Image, Never> {
        SharePreview(
            displayName,
            image: Image(uiImage: UIImage(contentsOfFile: mediaFile.path()) ?? UIImage(systemName: "photo.fill")!)
        )
    }
    
    var menuLabel: Label<Text, Image> {
        Label {
            Text(displayName)
        } icon: {
            let data = try! Data(contentsOf: mediaFile)
            Image(uiImage: UIImage(data: data) ?? UIImage(systemName: "photo.fill")!)
        }
    }
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .image) { (photo: PhotoMedia) -> Data in
            try Data(contentsOf: photo.mediaFile)
        }
    }
    
    static func < (lhs: PhotoMedia, rhs: PhotoMedia) -> Bool {
        lhs.creationDate < rhs.creationDate
    }
}
