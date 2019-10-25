//
//  GridWrapper.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/10/25.
//

import SwiftyMath

public protocol GridWrapper: GridType where GridDim == Grid.GridDim, Object == Grid.Object {
    associatedtype Grid: GridType
    var grid: Grid { get }
}

extension GridWrapper {
    public typealias Coords = GridCoords<GridDim>
    
    public subscript(I: Coords) -> Object {
        grid[I]
    }
    
    public var support: ClosedRange<Coords>? {
        grid.support
    }
    
    public func description(forObjectAt I: Coords) -> String {
        grid.description(forObjectAt: I)
    }
}
