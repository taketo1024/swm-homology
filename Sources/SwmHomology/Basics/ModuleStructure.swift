//
//  ModuleObject.swift
//  Sample
//
//  Created by Taketo Sano on 2018/06/02.
//

import SwmCore

// A decomposed form of a freely & finitely presented module,
// i.e. a module with finite generators and a finite & free presentation.
//
//   M = (R/d_0 ⊕ ... ⊕ R/d_k) ⊕ R^r  ( d_i: torsion-coeffs, r: rank )
//
// See: https://en.wikipedia.org/wiki/Free_presentation
//      https://en.wikipedia.org/wiki/Structure_theorem_for_finitely_generated_modules_over_a_principal_ideal_domain#Invariant_factor_decomposition

public struct ModuleStructure<BaseModule: Module>: Equatable, CustomStringConvertible {
    public typealias R = BaseModule.BaseRing
    public typealias Vectorizer = (BaseModule) -> AnySizeVector<R>

    public let summands: [Summand]
    internal let vectorizer: Vectorizer
    
    internal init(summands: [Summand], vectorizer: @escaping Vectorizer) {
        self.summands = summands
        self.vectorizer = vectorizer
    }
    
    public init(generators: [BaseModule], vectorizer: @escaping Vectorizer) {
        let summands = generators.map{ z in Summand(z) }
        self.init(summands: summands, vectorizer: vectorizer)
    }
    
    public init(generators: [BaseModule], divisors: [R], vectorizer: @escaping Vectorizer) {
        assert(generators.count == divisors.count)
        let summands = zip(generators, divisors).map{ (z, r) in Summand(z, r) }
        self.init(summands: summands, vectorizer: vectorizer)
    }

    public subscript(i: Int) -> Summand {
        summands[i]
    }
    
    public func vectorize(_ z: BaseModule) -> AnySizeVector<R> {
        vectorizer(z)
    }
    
    public static var zeroModule: Self {
        .init(summands: [], vectorizer: { _ in .zero(size: 0) } )
    }
    
    public var isZero: Bool {
        summands.isEmpty
    }
    
    public var isFree: Bool {
        summands.allSatisfy { $0.isFree }
    }
    
    public var rank: Int {
        summands.filter{ $0.isFree }.count
    }
    
    public var generators: [BaseModule] {
        summands.map{ $0.generator }
    }
    
    public func generator(_ i: Int) -> BaseModule {
        summands[i].generator
    }
    
    public func filter(_ predicate: @escaping (Summand) -> Bool) -> ModuleStructure {
        let (reduced, table) = summands
            .enumerated()
            .reduce(into: ([], [:])) {
                (res: inout (summands: [Summand], table: [Int : Int]), next) in
                
                let (i, z) = next
                if predicate(z) {
                    let j = res.0.count
                    res.summands.append(z)
                    res.table[i] = j
                }
            }
        
        let N = reduced.count
        let vectorizer = { (z: BaseModule) -> AnySizeVector<R> in
            let vec = vectorize(z)
            return .init(size: N) { setEntry in
                vec.nonZeroColEntries.forEach { (i, r) in
                    if let j = table[i]  {
                        setEntry(j, r)
                    }
                }
            }
        }
        return ModuleStructure(summands: reduced, vectorizer: vectorizer)
    }

    
    public static func ==(a: ModuleStructure<BaseModule>, b: ModuleStructure<BaseModule>) -> Bool {
        a.summands == b.summands
    }
    
    public var description: String {
        if summands.isEmpty {
            return "0"
        }
        
        let group = summands.group{ "\($0.divisor)" }
        return group.keys.sorted().map { key in
            let list = group[key]!
            return list.first!.description + (list.count > 1 ? Format.sup(list.count) : "")
        }.joined(separator: "⊕")
    }
    
    public func printDetail() {
        print("\(self) {")
        for s in summands {
            print("\t\(s): \(s.generator)")
        }
        print("}")
    }
    
    public struct Summand: Equatable, CustomStringConvertible {
        public let generator: BaseModule
        public let divisor: R
        
        public init(_ generator: BaseModule, _ divisor: R = .zero) {
            self.generator = generator
            self.divisor = divisor
        }
        
        public var isFree: Bool {
            divisor == .zero
        }
        
        public var description: String {
            switch (isFree, R.self == 𝐙.self) {
            case (true, _)    : return R.symbol
            case (false, true): return "𝐙\(Format.sub("\(divisor)"))"
            default           : return "\(R.symbol)/\(divisor)"
            }
        }
    }
}

extension ModuleStructure where BaseModule: LinearCombinationType {
    public init(rawGenerators: [BaseModule.Generator]) {
        let indexer = rawGenerators.makeIndexer()
        self.init(
            generators: rawGenerators.map{ x in .init(x) },
            vectorizer: { z in
                AnySizeVector(size: rawGenerators.count) { setEntry in
                    z.elements.forEach { (a, r) in
                        if let i = indexer(a) {
                            setEntry(i, r)
                        }
                    }
                }
            }
        )
    }
}

extension ModuleStructure {
    public var dual: ModuleStructure<DualModule<BaseModule>> {
        assert(isFree)
        
        typealias DualObject = ModuleStructure<DualModule<BaseModule>>
        let summands = self.generators.enumerated().map { (i, _) in
            DualModule<BaseModule> { z in
                .init(self.vectorize(z)[i])
            }
        }.map{ DualObject.Summand($0) }
        
        let vectorizer = { (f: DualModule<BaseModule>) -> AnySizeVector<R> in
            AnySizeVector(size: self.generators.count) { setEntry in
                self.generators.enumerated().forEach { (i, z) in
                    let a = f(z).value
                    if !a.isZero {
                        setEntry(i, a)
                    }
                }
            }
        }
        return ModuleStructure<DualModule<BaseModule>>(summands: summands, vectorizer: vectorizer)
    }
}

extension ModuleStructure where R: Hashable {
    public var dictionaryDescription: [R : Int] {
        summands.group{ $0.divisor }.mapValues{ $0.count }
    }
}
