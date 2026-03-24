import SwiftUI
import Metal

struct ContentView: View {
    @State private var engine: MetalEngine?
    @State private var fieldManager = FieldManager()
    @State private var gestureCoordinator: GestureCoordinator?
    @State private var pencilHandler: PencilInputHandler?
    @State private var persistenceManager = PersistenceManager()
    @State private var videoExporter = VideoExporter()
    @State private var particleBudget: ParticleBudget?

    @State private var currentBehavior: ParticleBehavior = .flocking
    @State private var showBehaviorPicker = false
    @State private var showPaletteSelector = false
    @State private var showPresetGallery = false
    @State private var showExportControls = false
    @State private var savedConfigs: [FieldConfig] = []
    @State private var bundledPresets: [FieldConfig] = []
    @State private var showQualityToast = false
    @State private var showCanvasSettings = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let engine, let coordinator = gestureCoordinator, let pencil = pencilHandler {
                    CanvasContainerView(
                        engine: engine,
                        gestureCoordinator: coordinator,
                        pencilHandler: pencil
                    )
                    .ignoresSafeArea()

                    // Radial node menu overlay
                    if case .showing(let viewPoint, let normalizedPoint) = coordinator.radialMenuState {
                        RadialNodeMenu(
                            position: viewPoint,
                            onSelect: { type in
                                fieldManager.addNode(FieldNodeModel(
                                    position: normalizedPoint,
                                    type: type
                                ))
                                coordinator.radialMenuState = .hidden
                            },
                            onDismiss: {
                                coordinator.radialMenuState = .hidden
                            }
                        )
                    }

                    // Pencil debug overlay
                    if let debugInfo = pencil.debugInfo, pencil.isDebugOverlayVisible {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Force: \(debugInfo.rawForce, specifier: "%.2f")")
                            Text("Strength: \(debugInfo.mappedStrength, specifier: "%.2f")")
                            Text("Azimuth: \(debugInfo.rawAzimuth, specifier: "%.2f") rad")
                        }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(8)
                        .background(.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding()
                    }

                    // Quality toast
                    if showQualityToast {
                        VStack {
                            Text("Quality adjusted for performance")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.black.opacity(0.8))
                                .clipShape(Capsule())
                                .padding(.top, 60)
                            Spacer()
                        }
                        .transition(.opacity)
                    }

                    // Canvas HUD (bottom-left, above toolbar)
                    VStack {
                        Spacer()
                        HStack {
                            CanvasHUD(
                                nodeCount: fieldManager.nodes.count,
                                particleCount: engine.particleCount,
                                onTap: { showCanvasSettings = true }
                            )
                            Spacer()
                        }
                        .padding(.leading, 16)
                        .padding(.bottom, 70)
                    }

                    // Palette selector overlay
                    if showPaletteSelector {
                        VStack {
                            Spacer()
                            PaletteSelector(
                                activePaletteIndex: engine.activePaletteIndex,
                                onSelect: { index in
                                    engine.activePaletteIndex = index
                                }
                            )
                            .padding(.horizontal, 12)
                            .padding(.bottom, 80)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Bottom toolbar
                    VStack {
                        Spacer()
                        HStack(spacing: 16) {
                            toolbarButton(icon: "square.grid.2x2", label: "Presets") {
                                savedConfigs = persistenceManager.loadAll()
                                showPresetGallery = true
                            }

                            toolbarButton(icon: "waveform.path", label: "Behavior") {
                                showBehaviorPicker = true
                            }

                            toolbarButton(
                                icon: "paintpalette",
                                label: "Palette",
                                isActive: showPaletteSelector
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showPaletteSelector.toggle()
                                }
                            }

                            toolbarButton(icon: "square.and.arrow.down", label: "Save") {
                                saveCurrentConfig(engine: engine)
                            }

                            toolbarButton(icon: "square.and.arrow.up", label: "Export") {
                                showExportControls = true
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.bottom, 8)
                    }
                } else {
                    Color.black.ignoresSafeArea()
                }
            }
            .sheet(isPresented: $showBehaviorPicker) {
                BehaviorPicker(currentBehavior: currentBehavior) { behavior in
                    currentBehavior = behavior
                    engine?.setBehavior(behavior)
                    showBehaviorPicker = false
                }
            }
            .sheet(isPresented: $showPresetGallery) {
                PresetGallery(
                    bundledPresets: bundledPresets,
                    savedConfigs: savedConfigs,
                    onLoad: { config in
                        loadConfig(config)
                        showPresetGallery = false
                    },
                    onDelete: { id in
                        try? persistenceManager.delete(id: id)
                        savedConfigs = persistenceManager.loadAll()
                    }
                )
            }
            .sheet(isPresented: $showCanvasSettings) {
                if let engine, let budget = particleBudget {
                    CanvasSettingsSheet(
                        particleCount: engine.particleCount,
                        maxParticles: budget.maxParticles,
                        currentBehavior: currentBehavior,
                        onSelectBehavior: { behavior in
                            currentBehavior = behavior
                            engine.setBehavior(behavior)
                        },
                        onClearNodes: {
                            fieldManager.replaceNodes([])
                            engine.clearAccumulationTexture()
                            showCanvasSettings = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showExportControls) {
                if let engine, let budget = particleBudget {
                    ExportControls(
                        engine: engine,
                        budget: budget,
                        screenSize: geometry.size,
                        videoExporter: videoExporter
                    )
                }
            }
            .task {
                setupEngine()
            }
            .onChange(of: engine?.qualityReduced) { _, reduced in
                guard reduced == true else { return }
                withAnimation { showQualityToast = true }
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation { showQualityToast = false }
                    engine?.qualityReduced = false
                }
            }
        }
    }

    // MARK: - Toolbar Button

    private func toolbarButton(
        icon: String,
        label: String,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isActive ? .cyan : .white.opacity(0.8))
            .frame(minWidth: 48)
        }
    }

    // MARK: - Setup

    private func setupEngine() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        let budget = detectParticleBudget()
        self.particleBudget = budget

        guard let newEngine = try? MetalEngine(device: device, particleCount: budget.maxParticles) else { return }

        newEngine.paletteProvider = { [newEngine] in
            guard newEngine.activePaletteIndex < palettes.count else { return nil }
            return palettes[newEngine.activePaletteIndex]
        }
        newEngine.updatePaletteBuffer()
        newEngine.fieldManager = fieldManager

        let coordinator = GestureCoordinator(fieldManager: fieldManager, engine: newEngine)
        let pencil = PencilInputHandler(fieldManager: fieldManager)

        self.engine = newEngine
        self.gestureCoordinator = coordinator
        self.pencilHandler = pencil
        self.bundledPresets = persistenceManager.loadBundledPresets()
        self.savedConfigs = persistenceManager.loadAll()
    }

    // MARK: - Config Actions

    private func loadConfig(_ config: FieldConfig) {
        guard let engine else { return }
        fieldManager.replaceNodes(config.nodes)
        engine.setBehavior(config.behavior)
        engine.activePaletteIndex = config.paletteIndex
        engine.simParams.noiseScale = config.noiseScale
        currentBehavior = config.behavior
        engine.clearAccumulationTexture()
    }

    private func saveCurrentConfig(engine: MetalEngine) {
        let config = FieldConfig(
            name: "Config \(savedConfigs.count + 1)",
            nodes: fieldManager.nodes,
            behavior: currentBehavior,
            paletteIndex: engine.activePaletteIndex,
            noiseScale: engine.simParams.noiseScale,
            thumbnailData: engine.renderThumbnail()
        )
        try? persistenceManager.save(config)
        savedConfigs = persistenceManager.loadAll()
    }
}
