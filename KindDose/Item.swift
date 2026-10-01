//
//  Item.swift
//  KindDose
//
//  Created by shruthi palchandar on 1/10/2026.
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
