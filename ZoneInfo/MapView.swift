//
//  MapView.swift
//  ZoneInfo
//
//  Created by Leptos on 5/26/22.
//

import SwiftUI
import MapKit

struct MapView {
    var selection: Binding<MKAnnotation?>? = nil
    
    var annotations: [MKAnnotation] = []
    
    var mapType: MKMapType = .standard
    
    
    func makeView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        mapView.delegate = context.coordinator
        mapView.register(TimeZoneEntry.AnnotationView.self, forAnnotationViewWithReuseIdentifier: "TimeZoneEntry")
        
        return mapView
    }
    
    func updateView(_ mapView: MKMapView, context: Context) {
        let annotationSort: (MKAnnotation, MKAnnotation) -> Bool = { lhs, rhs in
            // lhs < rhs
            // lhs - rhs < 0
            
            let latitudeDiff = lhs.coordinate.latitude - rhs.coordinate.latitude
            guard latitudeDiff == 0 else {
                return latitudeDiff < 0
            }
            
            let longitudeDiff = lhs.coordinate.longitude - rhs.coordinate.longitude
            guard longitudeDiff == 0 else {
                return longitudeDiff < 0
            }
            
            if let lhsProtocolTitle = lhs.title,
               let rhsProtocolTitle = rhs.title,
               let lhsTitle = lhsProtocolTitle,
               let rhsTitle = rhsProtocolTitle {
                return lhsTitle < rhsTitle
            }
            
            if let lhsProtocolSubtitle = lhs.subtitle,
               let rhsProtocolSubtitle = rhs.subtitle,
               let lhsSubtitle = lhsProtocolSubtitle,
               let rhsSubtitle = rhsProtocolSubtitle {
                return lhsSubtitle < rhsSubtitle
            }
            return false
        }
        
        // evidently the map view holds these in a different order
        // sort elements to reduce unnecessary insertions and removals
        let previous = mapView.annotations
            .sorted(by: annotationSort)
        
        let diff = annotations
            .sorted(by: annotationSort)
            .difference(from: previous) { lhs, rhs in
                lhs.title == rhs.title
                && lhs.subtitle == rhs.subtitle
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
        
        if let selection = selection?.wrappedValue {
            mapView.selectAnnotation(selection, animated: false)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(selection: selection)
    }
    
    final class Coordinator: NSObject, MKMapViewDelegate {
        let selection: Binding<MKAnnotation?>?
        
        init(selection: Binding<MKAnnotation?>?) {
            self.selection = selection
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is TimeZoneEntry.Annotation else { return nil }
            
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "TimeZoneEntry", for: annotation)
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            selection?.wrappedValue = view.annotation
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            if view.annotation === selection?.wrappedValue {
                selection?.wrappedValue = nil
            }
        }
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
        MapView()
    }
}
