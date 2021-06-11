//
//  HomologyCalculatable.swift
//  
//
//  Created by Taketo Sano on 2021/06/05.
//

import SwmCore
import SwmMatrixTools

public protocol HomologyCalculatable: ComputationalRing {
    static func homologyCalculator<C>(forChainComplexType: C.Type, options: HomologyCalculatorOptions) -> HomologyCalculator<C>.Type
    where C: ChainComplexType, C.BaseRing == Self
}

extension HomologyCalculatable where Self: EuclideanRing {
    public static func homologyCalculator<C>(forChainComplexType: C.Type, options: HomologyCalculatorOptions) -> HomologyCalculator<C>.Type
    where C : ChainComplexType, C.BaseRing == Self {
        typealias T = HNFHomologyCalculator<C, ComputationalSparseMatrix>
        return T.self
    }
}

extension HomologyCalculatable where Self: Field, ComputationalSparseMatrix: LUFactorizable {
    public static func homologyCalculator<C>(forChainComplexType: C.Type, options: HomologyCalculatorOptions) -> HomologyCalculator<C>.Type
    where C : ChainComplexType, C.BaseRing == Self {
        typealias T = LUHomologyCalculator<C, ComputationalSparseMatrix>
        return T.self
    }
}


extension Int: HomologyCalculatable {}
extension RationalNumber: HomologyCalculatable {}
extension RealNumber: HomologyCalculatable {}
extension 𝐅₂: HomologyCalculatable {}
extension Polynomial: HomologyCalculatable where BaseRing: Field {}
