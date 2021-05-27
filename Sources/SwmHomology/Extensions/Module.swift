//
//  Module.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwmCore

extension Module {
    // TODO rename basis -> elements
    internal static func combine<Impl, n>(basis: [Self], vector: MatrixIF<Impl, n, _1>) -> Self
    where Impl.BaseRing == BaseRing {
        combine(basis: basis, matrix: vector)[0]
    }

    internal static func combine<Impl, n, m>(basis: [Self], matrix A: MatrixIF<Impl, n, m>) -> [Self]
    where Impl.BaseRing == BaseRing {
        assert(basis.count == A.size.rows)
        let cols = A.nonZeroEntries.group{ $0.col }
        
        return Array(0 ..< A.size.cols).parallelMap { j in
            guard let col = cols[j] else {
                return .zero
            }
            return col.sum { (i, _, a) in a * basis[i] }
        }
    }
}

internal func * <M, Impl, n>(elements: [M], vector: MatrixIF<Impl, n, _1>) -> M
where M: Module, M.BaseRing == Impl.BaseRing {
    M.combine(basis: elements, vector: vector)
}

internal func * <M, Impl, n, m>(elements: [M], matrix: MatrixIF<Impl, n, m>) -> [M]
where M: Module, M.BaseRing == Impl.BaseRing {
    M.combine(basis: elements, matrix: matrix)
}
