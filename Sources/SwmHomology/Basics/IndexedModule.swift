//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/07.
//

import SwmCore

// {M}_I: the direct sum of copies of M over I.
public struct IndexedModule<Index: Hashable, _BaseModule: Module>: Module {
    public typealias BaseModule = _BaseModule
    public typealias BaseRing = BaseModule.BaseRing
    public let elements: [Index: BaseModule]
    
    public init(elements: [Index: BaseModule]) {
        self.elements = elements
    }
    
    public init<S>(elements: S)
    where S: Sequence, S.Element == (Index, BaseModule)
    {
        self.init(elements: Dictionary(elements, uniquingKeysWith: +))
    }
    
    public init(index: Index, value: BaseModule) {
        self.init(elements: [index : value])
    }
    
    public var reduced: Self {
        .init(elements: elements.exclude{(_, z) in z.isZero } )
    }
    
    public static var zero: Self {
        self.init(elements: [:])
    }
    
    public var isZero: Bool {
        elements.values.allSatisfy{ $0.isZero } 
    }
    
    public static func + (a: Self, b: Self) -> Self {
        Self(elements: a.elements.merging(b.elements, uniquingKeysWith: +))
    }
    
    public static prefix func - (x: Self) -> Self {
        Self(elements: x.elements.mapValues{ -$0 })
    }
    
    public static func * (r: BaseRing, m: Self) -> Self {
        Self(elements: m.elements.mapValues{ r * $0 })
    }
    
    public static func * (m: Self, r: BaseRing) -> Self {
        Self(elements: m.elements.mapValues{ $0 * r })
    }
    
    public func map(_ f: (Index, BaseModule) -> (Index, BaseModule)) -> Self {
        .init(elements: elements.map(f))
    }
    
    public func mapValues(_ f: (BaseModule) -> BaseModule) -> Self {
        .init(elements: elements.mapValues { z in f(z) } )
    }
    
    public func filter(_ f: (Index, BaseModule) -> Bool) -> Self {
        .init(elements: elements.filter(f))
    }
    
    public static func sum<S>(_ elements: S) -> IndexedModule<Index, BaseModule>
    where IndexedModule<Index, BaseModule> == S.Element, S : Sequence
    {
        .init(elements: elements.flatMap{ $0.elements })
    }
    
    public var description: String {
        elements.isEmpty ?
            "0" :
            elements.map { (index, x) in
                "{\(index): \(x)}"
            }.joined(separator: " + ")
    }
}

extension IndexedModule where BaseModule: LinearCombinationType {
    public var terms: [(Index, BaseModule)] {
        elements.flatMap { (index, z) in
            !z.isZero
                ? z.terms.map{ (index, $0) }
                : []
        }
    }

    public func filterTerms(_ f: (Index, BaseModule) -> Bool) -> Self {
        .init(elements: elements.map { (index, z) in
            (index, z.terms.filter{ f(index, $0) }.sum())
        })
    }
    
    public func mapTerms(_ f: (Index, BaseModule) -> (Index, BaseModule)) -> Self {
        .init(elements: elements.flatMap { (index, z) in
            z.terms.map { term in f(index, term) }
        })
    }
}
