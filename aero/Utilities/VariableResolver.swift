//
//  VariableResolver.swift
//  aero
//
//  Replaces {{variable}} placeholders in strings using a variable map.
//  Unknown placeholders are left untouched.
//

import Foundation

enum VariableResolver {
    /// Matches {{ name }} with optional surrounding whitespace.
    private static let regex = try! NSRegularExpression(
        pattern: "\\{\\{\\s*([A-Za-z0-9_.-]+)\\s*\\}\\}"
    )

    /// Returns a copy of `template` with placeholders replaced by values
    /// from `variables`. Placeholders without a matching key stay as-is.
    static func resolve(_ template: String, with variables: [String: String]) -> String {
        guard !variables.isEmpty, template.contains("{{") else { return template }

        let nsRange = NSRange(template.startIndex..<template.endIndex, in: template)
        var result = template

        // Replace from the last match backwards so earlier ranges stay valid.
        let matches = regex.matches(in: template, range: nsRange)
        for match in matches.reversed() {
            guard
                let fullRange = Range(match.range, in: result),
                let keyRange = Range(match.range(at: 1), in: template)
            else { continue }
            let key = String(template[keyRange])
            if let value = variables[key] {
                result.replaceSubrange(fullRange, with: value)
            }
        }
        return result
    }
}
