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
    public func structure() -> [Index : ModuleStructure<BaseModule>] {
        Dictionary(support.compactMap { idx in
            let obj = self[idx]
            return obj.isZero ? nil : (idx, obj)
        })
    }
    
    public func description(forObject obj: ModuleStructure<BaseModule>) -> String {
        obj.isZero ? "" : obj.description
    }
}

public typealias ModuleGrid1<M: Module> = GradedModuleStructure<Int, M>
public typealias ModuleGrid2<M: Module> = GradedModuleStructure<MultiIndex<_2>, M>

public struct GradedModuleStructure<Index: AdditiveGroup & Hashable, BaseModule: Module>: GradedModuleStructureType {
    public typealias Object = ModuleStructure<BaseModule>
    public typealias R = BaseRing
    
    public let support: [Index]
    private let grid: (Index) -> Object
    private let gridCache: Cache<Index, Object> = Cache.empty
    
    public init(support: [Index] = [], grid: @escaping (Index) -> Object) {
        self.support = support
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
        .init(
            support: support.reversed(),
            grid: { i in self[i].dual }
        )
    }
}
