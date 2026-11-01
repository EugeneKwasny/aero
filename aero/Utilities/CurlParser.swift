//
//  CurlParser.swift
//  aero
//
//  Parses a cURL command string into an APIRequest.
//

import Foundation

enum CurlParser {

    /// Parses a cURL command. Returns nil if no URL can be found.
    static func parse(_ input: String) -> APIRequest? {
        let tokens = tokenize(input)
        guard !tokens.isEmpty else { return nil }

        var index = tokens.first?.lowercased() == "curl" ? 1 : 0

        var method: HTTPMethod?
        var url: String?
        var headers: [KeyValueItem] = []
        var dataParts: [String] = []
        var user: String?

        func nextValue() -> String? {
            index += 1
            return index < tokens.count ? tokens[index] : nil
        }

        while index < tokens.count {
            let token = tokens[index]
            switch token {
            case "-X", "--request":
                if let value = nextValue() { method = HTTPMethod(rawValue: value.uppercased()) }
            case "-H", "--header":
                if let value = nextValue(), let header = parseHeader(value) { headers.append(header) }
            case "-d", "--data", "--data-raw", "--data-binary", "--data-ascii":
                if let value = nextValue() { dataParts.append(value) }
            case "--json":
                if let value = nextValue() {
                    dataParts.append(value)
                    if !headers.contains(where: { $0.key.lowercased() == "content-type" }) {
                        headers.append(KeyValueItem(key: "Content-Type", value: "application/json"))
                    }
                }
            case "-u", "--user":
                user = nextValue()
            case "--url":
                url = nextValue()
            case "-b", "--cookie", "-e", "--referer", "-A", "--user-agent", "-o", "--output":
                _ = nextValue() // consume value we don't model
            default:
                if token.hasPrefix("-X") && token.count > 2 {
                    method = HTTPMethod(rawValue: String(token.dropFirst(2)).uppercased())
                } else if !token.hasPrefix("-"), url == nil {
                    url = token
                }
                // other flags without values are ignored
            }
            index += 1
        }

        guard let finalURL = url else { return nil }

        var request = APIRequest(
            name: requestName(from: finalURL),
            method: method ?? (dataParts.isEmpty ? .get : .post),
            url: finalURL
        )

        applyAuth(to: &request, user: user, headers: &headers)
        request.headers = headers
        applyBody(to: &request, dataParts: dataParts, headers: headers)

        return request
    }

    // MARK: - Auth

    private static func applyAuth(to request: inout APIRequest, user: String?, headers: inout [KeyValueItem]) {
        if let user {
            request.authType = .basic
            let parts = user.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            request.authUsername = parts.first.map(String.init) ?? ""
            request.authPassword = parts.count > 1 ? String(parts[1]) : ""
            return
        }

        guard let authIndex = headers.firstIndex(where: { $0.key.lowercased() == "authorization" }) else {
            return
        }
        let value = headers[authIndex].value
        if value.lowercased().hasPrefix("bearer ") {
            request.authType = .bearer
            request.authToken = String(value.dropFirst("bearer ".count)).trimmingCharacters(in: .whitespaces)
            headers.remove(at: authIndex)
        } else if value.lowercased().hasPrefix("basic ") {
            let encoded = String(value.dropFirst("basic ".count)).trimmingCharacters(in: .whitespaces)
            if let data = Data(base64Encoded: encoded),
               let decoded = String(data: data, encoding: .utf8) {
                let parts = decoded.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
                request.authType = .basic
                request.authUsername = parts.first.map(String.init) ?? ""
                request.authPassword = parts.count > 1 ? String(parts[1]) : ""
                headers.remove(at: authIndex)
            }
        }
    }

    // MARK: - Body

    private static func applyBody(to request: inout APIRequest, dataParts: [String], headers: [KeyValueItem]) {
        guard !dataParts.isEmpty else { return }
        let body = dataParts.joined(separator: "&")
        let contentType = headers.first { $0.key.lowercased() == "content-type" }?.value.lowercased() ?? ""

        if contentType.contains("x-www-form-urlencoded") {
            request.bodyType = .formURLEncoded
            request.formFields = body.split(separator: "&").map { pair in
                let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                let key = kv.first.map(String.init)?.removingPercentEncoding ?? String(kv.first ?? "")
                let value = kv.count > 1 ? (String(kv[1]).removingPercentEncoding ?? String(kv[1])) : ""
                return KeyValueItem(key: key, value: value)
            }
        } else if contentType.contains("json") || JSONFormatter.isValid(body) {
            request.bodyType = .json
            request.bodyContent = body
        } else {
            request.bodyType = .raw
            request.bodyContent = body
        }
    }

    // MARK: - Helpers

    private static func parseHeader(_ raw: String) -> KeyValueItem? {
        guard let colon = raw.firstIndex(of: ":") else { return nil }
        let key = String(raw[raw.startIndex..<colon]).trimmingCharacters(in: .whitespaces)
        let value = String(raw[raw.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return nil }
        return KeyValueItem(key: key, value: value)
    }

    private static func requestName(from url: String) -> String {
        guard let components = URLComponents(string: url) else { return "Imported Request" }
        let path = components.path
        if let last = path.split(separator: "/").last, !last.isEmpty {
            return String(last)
        }
        return components.host ?? "Imported Request"
    }

    /// Splits a cURL command into tokens, honoring single/double quotes,
    /// backslash escapes, and line continuations.
    private static func tokenize(_ input: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var started = false
        var inSingle = false
        var inDouble = false
        let chars = Array(input)
        var i = 0

        func flush() {
            if started { tokens.append(current) }
            current = ""
            started = false
        }

        while i < chars.count {
            let c = chars[i]
            if inSingle {
                if c == "'" { inSingle = false } else { current.append(c) }
            } else if inDouble {
                if c == "\\", i + 1 < chars.count, "\"\\$`".contains(chars[i + 1]) {
                    current.append(chars[i + 1]); i += 1
                } else if c == "\"" {
                    inDouble = false
                } else {
                    current.append(c)
                }
            } else {
                switch c {
                case "'":
                    inSingle = true; started = true
                case "\"":
                    inDouble = true; started = true
                case "\\":
                    if i + 1 < chars.count {
                        if chars[i + 1] == "\n" || chars[i + 1] == "\r" {
                            // line continuation
                        } else {
                            current.append(chars[i + 1]); started = true
                        }
                        i += 1
                    }
                case " ", "\t", "\n", "\r":
                    flush()
                default:
                    current.append(c); started = true
                }
            }
            i += 1
        }
        flush()
        return tokens
    }
}
