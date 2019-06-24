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
        
        let elimCache: CacheDictionary<IntList, E> = CacheDictionary.empty
        func elim(_ I: IntList) -> E {
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
            let B = elim(I - C.differential.multiDegree).imageMatrix
            let (Q, d, S) = Homology.calculateQuotient(Z, B, T)
            
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
    
    public subscript(I: IntList) -> ModuleObject<BaseModule> {
        return grid[I]
    }
    
    public subscript(I: Int...) -> ModuleObject<BaseModule> {
        return self[IntList(I)]
    }
    
    public var gridDim: Int {
        return GridDim.intValue
    }
    
    /*
     *       R^n ==== R^n
     *        ^        ^|
     *       B|       A||T
     *        |   TB   |v
     *  0 -> R^l >---> R^k --->> Q -> 0
     *        ^        ^|
     *        |       P||
     *        |    D   |v
     *  0 -> R^l >---> R^k --->> Q -> 0
     *
     */
    internal static func calculateQuotient(_ A: DMatrix<R>, _ B: DMatrix<R>, _ T: DMatrix<R>) -> (DMatrix<R>, [R], DMatrix<R>) {
        assert(A.rows == B.rows) // n
        assert(A.cols == T.rows) // k
        assert(A.rows >= A.cols) // n >= k
        assert(A.cols >= B.cols) // k >= l
        
        let (k, l) = (A.cols, B.cols)
        
        // if k = 3, l = 2, D = [1, 2], then Q = 0 + Z/2 + Z.
        
        let elim = (T * B).eliminate(form: .Smith)
        let D = elim.result.diagonal + [.zero].repeated(k - l)
        let s = D.count{ !$0.isInvertible }
        
        let A2 = A * elim.leftInverse.submatrix(colRange: (k - s) ..< k)
        let diag = Array(D[k - s ..< k])
        let T2 = (elim.left * T).submatrix(rowRange: (k - s) ..< k)
        
        assert(T2 * A2 == DMatrix<R>.identity(size: s))
        return (A2, diag, T2)
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
