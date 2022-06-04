//
//  TimeZoneEntry.swift
//  ZoneInfo
//
//  Created by Leptos on 5/26/22.
//

import Foundation
import CoreLocation

struct TimeZoneEntry: CustomDebugStringConvertible {
    let code: String
    let coordinates: String
    let identifier: String
    let comments: String?
    
    let debugDescription: String
    
    init?(line: String) {
        self.debugDescription = line
        
        let words = line
            .split(maxSplits: 3, whereSeparator: \.isWhitespace)
            .map(String.init)
        
        guard words.count >= 3 else { return nil }
        
        self.code = words[0]
        self.coordinates = words[1]
        self.identifier = words[2]
        if words.count > 3 {
            self.comments = words[3]
        } else {
            self.comments = nil
        }
    }
    
    var timeZone: TimeZone? {
        TimeZone(identifier: identifier)
    }
    
    var coordinate: CLLocationCoordinate2D {
        // "either ±DDMM±DDDMM or ±DDMMSS±DDDMMSS"
        let isoCoordinates = coordinates
        
        let signPredicate: (Character) -> Bool = { character in
            character == "+" || character == "-"
        }
        
        guard let firstSign = isoCoordinates.firstIndex(where: signPredicate) else { return kCLLocationCoordinate2DInvalid }
        
        // we don't want to find the same character again, so start with the next one
        let sliceAfterFirstSign = isoCoordinates[isoCoordinates.index(after: firstSign)...]
        
        guard let secondSign = sliceAfterFirstSign.firstIndex(where: signPredicate) else { return kCLLocationCoordinate2DInvalid }
        
        let sliceAfterSecondSign = isoCoordinates[isoCoordinates.index(after: secondSign)...]
        
        // check that there are no more signs
        guard sliceAfterSecondSign.firstIndex(where: signPredicate) == nil else { return kCLLocationCoordinate2DInvalid }
        
        let latitudeText = isoCoordinates[firstSign..<secondSign]
        let longitudeText = isoCoordinates[secondSign...]
        
        guard let latitude = Self.parseCoordinateComponent(latitudeText, component: .latitude),
              let longitude = Self.parseCoordinateComponent(longitudeText, component: .longitude) else { return kCLLocationCoordinate2DInvalid }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension TimeZoneEntry {
    private enum CoordinateComponent {
        case latitude, longitude
    }
    
    private static func parseCoordinateComponent<T: StringProtocol>(_ input: T, component: CoordinateComponent) -> CLLocationDegrees? {
        let degreeWidth: Int
        switch component {
        case .latitude:
            degreeWidth = 3
        case .longitude:
            degreeWidth = 4
        }
        guard input.count >= degreeWidth else { return nil }
        guard let degrees = CLLocationDegrees(input.prefix(degreeWidth)) else { return nil }
        
        let minuteWidth = 2
        let minuteHead = input.dropFirst(degreeWidth)
        guard minuteHead.count >= minuteWidth else { return nil }
        
        guard let minutes = CLLocationDegrees(minuteHead.prefix(minuteWidth)) else { return nil }
        
        let secondWidth = 2
        let secondHead = minuteHead.dropFirst(minuteWidth)
        
        let seconds: CLLocationDegrees
        if secondHead.count >= secondWidth {
            guard let secondPropose = CLLocationDegrees(secondHead.prefix(secondWidth)) else { return nil }
            seconds = secondPropose
        } else {
            seconds = 0
        }
        
        return CLLocationDegrees(signOf: degrees, magnitudeOf: degrees.magnitude + minutes/60 + seconds/(60 * 60))
    }
}
