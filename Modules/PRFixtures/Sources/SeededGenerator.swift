/// SplitMix64: the same seed gives the same sequence on every run and machine.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func chance(_ probability: Double) -> Bool {
        Double.random(in: 0..<1, using: &self) < probability
    }

    mutating func int(_ range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &self)
    }

    mutating func pick<T>(_ values: [T]) -> T {
        values[Int.random(in: values.indices, using: &self)]
    }

    mutating func hex(length: Int) -> String {
        String((0..<length).map { _ in "0123456789abcdef".randomElement(using: &self)! })
    }
}
