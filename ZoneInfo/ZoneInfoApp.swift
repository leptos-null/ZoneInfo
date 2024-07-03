//
//  ZoneInfoApp.swift
//  Shared
//
//  Created by Leptos on 5/26/22.
//

import SwiftUI

@main
struct ZoneInfoApp: App {
    var body: some Scene {
#if os(visionOS)
        WindowGroup {
            RealityGlobeView()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.6, height: 0.7, depth: 0.6, in: .meters)
#else
        WindowGroup {
            ContentView()
        }
#endif
    }
}
