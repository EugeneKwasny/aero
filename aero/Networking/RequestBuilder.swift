//
//  RequestBuilder.swift
//  aero
//
//  Translates an APIRequest model into a Foundation URLRequest,
//  applying variable substitution, query parameters, headers,
//  authentication, and body.
//

import Foundation
import UniformTypeIdentifiers

enum RequestBuilder {

    /// A function that resolves {{variable}} placeholders in a string.
    typealias Resolver = (String) -> String

    /// Builds a `URLRequest` from the given `APIRequest`.
    /// - Parameter resolve: substitutes environment variables; identity by default.
    /// - Throws: `HTTPClientError.invalidURL` when the URL cannot be parsed.
    static func makeURLRequest(
        from request: APIRequest,
        resolve: Resolver = { $0 }
    ) throws -> URLRequest {
        guard let url = buildURL(from: request, resolve: resolve) else {
            throw HTTPClientError.invalidURL(request.url)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue

        applyHeaders(request, resolve: resolve, to: &urlRequest)
        applyAuth(request, resolve: resolve, to: &urlRequest)
        applyBody(request, resolve: resolve, to: &urlRequest)

        return urlRequest
    }

    // MARK: - URL + Query

    private static func buildURL(from request: APIRequest, resolve: Resolver) -> URL? {
        var trimmed = resolve(request.url).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Default to https when the user omits the scheme.
        if !trimmed.contains("://") {
            trimmed = "https://" + trimmed
        }

        guard var components = URLComponents(string: trimmed) else {
            return nil
        }

        let enabledParams = request.queryParams.filter { $0.isEnabled && !$0.key.isEmpty }
        if !enabledParams.isEmpty {
            var items = components.queryItems ?? []
            items.append(contentsOf: enabledParams.map {
                URLQueryItem(name: resolve($0.key), value: resolve($0.value))
            })
            components.queryItems = items
        }

        return components.url
    }

    // MARK: - Headers

    private static func applyHeaders(_ request: APIRequest, resolve: Resolver, to urlRequest: inout URLRequest) {
        for header in request.headers where header.isEnabled && !header.key.isEmpty {
            urlRequest.setValue(resolve(header.value), forHTTPHeaderField: resolve(header.key))
        }
    }

    // MARK: - Auth

    private static func applyAuth(_ request: APIRequest, resolve: Resolver, to urlRequest: inout URLRequest) {
        switch request.authType {
        case .none:
            break
        case .bearer:
            let token = resolve(request.authToken).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !token.isEmpty else { return }
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        case .basic:
            let pair = "\(resolve(request.authUsername)):\(resolve(request.authPassword))"
            guard let data = pair.data(using: .utf8) else { return }
            urlRequest.setValue("Basic \(data.base64EncodedString())", forHTTPHeaderField: "Authorization")
        case .oauth2:
            let token = resolve(request.oauth2.accessToken).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !token.isEmpty else { return }
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    // MARK: - Body

    private static func applyBody(_ request: APIRequest, resolve: Resolver, to urlRequest: inout URLRequest) {
        switch request.bodyType {
        case .none:
            break
        case .json:
            urlRequest.httpBody = resolve(request.bodyContent).data(using: .utf8)
            setIfAbsent("application/json", header: "Content-Type", on: &urlRequest)
        case .raw:
            urlRequest.httpBody = resolve(request.bodyContent).data(using: .utf8)
            setIfAbsent("text/plain", header: "Content-Type", on: &urlRequest)
        case .formURLEncoded:
            urlRequest.httpBody = encodeForm(request.formFields, resolve: resolve).data(using: .utf8)
            setIfAbsent("application/x-www-form-urlencoded", header: "Content-Type", on: &urlRequest)
        case .multipart:
            let boundary = "AeroBoundary-\(UUID().uuidString)"
            urlRequest.httpBody = encodeMultipart(request.multipartParts, boundary: boundary, resolve: resolve)
            setIfAbsent("multipart/form-data; boundary=\(boundary)", header: "Content-Type", on: &urlRequest)
        }
    }

    // MARK: - Multipart

    private static func encodeMultipart(_ parts: [MultipartPart], boundary: String, resolve: Resolver) -> Data {
        var data = Data()
        let crlf = "\r\n"
        func append(_ string: String) {
            if let d = string.data(using: .utf8) { data.append(d) }
        }

        for part in parts where part.isEnabled && !part.name.isEmpty {
            let name = resolve(part.name)
            append("--\(boundary)\(crlf)")
            if part.isFile {
                guard let file = readFile(part) else { continue }
                append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(file.name)\"\(crlf)")
                append("Content-Type: \(file.mime)\(crlf)\(crlf)")
                data.append(file.data)
                append(crlf)
            } else {
                append("Content-Disposition: form-data; name=\"\(name)\"\(crlf)\(crlf)")
                append(resolve(part.value))
                append(crlf)
            }
        }
        append("--\(boundary)--\(crlf)")
        return data
    }

    /// Resolves a part's security-scoped bookmark and reads the file.
    private static func readFile(_ part: MultipartPart) -> (data: Data, name: String, mime: String)? {
        guard let bookmark = part.bookmark else { return nil }
        var stale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) else { return nil }

        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        guard let fileData = try? Data(contentsOf: url) else { return nil }
        let name = part.fileName.isEmpty ? url.lastPathComponent : part.fileName
        let mime = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        return (fileData, name, mime)
    }

    /// Percent-encodes enabled form fields into an `a=b&c=d` string.
    private static func encodeForm(_ fields: [KeyValueItem], resolve: Resolver) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return fields
            .filter { $0.isEnabled && !$0.key.isEmpty }
            .map { field in
                let key = resolve(field.key).addingPercentEncoding(withAllowedCharacters: allowed) ?? field.key
                let value = resolve(field.value).addingPercentEncoding(withAllowedCharacters: allowed) ?? field.value
                return "\(key)=\(value)"
            }
            .joined(separator: "&")
    }

    /// Sets a header only when the user hasn't already provided one.
    private static func setIfAbsent(_ value: String, header: String, on urlRequest: inout URLRequest) {
        if urlRequest.value(forHTTPHeaderField: header) == nil {
            urlRequest.setValue(value, forHTTPHeaderField: header)
        }
    }
}
