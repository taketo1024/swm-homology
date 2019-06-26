//
//  GradedModuleMap.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/05/23.
//

import Foundation
import SwiftyMath

public typealias ChainMap1<M: Module, N: Module> = ChainMap<_1, M, N> where M.CoeffRing == N.CoeffRing
public typealias ChainMap2<M: Module, N: Module> = ChainMap<_2, M, N> where M.CoeffRing == N.CoeffRing

public struct ChainMap<GridDim: StaticSizeType, BaseModule1: Module, BaseModule2: Module> where BaseModule1.CoeffRing == BaseModule2.CoeffRing {
    public typealias R = BaseModule1.CoeffRing
    public typealias Hom = ModuleHom<BaseModule1, BaseModule2>
    
    public var multiDegree: IntList
    internal let maps: (IntList) -> Hom
    
    public init(multiDegree: IntList, maps: @escaping (IntList) -> Hom) {
        self.multiDegree = multiDegree
        self.maps = maps
    }
    
    public subscript(_ I: IntList) -> Hom {
        return maps(I)
    }
    
    public subscript(_ I: Int...) -> Hom {
        return self[IntList(I)]
    }
    
    public func shifted(_ shift: IntList) -> ChainMap<GridDim, BaseModule1, BaseModule2> {
        assert(shift.length == GridDim.intValue)
        return ChainMap(multiDegree: multiDegree) { I in
            self[I - shift]
        }
    }
    
    public func asMatrix(at I: IntList, from: ChainComplex<GridDim, BaseModule1>, to: ChainComplex<GridDim, BaseModule2>) -> DMatrix<R> {
        let (s0, s1) = (from[I], to[I + multiDegree])
        let f = self[I]
        
        let components = s0.generators.enumerated().flatMap { (j, x) -> [MatrixComponent<R>] in
            let y = f.applied(to: x)
            return to[I + multiDegree].factorize(y).map{ c in (c.row, j, c.value) }
        }
        
        return DMatrix(size: (s1.generators.count, s0.generators.count), components: components)
    }
    
    public func assertChainMap(at I0: IntList, from C0: ChainComplex<GridDim, BaseModule1>, to C1: ChainComplex<GridDim, BaseModule2>, debug: Bool = false) {
        assert(C0.differential.multiDegree == C1.differential.multiDegree)

        //          d0
        //  C0[I0] -----> C0[I1]
        //     |           |
        //   f |           | f
        //     v           v
        //  C1[I2] -----> C1[I3]
        //          d1

        let (f, d0, d1) = (self, C0.differential, C1.differential)

        func print(_ msg: @autoclosure () -> String) {
            Swift.print(msg())
        }

        let (I1, I2, I3) = (I0 + d0.multiDegree, I0 + f.multiDegree, I0 + d0.multiDegree + f.multiDegree)
        let (s0, s3) = (C0[I0], C1[I3])

        print("\(I0): \(s0) -> \(s3)")

        for x in s0.generators {
            let y0 = d0[I0].applied(to: x)
            let z0 =  f[I1].applied(to: y0)
            print("\t\(x) ->\t\(y0) ->\t\(z0)")

            let y1 =  f[I0].applied(to: x)
            let z1 = d1[I2].applied(to: y1)
            print("\t\(x) ->\t\(y1) ->\t\(z1)")
            print("")
            
            assert(C1[I3].factorize(z0) == C1[I3].factorize(z1))
        }
    }
}

extension ChainMap where GridDim == _1 {
    public init(degree: Int, maps: @escaping (Int) -> Hom) {
        self.init(multiDegree: IntList(degree)) { I in maps(I[0]) }
    }
    
    public subscript(_ i: Int) -> Hom {
        return self[IntList(i)]
    }
    
    public func shifted(_ shift: Int...) -> ChainMap<GridDim, BaseModule1, BaseModule2> {
        return shifted(IntList(shift))
    }
    
    public func asMatrix(at i: Int, from: ChainComplex<GridDim, BaseModule1>, to: ChainComplex<GridDim, BaseModule2>) -> DMatrix<R> {
        return asMatrix(at: IntList(i), from: from, to: to)
    }
    
    public func assertChainMap(at i: Int, from: ChainComplex<GridDim, BaseModule1>, to: ChainComplex<GridDim, BaseModule2>, debug: Bool = false) {
        assertChainMap(at: IntList(i), from: from, to: to, debug: debug)
    }

    
    public var degree: Int {
        return multiDegree[0]
    }
}

extension ChainMap where GridDim == _2 {
    public subscript(_ i: Int, _ j: Int) -> Hom {
        return self[IntList(i, j)]
    }
}

extension ChainMap {
    public var dual: ChainMap<GridDim, Dual<BaseModule2>, Dual<BaseModule1>> {
        return ChainMap<GridDim, Dual<BaseModule2>, Dual<BaseModule1>>(multiDegree: -self.multiDegree) { I in
            ModuleHom<Dual<BaseModule2>, Dual<BaseModule1>> { g in
                let f = self[I - self.multiDegree]
                return g ∘ f
            }
        }
    }
}
