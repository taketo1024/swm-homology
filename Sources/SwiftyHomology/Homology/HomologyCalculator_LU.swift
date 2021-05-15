//
//  HomologyCalculator_LU.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwiftyMath

extension HomologyCalculator where _MatrixImpl: MatrixImpl_LU {
    public func calculateByLU() -> Homology {
        .init(support: chainComplex.grid.support) { I in
            
            //       A0        A1
            //  C0 -----> C1 -----> C2
            //
            
            let d = self.chainComplex.differential
            
            let (A0, A1) = (self.matrix(at: I - d.multiDegree), self.matrix(at: I))
            let (e0, e1) = (A0.luDecomposition(), A1.luDecomposition())
            let (k, l) = (e1.nullity, e0.rank)
            
            if k == l {
                return .zeroModule
            } else if !self.options.contains(.withGenerators) && !self.options.contains(.withVectorizer) {
                return self.onlyStructure(rank: k - l)
            } else {
                let Z = e1.kernel
                let B = e0.image
                return self.homology(index: I, cycles: Z, boundaries: B)
            }
        }
    }
    
    private func homology(index I: Coords, cycles Z: Matrix, boundaries B: Matrix) -> Homology.Object {
        
        //
        //   B    ⊂    Z  -->>  H
        //   |         |        |
        //   v    T    v        v
        //  R^l  ---> R^k -->> R^{k-l}
        //
        
        let (k, l) = (Z.size.cols, B.size.cols)
        
        let T = Z.luDecomposition().solve(B)! // Z * T = B
        let e = T.luDecomposition()           // Z * PLUQ = B
        
        let P = e.P.inverse!
        let ZP = Z * P
        let H = ZP.submatrix(colRange: l ..< k)
        
        let summands = self.options.contains(.withGenerators)
            ? self.homologyGenerators(index: I, matrix: H)
            : self.onlyStructure(rank: k - l).summands
        
        let vectorizer = self.options.contains(.withVectorizer)
            ? self.homologyVectorizer(index: I, matrix: H)
            : self.onlyStructure(rank: k - l).vectorizer
        
        return ModuleObject(summands: summands, vectorizer: vectorizer)
    }
    
    private func homologyGenerators(index I: Coords, matrix H: Matrix) -> [Homology.Object.Summand] {
        let gens = BaseModule.combine(
            basis: chainComplex[I].generators,
            matrix: MatrixDxD(H)
        )
        return gens.map{ z in .init(z) }
    }
    
    private func homologyVectorizer(index I: Coords, matrix H: Matrix) -> Homology.Object.Vectorizer {
        let C = chainComplex[I]
        let e = H.luDecomposition()
        
        return { (z: BaseModule) in
            let x = MatrixInterface<_MatrixImpl, DynamicSize, _1>(C.vectorize(z))
            let y = e.solve(x) // Hy = x
            return VectorD(y!)
        }
    }
    
    private func onlyStructure(rank: Int) -> Homology.Object {
        .init(
            summands: (0 ..< rank).map { _ in .init(.zero) },
            vectorizer: { _ in .zero(size: rank) }
        )
    }
}
