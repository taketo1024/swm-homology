//
//  Module.swift
//  
//
//  Created by Taketo Sano on 2021/05/14.
//

import SwiftyMath

extension Module {
    internal static func combine<n>(basis: [Self], vector: ColVector<n, BaseRing>) -> Self {
        combine(basis: basis, matrix: vector)[0]
    }

    internal static func combine<n, m>(basis: [Self], matrix A: Matrix<n, m, BaseRing>) -> [Self] {
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
