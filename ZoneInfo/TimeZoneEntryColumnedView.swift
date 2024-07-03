//
//  TimeZoneEntryColumnedView.swift
//  ZoneInfo
//
//  Created by Leptos on 7/3/24.
//

import SwiftUI

struct TimeZoneEntryColumnedView: View {
    let entry: TimeZoneEntry
    
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    
    private var dateFormatStyle: Date.FormatStyle? {
        guard let timeZone = entry.timeZone else { return nil }
        
        var style: Date.FormatStyle = .dateTime
        style.timeZone = timeZone
        style.locale = locale
        style.calendar = calendar
        style.capitalizationContext = .standalone
        return style
    }
    
    var body: some View {
        TimelineView(.everyMinute) { timelineContext in
            if let format = dateFormatStyle {
                VStack(spacing: 8) {
                    RowView {
                        KeyValueView(key: "Short Specific Name") {
                            Text(timelineContext.date, format: format.timeZone(.specificName(.short)))
                        }
                    } trailing: {
                        KeyValueView(key: "Long Specific Name") {
                            Text(timelineContext.date, format: format.timeZone(.specificName(.long)))
                        }
                    }
                    Divider()
                    RowView {
                        KeyValueView(key: "Exemplar Location") {
                            Text(timelineContext.date, format: format.timeZone(.exemplarLocation))
                        }
                    } trailing: {
                        KeyValueView(key: "Generic Location") {
                            Text(timelineContext.date, format: format.timeZone(.genericLocation))
                        }
                    }
                    Divider()
                    RowView {
                        KeyValueView(key: "Short Generic Name") {
                            Text(timelineContext.date, format: format.timeZone(.genericName(.short)))
                        }
                    } trailing: {
                        KeyValueView(key: "Long Generic Name") {
                            Text(timelineContext.date, format: format.timeZone(.genericName(.long)))
                        }
                    }
                    Divider()
                    RowView {
                        KeyValueView(key: "Short Identifier") {
                            Text(timelineContext.date, format: format.timeZone(.identifier(.short)))
                        }
                    } trailing: {
                        KeyValueView(key: "Long Identifier") {
                            Text(timelineContext.date, format: format.timeZone(.identifier(.long)))
                        }
                    }
                    Divider()
                    RowView {
                        KeyValueView(key: "ISO 8601") {
                            Text(timelineContext.date, format: format.timeZone(.iso8601(.long)))
                        }
                    } trailing: {
                        KeyValueView(key: "Local Time") {
                            Text(timelineContext.date, format: format)
                        }
                    }
                }
                .frame(width: 724)
            } else {
                KeyValueView(key: "Identifier") {
                    Text(entry.identifier)
                }
            }
        }
    }
}

private struct RowView<Leading: View, Trailing: View>: View {
    private let leading: () -> Leading
    private let trailing: () -> Trailing
    
    init(@ViewBuilder leading: @escaping () -> Leading, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.leading = leading
        self.trailing = trailing
    }
    
    var body: some View {
        HStack(spacing: 24) {
            leading()
                .frame(width: 320)
            
            trailing()
                .frame(width: 380)
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
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct TimeZoneEntryColumnedView_Previews: PreviewProvider {
    static var previews: some View {
        TimeZoneEntryColumnedView(entry: .init(line: "US  +340308-1181434 America/Los_Angeles Pacific")!)
    }
}
