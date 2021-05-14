//
//  LUDecomposable.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwiftyMath
import SwiftyEigen

public protocol SNFComputable: HomologyComputable, EuclideanRing where HomologyComputingMatrixImpl.BaseRing == Self {}

extension SNFComputable {
    public static func computeHomology<GridDim, BaseModule>(chainComplex: ChainComplex<GridDim, BaseModule>, options: HomologyCalculatorOptions) -> ModuleGrid<GridDim, BaseModule> where BaseModule.BaseRing == Self {
        let H = HomologyCalculator<GridDim, BaseModule>(chainComplex: chainComplex, options: options)
        return H.calculateBySNF(usingMatrixImpl: HomologyComputingMatrixImpl.self)
    }
}

extension Int: SNFComputable {
    public typealias HomologyComputingMatrixImpl = DefaultMatrixImpl<Int>
}

extension RationalNumber: SNFComputable {
    public typealias HomologyComputingMatrixImpl = DefaultMatrixImpl<RationalNumber>
}

extension 𝐅₂: SNFComputable {
    public typealias HomologyComputingMatrixImpl = DefaultMatrixImpl<𝐅₂>
}
