//
//  KeyValueItem.swift
//  aero
//
//  A single enableable key/value pair used for query parameters,
//  headers, and form fields. Stored inline inside APIRequest as a
//  Codable value type.
//

import Foundation

struct KeyValueItem: Codable, Identifiable, Hashable {
    var id: UUID
    var key: String
    var value: String
    var isEnabled: Bool

    init(id: UUID = UUID(), key: String = "", value: String = "", isEnabled: Bool = true) {
        self.id = id
        self.key = key
        self.value = value
        self.isEnabled = isEnabled
    }
}
