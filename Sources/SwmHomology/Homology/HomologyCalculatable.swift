//
//  HomologyCalculatable.swift
//  
//
//  Created by Taketo Sano on 2021/06/05.
//

import SwmCore
import SwmMatrixTools

public protocol HomologyCalculatable: Ring {
    static func homologyCalculator<C>(forChainComplexType: C.Type, options: HomologyCalculatorOptions) -> HomologyCalculator<C>.Type
    where C: ChainComplexType, C.BaseRing == Self
}

extension HomologyCalculatable where Self: EuclideanRing & ComputationalRing {
    public static func homologyCalculator<C>(forChainComplexType: C.Type, options: HomologyCalculatorOptions) -> HomologyCalculator<C>.Type
    where C : ChainComplexType, C.BaseRing == Self {
        typealias T = HNFHomologyCalculator<C, ComputationalSparseMatrixImpl>
        return T.self
    }
}

extension HomologyCalculatable where Self: Field & ComputationalRing, ComputationalSparseMatrixImpl: LUFactorizable {
    public static func homologyCalculator<C>(forChainComplexType: C.Type, options: HomologyCalculatorOptions) -> HomologyCalculator<C>.Type
    where C : ChainComplexType, C.BaseRing == Self {
        typealias T = LUHomologyCalculator<C, ComputationalSparseMatrixImpl>
        return T.self
    }
}


extension Int: HomologyCalculatable {}
extension RationalNumber: HomologyCalculatable {}
extension RealNumber: HomologyCalculatable {}
extension 𝐅₂: HomologyCalculatable {}
extension Polynomial: HomologyCalculatable where BaseRing: Field & ComputationalRing {}
