import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                SettingsWorkspaceView()
            } else {
                OnboardingFlowView()
            }
        }
        .environmentObject(appState)
        .frame(minWidth: 880, minHeight: 640)
        .onAppear {
            appState.refreshPermissions()
            appState.refreshLaunchAtLoginStatus()
        }
    }
}

enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case presets = "Presets"
    case permissions = "Permissions"
    case privacy = "Privacy"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .general:
            "slider.horizontal.3"
        case .presets:
            "keyboard"
        case .permissions:
            "accessibility"
        case .privacy:
            "lock.shield"
        }
    }

    var tint: Color {
        switch self {
        case .general:
            .blue
        case .presets:
            .teal
        case .permissions:
            .orange
        case .privacy:
            .green
        }
    }
}

private struct SettingsWorkspaceView: View {
    @State private var selectedSection: SettingsSection = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                Label {
                    Text(section.rawValue)
                } icon: {
                    Image(systemName: section.symbolName)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(section.tint)
                }
                .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            ZStack(alignment: .top) {
                AppBackground(tint: selectedSection.tint)

                switch selectedSection {
                case .general:
                    GeneralSettingsPane()
                case .presets:
                    PresetCustomizerPane()
                case .permissions:
                    PermissionSettingsPane()
                case .privacy:
                    PrivacySettingsPane()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationSplitViewStyle(.balanced)
    }
}
