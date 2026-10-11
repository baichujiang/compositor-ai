import AppKit
import Testing
@testable import Compositor

@MainActor
struct AIEditorCommandsTests {
    private func session() throws -> EditorSession {
        let session = EditorSession()
        session.createDocument(width: 100, height: 80)
        let context = try #require(CGContext(data: nil, width: 20, height: 20, bitsPerComponent: 8, bytesPerRow: 80,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        let image = try #require(context.makeImage())
        session.insert(ImportedImage(image: image, thumbnail: image, name: "Moon"))
        return session
    }

    @Test func multiCommandEditIsOneNativeUndoStep() throws {
        let session = try session(), id = try #require(session.activeLayerID)
        let original = session.document, count = session.history.undoCount
        let plan = AIEditPlan(reply: "Updated", actions: [
            AIEditorCommand(kind: .opacity, layerID: id, value: 65),
            AIEditorCommand(kind: .rename, layerID: id, text: "Moon on peak"),
            AIEditorCommand(kind: .scale, layerID: id, value: 200),
            AIEditorCommand(kind: .move, layerID: id, x: 32, y: 12),
            AIEditorCommand(kind: .rotate, layerID: id, value: 30)])
        try AIEditorCommands.apply(plan, to: session, token: AIDocumentToken(session: session))
        #expect(session.activeLayer?.opacity == 0.65)
        #expect(session.activeLayer?.name == "Moon on peak")
        #expect(session.activeLayer?.origin == CGPoint(x: 32, y: 12))
        #expect(session.activeLayer?.size == CGSize(width: 40, height: 40))
        #expect(session.activeLayer?.transform.rotation == 30)
        #expect(session.history.undoCount == count + 1)
        #expect(session.transformEdit == nil)
        let changed = session.document
        session.undo()
        #expect(session.document == original)
        session.redo()
        #expect(session.document == changed)
    }

    @Test func invalidLaterCommandLeavesEverythingUntouched() throws {
        let session = try session(), id = try #require(session.activeLayerID)
        let original = session.document, count = session.history.undoCount, selected = session.activeLayerID
        let plan = AIEditPlan(reply: "", actions: [AIEditorCommand(kind: .opacity, layerID: id, value: 10),
            AIEditorCommand(kind: .rename, layerID: UUID(), text: "Missing")])
        #expect(throws: AIAssistantError.self) {
            try AIEditorCommands.apply(plan, to: session, token: AIDocumentToken(session: session))
        }
        #expect(session.document == original && session.activeLayerID == selected)
        #expect(session.history.undoCount == count)
    }

    @Test func stalePlansCannotOverwriteManualEditsOrAnotherDocument() throws {
        let session = try session(), id = try #require(session.activeLayerID)
        let token = try AIDocumentToken(session: session)
        let plan = AIEditPlan(reply: "", actions: [AIEditorCommand(kind: .opacity, layerID: id, value: 10)])
        session.renameLayer(id, to: "Manual name")
        #expect(throws: AIAssistantError.self) { try AIEditorCommands.apply(plan, to: session, token: token) }
        #expect(session.activeLayer?.name == "Manual name" && session.activeLayer?.opacity == 1)
        session.createDocument(width: 100, height: 80)
        #expect(throws: AIAssistantError.self) { try AIEditorCommands.apply(plan, to: session, token: token) }
    }

    @Test func rejectsInvalidNumbersHistoryMixingAndOpenEdits() throws {
        let session = try session(), id = try #require(session.activeLayerID)
        for command in [AIEditorCommand(kind: .opacity, layerID: id, value: .nan),
            AIEditorCommand(kind: .move, layerID: id, x: .infinity, y: 0),
            AIEditorCommand(kind: .scale, layerID: id, value: 0),
            AIEditorCommand(kind: .zoom, value: 0)] {
            let original = session.document
            #expect(throws: AIAssistantError.self) {
                try AIEditorCommands.apply(AIEditPlan(reply: "", actions: [command]), to: session, token: AIDocumentToken(session: session))
            }
            #expect(session.document == original)
        }
        #expect(throws: AIAssistantError.self) {
            try AIEditorCommands.apply(AIEditPlan(reply: "", actions: [AIEditorCommand(kind: .undo), AIEditorCommand(kind: .opacity, layerID: id, value: 30)]),
                to: session, token: AIDocumentToken(session: session))
        }
        session.beginOpacityEdit()
        #expect(throws: AIAssistantError.self) {
            try AIEditorCommands.apply(AIEditPlan(reply: "", actions: [AIEditorCommand(kind: .rename, layerID: id, text: "Blocked")]),
                to: session, token: AIDocumentToken(session: session))
        }
        session.finishOpacityEdit()
    }

    @Test func nativeMaskPlacementIsPreservedDuringTransform() throws {
        let session = try session(), id = try #require(session.activeLayerID)
        session.addLayerMask()
        session.isMaskSelected = true
        let before = try #require(session.document)
        try AIEditorCommands.apply(AIEditPlan(reply: "", actions: [AIEditorCommand(kind: .move, layerID: id, x: 10, y: 12)]),
            to: session, token: AIDocumentToken(session: session))
        #expect(session.activeLayer?.origin == CGPoint(x: 10, y: 12))
        #expect(session.activeLayer?.mask?.isLinked == true && session.activeLayer?.mask?.placement == nil)
        #expect(session.activeLayer?.mask?.asset.image === before.layers.last?.mask?.asset.image)
        session.undo()
        #expect(session.document == before)
    }

    @Test func adjustmentsUseExistingFormatAndPreserveOtherSettings() async throws {
        let session = try session(), before = session.history.undoCount
        try AIEditorCommands.apply(AIEditPlan(reply: "", actions: [AIEditorCommand(kind: .exposure, value: 0.4),
            AIEditorCommand(kind: .saturation, value: -20)]), to: session, token: AIDocumentToken(session: session))
        #expect(session.history.undoCount == before + 1 && session.adjustmentEditingID == nil)
        let layers = try #require(session.document?.layers)
        let exposure = try #require(layers.first { $0.adjustment?.kind == .exposure })
        let hsv = try #require(layers.first { $0.adjustment?.kind == .hsv })
        #expect(exposure.adjustment?.exposure.exposure == 0.4 && exposure.parentID == nil)
        var adjustment = try #require(hsv.adjustment)
        var settings = adjustment.resolvedHSV
        settings.adjustments[.reds] = RangeAdjustment(hue: 25, saturation: 12, lightness: 5)
        adjustment.hsvSettings = settings
        session.updateAdjustment(hsv.id, value: adjustment)
        try AIEditorCommands.apply(AIEditPlan(reply: "", actions: [AIEditorCommand(kind: .saturation, layerID: hsv.id, value: 40)]),
            to: session, token: AIDocumentToken(session: session))
        let changed = try #require(session.document?.layers.first { $0.id == hsv.id }?.adjustment)
        #expect(changed.resolvedHSV.adjustments[.reds] == settings.adjustments[.reds])
        #expect(changed.resolvedHSV.adjustments[.master]?.saturation == 40)
        let snapshot = try #require(session.projectSnapshot())
        #expect(snapshot.manifest.version == 11)
        let raster = try await ImageExporter.shared.render(snapshot)
        #expect(raster.image.width == 100 && raster.image.height == 80)
    }

    @Test func visibilitySequenceMatchesNativeTransformRules() throws {
        let session = try session(), id = try #require(session.activeLayerID)
        let original = session.document
        #expect(throws: AIAssistantError.self) {
            try AIEditorCommands.apply(AIEditPlan(reply: "", actions: [AIEditorCommand(kind: .visibility, layerID: id, visible: false),
                AIEditorCommand(kind: .move, layerID: id, x: 5, y: 5)]), to: session, token: AIDocumentToken(session: session))
        }
        #expect(session.document == original)
        session.toggleLayerVisibility(id)
        try AIEditorCommands.apply(AIEditPlan(reply: "", actions: [AIEditorCommand(kind: .visibility, layerID: id, visible: true),
            AIEditorCommand(kind: .move, layerID: id, x: 5, y: 5)]), to: session, token: AIDocumentToken(session: session))
        #expect(session.activeLayer?.isVisible == true && session.activeLayer?.origin == CGPoint(x: 5, y: 5))
    }

    @Test func protocolAndContextAreValidJSON() throws {
        let session = try session()
        let context = try #require(JSONSerialization.jsonObject(with: Data(AIEditorCommands.context(session).utf8)) as? [String: Any])
        #expect(context["apiVersion"] as? Int == 1)
        let schema = try #require(JSONSerialization.jsonObject(with: AIPlanningContract.schema()) as? [String: Any])
        #expect(schema["additionalProperties"] as? Bool == false)
        let json = """
        {"version":1,"reply":"请明确图层","actions":[]}
        """
        let plan = try JSONDecoder().decode(AIEditPlan.self, from: Data(json.utf8))
        #expect(plan.actions.isEmpty)
        #expect(throws: AIAssistantError.self) {
            try AIEditorCommands.apply(AIEditPlan(version: 2, reply: "", actions: []), to: session, token: AIDocumentToken(session: session))
        }
    }
}
