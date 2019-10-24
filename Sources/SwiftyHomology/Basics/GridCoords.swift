//
//  GridType.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/10/25.
//

import SwiftyMath

public struct GridCoords<GridDim: StaticSizeType>: ExpressibleByArrayLiteral, Comparable, Hashable {
    public typealias ArrayLiteralElement = Int
    
    private let coords: [Int]
    
    public init(_ coords: [Int]) {
        assert(coords.count == GridDim.intValue)
        self.coords = coords
    }
    
    public init(_ coords: Int...) {
        self.init(coords)
    }
    
    public init(arrayLiteral elements: Int...) {
        self.init(elements)
    }
    
    public subscript(_ i: Int) -> Int {
        coords[i]
    }
    
    public static func +(c1: Self, c2: Self) -> Self {
        .init( c1.coords.merging(c2.coords, filledWith: 0, mergedBy: +) )
    }
    
    public static prefix func -(_ c: Self) -> Self {
        .init( c.coords.map{ -$0 } )
    }

    public static func -(c1: Self, c2: Self) -> Self {
        .init( c1.coords.merging(c2.coords, filledWith: 0, mergedBy: -) )
    }
    
    public static func < (c1: Self, c2: Self) -> Bool {
        c1.coords.lexicographicallyPrecedes(c2.coords)
    }
}
