//
//  ModuleHom.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwmCore

extension ModuleHom where Domain: Module, Codomain: Module, Domain.BaseRing == Codomain.BaseRing {
    public func asMatrix(from: ModuleStructure<Domain>, to: ModuleStructure<Codomain>) -> AnySizeMatrix<BaseRing> {
        asMatrix(from: from, to: to, ofType: AnySizeMatrix.self)
    }
    
    public func asMatrix<M, n, m>(from: ModuleStructure<Domain>, to: ModuleStructure<Codomain>, ofType T: MatrixIF<M, n, m>.Type) -> MatrixIF<M, n, m>
    where M: MatrixImpl, n: SizeType, m: SizeType, M.BaseRing == BaseRing {
        let (n, m) = (to.generators.count, from.generators.count)
        let entries = Array(0 ..< m).parallelFlatMap { j -> [MatrixEntry<BaseRing>] in
            let x = from.generator(j)
            let y = self.callAsFunction(x)
            guard let v = to.vectorEntries(y) else {
                fatalError("Unavailable to vectorize \(y).")
            }
            return v.map{ (i, a) in (i, j, a) }
        }
        
        return .init(size: (n, m)) { setEntry in
            entries.forEach { (i, j, a) in
                setEntry(i, j, a)
            }
        }
    }
}
