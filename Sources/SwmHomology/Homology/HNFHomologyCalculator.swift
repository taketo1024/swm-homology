//
//  File.swift
//
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwmCore
import SwmMatrixTools

public final class HNFHomologyCalculator<C: ChainComplexType>: HomologyCalculator<C, DefaultMatrixImpl<C.BaseModule.BaseRing>> where C.BaseModule.BaseRing: EuclideanRing {
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
            let e1 = a1.eliminate(form: .ColEchelon)
            
            let free = self.freePart(i, e1)
            let tor  = self.torPart (i, e1)
 
            return free ⊕ tor
        }
    }
    
    private func freePart<n, m>(_ i: Index, _ e1: MatrixEliminationResult<Impl, n, m>) -> Homology.Object {
        let C = chainComplex
        let d = C.differential
        
        let t1 = e1.imageComplementMatrix // n x s
        let Y2 = C[i].sub(matrix: t1)
        let Z  = C[i + d.degree]
        
        let b1: Matrix = d[i].asMatrix(from: Y2, to: Z) // p x s
        let e2 = b1.eliminate(form: .ColEchelon)
        let k  = e2.nullity
        
        if k == 0 {
            return .zeroModule
        } else if options.contains(.onlyStructures) {
            return onlyStructure(rank: k)
        }
        
        let t2 = e2.kernelMatrix // s x k
        
        let generators = (C[i].generators * t1) * t2 // [n] -> [s] -> [k]
        let summands = generators.map{ z in Summand(z) }
        let vectorizer = onlyStructure(rank: k).vectorizer // TODO
        
        return .init(
            summands: summands,
            vectorizer: vectorizer
        )
    }
    
    private func torPart<n, m>(_ i: Index, _ e1: MatrixEliminationResult<Impl, n, m>) -> Homology.Object {
        let C = chainComplex
        
        let e2 = e1.eliminate(form: .Smith)
        let diag = e2.diagonalEntries
        
        let r = diag.count
        let s = diag.firstIndex { d in !d.isIdentity } ?? r
        let l = r - s
        
        if l == 0 {
            return .zeroModule
        } else if options.contains(.onlyStructures) {
            return onlyStructure(divisors: diag[s ..< r])
        }
        
        let t1 = e2.leftInverse(restrictedToCols: s ..< r) // n x l
        let generators = C[i].generators * t1 // [n] -> [l]
        let summands = zip(generators, diag[s ..< r]).map{ (z, a) in
            Homology.Object.Summand(z, a)
        }
        let vectorizer = onlyStructure(divisors: diag[s ..< r]).vectorizer // TODO

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
