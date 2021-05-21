//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwiftyMath
@testable import SwiftyHomology

struct Util {
    static func generateChainComplex<R>(matrices: [AnySizeMatrix<R>]) -> ChainComplex1<LinearCombination<R, Generator>> {
        typealias A = Generator
        typealias M = LinearCombination<R, A>

        var count = 0
        func gens(_ n: Int) -> [A] {
            defer {
                count += n
            }
            return (1 ... n).map{ A(count + $0) }
        }
        
        let bases = matrices.map { d in
            gens(d.size.rows)
        } + [gens(matrices.last!.size.cols)]
        
        let objs = bases.map { ModuleObject<M>(generators: $0) }
        
        return ChainComplex1<M>(
            grid: { i in
                bases.indices.contains(i) ? objs[i] : .zeroModule
            },
            degree: -1,
            differential: { i in
                if matrices.indices.contains(i - 1) {
                    let from = objs[i]
                    let to = objs[i - 1]
                    let d = matrices[i - 1]
                    return ModuleEnd { z in
                        .combine(basis: to.generators, vector: d * from.vectorize(z))
                    }
                } else {
                    return .zero
                }
            }
        )
    }
    
    struct Generator: LinearCombinationGenerator {
        let index: Int
        init(_ index: Int) {
            self.index = index
        }
        
        static func < (lhs: Self, rhs: Self) -> Bool {
            return lhs.index < rhs.index
        }
        
        var description: String {
            return "e\(Format.sub(index))"
        }
    }
}
