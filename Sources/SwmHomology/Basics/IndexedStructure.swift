//
//  GridType.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/10/25.
//

import SwmCore

public protocol IndexedStructure {
    associatedtype Index: AdditiveGroup & Hashable
    associatedtype Object
    
    subscript(i: Index) -> Object { get }
    var support: [Index] { get }
    func structure() -> [Index : Object]
    func description(forObject obj: Object) -> String
}

extension IndexedStructure {
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

extension IndexedStructure where Index == Int {
    public func printSequence() {
        let strc = structure()
        let seq = support.map{ i -> (Int, String) in
            let s = strc[i].flatMap{ description(forObject: $0) } ?? ""
            return (i, s)
        }
        let table = Format.table(elements: seq)
        print(table)
    }
}

extension IndexedStructure where Index == MultiIndex<_2> {
    public subscript(i: Int, j: Int) -> Object {
        self[Index(i, j)]
    }

    public func printTable() {
        let strc = structure()
        let elements = support.map { idx -> (Int, Int, String)  in
            let s = strc[idx].flatMap{ description(forObject: $0) } ?? ""
            return (idx[0], idx[1], s)
        }
        let table = Format.table(elements: elements)
        print(table)
    }
}

extension IndexedStructure where Index == MultiIndex<_3> {
    public subscript(i: Int, j: Int, k: Int) -> Object {
        self[Index(i, j, k)]
    }
}
