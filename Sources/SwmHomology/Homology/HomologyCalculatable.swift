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

extension EuclideanRing where Self: HomologyCalculatable {
    public static func HNFHomologyCalculator<C>(forChainComplexType: C.Type, options: HomologyCalculatorOptions) -> HomologyCalculator<C>.Type
    where C: ChainComplexType, C.BaseRing == Self {
        typealias T = HNFHomologyCalculator<C, DefaultMatrixImpl<Self>>
        return T.self
    }
}

extension Field where Self: HomologyCalculatable {
    public static func LUHomologyCalculator<C>(forChainComplexType: C.Type, options: HomologyCalculatorOptions) -> HomologyCalculator<C>.Type
    where C: ChainComplexType, C.BaseRing == Self {
        typealias T = LUHomologyCalculator<C, CSCMatrixImpl<Self>>
        return T.self
    }
}

extension Int: HomologyCalculatable {
    public static func homologyCalculator<C>(forChainComplexType: C.Type, options: HomologyCalculatorOptions) -> HomologyCalculator<C>.Type
    where C : ChainComplexType, C.BaseRing == Self {
        HNFHomologyCalculator(forChainComplexType: C.self, options: options)
    }
}

extension RationalNumber: HomologyCalculatable {
    public static func homologyCalculator<C>(forChainComplexType: C.Type, options: HomologyCalculatorOptions) -> HomologyCalculator<C>.Type
    where C : ChainComplexType, C.BaseRing == Self {
        LUHomologyCalculator(forChainComplexType: C.self, options: options)
    }
}

extension RealNumber: HomologyCalculatable {
    public static func homologyCalculator<C>(forChainComplexType: C.Type, options: HomologyCalculatorOptions) -> HomologyCalculator<C>.Type
    where C : ChainComplexType, C.BaseRing == Self {
        LUHomologyCalculator(forChainComplexType: C.self, options: options)
    }
}

extension 𝐅₂: HomologyCalculatable {
    public static func homologyCalculator<C>(forChainComplexType: C.Type, options: HomologyCalculatorOptions) -> HomologyCalculator<C>.Type
    where C : ChainComplexType, C.BaseRing == Self {
        LUHomologyCalculator(forChainComplexType: C.self, options: options)
    }
}

extension Polynomial: HomologyCalculatable where BaseRing: Field {
    public static func homologyCalculator<C>(forChainComplexType: C.Type, options: HomologyCalculatorOptions) -> HomologyCalculator<C>.Type
    where C : ChainComplexType, C.BaseRing == Self {
        HNFHomologyCalculator(forChainComplexType: C.self, options: options)
    }
}
