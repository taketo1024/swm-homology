//
//  ModuleObject.swift
//  Sample
//
//  Created by Taketo Sano on 2018/06/02.
//

import Foundation
import SwiftyMath

// A decomposed form of a freely & finitely presented module,
// i.e. a module with finite generators and a finite & free presentation.
//
//   M = (R/d_0 ⊕ ... ⊕ R/d_k) ⊕ R^r  ( d_i: torsion-coeffs, r: rank )
//
// See: https://en.wikipedia.org/wiki/Free_presentation
//      https://en.wikipedia.org/wiki/Structure_theorem_for_finitely_generated_modules_over_a_principal_ideal_domain#Invariant_factor_decomposition

public struct ModuleObject<BaseModule: Module>: Equatable, CustomStringConvertible {
    public typealias R = BaseModule.CoeffRing
    public typealias Factorizer = (BaseModule) -> DVector<R>

    public let summands: [Summand]
    private let factorizer: Factorizer
    
    internal init(_ summands: [Summand], _ factorizer: @escaping Factorizer) {
        self.summands = summands
        self.factorizer = factorizer
    }
    
    public init(basis: [BaseModule], factorizer: @escaping Factorizer) {
        let summands = basis.map{ z in Summand(z) }
        self.init(summands, factorizer)
    }
    
    public init(generators: [BaseModule], divisors: [R], factorizer: @escaping Factorizer) {
        assert(generators.count == divisors.count)
        let summands = zip(generators, divisors).map{ (z, r) in Summand(z, r) }
        self.init(summands, factorizer)
    }

    
    public subscript(i: Int) -> Summand {
        return summands[i]
    }
    
    public func factorize(_ z: BaseModule) -> DVector<R> {
        return factorizer(z)
    }
    
    public static var zeroModule: ModuleObject<BaseModule> {
        return ModuleObject([], {_ in DVector([])})
    }
    
    public var isZero: Bool {
        return summands.isEmpty
    }
    
    public var isFree: Bool {
        return summands.allSatisfy { $0.isFree }
    }
    
    public var rank: Int {
        return summands.filter{ $0.isFree }.count
    }
    
    public var generators: [BaseModule] {
        return summands.map{ $0.generator }
    }
    
    public func generator(_ i: Int) -> BaseModule {
        return summands[i].generator
    }
    
    public static func ==(a: ModuleObject<BaseModule>, b: ModuleObject<BaseModule>) -> Bool {
        return a.summands == b.summands
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
            return divisor == .zero
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

extension ModuleObject where BaseModule: FreeModuleType {
    public init(basis: [BaseModule.Generator]) {
        let indexer = basis.indexer()
        self.init(basis: basis.map{ x in .wrap(x) }, factorizer: { z in z.factorize(by: basis, indexer: indexer) })
    }
}

extension ModuleObject {
    public var dual: ModuleObject<Dual<BaseModule>> {
        assert(isFree)
        
        typealias DualObject = ModuleObject<Dual<BaseModule>>
        let summands = self.generators.enumerated().map { (i, _) in
            Dual<BaseModule> { z in
                .wrap(self.factorize(z)[i])
            }
        }.map{ DualObject.Summand($0) }
        
        let factr = { (f: Dual<BaseModule>) -> DVector<R> in
            let comps = self.generators.enumerated().compactMap{ (i, z) -> MatrixComponent<R>? in
                let a: R = f.applied(to: z).value
                return (a != .zero) ? (i, 0, a) : nil
            }
            return DVector(size: (self.rank, 1), components: comps, zerosExcluded: true)
        }
        return ModuleObject<Dual<BaseModule>>(summands, factr)
    }
}

extension ModuleObject where R: Hashable {
    public var dictionaryDescription: [R : Int] {
        return summands.group{ $0.divisor }.mapValues{ $0.count }
    }
}
