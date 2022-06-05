//
//  TimeZoneEntry+Annotation.swift
//  ZoneInfo
//
//  Created by Leptos on 6/5/22.
//

import MapKit

extension TimeZoneEntry {
    final class Annotation: MKPointAnnotation {
        let entry: TimeZoneEntry
        
        init(entry: TimeZoneEntry) {
            self.entry = entry
            
            super.init()
            
            self.coordinate = entry.coordinate
        }
    }
}
