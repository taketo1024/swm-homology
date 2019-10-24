//
//  GradedModuleStructure.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/18.
//

import SwiftyMath

public typealias ModuleGrid1<M: Module> = ModuleGrid<_1, M>
public typealias ModuleGrid2<M: Module> = ModuleGrid<_2, M>

public struct ModuleGrid<GridDim: StaticSizeType, BaseModule: Module> {
    public typealias Coords = GridCoords<GridDim>
    public typealias R = BaseModule.BaseRing
    public typealias Vertex = ModuleObject<BaseModule>
    
    public let support: ClosedRange<Coords>
    private let grid: (Coords) -> Vertex
    private let gridCache: CacheDictionary<Coords, Vertex> = CacheDictionary.empty
    
    public init(support: ClosedRange<Coords>, grid: @escaping (Coords) -> Vertex) {
        self.support = support
        self.grid = grid
    }
    
    public subscript(I: Coords) -> Vertex {
        gridCache.useCacheOrSet(key: I) { self.grid(I) }
    }
    
    public subscript(I: Int...) -> Vertex {
        self[GridCoords(I)]
    }
    
    public var gridDim: Int {
        GridDim.intValue
    }
    
    public func shifted(_ shift: Coords) -> Self {
        .init(support: (support.lowerBound + shift) ... (support.upperBound + shift) ) { I in
            self[I - shift]
        }
    }
}

extension ModuleGrid where GridDim == _1 {
    public init(support: ClosedRange<Int>, sequence: @escaping (Int) -> ModuleObject<BaseModule>) {
        let mSupport = Coords(support.lowerBound) ... Coords(support.upperBound)
        self.init(support: mSupport) { I in sequence(I[0]) }
    }
    
    public func shifted(_ shift: Int) -> Self {
        shifted([shift])
    }
    
    public func printSequence() {
        let indices = support.lowerBound[0] ... support.upperBound[0]
        printSequence(indices)
    }
    
    public func printSequence<S: Sequence>(_ indices: S) where S.Element == Int {
        print( Format.table(rows: [""], cols: indices, symbol: "i") { (_, i) in self[i].description } )
    }
}

extension ModuleGrid where GridDim == _2 {
    public func printTable() {
        let (i0, j0) = (support.lowerBound[0], support.lowerBound[1])
        let (i1, j1) = (support.upperBound[0], support.upperBound[1])
        printTable(i0 ... i1, j0 ... j1)
    }
    
    public func printTable<S1: Sequence, S2: Sequence>(_ indices1: S1, _ indices2: S2) where S1.Element == Int, S2.Element == Int {
        print( Format.table(rows: indices2.reversed(), cols: indices1, symbol: "j\\i") { (j, i) -> String in
            let s = self[i, j].description
            return (s != "0") ? s : ""
        } )
    }
}

extension ModuleGrid {
    public var dual: ModuleGrid<GridDim, Dual<BaseModule>> {
        .init(support: support) { I in self[I].dual }
    }
}
