//
//  GridType.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/10/25.
//

import SwiftyMath

public protocol GridType {
    associatedtype Index: AdditiveGroup & Hashable
    associatedtype Object
    
    subscript(i: Index) -> Object { get }
    func shifted(_ shift: Index) -> Self
    func description(forObjectAt i: Index) -> String
}

extension GridType {
    public func description(forObjectAt i: Index) -> String {
        "\(self[i])"
    }
}

extension GridType where Index == Int {
    public func shifted(_ i: Int) -> Self {
        shifted(Index(i))
    }
    
    public func printSequence<S: Sequence>(_ indices: S) where S.Element == Int {
        print( Format.table(rows: [""], cols: indices, symbol: "i") { (_, i) in description(forObjectAt: i) } )
    }
}

extension GridType where Index == MultiIndex<_2> {
    public subscript(i: Int, j: Int) -> Object {
        self[Index(i, j)]
    }

    public func shifted(_ i: Int, _ j: Int) -> Self {
        shifted(Index(i, j))
    }
    
    public func printTable<S1: Sequence, S2: Sequence>(_ indices1: S1, _ indices2: S2) where S1.Element == Int, S2.Element == Int {
        print( Format.table(rows: indices2.reversed(), cols: indices1, symbol: "j\\i") { (j, i) -> String in
            description(forObjectAt: Index(i, j))
        } )
    }
}
