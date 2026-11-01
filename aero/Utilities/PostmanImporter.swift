//
//  PostmanImporter.swift
//  aero
//
//  Imports a Postman Collection (v2.1) JSON into a RequestCollection
//  and its requests. Nested folders are flattened.
//

import Foundation

enum PostmanImporter {

    /// Parses collection data. Returns the collection and its (not yet
    /// inserted) requests, or nil if the JSON is not a Postman collection.
    static func importCollection(from data: Data) -> (collection: RequestCollection, requests: [APIRequest])? {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let info = root["info"] as? [String: Any]
        let name = info?["name"] as? String ?? "Imported Collection"
        let collection = RequestCollection(name: name)

        var requests: [APIRequest] = []
        if let items = root["item"] as? [[String: Any]] {
            parse(items: items, prefix: "", into: &requests)
        }
        return (collection, requests)
    }

    private static func parse(items: [[String: Any]], prefix: String, into requests: inout [APIRequest]) {
        for item in items {
            let name = item["name"] as? String ?? "Request"
            if let children = item["item"] as? [[String: Any]] {
                parse(items: children, prefix: prefix + name + " / ", into: &requests)
            } else if item["request"] != nil {
                requests.append(parseRequest(item, name: prefix + name))
            }
        }
    }

    private static func parseRequest(_ item: [String: Any], name: String) -> APIRequest {
        // request may be a bare URL string or an object
        if let urlString = item["request"] as? String {
            return APIRequest(name: name, url: urlString)
        }
        guard let r = item["request"] as? [String: Any] else {
            return APIRequest(name: name)
        }

        let request = APIRequest(name: name)
        if let method = r["method"] as? String {
            request.method = HTTPMethod(rawValue: method.uppercased()) ?? .get
        }

        parseURL(r["url"], into: request)
        request.headers = parseKeyValues(r["header"])
        parseBody(r["body"], into: request)
        parseAuth(r["auth"], into: request)

        return request
    }

    private static func parseURL(_ value: Any?, into request: APIRequest) {
        if let string = value as? String {
            request.url = string
        } else if let url = value as? [String: Any] {
            let raw = url["raw"] as? String ?? ""
            if let query = url["query"] as? [[String: Any]] {
                request.queryParams = parseKeyValues(query)
                request.url = String(raw.split(separator: "?").first ?? Substring(raw))
            } else {
                request.url = raw
            }
        }
    }

    private static func parseBody(_ value: Any?, into request: APIRequest) {
        guard let body = value as? [String: Any], let mode = body["mode"] as? String else { return }
        switch mode {
        case "raw":
            let raw = body["raw"] as? String ?? ""
            request.bodyContent = raw
            let language = ((body["options"] as? [String: Any])?["raw"] as? [String: Any])?["language"] as? String
            request.bodyType = (language == "json" || JSONFormatter.isValid(raw)) ? .json : .raw
        case "urlencoded":
            request.bodyType = .formURLEncoded
            request.formFields = parseKeyValues(body["urlencoded"])
        case "formdata":
            request.bodyType = .multipart
            if let items = body["formdata"] as? [[String: Any]] {
                request.multipartParts = items.map { item in
                    let isFile = (item["type"] as? String) == "file"
                    return MultipartPart(
                        name: item["key"] as? String ?? "",
                        isEnabled: !(item["disabled"] as? Bool ?? false),
                        isFile: isFile,
                        value: item["value"] as? String ?? "",
                        fileName: (item["src"] as? String).map { ($0 as NSString).lastPathComponent } ?? ""
                    )
                }
            }
        default:
            break
        }
    }

    private static func parseAuth(_ value: Any?, into request: APIRequest) {
        guard let auth = value as? [String: Any], let type = auth["type"] as? String else { return }
        switch type {
        case "bearer":
            request.authType = .bearer
            request.authToken = firstValue(in: auth["bearer"], key: "token") ?? ""
        case "basic":
            request.authType = .basic
            request.authUsername = firstValue(in: auth["basic"], key: "username") ?? ""
            request.authPassword = firstValue(in: auth["basic"], key: "password") ?? ""
        default:
            break
        }
    }

    // MARK: - Helpers

    private static func parseKeyValues(_ value: Any?) -> [KeyValueItem] {
        guard let array = value as? [[String: Any]] else { return [] }
        return array.map {
            KeyValueItem(
                key: $0["key"] as? String ?? "",
                value: $0["value"] as? String ?? "",
                isEnabled: !($0["disabled"] as? Bool ?? false)
            )
        }
    }

    /// Finds the value for a given key inside a Postman auth parameter array.
    private static func firstValue(in value: Any?, key: String) -> String? {
        guard let array = value as? [[String: Any]] else { return nil }
        return array.first { $0["key"] as? String == key }?["value"] as? String
    }
}
