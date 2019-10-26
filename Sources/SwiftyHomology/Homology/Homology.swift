//
//  Homology.swift
//  Sample
//
//  Created by Taketo Sano on 2018/06/02.
//

import SwiftyMath

public final class HomologyCalculator<GridDim: StaticSizeType, BaseModule: Module> where BaseModule.BaseRing: EuclideanRing {
    public typealias Coords = GridCoords<GridDim>
    public typealias R = BaseModule.BaseRing
    
    public let chainComplex: ChainComplex<GridDim, BaseModule>
    private var matrixCache: CacheDictionary<Coords, DMatrix<R>>
    
    public init(_ chainComplex: ChainComplex<GridDim, BaseModule>) {
        self.chainComplex = chainComplex
        self.matrixCache = .empty
    }
    
    private func matrix(at I: Coords) -> DMatrix<R> {
        matrixCache.useCacheOrSet(key: I) {
            let (C, d) = (chainComplex, chainComplex.differential)
            let (C0, C1) = (C[I], C[I + d.multiDegree])
            return d[I].asMatrix(from: C0, to: C1)
        }
    }
    
    public func homology(withGenerators: Bool = false, withVectorizer: Bool = false) -> ModuleGrid<GridDim, BaseModule> {
        .init(support: chainComplex.grid.support) { I in
            typealias Summand = ModuleObject<BaseModule>.Summand
            typealias Vectorizer = ModuleObject<BaseModule>.Vectorizer
            
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
            let (A0, A1) = (self.matrix(at: I - d.multiDegree), self.matrix(at: I))
            
            let E0 = MatrixEliminator.eliminate(target: A0, form: .Smith)
            let diag = E0.result.diagonalComponents.exclude{ $0.isZero }
            let m = A0.size.rows // == A1.size.cols
            let r = diag.count
            let s = diag.firstIndex { d in !d.isIdentity } ?? r
            
            //  P = [ Ps | Pr | Pm ] is the basis-trans matrix from C1 to C1' ⊕ C1".
            //  - gens * Ps collapses to 0,
            //  - gens * Pr gives the basis for the tor-part, and
            //  - gens * Pm * Ker(B1) gives the basis for the free-part.
            
            let Pm = E0.leftInverse(restrictedToCols: r ..< m)
            let B1 = A1 * Pm
            let E1 = MatrixEliminator.eliminate(target: B1, form: .Diagonal)
            
            if withGenerators {
                let gens = C[I].generators
                let Pr = E0.leftInverse(restrictedToCols: s ..< r)
                let tor = zip(gens * Pr, diag[s ..< r]).map{ (z, d) in Summand(z, d) }
                
                let Z1 = E1.kernelMatrix
                let free = (gens * (Pm * Z1)).map { z in Summand(z) }
                
                summands = free + tor
            } else {
                let k = E1.nullity
                let free = (0 ..< k).map { _ in Summand(.zero) }
                let tor = diag[s ..< r].map { d in Summand(.zero, d) }
                
                summands = free + tor
            }
            
            if withVectorizer {
                //  Q = P^{-1} = [Qs; Qr; Qm].
                //  - Qr (size: (r - s) × m ) maps C1 -> H_tor,
                //  - Qm (size: (m - r) × m ) maps C1 -> C1", and
                //  - Rk (size: k × (m - r) ) maps C1" -> Ker(B1) = H_free.
                //  Thus T = [Rk * Qm; Qr] (size: (r - s + k) × m ) maps C1 -> H = H_free ⊕ H_tor.
                
                let Qr = E0.left(restrictedToRows: s ..< r)
                let Tt = Qr.mapNonZeroComponents { (i, _, a) in a % diag[i + s] }
                
                let Qm = E0.left(restrictedToRows: r ..< m)
                let Rk = E1.kernelTransitionMatrix
                let Tf = Rk * Qm
                
                vectorizer = { z in
                    let v = C[I].vectorize(z)
                    let wf = Tf * v
                    let wt = (Tt * v).mapNonZeroComponents{ (i, _, a) in a % diag[i + s] }
                    return wf.concatVertically(wt)
                }
                
            } else {
                vectorizer = { _ in DVector.zero(size: summands.count) }
            }
            
            return ModuleObject(summands, vectorizer)
        }
    }
}

extension ChainComplex where R: EuclideanRing {
    public func homology(withGenerators b1: Bool = false, withVectorizer b2: Bool = false) -> ModuleGrid<GridDim, BaseModule> {
        HomologyCalculator(self).homology(withGenerators: b1, withVectorizer: b2)
    }
}
