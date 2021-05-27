//
//  HomologyCalculator_LU.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwmCore
import SwmMatrixTools

public final class LUHomologyCalculator<C: ChainComplexType, _MatrixImpl: MatrixImpl_LU>: HomologyCalculator<C, _MatrixImpl> where C.BaseModule.BaseRing == _MatrixImpl.BaseRing {
    internal override func calculate(_ i: Index) -> Homology.Object {
        
        //      a0       a1
        //  X -----> Y -----> Z
        //           |
        //           |
        //           |
        //  X -----> Y1
        //           ⊕
        //           Y2
        //           ⊕
        //           Y3 ----> Z
        
        let C = chainComplex
        let d = C.differential
        let (a0, a1) = (matrix(at: i - d.degree), matrix(at: i))
        
        let e0 = a0.luDecomposition()
//      let Y1 = e0.image     // y x y1
        let Y23 = e0.cokernel // y x (y - y1)
        let b1 = a1 * Y23     // z x (y - y1)
        
        let e1 = b1.luDecomposition()
        let r = e1.nullity
        
        if r == 0 {
            return .zeroModule
        } else if options.contains(.onlyStructures) {
            return onlyStructure(rank: r)
        } else {
            let K = e1.kernel // (y - y1) x y2
            let Y2 = Y23 * K  // y x y2
            return homology(index: i, matrix: Y2)
        }
    }
    
    private func homology(index i: Index, matrix H: Matrix) -> Homology.Object {
        let r = H.size.cols
        let summands = options.contains(.onlyStructures)
            ? onlyStructure(rank: r).summands
            : homologyGenerators(index: i, matrix: H)
        
        let vectorizer = options.contains(.onlyStructures)
            ? onlyStructure(rank: r).vectorizer
            : homologyVectorizer(index: i, matrix: H)

        return ModuleStructure(summands: summands, vectorizer: vectorizer)
    }
    
    private func homologyGenerators(index i: Index, matrix H: Matrix) -> [Homology.Object.Summand] {
        let gens = BaseModule.combine(
            basis: chainComplex[i].generators,
            matrix: AnySizeMatrix(H)
        )
        return gens.map{ z in .init(z) }
    }
    
    private func homologyVectorizer(index i: Index, matrix H: Matrix) -> Homology.Object.Vectorizer {
        let C = chainComplex[i]
        let e = H.luDecomposition()
        
        return { (z: BaseModule) in
            let x = MatrixIF<_MatrixImpl, anySize, _1>(C.vectorize(z))
            let y = e.solve(x) // Hy = x
            return AnySizeVector(y!)
        }
    }
    
    private func onlyStructure(rank: Int) -> Homology.Object {
        .init(
            summands: (0 ..< rank).map { _ in .init(.zero) },
            vectorizer: { _ in .zero(size: rank) }
        )
    }
}
