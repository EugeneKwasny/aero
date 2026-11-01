//
//  CurlExporterTests.swift
//  aeroTests
//

import Testing
@testable import aero

struct CurlExporterTests {

    @Test func exportsHeadersAndMethod() {
        let request = APIRequest(
            method: .post,
            url: "https://api.example.com/users",
            headers: [KeyValueItem(key: "X-Demo", value: "1")],
            bodyType: .json,
            bodyContent: "{\"a\":1}"
        )
        let curl = CurlExporter.export(request)
        #expect(curl.hasPrefix("curl"))
        #expect(curl.contains("-X POST"))
        #expect(curl.contains("-H 'X-Demo: 1'"))
        #expect(curl.contains("--data '{\"a\":1}'"))
    }

    @Test func exportsBearerAsHeader() {
        let request = APIRequest(url: "https://x.dev", authType: .bearer, authToken: "tok")
        #expect(CurlExporter.export(request).contains("-H 'Authorization: Bearer tok'"))
    }

    @Test func exportsBasicAsUserFlag() {
        let request = APIRequest(url: "https://x.dev", authType: .basic, authUsername: "u", authPassword: "p")
        #expect(CurlExporter.export(request).contains("-u 'u:p'"))
    }

    @Test func appendsQueryParameters() {
        let request = APIRequest(url: "https://x.dev/path", queryParams: [KeyValueItem(key: "q", value: "swift")])
        #expect(CurlExporter.export(request).contains("https://x.dev/path?q=swift"))
    }

    @Test func roundTripsThroughParser() throws {
        let original = APIRequest(
            method: .post,
            url: "https://api.example.com/items",
            headers: [KeyValueItem(key: "Accept", value: "application/json")],
            bodyType: .json,
            bodyContent: "{\"x\":1}"
        )
        let reparsed = try #require(CurlParser.parse(CurlExporter.export(original)))
        #expect(reparsed.method == .post)
        #expect(reparsed.url == "https://api.example.com/items")
        #expect(reparsed.bodyContent == "{\"x\":1}")
    }
}
