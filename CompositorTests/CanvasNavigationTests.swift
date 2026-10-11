import AppKit
import Testing
@testable import Compositor

/// Exercise the native input handlers across actual-pixel zoom, with an off-center anchor.
@MainActor struct CanvasNavigationTests {
    private func canvas() -> (EditorSession, CanvasView) {
        let session = EditorSession()
        session.viewport.resize(to: CGSize(width: 1000, height: 800), backingScale: 2, documentSize: nil)
        session.createDocument(width: 1920, height: 1080)
        session.zoom(to: 1)
        let view = CanvasView(session: session)
        view.frame = CGRect(x: 0, y: 0, width: 1000, height: 800)
        return (session, view)
    }

    @Test func pinchCrossesActualPixelsAndSurvivesResize() throws {
        let (session, view) = canvas()
        let size = try #require(session.document?.size)
        let point = CGPoint(x: 350, y: 300)
        let anchor = view.convert(point, from: nil)
        session.zoom(to: 0.8)
        let pixel = session.viewport.documentPoint(from: anchor, documentSize: size)
        view.magnify(with: NavigationEvent(point: point, magnification: 0.5))
        #expect(session.viewport.zoom > 1, "pinching crosses 100%")
        expectAnchor(pixel, at: anchor, in: session, size: size)
        view.magnify(with: NavigationEvent(point: point, magnification: 0.25))
        #expect(abs(session.viewport.zoom - 1.5) < 0.000001)
        expectAnchor(pixel, at: anchor, in: session, size: size)
        session.viewport.resize(to: CGSize(width: 800, height: 600), backingScale: 2, documentSize: size)
        #expect(abs(session.viewport.zoom - 1.5) < 0.000001, "layout does not reset the gesture to fit or 100%")
    }

    @Test(arguments: [NSEvent.ModifierFlags.command, .option], [false, true])
    func modifiedScrollCrossesActualPixels(flags: NSEvent.ModifierFlags, precise: Bool) throws {
        let (session, view) = canvas()
        let size = try #require(session.document?.size)
        let point = CGPoint(x: 350, y: 300)
        let anchor = view.convert(point, from: nil)
        let pixel = session.viewport.documentPoint(from: anchor, documentSize: size)
        view.scrollWheel(with: NavigationEvent(point: point, flags: flags, scrollY: -12, precise: precise))
        #expect(session.viewport.zoom > 1)
        expectAnchor(pixel, at: anchor, in: session, size: size)
        view.scrollWheel(with: NavigationEvent(point: point, flags: flags, scrollY: 12, precise: precise))
        #expect(abs(session.viewport.zoom - 1) < 0.000001)
        expectAnchor(pixel, at: anchor, in: session, size: size)
    }

    @Test(arguments: [false, true])
    func unmodifiedScrollPansWithoutChangingZoom(precise: Bool) {
        let (session, view) = canvas()
        let before = session.viewport.pan
        view.scrollWheel(with: NavigationEvent(point: CGPoint(x: 350, y: 300), scrollY: 12, precise: precise))
        #expect(session.viewport.zoom == 1)
        #expect(session.viewport.pan != before)
        #expect(!session.viewport.followsFit)
    }

    @Test func zoomToolClickAndDragCrossActualPixels() throws {
        let (session, view) = canvas()
        session.selectTool(.zoom)
        let point = CGPoint(x: 350, y: 300)
        func mouse(_ type: NSEvent.EventType, at point: CGPoint, flags: NSEvent.ModifierFlags = []) throws -> NSEvent {
            try #require(NSEvent.mouseEvent(with: type, location: point, modifierFlags: flags, timestamp: 0,
                windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
        }
        view.mouseDown(with: try mouse(.leftMouseDown, at: point))
        view.mouseUp(with: try mouse(.leftMouseUp, at: point))
        #expect(session.viewport.zoom == 2)
        view.mouseDown(with: try mouse(.leftMouseDown, at: point, flags: .option))
        view.mouseUp(with: try mouse(.leftMouseUp, at: point, flags: .option))
        #expect(session.viewport.zoom == 1)
        view.mouseDown(with: try mouse(.leftMouseDown, at: point))
        let end = CGPoint(x: point.x + 100, y: point.y)
        view.mouseDragged(with: try mouse(.leftMouseDragged, at: end))
        view.mouseUp(with: try mouse(.leftMouseUp, at: end))
        #expect(session.viewport.zoom == 2)
    }

    private func expectAnchor(_ pixel: CGPoint, at anchor: CGPoint, in session: EditorSession, size: CGSize) {
        let after = session.viewport.documentPoint(from: anchor, documentSize: size)
        #expect(abs(after.x - pixel.x) < 0.000001 && abs(after.y - pixel.y) < 0.000001)
    }
}

/// AppKit has no public pinch-event factory. This test event stays inside the test canvas;
/// it does not synthesize input for the user's desktop or establish hardware gesture delivery.
private final class NavigationEvent: NSEvent {
    private let point: CGPoint
    private let flags: NSEvent.ModifierFlags
    private let amount: CGFloat
    private let scroll: CGFloat
    private let precise: Bool

    init(point: CGPoint, flags: NSEvent.ModifierFlags = [], magnification: CGFloat = 0,
         scrollY: CGFloat = 0, precise: Bool = true) {
        self.point = point
        self.flags = flags
        self.amount = magnification
        self.scroll = scrollY
        self.precise = precise
        super.init()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var locationInWindow: NSPoint { point }
    override var modifierFlags: NSEvent.ModifierFlags { flags }
    override var magnification: CGFloat { amount }
    override var scrollingDeltaX: CGFloat { 0 }
    override var scrollingDeltaY: CGFloat { scroll }
    override var hasPreciseScrollingDeltas: Bool { precise }
}
