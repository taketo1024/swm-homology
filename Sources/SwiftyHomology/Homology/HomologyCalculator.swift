//
//  Homology.swift
//  Sample
//
//  Created by Taketo Sano on 2018/06/02.
//

import SwiftyMath

public struct HomologyCalculatorOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    public static let withGenerators = Self(rawValue: 1 << 0)
    public static let withVectorizer = Self(rawValue: 1 << 1)
}

public class HomologyCalculator<C: ChainComplexType, _MatrixImpl: MatrixImpl>
where C.BaseModule.BaseRing == _MatrixImpl.BaseRing {
    
    public typealias Homology = ModuleGrid<C.Index, C.BaseModule>

    typealias Index = C.Index
    typealias BaseModule = C.BaseModule
    typealias BaseRing = BaseModule.BaseRing
    typealias Matrix = MatrixIF<_MatrixImpl, anySize, anySize>
    
    public let chainComplex: C
    public let options: HomologyCalculatorOptions
    internal let matrixCache: Cache<Index, Matrix> = .empty

    public init(chainComplex: C, options: HomologyCalculatorOptions) {
        self.chainComplex = chainComplex
        self.options = options
    }
    
    internal func matrix(at i: Index) -> Matrix {
        matrixCache.getOrSet(key: i) {
            let (C, d) = (chainComplex, chainComplex.differential)
            let (C0, C1) = (C[i], C[i + d.degree])
            return d[i].asMatrix(from: C0, to: C1, implType: _MatrixImpl.self)
        }
    }
    
    public func calculate() -> Homology {
        fatalError("Use concrete subclasses.")
    }
}
