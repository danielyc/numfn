import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var settings: NumFnSettings {
        didSet {
            keyboardLayer.update(settings: settings)
            try? settingsStore.save(settings)
        }
    }

    @Published private(set) var isKeyboardLayerRunning = false
    @Published private(set) var isNumpadActive = false
    @Published private(set) var hasAccessibilityPermission = AccessibilityPermissionManager.isTrusted(prompt: false)
    @Published private(set) var runtimeStatus: AppRuntimeStatus = .disabled
    @Published private(set) var lastError: String?
    @Published private(set) var isLaunchAtLoginEnabled: Bool
    @Published private(set) var launchAtLoginStatus: LaunchAtLoginService.RegistrationStatus
    @Published private(set) var launchAtLoginError: String?
    @Published private(set) var hasCompletedOnboarding: Bool
    @Published private(set) var layoutEditorMessage: String?

    private let keyboardLayer: KeyboardLayerController
    private let launchAtLoginService: any LaunchAtLoginControlling
    private let settingsStore: NumFnSettingsStore

    var onRuntimeStatusChange: (() -> Void)?
    var onNumpadActiveChange: (() -> Void)?

    init(
        settings: NumFnSettings? = nil,
        keyboardLayer: KeyboardLayerController = KeyboardLayerController(),
        launchAtLoginService: any LaunchAtLoginControlling = LaunchAtLoginService(),
        settingsStore: NumFnSettingsStore = NumFnSettingsStore()
    ) {
        let loadedSettings = settings ?? settingsStore.load()
        self.settings = loadedSettings
        self.keyboardLayer = keyboardLayer
        self.launchAtLoginService = launchAtLoginService
        self.settingsStore = settingsStore
        self.isLaunchAtLoginEnabled = loadedSettings.launchAtLogin
        self.launchAtLoginStatus = launchAtLoginService.status
        self.hasCompletedOnboarding = loadedSettings.hasCompletedOnboarding
        self.keyboardLayer.eventTapRecovered = { [weak self] in
            Task { @MainActor in
                self?.handleEventTapRecovered()
            }
        }
        self.keyboardLayer.activationStateChanged = { [weak self] isActive in
            Task { @MainActor in
                self?.handleNumpadActiveChanged(isActive)
            }
        }
    }

    func startKeyboardLayer() {
        hasAccessibilityPermission = AccessibilityPermissionManager.isTrusted(prompt: false)

        guard settings.isEnabled else {
            stopKeyboardLayer()
            return
        }

        guard hasAccessibilityPermission else {
            updateRuntimeStatus(.permissionMissing)
            isKeyboardLayerRunning = false
            return
        }

        do {
            try keyboardLayer.start(settings: settings)
            isKeyboardLayerRunning = true
            updateRuntimeStatus(.running)
        } catch {
            isKeyboardLayerRunning = false
            updateRuntimeStatus(.eventTapFailed(error.localizedDescription))
        }
    }

    func stopKeyboardLayer() {
        keyboardLayer.stop()
        isKeyboardLayerRunning = false
        handleNumpadActiveChanged(false)
        updateRuntimeStatus(.disabled)
    }

    func setEnabled(_ isEnabled: Bool) {
        settings.isEnabled = isEnabled

        if isEnabled {
            startKeyboardLayer()
        } else {
            stopKeyboardLayer()
        }
    }

    func selectLayout(id: NumpadLayout.ID) {
        settings.selectedLayoutID = id
    }

    func resetSelectedLayout() {
        settings.resetSelectedLayout()
        layoutEditorMessage = nil
    }

    func createCustomLayout(named name: String? = nil) {
        let source = settings.layout
        let proposedName = name ?? "\(source.name) Custom"
        _ = settings.createCustomLayout(from: source.id, name: proposedName)
        layoutEditorMessage = nil
    }

    func createEmptyCustomLayout(named name: String) {
        _ = settings.createEmptyCustomLayout(name: name)
        layoutEditorMessage = nil
    }

    func duplicateSelectedLayout() {
        _ = settings.duplicateLayout(id: settings.selectedLayoutID)
        layoutEditorMessage = nil
    }

    func renameSelectedCustomLayout(to name: String) {
        guard settings.layout.kind == .custom else {
            return
        }

        settings.renameCustomLayout(id: settings.selectedLayoutID, name: name)
        layoutEditorMessage = nil
    }

    func deleteSelectedCustomLayout() {
        guard settings.layout.kind == .custom else {
            return
        }

        settings.deleteCustomLayout(id: settings.selectedLayoutID)
        layoutEditorMessage = nil
    }

    func resetSelectedCustomLayoutToSource() {
        guard settings.layout.kind == .custom else {
            return
        }

        settings.resetCustomLayout(id: settings.selectedLayoutID)
        layoutEditorMessage = nil
    }

    func updateSelectedLayoutMapping(source: KeyCode, output: KeyCode) {
        updateSelectedLayoutMapping(originalSource: source, source: source, output: output)
    }

    func updateSelectedLayoutMapping(originalSource: KeyCode, source: KeyCode, output: KeyCode) {
        if originalSource != source, settings.layout.entries.contains(where: { $0.source == source }) {
            layoutEditorMessage = "\(KeyCatalog.label(for: source)) is already mapped. Clear that key before reusing it."
            return
        }

        let editableLayout = editableSelectedLayout()
        let updated = editableLayout.updating(
            originalSource: originalSource,
            entry: NumpadKeyMapping(source: source, output: output)
        )
        settings.saveCustomLayout(updated)
        layoutEditorMessage = nil
    }

    func clearSelectedLayoutMapping(source: KeyCode) {
        removeMapping(source: source)
    }

    func addMapping() {
        let existingSources = Set(settings.layout.entries.map(\.source))
        guard
            let source = KeyCatalog.editableSources.first(where: { !existingSources.contains($0.code) })?.code,
            let output = KeyCatalog.editableOutputs.first?.code
        else {
            return
        }

        updateSelectedLayoutMapping(source: source, output: output)
    }

    func removeMapping(source: KeyCode) {
        let editableLayout = editableSelectedLayout()
        settings.saveCustomLayout(editableLayout.removing(source: source))
        layoutEditorMessage = nil
    }

    func requestAccessibilityPermission() {
        hasAccessibilityPermission = AccessibilityPermissionManager.isTrusted(prompt: true)
        if hasAccessibilityPermission, settings.isEnabled {
            startKeyboardLayer()
        } else if settings.isEnabled {
            updateRuntimeStatus(.permissionMissing)
        }
    }

    func openAccessibilitySettings() {
        AccessibilityPermissionManager.openSystemSettings()
    }

    func refreshPermissions() {
        hasAccessibilityPermission = AccessibilityPermissionManager.isTrusted(prompt: false)
        if hasAccessibilityPermission, settings.isEnabled, !isKeyboardLayerRunning {
            startKeyboardLayer()
        } else if !settings.isEnabled {
            updateRuntimeStatus(.disabled)
        } else if !hasAccessibilityPermission {
            updateRuntimeStatus(.permissionMissing)
        }
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginStatus = launchAtLoginService.status
    }

    func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        do {
            try launchAtLoginService.setEnabled(isEnabled)
            isLaunchAtLoginEnabled = isEnabled
            settings.launchAtLogin = isEnabled
            launchAtLoginError = nil
        } catch {
            isLaunchAtLoginEnabled = settings.launchAtLogin
            launchAtLoginError = error.localizedDescription
        }

        refreshLaunchAtLoginStatus()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        settings.hasCompletedOnboarding = true
    }

    func showOnboardingHelp() {
        hasCompletedOnboarding = false
        settings.hasCompletedOnboarding = false
    }

    func retryKeyboardLayer() {
        startKeyboardLayer()
    }

    private func updateRuntimeStatus(_ status: AppRuntimeStatus) {
        runtimeStatus = status
        lastError = switch status {
        case .disabled, .running:
            nil
        case .permissionMissing, .eventTapFailed:
            status.detail
        }
        onRuntimeStatusChange?()
    }

    private func handleEventTapRecovered() {
        guard settings.isEnabled, hasAccessibilityPermission else {
            return
        }

        isKeyboardLayerRunning = true
        updateRuntimeStatus(.running)
    }

    private func handleNumpadActiveChanged(_ isActive: Bool) {
        guard isNumpadActive != isActive else {
            return
        }

        isNumpadActive = isActive
        onNumpadActiveChange?()
    }

    private func editableSelectedLayout() -> NumpadLayout {
        let layout = settings.layout
        guard layout.kind == .preset else {
            return layout
        }

        var nextSettings = settings
        if let customLayout = nextSettings.createCustomLayout(
            from: layout.id,
            name: "\(layout.name) Custom"
        ) {
            settings = nextSettings
            return customLayout
        }

        return layout
    }
}
