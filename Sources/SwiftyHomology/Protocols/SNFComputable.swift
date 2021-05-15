//
//  LUDecomposable.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwiftyMath
import SwiftyEigen

public protocol SNFComputable: HomologyComputable where Self: EuclideanRing, HomologyComputingMatrixImpl.BaseRing == Self {}

extension SNFComputable {
    public static func computeHomology<GridDim, BaseModule>(chainComplex: ChainComplex<GridDim, BaseModule>, options: HomologyCalculatorOptions) -> ModuleGrid<GridDim, BaseModule> where BaseModule.BaseRing == Self {
        typealias H = HomologyCalculator<GridDim, BaseModule, HomologyComputingMatrixImpl>
        let h = H(chainComplex: chainComplex, options: options)
        return h.calculateBySNF()
    }
}

extension Int: SNFComputable {
    public typealias HomologyComputingMatrixImpl = DefaultMatrixImpl<Int>
}
