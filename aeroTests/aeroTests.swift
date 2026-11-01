//
//  aeroTests.swift
//  aeroTests
//
//  VariableResolver tests. Other components are covered in sibling files.
//

import Testing
@testable import aero

struct VariableResolverTests {

    @Test func replacesKnownPlaceholders() {
        let result = VariableResolver.resolve("{{base}}/users", with: ["base": "https://api.example.com"])
        #expect(result == "https://api.example.com/users")
    }

    @Test func leavesUnknownPlaceholdersUntouched() {
        let result = VariableResolver.resolve("{{base}}/{{missing}}", with: ["base": "x"])
        #expect(result == "x/{{missing}}")
    }

    @Test func toleratesWhitespaceInBraces() {
        let result = VariableResolver.resolve("{{ token }}", with: ["token": "abc"])
        #expect(result == "abc")
    }

    @Test func returnsInputWhenNoVariables() {
        let result = VariableResolver.resolve("plain text", with: [:])
        #expect(result == "plain text")
    }

    @Test func replacesMultipleOccurrences() {
        let result = VariableResolver.resolve("{{a}}-{{a}}-{{b}}", with: ["a": "1", "b": "2"])
        #expect(result == "1-1-2")
    }
}
