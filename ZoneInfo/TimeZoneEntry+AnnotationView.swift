//
//  TimeZoneEntry+AnnotationView.swift
//  ZoneInfo
//
//  Created by Leptos on 6/5/22.
//

import MapKit

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
        
        private func markerColor(for observer: Date) -> SystemColor {
            guard let timeZoneAnnotation = annotation as? TimeZoneEntry.Annotation else {
                return .init(white: 0.4, alpha: 1)
            }
            return timeZoneAnnotation.entry.markerColor(for: observer)
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
