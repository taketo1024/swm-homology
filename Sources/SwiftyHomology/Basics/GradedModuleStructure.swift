//
//  GradedModuleStructure.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/18.
//

import SwiftyMath

public protocol GradedModuleStructureType: GradedStructure where Object == ModuleStructure<BaseModule> {
    associatedtype BaseModule: Module
}

public typealias ModuleGrid1<M: Module> = GradedModuleStructure<Int, M>
public typealias ModuleGrid2<M: Module> = GradedModuleStructure<MultiIndex<_2>, M>

public struct GradedModuleStructure<Index: AdditiveGroup & Hashable, BaseModule: Module>: GradedModuleStructureType {
    public typealias Object = ModuleStructure<BaseModule>
    public typealias R = BaseModule.BaseRing
    
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
    
    public func description(forObjectAt i: Index) -> String {
        let obj = self[i]
        return obj.isZero ? "" : obj.description
    }
}

extension GradedModuleStructure {
    public var dual: GradedModuleStructure<Index, DualModule<BaseModule>> {
        .init { i in self[i].dual }
    }
}
