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

public class HomologyCalculator<C> where C: ChainComplexType {
    public typealias Homology = IndexedModuleStructure<C.Index, C.BaseModule>

    typealias Index = C.Index
    typealias BaseModule = C.BaseModule
    typealias BaseRing = C.BaseRing
    
    public let chainComplex: C
    public let options: HomologyCalculatorOptions

    public required init(chainComplex: C, options: HomologyCalculatorOptions) {
        self.chainComplex = chainComplex
        self.options = options
    }
    
    public final func calculate() -> Homology {
        Homology(
            support: chainComplex.support,
            grid: { i in
                self.calculate(i)
            }
        )
    }
    
    internal func calculate(_ i: Index) -> Homology.Object {
        fatalError("Use concrete subclasses.")
    }
}
