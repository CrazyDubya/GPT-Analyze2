//
//  Item.swift
//  GPT_Analyze2
//
//  Created by Stephen Thompson on 5/29/24.
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
