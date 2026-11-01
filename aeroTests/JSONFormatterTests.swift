//
//  JSONFormatterTests.swift
//  aeroTests
//

import Testing
@testable import aero

struct JSONFormatterTests {

    @Test func validatesWellFormedJSON() {
        #expect(JSONFormatter.isValid("{\"a\":1}"))
        #expect(JSONFormatter.isValid("[1, 2, 3]"))
    }

    @Test func rejectsMalformedJSON() {
        #expect(!JSONFormatter.isValid("{a:1}"))
        #expect(!JSONFormatter.isValid("not json"))
    }

    @Test func prettyPrintsObject() {
        let pretty = JSONFormatter.prettyPrinted("{\"a\":1}")
        #expect(pretty?.contains("\n") == true)
        #expect(pretty?.contains("\"a\"") == true)
    }

    @Test func returnsNilForInvalidInput() {
        #expect(JSONFormatter.prettyPrinted("{bad}") == nil)
    }
}
