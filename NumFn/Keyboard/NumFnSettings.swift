import Foundation

struct NumFnSettings: Codable, Equatable {
    var isEnabled: Bool
    var activationKey: ActivationKey
    var activationMode: ActivationMode
    var selectedLayoutID: NumpadLayout.ID
    var launchAtLogin: Bool
    var hasCompletedOnboarding: Bool
    var customLayouts: [NumpadLayout]

    var layout: NumpadLayout {
        layout(id: selectedLayoutID) ?? .numbersOnly
    }

    var availableLayouts: [NumpadLayout] {
        NumpadLayout.presets + customLayouts
    }

    var selectedLayout: NumpadLayout {
        layout
    }

    static let `default` = NumFnSettings(
        isEnabled: true,
        activationKey: .function,
        activationMode: .hold,
        selectedLayoutID: NumpadLayout.numbersOnly.id,
        launchAtLogin: false,
        hasCompletedOnboarding: false,
        customLayouts: []
    )

    init(
        isEnabled: Bool,
        activationKey: ActivationKey,
        activationMode: ActivationMode,
        selectedLayoutID: NumpadLayout.ID,
        launchAtLogin: Bool,
        hasCompletedOnboarding: Bool = false,
        customLayouts: [NumpadLayout]
    ) {
        self.isEnabled = isEnabled
        self.activationKey = activationKey
        self.activationMode = activationMode
        self.selectedLayoutID = selectedLayoutID
        self.launchAtLogin = launchAtLogin
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.customLayouts = customLayouts
    }

    func layout(id: NumpadLayout.ID) -> NumpadLayout? {
        customLayouts.first { $0.id == id }
            ?? NumpadLayout.presets.first { $0.id == id }
    }

    func mappedKeyCode(for keyCode: KeyCode) -> KeyCode? {
        guard isEnabled else {
            return nil
        }

        return layout.mappings[keyCode]
    }

    mutating func resetSelectedLayout() {
        selectedLayoutID = NumpadLayout.numbersOnly.id
    }

    mutating func saveCustomLayout(_ layout: NumpadLayout) {
        var customLayout = layout
        customLayout.kind = .custom

        if let index = customLayouts.firstIndex(where: { $0.id == customLayout.id }) {
            customLayouts[index] = customLayout
        } else {
            customLayouts.append(customLayout)
        }

        selectedLayoutID = customLayout.id
    }

    mutating func createCustomLayout(from sourceLayoutID: NumpadLayout.ID, name: String) -> NumpadLayout? {
        guard let sourceLayout = layout(id: sourceLayoutID) else {
            return nil
        }

        let customLayout = NumpadLayout(
            id: "custom-\(UUID().uuidString)",
            name: uniqueCustomLayoutName(name),
            kind: .custom,
            sourceLayoutID: sourceLayout.id,
            entries: sourceLayout.entries
        )
        saveCustomLayout(customLayout)
        return customLayout
    }

    mutating func createEmptyCustomLayout(name: String) -> NumpadLayout {
        let customLayout = NumpadLayout(
            id: "custom-\(UUID().uuidString)",
            name: uniqueCustomLayoutName(name),
            kind: .custom,
            entries: []
        )
        saveCustomLayout(customLayout)
        return customLayout
    }

    mutating func duplicateLayout(id layoutID: NumpadLayout.ID) -> NumpadLayout? {
        guard let sourceLayout = layout(id: layoutID) else {
            return nil
        }

        return createCustomLayout(
            from: sourceLayout.id,
            name: "\(sourceLayout.name) Copy"
        )
    }

    mutating func renameCustomLayout(id layoutID: NumpadLayout.ID, name: String) {
        guard let index = customLayouts.firstIndex(where: { $0.id == layoutID }) else {
            return
        }

        customLayouts[index].name = uniqueCustomLayoutName(name, excluding: layoutID)
    }

    mutating func deleteCustomLayout(id layoutID: NumpadLayout.ID) {
        customLayouts.removeAll { $0.id == layoutID }
        if selectedLayoutID == layoutID {
            selectedLayoutID = NumpadLayout.numbersOnly.id
        }
    }

    mutating func resetCustomLayout(id layoutID: NumpadLayout.ID) {
        guard
            let index = customLayouts.firstIndex(where: { $0.id == layoutID }),
            let sourceLayoutID = customLayouts[index].sourceLayoutID,
            let sourceLayout = layout(id: sourceLayoutID)
        else {
            return
        }

        customLayouts[index].entries = sourceLayout.entries
    }

    func canAddMapping(to layout: NumpadLayout) -> Bool {
        let existingSources = Set(layout.entries.map(\.source))
        return KeyCatalog.editableSources.contains { !existingSources.contains($0.code) }
    }

    func uniqueCustomLayoutName(_ proposedName: String) -> String {
        uniqueCustomLayoutName(proposedName, excluding: nil)
    }

    private func uniqueCustomLayoutName(_ proposedName: String, excluding layoutID: NumpadLayout.ID?) -> String {
        let trimmedName = proposedName.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = trimmedName.isEmpty ? "Custom Preset" : trimmedName
        let existingNames = Set(customLayouts
            .filter { $0.id != layoutID }
            .map(\.name))

        guard existingNames.contains(baseName) else {
            return baseName
        }

        var suffix = 2
        while existingNames.contains("\(baseName) \(suffix)") {
            suffix += 1
        }

        return "\(baseName) \(suffix)"
    }
}

enum ActivationKey: String, Codable, CaseIterable, Identifiable {
    case function = "Fn"
    case option = "Option"
    case command = "Command"
    case control = "Control"

    var id: String { rawValue }
}

enum ActivationMode: String, Codable, CaseIterable, Identifiable {
    case hold = "Hold"
    case toggle = "Toggle"

    var id: String { rawValue }
}

struct NumFnSettingsStore {
    enum StoreError: Error {
        case invalidUserDefaultsSuite
    }

    private let userDefaults: UserDefaults
    private let key: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        userDefaults: UserDefaults = .standard,
        key: String = "app.numfn.settings.v1",
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.userDefaults = userDefaults
        self.key = key
        self.encoder = encoder
        self.decoder = decoder
    }

    init(suiteName: String, key: String = "app.numfn.settings.v1") throws {
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw StoreError.invalidUserDefaultsSuite
        }

        self.init(userDefaults: userDefaults, key: key)
    }

    func load() -> NumFnSettings {
        guard
            let data = userDefaults.data(forKey: key),
            let settings = try? decoder.decode(NumFnSettings.self, from: data)
        else {
            return .default
        }

        return settings
    }

    func save(_ settings: NumFnSettings) throws {
        let data = try encoder.encode(settings)
        userDefaults.set(data, forKey: key)
    }

    func clear() {
        userDefaults.removeObject(forKey: key)
    }
}
