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
        let H = HomologyCalculator<GridDim, BaseModule>(chainComplex: chainComplex, options: options)
        return H.calculateByLU(usingMatrixImpl: HomologyComputingMatrixImpl.self)
    }
}

//extension RationalNumber: LUDecomposable {
//    public typealias HomologyComputingMatrixImpl = EigenRationalMatrix
//}
