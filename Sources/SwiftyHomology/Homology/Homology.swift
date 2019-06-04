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
    
    public init(name aName: String? = nil, _ chainComplex: ChainComplex<GridDim, BaseModule>) {
        let name = aName ?? "H(\(chainComplex.name))"
        let grid = ModuleGrid<GridDim, BaseModule>(name: name) { I in
            let C = chainComplex
            let generators = C[I].generators
            
            let Z = C.dKernel(I)
            let T = C.dKernelTransition(I)
            let B = C.dImage(I - C.differential.multiDegree)
            
            let (Q, d, S) = Homology.calculateQuotient(Z, B, T)
            
            let hGenerators = (0 ..< Q.cols).map { j in
                Q.nonZeroComponents(ofCol: j).sum{ c in
                    c.value * generators[c.row]
                }
            }
            
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
    
    public var gridDim: Int {
        return GridDim.intValue
    }
    
    public var name: String {
        return grid.name
    }
    
    public func describe(_ I: IntList) {
        grid.describe(I)
    }
    
    public var description: String {
        return grid.description
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
        
        let elim = (T * B).elimination(form: .Smith)
        let D = elim.diagonal + [.zero].repeated(k - l)
        let s = D.count{ !$0.isInvertible }
        
        let A2 = A * elim.leftInverse.submatrix(colRange: (k - s) ..< k)
        let diag = Array(D[k - s ..< k])
        let T2 = (elim.left * T).submatrix(rowRange: (k - s) ..< k)
        
        assert(T2 * A2 == DMatrix<R>.identity(size: s))
        return (A2, diag, T2)
    }
}

extension Homology where GridDim == _1 {
    public subscript(i: Int) -> ModuleObject<BaseModule> {
        return grid[i]
    }
    
    public func describe(_ i: Int) {
        describe(IntList(i))
    }
}

extension Homology where GridDim == _2 {
    public subscript(i: Int, j: Int) -> ModuleObject<BaseModule> {
        return grid[i, j]
    }
    
    public func describe(_ i: Int, _ j: Int) {
        describe(IntList(i, j))
    }
}


extension ChainComplex where R: EuclideanRing {
    internal func dKernel(_ I: IntList) -> DMatrix<R> {
        assert(isFreeToFree(I))
        
        let E = differntialMatrix(I).elimination(form: .Diagonal)
        return E.kernelMatrix
    }
    
    internal func dKernelTransition(_ I: IntList) -> DMatrix<R> {
        assert(isFreeToFree(I))
        
        let E = differntialMatrix(I).elimination(form: .Diagonal)
        return E.kernelTransitionMatrix
    }
    
    internal func dImage(_ I: IntList) -> DMatrix<R> {
        assert(isFreeToFree(I))
        
        let E = differntialMatrix(I).elimination(form: .Diagonal)
        return E.imageMatrix
    }
    
    internal func dImageTransition(_ I: IntList) -> DMatrix<R>? {
        assert(isFreeToFree(I))
        
        let E = differntialMatrix(I).elimination(form: .Diagonal)
        return E.imageTransitionMatrix
    }
    
    public var homology: Homology<GridDim, BaseModule> {
        return Homology(self)
    }
}
