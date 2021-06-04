//
//  HomologyCalculator_LU.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwmCore
import SwmMatrixTools

public final class LUHomologyCalculator<C: ChainComplexType, M: MatrixImpl & LUFactorizable>: HomologyCalculator<C> where C.BaseModule.BaseRing == M.BaseRing {
    
    private typealias Matrix = MatrixIF<M, anySize, anySize>
    private typealias Vector = MatrixIF<M, anySize, _1>

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
        
        let e0 = a0.LUfactorize()
//      let Y1 = e0.image     // y x y1
        let Y23 = e0.cokernel // y x (y - y1)
        let b1 = a1 * Y23     // z x (y - y1)
        
        let e1 = b1.LUfactorize()
        let r = e1.nullity
        
        if r == 0 {
            return .zeroModule
        } else if options.contains(.onlyStructures) {
            return onlyStructure(rank: r)
        } else {
            let p = e0.cokernelProjector
            let K = e1.kernel // (y - y1) x y2
            let Y2 = Y23 * K  // y x y2
            return homology(index: i, matrix: Y2, projector: p)
        }
    }
    
    private func homology(index i: Index, matrix H: Matrix, projector p: @escaping (Vector) -> Vector) -> Homology.Object {
        let r = H.size.cols
        let summands = options.contains(.onlyStructures)
            ? onlyStructure(rank: r).summands
            : homologyGenerators(index: i, matrix: H)
        
        let vectorizer = options.contains(.onlyStructures)
            ? onlyStructure(rank: r).vectorizer
            : homologyVectorizer(index: i, matrix: H, projector: p)

        return ModuleStructure(summands: summands, vectorizer: vectorizer)
    }
    
    private func homologyGenerators(index i: Index, matrix H: Matrix) -> [Homology.Object.Summand] {
        (chainComplex[i].generators * H).map{ z in .init(z) }
    }
    
    private func homologyVectorizer(index i: Index, matrix H: Matrix, projector p: @escaping (Vector) -> Vector) -> Homology.Object.Vectorizer {
        let C = chainComplex[i]
        let e = H.LUfactorize()
        
        assert(H.permute(rowsBy: e.P, colsBy: e.Q) == e.L * e.U)
        
        return { (z: BaseModule) in
            if let v = C.vectorize(z)?.convert(to: Vector.self),
               let x = e.solve(p(v)) {
                return x.convert(to: AnySizeVector.self)
            } else {
                return nil
            }
        }
    }
    
    private func onlyStructure(rank: Int) -> Homology.Object {
        .init(
            summands: (0 ..< rank).map { _ in .init(.zero) },
            vectorizer: { _ in nil }
        )
    }
    
    private let matrixCache: Cache<Index, Matrix> = .empty
    private func matrix(at i: Index) -> Matrix {
        matrixCache.getOrSet(key: i) {
            let (C, d) = (chainComplex, chainComplex.differential)
            let (C0, C1) = (C[i], C[i + d.degree])
            return d[i].asMatrix(from: C0, to: C1)
        }
    }
}
