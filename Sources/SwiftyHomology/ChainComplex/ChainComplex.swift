//
//  GradedChainComplex.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/21.
//

import SwiftyMath

public typealias ChainComplex1<M: Module> = ChainComplex<_1, M>
public typealias ChainComplex2<M: Module> = ChainComplex<_2, M>

public struct ChainComplex<GridDim: StaticSizeType, BaseModule: Module>: GridWrapper {
    public typealias Coords = GridCoords<GridDim>
    public typealias Object = ModuleGrid<GridDim, BaseModule>.Object
    public typealias R = BaseModule.BaseRing
    public typealias Element = BaseModule
    public typealias Differential = ChainMap<GridDim, BaseModule, BaseModule>
    
    public var grid: ModuleGrid<GridDim, BaseModule>
    private let d: Differential

    public init(grid: ModuleGrid<GridDim, BaseModule>, differential: Differential) {
        self.grid = grid
        self.d = differential
    }
    
    public init(support: ClosedRange<Coords>?, differentialDegree: Coords, grid: @escaping (Coords) -> ModuleGrid<GridDim, BaseModule>.Object, differential: @escaping (Coords) -> Differential.Object) {
        self.init(
            grid: ModuleGrid(support: support, grid: grid),
            differential: ChainMap(multiDegree: differentialDegree, maps: differential)
        )
    }
    
    public func shifted(_ shift: Coords) -> Self {
        .init(grid: grid.shifted(shift), differential: d.shifted(shift))
    }
    
    public func isFreeToFree(at I: Coords) -> Bool {
        grid[I].isFree && grid[I + d.multiDegree].isFree
    }
    
    public var differential: Differential {
        d
    }
    
    public func assertChainComplex(debug: Bool = false) {
        guard let support = support else { return }
        GridCoords.allCoords(in: support).forEach { I in
            assertChainComplex(at: I, debug: debug)
        }
    }
    
    public func assertChainComplex(at I0: Coords, debug: Bool = false) {
        func print(_ msg: @autoclosure () -> String) {
            if debug { Swift.print(msg()) }
        }
        
        let deg = d.multiDegree
        let I1 = I0 + deg
        let I2 = I1 + deg
        let (s0, s1, s2) = (self[I0], self[I1], self[I2])
        
        print("\(I0): \(s0) -> \(s1) -> \(s2)")
        
        for x in s0.generators {
            let y = d[I0](x)
            let z = d[I1](y)
            print("\t\(x) ->\t\(y) ->\t\(z)")
            
            assert(self[I2].vectorize(z).isZero)
        }
    }
}

extension ChainComplex where BaseModule.BaseRing: EuclideanRing {
    public func homology(options: HomologyCalculatorOptions = []) -> ModuleGrid<GridDim, BaseModule> {
        DefaultHomologyCalculator(chainComplex: self, options: options).calculate()
    }
}

public enum ChainComplex1Type {
    case ascending, descending
    public var degree: Int {
        switch self {
        case  .ascending: return 1
        case .descending: return -1
        }
    }
}

extension ChainComplex where GridDim == _1 {
    public init(type: ChainComplex1Type = .descending, support: ClosedRange<Int>?, sequence: @escaping (Int) -> ModuleObject<BaseModule>, differential d: @escaping (Int) -> ModuleHom<BaseModule, BaseModule>) {
        self.init(
            grid: ModuleGrid1(support: support, sequence: sequence),
            differential: Differential(degree: type.degree, maps: d)
        )
    }
    
    public func isFreeToFree(at i: Int) -> Bool {
        isFreeToFree(at: [i])
    }
    
    public func assertChainComplex(at i: Int, debug: Bool = false) {
        self.assertChainComplex(at: [i], debug: debug)
    }
}

extension ChainComplex {
    public var dual: ChainComplex<GridDim, Dual<BaseModule>> {
        ChainComplex<GridDim, Dual<BaseModule>>(grid: grid.dual, differential: d.dual)
    }
}

extension ChainComplex1 where GridDim == _1 {
    public func asBigraded(secondarySupport: ClosedRange<Int>? = nil, differentialSecondaryDegree: Int = 0, secondaryDegreeMap: @escaping (ModuleObject<BaseModule>.Summand) -> Int) -> ChainComplex2<BaseModule> {
        let support = { () -> ClosedRange<GridCoords<_2>>? in
            if let s1 = self.support, let s2 = secondarySupport {
                return [s1.lowerBound[0], s2.lowerBound] ... [s1.upperBound[0], s2.upperBound]
            } else {
                return nil
            }
        }()
        
        return ChainComplex2(
            support: support,
            differentialDegree: [differential.degree, differentialSecondaryDegree],
            grid: { I in
                let (i, j) = (I[0], I[1])
                return self[i].filter { summand in
                    secondaryDegreeMap(summand) == j
                }
            },
            differential: { I in self.differential[I[0]] }
        )
    }
}

extension ChainComplex where BaseModule: FreeModule, GridDim == _1 {
    public func generateGraph() -> SimpleDirectedGraph<BaseModule.Generator, BaseModule.BaseRing> {
        let C = self
        guard let support = C.support else {
            fatalError()
        }
        
        typealias Graph = SimpleDirectedGraph<BaseModule.Generator, BaseModule.BaseRing>
        var graph = Graph()
        var map: [BaseModule.Generator: Graph.Vertex] = [:]
        
        for i in support.range {
            for _x in C[i].generators {
                let x = _x.unwrap()!
                map[x] = graph.addVertex(value: x, options: ["group": i])
            }
        }
        
        for i in support.range {
            let d = C.differential[i]
            for _x in C[i].generators {
                let x = _x.unwrap()!
                for (y, a) in d(x).elements where a != .zero {
                    if let from = map[x], let to = map[y] {
                        graph.addEdge(from: from, to: to, value: a)
                    }
                }
            }
        }
        
        return graph
    }
}
