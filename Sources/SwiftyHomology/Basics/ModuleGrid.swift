//
//  GradedModuleStructure.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/18.
//

import SwiftyMath

public protocol ModuleGridType: GridType where Object == ModuleObject<BaseModule> {
    associatedtype BaseModule: Module
}

public typealias ModuleGrid1<M: Module> = ModuleGrid<Int, M>
public typealias ModuleGrid2<M: Module> = ModuleGrid<MultiIndex<_2>, M>

public struct ModuleGrid<Index: AdditiveGroup & Hashable, BaseModule: Module>: ModuleGridType {
    public typealias Object = ModuleObject<BaseModule>
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

extension ModuleGrid {
    public var dual: ModuleGrid<Index, DualModule<BaseModule>> {
        .init { i in self[i].dual }
    }
}
