//
//  ModuleHom.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwiftyMath

extension ModuleHom {
    public func asMatrix(from: ModuleObject<X>, to: ModuleObject<Y>) -> MatrixDxD<BaseRing> {
        asMatrix(from: from, to: to, implType: DefaultMatrixImpl<BaseRing>.self)
    }
    
    public func asMatrix<Impl: MatrixImpl>(from: ModuleObject<X>, to: ModuleObject<Y>, implType: Impl.Type) -> MatrixIF<Impl, DynamicSize, DynamicSize> where Impl.BaseRing == BaseRing {
        
        let (n, m) = (to.generators.count, from.generators.count)
        let entries = Array(0 ..< m).parallelFlatMap { j -> [MatrixEntry<BaseRing>] in
            let x = from.generator(j)
            let y = self.callAsFunction(x)
            return Array(to.vectorize(y).nonZeroColEntries.map{ (i, a) in (i, j, a) })
        }
        
        return .init(size: (n, m)) { setEntry in
            entries.forEach { (i, j, a) in
                setEntry(i, j, a)
            }
        }
    }
}
