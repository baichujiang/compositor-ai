import SwiftUI
import AppKit

struct AIAssistantPanel: View {
    @Bindable var session: EditorSession
    @Bindable var assistant: AIAssistant
    @AppStorage("ai.includeCanvas") private var includeCanvas = false
    @AppStorage("ai.autoApply") private var autoApply = true
    @AppStorage("ai.codexPath") private var codexPath = ""
    @State private var prompt = ""
    @State private var showsSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AI Assistant", systemImage: "sparkles").font(.headline)
                Spacer()
                Button { assistant.clear() } label: { Image(systemName: "arrow.counterclockwise") }.help("Clear conversation")
                Button { session.showsAIAssistant = false } label: { Image(systemName: "xmark") }.help("Hide AI Assistant")
            }
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if assistant.messages.isEmpty {
                            Text("Describe an edit in your language.").font(.headline)
                            Text("Try: “Set the selected layer to 70% opacity” or “Make this image a little brighter.”")
                                .foregroundStyle(.secondary)
                            Text("AI can move, scale, rotate, rename and adjust layers. Painting and object generation are not available yet.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach(assistant.messages) { message in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L(message.isUser ? "You" : "AI")).font(.caption.bold()).foregroundStyle(.secondary)
                                Text(message.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(10)
                            .background(message.isUser ? Color.accentColor.opacity(0.12) : Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                            .id(message.id)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: assistant.messages.count) { _, _ in
                    if let id = assistant.messages.last?.id { proxy.scrollTo(id, anchor: .bottom) }
                }
            }
            if let plan = assistant.pendingPlan {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Proposed commands").font(.caption.bold())
                    ScrollView {
                        ForEach(Array(plan.actions.enumerated()), id: \.offset) { _, action in
                            Text(describe(action)).font(.caption).textSelection(.enabled)
                        }
                    }.frame(maxHeight: 100)
                    HStack {
                        Button("Apply Changes") { assistant.applyPending(to: session) }.buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("aiApply")
                        Button("Discard") { assistant.discardPending() }
                    }
                }
            }
            if !assistant.status.isEmpty {
                HStack(alignment: .top) {
                    if assistant.isWorking { ProgressView().controlSize(.small) }
                    Text(L(assistant.status)).font(.caption).textSelection(.enabled)
                        .accessibilityIdentifier("aiStatus")
                }
            }
            Divider()
            Toggle("Include canvas image", isOn: $includeCanvas).toggleStyle(.checkbox).disabled(assistant.isWorking)
                .accessibilityIdentifier("aiIncludeCanvas")
            Toggle("Apply edits automatically", isOn: $autoApply).toggleStyle(.checkbox).disabled(assistant.isWorking)
            Text("Your request, recent chat and layer details are sent through your Codex account. Canvas pixels are sent only when enabled above.")
                .font(.caption2).foregroundStyle(.secondary)
            TextField("Describe an edit…", text: $prompt, axis: .vertical)
                .lineLimit(2...5).textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("aiPrompt").disabled(assistant.isWorking)
                .onSubmit { send() }
            HStack {
                if assistant.isWorking { Button("Cancel") { assistant.cancel() } }
                else {
                    Button("Send") { send() }.buttonStyle(.borderedProminent)
                        .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !session.canEditLayers)
                        .accessibilityIdentifier("aiSend")
                }
                Spacer()
                Button("Settings") { showsSettings.toggle() }
            }
            if showsSettings { settings }
        }
        .padding(14).frame(width: 330)
        .background(Color(white: 0.12))
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L(AICodexBackend.findExecutable(customPath: codexPath) == nil ? "Codex CLI not found" : "Codex CLI detected"))
                .font(.caption.bold())
            Text("Use your own Codex login. Install Codex CLI and run codex login, or sign in to the Codex desktop app.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                TextField("Optional Codex executable path", text: $codexPath).textFieldStyle(.roundedBorder)
                Button("Choose…") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = false
                    panel.canChooseFiles = true
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url { codexPath = url.path }
                }
            }
            Link("Project, downloads & feedback", destination: URL(string: "https://github.com/baichujiang/compositor-ai")!)
                .font(.caption)
        }.disabled(assistant.isWorking)
    }

    private func send() {
        let text = prompt
        assistant.send(text, session: session, includeImage: includeCanvas, autoApply: autoApply, executablePath: codexPath)
        if assistant.isWorking { prompt = "" }
    }

    private func describe(_ action: AIEditorCommand) -> String {
        let name = session.document?.layers.first(where: { $0.id == action.layerID })?.name ?? L("Canvas")
        var detail = action.kind.title + " · " + name
        if let value = action.value { detail += " · \(value.formatted())" }
        if let x = action.x, let y = action.y { detail += " · (\(x.formatted()), \(y.formatted()))" }
        if let text = action.text { detail += " · " + (action.kind == .blend ? L(text) : text) }
        if let visible = action.visible { detail += " · " + L(visible ? "Show" : "Hide") }
        return detail
    }
}
