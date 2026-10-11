import SwiftUI
import AppKit

struct AIAssistantPanel: View {
    let editor: any AIEditorGateway
    @Bindable var assistant: AIAssistant
    var hide: () -> Void
    @AppStorage("ai.includeCanvas") private var includeCanvas = false
    @AppStorage("ai.autoApply") private var autoApply = true
    @AppStorage("ai.codexPath") private var codexPath = ""
    @AppStorage("ai.geminiPath") private var geminiPath = ""
    @AppStorage("ai.geminiModel") private var geminiModel = ""
    @AppStorage("ai.antigravityPath") private var antigravityPath = ""
    @AppStorage("ai.antigravityModel") private var antigravityModel = ""
    @AppStorage("ai.backend") private var providerValue = "codex"
    @State private var prompt = ""
    @State private var showsSettings = false
    private var provider: AIBackendProvider { AIBackendProvider(rawValue: providerValue) ?? .codex }
    private var executablePath: Binding<String> {
        switch provider {
        case .codex: $codexPath
        case .gemini: $geminiPath
        case .antigravity: $antigravityPath
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AI Assistant", systemImage: "sparkles").font(.headline)
                Spacer()
                Button { assistant.clear() } label: { Image(systemName: "arrow.counterclockwise") }.help("Clear conversation")
                Button(action: hide) { Image(systemName: "xmark") }.help("Hide AI Assistant")
            }
            Picker("AI backend", selection: $providerValue) {
                ForEach(AIBackendProvider.allCases) { Text($0.title).tag($0.rawValue) }
            }.disabled(assistant.isWorking).accessibilityIdentifier("aiBackend")
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
                        Button("Apply Changes") { assistant.applyPending() }.buttonStyle(.borderedProminent)
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
            Toggle("Include canvas image", isOn: Binding(get: { provider.supportsCanvasImage && includeCanvas }, set: { includeCanvas = $0 }))
                .toggleStyle(.checkbox).disabled(assistant.isWorking || !provider.supportsCanvasImage)
                .accessibilityIdentifier("aiIncludeCanvas")
            if !provider.supportsCanvasImage {
                Text("Antigravity CLI currently accepts text only. Canvas input is available with Codex or Gemini CLI.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Toggle("Apply edits automatically", isOn: $autoApply).toggleStyle(.checkbox).disabled(assistant.isWorking)
            Text(LF("Your request, recent chat and layer details are sent through your %@ account. Canvas pixels are sent only when enabled above.", provider.accountName))
                .font(.caption2).foregroundStyle(.secondary)
            TextField("Describe an edit…", text: $prompt, axis: .vertical)
                .lineLimit(2...5).textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("aiPrompt").disabled(assistant.isWorking)
                .onSubmit { send() }
            HStack {
                if assistant.isWorking { Button("Cancel") { assistant.cancel() } }
                else {
                    Button("Send") { send() }.buttonStyle(.borderedProminent)
                        .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !editor.canSendRequest)
                        .accessibilityIdentifier("aiSend")
                }
                Spacer()
                Button("Settings") { showsSettings.toggle() }
            }
            if showsSettings { settings }
        }
        .padding(14).frame(width: 330)
        .background(Color(white: 0.12))
        .onAppear { assistant.selectBackend(provider) }
        .onChange(of: providerValue) { _, _ in assistant.selectBackend(provider) }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LF(provider.findExecutable(customPath: executablePath.wrappedValue) == nil ? "%@ not found" : "%@ detected (login not verified)", provider.title))
                .font(.caption.bold())
            Text(L(provider.loginInstructions))
                .font(.caption).foregroundStyle(.secondary)
            Text("The CLI and service may retain their own sessions or logs. Clearing this chat does not remove those records.")
                .font(.caption2).foregroundStyle(.secondary)
            HStack {
                TextField(L(provider.pathPlaceholder), text: executablePath).textFieldStyle(.roundedBorder)
                Button("Choose…") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = false
                    panel.canChooseFiles = true
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url { executablePath.wrappedValue = url.path }
                }
            }
            if provider == .gemini {
                TextField("Optional Gemini model (CLI default when blank)", text: $geminiModel).textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("aiGeminiModel")
            } else if provider == .antigravity {
                TextField("Optional Antigravity model (CLI default when blank)", text: $antigravityModel).textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("aiAntigravityModel")
            }
            Link("Project, downloads & feedback", destination: URL(string: "https://github.com/baichujiang/compositor-ai")!)
                .font(.caption)
        }.disabled(assistant.isWorking)
    }

    private func send() {
        let text = prompt
        assistant.send(text, editor: editor, includeImage: includeCanvas && provider.supportsCanvasImage, autoApply: autoApply,
                       executablePath: executablePath.wrappedValue, provider: provider,
                       model: provider == .antigravity ? antigravityModel : geminiModel)
        if assistant.isWorking { prompt = "" }
    }

    private func describe(_ action: AIEditorCommand) -> String {
        let name = editor.layerName(for: action.layerID) ?? L("Canvas")
        var detail = action.kind.title + " · " + name
        if let value = action.value { detail += " · \(value.formatted())" }
        if let x = action.x, let y = action.y { detail += " · (\(x.formatted()), \(y.formatted()))" }
        if let text = action.text { detail += " · " + (action.kind == .blend ? L(text) : text) }
        if let visible = action.visible { detail += " · " + L(visible ? "Show" : "Hide") }
        return detail
    }
}
