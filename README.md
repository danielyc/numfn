# NumFn

Turn your compact Mac keyboard into a numpad layer.

[numfn.app](https://numfn.app) | [Privacy](https://numfn.app/privacy/) | [Contact](https://numfn.app/contact/)

NumFn is a lightweight macOS menu bar app for MacBooks and compact keyboards. Hold Fn and use the left side of your keyboard for numpad-style numbers and operators. Release Fn and your keyboard goes back to normal typing.

## Features

- Menu bar app for macOS
- Fn hold mode for temporary numpad input
- Numbers Only and Numpad built-in presets
- Custom preset editing
- Optional launch at login
- Local settings stored with UserDefaults
- No analytics, telemetry, network features, keystroke logging, or keystroke transmission

Global keyboard remapping requires macOS Accessibility permission and may also require Input Monitoring approval depending on system settings.

## Download

The current macOS download is available from [numfn.app](https://numfn.app).

## Build From Source

Requirements:

- macOS 14 or newer
- Xcode 26.3 or newer
- Swift 6.2 toolchain from Xcode
- XcodeGen 2.45 or newer

Generate the Xcode project:

```sh
xcodegen generate
```

Build and test from the command line:

```sh
xcodebuild -project NumFn.xcodeproj -scheme NumFn -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build test
```

`NumFn.xcodeproj` is generated from `project.yml` and is not committed. Update `project.yml` and rerun `xcodegen generate` when project structure changes.

## Project Layout

```text
NumFn/
  App/        App lifecycle, menu bar, launch-at-login, and runtime state
  Keyboard/   Key codes, layouts, settings, event tap, and mapping logic
  Resources/  Info.plist, privacy manifest, entitlements, and app assets
  UI/         SwiftUI settings, onboarding, permissions, presets, and privacy panes
NumFnTests/   Unit tests for mapping, settings, and app state behavior
project.yml   XcodeGen project specification
```

## Built-In Presets

Numbers Only:

```text
Q W E  ->  7 8 9
A S D  ->  4 5 6
Z X C  ->  1 2 3
V      ->  0
```

Numpad:

```text
Q W E  ->  7 8 9
A S D  ->  4 5 6
Z X C  ->  1 2 3
V      ->  0
G      ->  .
R F    ->  - +
T B    ->  * /
`      ->  Keypad Enter
```

## Contributing

Before opening a pull request, run:

```sh
xcodegen generate
xcodebuild -project NumFn.xcodeproj -scheme NumFn -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build test
```

Keep generated build output, local Xcode user data, and signing files out of commits. The repository `.gitignore` is configured for the generated Xcode project, `DerivedData`, local signing material, and other developer-only files.

## Privacy

NumFn remaps keys locally on your Mac. It does not collect personal data, analytics, telemetry, tracking data, keystroke logs, or keystroke transmission.

See the public privacy policy at [numfn.app/privacy](https://numfn.app/privacy/).

## License

NumFn is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE).
