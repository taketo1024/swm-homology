//
//  Homology.swift
//  Sample
//
//  Created by Taketo Sano on 2018/06/02.
//

import SwiftyMath

public final class HomologyCalculator<GridDim: StaticSizeType, BaseModule: Module> where BaseModule.BaseRing: EuclideanRing {
    public typealias R = BaseModule.BaseRing
    
    public let chainComplex: ChainComplex<GridDim, BaseModule>
    private var elimResult: [GridCoords: MatrixEliminationResult<DynamicSize, DynamicSize, R>]
    
    public init(_ chainComplex: ChainComplex<GridDim, BaseModule>) {
        self.chainComplex = chainComplex
        self.elimResult = [:]
    }
    
    public func homology() -> ModuleGrid<GridDim, BaseModule> {
        .init(supportedCoords: chainComplex.grid.supportedCoords) { I in
            let C = self.chainComplex
            
            let generators = C[I].generators
            let d = C.differential
            let Z = self.cycleMatrix(I)
            let T = self.cycleTransitionMatrix(I)
            let B = self.boundaryMatrix(I.shifted(-d.multiDegree))
            let (diag, Q, S) = self.calculateQuotient(Z, B, T)
            
            let hGenerators = generators * Q
            let summands = hGenerators.enumerated().map { (i, z) in
                ModuleObject.Summand(z, diag[i])
            }
            let factr = { z in S * C[I].factorize(z) }
            
            return ModuleObject(summands, factr)
        }
    }
    
    public func cycleSubmodule(_ I: GridCoords) -> ModuleObject<BaseModule> {
        assert(chainComplex.isFreeToFree(at: I))
        let (Z, T) = (cycleMatrix(I), cycleTransitionMatrix(I))
        
        let C = chainComplex[I]
        let gens = C.generators * Z
        let factr = { z in T * C.factorize(z) }
        
        return ModuleObject(basis: gens, factorizer: factr)
    }
    
    public func boundarySubmodule(_ I: GridCoords) -> ModuleObject<BaseModule> {
        assert(chainComplex.isFreeToFree(at: I))
        let d = chainComplex.differential
        let J = I.shifted(-d.multiDegree)
        let (B, T) = (boundaryMatrix(J), boundaryTransitionMatrix(J))
        
        let C_I = chainComplex[I]
        let gens = C_I.generators * B
        let diag = dElim(J).result.diagonalComponents
        let factr = { (b: BaseModule) -> DVector<R> in
            let v = T * C_I.factorize(b)
            return DVector(size: v.size) { setEntry in
                v.nonZeroComponents.forEach { (i, _, a) in setEntry(i, 0, a / diag[i]) }
            }
        }
        return ModuleObject(basis: gens, factorizer: factr)
    }
    
    public func boundaryInverse(of b: BaseModule, at I: GridCoords) -> BaseModule? {
        assert(chainComplex.isFreeToFree(at: I))
        let d = chainComplex.differential
        let J = I.shifted(-d.multiDegree)
        if let v = dElim(J).invert(chainComplex[I].factorize(b)) {
            return (chainComplex[J].generators * v)[0]
        } else {
            return nil
        }
    }
    
    public func cycleMatrix(_ I: GridCoords) -> DMatrix<R> {
        dElim(I).kernelMatrix
    }
    
    public func cycleTransitionMatrix(_ I: GridCoords) -> DMatrix<R> {
        dElim(I).kernelTransitionMatrix
    }
    
    public func boundaryMatrix(_ I: GridCoords) -> DMatrix<R> {
        dElim(I).imageMatrix
    }
    
    public func boundaryTransitionMatrix(_ I: GridCoords) -> DMatrix<R> {
        dElim(I).imageTransitionMatrix
    }
    
    private func dElim(_ I: GridCoords) -> MatrixEliminationResult<DynamicSize, DynamicSize, R> {
        if let E = elimResult[I] {
            return E
        } else {
            assert(chainComplex.isFreeToFree(at: I))
            let A = chainComplex.differentialMatrix(at: I)
            let E = MatrixEliminator.eliminate(target: A, form: .Diagonal)
            elimResult[I] = E
            return E
        }
    }
    
    // Calculates the quotient module Im(A) / Im(B).
    //
    //        Im(B)  ⊂  Im(A) ⊂ R^n
    //          ↑         ↑   /
    //         B|        A|  / T
    //          |   TB    | ↓
    //    0 -> R^l >---> R^k --->> Q -> 0
    //          ↑         |
    //          |        P|
    //          |    S    ↓
    //    0 -> R^l >---> R^k --->> Q -> 0
    //
    // If
    //
    //     TB  ~>  S = [ I |   |   ]
    //                 [   | D |   ]
    //                 [   |   | O ]
    //                 [   |   | O ]
    //
    // then
    //
    //      Q = R^k / Im(I ⊕ D ⊕ O)
    //        = (0 ⊕ .. ⊕ 0) ⊕ (R/d_1 ⊕ .. ⊕ R/d_r) ⊕ (R ⊕ .. ⊕ R)
    //                          ~~~~~~~~~~~~~~~~~~~    ~~~~~~~~~~~~
    //                               tor-part            free-part
    
    private func calculateQuotient(_ A: DMatrix<R>, _ B: DMatrix<R>, _ T: DMatrix<R>) -> (factors: [R], generatingMatrix: DMatrix<R>, transitionMatrix: DMatrix<R>) {
        assert(A.size.rows == B.size.rows) // n
        assert(A.size.cols == T.size.rows) // k
        assert(A.size.rows >= A.size.cols) // n >= k
        assert(A.size.cols >= B.size.cols) // k >= l
        
        let (k, l) = (A.size.cols, B.size.cols)
        let elim = MatrixEliminator.eliminate(target: T * B, form: .Smith)
        let d = elim.result.diagonalComponents.exclude{ $0.isInvertible } + [R.zero] * (k - l)
        let s = d.count
        
        let P    = elim.left       .submatrix(rowRange: (k - s) ..< k)
        let Pinv = elim.leftInverse.submatrix(colRange: (k - s) ..< k)
        let (A2, T2) = (A * Pinv, P * T)
        
        assert(T2 * A2 == DMatrix<R>.identity(size: s))
        
        return (d, A2, T2)
    }
}

extension HomologyCalculator where GridDim == _1 {
    public func cycleSubmodule(_ i: Int) -> ModuleObject<BaseModule> {
        cycleSubmodule([i])
    }
    
    public func boundarySubmodule(_ i: Int) -> ModuleObject<BaseModule> {
        boundarySubmodule([i])
    }
    
    public func boundaryInverse(of b: BaseModule, at i: Int) -> BaseModule? {
        boundaryInverse(of: b, at: [i])
    }
    
    public func cycleMatrix(_ i: Int) -> DMatrix<R> {
        cycleMatrix([i])
    }
    
    public func cycleTransitionMatrix(_ i: Int) -> DMatrix<R> {
        cycleTransitionMatrix([i])
    }
    
    public func boundaryMatrix(_ i: Int) -> DMatrix<R> {
        boundaryMatrix([i])
    }
    
    public func boundaryTransitionMatrix(_ i: Int) -> DMatrix<R> {
        boundaryTransitionMatrix([i])
    }
}

extension ChainComplex where R: EuclideanRing {
    public var homology: ModuleGrid<GridDim, BaseModule> {
        HomologyCalculator(self).homology()
    }
}
