//
//  PostmanExporter.swift
//  aero
//
//  Exports a RequestCollection to Postman Collection (v2.1) JSON.
//

import Foundation

enum PostmanExporter {

    static func export(_ collection: RequestCollection) -> Data? {
        let items = collection.requests
            .sorted { $0.createdAt < $1.createdAt }
            .map { itemDict($0) }

        let root: [String: Any] = [
            "info": [
                "name": collection.name,
                "_postman_id": UUID().uuidString,
                "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
            ],
            "item": items,
        ]

        return try? JSONSerialization.data(
            withJSONObject: root,
            options: [.prettyPrinted, .withoutEscapingSlashes]
        )
    }

    private static func itemDict(_ request: APIRequest) -> [String: Any] {
        var req: [String: Any] = ["method": request.method.rawValue]

        req["header"] = request.headers
            .filter { !$0.key.isEmpty }
            .map { keyValueDict($0) }

        req["url"] = urlDict(request)

        if let body = bodyDict(request) { req["body"] = body }
        if let auth = authDict(request) { req["auth"] = auth }

        return ["name": request.name, "request": req]
    }

    private static func urlDict(_ request: APIRequest) -> [String: Any] {
        let enabled = request.queryParams.filter { !$0.key.isEmpty }
        let query = enabled.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let raw = query.isEmpty
            ? request.url
            : request.url + (request.url.contains("?") ? "&" : "?") + query

        var dict: [String: Any] = ["raw": raw]
        if !enabled.isEmpty {
            dict["query"] = enabled.map { keyValueDict($0) }
        }
        return dict
    }

    private static func bodyDict(_ request: APIRequest) -> [String: Any]? {
        switch request.bodyType {
        case .none:
            return nil
        case .json:
            return ["mode": "raw", "raw": request.bodyContent,
                    "options": ["raw": ["language": "json"]]]
        case .raw:
            return ["mode": "raw", "raw": request.bodyContent]
        case .formURLEncoded:
            return ["mode": "urlencoded",
                    "urlencoded": request.formFields.filter { !$0.key.isEmpty }.map { keyValueDict($0) }]
        case .multipart:
            let data = request.multipartParts.filter { !$0.name.isEmpty }.map { part -> [String: Any] in
                var dict: [String: Any] = ["key": part.name, "disabled": !part.isEnabled]
                if part.isFile {
                    dict["type"] = "file"
                    dict["src"] = part.fileName
                } else {
                    dict["type"] = "text"
                    dict["value"] = part.value
                }
                return dict
            }
            return ["mode": "formdata", "formdata": data]
        }
    }

    private static func authDict(_ request: APIRequest) -> [String: Any]? {
        switch request.authType {
        case .none:
            return nil
        case .bearer:
            return ["type": "bearer", "bearer": [["key": "token", "value": request.authToken, "type": "string"]]]
        case .basic:
            return ["type": "basic", "basic": [
                ["key": "username", "value": request.authUsername, "type": "string"],
                ["key": "password", "value": request.authPassword, "type": "string"],
            ]]
        case .oauth2:
            guard !request.oauth2.accessToken.isEmpty else { return nil }
            return ["type": "bearer", "bearer": [
                ["key": "token", "value": request.oauth2.accessToken, "type": "string"],
            ]]
        }
    }

    private static func keyValueDict(_ item: KeyValueItem) -> [String: Any] {
        ["key": item.key, "value": item.value, "disabled": !item.isEnabled]
    }
}
