//
//  MapView.swift
//  ZoneInfo
//
//  Created by Leptos on 5/26/22.
//

import SwiftUI
import MapKit

struct MapView {
    let annotations: [MKAnnotation]
    
    var mapType: MKMapType = .standard
    
    func makeView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        return mapView
    }
    
    func updateView(_ mapView: MKMapView, context: Context) {
        let previous = mapView.annotations
        let diff = annotations.difference(from: previous) { lhs, rhs in
            lhs.title == rhs.title
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
        }
        
        let remove: [MKAnnotation] = diff.removals
            .compactMap {
                switch $0 {
                case .insert:
                    return nil
                case .remove(offset: _, element: let element, associatedWith: _):
                    return element
                }
            }
        
        let add: [MKAnnotation] = diff.insertions
            .compactMap {
                switch $0 {
                case .insert(offset: _, element: let element, associatedWith: _):
                    return element
                case .remove:
                    return nil
                }
            }
        
        mapView.mapType = mapType
        
        mapView.removeAnnotations(remove)
        mapView.addAnnotations(add)
    }
}

#if canImport(UIKit)
extension MapView: UIViewRepresentable {
    func makeUIView(context: Context) -> MKMapView {
        makeView(context: context)
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        updateView(uiView, context: context)
    }
}
#endif

#if canImport(AppKit)
extension MapView: NSViewRepresentable {
    func makeNSView(context: Context) -> MKMapView {
        makeView(context: context)
    }
    
    func updateNSView(_ nsView: MKMapView, context: Context) {
        updateView(nsView, context: context)
    }
}
#endif

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(annotations: [])
    }
}
