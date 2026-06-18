import Foundation
import ServiceManagement

@MainActor
protocol LaunchAtLoginControlling {
    var status: LaunchAtLoginService.RegistrationStatus { get }
    func setEnabled(_ isEnabled: Bool) throws
}

@MainActor
final class LaunchAtLoginService: LaunchAtLoginControlling {
    enum RegistrationStatus: Equatable {
        case unavailable
        case disabled
        case enabled
        case requiresApproval
        case notFound
        case unknown

        var title: String {
            switch self {
            case .unavailable:
                "Unavailable"
            case .disabled:
                "Off"
            case .enabled:
                "On"
            case .requiresApproval:
                "Needs Approval"
            case .notFound:
                "Not Found"
            case .unknown:
                "Unknown"
            }
        }

        var detail: String {
            switch self {
            case .unavailable:
                "Launch at login is not available on this version of macOS."
            case .disabled:
                "NumFn will not open automatically when you log in."
            case .enabled:
                "NumFn will open automatically when you log in."
            case .requiresApproval:
                "Allow NumFn in System Settings before it can open at login."
            case .notFound:
                "macOS could not find NumFn in the launch-at-login list."
            case .unknown:
                "macOS returned an unknown launch-at-login status."
            }
        }
    }

    enum ServiceError: LocalizedError {
        case unavailable

        var errorDescription: String? {
            switch self {
            case .unavailable:
                "Launch at login is not available on this version of macOS."
            }
        }
    }

    var status: RegistrationStatus {
        guard #available(macOS 13.0, *) else {
            return .unavailable
        }

        switch SMAppService.mainApp.status {
        case .notRegistered:
            return .disabled
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .notFound
        @unknown default:
            return .unknown
        }
    }

    func setEnabled(_ isEnabled: Bool) throws {
        guard #available(macOS 13.0, *) else {
            throw ServiceError.unavailable
        }

        if isEnabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
