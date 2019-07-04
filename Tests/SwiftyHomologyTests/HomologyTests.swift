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

    var count = 0
    private func gens(_ n: Int) -> [A] {
        defer {
            count += n
        }
        return (1 ... n).map{ A(count + $0) }
    }
    
    private func generateChainComplex(matrices: [DMatrix<R>]) -> ChainComplex1<M> {
        let bases = matrices.map { d in
            gens(d.size.rows)
        } + [gens(matrices.last!.size.cols)]
        
        let objs = bases.map { ModuleObject<M>(basis: $0) }
        
        return ChainComplex1<M>(
            descendingSequence: { i in
                bases.indices.contains(i) ? objs[i] : .zeroModule
            },
            differential: { i in
                if matrices.indices.contains(i - 1) {
                    let from = objs[i]
                    let to = objs[i - 1]
                    let d = matrices[i - 1]
                    return ModuleEnd { z in
                        return (to.generators * (d * from.factorize(z)))[0]
                    }
                } else {
                    return .zero
                }
            }
        )
    }
    
    override func setUp() {
        super.setUp()
        count = 0
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test1() {
        let d = (1 ... 3).map{ _ in DMatrix<R>.zero(size: (1, 1)) }
        let C = generateChainComplex(matrices: d)
        let H = Homology(C)
        
        C.assertChainComplex(range: 0 ... d.count)

        XCTAssertEqual(H[-1].dictionaryDescription, [:])
        XCTAssertEqual(H[0].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[1].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[2].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[3].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[4].dictionaryDescription, [:])
    }

    func test2() {
        let d = (1 ... 3).map{ i in i.isOdd ? DMatrix<R>.identity(size: 1) : DMatrix<R>.zero(size: (1, 1)) }
        let C = generateChainComplex(matrices: d)
        let H = Homology(C)

        C.assertChainComplex(range: 0 ... d.count)
        
        XCTAssertEqual(H[-1].dictionaryDescription, [:])
        XCTAssertEqual(H[0].dictionaryDescription, [:])
        XCTAssertEqual(H[1].dictionaryDescription, [:])
        XCTAssertEqual(H[2].dictionaryDescription, [:])
        XCTAssertEqual(H[3].dictionaryDescription, [:])
        XCTAssertEqual(H[4].dictionaryDescription, [:])
    }

    func test3() {
        let d = (1 ... 3).map{ i in i.isOdd ? 2 * DMatrix<R>.identity(size: 1) : DMatrix<R>.zero(size: (1, 1)) }
        let C = generateChainComplex(matrices: d)
        let H = Homology(C)

        for i in 0 ... d.count {
            C.assertChainComplex(at: i)
        }
        
        XCTAssertEqual(H[-1].dictionaryDescription, [:])
        XCTAssertEqual(H[0].dictionaryDescription, [2:1])
        XCTAssertEqual(H[1].dictionaryDescription, [:])
        XCTAssertEqual(H[2].dictionaryDescription, [2:1])
        XCTAssertEqual(H[3].dictionaryDescription, [:])
        XCTAssertEqual(H[4].dictionaryDescription, [:])
    }
    
    func testShift() {
        let shift = -3
        let d = (1 ... 3).map{ i in i.isOdd ? 2 * DMatrix<R>.identity(size: 1) : DMatrix<R>.zero(size: (1, 1)) }
        let C = generateChainComplex(matrices: d).shifted(shift)
        let H = Homology(C)
        
        for i in 0 ... d.count {
            C.assertChainComplex(at: i + shift)
        }
        
        XCTAssertEqual(H[-1 + shift].dictionaryDescription, [:])
        XCTAssertEqual(H[ 0 + shift].dictionaryDescription, [2:1])
        XCTAssertEqual(H[ 1 + shift].dictionaryDescription, [:])
        XCTAssertEqual(H[ 2 + shift].dictionaryDescription, [2:1])
        XCTAssertEqual(H[ 3 + shift].dictionaryDescription, [:])
    }
    
    func test_D3() {
        let d = [
            DMatrix(size: (4, 6), grid: [-1, -1, 0, -1, 0, 0, 1, 0, -1, 0, -1, 0, 0, 1, 1, 0, 0, -1, 0, 0, 0, 1, 1, 1] ),
            DMatrix(size: (6, 4), grid: [1, 1, 0, 0, -1, 0, 1, 0, 1, 0, 0, 1, 0, -1, -1, 0, 0, 1, 0, -1, 0, 0, 1, 1] ),
            DMatrix(size: (4, 1), grid: [-1, 1, -1, 1] )
        ]
        
        let C = generateChainComplex(matrices: d)
        let H = Homology(C)
        
        C.assertChainComplex(range: 0 ... d.count)
        
        XCTAssertEqual(H[0].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[1].dictionaryDescription, [:])
        XCTAssertEqual(H[2].dictionaryDescription, [:])
        XCTAssertEqual(H[3].dictionaryDescription, [:])
        
    }
    
    func test_S2() {
        let d = [
            DMatrix(size: (4, 6), grid: [-1, -1, 0, 0, 0, 1, 1, 0, -1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, -1, -1, -1] ),
            DMatrix(size: (6, 4), grid: [1, 0, 0, 1, -1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, -1, 0, -1, -1, 0, 0, 0, 1, 1] ),
        ]
        
        let C = generateChainComplex(matrices: d)
        let H = Homology(C)
        
        C.assertChainComplex(range: 0 ... d.count)
        
        XCTAssertEqual(H[0].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[1].dictionaryDescription, [:])
        XCTAssertEqual(H[2].dictionaryDescription, [0: 1])
        
    }
    
    func test_T2() {
        let d = [
            DMatrix(size: (9, 27), grid: [-1, -1, 0, -1, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, -1, 1, 0, -1, 0, 0, 0, 0, 0, 0, -1, -1, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, -1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, -1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, -1, 0, 1, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0, 1, -1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, -1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1] ),
            DMatrix(size: (27, 18), grid: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1] )
        ]
        
        let C = generateChainComplex(matrices: d)
        let H = Homology(C)
        
        C.assertChainComplex(range: 0 ... d.count)
        
        XCTAssertEqual(H[0].dictionaryDescription, [0: 1])
        XCTAssertEqual(H[1].dictionaryDescription, [0: 2])
        XCTAssertEqual(H[2].dictionaryDescription, [0: 1])
        
    }
    
    func test_RP2() {
        let d = [
            DMatrix(size: (6, 15), grid: [-1, -1, 0, 0, 0, 0, 0, -1, -1, 0, -1, 0, 0, 0, 0, 1, 0, -1, -1, 0, -1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 1, 1, 0, 1, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 1, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1] ),
            DMatrix(size: (15, 10), grid: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, -1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1] ),
        ]
        
        let C = generateChainComplex(matrices: d)
        let H = Homology(C)
        
        C.assertChainComplex(range: 0 ... d.count)
        
        XCTAssertEqual(H[0].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[1].dictionaryDescription, [2 : 1])
        XCTAssertEqual(H[2].dictionaryDescription, [:])
    }
    
    func test_Dual() {
        let d = [
            DMatrix(size: (6, 15), grid: [-1, -1, 0, 0, 0, 0, 0, -1, -1, 0, -1, 0, 0, 0, 0, 1, 0, -1, -1, 0, -1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 1, 1, 0, 1, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 1, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1] ),
            DMatrix(size: (15, 10), grid: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, -1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1] ),
        ]
        
        let C = generateChainComplex(matrices: d).dual
        let H = Homology(C)
        
        C.assertChainComplex(range: 0 ... d.count)
        
        XCTAssertEqual(C.differential.degree, 1)
        XCTAssertEqual(C.differntialMatrix(at: 0), d[0].transposed)
        XCTAssertEqual(C.differntialMatrix(at: 1), d[1].transposed)

        XCTAssertEqual(H[0].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[1].dictionaryDescription, [:])
        XCTAssertEqual(H[2].dictionaryDescription, [2 : 1])
    }

}
