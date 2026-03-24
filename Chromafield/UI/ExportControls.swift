import SwiftUI

struct ExportControls: View {
    let engine: MetalEngine
    let budget: ParticleBudget
    let screenSize: CGSize
    @ObservedObject var videoExporter: VideoExporter

    @State private var isExportingImage = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Export")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 20)

            // PNG Export
            Button {
                Task { await exportImage() }
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .frame(width: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Save Image")
                            .font(.system(size: 16, weight: .bold))
                        Text("PNG at \(Int(budget.exportScalePNG))× resolution")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                    if isExportingImage {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isExportingImage || videoExporter.isExporting)
            .foregroundStyle(.white)

            // MP4 Export
            Button {
                Task { await exportVideo() }
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "video")
                        .font(.system(size: 24))
                        .frame(width: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Record Loop")
                            .font(.system(size: 16, weight: .bold))
                        Text("10-second MP4 at 60fps")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isExportingImage || videoExporter.isExporting)
            .foregroundStyle(.white)

            // Video progress
            if videoExporter.isExporting {
                VStack(spacing: 8) {
                    ProgressView(value: videoExporter.progress)
                        .tint(.cyan)
                    Text("Rendering… \(Int(videoExporter.progress * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.95))
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .alert("Exported", isPresented: $showSuccess) {
            Button("OK") {}
        } message: {
            Text("Saved to your photo library.")
        }
        .alert("Export Failed", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func exportImage() async {
        isExportingImage = true
        defer { isExportingImage = false }

        do {
            _ = try await ImageExporter.export(
                engine: engine,
                budget: budget,
                screenSize: screenSize
            )
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func exportVideo() async {
        do {
            _ = try await videoExporter.export(
                engine: engine,
                budget: budget,
                screenSize: screenSize
            )
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
