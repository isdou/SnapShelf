import Foundation
import Testing
@testable import ZancunjiaCore

struct LocalizationTests {
    @Test func englishCatalogUsesTopCapsuleAndEnglishMenus() throws {
        let bundle = try catalog(locale: "en")
        #expect(string("menu.about", in: bundle) == "About SnapShelf")
        #expect(string("placement.top_capsule", in: bundle) == "Top Capsule")
        #expect(string("error.cannot_open", in: bundle) == "Unable to open SnapShelf")
        #expect(!containsBannedTerms(in: bundle))
    }

    @Test func chineseCatalogUsesTopCapsuleNotIslandTrademark() throws {
        let bundle = try catalog(locale: "zh-Hans")
        #expect(string("menu.about", in: bundle) == "关于 SnapShelf")
        #expect(string("placement.top_capsule", in: bundle) == "顶部胶囊")
        #expect(string("empty.drag_capsule", in: bundle) == "仍可把图片或视频拖到顶部胶囊上")
        #expect(!containsBannedTerms(in: bundle))
    }

    private func catalog(locale: String) throws -> Bundle {
        let path = try #require(L10n.bundle.path(forResource: locale, ofType: "lproj"))
        return try #require(Bundle(path: path))
    }

    private func string(_ key: String, in bundle: Bundle) -> String {
        bundle.localizedString(forKey: key, value: "MISSING", table: nil)
    }

    private func containsBannedTerms(in bundle: Bundle) -> Bool {
        let banned = ["for Mac", "Dynamic Island", "灵动岛", "刘海", "notch island"]
        guard let table = bundle.path(forResource: "Localizable", ofType: "strings"),
              let dict = NSDictionary(contentsOfFile: table) as? [String: String] else {
            return true
        }
        return dict.values.contains { value in
            banned.contains { value.localizedCaseInsensitiveContains($0) }
        }
    }
}
