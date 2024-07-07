//
//  RealityGlobeView.swift
//  ZoneInfo
//
//  Created by Leptos on 7/1/24.
//

#if os(visionOS)

import SwiftUI
import RealityKit
import CoreLocation

final class RealityGlobeViewModel: ObservableObject {
    // not marking this as published so that the RealityView can
    // remove entries from this collection without causing the view to update again
    private(set) var dirtyEntries: Set<TimeZoneEntry> = []
    
    private var registry: [TimeZoneEntry: Timer] = [:]
    private var notificationObserver: (any NSObjectProtocol)?
    
    init() {
        notificationObserver = NotificationCenter.default.addObserver(forName: .NSSystemClockDidChange, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            while let (entry, timer) = self.registry.popFirst() {
                timer.invalidate()
                self.dirtyEntries.insert(entry)
                self.objectWillChange.send()
            }
        }
    }
    
    func register(entry: TimeZoneEntry, at date: Date) {
        if let existing = registry[entry] {
            existing.invalidate()
        }
        
        guard let timeZone = entry.timeZone,
              let next = timeZone.nextDaylightSavingTimeTransition(after: date) else { return }
        // `interval` is not used since `repeats: false`
        let timer = Timer(fire: next, interval: 1, repeats: false) { [weak self] timer in
            timer.invalidate()
            guard let self else { return }
            self.dirtyEntries.insert(entry)
            self.objectWillChange.send()
        }
        registry[entry] = timer
        RunLoop.main.add(timer, forMode: .default)
    }
    
    func popDirtyEntry(_ entry: TimeZoneEntry) -> Bool {
        // it's notable that `remove` will cause a willSet/ didSet
        // even if the values in the Set do not change
        dirtyEntries.remove(entry) != nil
    }
    
    deinit {
        for (_, timer) in registry {
            timer.invalidate()
        }
        if let notificationObserver {
            NotificationCenter.default.removeObserver(notificationObserver)
        }
    }
}

struct RealityGlobeView: View {
    private enum AttachmentID: Hashable {
        case entryDetail
    }
    
    let table: TimeZoneTable
    
    @StateObject private var viewModel = RealityGlobeViewModel()
    
    @State private var selectedEntry: TimeZoneEntry?
    
    @State private var globeEntity: Entity = .init()
    
    init() {
        // "/var/db/timezone/zoneinfo/zone.tab"
        let file = URL(fileURLWithPath: "/usr/share/zoneinfo/zone.tab")
        table = try! TimeZoneTable(url: file)
    }
    
    var body: some View {
        RealityView { realityContent, attachments in
            TimeZoneEntryComponent.registerComponent()
            
            var globeMaterial = PhysicallyBasedMaterial()
            
            do {
                let baseResource = try await TextureResource(named: "8k_earth_daymap")
                globeMaterial.baseColor = .init(texture: .init(baseResource))
            } catch {
                assertionFailure("TextureResource(named: \"8k_earth_daymap\") -> \(error as NSError)")
            }
            
            do {
                let baseResource = try await TextureResource(named: "8k_earth_normal_map")
                globeMaterial.normal = .init(texture: .init(baseResource))
            } catch {
                assertionFailure("TextureResource(named: \"8k_earth_normal_map\") -> \(error as NSError)")
            }
            
            do {
                let baseResource = try await TextureResource(named: "8k_earth_specular_map")
                globeMaterial.specular = .init(texture: .init(baseResource))
            } catch {
                assertionFailure("TextureResource(named: \"8k_earth_specular_map\") -> \(error as NSError)")
            }
            
            globeMaterial.textureCoordinateTransform = .init(offset: .init(x: 0.75, y: 0), scale: .one, rotation: .zero)
            
            let globeRadius: Float = 0.28
            let globe = ModelEntity(
                mesh: .generateSphere(radius: globeRadius),
                materials: [globeMaterial],
                collisionShape: .generateSphere(radius: globeRadius),
                mass: 0
            )
            globe.components.set(InputTargetComponent())
            globeEntity = globe
            
            let pinRadius: Float = 0.004
            
            for entry in table.entries {
                let date: Date = .now
                let pinMaterial = UnlitMaterial(color: entry.markerColor(for: date).withAlphaComponent(0.7))
                viewModel.register(entry: entry, at: date)
                
                let pin = ModelEntity(
                    mesh: .generateSphere(radius: pinRadius),
                    materials: [pinMaterial],
                    collisionShape: .generateSphere(radius: pinRadius),
                    mass: 0
                )
                pin.position = entry.coordinate.realityKitXYZ(for: globeRadius + pinRadius)
                pin.components.set([
                    TimeZoneEntryComponent(entry: entry),
                    InputTargetComponent(),
                    HoverEffectComponent()
                ])
                
                globe.addChild(pin)
            }
            
            if let detailAttachment = attachments.entity(for: AttachmentID.entryDetail) {
                detailAttachment.position = .init(x: 0, y: -0.26, z: 0.23)
                realityContent.add(detailAttachment)
            }
            
            globe.position = .init(x: 0, y: 0.06, z: 0)
            
            // rotate globe such that the user's current time zone is centered.
            // this matches MapKit behavior
            let matchIdentifier = TimeZone.current.identifier
            let matchEntry = table.entries.first { $0.identifier == matchIdentifier }
            if let matchEntry {
                let coordinate = matchEntry.coordinate
                
                let x = simd_quatf(angle: Float(coordinate.latitude / 180 * .pi), axis: .init(x: 1, y: 0, z: 0))
                let y = simd_quatf(angle: Float(-coordinate.longitude / 180 * .pi), axis: .init(x: 0, y: 1, z: 0))
                globe.orientation = x * y
            }
            
            realityContent.add(globe)
        } update: { realityContent, attachments in
            updateEntryMarkersIfNeeded(realityContent: realityContent)
        } placeholder: {
            ProgressView()
        } attachments: {
            Attachment(id: AttachmentID.entryDetail) {
                Group {
                    if let selectedEntry {
                        TimeZoneEntryColumnedView(entry: selectedEntry)
                            .padding(.horizontal)
                    } else {
                        Text("Select a time zone marker on the globe to view details")
                            .foregroundStyle(.secondary)
                    }
                }
                .scenePadding()
                .glassBackgroundEffect(displayMode: .implicit)
            }
        }
        .gesture(
            TapGesture()
                .targetedToEntity(where: .has(TimeZoneEntryComponent.self))
                .onEnded { value in
                    guard let entryComponent = value.entity.components[TimeZoneEntryComponent.self] else { return }
                    print(entryComponent.entry)
                    selectedEntry = entryComponent.entry
                }
        )
        .addRotateGestures(to: globeEntity)
    }
    
    private func updateEntryMarkersIfNeeded(realityContent: RealityViewContent) {
        if viewModel.dirtyEntries.isEmpty { return }
        
        realityContent.entities.forEach { entities in
            entities.children.forEach { child in
                guard let entryComponent = child.components[TimeZoneEntryComponent.self],
                      var modelComponent = child.components[ModelComponent.self] else { return }
                let entry = entryComponent.entry
                guard viewModel.popDirtyEntry(entry) else { return }
                
                var materials = modelComponent.materials
                let colorIndex = materials.firstIndex {
                    $0 is UnlitMaterial
                }
                
                let date: Date = .now
                let pinMaterial = UnlitMaterial(color: entry.markerColor(for: date).withAlphaComponent(0.7))
                viewModel.register(entry: entry, at: date)
                
                if let colorIndex {
                    materials[colorIndex] = pinMaterial
                } else {
                    materials.append(pinMaterial)
                }
                modelComponent.materials = materials
                child.components[ModelComponent.self] = modelComponent
            }
        }
    }
}

extension CLLocationCoordinate2D {
    func realityKitXYZ(for radius: Float) -> SIMD3<Float> {
        let point = SIMD2(Float(latitude), Float(longitude))
        let dist = sincospi(point / 180) // divide by 180 degrees
        
        // (x: phi, y: lambda)
        return .init(
            x: radius * dist.cos.x * dist.sin.y,
            y: radius * dist.sin.x,
            z: radius * dist.cos.x * dist.cos.y
        )
    }
}

struct TimeZoneEntryComponent: Component {
    let entry: TimeZoneEntry
}

#Preview {
    RealityGlobeView()
}

#endif
