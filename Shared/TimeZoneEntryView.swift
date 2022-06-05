//
//  TimeZoneEntryView.swift
//  ZoneInfo
//
//  Created by Leptos on 6/5/22.
//

import SwiftUI

struct TimeZoneEntryView: View {
    let entry: TimeZoneEntry
    
    private var dateFormatStyle: Date.FormatStyle? {
        guard let timeZone = entry.timeZone else { return nil }
        
        var style: Date.FormatStyle = .dateTime
        style.timeZone = timeZone
        style.capitalizationContext = .standalone
        return style
    }
    
    var body: some View {
        TimelineView(.everyMinute) { timelineContext in
            VStack(spacing: 8) {
                if let format = dateFormatStyle {
                    Group {
                        KeyValueView(key: "Short Specific Name") {
                            Text(timelineContext.date, format: format.timeZone(.specificName(.short)))
                        }
                        KeyValueView(key: "Long Specific Name") {
                            Text(timelineContext.date, format: format.timeZone(.specificName(.long)))
                        }
                        
                        Divider()
                    }
                    Group {
                        KeyValueView(key: "Exemplar Location") {
                            Text(timelineContext.date, format: format.timeZone(.exemplarLocation))
                        }
                        KeyValueView(key: "Generic Location") {
                            Text(timelineContext.date, format: format.timeZone(.genericLocation))
                        }
                        
                        Divider()
                    }
                    Group {
                        KeyValueView(key: "Short Generic Name") {
                            Text(timelineContext.date, format: format.timeZone(.genericName(.short)))
                        }
                        KeyValueView(key: "Long Generic Name") {
                            Text(timelineContext.date, format: format.timeZone(.genericName(.long)))
                        }
                        
                        Divider()
                    }
                    Group {
                        KeyValueView(key: "Short Identifier") {
                            Text(timelineContext.date, format: format.timeZone(.identifier(.short)))
                        }
                        KeyValueView(key: "Long Identifier") {
                            Text(timelineContext.date, format: format.timeZone(.identifier(.long)))
                        }
                        
                        Divider()
                    }
                    
                    KeyValueView(key: "Local Time") {
                        Text(timelineContext.date, format: format)
                    }
                } else {
                    KeyValueView(key: "Identifier") {
                        Text(entry.identifier)
                    }
                }
            }
        }
    }
}

private struct KeyValueView<Key: StringProtocol>: View {
    let key: Key
    let value: () -> (Text)
    
    var body: some View {
        HStack {
            Text(key)
                .font(.callout)
            Spacer(minLength: 12)
            value()
                .textSelection(.enabled)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct TimeZoneEntryView_Previews: PreviewProvider {
    static var previews: some View {
        TimeZoneEntryView(entry: .init(line: "US  +340308-1181434 America/Los_Angeles Pacific")!)
    }
}
