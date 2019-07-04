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
    public let differential: Differential

    public init(grid: ModuleGrid<GridDim, BaseModule>, differential: Differential) {
        self.grid = grid
        self.differential = differential
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
        return ChainComplex(grid: grid.shifted(shift), differential: differential.shifted(shift))
    }
    
    public func isFreeToFree(at I: GridCoords) -> Bool {
        return grid[I].isFree && grid[I.shifted(differential.multiDegree)].isFree
    }
    
    public func differntialMatrix(at I: GridCoords) -> DMatrix<R> {
        return differential.asMatrix(at: I, from: self, to: self)
    }
    
    public func assertChainComplex(at I0: GridCoords, debug: Bool = false) {
        func print(_ msg: @autoclosure () -> String) {
            if debug { Swift.print(msg()) }
        }
        
        let deg = differential.multiDegree
        let I1 = I0.shifted(deg)
        let I2 = I1.shifted(deg)
        let (s0, s1, s2) = (self[I0], self[I1], self[I2])
        
        print("\(I0): \(s0) -> \(s1) -> \(s2)")
        
        for x in s0.generators {
            let y = differential[I0].applied(to: x)
            
            let z = differential[I1].applied(to: y)
            print("\t\(x) ->\t\(y) ->\t\(z)")
            
            assert(self[I2].factorize(z).isZero)
        }
    }
}

extension ChainComplex where GridDim == _1 {
    // chain complex (degree: -1)
    public static func descending<S: Sequence>(supported: S, sequence: @escaping (Int) -> ModuleObject<BaseModule>, differential d: @escaping (Int) -> ModuleHom<BaseModule, BaseModule>) -> ChainComplex1<BaseModule> where S.Element == Int {
        return _sequence(supported: supported, ascending: false, sequence: sequence, differential: d)
    }
    
    // cochain complex (degree: +1)
    public static func ascending<S: Sequence>(supported: S, sequence: @escaping (Int) -> ModuleObject<BaseModule>, differential d: @escaping (Int) -> ModuleHom<BaseModule, BaseModule>) -> ChainComplex1<BaseModule> where S.Element == Int {
        return _sequence(supported: supported, ascending: true, sequence: sequence, differential: d)
    }
    
    private static func _sequence<S: Sequence>(supported: S, ascending: Bool, sequence: @escaping (Int) -> ModuleObject<BaseModule>, differential d: @escaping (Int) -> ModuleHom<BaseModule, BaseModule>) -> ChainComplex1<BaseModule> where S.Element == Int {
        return .init(grid: ModuleGrid1(supported: supported, sequence: sequence), differential: Differential(degree: ascending ? 1 : -1, maps: d))
    }
    
    public func shifted(_ shift: Int) -> ChainComplex<GridDim, BaseModule> {
        return shifted([shift])
    }
    
    public func isFreeToFree(at i: Int) -> Bool {
        return isFreeToFree(at: [i])
    }
    
    public func differntialMatrix(at i: Int) -> DMatrix<R> {
        return differntialMatrix(at: [i])
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
        return ChainComplex<GridDim, Dual<BaseModule>>(grid: grid.dual, differential: differential.dual)
    }
}
