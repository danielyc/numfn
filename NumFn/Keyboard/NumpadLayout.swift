import Foundation

struct NumpadKeyMapping: Codable, Equatable, Identifiable {
    var id: String { "\(source)-\(output)" }
    var source: KeyCode
    var output: KeyCode
}

struct NumpadLayout: Codable, Equatable, Identifiable {
    enum Kind: String, Codable, Equatable {
        case preset
        case custom
    }

    var id: String
    var name: String
    var kind: Kind
    var sourceLayoutID: String?
    var entries: [NumpadKeyMapping]

    var mappings: [KeyCode: KeyCode] {
        entries.reduce(into: [:]) { mappings, entry in
            mappings[entry.source] = entry.output
        }
    }

    func mapping(for source: KeyCode) -> KeyCode? {
        mappings[source]
    }

    init(
        id: String,
        name: String,
        kind: Kind,
        sourceLayoutID: String? = nil,
        entries: [NumpadKeyMapping]
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.sourceLayoutID = sourceLayoutID
        self.entries = entries
    }

    init(
        id: String,
        name: String,
        kind: Kind,
        sourceLayoutID: String? = nil,
        mappings: [KeyCode: KeyCode]
    ) {
        self.init(
            id: id,
            name: name,
            kind: kind,
            sourceLayoutID: sourceLayoutID,
            entries: mappings
                .sorted { $0.key < $1.key }
                .map { NumpadKeyMapping(source: $0.key, output: $0.value) }
        )
    }

    static let numbersOnlyID = "left-hand-default"
    static let numpadID = "numpad"

    private static let numberEntries = [
        NumpadKeyMapping(source: ANSIKeyCode.q, output: KeypadKeyCode.seven),
        NumpadKeyMapping(source: ANSIKeyCode.w, output: KeypadKeyCode.eight),
        NumpadKeyMapping(source: ANSIKeyCode.e, output: KeypadKeyCode.nine),
        NumpadKeyMapping(source: ANSIKeyCode.a, output: KeypadKeyCode.four),
        NumpadKeyMapping(source: ANSIKeyCode.s, output: KeypadKeyCode.five),
        NumpadKeyMapping(source: ANSIKeyCode.d, output: KeypadKeyCode.six),
        NumpadKeyMapping(source: ANSIKeyCode.z, output: KeypadKeyCode.one),
        NumpadKeyMapping(source: ANSIKeyCode.x, output: KeypadKeyCode.two),
        NumpadKeyMapping(source: ANSIKeyCode.c, output: KeypadKeyCode.three),
        NumpadKeyMapping(source: ANSIKeyCode.v, output: KeypadKeyCode.zero)
    ]

    static let numbersOnly = NumpadLayout(
        id: numbersOnlyID,
        name: "Numbers only",
        kind: .preset,
        entries: numberEntries
    )

    static let numpad = NumpadLayout(
        id: numpadID,
        name: "Numpad",
        kind: .preset,
        entries: numberEntries + [
            NumpadKeyMapping(source: ANSIKeyCode.g, output: KeypadKeyCode.decimal),
            NumpadKeyMapping(source: ANSIKeyCode.r, output: KeypadKeyCode.minus),
            NumpadKeyMapping(source: ANSIKeyCode.f, output: KeypadKeyCode.plus),
            NumpadKeyMapping(source: ANSIKeyCode.t, output: KeypadKeyCode.multiply),
            NumpadKeyMapping(source: ANSIKeyCode.b, output: KeypadKeyCode.divide),
            NumpadKeyMapping(source: ANSIKeyCode.grave, output: KeypadKeyCode.enter)
        ]
    )

    static let presets: [NumpadLayout] = [
        .numbersOnly,
        .numpad
    ]

    func updating(entry: NumpadKeyMapping) -> NumpadLayout {
        updating(originalSource: entry.source, entry: entry)
    }

    func updating(originalSource: KeyCode, entry: NumpadKeyMapping) -> NumpadLayout {
        var copy = self
        copy.entries.removeAll { $0.source == originalSource || $0.source == entry.source }
        copy.entries.append(entry)
        copy.entries.sort { $0.source < $1.source }
        copy.kind = .custom
        return copy
    }

    func removing(source: KeyCode) -> NumpadLayout {
        var copy = self
        copy.entries.removeAll { $0.source == source }
        copy.kind = .custom
        return copy
    }
}
