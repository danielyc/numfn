import CoreGraphics

typealias KeyCode = CGKeyCode

enum ANSIKeyCode {
    static let a: KeyCode = 0
    static let s: KeyCode = 1
    static let d: KeyCode = 2
    static let f: KeyCode = 3
    static let g: KeyCode = 5
    static let h: KeyCode = 4
    static let z: KeyCode = 6
    static let x: KeyCode = 7
    static let c: KeyCode = 8
    static let v: KeyCode = 9
    static let b: KeyCode = 11
    static let q: KeyCode = 12
    static let w: KeyCode = 13
    static let e: KeyCode = 14
    static let r: KeyCode = 15
    static let y: KeyCode = 16
    static let t: KeyCode = 17
    static let one: KeyCode = 18
    static let two: KeyCode = 19
    static let three: KeyCode = 20
    static let four: KeyCode = 21
    static let six: KeyCode = 22
    static let five: KeyCode = 23
    static let equal: KeyCode = 24
    static let nine: KeyCode = 25
    static let seven: KeyCode = 26
    static let minus: KeyCode = 27
    static let eight: KeyCode = 28
    static let zero: KeyCode = 29
    static let o: KeyCode = 31
    static let u: KeyCode = 32
    static let i: KeyCode = 34
    static let p: KeyCode = 35
    static let l: KeyCode = 37
    static let j: KeyCode = 38
    static let k: KeyCode = 40
    static let n: KeyCode = 45
    static let m: KeyCode = 46
    static let grave: KeyCode = 50
}

enum KeypadKeyCode {
    static let decimal: KeyCode = 65
    static let multiply: KeyCode = 67
    static let plus: KeyCode = 69
    static let divide: KeyCode = 75
    static let enter: KeyCode = 76
    static let minus: KeyCode = 78
    static let zero: KeyCode = 82
    static let one: KeyCode = 83
    static let two: KeyCode = 84
    static let three: KeyCode = 85
    static let four: KeyCode = 86
    static let five: KeyCode = 87
    static let six: KeyCode = 88
    static let seven: KeyCode = 89
    static let eight: KeyCode = 91
    static let nine: KeyCode = 92
}

enum NavigationKeyCode {
    static let `return`: KeyCode = 36
    static let tab: KeyCode = 48
    static let leftArrow: KeyCode = 123
    static let rightArrow: KeyCode = 124
    static let downArrow: KeyCode = 125
    static let upArrow: KeyCode = 126
}

struct KeyCodeOption: Identifiable, Hashable {
    let code: KeyCode
    let label: String

    var id: KeyCode { code }
}

enum KeyCatalog {
    static let editableSources: [KeyCodeOption] = [
        .init(code: ANSIKeyCode.q, label: "Q"),
        .init(code: ANSIKeyCode.w, label: "W"),
        .init(code: ANSIKeyCode.e, label: "E"),
        .init(code: ANSIKeyCode.r, label: "R"),
        .init(code: ANSIKeyCode.t, label: "T"),
        .init(code: ANSIKeyCode.y, label: "Y"),
        .init(code: ANSIKeyCode.a, label: "A"),
        .init(code: ANSIKeyCode.s, label: "S"),
        .init(code: ANSIKeyCode.d, label: "D"),
        .init(code: ANSIKeyCode.f, label: "F"),
        .init(code: ANSIKeyCode.g, label: "G"),
        .init(code: ANSIKeyCode.h, label: "H"),
        .init(code: ANSIKeyCode.grave, label: "`~"),
        .init(code: ANSIKeyCode.z, label: "Z"),
        .init(code: ANSIKeyCode.x, label: "X"),
        .init(code: ANSIKeyCode.c, label: "C"),
        .init(code: ANSIKeyCode.v, label: "V"),
        .init(code: ANSIKeyCode.b, label: "B"),
        .init(code: ANSIKeyCode.n, label: "N"),
        .init(code: ANSIKeyCode.m, label: "M")
    ]

    static let editableOutputs: [KeyCodeOption] = [
        .init(code: KeypadKeyCode.seven, label: "Keypad 7"),
        .init(code: KeypadKeyCode.eight, label: "Keypad 8"),
        .init(code: KeypadKeyCode.nine, label: "Keypad 9"),
        .init(code: KeypadKeyCode.four, label: "Keypad 4"),
        .init(code: KeypadKeyCode.five, label: "Keypad 5"),
        .init(code: KeypadKeyCode.six, label: "Keypad 6"),
        .init(code: KeypadKeyCode.one, label: "Keypad 1"),
        .init(code: KeypadKeyCode.two, label: "Keypad 2"),
        .init(code: KeypadKeyCode.three, label: "Keypad 3"),
        .init(code: KeypadKeyCode.zero, label: "Keypad 0"),
        .init(code: KeypadKeyCode.decimal, label: "Keypad ."),
        .init(code: KeypadKeyCode.minus, label: "Keypad -"),
        .init(code: KeypadKeyCode.plus, label: "Keypad +"),
        .init(code: KeypadKeyCode.multiply, label: "Keypad *"),
        .init(code: KeypadKeyCode.divide, label: "Keypad /"),
        .init(code: KeypadKeyCode.enter, label: "Keypad Enter"),
        .init(code: NavigationKeyCode.leftArrow, label: "Left Arrow"),
        .init(code: NavigationKeyCode.rightArrow, label: "Right Arrow"),
        .init(code: NavigationKeyCode.downArrow, label: "Down Arrow"),
        .init(code: NavigationKeyCode.upArrow, label: "Up Arrow"),
        .init(code: NavigationKeyCode.tab, label: "Tab"),
        .init(code: NavigationKeyCode.return, label: "Return")
    ]

    static func label(for code: KeyCode) -> String {
        if let option = (editableSources + editableOutputs).first(where: { $0.code == code }) {
            return option.label
        }

        return "Key \(code)"
    }
}
