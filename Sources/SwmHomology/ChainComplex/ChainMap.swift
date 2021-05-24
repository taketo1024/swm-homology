//
//  GradedModuleMap.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/05/23.
//

import SwmCore

public struct ChainMap<C1: ChainComplexType, C2: ChainComplexType>: GradedStructure
where C1.Index == C2.Index,
      C1.BaseModule.BaseRing == C2.BaseModule.BaseRing
{
    public typealias Index = C1.Index
    public typealias Object = ModuleHom<C1.BaseModule, C2.BaseModule>
    public typealias R = C1.BaseModule.BaseRing
    
    public var degree: Index
    internal let maps: (Index) -> Object
    
    public init(degree: Index, maps: @escaping (Index) -> Object) {
        self.degree = degree
        self.maps = maps
    }
    
    public init<D1, D2>(_ f: ChainMap<D1, D2>) where D1.Index == Index, D1.BaseModule == C1.BaseModule, D2.BaseModule == C2.BaseModule {
        self.init(degree: f.degree, maps: f.maps)
    }
    
    public subscript(_ i: Index) -> Object {
        maps(i)
    }
    
    public func shifted(_ shift: Index) -> Self {
        .init(degree: degree) { i in self[i - shift] }
    }
    
    public func assertChainMap(from c1: C1, to c2: C2, at i0: Index, debug: Bool = false) {
        let (f, d0, d1) = (self, c1.differential, c2.differential)
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
        let (s0, s3) = (c1[i0], c2[i3])

        print("\(i0): \(s0) -> \(s3)")

        for x in s0.generators {
            let y0 = d0[i0](x)
            let z0 =  f[i1](y0)
            print("\t\(x) ->\t\(y0) ->\t\(z0)")

            let y1 =  f[i0](x)
            let z1 = d1[i2](y1)
            print("\t\(x) ->\t\(y1) ->\t\(z1)")
            print("")
            
            assert(c2[i3].vectorize(z0) == c2[i3].vectorize(z1))
        }
    }
}

extension ChainMap {
    public var dual: ChainMap<ChainComplex<Index, DualModule<C2.BaseModule>>, ChainComplex<Index, DualModule<C1.BaseModule>>> {
        .init(degree: -degree) { i in
            ModuleHom { g in
                let j = i - self.degree
                let f = self[j]
                return .init(g ∘ f)
            }
        }
    }
}
