//
//  HomologyTests.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/05/15.
//

import XCTest
import SwmCore
import SwmMatrixTools
@testable import SwmHomology

class RealHomologyTests: XCTestCase {
    
    typealias R = 𝐑
    typealias Matrix = AnySizeMatrix<R>

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCalculatorType() {
        typealias C = ChainComplex1<LinearCombination<R, Util.Generator>>
        let type = R.homologyCalculator(forChainComplexType: C.self, options: [])
        XCTAssertTrue(type == LUHomologyCalculator<C>.self)
    }
    
    func test1() {
        let d = (1 ... 3).map{ _ in Matrix.zero(size: (1, 1)) }
        let C = Util.generateChainComplex(matrices: d)
        let H = C.homology()
        
        XCTAssertEqual(H[-1].dictionaryDescription, [:])
        XCTAssertEqual(H[0].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[1].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[2].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[3].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[4].dictionaryDescription, [:])
    }

    func test2() {
        let d = (1 ... 3).map{ i in i.isOdd ? Matrix.identity(size: (1, 1)) : Matrix.zero(size: (1, 1)) }
        let C = Util.generateChainComplex(matrices: d)
        let H = C.homology()

        XCTAssertEqual(H[-1].dictionaryDescription, [:])
        XCTAssertEqual(H[0].dictionaryDescription, [:])
        XCTAssertEqual(H[1].dictionaryDescription, [:])
        XCTAssertEqual(H[2].dictionaryDescription, [:])
        XCTAssertEqual(H[3].dictionaryDescription, [:])
        XCTAssertEqual(H[4].dictionaryDescription, [:])
    }

    func test3() {
        let d = (1 ... 3).map{ i in i.isOdd ? 2 * Matrix.identity(size: (1, 1)) : Matrix.zero(size: (1, 1)) }
        let C = Util.generateChainComplex(matrices: d)
        let H = C.homology()

        XCTAssertEqual(H[-1].dictionaryDescription, [:])
        XCTAssertEqual(H[0].dictionaryDescription, [:])
        XCTAssertEqual(H[1].dictionaryDescription, [:])
        XCTAssertEqual(H[2].dictionaryDescription, [:])
        XCTAssertEqual(H[3].dictionaryDescription, [:])
        XCTAssertEqual(H[4].dictionaryDescription, [:])
    }
    
    func testShift() {
        let shift = -3
        let d = (1 ... 3).map{ i in i.isOdd ? 2 * Matrix.identity(size: (1, 1)) : Matrix.zero(size: (1, 1)) }
        let C = Util.generateChainComplex(matrices: d).shifted(shift)
        let H = C.homology()
        
        XCTAssertEqual(H[-1 + shift].dictionaryDescription, [:])
        XCTAssertEqual(H[ 0 + shift].dictionaryDescription, [:])
        XCTAssertEqual(H[ 1 + shift].dictionaryDescription, [:])
        XCTAssertEqual(H[ 2 + shift].dictionaryDescription, [:])
        XCTAssertEqual(H[ 3 + shift].dictionaryDescription, [:])
    }
    
    func test_D3() {
        let d = [
            Matrix(size: (4, 6), grid: [-1, -1, 0, -1, 0, 0, 1, 0, -1, 0, -1, 0, 0, 1, 1, 0, 0, -1, 0, 0, 0, 1, 1, 1] ),
            Matrix(size: (6, 4), grid: [1, 1, 0, 0, -1, 0, 1, 0, 1, 0, 0, 1, 0, -1, -1, 0, 0, 1, 0, -1, 0, 0, 1, 1] ),
            Matrix(size: (4, 1), grid: [-1, 1, -1, 1] )
        ]
        
        let C = Util.generateChainComplex(matrices: d)
        let H = C.homology()
        
        XCTAssertEqual(H[0].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[1].dictionaryDescription, [:])
        XCTAssertEqual(H[2].dictionaryDescription, [:])
        XCTAssertEqual(H[3].dictionaryDescription, [:])
        
    }
    
    func test_S2() {
        let d = [
            Matrix(size: (4, 6), grid: [-1, -1, 0, 0, 0, 1, 1, 0, -1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, -1, -1, -1] ),
            Matrix(size: (6, 4), grid: [1, 0, 0, 1, -1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, -1, 0, -1, -1, 0, 0, 0, 1, 1] ),
        ]
        
        let C = Util.generateChainComplex(matrices: d)
        let H = C.homology()
        
        XCTAssertEqual(H[0].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[1].dictionaryDescription, [:])
        XCTAssertEqual(H[2].dictionaryDescription, [0: 1])
        
    }
    
    func test_T2() {
        let d = [
            Matrix(size: (9, 27), grid: [-1, -1, 0, -1, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, -1, 1, 0, -1, 0, 0, 0, 0, 0, 0, -1, -1, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, -1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, -1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, -1, 0, 1, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0, 1, -1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, -1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1] ),
            Matrix(size: (27, 18), grid: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1] )
        ]
        
        let C = Util.generateChainComplex(matrices: d)
        let H = C.homology()
        
        XCTAssertEqual(H[0].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[1].dictionaryDescription, [0: 2])
        XCTAssertEqual(H[2].dictionaryDescription, [0: 1])
        
    }
    
    func test_RP2() {
        let d = [
            Matrix(size: (6, 15), grid: [-1, -1, 0, 0, 0, 0, 0, -1, -1, 0, -1, 0, 0, 0, 0, 1, 0, -1, -1, 0, -1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 1, 1, 0, 1, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 1, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1] ),
            Matrix(size: (15, 10), grid: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, -1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1] ),
        ]
        
        let C = Util.generateChainComplex(matrices: d)
        let H = C.homology()
        
        XCTAssertEqual(H[0].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[1].dictionaryDescription, [:])
        XCTAssertEqual(H[2].dictionaryDescription, [:])
    }
    
    func test_Dual() {
        let d = [
            Matrix(size: (6, 15), grid: [-1, -1, 0, 0, 0, 0, 0, -1, -1, 0, -1, 0, 0, 0, 0, 1, 0, -1, -1, 0, -1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 1, 1, 0, 1, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 1, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1] ),
            Matrix(size: (15, 10), grid: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, -1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1] ),
        ]
        
        let C = Util.generateChainComplex(matrices: d).dual
        let δ = C.differential
        let H = C.homology()
        
        XCTAssertEqual(δ.degree, 1)
        XCTAssertEqual(δ[0].asMatrix(from: C[0], to: C[1]), d[0].transposed)
        XCTAssertEqual(δ[1].asMatrix(from: C[1], to: C[2]), d[1].transposed)

        XCTAssertEqual(H[0].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[1].dictionaryDescription, [:])
        XCTAssertEqual(H[2].dictionaryDescription, [:])
    }
    
    func test_D3_withGenerators() {
        let d = [
            Matrix(size: (4, 6), grid: [-1, -1, 0, -1, 0, 0, 1, 0, -1, 0, -1, 0, 0, 1, 1, 0, 0, -1, 0, 0, 0, 1, 1, 1] ),
            Matrix(size: (6, 4), grid: [1, 1, 0, 0, -1, 0, 1, 0, 1, 0, 0, 1, 0, -1, -1, 0, 0, 1, 0, -1, 0, 0, 1, 1] ),
            Matrix(size: (4, 1), grid: [-1, 1, -1, 1] )
        ]
        
        let C = Util.generateChainComplex(matrices: d)
        let H = C.homology()
        
        if H[0].rank == 1 {
            let z = H[0].generator(0)
            XCTAssertEqual(H[0].vectorize(z), AnySizeVector(size: 1, grid: [1]) )
        } else {
            XCTFail()
        }
    }
    
    func test_S2_withGenerators() {
        let d = [
            Matrix(size: (4, 6), grid: [-1, -1, 0, 0, 0, 1, 1, 0, -1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, -1, -1, -1] ),
            Matrix(size: (6, 4), grid: [1, 0, 0, 1, -1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, -1, 0, -1, -1, 0, 0, 0, 1, 1] ),
        ]

        let C = Util.generateChainComplex(matrices: d)
        let H = C.homology()
        let H2 = H[2]

        if H2.rank == 1 {
            let z = H2.generator(0)
            XCTAssertEqual(H2.vectorize(z)!.serialize(), [1])
            XCTAssertEqual(H2.vectorize(2 * z)!.serialize(), [2])
        } else {
            XCTFail()
        }
    }

    func test_T2_withGenerators() {
        let d = [
            Matrix(size: (9, 27), grid: [-1, -1, 0, -1, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, -1, 1, 0, -1, 0, 0, 0, 0, 0, 0, -1, -1, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, -1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, -1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, -1, 0, 1, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0, 1, -1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, -1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1] ),
            Matrix(size: (27, 18), grid: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1] )
        ]

        let C = Util.generateChainComplex(matrices: d)
        let H = C.homology()
        let H1 = H[1]

        if H1.rank == 2 {
            let z = H1.generator(0)
            let w = H1.generator(1)
            XCTAssertEqual(H1.vectorize(z)!.serialize(), [1, 0])
            XCTAssertEqual(H1.vectorize(w)!.serialize(), [0, 1])
            XCTAssertEqual(H1.vectorize(z - 2 * w)!.serialize(), [1, -2])
        } else {
            XCTFail()
        }
    }
}
