//
//  MultipartPart.swift
//  aero
//
//  A single part of a multipart/form-data body: either a text field or
//  a file selected by the user (persisted via a security-scoped bookmark).
//

import Foundation

struct MultipartPart: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var isEnabled: Bool
    var isFile: Bool
    var value: String
    var fileName: String
    var bookmark: Data?

    init(
        id: UUID = UUID(),
        name: String = "",
        isEnabled: Bool = true,
        isFile: Bool = false,
        value: String = "",
        fileName: String = "",
        bookmark: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.isFile = isFile
        self.value = value
        self.fileName = fileName
        self.bookmark = bookmark
    }
}
