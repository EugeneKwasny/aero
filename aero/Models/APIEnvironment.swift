//
//  APIEnvironment.swift
//  aero
//
//  Persistent model holding a named set of variables that can be
//  substituted into requests via {{variable}} placeholders.
//

import Foundation
import SwiftData

@Model
final class APIEnvironment {
    var id: UUID
    var name: String
    var variables: [KeyValueItem]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "New Environment",
        variables: [KeyValueItem] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.variables = variables
        self.createdAt = createdAt
    }

    /// Enabled variables as a lookup map (key -> value).
    var variableMap: [String: String] {
        var map: [String: String] = [:]
        for item in variables where item.isEnabled && !item.key.isEmpty {
            map[item.key] = item.value
        }
        return map
    }
}
