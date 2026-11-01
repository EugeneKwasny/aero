//
//  RequestBuilderTests.swift
//  aeroTests
//

import Foundation
import Testing
@testable import aero

struct RequestBuilderTests {

    private func bodyString(_ request: URLRequest) -> String {
        String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
    }

    @Test func prependsHTTPSWhenSchemeMissing() throws {
        let request = try RequestBuilder.makeURLRequest(from: APIRequest(url: "api.example.com/x"))
        #expect(request.url?.absoluteString == "https://api.example.com/x")
    }

    @Test func appendsEnabledQueryParameters() throws {
        let api = APIRequest(url: "https://x.dev/path", queryParams: [
            KeyValueItem(key: "a", value: "1"),
            KeyValueItem(key: "b", value: "2", isEnabled: false),
        ])
        let request = try RequestBuilder.makeURLRequest(from: api)
        let url = request.url?.absoluteString ?? ""
        #expect(url.contains("a=1"))
        #expect(!url.contains("b=2"))
    }

    @Test func appliesHeaders() throws {
        let api = APIRequest(url: "https://x.dev", headers: [KeyValueItem(key: "X-Test", value: "yes")])
        let request = try RequestBuilder.makeURLRequest(from: api)
        #expect(request.value(forHTTPHeaderField: "X-Test") == "yes")
    }

    @Test func appliesBearerAuth() throws {
        let api = APIRequest(url: "https://x.dev", authType: .bearer, authToken: "tok")
        let request = try RequestBuilder.makeURLRequest(from: api)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer tok")
    }

    @Test func appliesBasicAuth() throws {
        let api = APIRequest(url: "https://x.dev", authType: .basic, authUsername: "user", authPassword: "pass")
        let request = try RequestBuilder.makeURLRequest(from: api)
        // base64("user:pass") == "dXNlcjpwYXNz"
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Basic dXNlcjpwYXNz")
    }

    @Test func setsJSONBodyAndContentType() throws {
        let api = APIRequest(url: "https://x.dev", bodyType: .json, bodyContent: "{\"a\":1}")
        let request = try RequestBuilder.makeURLRequest(from: api)
        #expect(bodyString(request) == "{\"a\":1}")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func encodesFormURLEncodedBody() throws {
        let api = APIRequest(url: "https://x.dev", bodyType: .formURLEncoded, formFields: [
            KeyValueItem(key: "a", value: "1"),
            KeyValueItem(key: "b", value: "2"),
        ])
        let request = try RequestBuilder.makeURLRequest(from: api)
        #expect(bodyString(request) == "a=1&b=2")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    }

    @Test func buildsMultipartTextParts() throws {
        let api = APIRequest(url: "https://x.dev", bodyType: .multipart, multipartParts: [
            MultipartPart(name: "field", value: "value"),
        ])
        let request = try RequestBuilder.makeURLRequest(from: api)
        let contentType = request.value(forHTTPHeaderField: "Content-Type") ?? ""
        #expect(contentType.hasPrefix("multipart/form-data; boundary="))
        let body = bodyString(request)
        #expect(body.contains("name=\"field\""))
        #expect(body.contains("value"))
    }

    @Test func substitutesVariables() throws {
        let api = APIRequest(url: "{{host}}/users", queryParams: [KeyValueItem(key: "q", value: "{{term}}")])
        let request = try RequestBuilder.makeURLRequest(from: api) {
            VariableResolver.resolve($0, with: ["host": "https://api.example.com", "term": "swift"])
        }
        #expect(request.url?.absoluteString == "https://api.example.com/users?q=swift")
    }

    @Test func throwsOnEmptyURL() {
        #expect(throws: HTTPClientError.self) {
            _ = try RequestBuilder.makeURLRequest(from: APIRequest(url: ""))
        }
    }
}
