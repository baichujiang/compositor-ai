import AppKit
import Testing
@testable import Compositor

struct LocalizationTests {
    @Test func newInstallsUseChineseAndSavedEnglishIsRespected() throws {
        let suite = "compositor.localization.test." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        #expect(AppLocalization.language(in: defaults) == "zh-Hans")
        defaults.set("en", forKey: AppLocalization.preferenceKey)
        #expect(AppLocalization.language(in: defaults) == "en")
        defaults.set("unsupported", forKey: AppLocalization.preferenceKey)
        #expect(AppLocalization.language(in: defaults) == "zh-Hans")
    }

    @Test func packagedResourcesCoverBothLanguagesAndPreserveArguments() {
        #expect(AppLocalization.text("New Canvas…", language: "zh-Hans") == "新建画布…")
        #expect(AppLocalization.text("Include canvas image", language: "zh-Hans") == "附带画布图片")
        #expect(AppLocalization.text("New Canvas…", language: "en") == "New Canvas…")
        let key = "Save changes to %@?"
        let name = "Moon 50% 月亮.comp"
        let question = String(format: AppLocalization.text(key, language: "zh-Hans"), name)
        #expect(question == "保存对 Moon 50% 月亮.comp 的更改吗？")
        #expect(AppLocalization.text("custom user text", language: "zh-Hans") == "custom user text")
    }

    @MainActor @Test func translatedBlendItemsStillResolveToStoredValues() {
        for mode in LayerBlendMode.allCases {
            let item = NSMenuItem(title: AppLocalization.text(mode.rawValue, language: "zh-Hans"), action: nil, keyEquivalent: "")
            item.representedObject = mode.rawValue
            #expect(BlendModePicker.mode(of: item) == mode)
        }
        #expect(LayerBlendMode.multiply.rawValue == "Multiply")
        #expect(AICommandKind.move.rawValue == "move_layer")
    }

    @MainActor @Test func commandSearchFindsChineseAndStableEnglishNames() {
        let entry = CommandPaletteEntry(id: "Tool › Brush", title: "工具 › 画笔", shortcut: "B", isEnabled: true, perform: {})
        #expect(CommandPaletteSearch.rank([entry], query: "画笔").first?.id == entry.id)
        #expect(CommandPaletteSearch.rank([entry], query: "brush").first?.id == entry.id)
    }
}
