import SwiftyMath
import SwiftyHomology

extension String: LinearCombinationGenerator {}

typealias Generators = String
typealias R = Int
typealias M = LinearCombination<R, Generators>

// C = C_*(S^2)
let C = ChainComplex1<M>(
    grid: [
        ModuleStructure(rawGenerators: ["a"]),
        ModuleStructure(rawGenerators: ["b"]),
        ModuleStructure(rawGenerators: ["c", "d"]),
    ],
    degree: -1,
    differential: [
        .zero,
        .zero,
        .linearlyExtend { x in
            .init("b")
        },
    ]
)

print("C_*(S^2; \(R.symbol))")
C.printSequence(0 ... 2)

print()
print("H_*(S^2; \(R.symbol))")
let H = C.homology()
H.printSequence(0 ... 2)
