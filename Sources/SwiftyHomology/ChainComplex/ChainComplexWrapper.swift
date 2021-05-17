//
//  ChainComplexWrapper.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/10/25.
//

import SwiftyMath

public protocol ChainComplexWrapper: GridType {
    associatedtype BaseModule: Module
    var chainComplex: ChainComplex<GridDim, BaseModule> { get }
}

extension ChainComplexWrapper {
    public typealias Element = BaseModule
    public typealias Differential = ChainComplex<GridDim, BaseModule>.Differential
    
    public subscript(I: Coords) -> ModuleObject<BaseModule> {
        chainComplex[I]
    }
    
    public var support: ClosedRange<Coords>? {
        chainComplex.support
    }
    
    public var differential: Differential {
        chainComplex.differential
    }
    
    public func assertChainComplex(debug: Bool = false) {
        chainComplex.assertChainComplex(debug: debug)
    }
    
    public func assertChainComplex(at I0: Coords, debug: Bool = false) {
        chainComplex.assertChainComplex(at: I0, debug: debug)
    }
}

extension ChainComplexWrapper where GridDim == _1 {
    public func assertChainComplex(at i: Int, debug: Bool = false) {
        chainComplex.assertChainComplex(at: i, debug: debug)
    }
}

extension ChainComplexWrapper where BaseModule.BaseRing: EuclideanRing {
    public func homology(options: HomologyCalculatorOptions = []) -> ModuleGrid<GridDim, BaseModule> {
        chainComplex.homology(options: options)
    }
}
