import Metal
import simd

enum ParticleBufferError: Error, CustomStringConvertible {
    case allocationFailed(requestedBytes: Int)

    var description: String {
        switch self {
        case .allocationFailed(let bytes):
            "MTLBuffer allocation failed for \(bytes) bytes (\(bytes / 1024 / 1024) MB)"
        }
    }
}

final class ParticleBuffer {
    let buffer: MTLBuffer
    let count: Int

    init(device: MTLDevice, count: Int) throws {
        self.count = count
        let bufferSize = count * MemoryLayout<Particle>.stride

        guard let mtlBuffer = device.makeBuffer(length: bufferSize, options: .storageModeShared) else {
            throw ParticleBufferError.allocationFailed(requestedBytes: bufferSize)
        }
        self.buffer = mtlBuffer

        let pointer = mtlBuffer.contents().bindMemory(to: Particle.self, capacity: count)

        for i in 0..<count {
            let posX = Float.random(in: 0..<1)
            let posY = Float.random(in: 0..<1)
            let lifetime = Float.random(in: 120...600)

            pointer[i] = Particle(
                position: simd_float2(posX, posY),
                velocity: simd_float2(0, 0),
                age: Float.random(in: 0..<lifetime),
                lifetime: lifetime,
                speed: 0,
                padding: 0
            )
        }
    }

    var pointer: UnsafeMutablePointer<Particle> {
        buffer.contents().bindMemory(to: Particle.self, capacity: count)
    }
}
