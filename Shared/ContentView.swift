//
//  ContentView.swift
//  Shared
//
//  Created by Leptos on 5/26/22.
//

import SwiftUI
import MapKit

struct ContentView: View {
    let entries: [TimeZoneEntry]
    
    @State private var mapType: MKMapType = .mutedStandard
    
    @Environment(\.locale) private var locale
    
    private var annotations: [MKAnnotation] {
        entries.map { entry in
            let point = TimeZoneEntry.Annotation(entry: entry)
            point.title = entry.timeZone?.localizedName(for: .generic, locale: locale)
            point.subtitle = entry.identifier
            return point
        }
    }
    
    init() {
        // "/var/db/timezone/zoneinfo/zone.tab"
        let file = URL(fileURLWithPath: "/usr/share/zoneinfo/zone.tab")
        let contents = try! String(contentsOf: file)
        
        entries = contents
            .split(whereSeparator: \.isNewline)
            .filter { !$0.hasPrefix("#") }
            .compactMap { TimeZoneEntry(line: .init($0)) }
    }
    
    var body: some View {
        MapView(annotations: annotations, mapType: mapType)
            .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
