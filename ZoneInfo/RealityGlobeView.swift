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
    let table: TimeZoneTable
    
    init() {
        // "/var/db/timezone/zoneinfo/zone.tab"
        let file = URL(fileURLWithPath: "/usr/share/zoneinfo/zone.tab")
        table = try! TimeZoneTable(url: file)
    }
    
    var body: some View {
        RealityView { realityContent in
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
            
            realityContent.add(globe)
        }
        .gesture(
            TapGesture()
                .targetedToEntity(where: .has(TimeZoneEntryComponent.self))
                .onEnded { value in
                    guard let entryComponent = value.entity.components[TimeZoneEntryComponent.self] else { return }
                    print(entryComponent.entry)
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
