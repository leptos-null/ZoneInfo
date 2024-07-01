//
//  TimeZoneTable.swift
//  ZoneInfo
//
//  Created by Leptos on 7/1/24.
//

import Foundation

struct TimeZoneTable {
    let entries: [TimeZoneEntry]
    
    init(url: URL) throws {
        let contents = try String(contentsOf: url)
        
        entries = contents
            .split(whereSeparator: \.isNewline)
            .filter { !$0.hasPrefix("#") }
            .compactMap { TimeZoneEntry(line: .init($0)) }
    }
}
