//
//  File.swift
//
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwmCore
import SwmMatrixTools

public final class HNFHomologyCalculator<C>: HomologyCalculator<C, DefaultMatrixImpl<C.BaseModule.BaseRing>>
where C: ChainComplexType, C.BaseModule.BaseRing: EuclideanRing {
    private typealias Impl = DefaultMatrixImpl<C.BaseModule.BaseRing>
    private typealias Summand = Homology.Object.Summand
    private typealias Vectorizer = Homology.Object.Vectorizer

    public override func calculate() -> Homology {
        return .init { i in
            //
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
            //    = Ker(b2) ⊕ Coker(b1)

            let d  = self.chainComplex.differential
            let a1 = self.matrix(at: i - d.degree) // TODO use kernelComplement of b1
            let e1 = a1.eliminate(form: .RowEchelon)
            
            let free = self.freePart(i, e1)
            let tor  = self.torPart (i, e1)
 
            return free ⊕ tor
        }
    }
    
    private func freePart<n, m>(_ i: Index, _ e1: MatrixEliminationResult<Impl, n, m>) -> Homology.Object {
        let (n, r) = (e1.size.rows, e1.rank)
        if n == r {
            return .zeroModule
        }
        
        let C = chainComplex
        let d = C.differential
        
        let Pinv = e1.leftInverse
        let T1 = Pinv * Matrix.colUnits(
            size: (n, n - r),
            indices: r ..< n
        ).as(MatrixIF<Impl, n, anySize>.self)
        
        let Y2 = C[i].sub(matrix: T1)
        let Z  = C[i + d.degree]
        
        let b2: Matrix = d[i].asMatrix(from: Y2, to: Z) // p x (n - r)
        let e2 = b2.eliminate(form: .ColEchelon)
        let k = e2.nullity // <= n - r
        
        if k == 0 {
            return .zeroModule
        } else if options.contains(.onlyStructures) {
            return onlyStructure(rank: k)
        }
        
        let T2 = e2.kernelMatrix // (n - r) x k
        
        let generators = (C[i].generators * T1) * T2 // [n] -> [n - r] -> [k]
        let summands = generators.map{ z in Summand(z.reduced) }
        
        let vectorizer: Vectorizer = { z in
            // Solve:
            //
            //   T1 * (T2 * x) = v (mod Y1).
            //
            // Project to Y2 by [O, I_{n-r}] * (P * ( - )).
            // From T1 = P^-1 [O; I_{n-r}], we get
            //
            //   T2 * x = Pv[r ..< n].
            //
            // Then solve x as kernel vector of b2.
            
            let v = C[i].vectorize(z).as(ColVector<BaseRing, n>.self)
            
            let P = e1.left // n x n
            let p = (P * v)[r ..< n] // projected to Y2
            
            if let x = e2.solveKernel(p) {
                return x
            } else {
                fatalError()
            }
        }
        
        return .init(
            summands: summands,
            vectorizer: vectorizer
        )
    }
    
    private func torPart<n, m>(_ i: Index, _ e1: MatrixEliminationResult<Impl, n, m>) -> Homology.Object {
        if BaseRing.isField || e1.rank == 0 {
            return .zeroModule
        }
        
        let (n, r) = (e1.size.rows, e1.rank)
        
        let e2 = e1.eliminate(form: .Smith)
        let d = e2.headEntries
            .map{ $0.value }
            .exclude { $0.isIdentity }
        
        let l = d.count // <= r
        
        if l == 0 {
            return .zeroModule
        } else if options.contains(.onlyStructures) {
            return onlyStructure(divisors: d)
        }

        let Pinv = e2.leftInverse
        let T = Pinv * Matrix.colUnits(
            size: (n, l),
            indices: (r - l ..< r)
        ).as(MatrixIF<Impl, n, anySize>.self)
        
        let C = chainComplex
        let generators = C[i].generators * T // [n] -> [l]
        let summands = zip(generators, d).map{ (z, a) in
            Summand(z, a)
        }
        
        let vectorizer: Vectorizer = { z in
            let P = e2.left
            let v = C[i].vectorize(z).as(ColVector<BaseRing, n>.self)
            let p = (P * v)[r - l ..< r].mapNonZeroEntries { (i, _, a) in
                a % d[i]
            }
            return p
        }

        return .init(
            summands: summands,
            vectorizer: vectorizer
        )
    }
    
    private func onlyStructure(rank: Int) -> Homology.Object {
        .init(
            summands: (0 ..< rank).map { _ in .init(.zero) },
            vectorizer: { _ in .zero(size: rank) }
        )
    }

    private func onlyStructure<S>(divisors: S) -> Homology.Object where S: Sequence, S.Element == BaseRing {
        .init(
            summands: divisors.map { a in .init(.zero, a) },
            vectorizer: { _ in .zero(size: divisors.count) }
        )
    }
}
