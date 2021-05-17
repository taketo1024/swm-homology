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

public class HomologyCalculator<GridDim: StaticSizeType, BaseModule: Module, _MatrixImpl: MatrixImpl>
    where BaseModule.BaseRing == _MatrixImpl.BaseRing {
    
    public typealias Homology = ModuleGrid<GridDim, BaseModule>
    public typealias Matrix = MatrixIF<_MatrixImpl, DynamicSize, DynamicSize>
    public typealias BaseRing = BaseModule.BaseRing

    typealias Coords = GridCoords<GridDim>

    public let chainComplex: ChainComplex<GridDim, BaseModule>
    public let options: HomologyCalculatorOptions
    internal let matrixCache: CacheDictionary<Coords, Matrix> = .empty

    public init(chainComplex: ChainComplex<GridDim, BaseModule>, options: HomologyCalculatorOptions) {
        self.chainComplex = chainComplex
        self.options = options
    }
    
    internal func matrix(at I: Coords) -> Matrix {
        matrixCache.useCacheOrSet(key: I) {
            let (C, d) = (chainComplex, chainComplex.differential)
            let (C0, C1) = (C[I], C[I + d.multiDegree])
            return d[I].asMatrix(from: C0, to: C1, implType: _MatrixImpl.self)
        }
    }
    
    public func calculate() -> Homology {
        fatalError("Use concrete subclasses.")
    }
}
