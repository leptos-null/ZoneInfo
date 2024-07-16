//
//  RealityRotateViewModifier.swift
//  ZoneInfo
//
//  Created by Leptos on 7/5/24.
//

#if os(visionOS)

import SwiftUI
import RealityKit

private struct RealityRotateViewModifier: ViewModifier {
    @State private var baseRotation: simd_quatf?
    
    let targetEntity: Entity
    
    func body(content: Content) -> some View {
        content
            .gesture(
                RotateGesture3D() // two-handed rotation gesture
                    .targetedToEntity(targetEntity)
                    .onChanged { value in
                        if baseRotation == nil {
                            baseRotation = value.entity.transform.rotation
                        }
                        guard let baseRotation else { return }
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
                        let newOrientation = flippedRotation * baseRotation
                        value.entity.transform.rotation = newOrientation
                    }
                    .onEnded { value in
                        baseRotation = nil
                    }
                    .simultaneously(with: DragGesture() // one-handed custom rotation gesture
                        .targetedToEntity(targetEntity)
                        .onChanged { value in
                            if baseRotation == nil {
                                baseRotation = value.entity.transform.rotation
                            }
                            guard let baseRotation else { return }
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
                            let newOrientation = transformAngles.rotation * baseRotation
                            value.entity.transform.rotation = newOrientation
                        }
                        .onEnded { value in
                            baseRotation = nil
                        }
                    )
            )
    }
}

extension View {
    func addRotateGestures(to entity: Entity) -> some View {
        modifier(RealityRotateViewModifier(targetEntity: entity))
    }
}

#endif
