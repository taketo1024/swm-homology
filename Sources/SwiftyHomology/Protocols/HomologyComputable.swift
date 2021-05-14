//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwiftyMath

public protocol HomologyComputable: Ring {
    associatedtype HomologyComputingMatrixImpl: MatrixImpl
    static func computeHomology<GridDim, BaseModule>(chainComplex: ChainComplex<GridDim, BaseModule>, options: HomologyCalculatorOptions) -> ModuleGrid<GridDim, BaseModule> where BaseModule.BaseRing == Self
}

extension ChainComplex where BaseModule.BaseRing: HomologyComputable {
    public func homology(options: HomologyCalculatorOptions = []) -> ModuleGrid<GridDim, BaseModule> {
        BaseModule.BaseRing.computeHomology(chainComplex: self, options: options)
    }
}
