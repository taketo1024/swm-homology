//
//  HomologyCalculator_LU.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwmCore
import SwmMatrixTools

public final class LUHomologyCalculator<C: ChainComplexType, _MatrixImpl: MatrixImpl_LU>: HomologyCalculator<C, _MatrixImpl> where C.BaseModule.BaseRing == _MatrixImpl.BaseRing {
    public override func calculate() -> Homology {
        .init { I in
            
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

            let C = self.chainComplex
            let d = C.differential
            let (a0, a1) = (self.matrix(at: I - d.degree), self.matrix(at: I))
            
            let e0 = a0.luDecomposition()
//          let Y1 = e0.image     // y x y1
            let Y23 = e0.cokernel // y x (y - y1)
            let b1 = a1 * Y23     // z x (y - y1)
            
            let e1 = b1.luDecomposition()
            let r = e1.nullity
            
            if r == 0 {
                return .zeroModule
            } else if self.options.contains(.onlyStructures) {
                return self.onlyStructure(rank: r)
            } else {
                let K = e1.kernel // (y - y1) x y2
                let Y2 = Y23 * K  // y x y2
                return self.homology(index: I, matrix: Y2)
            }
        }
    }
    
    private func homology(index I: Index, matrix H: Matrix) -> Homology.Object {
        let r = H.size.cols
        let summands = self.options.contains(.onlyStructures)
            ? self.onlyStructure(rank: r).summands
            : self.homologyGenerators(index: I, matrix: H)
        
        let vectorizer = self.options.contains(.onlyStructures)
            ? self.onlyStructure(rank: r).vectorizer
            : self.homologyVectorizer(index: I, matrix: H)

        return ModuleStructure(summands: summands, vectorizer: vectorizer)
    }
    
    private func homologyGenerators(index I: Index, matrix H: Matrix) -> [Homology.Object.Summand] {
        let gens = BaseModule.combine(
            basis: chainComplex[I].generators,
            matrix: AnySizeMatrix(H)
        )
        return gens.map{ z in .init(z) }
    }
    
    private func homologyVectorizer(index I: Index, matrix H: Matrix) -> Homology.Object.Vectorizer {
        let C = chainComplex[I]
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
