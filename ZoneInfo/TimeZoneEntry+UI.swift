//
//  TimeZoneEntry+UI.swift
//  ZoneInfo
//
//  Created by Leptos on 7/1/24.
//

import Foundation

#if canImport(UIKit)
import UIKit
typealias SystemColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias SystemColor = NSColor
#else
#error("Unknown UI framework")
#endif

extension TimeZoneEntry {
    func markerColor(for observer: Date) -> SystemColor {
        guard let timeZone else {
            return .init(white: 0.6, alpha: 1)
        }
        
        let seconds = timeZone.secondsFromGMT(for: observer)
        let normalized = CGFloat(seconds)/(12 * 60 * 60) // [-1, +1]
        
        // let x = 12/magnitude
        // assuming that time zone offsets fall on the hour (not all do)
        // `x` is the number of colors that will appear on the map
        // or in other words, a given color will repeat every `x` time zones.
        // if x > 24, some hues will be unused.
        // the greater x is, the less contrast there is between adjacent time zones
        // if x is not an integer, there will be an un-even distribution of colors.
        //
        // therefore, I suggest that x is an integer in the range [3, 24]
        // meaning that magnitude may take on the values
        //   0.5, 1.0, 2.0, 3.0, 4.0
        let magnitude: CGFloat = 2
        // only the fraction component of `shift` is used
        let shift: CGFloat = 0.075
        
        let huePhase = (normalized + 1) * magnitude + shift
        let hueComponent = huePhase.truncatingRemainder(dividingBy: 1)
        return .init(hue: hueComponent, saturation: 0.9, brightness: 0.74, alpha: 1)
    }
}
