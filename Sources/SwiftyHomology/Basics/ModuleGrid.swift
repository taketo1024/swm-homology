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
    
    private let grid: (IntList) -> Vertex
    private let gridCache: Cache<[IntList : Vertex]> = Cache([:])
    
    public init(grid: @escaping (IntList) -> Vertex) {
        self.grid = grid
    }
    
    public subscript(I: IntList) -> Vertex {
        let vertex: Vertex
        if let cached = gridCache.value![I] {
            vertex = cached
        } else {
            vertex = grid(I)
            gridCache.value![I] = vertex
        }
        return vertex
    }
    
    public subscript(I: Int...) -> Vertex {
        return self[IntList(I)]
    }
    
    public var gridDim: Int {
        return GridDim.intValue
    }
    
    public var description: String {
        return gridCache.value!.description
    }
}

extension ModuleGrid where GridDim == _1 {
    public init(sequence: @escaping (Int) -> ModuleObject<BaseModule>) {
        self.init{ I in sequence(I[0]) }
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
