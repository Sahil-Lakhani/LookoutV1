//
//  Date+Identifiable.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 29/10/24.
//

import Foundation

extension Date: @retroactive Identifiable {
    public var id: TimeInterval {
        self.timeIntervalSinceReferenceDate
    }
}

extension Date {
    func truncatedToSecond() -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        let truncatedDateOrNil = Calendar.current.date(from: components)
        if truncatedDateOrNil == nil {
            print("Problem!")
        }
        return truncatedDateOrNil ?? self
    }
}
