//
//  ModuleHom.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwmCore

extension ModuleHom where Domain: Module, Codomain: Module, Domain.BaseRing == Codomain.BaseRing {
    public func asMatrix<Impl, n, m>(from: ModuleStructure<Domain>, to: ModuleStructure<Codomain>) -> MatrixIF<Impl, n, m>
    where Impl: MatrixImpl, n: SizeType, m: SizeType, Impl.BaseRing == BaseRing {
        
        let (n, m) = (to.generators.count, from.generators.count)
        let entries = Array(0 ..< m).parallelFlatMap { j -> [MatrixEntry<BaseRing>] in
            let x = from.generator(j)
            let y = self.callAsFunction(x)
            guard let v = to.vectorize(y) else {
                fatalError("Unavailable to vectorize.")
            }
            return v.nonZeroColEntries.map{ (i, a) in (i, j, a) }.toArray()
        }
        
        return .init(size: (n, m)) { setEntry in
            entries.forEach { (i, j, a) in
                setEntry(i, j, a)
            }
        }
    }
}
