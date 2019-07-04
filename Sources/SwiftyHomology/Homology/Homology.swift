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
        
        let elimCache: CacheDictionary<GridCoords, E> = CacheDictionary.empty
        func elim(_ I: GridCoords) -> E {
            assert(chainComplex.isFreeToFree(at: I))
            return elimCache.useCacheOrSet(key: I) {
                chainComplex.differntialMatrix(at: I).eliminate(form: .Diagonal)
            }
        }
        
        let grid = ModuleGrid<GridDim, BaseModule> { I in
            let C = chainComplex
            
            let generators = C[I].generators
            let Z = elim(I).kernelMatrix
            let T = elim(I).kernelTransitionMatrix
            let B = elim(I.shifted(-C.differential.multiDegree)).imageMatrix
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
    public func printSequence(indices: [Int]) {
        grid.printSequence(indices: indices)
    }
    
    public func printSequence(range: ClosedRange<Int>) {
        grid.printSequence(range: range)
    }
}

extension Homology where GridDim == _2 {
    public func printTable(indices1: [Int], indices2: [Int]) {
        grid.printTable(indices1: indices1, indices2: indices2)
    }
    
    public func printTable(range1: ClosedRange<Int>, range2: ClosedRange<Int>) {
        grid.printTable(range1: range1, range2: range2)
    }
}

extension ChainComplex where R: EuclideanRing {
    public var homology: Homology<GridDim, BaseModule> {
        return Homology(self)
    }
}
