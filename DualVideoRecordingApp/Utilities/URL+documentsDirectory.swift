//
//  FileManager+documentsDirector.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 26/10/24.
//

import Foundation

extension URL {
    static func newPiPMoviewDirectory(_ creationDate: Date) -> URL {
        URL.documentsDirectory
            .appending(component: "PiPCam on \(creationDate.ISO8601Format(.iso8601WithTimeZone()))")
            .appendingPathExtension("mov")
    }
    
    static func newMovieDirectory(fromBackCamera: Bool = true, onDateString dateString: String) -> URL {
        URL.documentsDirectory
            .appending(component: "\(fromBackCamera ? "BackCam" : "FrontCam") on \(dateString)")
            .appendingPathExtension("mov")
    }
    
    static func newPhotoDirectory(fromBackCamera: Bool = true, forDate date: Date) -> URL {
        URL.documentsDirectory
            .appending(component: "\(fromBackCamera ? "BackCam" : "FrontCam") on \(date.ISO8601Format(.iso8601WithTimeZone()))")
            .appendingPathExtension("png")
    }
}
