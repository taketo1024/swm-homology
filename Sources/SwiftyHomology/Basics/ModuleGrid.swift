//
//  GradedModuleStructure.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/18.
//

import Foundation
import SwiftyMath

public typealias ModuleGrid1<M: Module> = ModuleGrid<_1, M>
public typealias ModuleGrid2<M: Module> = ModuleGrid<_2, M>

public struct ModuleGrid<GridDim: StaticSizeType, BaseModule: Module> {
    public typealias R = BaseModule.CoeffRing
    public typealias Vertex = ModuleObject<BaseModule>
    
    private let grid: (GridCoords) -> Vertex
    private let gridCache: CacheDictionary<GridCoords, Vertex> = CacheDictionary.empty
    
    public init(grid: @escaping (GridCoords) -> Vertex) {
        self.grid = grid
    }
    
    public subscript(I: GridCoords) -> Vertex {
        assert(I.count == gridDim)
        return gridCache.useCacheOrSet(key: I) { self.grid(I) }
    }
    
    public subscript(I: Int...) -> Vertex {
        return self[I]
    }
    
    public var gridDim: Int {
        return GridDim.intValue
    }
    
    public func shifted(_ shift: GridCoords) -> ModuleGrid<GridDim, BaseModule> {
        assert(shift.count == gridDim)
        return ModuleGrid { I in
            self[I.shifted(-shift)]
        }
    }
}

extension ModuleGrid where GridDim == _1 {
    public init(sequence: @escaping (Int) -> ModuleObject<BaseModule>) {
        self.init{ I in sequence(I[0]) }
    }
    
    public func shifted(_ shift: Int) -> ModuleGrid<GridDim, BaseModule> {
        return shifted([shift])
    }

    public func printSequence(indices: [Int]) {
        print( Format.table(rows: [""], cols: indices, symbol: "i") { (_, i) in self[i].description } )
    }
    
    public func printSequence(range: ClosedRange<Int>) {
        printSequence(indices: range.toArray())
    }
}

extension ModuleGrid where GridDim == _2 {
    public func printTable(indices1: [Int], indices2: [Int]) {
        print( Format.table(rows: indices2.reversed(), cols: indices1, symbol: "j\\i") { (j, i) -> String in
            let s = self[i, j].description
            return (s != "0") ? s : ""
        } )
    }
    
    public func printTable(range1: ClosedRange<Int>, range2: ClosedRange<Int>) {
        printTable(indices1: range1.toArray(), indices2: range2.toArray())
    }
}

extension ModuleGrid {
    public var dual: ModuleGrid<GridDim, Dual<BaseModule>> {
        return ModuleGrid<GridDim, Dual<BaseModule>>{ I in self[I].dual }
    }
}
