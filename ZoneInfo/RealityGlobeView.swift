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
    
    @State private var globeEntity: Entity = .init()
    @State private var baseGlobeRotation: simd_quatf?
    
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
                detailAttachment.position = .init(x: 0, y: -0.26, z: 0.23)
                realityContent.add(detailAttachment)
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
        .gesture(
            RotateGesture3D() // two-handed rotation gesture
                .targetedToEntity(globeEntity)
                .onChanged { value in
                    if baseGlobeRotation == nil {
                        baseGlobeRotation = value.entity.transform.rotation
                    }
                    guard let baseGlobeRotation else { return }
                    let rotation = value.rotation
                    // swap from SwiftUI coordinate system to RealityKit;
                    // code thanks to
                    // https://developer.apple.com/documentation/realitykit/transforming-realitykit-entities-with-gestures
                    let flippedRotation = simd_quatf(
                        angle: Float(rotation.angle.radians),
                        axis: .init(
                            x: Float(-rotation.axis.x),
                            y: Float(rotation.axis.y),
                            z: Float(-rotation.axis.z)
                        )
                    )
                    let newOrientation = flippedRotation * baseGlobeRotation
                    value.entity.transform.rotation = newOrientation
                }
                .onEnded { value in
                    baseGlobeRotation = nil
                }
                .simultaneously(with: DragGesture() // one-handed custom rotation gesture
                    .targetedToEntity(globeEntity)
                    .onChanged { value in
                        if baseGlobeRotation == nil {
                            baseGlobeRotation = value.entity.transform.rotation
                        }
                        guard let baseGlobeRotation else { return }
                        // from https://developer.apple.com/documentation/visionos/world
                        let location3D = value.convert(value.location3D, from: .local, to: .scene)
                        let startLocation3D = value.convert(value.startLocation3D, from: .local, to: .scene)
                        let delta = location3D - startLocation3D
                        
                        // inspired by https://stackoverflow.com/a/76823868
                        // similar to above, we want to adjust the coordinate system
                        let transformAngles = Transform(
                            pitch: atan(-delta.y) * .pi,
                            yaw: atan(delta.x) * .pi
                        )
                        let newOrientation = transformAngles.rotation * baseGlobeRotation
                        value.entity.transform.rotation = newOrientation
                    }
                    .onEnded { value in
                        baseGlobeRotation = nil
                    }
                )
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
