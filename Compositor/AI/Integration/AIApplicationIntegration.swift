import SwiftUI
import Observation

@Observable final class AIEditorWorkspace {
    let assistant = AIAssistant()
    let editor: AINativeEditorAdapter
    var showsAssistant = false

    init(session: EditorSession) { editor = AINativeEditorAdapter(session: session) }

    func detach() {
        assistant.clear()
        editor.detach()
        showsAssistant = false
    }
}

/// The composition root owns per-tab AI state, without modifying EditorSession or ProjectWorkspace.
final class AIApplicationIntegration {
    private var editors: [ObjectIdentifier: AIEditorWorkspace] = [:]

    func state(for session: EditorSession) -> AIEditorWorkspace {
        retainSessions(nil)
        let key = ObjectIdentifier(session)
        if let state = editors[key] { return state }
        let state = AIEditorWorkspace(session: session)
        editors[key] = state
        return state
    }

    func retainSessions(_ sessions: [EditorSession]?) {
        let live = sessions.map { Set($0.map(ObjectIdentifier.init)) }
        for (key, state) in editors where state.editor.session == nil || live?.contains(key) == false {
            state.detach()
            editors[key] = nil
        }
    }

    var hooks: EditorExtensionHooks {
        EditorExtensionHooks(sidebar: { [weak self] session in
            guard let self else { return AnyView(EmptyView()) }
            return AnyView(AIEditorSidebar(state: self.state(for: session)))
        }, documentChanged: { [weak self] session in
            self?.state(for: session).assistant.clear()
        })
    }
}

private struct AIEditorSidebar: View {
    @Bindable var state: AIEditorWorkspace

    var body: some View {
        if state.showsAssistant {
            Divider()
            AIAssistantPanel(editor: state.editor, assistant: state.assistant, hide: { state.showsAssistant = false })
        }
    }
}

struct AIAssistantMenu: View {
    let integration: AIApplicationIntegration
    let session: EditorSession

    var body: some View {
        let state = integration.state(for: session)
        Toggle(L("AI Assistant"), isOn: Binding(get: { state.showsAssistant }, set: { state.showsAssistant = $0 }))
    }
}

struct AIWorkspaceIntegration: ViewModifier {
    let integration: AIApplicationIntegration
    let workspace: ProjectWorkspace

    func body(content: Content) -> some View {
        content
            .environment(\.editorExtensions, integration.hooks)
            .onChange(of: workspace.tabs.map(\.id), initial: true) { _, _ in
                integration.retainSessions(workspace.tabs.map(\.session))
            }
    }
}
