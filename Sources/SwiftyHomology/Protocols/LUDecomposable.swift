//
//  LUDecomposable.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwiftyMath
import SwiftyEigen

public protocol LUDecomposable: HomologyComputable where HomologyComputingMatrixImpl: MatrixImpl_LU, HomologyComputingMatrixImpl.BaseRing == Self {}

extension LUDecomposable {
    public static func computeHomology<GridDim, BaseModule>(chainComplex: ChainComplex<GridDim, BaseModule>, options: HomologyCalculatorOptions) -> ModuleGrid<GridDim, BaseModule> where BaseModule.BaseRing == Self {
        typealias H = HomologyCalculator<GridDim, BaseModule, HomologyComputingMatrixImpl>
        let h = H(chainComplex: chainComplex, options: options)
        return h.calculateByLU()
    }
}

extension RationalNumber: LUDecomposable {
    public typealias HomologyComputingMatrixImpl = EigenRationalMatrix
}
