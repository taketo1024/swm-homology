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

public class HomologyCalculator<Index: AdditiveGroup & Hashable, BaseModule: Module, _MatrixImpl: MatrixImpl>
    where BaseModule.BaseRing == _MatrixImpl.BaseRing {
    
    public typealias Homology = ModuleGrid<Index, BaseModule>

    typealias BaseRing = BaseModule.BaseRing
    typealias Matrix = MatrixIF<_MatrixImpl, DynamicSize, DynamicSize>
    

    public let chainComplex: ChainComplex<Index, BaseModule>
    public let options: HomologyCalculatorOptions
    internal let matrixCache: CacheDictionary<Index, Matrix> = .empty

    public init(chainComplex: ChainComplex<Index, BaseModule>, options: HomologyCalculatorOptions) {
        self.chainComplex = chainComplex
        self.options = options
    }
    
    internal func matrix(at i: Index) -> Matrix {
        matrixCache.useCacheOrSet(key: i) {
            let (C, d) = (chainComplex, chainComplex.differential)
            let (C0, C1) = (C[i], C[i + d.degree])
            return d[i].asMatrix(from: C0, to: C1, implType: _MatrixImpl.self)
        }
    }
    
    public func calculate() -> Homology {
        fatalError("Use concrete subclasses.")
    }
}
