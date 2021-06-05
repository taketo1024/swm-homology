//
//  HomologyCalculator_LU.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwmCore
import SwmMatrixTools

public final class LUHomologyCalculator<C, M>: HomologyCalculator<C>
where C: ChainComplexType, C.BaseRing: HomologyCalculatable,
      M: MatrixImpl & LUFactorizable, M.BaseRing == C.BaseRing {
    
    private typealias Object = Homology.Object
    private typealias Summand = Object.Summand
    private typealias Vectorizer = Object.Vectorizer

    private typealias Matrix = MatrixIF<M, anySize, anySize>
    private typealias Vector = MatrixIF<M, anySize, _1>
    private typealias LU = LUFactorizationResult<M, anySize, anySize>
    
    private let luCache: Cache<Index, LU> = .empty

    internal override func calculate(_ i: Index) -> Homology.Object {
        
        //        a1        a2
        //    X -----> Y ------> Z
        //    ^        |
        //  Q |        | P
        //    |   b1   V
        //    X -----> Y1
        //             ⊕    b2
        //             Y2 -----> Z
        //
        //  H = Ker(a2) / Im(a1)
        //    = Ker(b2)
        
        let C = chainComplex
        let d = C.differential
        let X = C[i - d.degree]
        let Y = C[i]

        let e1 = luCache[i] ?? {
            let a1 = d[i - d.degree].asMatrix(from: X, to: Y, ofType: Matrix.self)
            return a1.LUfactorize()
        }()
        
        let T1 = e1.cokernel
        let Y2 = C[i].sub(matrix: T1)
        let Z = C[i + d.degree]
        
        let b2 = d[i].asMatrix(from: Y2, to: Z, ofType: Matrix.self)
        let e2 = b2.LUfactorize()
        
        // MEMO: e2 can be used for e1 in the next degree.
        // Note that only the cokernel of e1 is used.
        defer {
            luCache[i + d.degree] = e2
        }
        
        let r = e2.nullity
        if r == 0 {
            return .zeroModule
        } else if options.contains(.onlyStructures) {
            return onlyStructure(rank: r)
        }
        
        let T2 = e2.kernel // (y - y1) x y2
        let generators = (Y.generators * T1) * T2
        let summands = generators.map{ z in Summand(z.reduced) }
        
        let p = e1.cokernelProjector
        let vectorizer: Vectorizer = { z in
            guard let v = Y.vectorize(z)?.convert(to: Vector.self) else {
                return nil
            }
            
            if let x = e2.solveKernel(p(v)) {
                return x.convert(to: AnySizeVector.self)
            } else {
                return nil
            }
        }
        
        return Object(summands: summands, vectorizer: vectorizer)
    }
    
    private func onlyStructure(rank: Int) -> Homology.Object {
        .init(
            summands: (0 ..< rank).map { _ in .init(.zero) },
            vectorizer: { _ in nil }
        )
    }
}
