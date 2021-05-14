//
//  ModuleHom.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwiftyMath

extension ModuleHom {
    public func asMatrix(from: ModuleObject<X>, to: ModuleObject<Y>) -> MatrixDxD<BaseRing> {
        asMatrix(from: from, to: to, matrixType: MatrixDxD<BaseRing>.self)
    }
    
    public func asMatrix<Impl: MatrixImpl>(from: ModuleObject<X>, to: ModuleObject<Y>, matrixType: MatrixInterface<Impl, DynamicSize, DynamicSize>.Type) -> MatrixInterface<Impl, DynamicSize, DynamicSize> where Impl.BaseRing == BaseRing {
        
        let (n, m) = (to.generators.count, from.generators.count)
        let comps = Array(0 ..< m).parallelFlatMap { j -> [MatrixComponent<BaseRing>] in
            let x = from.generator(j)
            let y = self.callAsFunction(x)
            return Array(to.vectorize(y).nonZeroComponents.map{ (i, _, a) in (i, j, a) })
        }
        
        return .init(size: (n, m)) { setEntry in
            comps.forEach { (i, j, a) in
                setEntry(i, j, a)
            }
        }
    }
}
