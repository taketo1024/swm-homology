//
//  GradedModuleMap.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/05/23.
//

import SwiftyMath

public typealias ChainMap1<M: Module, N: Module> = ChainMap<Int, M, N> where M.BaseRing == N.BaseRing
public typealias ChainMap2<M: Module, N: Module> = ChainMap<MultiIndex<_2>, M, N> where M.BaseRing == N.BaseRing

public struct ChainMap<Index: AdditiveGroup & Hashable, BaseModule1: Module, BaseModule2: Module>: IndexedStructure where BaseModule1.BaseRing == BaseModule2.BaseRing {
    public typealias Object = ModuleHom<BaseModule1, BaseModule2>
    public typealias R = BaseModule1.BaseRing
    
    public var degree: Index
    internal let maps: (Index) -> Object
    
    public init(degree: Index, maps: @escaping (Index) -> Object) {
        self.degree = degree
        self.maps = maps
    }
    
    public subscript(_ i: Index) -> Object {
        maps(i)
    }
    
    public func shifted(_ shift: Index) -> Self {
        .init(degree: degree) { i in self[i - shift] }
    }
    
    public func assertChainMap(from C0: ChainComplex<Index, BaseModule1>, to C1: ChainComplex<Index, BaseModule2>, at i0: Index, debug: Bool = false) {
        let (f, d0, d1) = (self, C0.differential, C1.differential)
        assert(d0.degree == d1.degree)

        //          d0
        //  C0[I0] -----> C0[I1]
        //     |           |
        //   f |           | f
        //     v           v
        //  C1[I2] -----> C1[I3]
        //          d1

        func print(_ msg: @autoclosure () -> String) {
            Swift.print(msg())
        }

        let i1 = i0 + d0.degree
        let i2 = i0 + f.degree
        let i3 = i1 + f.degree
        let (s0, s3) = (C0[i0], C1[i3])

        print("\(i0): \(s0) -> \(s3)")

        for x in s0.generators {
            let y0 = d0[i0](x)
            let z0 =  f[i1](y0)
            print("\t\(x) ->\t\(y0) ->\t\(z0)")

            let y1 =  f[i0](x)
            let z1 = d1[i2](y1)
            print("\t\(x) ->\t\(y1) ->\t\(z1)")
            print("")
            
            assert(C1[i3].vectorize(z0) == C1[i3].vectorize(z1))
        }
    }
}

extension ChainMap {
    public var dual: ChainMap<Index, DualModule<BaseModule2>, DualModule<BaseModule1>> {
        .init(degree: -degree) { i in
            ModuleHom { g in
                let j = i - self.degree
                let f = self[j]
                return .init(g ∘ f)
            }
        }
    }
}
