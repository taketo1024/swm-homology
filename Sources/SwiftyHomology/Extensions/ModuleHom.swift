//
//  ModuleHom.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwiftyMath

extension ModuleHom where Domain: Module, Codomain: Module, Domain.BaseRing == Codomain.BaseRing {
    public func asMatrix(from: ModuleStructure<Domain>, to: ModuleStructure<Codomain>) -> AnySizeMatrix<BaseRing> {
        asMatrix(from: from, to: to, implType: DefaultMatrixImpl<BaseRing>.self)
    }
    
    public func asMatrix<Impl: MatrixImpl>(from: ModuleStructure<Domain>, to: ModuleStructure<Codomain>, implType: Impl.Type) -> MatrixIF<Impl, anySize, anySize> where Impl.BaseRing == BaseRing {
        
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
