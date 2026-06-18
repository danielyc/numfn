import Foundation

enum AppRuntimeStatus: Equatable {
    case disabled
    case permissionMissing
    case eventTapFailed(String)
    case running

    var title: String {
        switch self {
        case .disabled:
            "Off"
        case .permissionMissing:
            "Needs Permission"
        case .eventTapFailed:
            "Needs Attention"
        case .running:
            "Ready"
        }
    }

    var menuBarTitle: String {
        "NumFn: \(title)"
    }

    var detail: String {
        switch self {
        case .disabled:
            "NumFn is off, so it is not changing any keys."
        case .permissionMissing:
            "Allow Accessibility access before NumFn can remap keys."
        case .eventTapFailed(let message):
            message
        case .running:
            "NumFn is ready and waiting for the activation key."
        }
    }
}
