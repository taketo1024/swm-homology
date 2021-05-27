//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/07.
//

import SwmCore

// {M}_I: the direct sum of copies of M over I.
public struct GradedModule<Index: Hashable, BaseModule: Module>: Module {
    public typealias BaseRing = BaseModule.BaseRing
    public let elements: [Index: BaseModule]
    
    public init(elements: [Index: BaseModule]) {
        self.elements = elements.exclude{ $0.value.isZero }
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

extension ModuleStructure {
    public static func formDirectSum<Index: Hashable>(_ objects: [Index : Self]) -> ModuleStructure<GradedModule<Index, BaseModule>> {
        typealias S = ModuleStructure<GradedModule<Index, BaseModule>>
        
        let indices = objects.keys.toArray()
        let ranks = [0] + indices.map { objects[$0]!.rank }.accumulate()
        let shifts = Dictionary(zip(indices, ranks))
        
        let generators = indices.flatMap { index -> [GradedModule<Index, BaseModule>] in
            objects[index]!.generators.map { x in GradedModule(index: index, value: x) }
        }
        
        let N = ranks.last ?? 0
        let vectorizer: S.Vectorizer = { z in
            let entries = z.elements.reduce(
                into: [ColEntry<R>]?.some([]),
                while: { (res, _) in res != nil }
            ) { (res, elem) in
                let (index, x) = elem
                let (obj, shift) = (objects[index]!, shifts[index]!)
                
                if let v = obj.vectorize(x) {
                    res! += v.nonZeroColEntries.map{ (i, a) in (i + shift, a) }
                } else {
                    res = nil
                }
            }
            if let entries = entries {
                return .init(size: N, colEntries: entries)
            } else {
                return nil
            }
        }
        
        return ModuleStructure<GradedModule<Index, BaseModule>>(generators: generators, vectorizer: vectorizer)
    }
}
