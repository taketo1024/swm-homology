//
//  GradedModuleStructure.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/18.
//

import SwmCore

public protocol GradedModuleStructureType: GradedStructure where Object == ModuleStructure<BaseModule> {
    associatedtype BaseModule: Module
    typealias BaseRing = BaseModule.BaseRing
}

extension GradedModuleStructureType {
    public func description(forObjectAt i: Index) -> String {
        let obj = self[i]
        return obj.isZero ? "" : obj.description
    }
}

public typealias ModuleGrid1<M: Module> = GradedModuleStructure<Int, M>
public typealias ModuleGrid2<M: Module> = GradedModuleStructure<MultiIndex<_2>, M>

public struct GradedModuleStructure<Index: AdditiveGroup & Hashable, BaseModule: Module>: GradedModuleStructureType {
    public typealias Object = ModuleStructure<BaseModule>
    public typealias R = BaseRing
    
    private let grid: (Index) -> Object
    private let gridCache: Cache<Index, Object> = Cache.empty
    
    public init(grid: @escaping (Index) -> Object) {
        self.grid = grid
    }
    
    public subscript(I: Index) -> Object {
        gridCache.getOrSet(key: I) { self.grid(I) }
    }
    
    public func shifted(_ shift: Index) -> Self {
        .init { i in
            self[i - shift]
        }
    }
}

extension GradedModuleStructure {
    public var dual: GradedModuleStructure<Index, DualModule<BaseModule>> {
        .init { i in self[i].dual }
    }
}
