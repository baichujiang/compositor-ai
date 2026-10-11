import SwiftUI

/// Optional app extensions use these presentation hooks; the editor owns no extension state.
nonisolated struct EditorExtensionHooks {
    var sidebar: @MainActor (EditorSession) -> AnyView = { _ in AnyView(EmptyView()) }
    var documentChanged: @MainActor (EditorSession) -> Void = { _ in }
}

private nonisolated struct EditorExtensionKey: EnvironmentKey {
    static let defaultValue = EditorExtensionHooks()
}

extension EnvironmentValues {
    var editorExtensions: EditorExtensionHooks {
        get { self[EditorExtensionKey.self] }
        set { self[EditorExtensionKey.self] = newValue }
    }
}
