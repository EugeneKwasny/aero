//
//  PostmanTests.swift
//  aeroTests
//

import Foundation
import Testing
@testable import aero

struct PostmanTests {

    @Test func roundTripsCollection() throws {
        let request = APIRequest(
            name: "Create Item",
            method: .post,
            url: "https://api.example.com/items",
            headers: [KeyValueItem(key: "Accept", value: "application/json")],
            bodyType: .json,
            bodyContent: "{\"x\":1}",
            authType: .bearer,
            authToken: "tok"
        )
        let collection = RequestCollection(name: "My API")
        collection.requests = [request]

        let data = try #require(PostmanExporter.export(collection))
        let result = try #require(PostmanImporter.importCollection(from: data))

        #expect(result.collection.name == "My API")
        #expect(result.requests.count == 1)

        let imported = try #require(result.requests.first)
        #expect(imported.name == "Create Item")
        #expect(imported.method == .post)
        #expect(imported.url == "https://api.example.com/items")
        #expect(imported.bodyType == .json)
        #expect(imported.bodyContent == "{\"x\":1}")
        #expect(imported.authType == .bearer)
        #expect(imported.authToken == "tok")
        #expect(imported.headers.contains { $0.key == "Accept" && $0.value == "application/json" })
    }

    @Test func importsFormUrlEncodedBody() throws {
        let json = """
        {
          "info": { "name": "C", "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json" },
          "item": [
            { "name": "Login", "request": {
                "method": "POST",
                "url": { "raw": "https://x.dev/login" },
                "body": { "mode": "urlencoded", "urlencoded": [
                    { "key": "user", "value": "a" },
                    { "key": "pass", "value": "b" }
                ]}
            }}
          ]
        }
        """
        let result = try #require(PostmanImporter.importCollection(from: Data(json.utf8)))
        let request = try #require(result.requests.first)
        #expect(request.bodyType == .formURLEncoded)
        #expect(request.formFields.count == 2)
    }

    @Test func flattensNestedFolders() throws {
        let json = """
        {
          "info": { "name": "C", "schema": "v2.1.0" },
          "item": [
            { "name": "Folder", "item": [
                { "name": "Inner", "request": { "method": "GET", "url": "https://x.dev/a" } }
            ]}
          ]
        }
        """
        let result = try #require(PostmanImporter.importCollection(from: Data(json.utf8)))
        #expect(result.requests.count == 1)
        #expect(result.requests.first?.name.contains("Inner") == true)
    }

    @Test func returnsNilForNonJSON() {
        #expect(PostmanImporter.importCollection(from: Data("not json".utf8)) == nil)
    }
}
