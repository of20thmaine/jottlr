//
//  Item.swift
//  Jottlr
//
//  Created by Bobby Palmer on 2/28/26.
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
