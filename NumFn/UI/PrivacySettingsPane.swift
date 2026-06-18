import SwiftUI

struct PrivacySettingsPane: View {
    var body: some View {
        SettingsPane(
            title: "Privacy",
            subtitle: "NumFn keeps keyboard remapping on your Mac.",
            symbolName: SettingsSection.privacy.symbolName,
            tint: SettingsSection.privacy.tint
        ) {
            SettingsGroup("Data") {
                PrivacyPoint(symbolName: "network.slash", text: "No network connections.")
                PrivacyPoint(symbolName: "chart.bar.xaxis", text: "No analytics or telemetry.")
                PrivacyPoint(symbolName: "keyboard.badge.ellipsis", text: "No keystroke logging.")
                PrivacyPoint(symbolName: "paperplane", text: "NumFn never sends what you type.")
                PrivacyPoint(symbolName: "internaldrive", text: "Settings are saved on this Mac.")
            }

            SettingsGroup("Policy") {
                if let privacyPolicyURL {
                    Link(destination: privacyPolicyURL) {
                        Label("Privacy Policy", systemImage: "arrow.up.right.square")
                    }
                } else {
                    PrivacyPoint(symbolName: "doc.text", text: "Privacy policy URL is not configured.")
                }
            }
        }
    }

    private var privacyPolicyURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "NumFnPrivacyPolicyURL") as? String else {
            return nil
        }

        return URL(string: value)
    }
}

private struct PrivacyPoint: View {
    let symbolName: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.green)
                .frame(width: 26, height: 26)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(text)
        }
    }
}
