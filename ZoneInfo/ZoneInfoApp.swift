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
#else
        WindowGroup {
            ContentView()
        }
#endif
    }
}
