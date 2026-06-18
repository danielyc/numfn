import Foundation

struct NumpadMapper {
    func mappedKeyCode(for keyCode: KeyCode, layout: NumpadLayout) -> KeyCode? {
        layout.mappings[keyCode]
    }
}
