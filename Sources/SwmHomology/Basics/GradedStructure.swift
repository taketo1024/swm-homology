//
//  GridType.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/10/25.
//

import SwmCore

public protocol GradedStructure {
    associatedtype Index: AdditiveGroup & Hashable
    associatedtype Object
    
    subscript(i: Index) -> Object { get }
    var support: [Index] { get }
    func structure() -> [Index : Object]
    func description(forObject obj: Object) -> String
}

extension GradedStructure {
    public func structure() -> [Index : Object] {
        Dictionary(support.map{ idx in (idx, self[idx]) })
    }
    
    public func description(forObject obj: Object) -> String {
        "\(obj)"
    }
    
    public func printStructure() {
        let strc = structure()
        for s in support {
            if let obj = strc[s] {
                print(s, ":", description(forObject: obj))
            }
        }
    }
}

extension GradedStructure where Index == Int {
    public func printSequence() {
        let strc = structure()
        let seq = support.compactMap{ i in
            strc[i].flatMap{ obj in (i, description(forObject: obj)) }
        }
        let table = Format.table(elements: seq)
        print(table)
    }
}

extension GradedStructure where Index == MultiIndex<_2> {
    public subscript(i: Int, j: Int) -> Object {
        self[Index(i, j)]
    }

    public func printTable() {
        let strc = structure()
        let elements = support.compactMap { idx in
            strc[idx].flatMap{ (idx[0], idx[1], description(forObject: $0)) }
        }
        let table = Format.table(elements: elements)
        print(table)
    }
}

extension GradedStructure where Index == MultiIndex<_3> {
    public subscript(i: Int, j: Int, k: Int) -> Object {
        self[Index(i, j, k)]
    }
}
