//
//  GridCoords.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/07/04.
//

import Foundation

public typealias GridCoords = [Int]

internal extension Array where Element == Int {
    func shifted(_ I: GridCoords) -> GridCoords {
        assert(self.count == I.count)
        return zip(self, I).map{ (x, y) in x + y }
    }
    
    static prefix func -(_ I: GridCoords) -> GridCoords {
        return I.map{ -$0 }
    }
}
