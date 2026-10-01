// {{PROJECT_NAME}} — flavor → API base. 값은 xcconfig(Config/*.xcconfig)의 빌드설정에서 Info.plist 로 주입.
import Foundation

enum Env {
    static var flavor: String { value("APP_FLAVOR", "Debug") }
    static var apiBase: String { value("API_BASE_URL", "http://localhost:8000") }

    private static func value(_ key: String, _ def: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? def
    }
}
