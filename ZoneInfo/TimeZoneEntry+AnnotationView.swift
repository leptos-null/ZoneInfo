//
//  TimeZoneEntry+AnnotationView.swift
//  ZoneInfo
//
//  Created by Leptos on 6/5/22.
//

import MapKit

#if canImport(UIKit)
private typealias MKColor = UIColor
#elseif canImport(AppKit)
private typealias MKColor = NSColor
#else
#error("Unknown UI framework")
#endif


extension TimeZoneEntry {
    final class AnnotationView: MKMarkerAnnotationView {
        
        private var timer: Timer?
        
        override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
            super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.updateInterfaceValues), name: .NSSystemClockDidChange, object: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func markerColor(for observer: Date) -> MKColor {
            guard let timeZoneAnnotation = annotation as? TimeZoneEntry.Annotation else {
                return .init(white: 0.4, alpha: 1)
            }
            
            guard let timeZone = timeZoneAnnotation.entry.timeZone else {
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
        
        private func glyphText(for observer: Date) -> String? {
            guard let timeZoneAnnotation = annotation as? TimeZoneEntry.Annotation,
                  let timeZone = timeZoneAnnotation.entry.timeZone else { return nil }
            
            return timeZone.abbreviation(for: observer)
        }
        
        @objc
        private func updateInterfaceValues() {
            let observer: Date = .now
            
            markerTintColor = markerColor(for: observer)
            glyphText = glyphText(for: observer)
            
            timer?.invalidate()
            timer = nil
            
            guard let timeZoneAnnotation = annotation as? TimeZoneEntry.Annotation,
                  let timeZone = timeZoneAnnotation.entry.timeZone,
                  let nextDate = timeZone.nextDaylightSavingTimeTransition(after: observer) else { return }
            
            let timer = Timer(fireAt: nextDate, interval: 1, target: self, selector: #selector(self.updateInterfaceValues), userInfo: nil, repeats: false)
            self.timer = timer
            RunLoop.main.add(timer, forMode: .default)
        }
        
        override var annotation: MKAnnotation? {
            didSet {
                updateInterfaceValues()
            }
        }
        
    }
}
