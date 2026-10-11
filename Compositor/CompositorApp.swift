import SwiftUI

@main
struct CompositorApp: App {
    @NSApplicationDelegateAdaptor(CompositorApplicationDelegate.self) private var applicationDelegate
    @AppStorage("navigator.visible") private var showsNavigator = false
    @AppStorage("ui.interfaceLanguage") private var interfaceLanguage = "zh-Hans"
    private var session: EditorSession { applicationDelegate.session }
    init() { AppLocalization.prepare() }
    var body: some Scene {
        Window("Compositor AI", id: "editor") {
            ProjectWorkspaceView(applicationDelegate: applicationDelegate).roundedControls()
                .environment(\.locale, AppLocalization.locale)
        }
            .defaultSize(width: 1180, height: 780)
            // Files opened from Finder or dropped on the Dock icon go to the app delegate, which imports them into
            // the open window. Left to SwiftUI, each one builds a throwaway window and fades the editor out and back.
            .handlesExternalEvents(matching: [])
            // A first launch fills the screen (without going full screen); after that macOS reopens the window at the
            // size it was left.
            .defaultWindowPlacement { _, context in
                WindowPlacement(size: context.defaultDisplay.visibleRect.size)
            }
            // The project's name is already on its tab, so the toolbar doesn't repeat it as a window title.
            .windowToolbarStyle(.unifiedCompact(showsTitle: false))
            .commands {
                CommandGroup(replacing: .undoRedo) {
                    // Dialog text fields keep native text undo; document history
                    // is unavailable while an import or modal edit is active.
                    if session.textDraft != nil || session.levels != nil || session.isProjectBusy || session.showsNewDocument || session.showsImporter || session.renamingLayerID != nil || session.transformEdit?.persistent == true {
                        Button(L("Undo")) {
                            if NSApp.keyWindow?.firstResponder is NSTextView {
                                NSApp.sendAction(NSSelectorFromString("undo:"), to: nil, from: nil)
                            }
                        }
                            .configuredKeyboardShortcut("z")
                        Button(L("Redo")) {
                            if NSApp.keyWindow?.firstResponder is NSTextView {
                                NSApp.sendAction(NSSelectorFromString("redo:"), to: nil, from: nil)
                            }
                        }
                            .configuredKeyboardShortcut("z", modifiers: [.command, .shift])
                    } else {
                        Button(session.history.canUndo ? LF("Undo %@", L(session.history.undoName)) : L("Undo")) { session.undo() }
                            .configuredKeyboardShortcut("z").disabled(!session.canUndo)
                        Button(session.history.canRedo ? LF("Redo %@", L(session.history.redoName)) : L("Redo")) { session.redo() }
                            .configuredKeyboardShortcut("z", modifiers: [.command, .shift]).disabled(!session.canRedo)
                    }
                }
                CommandGroup(replacing: .newItem) {
                    Button(L("New Canvas…")) {
                        applicationDelegate.showEditor?()
                        Task { await applicationDelegate.projects.newCanvas() }
                    }.configuredKeyboardShortcut("n")
                        .disabled(!applicationDelegate.projects.canStart)
                    Button(L("Open Project…")) {
                        applicationDelegate.showEditor?()
                        Task { await applicationDelegate.projects.open() }
                    }
                        .configuredKeyboardShortcut("o").disabled(!applicationDelegate.projects.canStart)
                    Menu(L("Open Recent")) {
                        ForEach(RecentProjects.shared.urls, id: \.self) { url in
                            Button(url.deletingPathExtension().lastPathComponent) {
                                applicationDelegate.showEditor?()
                                Task { await applicationDelegate.projects.open(url) }
                            }
                        }
                        Divider()
                        Button(L("Clear Menu")) { RecentProjects.shared.clear() }
                            .disabled(RecentProjects.shared.urls.isEmpty)
                    }
                        .disabled(!applicationDelegate.projects.canStart)
                    Button(L("Import Images…")) { session.showsImporter = true }
                        .disabled(session.levels != nil || session.showsBusy || session.isImporting || session.showsNewDocument)
                }
                CommandGroup(replacing: .saveItem) {
                    Button(L("Save")) { Task { await applicationDelegate.projects.save() } }
                        .configuredKeyboardShortcut("s").disabled(session.document == nil || !applicationDelegate.projects.canStart)
                    Button(L("Save As…")) { Task { await applicationDelegate.projects.save(asNew: true) } }
                        .configuredKeyboardShortcut("s", modifiers: [.command, .shift])
                        .disabled(session.document == nil || !applicationDelegate.projects.canStart)
                    Divider()
                    Button(L("Export PNG…")) { Task { await applicationDelegate.projects.exportPNG() } }
                        .configuredKeyboardShortcut("e", modifiers: [.command, .shift])
                        .disabled(session.document == nil || !applicationDelegate.projects.canStart)
                    // Export As on JPEG.
                    Button(L("Export JPEG…")) { Task { await applicationDelegate.projects.exportAs(start: .jpeg) } }
                        .configuredKeyboardShortcut("s", modifiers: [.command, .option, .shift])
                        .disabled(session.document == nil || !applicationDelegate.projects.canStart)
                    // PNG, JPEG or PDF, sized and previewed; ⌥⇧⌘W, as Photoshop's Export As.
                    Button(L("Export As…")) { Task { await applicationDelegate.projects.exportAs() } }
                        .configuredKeyboardShortcut("w", modifiers: [.command, .option, .shift])
                        .disabled(session.document == nil || !applicationDelegate.projects.canStart)
                    Divider()
                    Button(L("Close Project")) {
                        if let window = applicationDelegate.projects.window {
                            Task { await applicationDelegate.projects.close(window) }
                        }
                    }.configuredKeyboardShortcut("w").disabled(!applicationDelegate.projects.canStart)
                }
                // Grouped: a commands builder takes at most ten items.
                Group {
                    CommandGroup(after: .appInfo) {
                        Button(L("Compositor AI Releases…")) { NSWorkspace.shared.open(URL(string: "https://github.com/baichujiang/compositor-ai/releases")!) }
                        Menu(L("Interface Language")) {
                            Toggle(L("简体中文"), isOn: languageBinding("zh-Hans"))
                            Toggle(L("English"), isOn: languageBinding("en"))
                            Divider()
                            Text(L("Reopen the app to apply language changes."))
                        }
                    }
                    CommandGroup(after: .toolbar) {
                        Button(L("AI Assistant")) { session.showsAIAssistant.toggle() }
                            .keyboardShortcut("a", modifiers: [.command, .shift])
                        Button(L("Search Commands…")) {
                            CommandPaletteController.shared.toggle(session: session, over: applicationDelegate.projects.window)
                        }
                        .configuredKeyboardShortcut("f", modifiers: [.command])
                        // A plain F, shown as menus show keys; the app hands an F meant for a text field to the field
                        // first (see CompositorApplicationDelegate).
                        Toggle(L("Toggle Fullscreen"), isOn: Binding(get: { session.canvasOnly },
                                                            set: { _ in applicationDelegate.toggleCanvasOnly() }))
                            .keyboardShortcut("f", modifiers: [])
                            .disabled(!session.canToggleCanvasOnly)
                        Divider()
                        // With a dialog's preview open (Export As), these zoom that preview rather than the canvas.
                        Button(L("Fit Canvas")) {
                            if let preview = session.previewZoom { preview(.fit) } else { session.fit() }
                        }.configuredKeyboardShortcut("0").disabled(session.document == nil)
                        Button(L("Actual Pixels")) {
                            if let preview = session.previewZoom { preview(.actual) } else { session.zoom(to: 1) }
                        }.configuredKeyboardShortcut("1").disabled(session.document == nil)
                        Button(L("Zoom In")) {
                            guard !(NSApp.keyWindow?.firstResponder is NSText) else { return }
                            if let preview = session.previewZoom { preview(.zoomIn) } else { session.zoomKeyboard(by: 1) }
                        }
                            .configuredKeyboardShortcut("=").disabled(session.document == nil)
                        Button(L("Zoom Out")) {
                            guard !(NSApp.keyWindow?.firstResponder is NSText) else { return }
                            if let preview = session.previewZoom { preview(.zoomOut) } else { session.zoomKeyboard(by: -1) }
                        }
                            .configuredKeyboardShortcut("-").disabled(session.document == nil)
                        Toggle(L("Navigator (300% and above)"), isOn: $showsNavigator)
                        Toggle(L("Pixel Grid (800% and above)"), isOn: Binding(get: { session.showsPixelGrid },
                                                                              set: { session.showsPixelGrid = $0 }))
                        Toggle(L("Show Transform Controls"), isOn: Binding(get: { session.showsTransformControls },
                                                                          set: { session.showsTransformControls = $0 }))
                            .configuredKeyboardShortcut("h").disabled(session.tool != .move || session.document == nil)
                        Group {
                            Divider()
                            Menu(L("Show")) {
                                Toggle(L("Grid"), isOn: Binding(get: { session.showsGrid }, set: { session.showsGrid = $0 }))
                                    .configuredKeyboardShortcut("'").disabled(session.document == nil)
                                Toggle(L("Guides"), isOn: Binding(get: { session.showsGuides }, set: { session.showsGuides = $0 }))
                                    .configuredKeyboardShortcut(";").disabled(session.document == nil)
                            }
                            Button(L("Grid Settings…")) { Task { await applicationDelegate.projects.gridSettings() } }
                                .disabled(session.document == nil)
                            Toggle(L("Rulers"), isOn: Binding(get: { session.showsRulers }, set: { session.showsRulers = $0 }))
                                .configuredKeyboardShortcut("r").disabled(session.document == nil)
                            Divider()
                            Toggle(L("Snap"), isOn: Binding(get: { session.snapEnabled }, set: { session.snapEnabled = $0 }))
                                .configuredKeyboardShortcut(";", modifiers: [.command, .shift]).disabled(session.document == nil)
                            Menu(L("Snap To")) {
                                Toggle(L("Guides"), isOn: Binding(get: { session.snapToGuides }, set: { session.snapToGuides = $0 }))
                                    .disabled(session.document == nil)
                                Toggle(L("Grid"), isOn: Binding(get: { session.snapToGrid }, set: { session.snapToGrid = $0 }))
                                    .disabled(session.document == nil)
                                Toggle(L("Layers"), isOn: Binding(get: { session.snapToLayers }, set: { session.snapToLayers = $0 }))
                                    .disabled(session.document == nil)
                                Toggle(L("Document Bounds"), isOn: Binding(get: { session.snapToDocumentBounds },
                                                                        set: { session.snapToDocumentBounds = $0 }))
                                    .disabled(session.document == nil)
                            }
                            Divider()
                            Toggle(L("Lock Guides"), isOn: Binding(get: { session.locksGuides }, set: { session.locksGuides = $0 }))
                                .configuredKeyboardShortcut(";", modifiers: [.command, .option]).disabled(session.document == nil)
                            Button(L("Clear Guides")) { session.clearGuides() }
                                .disabled(!session.canClearGuides)
                        }
                    }
                    // ⌘H toggles the Move tool's transform controls instead of hiding the app, so Hide keeps its
                    // place in the app menu without the shortcut.
                    CommandGroup(replacing: .appVisibility) {
                        Button(L("Hide Compositor AI")) { NSApp.hide(nil) }
                        Button(L("Hide Others")) { NSApp.hideOtherApplications(nil) }
                            .configuredKeyboardShortcut("h", modifiers: [.command, .option])
                        Button(L("Show All")) { NSApp.unhideAllApplications(nil) }
                    }
                }
                CommandGroup(replacing: .pasteboard) {
                    // Canvas pixels when the canvas has focus; text fields keep their own editing.
                    // Cut, Copy and Paste check when chosen rather than through .disabled: what they depend on
                    // (the pasteboard, the copied pixels, the busy flag) isn't observed, so a disabled state could
                    // go stale — the first Paste after a Copy used to beep until something else refreshed the menu.
                    Button(L("Cut")) {
                        if NSApp.keyWindow?.firstResponder is NSTextView { NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil) }
                        else if session.selection != nil, session.canCopyPixels { Task { await session.cutSelection() } }
                        else { NSSound.beep() }
                    }
                        .configuredKeyboardShortcut("x")
                    Button(L("Copy")) {
                        if NSApp.keyWindow?.firstResponder is NSTextView { NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil) }
                        else if session.canCopyPixels || session.canCopyLayer { session.copySelection() }
                        else { NSSound.beep() }
                    }
                        .configuredKeyboardShortcut("c")
                    Button(L("Copy Merged")) { session.copyMergedSelection() }
                        .configuredKeyboardShortcut("c", modifiers: [.command, .shift]).disabled(!session.canCopyMerged)
                    Button(L("Paste")) {
                        if NSApp.keyWindow?.firstResponder is NSTextView { NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil) }
                        else if applicationDelegate.workspace.pasteCopiedLayer() { }
                        else if session.canPaste { session.paste() }
                        else { NSSound.beep() }
                    }
                        .configuredKeyboardShortcut("v")
                }
                CommandGroup(after: .pasteboard) {
                    Divider()
                    Button(L("Keyboard Shortcuts…")) { ShortcutSettings.shared.show() }
                    // Photoshop's fill shortcuts; in a text field they keep their text meaning.
                    Button(L("Fill with Foreground Color")) {
                        if NSApp.keyWindow?.firstResponder is NSTextView {
                            NSApp.sendAction(#selector(NSResponder.deleteWordBackward(_:)), to: nil, from: nil)
                        } else { Task { await session.fillSelection(with: .foreground) } }
                    }
                        .configuredKeyboardShortcut(.delete, modifiers: .option).disabled(!session.canEditPixels)
                    Button(L("Fill with Background Color")) {
                        if NSApp.keyWindow?.firstResponder is NSTextView {
                            NSApp.sendAction(#selector(NSResponder.deleteToBeginningOfLine(_:)), to: nil, from: nil)
                        } else { Task { await session.fillSelection(with: .background) } }
                    }
                        .configuredKeyboardShortcut(.delete, modifiers: .command).disabled(!session.canEditPixels)
                    Button(L("Clear Selection Pixels")) { Task { await session.clearSelectedPixels() } }
                        .disabled(session.selection == nil || !session.canEditPixels)
                    Button(L("Content-Aware Fill…")) { session.beginFilter(.contentAwareFill) }
                        .configuredKeyboardShortcut(.delete, modifiers: .shift).disabled(!session.canContentAwareFill)
                }
                CommandMenu(L("Select")) {
                    // A field being edited keeps its own Select All: offer it to the responder chain
                    // first, which covers every kind of text control rather than NSTextView alone,
                    // and select the canvas only when nothing there wanted it.
                    Button(L("All")) {
                        if NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil) { return }
                        guard session.document != nil else { return }
                        session.selectAll()
                    }
                        // Never disabled: on macOS this menu item is what binds Cmd-A to selectAll:, so
                        // switching it off takes Select All away from every text field too. With no
                        // document and nothing being edited the action simply does nothing.
                        .configuredKeyboardShortcut("a")
                    Button(L("Deselect")) { session.deselect() }
                        .configuredKeyboardShortcut("d").disabled(session.selection == nil || !session.canEditSelection)
                    Button(L("Inverse")) { session.invertSelection() }
                        .configuredKeyboardShortcut("i", modifiers: [.command, .shift])
                        .disabled(session.selection == nil || !session.canEditSelection)
                    Button(L("Layer's Pixels")) {
                        if let id = session.activeLayerID { session.loadLayerSelection(layerID: id) }
                    }
                        .disabled(session.activeLayer?.asset == nil || !session.canEditSelection)
                    Button(L("Subject")) { Task { await session.selectSubject() } }
                        .configuredKeyboardShortcut("a", modifiers: [.command, .option])
                        .disabled(!session.canSelectSubject)
                    Button(L("Color Range…")) { session.beginColorRange() }
                        .disabled(!session.canSelectColorRange)
                    Button(L("Mask's Black Areas")) {
                        if let id = session.activeLayerID { session.loadMaskSelection(layerID: id) }
                    }
                        .disabled(session.activeLayer?.mask == nil || !session.canEditSelection)
                    Divider()
                    Button(L("Expand…")) { session.promptSelectionAmount(.expand) }
                        .disabled(!session.canModifySelection)
                    Button(L("Contract…")) { session.promptSelectionAmount(.contract) }
                        .disabled(!session.canModifySelection)
                    Button(L("Feather…")) { session.promptSelectionAmount(.feather) }
                        .disabled(!session.canModifySelection)
                }
                CommandMenu(L("Image")) {
                    Button(L("Curves…")) { session.beginFilter(.curves) }
                        .configuredKeyboardShortcut("m").disabled(!session.canAdjustColors || session.hueSaturation != nil)
                    Button(L("Levels…")) { session.beginLevels() }
                        .configuredKeyboardShortcut("l").disabled(!session.canAdjustColors || session.hueSaturation != nil)
                    Button(L("Hue/Saturation…")) { session.beginHueSaturation() }
                        .configuredKeyboardShortcut("u").disabled(!session.canAdjustColors)
                    ForEach([FilterKind.blackWhite, .colorBalance, .exposure, .gradientMap, .grain], id: \.self) { kind in
                        Button("\(L(kind.rawValue))…") { session.beginFilter(kind) }
                            .disabled(!session.canAdjustColors || session.hueSaturation != nil)
                    }
                    Button(L(session.isMaskSelected ? "Invert Mask" : "Invert")) { Task { await session.invertPixels() } }
                        .configuredKeyboardShortcut("i")
                        .disabled(!session.canInvert)
                    Divider()
                    Button(L("Canvas Size…")) { Task { await applicationDelegate.projects.canvasSize() } }
                        .configuredKeyboardShortcut("c", modifiers: [.command, .option])
                        .disabled(session.document == nil || !applicationDelegate.projects.canStart)
                    Button(L("Image Size…")) { Task { await applicationDelegate.projects.imageSize() } }
                        .configuredKeyboardShortcut("i", modifiers: [.command, .option])
                        .disabled(session.document == nil || !applicationDelegate.projects.canStart)
                    Button(L("Trim…")) { Task { await applicationDelegate.projects.trim() } }
                        .disabled(session.document == nil || !applicationDelegate.projects.canStart)
                    Group {
                        Divider()
                        Button(L("Rotate Canvas 90° Clockwise")) { session.rotateCanvas(clockwise: true) }
                            .disabled(!session.canEditLayers)
                        Button(L("Rotate Canvas 90° Counterclockwise")) { session.rotateCanvas(clockwise: false) }
                            .disabled(!session.canEditLayers)
                        Button(L("Flip Canvas Horizontal")) { session.flipCanvas(horizontally: true) }
                            .disabled(!session.canEditLayers)
                        Button(L("Flip Canvas Vertical")) { session.flipCanvas(horizontally: false) }
                            .disabled(!session.canEditLayers)
                    }
                }
                CommandMenu(L("Filter")) {
                    Button(session.lastFilter.map { LF("Last Filter: %@", L($0.rawValue)) } ?? L("Last Filter")) {
                        Task { await session.repeatLastFilter() }
                    }
                        // ⌃⌘F, as in Photoshop; ⌘F is the command palette.
                        .configuredKeyboardShortcut("f", modifiers: [.command, .control]).disabled(!session.canRepeatLastFilter)
                    Divider()
                    ForEach(FilterKind.allCases.filter { $0 != .contentAwareFill && !$0.isImageAdjustment }, id: \.self) { kind in
                        Button("\(L(kind.rawValue))…") { session.beginFilter(kind) }
                            .disabled(!(kind == .vignette ? session.canVignette : session.canAdjustColors) || session.hueSaturation != nil)
                    }
                }
                CommandMenu(L("Layer")) {
                    Menu(L("New Adjustment Layer")) {
                        ForEach(AdjustmentKind.allCases, id: \.self) { kind in
                            Button(L(kind.rawValue) + (kind.isEditable ? "…" : "")) { session.addAdjustment(kind) }
                        }
                    }.disabled(!session.canEditLayers || session.document == nil)
                    Button(L("Edit Adjustment…")) {
                        session.adjustmentEditingID = session.activeLayerID
                    }.disabled(!session.canEditLayers || session.activeLayer?.adjustment == nil)
                    Divider()
                    Button(L(session.canTransformSelection ? "Transform Selection" : "Transform Layer")) { session.transformCommand() }
                        .configuredKeyboardShortcut("t").disabled(!session.canTransform && !session.canTransformSelection)
                    Button(L(session.selection == nil ? "Duplicate Layer" : "Layer via Copy")) { session.layerViaCopy() }
                        .configuredKeyboardShortcut("j").disabled(!session.canCopyPixels && !(session.selection == nil && session.canEditLayers && session.activeLayer != nil))
                    Divider()
                    Button(L(session.activeLayer?.maskSourceID == nil ? "Create Clipping Mask" : "Release Clipping Mask")) {
                        if let id = session.activeLayerID { session.toggleClippingMask(id) }
                    }
                    .configuredKeyboardShortcut("g", modifiers: [.command, .option])
                    .disabled(session.activeLayerID.map { !session.canToggleClippingMask($0) } ?? true)
                    Divider()
                    Button(L("Group Selected Layers")) { session.groupSelectedLayers() }
                        .configuredKeyboardShortcut("g").disabled(!session.canEditLayers)
                    Button(L("Ungroup Layers")) { session.ungroupLayers() }
                        .configuredKeyboardShortcut("g", modifiers: [.command, .shift]).disabled(!session.canUngroupLayers)
                    Button(L("Move Out of Folder")) { session.moveActiveLayerOutOfGroup() }
                        .disabled(!session.canEditLayers || session.activeLayer?.parentID == nil)
                    Button(L("New Blank Layer")) { session.addBlankLayer() }
                        .configuredKeyboardShortcut("n", modifiers: [.command, .shift]).disabled(!session.canEditLayers)
                    Button(L("Rename Layer…")) { session.renamingLayerID = session.activeLayerID }
                        .disabled(!session.canEditLayers || session.activeLayer == nil)
                    Button(L(session.activeLayer?.isVisible == false ? "Show Layer" : "Hide Layer")) {
                        if let id = session.activeLayerID { session.toggleLayerVisibility(id) }
                    }.disabled(!session.canEditLayers || session.activeLayer == nil)
                    Divider()
                    Button(L("Move Layer Up")) { session.moveActiveLayer(by: 1) }
                        .configuredKeyboardShortcut("]").disabled(!session.canMoveActiveLayer(by: 1))
                    Button(L("Move Layer Down")) { session.moveActiveLayer(by: -1) }
                        .configuredKeyboardShortcut("[").disabled(!session.canMoveActiveLayer(by: -1))
                    Group {
                        Button(L(session.mergeTitle)) { session.mergeLayers() }
                            .configuredKeyboardShortcut("e").disabled(!session.canMergeLayers)
                        Divider()
                        Button(L("Flip Layer Horizontal")) { session.flipLayers(horizontally: true) }
                            .disabled(!session.canTransform)
                        Button(L("Flip Layer Vertical")) { session.flipLayers(horizontally: false) }
                            .disabled(!session.canTransform)
                    }
                    Divider()
                    Button(session.selectedEffect != nil ? LF("Delete %@", L(session.selectedEffect!.kind.rawValue)) : L(session.isMaskSelected && session.activeLayer?.mask != nil ? "Delete Layer Mask" : session.selectedLayerIDs.count > 1 ? "Delete Layers" : "Delete Layer")) {
                        session.deleteLayerOrMask()
                    }
                        .disabled(!session.canEditLayers || session.activeLayer == nil)
                }
            }
    }

    private func languageBinding(_ language: String) -> Binding<Bool> {
        Binding(get: { interfaceLanguage == language }, set: { selected in
            if selected { AppLocalization.choose(language) }
        })
    }
}
