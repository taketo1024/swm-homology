//
//  GradedChainComplex.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/21.
//

import Foundation
import SwiftyMath

public typealias ChainComplex1<M: Module> = ChainComplex<_1, M>
public typealias ChainComplex2<M: Module> = ChainComplex<_2, M>

public struct ChainComplex<GridDim: StaticSizeType, BaseModule: Module> {
    public typealias R = BaseModule.CoeffRing
    public typealias Differential = ChainMap<GridDim, BaseModule, BaseModule>
    
    public var grid: ModuleGrid<GridDim, BaseModule>
    
    internal let d: Differential
    internal let elimCache: CacheDictionary<GridCoords, Any> = .empty

    public init(grid: ModuleGrid<GridDim, BaseModule>, differential: Differential) {
        self.grid = grid
        self.d = differential
    }
    
    public subscript(I: GridCoords) -> ModuleObject<BaseModule> {
        return grid[I]
    }
    
    public subscript(I: Int...) -> ModuleObject<BaseModule> {
        return self[I]
    }
    
    public var gridDim: Int {
        return GridDim.intValue
    }
    
    public func shifted(_ shift: GridCoords) -> ChainComplex<GridDim, BaseModule> {
        assert(shift.count == gridDim)
        return ChainComplex(grid: grid.shifted(shift), differential: d.shifted(shift))
    }
    
    public func isFreeToFree(at I: GridCoords) -> Bool {
        return grid[I].isFree && grid[I.shifted(d.multiDegree)].isFree
    }
    
    public var differential: Differential {
        return d
    }
    
    public func differential(at I: GridCoords) -> Differential.Hom {
        return d[I]
    }
    
    public func differentialMatrix(at I: GridCoords) -> DMatrix<R> {
        return d.asMatrix(at: I, from: self, to: self)
    }
    
    public func assertChainComplex(at I0: GridCoords, debug: Bool = false) {
        func print(_ msg: @autoclosure () -> String) {
            if debug { Swift.print(msg()) }
        }
        
        let deg = d.multiDegree
        let I1 = I0.shifted(deg)
        let I2 = I1.shifted(deg)
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
    public init<S: Sequence>(type: ChainComplex1Type = .descending, supported: S, sequence: @escaping (Int) -> ModuleObject<BaseModule>, differential d: @escaping (Int) -> ModuleHom<BaseModule, BaseModule>) where S.Element == Int {
        self.init(grid: ModuleGrid1(supported: supported, sequence: sequence), differential: Differential(degree: type.degree, maps: d))
    }
    
    // chain complex (degree: -1)
    @available(*, deprecated, message: "use ChainComplex1(type: .descending, ...) ")
    public static func descending<S: Sequence>(supported: S, sequence: @escaping (Int) -> ModuleObject<BaseModule>, differential d: @escaping (Int) -> ModuleHom<BaseModule, BaseModule>) -> ChainComplex1<BaseModule> where S.Element == Int {
        return .init(type: .descending, supported: supported, sequence: sequence, differential: d)
    }
    
    // cochain complex (degree: +1)
    @available(*, deprecated, message: "use ChainComplex1(type: .ascending, ...) ")
    public static func ascending<S: Sequence>(supported: S, sequence: @escaping (Int) -> ModuleObject<BaseModule>, differential d: @escaping (Int) -> ModuleHom<BaseModule, BaseModule>) -> ChainComplex1<BaseModule> where S.Element == Int {
        return .init(type: .ascending, supported: supported, sequence: sequence, differential: d)
    }

    public func shifted(_ shift: Int) -> ChainComplex<GridDim, BaseModule> {
        return shifted([shift])
    }
    
    public func isFreeToFree(at i: Int) -> Bool {
        return isFreeToFree(at: [i])
    }
    
    public func differential(at i: Int) -> Differential.Hom {
        return differential(at: [i])
    }
    
    public func differentialMatrix(at i: Int) -> DMatrix<R> {
        return differentialMatrix(at: [i])
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
        return ChainComplex<GridDim, Dual<BaseModule>>(grid: grid.dual, differential: d.dual)
    }
}

extension ChainComplex where BaseModule: FreeModuleType {
    public func filtered(_ predicate: @escaping (BaseModule.Generator) -> Bool) -> ChainComplex<GridDim, BaseModule> {
        return ChainComplex(
            grid: ModuleGrid(supportedCoords: grid.supportedCoords) { I in
                let Ci = self[I]
                let gens = Ci.generators.compactMap{ z -> BaseModule.Generator? in
                    let x = z.unwrap()!
                    return (predicate(x)) ? x : nil
                }
                return ModuleObject(basis: gens)
            },
            differential: d
        )
    }
}

extension ChainComplex1 where GridDim == _1, BaseModule: FreeModuleType {
    public func asBigraded(supportedCoords: [GridCoords] = [], secondaryDegree: @escaping (BaseModule.Generator) -> Int) -> ChainComplex2<BaseModule> {
        return ChainComplex2(
            grid: ModuleGrid(supportedCoords: supportedCoords) { I in
                let (i, j) = (I[0], I[1])
                let Ci = self[i]
                let gens = Ci.generators.compactMap{ z -> BaseModule.Generator? in
                    let x = z.unwrap()!
                    return (secondaryDegree(x) == j) ? x : nil
                }
                return ModuleObject(basis: gens)
            },
            differential: ChainMap2(multiDegree: [d.degree, 0]) { I in
                self.differential(at: I[0])
            }
        )
    }
}
