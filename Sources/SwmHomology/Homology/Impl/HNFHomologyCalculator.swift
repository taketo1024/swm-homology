//
//  File.swift
//
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwmCore
import SwmMatrixTools

public final class HNFHomologyCalculator<C, M: MatrixImpl>: HomologyCalculator<C>
where C: ChainComplexType, C.BaseRing == M.BaseRing, M.BaseRing: EuclideanRing & ComputationalRing {
    
    private typealias Object = Homology.Object
    private typealias Summand = Object.Summand
    private typealias Vectorizer = Object.Vectorizer
    
    private typealias R = C.BaseRing
    private typealias Matrix = MatrixIF<M, anySize, anySize>
    private typealias Vector = ColVectorIF<M, anySize>
    private typealias Elimination = MatrixEliminationResult<M, anySize, anySize>
    
    private let eliminationCache: Cache<Index, Elimination> = .empty

    internal override func calculate(_ i: Index) -> Homology.Object {
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
        
        let C = chainComplex
        let d = C.differential
        let X = C[i - d.degree]
        let Y = C[i]
        
        let e1 = eliminationCache[i] ?? {
            let a1 = d[i - d.degree].asMatrix(from: X, to: Y, ofType: Matrix.self)
            return a1.eliminate(form: .RowEchelon)
        }()
        
        let free = freePart(i, e1)
        let tor  = torPart (i, e1)
        
        return free ⊕ tor
    }
    
    private func freePart(_ i: Index, _ e1: Elimination) -> Homology.Object {
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
        )
        
        let Y2 = C[i].sub(matrix: T1)
        let Z  = C[i + d.degree]
        
        let b2 = d[i].asMatrix(from: Y2, to: Z, ofType: Matrix.self) // p x (n - r)
        let e2 = b2
            .eliminate(form: .RowEchelon)
            .eliminate(form: .ColEchelon)
        
        // MEMO: e2 can be used for e1 in the next degree.
        // Note that only the cokernel of e1 is used.
        defer {
            eliminationCache[i + d.degree] = e2
        }
        
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
            
            guard let v = C[i].vectorize(z, Vector.self) else {
                return nil
            }
            
            let P = e1.left // n x n
            let p = (P * v)[r ..< n] // projected to Y2
            
            if let x = e2.solveKernel(p) {
                return x.nonZeroColEntries.toArray()
            } else {
                return nil
            }
        }
        
        return .init(
            summands: summands,
            vectorizer: vectorizer
        )
    }
    
    private func torPart(_ i: Index, _ e1: Elimination) -> Homology.Object {
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
        )
        
        let C = chainComplex
        let generators = C[i].generators * T // [n] -> [l]
        let summands = zip(generators, d).map{ (z, a) in
            Summand(z, a)
        }
        
        let vectorizer: Vectorizer = { z in
            guard let v = C[i].vectorize(z, Vector.self) else {
                return nil
            }
            
            let P = e2.left
            let p = (P * v)[r - l ..< r].mapNonZeroEntries { (i, _, a) in
                a % d[i]
            }
            return p.nonZeroColEntries.toArray()
        }

        return .init(
            summands: summands,
            vectorizer: vectorizer
        )
    }
    
    private func onlyStructure(rank: Int) -> Homology.Object {
        .init(
            summands: (0 ..< rank).map { _ in .init(.zero) },
            vectorizer: { _ in nil }
        )
    }

    private func onlyStructure<S>(divisors: S) -> Homology.Object where S: Sequence, S.Element == BaseRing {
        .init(
            summands: divisors.map { a in .init(.zero, a) },
            vectorizer: { _ in nil }
        )
    }
}
