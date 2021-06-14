//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/07.
//

import SwmCore

// {M}_I: the direct sum of copies of M over I.
public struct GradedModule<Index: Hashable, _BaseModule: Module>: Module {
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
    
    public func filter(_ f: (Index, BaseModule) -> Bool) -> Self {
        .init(elements: elements.filter(f))
    }
    
    public static func sum<S>(_ elements: S) -> GradedModule<Index, BaseModule>
    where GradedModule<Index, BaseModule> == S.Element, S : Sequence
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

extension GradedModule where BaseModule: LinearCombinationType {
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

extension ModuleStructure {
    public static func formDirectSum<Index: Hashable>(indices: [Index], objects: [Self]) -> ModuleStructure<GradedModule<Index, BaseModule>> {
        typealias S = ModuleStructure<GradedModule<Index, BaseModule>>
        typealias R = BaseModule.BaseRing
        
        let indexer = indices.makeIndexer()
        
        let ranks = [0] + objects.map { $0.rank }.accumulate()
        let generators = zip(indices, objects).flatMap { (index, obj) -> [GradedModule<Index, BaseModule>] in
            obj.generators.map { x in GradedModule(index: index, value: x) }
        }
        
        let N = ranks.last ?? 0
        let vectorizer: S.Vectorizer = { z in
            var valid = true
            let vec = AnySizeVector<R>(size: N) { setEntry in
                for (index, x) in z.elements {
                    guard let i = indexer(index),
                          let v = objects[i].vectorize(x)
                    else {
                        valid = false
                        break
                    }
                    
                    let shift = ranks[i]
                    v.nonZeroColEntries.forEach { (i, a) in
                        setEntry(i + shift, a)
                    }
                }
            }
            return valid ? vec : nil
        }
        
        return S(
            generators: generators,
            vectorizer: vectorizer
        )
    }
}
