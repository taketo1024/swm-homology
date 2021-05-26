//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/26.
//

import SwmCore
import SwmMatrixTools

extension MatrixEliminationResult {
    // P^-1 * [I_r; O]
    public var imageSpanningMatrix: MatrixIF<Impl, n, anySize> {
        let (r, n) = (rank, size.rows)
        if r == 0 {
            return .zero(size: (n, 0))
        }
        
        switch form {
        case .Diagonal, .Smith, .ColHermite, .ColEchelon:
            return .identity(size: (n, r))
                .appliedRowOperations(rowOpsInverse)
            
        case .RowHermite, .RowEchelon:
            fatalError("not supported yet.")
            
        default:
            fatalError("unavailable.")
        }
    }

    // C = P^-1 * [O; I_{n-r}]
    public var imageComplementMatrix: MatrixIF<Impl, n, anySize> {
        let (r, n) = (rank, size.rows)
        if r == n {
            return .zero(size: (n, 0))
        }
        
        switch form {
        case .Diagonal, .Smith, .ColHermite, .ColEchelon:
            let occupied = Set(headEntries.map{ $0.row })
            let remain = (0 ..< n).subtract(occupied)
            return .colUnits(size: (n, n - r), indices: remain)
                .appliedRowOperations(rowOpsInverse)
            
        case .RowHermite, .RowEchelon:
            fatalError("not supported yet.")
            
        default:
            fatalError("unavailable.")
        }
    }
}
