//
//  HomologyCalculatable.swift
//  
//
//  Created by Taketo Sano on 2021/06/05.
//

import SwmCore
import SwmMatrixTools

public protocol HomologyCalculatable: Ring {
    static func homologyCalculator<C>(forChainComplex chainComplex: C, options: HomologyCalculatorOptions) -> HomologyCalculator<C>
    where C.BaseRing == Self
    static func defaultHomologyCalculator<C>(forChainComplex chainComplex: C, options: HomologyCalculatorOptions) -> HomologyCalculator<C>
    where C: ChainComplexType, C.BaseRing == Self
}

extension HomologyCalculatable {
    public static func homologyCalculator<C>(forChainComplex chainComplex: C, options: HomologyCalculatorOptions) -> HomologyCalculator<C>
    where C.BaseRing == Self {
        defaultHomologyCalculator(forChainComplex: chainComplex, options: options)
    }
}

extension ChainComplexType where BaseRing: HomologyCalculatable {
    public func homology(options: HomologyCalculatorOptions = []) -> IndexedModuleStructure<Index, BaseModule> {
        let calculator = BaseRing.homologyCalculator(forChainComplex: self, options: options)
        return calculator.calculate()
    }
}

extension ComputationalRing where Self: EuclideanRing {
    public static func defaultHomologyCalculator<C>(forChainComplex chainComplex: C, options: HomologyCalculatorOptions) -> HomologyCalculator<C>
    where C.BaseRing == Self {
        HNFHomologyCalculator<C, DefaultSparseMatrixImpl<Self>>(chainComplex: chainComplex, options: options)
    }
}

extension ComputationalRing where Self: Field {
    public static func defaultHomologyCalculator<C>(forChainComplex chainComplex: C, options: HomologyCalculatorOptions) -> HomologyCalculator<C>
    where C.BaseRing == Self {
        LUHomologyCalculator<C, DefaultSparseMatrixImpl<Self>>(chainComplex: chainComplex, options: options)
    }
}
