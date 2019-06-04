//
//  GradedChainComplex.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/21.
//

import Foundation
import SwiftyMath

// TODO substitute for old ChainComplex.

public typealias ChainComplex1<M: Module> = ChainComplex<_1, M>
public typealias ChainComplex2<M: Module> = ChainComplex<_2, M>

public struct ChainComplex<GridDim: StaticSizeType, BaseModule: Module>: CustomStringConvertible {
    public typealias R = BaseModule.CoeffRing
    public typealias Differential = ChainMap<GridDim, BaseModule, BaseModule>
    
    public var grid: ModuleGrid<GridDim, BaseModule>
    public let differential: Differential
    private let matrixCache: Cache<[IntList : DMatrix<R>]> = Cache([:])

    public init(grid: ModuleGrid<GridDim, BaseModule>, differential: Differential) {
        self.grid = grid
        self.differential = differential
    }
    
    public subscript(I: IntList) -> ModuleObject<BaseModule> {
        return grid[I]
    }
    
    public var gridDim: Int {
        return GridDim.intValue
    }
    
    internal func isFreeToFree(_ I: IntList) -> Bool {
        return grid[I].isFree && grid[I + differential.multiDegree].isFree
    }
    
    internal func differntialMatrix(_ I: IntList) -> DMatrix<R> {
        if let A = matrixCache.value![I] {
            return A // cached.
        }
        
        let A = differential.asMatrix(at: I, from: self, to: self)
        matrixCache.value![I] = A
        return A
    }
    
    public func assertChainComplex(at I0: IntList, debug: Bool = false) {
        func print(_ msg: @autoclosure () -> String) {
            if debug { Swift.print(msg()) }
        }
        
        let deg = differential.multiDegree
        let (I1, I2) = (I0 + deg, I0 + deg + deg)
        let (s0, s1, s2) = (self[I0], self[I1], self[I2])
        
        print("\(I0): \(s0) -> \(s1) -> \(s2)")
        
        for x in s0.generators {
            let y = differential[I0].applied(to: x)
            
            let z = differential[I1].applied(to: y)
            print("\t\(x) ->\t\(y) ->\t\(z)")
            
            assert(self[I2].factorize(z).isZero)
        }
    }
    
    public func describe(_ I: IntList) {
        grid.describe(I)
    }
    
    public var description: String {
        return grid.description
    }
}

extension ChainComplex where GridDim == _1 {
    // chain complex (degree: -1)
    public init(descendingSequence sequence: @escaping (Int) -> ModuleObject<BaseModule>, differential d: @escaping (Int) -> ModuleHom<BaseModule, BaseModule>) {
        self.init(sequence: sequence, ascending: false, differential: d)
    }
    
    // cochain complex (degree: +1)
    public init(ascendingSequence sequence: @escaping (Int) -> ModuleObject<BaseModule>, differential d: @escaping (Int) -> ModuleHom<BaseModule, BaseModule>) {
        self.init(sequence: sequence, ascending: true, differential: d)
    }
    
    private init(sequence: @escaping (Int) -> ModuleObject<BaseModule>, ascending: Bool, differential d: @escaping (Int) -> ModuleHom<BaseModule, BaseModule>) {
        self.init(grid: ModuleGrid1(sequence: sequence), differential: Differential(degree: ascending ? 1 : -1, maps: d))
    }
    
    public subscript(i: Int) -> ModuleObject<BaseModule> {
        return grid[i]
    }
    
    public func describe(_ i: Int) {
        describe(IntList(i))
    }
}

extension ChainComplex where GridDim == _2 {
    public subscript(i: Int, j: Int) -> ModuleObject<BaseModule> {
        return grid[i, j]
    }
    
    public func describe(_ i: Int, _ j: Int) {
        describe(IntList(i, j))
    }
}

extension ChainComplex {
    public var dual: ChainComplex<GridDim, Dual<BaseModule>> {
        return ChainComplex<GridDim, Dual<BaseModule>>(grid: grid.dual, differential: differential.dual)
    }
}
