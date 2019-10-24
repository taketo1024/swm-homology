//
//  GradedChainComplex.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/21.
//

import SwiftyMath

public typealias ChainComplex1<M: Module> = ChainComplex<_1, M>
public typealias ChainComplex2<M: Module> = ChainComplex<_2, M>

public struct ChainComplex<GridDim: StaticSizeType, BaseModule: Module> {
    public typealias Coords = GridCoords<GridDim>
    public typealias R = BaseModule.BaseRing
    public typealias Element = BaseModule
    public typealias Differential = ChainMap<GridDim, BaseModule, BaseModule>
    
    public var grid: ModuleGrid<GridDim, BaseModule>
    private let d: Differential

    public init(grid: ModuleGrid<GridDim, BaseModule>, differential: Differential) {
        self.grid = grid
        self.d = differential
    }
    
    public subscript(I: Coords) -> ModuleObject<BaseModule> {
        grid[I]
    }
    
    public subscript(I: Int...) -> ModuleObject<BaseModule> {
        self[Coords(I)]
    }
    
    public var gridDim: Int {
        GridDim.intValue
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
    
    public func differential(at I: Coords) -> Differential.Hom {
        d[I]
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
            let y = d[I0].applied(to: x)
            let z = d[I1].applied(to: y)
            print("\t\(x) ->\t\(y) ->\t\(z)")
            
            assert(self[I2].factorize(z).isZero)
        }
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
    public init(type: ChainComplex1Type = .descending, support: ClosedRange<Int>, sequence: @escaping (Int) -> ModuleObject<BaseModule>, differential d: @escaping (Int) -> ModuleHom<BaseModule, BaseModule>) {
        self.init(grid: ModuleGrid1(support: support, sequence: sequence), differential: Differential(degree: type.degree, maps: d))
    }
    
    public func shifted(_ shift: Int) -> Self {
        shifted([shift])
    }
    
    public func isFreeToFree(at i: Int) -> Bool {
        isFreeToFree(at: [i])
    }
    
    public func differential(at i: Int) -> Differential.Hom {
        differential(at: [i])
    }
    
    public func assertChainComplex(at i: Int, debug: Bool = false) {
        self.assertChainComplex(at: [i], debug: debug)
    }

    public func assertChainComplex(range: CountableClosedRange<Int>, debug: Bool = false) {
        for i in range {
            self.assertChainComplex(at: i, debug: debug)
        }
    }
    
    public func printSequence() {
        grid.printSequence()
    }
    
    public func printSequence(_ range: ClosedRange<Int>) {
        grid.printSequence(range)
    }
}

extension ChainComplex where GridDim == _2 {
    public func printTable() {
        grid.printTable()
    }
    
    public func printTable(_ range1: ClosedRange<Int>, _ range2: ClosedRange<Int>) {
        grid.printTable(range1, range2)
    }
}

extension ChainComplex {
    public var dual: ChainComplex<GridDim, Dual<BaseModule>> {
        ChainComplex<GridDim, Dual<BaseModule>>(grid: grid.dual, differential: d.dual)
    }
}
