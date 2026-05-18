import UIKit
import Photos

enum ExportError: Error, LocalizedError {
    case photoLibraryDenied
    case renderFailed
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .photoLibraryDenied:
            "Photo library access was denied. Please enable it in Settings."
        case .renderFailed:
            "Failed to render the image. Please try again."
        case .saveFailed(let detail):
            "Failed to save: \(detail)"
        }
    }
}

@MainActor
final class ImageExporter {

    static func export(
        engine: MetalEngine,
        budget: ParticleBudget,
        screenSize: CGSize
    ) async throws -> UIImage {
        // Request permission
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw ExportError.photoLibraryDenied
        }

        // Compute export dimensions (ensure even)
        let width = Int(screenSize.width * CGFloat(budget.exportScalePNG)) & ~1
        let height = Int(screenSize.height * CGFloat(budget.exportScalePNG)) & ~1

        // Render
        let renderer = OffscreenRenderer(engine: engine)
        guard let texture = renderer.renderFrame(width: width, height: height),
              let image = OffscreenRenderer.textureToImage(texture: texture) else {
            throw ExportError.renderFailed
        }

        guard let imageData = image.pngData() else {
            throw ExportError.saveFailed("Unable to encode image")
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("chromafield-\(UUID().uuidString).png")
        try imageData.write(to: outputURL, options: .atomic)
        defer {
            try? FileManager.default.removeItem(at: outputURL)
        }

        // Save to Photos
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: outputURL)
        }

        return image
    }
}
