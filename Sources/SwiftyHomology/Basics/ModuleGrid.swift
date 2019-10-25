//
//  GradedModuleStructure.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/18.
//

import SwiftyMath

public typealias ModuleGrid1<M: Module> = ModuleGrid<_1, M>
public typealias ModuleGrid2<M: Module> = ModuleGrid<_2, M>

public struct ModuleGrid<GridDim: StaticSizeType, BaseModule: Module>: GridType {
    public typealias Coords = GridCoords<GridDim>
    public typealias Object = ModuleObject<BaseModule>
    public typealias R = BaseModule.BaseRing
    
    public let support: ClosedRange<Coords>?
    private let grid: (Coords) -> Object
    private let gridCache: CacheDictionary<Coords, Object> = CacheDictionary.empty
    
    public init(support: ClosedRange<Coords>? = nil, grid: @escaping (Coords) -> Object) {
        self.support = support
        self.grid = grid
    }
    
    public subscript(I: Coords) -> Object {
        gridCache.useCacheOrSet(key: I) { self.grid(I) }
    }
    
    public func shifted(_ shift: Coords) -> Self {
        let mSupport = support.map { support in support.lowerBound + shift ... support.upperBound + shift }
        return .init(support: mSupport ) { I in
            self[I - shift]
        }
    }
}

extension ModuleGrid where GridDim == _1 {
    public init(support: ClosedRange<Int>? = nil, sequence: @escaping (Int) -> ModuleObject<BaseModule>) {
        let mSupport = support.map { support in Coords(support.lowerBound) ... Coords(support.upperBound) }
        self.init(support: mSupport) { I in sequence(I[0]) }
    }
}

extension ModuleGrid {
    public var dual: ModuleGrid<GridDim, Dual<BaseModule>> {
        .init(support: support) { I in self[I].dual }
    }
}
