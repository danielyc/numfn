import SwiftUI

private enum KeyboardGridMetrics {
    static let keyWidth: CGFloat = 80
    static let keyHeight: CGFloat = 62
    static let keySpacing: CGFloat = 8
}

struct PresetCustomizerPane: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedSource: KeyCode = ANSIKeyCode.q
    @State private var newPresetName = "Custom Preset"

    private let gridRows: [[KeyCode]] = [
        [ANSIKeyCode.q, ANSIKeyCode.w, ANSIKeyCode.e, ANSIKeyCode.r, ANSIKeyCode.t, ANSIKeyCode.y],
        [ANSIKeyCode.a, ANSIKeyCode.s, ANSIKeyCode.d, ANSIKeyCode.f, ANSIKeyCode.g, ANSIKeyCode.h],
        [ANSIKeyCode.grave, ANSIKeyCode.z, ANSIKeyCode.x, ANSIKeyCode.c, ANSIKeyCode.v, ANSIKeyCode.b, ANSIKeyCode.n]
    ]

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: true) {
                SettingsPane(
                    title: "Presets",
                    subtitle: "Start with a preset, or make your own.",
                    symbolName: SettingsSection.presets.symbolName,
                    tint: SettingsSection.presets.tint
                ) {
                    VStack(alignment: .leading, spacing: 22) {
                        selectedLayoutHeader
                        keyboardGrid

                        HStack(alignment: .top, spacing: 24) {
                            layoutList
                                .frame(width: 260)

                            VStack(alignment: .leading, spacing: 18) {
                                selectedKeyEditor
                                mappingSummary
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(minWidth: geometry.size.width, alignment: .top)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            if appState.settings.layout.mapping(for: selectedSource) == nil {
                selectedSource = appState.settings.layout.entries.first?.source ?? ANSIKeyCode.q
            }
        }
    }

    private var layoutList: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsGroup("Built-in presets") {
                ForEach(NumpadLayout.presets) { layout in
                    LayoutSelectionButton(layout: layout)
                }
            }

            SettingsGroup("Custom presets") {
                if appState.settings.customLayouts.isEmpty {
                    Text("No custom presets yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appState.settings.customLayouts) { layout in
                        LayoutSelectionButton(layout: layout)
                    }
                }
            }

            SettingsGroup("Create a preset") {
                TextField("Preset name", text: $newPresetName)
                HStack {
                    Button("New") {
                        appState.createEmptyCustomLayout(named: newPresetName)
                        newPresetName = "Custom Preset"
                    }

                    Button("Duplicate Selected") {
                        appState.duplicateSelectedLayout()
                    }
                }
            }
        }
    }

    private var selectedLayoutHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            SymbolBadge(symbolName: "keyboard.badge.eye", tint: SettingsSection.presets.tint, size: 44)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.settings.layout.name)
                            .font(.title2.bold())

                        Text(appState.settings.layout.kind == .custom ? "Custom preset" : "Built-in preset")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(appState.settings.layout.entries.count) mappings")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SettingsSection.presets.tint)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(SettingsSection.presets.tint.opacity(0.12))
                        .clipShape(Capsule())
                }

                Picker("Active preset", selection: selectedLayoutBinding) {
                    ForEach(appState.settings.availableLayouts) { layout in
                        Text(layout.name).tag(layout.id)
                    }
                }
                .frame(maxWidth: 360)
            }

            if appState.settings.layout.kind == .custom {
                HStack(spacing: 12) {
                    TextField("Preset name", text: customNameBinding)
                        .textFieldStyle(.roundedBorder)

                    Button("Reset to Original") {
                        appState.resetSelectedCustomLayoutToSource()
                    }
                    .disabled(appState.settings.layout.sourceLayoutID == nil)

                    Button("Delete") {
                        appState.deleteSelectedCustomLayout()
                    }
                }
            } else {
                HStack {
                    Button("Customize Preset") {
                        appState.createCustomLayout()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Reset to Numbers only") {
                        appState.resetSelectedLayout()
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(SettingsSection.presets.tint.opacity(0.18))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }

    private var keyboardGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(gridRows.indices, id: \.self) { rowIndex in
                HStack(spacing: KeyboardGridMetrics.keySpacing) {
                    ForEach(gridRows[rowIndex], id: \.self) { source in
                        KeyboardKeyTile(
                            source: source,
                            output: appState.settings.layout.mapping(for: source),
                            isSelected: selectedSource == source
                        ) {
                            selectedSource = source
                        }
                    }
                }
                .padding(.leading, rowIndex < 2 ? (KeyboardGridMetrics.keyWidth + KeyboardGridMetrics.keySpacing) - (3 - CGFloat(rowIndex)) * (KeyboardGridMetrics.keyWidth/4) : 0)
            }
        }
        .padding(14)
        .background(Color.primary.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.07))
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Preset keyboard grid")
    }

    private var selectedKeyEditor: some View {
        SettingsGroup("Selected key") {
            StatusRow(
                title: KeyCatalog.label(for: selectedSource),
                value: appState.settings.layout.mapping(for: selectedSource).map(KeyCatalog.label(for:)) ?? "Unmapped",
                color: appState.settings.layout.mapping(for: selectedSource) == nil ? .secondary : .accentColor
            )

            Picker("Output", selection: selectedOutputBinding) {
                ForEach(KeyCatalog.editableOutputs) { option in
                    Text(option.label).tag(option.code)
                }
            }

            HStack {
                Button("Clear Selected Key") {
                    appState.clearSelectedLayoutMapping(source: selectedSource)
                }
                .disabled(appState.settings.layout.mapping(for: selectedSource) == nil)

                Button("Add Next Unmapped Key") {
                    appState.addMapping()
                }
                .disabled(!appState.settings.canAddMapping(to: appState.settings.layout))
            }

            if let message = appState.layoutEditorMessage {
                Text(message)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var mappingSummary: some View {
        SettingsGroup("Mappings") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], alignment: .leading, spacing: 10) {
                ForEach(appState.settings.layout.entries) { entry in
                    HStack {
                        Text(KeyCatalog.label(for: entry.source))
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)
                        Text(KeyCatalog.label(for: entry.output))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.teal.opacity(0.12), Color(nsColor: .controlBackgroundColor)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.06))
                    )
                }
            }
        }
    }

    private var selectedLayoutBinding: Binding<NumpadLayout.ID> {
        Binding(
            get: { appState.settings.selectedLayoutID },
            set: { appState.selectLayout(id: $0) }
        )
    }

    private var customNameBinding: Binding<String> {
        Binding(
            get: { appState.settings.layout.name },
            set: { appState.renameSelectedCustomLayout(to: $0) }
        )
    }

    private var selectedOutputBinding: Binding<KeyCode> {
        Binding(
            get: {
                appState.settings.layout.mapping(for: selectedSource)
                    ?? KeyCatalog.editableOutputs.first?.code
                    ?? selectedSource
            },
            set: { output in
                appState.updateSelectedLayoutMapping(source: selectedSource, output: output)
            }
        )
    }
}

private struct LayoutSelectionButton: View {
    @EnvironmentObject private var appState: AppState
    let layout: NumpadLayout

    var body: some View {
        Button {
            appState.selectLayout(id: layout.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(layout.name)
                    Text(layout.kind == .custom ? "Custom" : "\(layout.entries.count) mappings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if appState.settings.selectedLayoutID == layout.id {
                    Image(systemName: "checkmark")
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(8)
        .background(selectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(appState.settings.selectedLayoutID == layout.id ? Color.accentColor.opacity(0.35) : Color.clear)
        )
    }

    private var selectionBackground: Color {
        appState.settings.selectedLayoutID == layout.id
            ? Color.accentColor.opacity(0.12)
            : Color.clear
    }
}

private struct KeyboardKeyTile: View {
    let source: KeyCode
    let output: KeyCode?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(KeyCatalog.label(for: source))
                    .font(.headline)
                Text(output.map(KeyCatalog.label(for:)) ?? "Unmapped")
                    .font(.caption)
                    .fontWeight(output == nil ? .regular : .semibold)
                    .foregroundStyle(output == nil ? .secondary : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 7)
                    .background(output == nil ? Color.clear : Color.white.opacity(0.32))
                    .clipShape(Capsule())
            }
            .frame(width: KeyboardGridMetrics.keyWidth, height: KeyboardGridMetrics.keyHeight)
            .background(tileBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.20), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: shadowColor, radius: isSelected ? 5 : 2, y: 1)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(KeyCatalog.label(for: source)), \(output.map(KeyCatalog.label(for:)) ?? "unmapped")")
    }

    private var tileBackground: LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: [Color.accentColor.opacity(0.24), Color.accentColor.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if output == nil {
            return LinearGradient(
                colors: [Color(nsColor: .controlBackgroundColor), Color(nsColor: .windowBackgroundColor)],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        return LinearGradient(
            colors: [Color.teal.opacity(0.18), Color(nsColor: .controlBackgroundColor)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var shadowColor: Color {
        isSelected ? Color.accentColor.opacity(0.18) : Color.black.opacity(0.08)
    }
}
