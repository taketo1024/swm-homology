//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwiftyMath

public final class DefaultHomologyCalculator<C: ChainComplexType>: HomologyCalculator<C, DefaultMatrixImpl<C.BaseModule.BaseRing>> where C.BaseModule.BaseRing: EuclideanRing {
    public override func calculate() -> Homology {
        return .init { I in
            typealias Summand = Homology.Object.Summand
            typealias Vectorizer = Homology.Object.Vectorizer

            let summands: [Summand]
            let vectorizer: Vectorizer

            //
            //       A0        A1
            //  C0 -----> C1 -----> C2
            //            |
            //            | P
            //       B0   |
            //  C0 -----> C1'
            //             ⊕
            //            C1"-----> C2
            //                 B1
            //
            //  H = H_free ⊕ H_tor,
            //  H_free = Ker(B1),
            //  H_tor  = Coker(B0).

            let (C, d) = (self.chainComplex, self.chainComplex.differential)
            let (A0, A1) = (self.matrix(at: I - d.degree), self.matrix(at: I))

            let E0 = A0.eliminate(form: .Smith)
            let diag = E0.diagonalEntries
            let m = A0.size.rows // == A1.size.cols
            let r = diag.count
            let s = diag.firstIndex { d in !d.isIdentity } ?? r

            //  P = [ Ps | Pr | Pm ] is the basis-trans matrix from C1 to C1' ⊕ C1".
            //  - gens * Ps collapses to 0,
            //  - gens * Pr gives the basis for the tor-part, and
            //  - gens * Pm * Ker(B1) gives the basis for the free-part.

            let Pm = E0.leftInverse(restrictedToCols: r ..< m)
            let B1 = A1 * Pm
            let E1 = B1.eliminate(form: .Diagonal)

            if self.options.contains(.withGenerators) {
                let gens = C[I].generators
                let Pr = E0.leftInverse(restrictedToCols: s ..< r)
                let tor_gens = BaseModule.combine(basis: gens, matrix: Pr)
                let tor = zip(tor_gens, diag[s ..< r]).map{ (z, d) in Summand(z, d) }

                let Z1 = E1.kernelMatrix
                let free_gens = BaseModule.combine(basis: gens, matrix: Pm * Z1)
                let free = free_gens.map { z in Summand(z) }

                summands = free + tor
            } else {
                let k = E1.nullity
                let free = (0 ..< k).map { _ in Summand(.zero) }
                let tor = diag[s ..< r].map { d in Summand(.zero, d) }

                summands = free + tor
            }

            if self.options.contains(.withVectorizer) {
                //  Q = P^{-1} = [Qs; Qr; Qm].
                //  - Qr (size: (r - s) × m ) maps C1 -> H_tor,
                //  - Qm (size: (m - r) × m ) maps C1 -> C1", and
                //  - Rk (size: k × (m - r) ) maps C1" -> Ker(B1) = H_free.
                //  Thus T = [Rk * Qm; Qr] (size: (r - s + k) × m ) maps C1 -> H = H_free ⊕ H_tor.

                let Qr = E0.left(restrictedToRows: s ..< r)
                let Tt = Qr.mapNonZeroEntries { (i, _, a) in a % diag[i + s] }

                let Qm = E0.left(restrictedToRows: r ..< m)
                let Rk = E1.kernelTransitionMatrix
                let Tf = Rk * Qm

                vectorizer = { z in
                    let v = C[I].vectorize(z)
                    let wf = Tf * v
                    let wt = (Tt * v).mapNonZeroEntries{ (i, _, a) in a % diag[i + s] }
                    return wf.stack(wt)
                }

            } else {
                vectorizer = { _ in VectorD.zero(size: summands.count) }
            }

            return ModuleObject(summands: summands, vectorizer: vectorizer)
        }
    }
}

private extension Matrix where Impl: SparseMatrixImpl {
    func mapNonZeroEntries(_ f: @escaping (MatrixEntry<BaseRing>) -> BaseRing) -> Self {
        .init(size: size) { setEntry in
            nonZeroEntries.forEach { (i, j, a) in
                setEntry(i, j, f((i, j, a)))
            }
        }
    }
}
