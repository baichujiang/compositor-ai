import Foundation
import CoreGraphics

nonisolated enum AICommandKind: String, Codable, CaseIterable, Sendable {
    case selectLayer = "select_layer", opacity = "set_opacity", rename = "rename_layer"
    case visibility = "set_visibility", move = "move_layer", scale = "scale_layer"
    case rotate = "rotate_layer", blend = "set_blend_mode"
    case exposure = "set_exposure", saturation = "set_saturation", blackWhite = "black_white"
    case undo, redo, zoom = "set_zoom"
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
        if case .message(let value) = self { return value }
        return nil
    }
}

/// Capturing values also catches edits made inside an unfinished native history transaction.
struct AIDocumentToken {
    let document: CanvasDocument
    let revision: UUID
    init(session: EditorSession) throws {
        guard let document = session.document else { throw AIAssistantError.message("Open or create a canvas first.") }
        self.document = document
        revision = session.history.currentRevision
    }
    func check(_ session: EditorSession) throws {
        guard session.document == document, session.history.currentRevision == revision else {
            throw AIAssistantError.message("The document changed while AI was working. Send the request again using the current canvas.")
        }
    }
}

/// Versioned, in-process editor API. Model output never becomes shell code or arbitrary method calls.
enum AIEditorCommands {
    private enum Prepared {
        case select(UUID), opacity(UUID, Double), rename(UUID, String), visibility(UUID, Bool)
        case transform(UUID, LayerTransform), blend(UUID, LayerBlendMode)
        case adjustment(UUID, LayerAdjustment), insert(ImageLayer), zoom(Double)
    }

    @discardableResult static func apply(_ plan: AIEditPlan, to session: EditorSession, token: AIDocumentToken) throws -> Int {
        guard plan.version == 1, plan.actions.count <= 20, plan.reply.count <= 4_000 else {
            throw AIAssistantError.message("Unsupported AI command format. Nothing was changed.")
        }
        try token.check(session)
        if plan.actions.isEmpty { return 0 }
        guard session.canEditLayers, session.effectsEditing == nil, session.colorPicker == nil, session.opacityEditLayerID == nil else {
            throw AIAssistantError.message("Finish the current edit or close the editing dialog before applying AI changes.")
        }
        if plan.actions.contains(where: { $0.kind == .undo || $0.kind == .redo }) {
            guard plan.actions.count == 1 else { throw AIAssistantError.message("Undo and redo must be requested separately.") }
            if plan.actions[0].kind == .undo {
                guard session.canUndo else { throw AIAssistantError.message("There is nothing to undo.") }
                session.undo()
            } else {
                guard session.canRedo else { throw AIAssistantError.message("There is nothing to redo.") }
                session.redo()
            }
            return 1
        }
        // Validate the entire sequence against a value copy before touching the live document.
        var draft = token.document
        var prepared: [Prepared] = []
        for action in plan.actions {
            func number(_ value: Double?, _ range: ClosedRange<Double>) throws -> Double {
                guard let value, value.isFinite, range.contains(value) else {
                    throw AIAssistantError.message("An AI parameter is missing or out of range. Nothing was changed.")
                }
                return value
            }
            func index() throws -> Int {
                guard let id = action.layerID, let i = draft.layers.firstIndex(where: { $0.id == id }) else {
                    throw AIAssistantError.message("AI referenced a missing layer. Nothing was changed.")
                }
                return i
            }
            switch action.kind {
            case .selectLayer: prepared.append(.select(draft.layers[try index()].id))
            case .opacity:
                let i = try index(), value = try number(action.value, 0...100) / 100
                draft.layers[i].opacity = value
                prepared.append(.opacity(draft.layers[i].id, value))
            case .rename:
                let i = try index(), name = action.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard !name.isEmpty, name.count <= 200 else { throw AIAssistantError.message("A layer name must contain 1–200 characters.") }
                draft.layers[i].name = name
                prepared.append(.rename(draft.layers[i].id, name))
            case .visibility:
                let i = try index()
                guard let value = action.visible else { throw AIAssistantError.message("A visibility value is missing.") }
                draft.layers[i].isVisible = value
                prepared.append(.visibility(draft.layers[i].id, value))
            case .move, .scale, .rotate:
                let i = try index(), layer = draft.layers[i]
                guard let asset = layer.asset, !layer.isGroup, draft.effectiveVisibleIDs.contains(layer.id) else {
                    throw AIAssistantError.message("AI can transform visible image, shape, and text layers. Show a hidden layer first; transform folders manually.")
                }
                var transform = layer.transform
                switch action.kind {
                case .move:
                    transform.origin = CGPoint(x: try number(action.x, -1_000_000...1_000_000), y: try number(action.y, -1_000_000...1_000_000))
                case .scale:
                    let value = try number(action.value, 0.01...10_000)
                    transform = transform.scaled(toPercent: value, pixelSize: CGSize(width: asset.image.width, height: asset.image.height))
                default: transform.rotation = try number(action.value, -360...360)
                }
                guard transform.isValid else { throw AIAssistantError.message("The requested transform exceeds editor limits.") }
                draft.layers[i].transform = transform
                prepared.append(.transform(layer.id, transform))
            case .blend:
                let i = try index()
                guard !draft.layers[i].isGroup, let text = action.text, let mode = LayerBlendMode(rawValue: text) else {
                    throw AIAssistantError.message("AI requested an unsupported blend mode.")
                }
                draft.layers[i].blendMode = mode
                prepared.append(.blend(draft.layers[i].id, mode))
            case .exposure, .saturation, .blackWhite:
                let kind: AdjustmentKind = action.kind == .exposure ? .exposure : action.kind == .saturation ? .hsv : .blackWhite
                let existing = try action.layerID.map { _ in try index() }
                if let existing, draft.layers[existing].adjustment?.kind != kind {
                    throw AIAssistantError.message("The selected adjustment layer has a different type.")
                }
                var adjustment = existing.flatMap { draft.layers[$0].adjustment } ?? LayerAdjustment(kind: kind)
                if kind == .exposure { adjustment.exposure.exposure = try number(action.value, -5...5) }
                if kind == .hsv {
                    let value = try number(action.value, -100...100)
                    adjustment.saturation = value
                    var hsv = adjustment.resolvedHSV
                    hsv.adjustments[.master, default: RangeAdjustment()].saturation = value
                    adjustment.hsvSettings = hsv
                }
                guard adjustment.isValid else { throw AIAssistantError.message("The adjustment parameters are invalid.") }
                if let existing {
                    draft.layers[existing].adjustment = adjustment
                    prepared.append(.adjustment(draft.layers[existing].id, adjustment))
                } else {
                    guard draft.layers.count < 10_000 else { throw AIAssistantError.message("The document has too many layers.") }
                    var layer = ImageLayer(name: "AI " + kind.rawValue, blankSize: draft.size)
                    layer.adjustment = adjustment
                    draft.layers.append(layer)
                    prepared.append(.insert(layer))
                }
            case .zoom: prepared.append(.zoom(try number(action.value, 1...1600) / 100))
            case .undo, .redo: break
            }
        }
        session.beginEdit("AI Edit")
        defer { session.endEdit() }
        for command in prepared {
            switch command {
            case .select(let id): session.selectLayer(id)
            case .opacity(let id, let value): session.selectLayer(id); session.setLayerOpacity(value)
            case .rename(let id, let name): session.renameLayer(id, to: name)
            case .visibility(let id, let value):
                if session.document?.layers.first(where: { $0.id == id })?.isVisible != value { session.toggleLayerVisibility(id) }
            case .transform(let id, let value):
                session.selectLayer(id)
                session.isMaskSelected = false
                session.beginTransform(persistent: false)
                session.previewTransform(value)
                session.commitTransform()
            case .blend(let id, let value): session.selectLayer(id); session.setLayerBlendMode(value)
            case .adjustment(let id, let value): session.updateAdjustment(id, value: value)
            case .insert(let layer): session.document?.layers.append(layer); session.selectLayer(layer.id)
            case .zoom(let value): session.zoom(to: value)
            }
        }
        session.brushRevision += 1
        session.refreshCanvasPreview?()
        return prepared.count
    }

    static func context(_ session: EditorSession) throws -> String {
        guard let document = session.document else { throw AIAssistantError.message("Open or create a canvas first.") }
        let data: [String: Any] = ["apiVersion": 1, "canvas": ["width": document.width, "height": document.height],
            "selectedLayerID": session.activeLayerID?.uuidString as Any? ?? NSNull(),
            "canUndo": session.canUndo, "canRedo": session.canRedo,
            "blendModes": LayerBlendMode.allCases.map(\.rawValue),
            "layersBottomToTop": document.layers.map { layer in
                ["id": layer.id.uuidString, "name": layer.name, "group": layer.isGroup,
                 "parentID": layer.parentID?.uuidString as Any? ?? NSNull(),
                 "visible": document.effectiveVisibleIDs.contains(layer.id), "opacityPercent": layer.opacity * 100,
                 "x": layer.transform.origin.x, "y": layer.transform.origin.y,
                 "width": layer.size.width, "height": layer.size.height,
                 "rotationDegrees": layer.transform.rotation,
                 "originalWidth": layer.asset?.image.width as Any? ?? NSNull(),
                 "originalHeight": layer.asset?.image.height as Any? ?? NSNull(),
                 "blendMode": layer.blendMode.rawValue,
                 "adjustment": layer.adjustment?.kind.rawValue as Any? ?? NSNull(),
                 "exposureStops": layer.adjustment?.exposure.exposure as Any? ?? NSNull(),
                 "saturation": layer.adjustment?.resolvedHSV.adjustments[.master]?.saturation as Any? ?? NSNull()] as [String: Any]
            }]
        return String(decoding: try JSONSerialization.data(withJSONObject: data, options: [.sortedKeys]), as: UTF8.self)
    }
}
