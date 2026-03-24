import UIKit

enum ChipTier: Sendable {
    case m4
    case m3
    case m2
    case m1
    case a18
    case a17
    case a16
    case a15
    case unknown
}

func detectChipTier() -> ChipTier {
    var size: Int = 0
    sysctlbyname("hw.machine", nil, &size, nil, 0)
    var machine = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.machine", &machine, &size, nil, 0)
    let identifier = machine.withUnsafeBufferPointer { buffer in
        String(cString: buffer.baseAddress!)
    }

    if identifier.hasPrefix("iPad16") { return .m4 }
    if identifier.hasPrefix("iPad15") { return .m3 }
    if identifier.hasPrefix("iPad14") { return .m2 }
    if identifier.hasPrefix("iPad13") { return .m1 }
    if identifier.hasPrefix("iPhone17") { return .a18 }
    if identifier.hasPrefix("iPhone16") { return .a17 }
    if identifier.hasPrefix("iPhone15") { return .a16 }

    // Simulator on Apple Silicon returns "arm64" or Mac identifier
    if identifier == "arm64" || identifier.hasPrefix("Mac") {
        return .m1
    }

    return .unknown
}

@MainActor
func detectParticleBudget(chipTier: ChipTier? = nil) -> ParticleBudget {
    let chip = chipTier ?? detectChipTier()
    let isIPad = UIDevice.current.userInterfaceIdiom == .pad

    switch chip {
    case .m4:
        return ParticleBudget(
            maxParticles: 200_000,
            exportScalePNG: 2.0,
            exportScaleVideo: isIPad ? 2.0 : 1.0,
            targetFPS: 60
        )
    case .m2, .m3:
        return ParticleBudget(
            maxParticles: 150_000,
            exportScalePNG: 2.0,
            exportScaleVideo: isIPad ? 2.0 : 1.0,
            targetFPS: 60
        )
    case .m1:
        return ParticleBudget(
            maxParticles: 100_000,
            exportScalePNG: 2.0,
            exportScaleVideo: isIPad ? 2.0 : 1.0,
            targetFPS: 60
        )
    case .a17, .a18:
        return ParticleBudget(
            maxParticles: 50_000,
            exportScalePNG: 2.0,
            exportScaleVideo: 1.0,
            targetFPS: 60
        )
    case .a15, .a16, .unknown:
        return ParticleBudget(
            maxParticles: 20_000,
            exportScalePNG: 1.0,
            exportScaleVideo: 1.0,
            targetFPS: 60
        )
    }
}
