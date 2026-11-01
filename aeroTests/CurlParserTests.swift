//
//  CurlParserTests.swift
//  aeroTests
//

import Testing
@testable import aero

struct CurlParserTests {

    @Test func parsesSimpleGet() throws {
        let request = try #require(CurlParser.parse("curl https://api.example.com/users"))
        #expect(request.method == .get)
        #expect(request.url == "https://api.example.com/users")
    }

    @Test func parsesPostWithJSONBody() throws {
        let command = "curl -X POST https://api.example.com/users -H 'Content-Type: application/json' -d '{\"name\":\"Ann\"}'"
        let request = try #require(CurlParser.parse(command))
        #expect(request.method == .post)
        #expect(request.bodyType == .json)
        #expect(request.bodyContent == "{\"name\":\"Ann\"}")
        #expect(request.headers.contains { $0.key == "Content-Type" && $0.value == "application/json" })
    }

    @Test func infersPostWhenDataPresentWithoutMethod() throws {
        let request = try #require(CurlParser.parse("curl https://x.dev -d 'a=b'"))
        #expect(request.method == .post)
    }

    @Test func parsesBasicAuthFromUserFlag() throws {
        let request = try #require(CurlParser.parse("curl https://x.dev -u alice:secret"))
        #expect(request.authType == .basic)
        #expect(request.authUsername == "alice")
        #expect(request.authPassword == "secret")
    }

    @Test func parsesBearerFromAuthorizationHeader() throws {
        let request = try #require(CurlParser.parse("curl https://x.dev -H 'Authorization: Bearer tok123'"))
        #expect(request.authType == .bearer)
        #expect(request.authToken == "tok123")
        // The Authorization header is consumed into auth, not kept as a header.
        #expect(!request.headers.contains { $0.key.lowercased() == "authorization" })
    }

    @Test func parsesFormUrlEncodedBody() throws {
        let command = "curl -X POST https://x.dev -H 'Content-Type: application/x-www-form-urlencoded' -d 'a=1&b=2'"
        let request = try #require(CurlParser.parse(command))
        #expect(request.bodyType == .formURLEncoded)
        #expect(request.formFields.count == 2)
        #expect(request.formFields.first { $0.key == "a" }?.value == "1")
    }

    @Test func returnsNilWithoutURL() {
        #expect(CurlParser.parse("curl -X GET") == nil)
    }
}
