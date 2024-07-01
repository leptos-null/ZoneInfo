//
//  ContentView.swift
//  Shared
//
//  Created by Leptos on 5/26/22.
//

import SwiftUI
import MapKit

struct ContentView: View {
    let table: TimeZoneTable
    
    @State private var mapType: MKMapType = .hybridFlyover
    @State private var selectedAnnotation: MKAnnotation?
    
    @Environment(\.locale) private var locale
#if canImport(UIKit)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif
    
    private var horizontalSizeClassIsCompact: Bool {
#if canImport(UIKit)
        (horizontalSizeClass == .compact)
#else
        false
#endif
    }
    
    private var annotations: [MKAnnotation] {
        table.entries.map { entry in
            let point = TimeZoneEntry.Annotation(entry: entry)
            point.title = entry.timeZone?.localizedName(for: .generic, locale: locale)
            point.subtitle = entry.identifier
            return point
        }
    }
    
    init() {
        // "/var/db/timezone/zoneinfo/zone.tab"
        let file = URL(fileURLWithPath: "/usr/share/zoneinfo/zone.tab")
        table = try! TimeZoneTable(url: file)
    }
    
    var body: some View {
        MapView(selection: $selectedAnnotation, annotations: annotations, mapType: mapType)
            .ignoresSafeArea()
            .overlay(alignment: .bottomTrailing) {
                if let timeZoneAnnotation = selectedAnnotation as? TimeZoneEntry.Annotation {
                    TimeZoneEntryView(entry: timeZoneAnnotation.entry)
                        .frame(maxWidth: horizontalSizeClassIsCompact ? .infinity : 380, alignment: .trailing)
                        .scenePadding()
                        .background(.ultraThickMaterial, ignoresSafeAreaEdges: .bottom)
                        .transition(.opacity.animation(.easeInOut))
                }
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
