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

public final class HomologyCalculator<GridDim: StaticSizeType, BaseModule: Module> {
    typealias Coords = GridCoords<GridDim>
    typealias BaseRing = BaseModule.BaseRing
    
    public let chainComplex: ChainComplex<GridDim, BaseModule>
    public let options: HomologyCalculatorOptions
    
    public init(chainComplex: ChainComplex<GridDim, BaseModule>, options: HomologyCalculatorOptions) {
        self.chainComplex = chainComplex
        self.options = options
    }
    
    internal func matrix<Impl: MatrixImpl>(at I: Coords, matrixType: MatrixInterface<Impl, DynamicSize, DynamicSize>.Type) -> MatrixInterface<Impl, DynamicSize, DynamicSize> where Impl.BaseRing == BaseRing {
        let (C, d) = (chainComplex, chainComplex.differential)
        let (C0, C1) = (C[I], C[I + d.multiDegree])
        return d[I].asMatrix(from: C0, to: C1, matrixType: matrixType)
    }
}
