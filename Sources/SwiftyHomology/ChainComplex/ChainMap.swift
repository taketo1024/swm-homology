//
//  GradedModuleMap.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/05/23.
//

import SwiftyMath

public typealias ChainMap1<M: Module, N: Module> = ChainMap<_1, M, N> where M.BaseRing == N.BaseRing
public typealias ChainMap2<M: Module, N: Module> = ChainMap<_2, M, N> where M.BaseRing == N.BaseRing

public struct ChainMap<GridDim: StaticSizeType, BaseModule1: Module, BaseModule2: Module>: GridType where BaseModule1.BaseRing == BaseModule2.BaseRing {
    public typealias Coords = GridCoords<GridDim>
    public typealias Object = ModuleHom<BaseModule1, BaseModule2>
    public typealias R = BaseModule1.BaseRing
    
    public var multiDegree: Coords
    internal let maps: (Coords) -> Object
    
    public init(multiDegree: Coords, maps: @escaping (Coords) -> Object) {
        self.multiDegree = multiDegree
        self.maps = maps
    }
    
    public subscript(_ I: Coords) -> Object {
        maps(I)
    }
    
    public var support: ClosedRange<Coords>? {
        nil
    }
    
    public func shifted(_ shift: Coords) -> Self {
        .init(multiDegree: multiDegree) { I in self[I - shift] }
    }
    
    public func assertChainMap(at I0: Coords, from C0: ChainComplex<GridDim, BaseModule1>, to C1: ChainComplex<GridDim, BaseModule2>, debug: Bool = false) {
        let (f, d0, d1) = (self, C0.differential, C1.differential)
        assert(d0.multiDegree == d1.multiDegree)

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

        let I1 = I0 + d0.multiDegree
        let I2 = I0 + f.multiDegree
        let I3 = I1 + f.multiDegree
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
    public init(degree: Int, maps: @escaping (Int) -> Object) {
        self.init(multiDegree: [degree], maps: { I in maps(I[0]) })
    }
    
    public func assertChainMap(at i: Int, from: ChainComplex<GridDim, BaseModule1>, to: ChainComplex<GridDim, BaseModule2>, debug: Bool = false) {
        assertChainMap(at: [i], from: from, to: to, debug: debug)
    }
    
    public var degree: Int {
        multiDegree[0]
    }
}

extension ChainMap {
    public var dual: ChainMap<GridDim, Dual<BaseModule2>, Dual<BaseModule1>> {
        .init(multiDegree: -multiDegree) { I in
            ModuleHom { g in
                let J = I - self.multiDegree
                let f = self[J]
                return .init(g ∘ f)
            }
        }
    }
}
