//
//  GradedChainComplex.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/21.
//

import SwiftyMath

public protocol ChainComplexType: GradedModuleStructureType {
    typealias Differential = ChainMap<Index, BaseModule, BaseModule>
    var differential: Differential { get }
}

extension ChainComplexType where BaseModule.BaseRing: EuclideanRing {
    public func homology(options: HomologyCalculatorOptions = []) -> GradedModuleStructure<Index, BaseModule> {
        DefaultHomologyCalculator(chainComplex: self, options: options).calculate()
    }
}

public typealias ChainComplex1<M: Module> = ChainComplex<Int, M>
public typealias ChainComplex2<M: Module> = ChainComplex<MultiIndex<_2>, M>

public struct ChainComplex<Index: AdditiveGroup & Hashable, BaseModule: Module>: ChainComplexType {
    public typealias BaseGrid = GradedModuleStructure<Index, BaseModule>
    public typealias Object = BaseGrid.Object
    public typealias Differential = ChainMap<Index, BaseModule, BaseModule>
    
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

//extension ChainComplex where BaseModule: LinearCombinationType, GridDim == _1 {
//    public func generateGraph() -> SimpleDirectedGraph<BaseModule.Generator, BaseModule.BaseRing> {
//        let C = self
//        guard let support = C.support else {
//            fatalError()
//        }
//
//        typealias Graph = SimpleDirectedGraph<BaseModule.Generator, BaseModule.BaseRing>
//        var graph = Graph()
//        var map: [BaseModule.Generator: Graph.Vertex] = [:]
//
//        for i in support.range {
//            for _x in C[i].generators {
//                let x = _x.unwrap()!
//                map[x] = graph.addVertex(value: x, options: ["group": i])
//            }
//        }
//
//        for i in support.range {
//            let d = C.differential[i]
//            for _x in C[i].generators {
//                let x = _x.unwrap()!
//                for (y, a) in d(x).elements where a != .zero {
//                    if let from = map[x], let to = map[y] {
//                        graph.addEdge(from: from, to: to, value: a)
//                    }
//                }
//            }
//        }
//
//        return graph
//    }
//}
