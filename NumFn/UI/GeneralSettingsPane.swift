import SwiftUI

struct GeneralSettingsPane: View {
    @EnvironmentObject private var appState: AppState
    @State private var settingsColumnHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            SettingsPane(
                title: "General",
                subtitle: "Control how NumFn runs and starts.",
                symbolName: SettingsSection.general.symbolName,
                tint: SettingsSection.general.tint
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    statusOverview
                    settingsColumns(width: geometry.size.width)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var statusOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    overviewHeader

                    Spacer(minLength: 12)

                    overviewControls(alignment: .trailing)
                }

                VStack(alignment: .leading, spacing: 14) {
                    overviewHeader
                    overviewControls(alignment: .leading)
                }
            }

            Divider()

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    overviewMetrics
                }

                VStack(alignment: .leading, spacing: 12) {
                    overviewMetrics
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(runtimeStatusColor.opacity(0.18))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }

    private var overviewHeader: some View {
        HStack(alignment: .top, spacing: 18) {
            Button {
                enabledBinding.wrappedValue.toggle()
            } label: {
                SymbolBadge(symbolName: runtimeStatusSymbol, tint: runtimeStatusColor, size: 48)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(appState.settings.isEnabled ? "Turn NumFn off" : "Turn NumFn on")
            .accessibilityValue(appState.settings.isEnabled ? "On" : "Off")

            VStack(alignment: .leading, spacing: 10) {
                Text(appState.settings.isEnabled ? "NumFn is On" : "NumFn is Off")
                    .font(.title2.bold())

                Text(runtimeSummary)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                contextualRuntimeAction
            }
        }
    }

    private func overviewControls(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 10) {
            HStack{
                Text(appState.isNumpadActive ? "Numpad active" : "Waiting for activation")
                    .font(.caption)
                    .foregroundStyle(appState.isNumpadActive ? SettingsSection.general.tint : .secondary)

                StatusPill(
                    label: "App status",
                    value: appState.runtimeStatus.title,
                    color: runtimeStatusColor
                )
            }

            Toggle("Listener", isOn: enabledBinding)
                .toggleStyle(.switch)
                .accessibilityLabel(appState.settings.isEnabled ? "Turn NumFn off" : "Turn NumFn on")
                .accessibilityValue(appState.settings.isEnabled ? "On" : "Off")

        }
    }

    @ViewBuilder
    private var overviewMetrics: some View {
        OverviewMetric(
            symbolName: "keyboard",
            title: "Activation",
            value: activationSummary,
            tint: SettingsSection.general.tint
        )

        OverviewMetric(
            symbolName: "rectangle.on.rectangle.angled",
            title: "Preset",
            value: appState.settings.layout.name,
            tint: .teal
        )

        OverviewMetric(
            symbolName: "power",
            title: "Login",
            value: appState.launchAtLoginStatus.title,
            tint: launchAtLoginStatusColor
        )
    }

    @ViewBuilder
    private var contextualRuntimeAction: some View {
        switch appState.runtimeStatus {
        case .eventTapFailed:
            Button {
                appState.retryKeyboardLayer()
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise.circle")
            }
            .buttonStyle(.borderedProminent)
        case .permissionMissing:
            Button {
                appState.openAccessibilitySettings()
            } label: {
                Label("Open System Settings", systemImage: "gearshape")
            }
        case .disabled, .running:
            EmptyView()
        }
    }

    @ViewBuilder
    private func settingsColumns(width: CGFloat) -> some View {
        if width >= 760 {
            let equalHeight = settingsColumnHeight > 0 ? settingsColumnHeight : nil

            HStack(alignment: .top, spacing: 16) {
                activationGroup(minHeight: equalHeight)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .readSettingsColumnHeight()

                launchGroup(minHeight: equalHeight)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .readSettingsColumnHeight()
            }
            .onPreferenceChange(SettingsColumnHeightKey.self) { height in
                if abs(settingsColumnHeight - height) > 0.5 {
                    settingsColumnHeight = height
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 16) {
                activationGroup()
                launchGroup()
            }
        }
    }

    private func activationGroup(minHeight: CGFloat? = nil) -> some View {
        GeneralSettingsCard("Activation", minHeight: minHeight) {
            SettingsControlRow(
                symbolName: "command",
                tint: SettingsSection.general.tint,
                title: "Activation key",
                subtitle: "Choose the key that turns on the numpad layer."
            ) {
                Picker("Activation key", selection: activationKeyBinding) {
                    ForEach(ActivationKey.allCases) { key in
                        Text(key.rawValue).tag(key)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
            }

            SettingsControlRow(
                symbolName: "switch.2",
                tint: SettingsSection.general.tint,
                title: "Mode",
                subtitle: "Hold works while the key is pressed. Toggle stays on until you press it again."
            ) {
                Picker("Mode", selection: activationModeBinding) {
                    ForEach(ActivationMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
        }
    }

    private func launchGroup(minHeight: CGFloat? = nil) -> some View {
        GeneralSettingsCard("Launch at Login", minHeight: minHeight) {
            SettingsControlRow(
                symbolName: "arrow.up.forward.app",
                tint: launchAtLoginStatusColor,
                title: "Open NumFn automatically",
                subtitle: launchSummary
            ) {
                Toggle("Launch at login", isOn: launchAtLoginBinding)
                    .toggleStyle(.switch)
            }

            HStack(spacing: 10) {
                Text("Status")
                Spacer()
                StatusPill(
                    label: "Launch at login status",
                    value: appState.launchAtLoginStatus.title,
                    color: launchAtLoginStatusColor
                )
            }

            if appState.launchAtLoginStatus == .requiresApproval {
                SettingsNotice(
                    symbolName: "exclamationmark.triangle.fill",
                    text: appState.launchAtLoginStatus.detail,
                    tint: .orange
                )
            }

            if let launchAtLoginError = appState.launchAtLoginError {
                SettingsNotice(
                    symbolName: "exclamationmark.triangle.fill",
                    text: launchAtLoginError,
                    tint: .red
                )
            }

            HStack {
                Spacer()

                Button {
                    appState.refreshLaunchAtLoginStatus()
                } label: {
                    Label("Refresh Status", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.isEnabled },
            set: { appState.setEnabled($0) }
        )
    }

    private var activationKeyBinding: Binding<ActivationKey> {
        Binding(
            get: { appState.settings.activationKey },
            set: { appState.settings.activationKey = $0 }
        )
    }

    private var activationModeBinding: Binding<ActivationMode> {
        Binding(
            get: { appState.settings.activationMode },
            set: { appState.settings.activationMode = $0 }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { appState.isLaunchAtLoginEnabled },
            set: { appState.setLaunchAtLoginEnabled($0) }
        )
    }

    private var runtimeStatusColor: Color {
        switch appState.runtimeStatus {
        case .disabled:
            .secondary
        case .permissionMissing, .eventTapFailed:
            .orange
        case .running:
            .green
        }
    }

    private var launchAtLoginStatusColor: Color {
        switch appState.launchAtLoginStatus {
        case .enabled:
            .green
        case .requiresApproval:
            .orange
        case .disabled, .unavailable, .notFound, .unknown:
            .secondary
        }
    }

    private var activationSummary: String {
        "\(appState.settings.activationKey.rawValue) / \(appState.settings.activationMode.rawValue)"
    }

    private var runtimeSummary: String {
        switch appState.runtimeStatus {
        case .disabled:
            "NumFn is off and is not changing keys."
        case .permissionMissing, .eventTapFailed:
            appState.runtimeStatus.detail
        case .running:
            "Ready when you press the activation key."
        }
    }

    private var launchSummary: String {
        switch appState.launchAtLoginStatus {
        case .disabled:
            "Open NumFn manually when you need it."
        case .enabled:
            "NumFn will open automatically when you log in."
        case .requiresApproval, .unavailable, .notFound, .unknown:
            appState.launchAtLoginStatus.detail
        }
    }

    private var runtimeStatusSymbol: String {
        switch appState.runtimeStatus {
        case .disabled:
            "pause.circle"
        case .permissionMissing:
            "lock.trianglebadge.exclamationmark"
        case .eventTapFailed:
            "exclamationmark.triangle"
        case .running:
            "checkmark.circle"
        }
    }
}

private struct StatusPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        Text(value)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .accessibilityLabel(label)
            .accessibilityValue(value)
    }
}

private struct GeneralSettingsCard<Content: View>: View {
    let title: String
    let minHeight: CGFloat?
    @ViewBuilder let content: Content

    init(_ title: String, minHeight: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.minHeight = minHeight
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

private struct SettingsColumnHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension View {
    func readSettingsColumnHeight() -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(key: SettingsColumnHeightKey.self, value: proxy.size.height)
            }
        )
    }
}

private struct OverviewMetric: View {
    let symbolName: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
    }
}

private struct SettingsControlRow<Trailing: View>: View {
    let symbolName: String
    let tint: Color
    let title: String
    let subtitle: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalLayout
            verticalLayout
        }
        .padding(.vertical, 2)
    }

    private var horizontalLayout: some View {
        HStack(alignment: .center, spacing: 12) {
            rowLabel

            Spacer(minLength: 16)

            trailing
                .fixedSize()
        }
    }

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            rowLabel
            trailing
        }
    }

    private var rowLabel: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct SettingsNotice: View {
    let symbolName: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
                .frame(width: 18)
                .accessibilityHidden(true)

            Text(text)
                .foregroundStyle(tint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.callout)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(tint.opacity(0.18))
        )
    }
}
