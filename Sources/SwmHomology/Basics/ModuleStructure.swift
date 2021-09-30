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
    public typealias Vectorizer = (BaseModule) -> [ColEntry<R>]?

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
    
    public func vectorEntries(_ z: BaseModule) -> [ColEntry<R>]? {
        vectorizer(z)
    }
    
    public func vectorize(_ z: BaseModule) -> AnySizeVector<R>? {
        vectorize(z, AnySizeVector<R>.self)
    }
    
    public func vectorize<M, n>(_ z: BaseModule, _ type: ColVectorIF<M, n>.Type) -> ColVectorIF<M, n>?
    where M: MatrixImpl, M.BaseRing == R {
        if let entries = vectorEntries(z) {
            return .init(size: summands.count, colEntries: entries)
        } else {
            return nil
        }
    }
    
    public static var zeroModule: Self {
        .init(summands: [], vectorizer: { _ in [] } )
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
        var reduced: [Summand] = []
        var table: [Int : Int] = [:]
        
        for (i, s) in summands.enumerated() where predicate(s) {
            reduced.append(s)
            table[i] = reduced.count - 1
        }
        
        let vectorizer: Vectorizer = { z in
            guard let v = vectorEntries(z) else {
                return nil
            }
            
            var w: [ColEntry<R>] = []
            for (i, a) in v {
                if let j = table[i]  {
                    w.append((j, a))
                } else {
                    return nil
                }
            }
            return w
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
                if let v = a.vectorEntries(z), let w = b.vectorEntries(z) {
                    let n = a.summands.count
                    return v + w.map{ (i, a) in (n + i, a) }
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
    
    public var detailDescription: String {
        "\(self) {\n" + summands.map { s in
            "\t\(s): \(s.generator)"
        }.joined(separator: "\n") + "\n}"
    }
    
    public func printDetail() {
        print(detailDescription)
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
            default           : return "\(R.symbol)/(\(divisor))"
            }
        }
    }
}

extension ModuleStructure where BaseModule: LinearCombinationType {
    public init(rawGenerators: [BaseModule.Generator]) {
        assert(rawGenerators.isUnique)
        
        let indexer = rawGenerators.makeIndexer()
        
        self.init(
            generators: rawGenerators.map{ x in .init(x) },
            vectorizer: { (z: BaseModule) in
                var v: [ColEntry<R>] = []
                for (x, a) in z.elements where !a.isZero {
                    guard let i = indexer(x) else {
                        return nil
                    }
                    v.append((i, a))
                }
                return v
            }
        )
    }
}

extension ModuleStructure {
    public var dual: ModuleStructure<DualModule<BaseModule>> {
        assert(isFree)
        
        typealias D = ModuleStructure<DualModule<BaseModule>>
        
        let n = generators.count
        let summands = (0 ..< n).map { i in
            // dual of i-th summand.
            let d = DualModule<BaseModule> { z in
                let v = vectorEntries(z)!
                if let a = v.first(where: { (j, _) in i == j })?.value {
                    return AsModule(a)
                } else {
                    return .zero
                }
            }
            return d
        }.map{ D.Summand($0) }
        
        let vectorizer: D.Vectorizer = { f in
            generators.enumerated().compactMap { (i, z) -> ColEntry<R>? in
                let a = f(z).value
                if !a.isZero {
                    return (i, a)
                } else {
                    return nil
                }
            }
        }
        
        return .init(summands: summands, vectorizer: vectorizer)
    }
}

extension ModuleStructure where R: Hashable {
    public var dictionaryDescription: [R : Int] {
        summands.group{ $0.divisor }.mapValues{ $0.count }
    }
}

extension ModuleStructure.Summand: Codable where BaseModule.BaseRing: Codable {
    public enum CodingKeys: CodingKey {
        case generator, divisor
    }
    
    public init(from decoder: Decoder) throws {
        typealias R = BaseModule.BaseRing
        let c = try decoder.container(keyedBy: CodingKeys.self)
        generator = .zero // TODO
        divisor = try c.decode(R.self, forKey: .divisor)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(divisor, forKey: .divisor)
    }
}

extension ModuleStructure: Codable where BaseModule.BaseRing: Codable {
    public enum CodingKeys: CodingKey {
        case summands
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        summands = try c.decode([Summand].self, forKey: .summands)
        vectorizer = { _ in nil }
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(summands, forKey: .summands)
    }
}
