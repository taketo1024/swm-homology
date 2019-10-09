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
    public typealias R = BaseModule.BaseRing
    public typealias Vertex = ModuleObject<BaseModule>
    
    public let supportedCoords: [GridCoords]
    private let grid: (GridCoords) -> Vertex
    private let gridCache: CacheDictionary<GridCoords, Vertex> = CacheDictionary.empty
    
    public init(supportedCoords: [GridCoords] = [], grid: @escaping (GridCoords) -> Vertex) {
        self.supportedCoords = supportedCoords
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
        return ModuleGrid(supportedCoords: supportedCoords.map{ $0.shifted(shift) }) { I in
            self[I.shifted(-shift)]
        }
    }
}

extension ModuleGrid where GridDim == _1 {
    public init<S: Sequence>(supported: S, sequence: @escaping (Int) -> ModuleObject<BaseModule>) where S.Element == Int {
        self.init(supportedCoords: supported.map{ [$0] }) { I in sequence(I[0]) }
    }
    
    public func shifted(_ shift: Int) -> ModuleGrid<GridDim, BaseModule> {
        return shifted([shift])
    }
    
    public func printSequence() {
        let indices = supportedCoords.map{ $0[0] }.sorted()
        printSequence(indices)
    }
    
    public func printSequence(_ range: ClosedRange<Int>) {
        printSequence(range.toArray())
    }
    
    private func printSequence(_ indices: [Int]) {
        print( Format.table(rows: [""], cols: indices, symbol: "i") { (_, i) in self[i].description } )
    }
}

extension ModuleGrid where GridDim == _2 {
    public func printTable() {
        let indices = [0, 1].map { i in
            Set(supportedCoords.map{ $0[i] }).sorted()
        }
        printTable(indices[0], indices[1])
    }
    
    public func printTable(_ range1: ClosedRange<Int>, _ range2: ClosedRange<Int>) {
        printTable(range1.toArray(), range2.toArray())
    }
    
    private func printTable(_ indices1: [Int], _ indices2: [Int]) {
        print( Format.table(rows: indices2.reversed(), cols: indices1, symbol: "j\\i") { (j, i) -> String in
            let s = self[i, j].description
            return (s != "0") ? s : ""
        } )
    }
}

extension ModuleGrid {
    public var dual: ModuleGrid<GridDim, Dual<BaseModule>> {
        return ModuleGrid<GridDim, Dual<BaseModule>>{ I in self[I].dual }
    }
}
