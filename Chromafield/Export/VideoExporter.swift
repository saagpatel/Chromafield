import AVFoundation
import Photos
import UIKit

@MainActor
final class VideoExporter: ObservableObject {
    @Published var progress: Float = 0
    @Published var isExporting = false

    private let frameCount = 600  // 10 seconds at 60fps
    private let fps: Int32 = 60

    func export(
        engine: MetalEngine,
        budget: ParticleBudget,
        screenSize: CGSize
    ) async throws -> URL {
        guard !isExporting else { throw ExportError.saveFailed("Export already in progress") }

        // Request permission
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw ExportError.photoLibraryDenied
        }

        isExporting = true
        engine.isExporting = true
        progress = 0

        // Save particle state
        let savedState = engine.saveParticleState()

        defer {
            if let state = savedState {
                engine.restoreParticleState(state)
            }
            engine.isExporting = false
            isExporting = false
        }

        // Compute video dimensions (ensure even)
        let width = Int(screenSize.width * CGFloat(budget.exportScaleVideo)) & ~1
        let height = Int(screenSize.height * CGFloat(budget.exportScaleVideo)) & ~1

        // Setup AVAssetWriter
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("chromafield-\(UUID().uuidString).mp4")

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 10_000_000,
                AVVideoExpectedSourceFrameRateKey: fps,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
            ],
        ]

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = false

        let sourceAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
        ]

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: sourceAttributes
        )

        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        // Create renderer with fresh accumulation
        let renderer = OffscreenRenderer(engine: engine)

        // Render frames
        for frame in 0..<frameCount {
            // Advance simulation
            engine.step()

            // Render to texture
            guard let texture = renderer.renderFrame(width: width, height: height) else {
                writer.cancelWriting()
                try? FileManager.default.removeItem(at: outputURL)
                throw ExportError.renderFailed
            }

            // Wait for writer to be ready
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(for: .milliseconds(1))
            }

            // Copy texture to pixel buffer
            guard let pool = adaptor.pixelBufferPool else {
                writer.cancelWriting()
                try? FileManager.default.removeItem(at: outputURL)
                throw ExportError.saveFailed("Pixel buffer pool unavailable")
            }

            var pixelBuffer: CVPixelBuffer?
            let poolStatus = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
            guard poolStatus == kCVReturnSuccess, let buffer = pixelBuffer else {
                writer.cancelWriting()
                try? FileManager.default.removeItem(at: outputURL)
                throw ExportError.saveFailed("Failed to create pixel buffer")
            }

            CVPixelBufferLockBaseAddress(buffer, [])
            defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

            guard let dest = CVPixelBufferGetBaseAddress(buffer) else {
                writer.cancelWriting()
                try? FileManager.default.removeItem(at: outputURL)
                throw ExportError.saveFailed("Failed to get pixel buffer base address")
            }

            let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
            texture.getBytes(
                dest,
                bytesPerRow: bytesPerRow,
                from: MTLRegion(
                    origin: MTLOrigin(x: 0, y: 0, z: 0),
                    size: MTLSize(width: width, height: height, depth: 1)
                ),
                mipmapLevel: 0
            )

            let presentationTime = CMTime(value: CMTimeValue(frame), timescale: fps)
            adaptor.append(buffer, withPresentationTime: presentationTime)

            progress = Float(frame + 1) / Float(frameCount)

            // Yield periodically to keep UI responsive
            if frame % 10 == 0 {
                await Task.yield()
            }
        }

        // Finalize
        input.markAsFinished()
        await withCheckedContinuation { continuation in
            writer.finishWriting {
                continuation.resume()
            }
        }

        guard writer.status == .completed else {
            try? FileManager.default.removeItem(at: outputURL)
            throw ExportError.saveFailed(writer.error?.localizedDescription ?? "Unknown writer error")
        }

        // Save to Photos (must happen before temp file deletion)
        try await PhotoLibraryVideoExporter.saveVideo(at: outputURL)

        // Clean up temp file after Photos has copied it
        let savedURL = outputURL
        try? FileManager.default.removeItem(at: outputURL)

        return savedURL
    }
}

private enum PhotoLibraryVideoExporter {
    static func saveVideo(at url: URL) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }
}