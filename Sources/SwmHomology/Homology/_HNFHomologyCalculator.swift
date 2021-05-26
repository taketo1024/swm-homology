//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwmCore
import SwmMatrixTools

@available(*, deprecated)
public final class _HNFHomologyCalculator<C: ChainComplexType>: HomologyCalculator<C, DefaultMatrixImpl<C.BaseModule.BaseRing>> where C.BaseModule.BaseRing: EuclideanRing {
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
            let diag = E0.divisors
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

            if self.options.contains(.onlyStructures) {
                let k = E1.nullity
                let free = (0 ..< k).map { _ in Summand(.zero) }
                let tor = diag[s ..< r].map { d in Summand(.zero, d) }

                summands = free + tor
            } else {
                let gens = C[I].generators
                let Pr = E0.leftInverse(restrictedToCols: s ..< r)
                let tor_gens = BaseModule.combine(basis: gens, matrix: Pr)
                let tor = zip(tor_gens, diag[s ..< r]).map{ (z, d) in Summand(z, d) }

                let Z1 = E1.kernelMatrix
                let free_gens = BaseModule.combine(basis: gens, matrix: Pm * Z1)
                let free = free_gens.map { z in Summand(z) }

                summands = free + tor
            }

            if self.options.contains(.onlyStructures) {
                vectorizer = { _ in AnySizeVector.zero(size: summands.count) }
            } else {
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
            }

            return ModuleStructure(summands: summands, vectorizer: vectorizer)
        }
    }
}

private extension MatrixEliminationResult {
    func left(restrictedToRows rowRange: Range<Int>) -> MatrixIF<Impl, anySize, n> {
        composeRowOps(rowOps, restrictedToRows: rowRange)
    }
    
    func leftInverse(restrictedToCols colRange: Range<Int>) -> MatrixIF<Impl, n, anySize> {
        composeRowOps(rowOpsInverse, restrictedToCols: colRange)
    }
    
    func right(restrictedToCols colRange: Range<Int>) -> MatrixIF<Impl, m, anySize> {
        composeColOps(colOps, restrictedToCols: colRange)
    }
    
    func rightInverse(restrictedToRows rowRange: Range<Int>) -> MatrixIF<Impl, anySize, m> {
        composeColOps(colOpsInverse, restrictedToRows: rowRange)
    }
    
    // Returns the transition matrix T of Z,
    // i.e. T * Z = I_k.
    //
    //     T = [O, I_k] Q^-1
    //       = Q^-1 [r ..< n; -]
    //
    // satisfies T * Z = [O, I_k] * [O; I_k] = I_k.
    
    var kernelTransitionMatrix: MatrixIF<Impl, anySize, m> {
        switch form {
        case .Diagonal, .Smith, .ColHermite, .ColEchelon:
            return rightInverse(restrictedToRows: rank ..< size.cols)
            
        case .RowHermite, .RowEchelon:
            fatalError("not supported yet.")
            
        default:
            fatalError("unavailable.")
        }
    }
    
    //  Given row ops [P1, ..., Pn],
    //  produce P = (Pn ... P1) * I by applying the row-ops from P1 to Pn.
    
    private func composeRowOps<n, m, S>(_ ops: S, restrictedToCols colRange: Range<Int>) -> MatrixIF<Impl, n, m> where S: Sequence, S.Element == RowElementaryOperation<R> {
        composeRowOps(size: size.rows, ops: ops, restrictedToCols: colRange)
    }
    
    //  Given row ops [P1, ..., Pn],
    //  produce P = I * (Pn ... P1) by applying the corresponding col-ops from Pn to P1.
    //  Compute by P^t = (P1^t ... Pn^t) * I^t,
    
    private func composeRowOps<n, m, S>(_ ops: S, restrictedToRows rowRange: Range<Int>) -> MatrixIF<Impl, n, m> where S: Sequence, S.Element == RowElementaryOperation<R> {
        composeRowOps(size: size.rows, ops: ops.reversed().map{ $0.transposed.asRowOperation }, restrictedToCols: rowRange).transposed
    }
    
    //  Given col ops [Q1, ..., Qn],
    //  produce Q = I * (Q1 ... Qn) by applying the col-ops from Q1 to Qn.
    //  Compute by Q^t = (Qn^t ... Q1^t) * I^t.

    private func composeColOps<n, m, S>(_ ops: S, restrictedToRows rowRange: Range<Int>) -> MatrixIF<Impl, n, m> where S: Sequence, S.Element == ColElementaryOperation<R> {
        composeRowOps(size: size.cols, ops: ops.map{ $0.transposed }, restrictedToCols: rowRange).transposed
    }
    
    //  Given col ops [Q1, ..., Qn],
    //  produce Q = (Q1 ... Qn) * I by applying the corresponding row-ops from Qn to Q1.
    
    private func composeColOps<n, m, S>(_ ops: S, restrictedToCols colRange: Range<Int>) -> MatrixIF<Impl, n, m> where S: Sequence, S.Element == ColElementaryOperation<R> {
        composeRowOps(size: size.cols, ops: ops.reversed().map{ $0.asRowOperation }, restrictedToCols: colRange)
    }
    
    private func composeRowOps<n, m, S>(size n: Int, ops: S, restrictedToCols colRange: Range<Int>) -> MatrixIF<Impl, n, m> where S: Sequence, S.Element == RowElementaryOperation<R> {
        .init(
            size: (n, colRange.endIndex - colRange.startIndex),
            entries: colRange.map { i in (i, i - colRange.startIndex, .identity) }
        )
        .appliedRowOperations(ops)
    }
}
