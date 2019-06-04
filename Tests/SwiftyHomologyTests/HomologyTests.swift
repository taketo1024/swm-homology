//
//  HomologyTests.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/05/15.
//

import XCTest
import SwiftyMath
@testable import SwiftyHomology

struct IntGenerator: FreeModuleGenerator {
    let index: Int
    init(_ index: Int) {
        self.index = index
    }
    
    static func < (lhs: IntGenerator, rhs: IntGenerator) -> Bool {
        return lhs.index < rhs.index
    }
    
    var description: String {
        return "e\(Format.sub(index))"
    }
}

class HomologyTests: XCTestCase {
    
    typealias R = 𝐙
    typealias A = IntGenerator
    typealias M = FreeModule<A, R>

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testHomology() {
        let seq = (0 ... 3).map { (i: Int) -> ModuleObject<M> in
            let a = A(i)
            return ModuleObject(basis: [M.wrap(a)], factorizer: { z in DVector([z[a]]) })
        }
        let C = ChainComplex1(
            descendingSequence: { i in
                seq.indices.contains(i) ? seq[i] : .zeroModule
            },
            differential: { i in
                ModuleEnd<M>.linearlyExtend{ _ in .zero }
            }
        )
        let H = Homology(C)

        XCTAssertEqual(H[0].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[1].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[2].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[3].dictionaryDescription, [0: 1])
    }

    func testHomology2() {
        let seq = (0 ... 3).map { (i: Int) -> ModuleObject<M> in
            let a = A(i)
            return ModuleObject(basis: [M.wrap(a)], factorizer: { z in DVector([z[a]]) })
        }
        let C = ChainComplex1(
            descendingSequence: { i in
                seq.indices.contains(i) ? seq[i] : .zeroModule
            },
            differential: { i in
                ModuleEnd<M>.linearlyExtend{ _ in (i % 2 == 1 && seq.indices.contains(i - 1)) ? seq[i - 1].generators[0] : .zero }
            }
        )
        let H = Homology(C)

        XCTAssertEqual(H[0].dictionaryDescription, [:])
        XCTAssertEqual(H[1].dictionaryDescription, [:])
        XCTAssertEqual(H[2].dictionaryDescription, [:])
        XCTAssertEqual(H[3].dictionaryDescription, [:])
    }

    func testHomology3() {
        let seq = (0 ... 3).map { (i: Int) -> ModuleObject<M> in
            let a = A(i)
            return ModuleObject(basis: [M.wrap(a)], factorizer: { z in DVector([z[a]]) })
        }
        let C = ChainComplex1(
            descendingSequence: { i in
                seq.indices.contains(i) ? seq[i] : .zeroModule
            },
            differential: { i in
                ModuleEnd<M>.linearlyExtend{ _ in (i % 2 == 1 && seq.indices.contains(i - 1)) ? 2 * seq[i - 1].generators[0] : .zero }
            }
        )
        let H = Homology(C)

        XCTAssertEqual(H[0].dictionaryDescription, [2:1])
        XCTAssertEqual(H[1].dictionaryDescription, [:])
        XCTAssertEqual(H[2].dictionaryDescription, [2:1])
        XCTAssertEqual(H[3].dictionaryDescription, [:])
    }
    
    func testCohomology() {
        let seq = (0 ... 3).map { (i: Int) -> ModuleObject<M> in
            let a = A(i)
            return ModuleObject(basis: [M.wrap(a)], factorizer: { z in DVector([z[a]]) })
        }
        let C = ChainComplex1(
            descendingSequence: { i in
                seq.indices.contains(i) ? seq[i] : .zeroModule
            },
            differential: { i in
                ModuleEnd<M>.linearlyExtend{ _ in (i % 2 == 1 && seq.indices.contains(i - 1)) ? 2 * seq[i - 1].generators[0] : .zero }
            }
        )
        let H = Homology(C.dual)
        
        XCTAssertEqual(H[0].dictionaryDescription, [:])
        XCTAssertEqual(H[1].dictionaryDescription, [2:1])
        XCTAssertEqual(H[2].dictionaryDescription, [:])
        XCTAssertEqual(H[3].dictionaryDescription, [2:1])
    }

}
