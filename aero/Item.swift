//
//  Item.swift
//  aero
//
//  Created by Eugene Kwasny on 31.10.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
