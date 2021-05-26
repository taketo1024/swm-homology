//
//  GradedChainComplex.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/21.
//

import SwmCore

public protocol ChainComplexType: GradedModuleStructureType {
    typealias Differential = ChainMap<Self, Self>
    var differential: Differential { get }
}

extension ChainComplexType where BaseModule.BaseRing: EuclideanRing {
    public func homology(options: HomologyCalculatorOptions = []) -> GradedModuleStructure<Index, BaseModule> {
        HNFHomologyCalculator(chainComplex: self, options: options).calculate()
    }

    public func oldHomology(options: HomologyCalculatorOptions = []) -> GradedModuleStructure<Index, BaseModule> {
        _HNFHomologyCalculator(chainComplex: self, options: options).calculate()
    }
}

public typealias ChainComplex1<M: Module> = ChainComplex<Int, M>
public typealias ChainComplex2<M: Module> = ChainComplex<MultiIndex<_2>, M>

public struct ChainComplex<Index: AdditiveGroup & Hashable, BaseModule: Module>: ChainComplexType {
    public typealias BaseGrid = GradedModuleStructure<Index, BaseModule>
    public typealias Object = BaseGrid.Object
    public typealias Differential = ChainMap<Self, Self>
    
    public let grid: BaseGrid
    public let differential: Differential

    public init(grid: BaseGrid, differential: Differential) {
        self.grid = grid
        self.differential = differential
    }
    
    public init(grid: @escaping (Index) -> Object, degree: Index, differential: @escaping (Index) -> Differential.Object) {
        self.init(
            grid: GradedModuleStructure(grid: grid),
            differential: ChainMap(degree: degree, maps: differential)
        )
    }
    
    public subscript(i: Index) -> Object {
        grid[i]
    }
    
    public func shifted(_ shift: Index) -> Self {
        .init(grid: grid.shifted(shift), differential: differential.shifted(shift))
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
            
            assert(self[i2].vectorize(z).isZero)
        }
    }

    public var dual: ChainComplex<Index, DualModule<BaseModule>> {
        ChainComplex<Index, DualModule<BaseModule>>(grid: grid.dual, differential: differential.dual)
    }
}

extension ChainComplex1 where Index == Int {
    public init(grid: [Object], degree: Index, differential: [Differential.Object]) {
        assert(grid.count == differential.count)
        self.init(
            grid: { i in
                grid.indices.contains(i) ? grid[i] : .zeroModule
            },
            degree: degree,
            differential: { i in
                differential.indices.contains(i) ? differential[i] : .zero
            }
        )
    }
    
    public func asBigraded(differentialSecondaryDegree: Int = 0, secondaryDegreeMap: @escaping (Object.Summand) -> Int) -> ChainComplex2<BaseModule> {
        ChainComplex2(
            grid: { I in
                let (i, j) = I.tuple
                return self[i].filter { summand in
                    secondaryDegreeMap(summand) == j
                }
            },
            degree: MultiIndex<_2>(differential.degree, differentialSecondaryDegree),
            differential: { I in self.differential[I[0]] }
        )
    }
}

extension ChainComplexType where Index == Int {
    public func generateGraph(range: ClosedRange<Int>) -> DirectedGraph<BaseModule, BaseModule.BaseRing> {
        typealias Graph = DirectedGraph<BaseModule, BaseModule.BaseRing>
        
        let C = self
        let d = C.differential
        
        var graph = Graph(template: .hierarchical)
        var table: [MultiIndex<_2>: Graph.Vertex] = [:]

        for i in range {
            for (j, z) in C[i].generators.enumerated() {
                table[[i, j]] = graph.addVertex(value: z, options: ["group": i])
            }
        }

        for i1 in range {
            let i2 = i1 + d.degree
            for (j1, z) in C[i1].generators.enumerated() {
                let from = table[[i1, j1]]!
                let w = d[i1](z)
                let vec = C[i2].vectorize(w)
                for (j2, a) in vec.nonZeroColEntries {
                    if let to = table[[i2, j2]] {
                        from.addEdge(to: to, value: a)
                    }
                }
            }
        }

        return graph
    }
}
