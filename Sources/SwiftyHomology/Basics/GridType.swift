//
//  GridType.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/10/25.
//

import SwiftyMath

public protocol GridType {
    associatedtype GridDim: StaticSizeType
    associatedtype Object
    
    typealias Coords = GridCoords<GridDim>
    
    subscript(I: Coords) -> Object { get }
    var support: ClosedRange<Coords>? { get }
    func shifted(_ shift: Coords) -> Self
    func description(forObjectAt I: Coords) -> String
}

extension GridType {
    public var gridDim: Int {
        GridDim.intValue
    }
    
    public subscript(I: Int...) -> Object {
        self[Coords(I)]
    }
    
    public func description(forObjectAt I: Coords) -> String {
        "\(self[I])"
    }
}

extension GridType where GridDim == _1 {
    public func shifted(_ i: Int) -> Self {
        shifted(Coords(i))
    }
    
    public func printSequence() {
        guard let support = support else { return }
        printSequence(support.range)
    }
    
    public func printSequence<S: Sequence>(_ indices: S) where S.Element == Int {
        print( Format.table(rows: [""], cols: indices, symbol: "i") { (_, i) in description(forObjectAt: [i]) } )
    }
}

extension GridType where GridDim == _2 {
    public func shifted(_ i: Int, _ j: Int) -> Self {
        shifted(Coords(i, j))
    }
    
    public func printTable() {
        guard let support = support else { return }
        let (r0, r1) = support.range
        printTable(r0, r1)
    }
    
    public func printTable<S1: Sequence, S2: Sequence>(_ indices1: S1, _ indices2: S2) where S1.Element == Int, S2.Element == Int {
        print( Format.table(rows: indices2.reversed(), cols: indices1, symbol: "j\\i") { (j, i) -> String in
            description(forObjectAt: [i, j])
        } )
    }
}
