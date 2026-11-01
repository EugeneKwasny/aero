//
//  RequestCollection.swift
//  aero
//
//  Persistent model grouping related API requests.
//

import Foundation
import SwiftData

@Model
final class RequestCollection {
    var id: UUID
    var name: String
    var createdAt: Date

    /// Requests belonging to this collection. Deleting the collection
    /// cascades to its requests.
    @Relationship(deleteRule: .cascade, inverse: \APIRequest.collection)
    var requests: [APIRequest]

    init(
        id: UUID = UUID(),
        name: String = "New Collection",
        createdAt: Date = .now,
        requests: [APIRequest] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.requests = requests
    }
}
