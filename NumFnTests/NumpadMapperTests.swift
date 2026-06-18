import XCTest
@testable import NumFn

final class NumpadMapperTests: XCTestCase {
    private let mapper = NumpadMapper()
    private let layout = NumpadLayout.numbersOnly

    func testNumbersOnlyLayoutMapsLeftHandGridToNumpadDigits() {
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.q, layout: layout), KeypadKeyCode.seven)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.w, layout: layout), KeypadKeyCode.eight)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.e, layout: layout), KeypadKeyCode.nine)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.a, layout: layout), KeypadKeyCode.four)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.s, layout: layout), KeypadKeyCode.five)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.d, layout: layout), KeypadKeyCode.six)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.z, layout: layout), KeypadKeyCode.one)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.x, layout: layout), KeypadKeyCode.two)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.c, layout: layout), KeypadKeyCode.three)
    }

    func testNumbersOnlyLayoutMapsZeroAndLeavesOperatorsUnmapped() {
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.v, layout: layout), KeypadKeyCode.zero)
        XCTAssertNil(mapper.mappedKeyCode(for: ANSIKeyCode.g, layout: layout))
        XCTAssertNil(mapper.mappedKeyCode(for: ANSIKeyCode.r, layout: layout))
        XCTAssertNil(mapper.mappedKeyCode(for: ANSIKeyCode.f, layout: layout))
    }

    func testUnmappedKeyPassesThrough() {
        XCTAssertNil(mapper.mappedKeyCode(for: 49, layout: layout))
    }

    func testPresetLayoutsIncludeNumbersOnlyAndNumpad() throws {
        let presetIDs = NumpadLayout.presets.map(\.id)

        XCTAssertEqual(presetIDs, [
            NumpadLayout.numbersOnly.id,
            NumpadLayout.numpad.id
        ])

        XCTAssertEqual(try XCTUnwrap(NumpadLayout.presets.first).kind, .preset)
        XCTAssertEqual(NumpadLayout.numpad.kind, .preset)
        XCTAssertEqual(NumFnSettings.default.selectedLayoutID, NumpadLayout.numbersOnly.id)
    }

    func testEditableSourceTopRowIncludesYAfterT() {
        let topRowLabels = KeyCatalog.editableSources.prefix(6).map(\.label)

        XCTAssertEqual(topRowLabels, ["Q", "W", "E", "R", "T", "Y"])
    }

    func testNumpadPresetMapsDigitsOperatorsDecimalAndKeypadEnter() {
        let layout = NumpadLayout.numpad

        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.q, layout: layout), KeypadKeyCode.seven)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.s, layout: layout), KeypadKeyCode.five)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.v, layout: layout), KeypadKeyCode.zero)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.f, layout: layout), KeypadKeyCode.plus)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.r, layout: layout), KeypadKeyCode.minus)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.t, layout: layout), KeypadKeyCode.multiply)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.b, layout: layout), KeypadKeyCode.divide)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.g, layout: layout), KeypadKeyCode.decimal)
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.grave, layout: layout), KeypadKeyCode.enter)
        XCTAssertNil(mapper.mappedKeyCode(for: ANSIKeyCode.h, layout: layout))
        XCTAssertNil(mapper.mappedKeyCode(for: ANSIKeyCode.m, layout: layout))
    }

    func testCustomLayoutCanChangeSourceAndOutputKeys() {
        let layout = NumpadLayout.numbersOnly
            .updating(
                originalSource: ANSIKeyCode.q,
                entry: NumpadKeyMapping(source: ANSIKeyCode.t, output: KeypadKeyCode.enter)
            )

        XCTAssertNil(mapper.mappedKeyCode(for: ANSIKeyCode.q, layout: layout))
        XCTAssertEqual(mapper.mappedKeyCode(for: ANSIKeyCode.t, layout: layout), KeypadKeyCode.enter)
        XCTAssertEqual(layout.kind, .custom)
    }

    func testCustomSettingsSaveLoadRoundTrip() throws {
        let suiteName = "app.numfn.tests.\(UUID().uuidString)"
        let store = try NumFnSettingsStore(suiteName: suiteName)
        defer {
            store.clear()
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }

        let customLayout = NumpadLayout(
            id: "custom-accounting",
            name: "Accounting",
            kind: .custom,
            entries: [
                NumpadKeyMapping(source: ANSIKeyCode.q, output: KeypadKeyCode.one),
                NumpadKeyMapping(source: ANSIKeyCode.w, output: KeypadKeyCode.two),
                NumpadKeyMapping(source: ANSIKeyCode.e, output: KeypadKeyCode.three),
                NumpadKeyMapping(source: ANSIKeyCode.f, output: KeypadKeyCode.plus)
            ]
        )
        let settings = NumFnSettings(
            isEnabled: false,
            activationKey: .option,
            activationMode: .toggle,
            selectedLayoutID: customLayout.id,
            launchAtLogin: true,
            customLayouts: [customLayout]
        )

        try store.save(settings)

        let loaded = store.load()
        XCTAssertEqual(loaded, settings)
        XCTAssertEqual(loaded.layout, customLayout)
        XCTAssertEqual(loaded.layout.mappings, customLayout.mappings)
    }

    func testDisabledSettingsPassThroughMappedKeys() {
        let settings = NumFnSettings(
            isEnabled: false,
            activationKey: .function,
            activationMode: .hold,
            selectedLayoutID: NumpadLayout.numbersOnly.id,
            launchAtLogin: false,
            hasCompletedOnboarding: false,
            customLayouts: []
        )

        XCTAssertNil(settings.mappedKeyCode(for: ANSIKeyCode.q))
    }

    func testCreateCustomLayoutTracksSourceAndSelectsCustomPreset() throws {
        var settings = NumFnSettings.default

        let customLayout = try XCTUnwrap(settings.createCustomLayout(
            from: NumpadLayout.numpad.id,
            name: "Accounting"
        ))

        XCTAssertEqual(customLayout.kind, .custom)
        XCTAssertEqual(customLayout.name, "Accounting")
        XCTAssertEqual(customLayout.sourceLayoutID, NumpadLayout.numpad.id)
        XCTAssertEqual(customLayout.entries, NumpadLayout.numpad.entries)
        XCTAssertEqual(settings.selectedLayoutID, customLayout.id)
        XCTAssertEqual(settings.layout, customLayout)
    }

    func testCreateEmptyCustomLayoutSelectsPresetWithoutMappings() throws {
        var settings = NumFnSettings.default

        let customLayout = settings.createEmptyCustomLayout(name: "Scratch")

        XCTAssertEqual(customLayout.kind, .custom)
        XCTAssertEqual(customLayout.name, "Scratch")
        XCTAssertNil(customLayout.sourceLayoutID)
        XCTAssertTrue(customLayout.entries.isEmpty)
        XCTAssertEqual(settings.selectedLayoutID, customLayout.id)
        XCTAssertEqual(settings.layout, customLayout)
    }

    func testCustomLayoutNamesStayUniqueWhenCreatedAndRenamed() throws {
        var settings = NumFnSettings.default

        let first = try XCTUnwrap(settings.createCustomLayout(
            from: NumpadLayout.numbersOnly.id,
            name: "Accounting"
        ))
        let second = try XCTUnwrap(settings.createCustomLayout(
            from: NumpadLayout.numbersOnly.id,
            name: "Accounting"
        ))

        XCTAssertEqual(first.name, "Accounting")
        XCTAssertEqual(second.name, "Accounting 2")

        settings.renameCustomLayout(id: second.id, name: "Accounting")
        XCTAssertEqual(settings.layout(id: second.id)?.name, "Accounting 2")
    }

    func testResetCustomLayoutRestoresItsSourceMappings() throws {
        var settings = NumFnSettings.default
        let customLayout = try XCTUnwrap(settings.createCustomLayout(
            from: NumpadLayout.numbersOnly.id,
            name: "Custom"
        ))
        let edited = customLayout.updating(
            originalSource: ANSIKeyCode.q,
            entry: NumpadKeyMapping(source: ANSIKeyCode.q, output: KeypadKeyCode.one)
        )
        settings.saveCustomLayout(edited)

        XCTAssertEqual(settings.layout.mapping(for: ANSIKeyCode.q), KeypadKeyCode.one)

        settings.resetCustomLayout(id: customLayout.id)

        XCTAssertEqual(settings.layout.mapping(for: ANSIKeyCode.q), KeypadKeyCode.seven)
    }

    func testDuplicatedCustomLayoutResetsToCustomSource() throws {
        var settings = NumFnSettings.default
        let customLayout = try XCTUnwrap(settings.createCustomLayout(
            from: NumpadLayout.numbersOnly.id,
            name: "Accounting"
        ))
        let edited = customLayout.updating(
            originalSource: ANSIKeyCode.q,
            entry: NumpadKeyMapping(source: ANSIKeyCode.q, output: KeypadKeyCode.one)
        )
        settings.saveCustomLayout(edited)

        let duplicate = try XCTUnwrap(settings.duplicateLayout(id: edited.id))
        let changedDuplicate = duplicate.updating(
            originalSource: ANSIKeyCode.q,
            entry: NumpadKeyMapping(source: ANSIKeyCode.q, output: KeypadKeyCode.nine)
        )
        settings.saveCustomLayout(changedDuplicate)

        XCTAssertEqual(settings.layout.mapping(for: ANSIKeyCode.q), KeypadKeyCode.nine)

        settings.resetCustomLayout(id: duplicate.id)

        XCTAssertEqual(settings.layout.mapping(for: ANSIKeyCode.q), KeypadKeyCode.one)
        XCTAssertEqual(settings.layout.sourceLayoutID, edited.id)
    }


    func testDeleteSelectedCustomLayoutFallsBackToDefaultPreset() throws {
        var settings = NumFnSettings.default
        let customLayout = try XCTUnwrap(settings.createCustomLayout(
            from: NumpadLayout.numpad.id,
            name: "Sheet Custom"
        ))

        settings.deleteCustomLayout(id: customLayout.id)

        XCTAssertTrue(settings.customLayouts.isEmpty)
        XCTAssertEqual(settings.selectedLayoutID, NumpadLayout.numbersOnly.id)
    }

    @MainActor
    func testAppStateRejectsDuplicateSourceEdits() throws {
        let customLayout = NumpadLayout(
            id: "custom-test",
            name: "Custom",
            kind: .custom,
            sourceLayoutID: NumpadLayout.numbersOnly.id,
            entries: NumpadLayout.numbersOnly.entries
        )
        let settings = NumFnSettings(
            isEnabled: false,
            activationKey: .function,
            activationMode: .hold,
            selectedLayoutID: customLayout.id,
            launchAtLogin: false,
            hasCompletedOnboarding: true,
            customLayouts: [customLayout]
        )
        let appState = AppState(
            settings: settings,
            launchAtLoginService: FakeLaunchAtLoginService()
        )

        appState.updateSelectedLayoutMapping(
            originalSource: ANSIKeyCode.q,
            source: ANSIKeyCode.w,
            output: KeypadKeyCode.one
        )

        XCTAssertEqual(appState.settings.layout.mapping(for: ANSIKeyCode.q), KeypadKeyCode.seven)
        XCTAssertEqual(appState.settings.layout.mapping(for: ANSIKeyCode.w), KeypadKeyCode.eight)
        XCTAssertNotNil(appState.layoutEditorMessage)
    }

    @MainActor
    func testLaunchAtLoginFailureRollsBackPersistedToggle() {
        let service = FakeLaunchAtLoginService(error: FakeLaunchAtLoginService.TestError.denied)
        let appState = AppState(
            settings: NumFnSettings.default,
            launchAtLoginService: service
        )

        appState.setLaunchAtLoginEnabled(true)

        XCTAssertFalse(appState.isLaunchAtLoginEnabled)
        XCTAssertFalse(appState.settings.launchAtLogin)
        XCTAssertNotNil(appState.launchAtLoginError)
    }
}

@MainActor
private final class FakeLaunchAtLoginService: LaunchAtLoginControlling {
    enum TestError: LocalizedError {
        case denied

        var errorDescription: String? {
            "Registration denied."
        }
    }

    var status: LaunchAtLoginService.RegistrationStatus
    private let error: Error?

    init(
        status: LaunchAtLoginService.RegistrationStatus = .disabled,
        error: Error? = nil
    ) {
        self.status = status
        self.error = error
    }

    func setEnabled(_ isEnabled: Bool) throws {
        if let error {
            throw error
        }

        status = isEnabled ? .enabled : .disabled
    }
}
