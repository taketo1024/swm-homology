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
    public typealias Vectorizer = (BaseModule) -> AnySizeVector<R>?

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
    
    public func vectorize(_ z: BaseModule) -> AnySizeVector<R>? {
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
        let (reduced, table): ([Summand], [Int: Int]) =
            summands.enumerated()
            .reduce(
                into: ([Summand](), [Int : Int]())
            ) { (res, next) in
                let (i, z) = next
                if predicate(z) {
                    let j = res.0.count
                    res.0.append(z)
                    res.1[i] = j
                }
            }
        
        let N = reduced.count
        
        let vectorizer: Vectorizer = { z in
            guard let v = vectorize(z) else {
                return nil
            }
            let entries = v.nonZeroColEntries.reduce(
                into: [ColEntry<R>]?.some([]),
                while: { (res, _) in res != nil }
            ) { (res, entry) in
                let (i, a) = entry
                if let j = table[i]  {
                    res?.append((j, a))
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
        return ModuleStructure(summands: reduced, vectorizer: vectorizer)
    }

    public func sub<Impl, n, m>(matrix A: MatrixIF<Impl, n, m>) -> Self where Impl.BaseRing == R {
        assert(isFree)
        assert(A.size.rows == summands.count)
        
        let summands = (generators * A).map { Summand($0) }
        let vectorizer: Vectorizer = { _ in nil }
        
        return .init(summands: summands, vectorizer: vectorizer)
    }
    
    public static func ==(a: Self, b: Self) -> Bool {
        a.summands == b.summands
    }
    
    public static func ⊕(a: Self, b: Self) -> Self {
        if b.isZero {
            return a
        }
        if a.isZero {
            return b
        }
        
        return .init(
            summands: a.summands + b.summands,
            vectorizer: { z in
                if let v = a.vectorize(z),
                   let w = b.vectorize(z) {
                    return v.stack(w)
                } else {
                    return nil
                }
            }
        )
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
        assert(rawGenerators.isUnique)
        
        let n = rawGenerators.count
        let indexer = rawGenerators.makeIndexer()
        
        self.init(
            generators: rawGenerators.map{ x in .init(x) },
            vectorizer: { (z: BaseModule) in
                var valid = true
                let vec = AnySizeVector<R>(size: n) { setEntry in
                    for (x, a) in z.elements where !a.isZero {
                        guard let i = indexer(x) else {
                            valid = false
                            break
                        }
                        
                        setEntry(i, a)
                    }
                }
                return valid ? vec : nil
            }
        )
    }
}

extension ModuleStructure {
    public var dual: ModuleStructure<DualModule<BaseModule>> {
        assert(isFree)
        
        typealias D = ModuleStructure<DualModule<BaseModule>>
        
        let gens = generators
        let summands = gens.enumerated().map { (i, _) in
            DualModule<BaseModule> { z in
                .init(self.vectorize(z)![i])
            }
        }.map{ D.Summand($0) }
        
        let vectorizer: D.Vectorizer = { f in
            AnySizeVector(size: gens.count) { setEntry in
                self.generators.enumerated().forEach { (i, z) in
                    let a = f(z).value
                    if !a.isZero {
                        setEntry(i, a)
                    }
                }
            }
        }
        
        return .init(summands: summands, vectorizer: vectorizer)
    }

    public static func formDirectSum<Index: Hashable>(indices: [Index], objects: [Self]) -> ModuleStructure<IndexedModule<Index, BaseModule>> {
        typealias S = ModuleStructure<IndexedModule<Index, BaseModule>>
        typealias R = BaseModule.BaseRing
        
        let indexer = indices.makeIndexer()
        
        let ranks = [0] + objects.map { $0.rank }.accumulate()
        let generators = zip(indices, objects).flatMap { (index, obj) -> [IndexedModule<Index, BaseModule>] in
            obj.generators.map { x in IndexedModule(index: index, value: x) }
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

extension ModuleStructure where R: Hashable {
    public var dictionaryDescription: [R : Int] {
        summands.group{ $0.divisor }.mapValues{ $0.count }
    }
}
