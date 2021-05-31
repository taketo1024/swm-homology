//
//  Homology.swift
//  Sample
//
//  Created by Taketo Sano on 2018/06/02.
//

import SwmCore

public struct HomologyCalculatorOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    public static let onlyStructures = Self(rawValue: 1 << 0)
}

public class HomologyCalculator<C: ChainComplexType> {
    public typealias Homology = GradedModuleStructure<C.Index, C.BaseModule>

    typealias Index = C.Index
    typealias BaseModule = C.BaseModule
    typealias BaseRing = BaseModule.BaseRing
    
    public let chainComplex: C
    public let options: HomologyCalculatorOptions

    public required init(chainComplex: C, options: HomologyCalculatorOptions) {
        self.chainComplex = chainComplex
        self.options = options
    }
    
    public final func calculate() -> Homology {
        .init { i in
            self.calculate(i)
        }
    }
    
    internal func calculate(_ i: Index) -> Homology.Object {
        fatalError("Use concrete subclasses.")
    }
}

extension ChainComplexType where BaseModule.BaseRing: EuclideanRing {
    public func homology(options: HomologyCalculatorOptions = []) -> GradedModuleStructure<Index, BaseModule> {
        homology(options: options, using: HNFHomologyCalculator<Self>.self)
    }

    public func homology(options: HomologyCalculatorOptions = [], using type: HomologyCalculator<Self>.Type) -> GradedModuleStructure<Index, BaseModule> {
        type.init(chainComplex: self, options: options).calculate()
    }
}
