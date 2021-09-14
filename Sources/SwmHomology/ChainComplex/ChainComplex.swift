//
//  GradedChainComplex.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/21.
//

import SwmCore

public protocol ChainComplexType: IndexedModuleStructureType {
    typealias Differential = ChainMap<Self, Self>
    var differential: Differential { get }
}

public typealias ChainComplex1<M: Module> = ChainComplex<Int, M>
public typealias ChainComplex2<M: Module> = ChainComplex<IntList<_2>, M>

public struct ChainComplex<Index: AdditiveGroup & Hashable, BaseModule: Module>: ChainComplexType {
    public typealias BaseGrid = IndexedModuleStructure<Index, BaseModule>
    public typealias Object = BaseGrid.Object
    public typealias Differential = ChainMap<Self, Self>
    
    public let grid: BaseGrid
    public let differential: Differential

    public init(grid: BaseGrid, differential: Differential) {
        self.grid = grid
        self.differential = differential
    }
    
    public init(support: [Index] = [], grid: @escaping (Index) -> Object, degree: Index, differential: @escaping (Index) -> Differential.Object) {
        self.init(
            grid: IndexedModuleStructure(support: support, grid: grid),
            differential: ChainMap(degree: degree, maps: differential)
        )
    }
    
    public subscript(i: Index) -> Object {
        grid[i]
    }
    
    public func shifted(_ shift: Index) -> Self {
        .init(grid: grid.shifted(shift), differential: differential.shifted(shift))
    }
    
    public var support: [Index] {
        grid.support
    }
    
    public func isFreeToFree(at i: Index) -> Bool {
        grid[i].isFree && grid[i + differential.degree].isFree
    }
    
    public func assertChainComplex(at i0: Index, debug: Bool = false) {
        func print(_ msg: @autoclosure () -> String) {
            if debug { Swift.print(msg()) }
        }
        
        let d = differential
        let deg = d.degree
        let i1 = i0 + deg
        let i2 = i1 + deg
        let (s0, s1, s2) = (self[i0], self[i1], self[i2])
        
        print("\(i0): \(s0) -> \(s1) -> \(s2)")
        
        for x in s0.generators {
            let y = d[i0](x)
            let z = d[i1](y)
            print("\t\(x) ->\t\(y) ->\t\(z)")
            
            assert(self[i2].vectorize(z)?.isZero ?? false)
        }
    }
    
    public func assertChainComplex(debug: Bool = false) {
        for i in support {
            assertChainComplex(at: i, debug: debug)
        }
    }

    public var dual: ChainComplex<Index, DualModule<BaseModule>> {
        ChainComplex<Index, DualModule<BaseModule>>(
            grid: grid.dual,
            differential: differential.dual
        )
    }
}

extension ChainComplex1 where Index == Int {
    public init(grid: [Object], degree: Index, differential: [Differential.Object]) {
        assert(grid.count == differential.count)
        self.init(
            support: Array(0 ..< grid.count),
            grid: { i in
                grid.indices.contains(i) ? grid[i] : .zeroModule
            },
            degree: degree,
            differential: { i in
                differential.indices.contains(i) ? differential[i] : .zero
            }
        )
    }
    
    public func asBigraded(secondaryDegreeSupport: [Int] = [], differentialSecondaryDegree: Int = 0, secondaryDegreeMap: @escaping (Object.Summand) -> Int) -> ChainComplex2<BaseModule> {
        ChainComplex2(
            support: (support * secondaryDegreeSupport).map{ (i, j) in [i, j] },
            grid: { I in
                let (i, j) = I.tuple
                return self[i].filter { summand in
                    secondaryDegreeMap(summand) == j
                }
            },
            degree: IntList<_2>(differential.degree, differentialSecondaryDegree),
            differential: { I in self.differential[I[0]] }
        )
    }
}
