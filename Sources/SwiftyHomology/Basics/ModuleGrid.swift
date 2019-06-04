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
    
    public var gridDim: Int {
        return GridDim.intValue
    }
    
    public func describe(_ I: IntList, detail: Bool = false) {
        print("\(I) ", terminator: "")
        self[I].describe(detail: detail)
    }
    
    public var description: String {
        return gridCache.value!.description
    }
}

extension ModuleGrid where GridDim == _1 {
    public init(sequence: @escaping (Int) -> ModuleObject<BaseModule>) {
        self.init{ I in sequence(I[0]) }
    }
    
    public subscript(i: Int) -> Vertex {
        return self[IntList(i)]
    }
    
    public func describe(_ i: Int) {
        describe(IntList(i))
    }
}

extension ModuleGrid where GridDim == _2 {
    public subscript(i: Int, j: Int) -> Vertex {
        return self[IntList(i, j)]
    }
    
    public func describe(_ i: Int, _ j: Int) {
        describe(IntList(i, j))
    }
}
