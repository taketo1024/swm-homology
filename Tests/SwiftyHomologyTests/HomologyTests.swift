//
//  HomologyTests.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/05/15.
//

import XCTest
import SwiftyMath
@testable import SwiftyHomology

extension Matrix {
    func asDMatrix() -> DMatrix<R> {
        return DMatrix(rows: rows, cols: cols, grid: grid)
    }
}

class HomologyTests: XCTestCase {
    
    typealias R = 𝐙
    typealias A = AbstractBasisElement

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testHomology() {
        let n = 3
        let base = ModuleGrid1<A, R>(generators: Dictionary(pairs: (0 ... n).map{ i in
            (i, A.generateBasis(1))
        }))
        let d = ChainMap(degree: -1) { i in
            ModuleEnd<FreeModule<A, R>>.linearlyExtend{ _ in .zero }
        }
        let C = ChainComplex(base: base, differential: d)
        let H = C.homology()
        
        XCTAssertEqual(H[0]!.structure, [0: 1])
        XCTAssertEqual(H[1]!.structure, [0: 1])
        XCTAssertEqual(H[2]!.structure, [0: 1])
        XCTAssertEqual(H[3]!.structure, [0: 1])
    }

    func testHomology2() {
        let n = 3
        let base = ModuleGrid1<A, R>(generators: Dictionary(pairs: (0 ... n).map{ i in
            (i, A.generateBasis(1))
        }))
        let d = ChainMap(degree: -1) { i in
            ModuleEnd<FreeModule<A, R>>.linearlyExtend{ _ in (i % 2 == 0) ? .zero : base[i - 1]!.generators[0] }
        }
        let C = ChainComplex(base: base, differential: d)
        let H = C.homology()
        
        XCTAssertEqual(H[0]!.structure, [:])
        XCTAssertEqual(H[1]!.structure, [:])
        XCTAssertEqual(H[2]!.structure, [:])
        XCTAssertEqual(H[3]!.structure, [:])
    }

    func testHomology3() {
        let n = 3
        let base = ModuleGrid1<A, R>(generators: Dictionary(pairs: (0 ... n).map{ i in
            (i, A.generateBasis(1))
        }))
        let d = ChainMap(degree: -1) { i in
            ModuleEnd<FreeModule<A, R>>.linearlyExtend{ _ in (i % 2 == 0) ? .zero : 2 * base[i - 1]!.generators[0] }
        }
        let C = ChainComplex(base: base, differential: d)
        let H = C.homology()

        XCTAssertEqual(H[0]!.structure, [2: 1])
        XCTAssertEqual(H[1]!.structure, [:])
        XCTAssertEqual(H[2]!.structure, [2: 1])
        XCTAssertEqual(H[3]!.structure, [:])
    }
}
