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

struct RealityGlobeView: View {
    private enum AttachmentID: Hashable {
        case entryDetail
    }
    
    let table: TimeZoneTable
    
    @State private var selectedEntry: TimeZoneEntry?
    
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
            
            let pinRadius: Float = 0.004
            let pinMaterial = UnlitMaterial(color: .systemPurple.withAlphaComponent(0.7))
            
            for entry in table.entries {
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
                detailAttachment.position = .init(x: 0, y: -0.32, z: 0.23)
                globe.addChild(detailAttachment)
            }
            
            globe.position = .init(x: 0, y: 0.06, z: 0)
            realityContent.add(globe)
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
