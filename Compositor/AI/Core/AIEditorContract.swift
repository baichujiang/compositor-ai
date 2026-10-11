import Foundation

nonisolated enum AICommandKind: String, Codable, CaseIterable, Sendable {
    case selectLayer = "select_layer", opacity = "set_opacity", rename = "rename_layer"
    case visibility = "set_visibility", move = "move_layer", scale = "scale_layer"
    case rotate = "rotate_layer", blend = "set_blend_mode"
    case exposure = "set_exposure", saturation = "set_saturation", blackWhite = "black_white"
    case undo, redo, zoom = "set_zoom"

    var title: String {
        switch self {
        case .selectLayer: L("Select Layer")
        case .opacity: L("Opacity")
        case .rename: L("Rename Layer")
        case .visibility: L("Layer Visibility")
        case .move: L("Move Layer")
        case .scale: L("Scale")
        case .rotate: L("Rotate")
        case .blend: L("Blend mode")
        case .exposure: L("Exposure")
        case .saturation: L("Saturation")
        case .blackWhite: L("Black & White")
        case .undo: L("Undo")
        case .redo: L("Redo")
        case .zoom: L("Zoom")
        }
    }
}

nonisolated struct AIEditorCommand: Codable, Sendable {
    var kind: AICommandKind
    var layerID: UUID? = nil
    var value: Double? = nil
    var x: Double? = nil
    var y: Double? = nil
    var text: String? = nil
    var visible: Bool? = nil
}

nonisolated struct AIEditPlan: Codable, Sendable {
    var version: Int = 1
    var reply: String
    var actions: [AIEditorCommand]
}

nonisolated enum AIAssistantError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        if case .message(let value) = self { return L(value) }
        return nil
    }
}
