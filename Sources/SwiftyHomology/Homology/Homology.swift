//
//  Homology.swift
//  Sample
//
//  Created by Taketo Sano on 2018/06/02.
//

import Foundation
import SwiftyMath

public typealias Homology1<M: Module> = Homology<_1, M> where M.CoeffRing: EuclideanRing
public typealias Homology2<M: Module> = Homology<_2, M> where M.CoeffRing: EuclideanRing

public struct Homology<GridDim: StaticSizeType, BaseModule: Module> where BaseModule.CoeffRing: EuclideanRing {
    public typealias R = BaseModule.CoeffRing
    
    public let chainComplex: ChainComplex<GridDim, BaseModule>
    public let grid: ModuleGrid<GridDim, BaseModule>
    
    public init(_ chainComplex: ChainComplex<GridDim, BaseModule>) {
        typealias E = MatrixEliminationResult<DynamicSize, DynamicSize, R>
        
        let supported = chainComplex.grid.supportedCoords
        let grid = ModuleGrid<GridDim, BaseModule>(supportedCoords: supported) { I in
            let C = chainComplex
            
            let generators = C[I].generators
            let Z = C.cycleMatrix(I)
            let T = C.cycleTransitionMatrix(I)
            let B = C.boundaryMatrix(I.shifted(-C.d.multiDegree))
            let (d, Q, S) = Homology.calculateQuotient(Z, B, T)
            
            let hGenerators = generators * Q
            let summands = hGenerators.enumerated().map { (i, z) in
                ModuleObject.Summand(z, d[i])
            }
            let factr = { z in S * C[I].factorize(z) }
            
            return ModuleObject(summands, factr)
        }
        
        self.chainComplex = chainComplex
        self.grid = grid
    }
    
    public subscript(I: GridCoords) -> ModuleObject<BaseModule> {
        return grid[I]
    }
    
    public subscript(I: Int...) -> ModuleObject<BaseModule> {
        return self[I]
    }
    
    public var gridDim: Int {
        return GridDim.intValue
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
    
    internal static func calculateQuotient(_ A: DMatrix<R>, _ B: DMatrix<R>, _ T: DMatrix<R>) -> (factors: [R], generatingMatrix: DMatrix<R>, transitionMatrix: DMatrix<R>) {
        assert(A.size.rows == B.size.rows) // n
        assert(A.size.cols == T.size.rows) // k
        assert(A.size.rows >= A.size.cols) // n >= k
        assert(A.size.cols >= B.size.cols) // k >= l
        
        let (k, l) = (A.size.cols, B.size.cols)
        let elim = (T * B).eliminate(form: .Smith)
        let d = elim.result.diagonal.exclude{ $0.isInvertible } + [.zero].repeated(k - l)
        let s = d.count
        
        let P    = elim.left       .submatrix(rowRange: (k - s) ..< k)
        let Pinv = elim.leftInverse.submatrix(colRange: (k - s) ..< k)
        let (A2, T2) = (A * Pinv, P * T)
        
        assert(T2 * A2 == DMatrix<R>.identity(size: s))
        
        return (d, A2, T2)
    }
}

extension Homology where GridDim == _1 {
    public func printSequence() {
        grid.printSequence()
    }
    
    public func printSequence(_ range: ClosedRange<Int>) {
        grid.printSequence(range)
    }
}

extension Homology where GridDim == _2 {
    public func printTable() {
        grid.printTable()
    }
    
    public func printTable(_ range1: ClosedRange<Int>, _ range2: ClosedRange<Int>) {
        grid.printTable(range1, range2)
    }
}

extension ChainComplex where R: EuclideanRing {
    public var homology: Homology<GridDim, BaseModule> {
        return Homology(self)
    }

    public func cycleSubmodule(_ I: GridCoords) -> ModuleObject<BaseModule> {
        assert(isFreeToFree(at: I))
        let (Z, T) = (cycleMatrix(I), cycleTransitionMatrix(I))
        
        let C_I = self[I]
        let gens = C_I.generators * Z
        let factr = { z in T * C_I.factorize(z) }
        
        return ModuleObject(basis: gens, factorizer: factr)
    }
    
    public func boundarySubmodule(_ I: GridCoords) -> ModuleObject<BaseModule> {
        assert(isFreeToFree(at: I))
        let J = I.shifted(-d.multiDegree)
        let (B, T) = (boundaryMatrix(J), boundaryTransitionMatrix(J))
        
        let C_I = self[I]
        let gens = C_I.generators * B
        let diag = dElim(J).result.diagonal
        let factr = { (b: BaseModule) -> DVector<R> in
            let v = T * C_I.factorize(b)
            let divided = v.map { (i, _, a) -> MatrixComponent<R> in (i, 0, a / diag[i]) }
            return DVector(size: v.size, components: divided, zerosExcluded: true)
        }
        return ModuleObject(basis: gens, factorizer: factr)
    }
    
    public func boundaryInverse(of b: BaseModule, at I: GridCoords) -> BaseModule? {
        assert(isFreeToFree(at: I))
        let J = I.shifted(-d.multiDegree)
        if let v = dElim(J).invert(self[I].factorize(b)) {
            return (self[J].generators * v)[0]
        } else {
            return nil
        }
    }
    
    internal func cycleMatrix(_ I: GridCoords) -> DMatrix<R> {
        return dElim(I).kernelMatrix
    }
    
    internal func cycleTransitionMatrix(_ I: GridCoords) -> DMatrix<R> {
        return dElim(I).kernelTransitionMatrix
    }
    
    internal func boundaryMatrix(_ I: GridCoords) -> DMatrix<R> {
        return dElim(I).imageMatrix
    }
    
    internal func boundaryTransitionMatrix(_ I: GridCoords) -> DMatrix<R> {
        return dElim(I).imageTransitionMatrix
    }
    
    private func dElim(_ I: GridCoords) -> MatrixEliminationResult<DynamicSize, DynamicSize, R> {
        return elimCache.useCacheOrSet(key: I) {
            assert(isFreeToFree(at: I))
            return differentialMatrix(at: I).eliminate(form: .Diagonal)
        } as! MatrixEliminationResult<DynamicSize, DynamicSize, R>
    }
}

extension ChainComplex where R: EuclideanRing, GridDim == _1 {
    public func cycleSubmodule(_ i: Int) -> ModuleObject<BaseModule> {
        return cycleSubmodule([i])
    }
    
    public func boundarySubmodule(_ i: Int) -> ModuleObject<BaseModule> {
        return boundarySubmodule([i])
    }
}
