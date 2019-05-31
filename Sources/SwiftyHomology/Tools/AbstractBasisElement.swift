//
//  AbstractBasisElement.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/05/30.
//

import Foundation
import SwiftyMath

public struct AbstractBasisElement: FreeModuleGenerator {
    public let index: Int
    public let label: String
    
    public init(_ index: Int, label: String? = nil) {
        self.index = index
        self.label = label ?? "e\(Format.sub(index))"
    }
    
    public static func generateBasis(_ size: Int) -> [AbstractBasisElement] {
        return (0 ..< size).map{ AbstractBasisElement($0) }
    }
    
    public static func == (e1: AbstractBasisElement, e2: AbstractBasisElement) -> Bool {
        return e1.index == e2.index
    }
    
    public static func < (e1: AbstractBasisElement, e2: AbstractBasisElement) -> Bool {
        return e1.index < e2.index
    }
    
    public var hashValue: Int {
        return index
    }
    
    public var description: String {
        return label
    }
}
