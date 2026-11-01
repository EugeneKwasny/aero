//
//  JSONFormatter.swift
//  aero
//
//  Helpers for validating and pretty-printing JSON, used by the body
//  editor and the response viewer.
//

import Foundation

enum JSONFormatter {

    /// Whether the string parses as valid JSON.
    static func isValid(_ string: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])) != nil
    }

    /// Returns a pretty-printed version of the JSON string, or nil if invalid.
    static func prettyPrinted(_ string: String) -> String? {
        guard let data = string.data(using: .utf8) else { return nil }
        return prettyPrinted(data)
    }

    /// Returns a pretty-printed version of JSON data, or nil if invalid.
    static func prettyPrinted(_ data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else {
            return nil
        }
        guard let output = try? JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .withoutEscapingSlashes]
        ) else {
            return nil
        }
        return String(data: output, encoding: .utf8)
    }
}
