import Foundation

/// 节假日 App Group 缓存读写（仅文件 I/O，无网络）
/// 主 App 和 Widget Extension 均可安全调用
struct HolidayCache {
    private static let appGroupID = "group.com.dualcalendar.holidays"
    private static let cacheFileName = "holiday_cache.json"

    private static var appGroupURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        )
    }

    /// 读取某年缓存（无缓存时回退到硬编码数据）
    static func load(year: Int) -> [String: HolidayInfo]? {
        // 1. App Group 缓存
        if let groupURL = appGroupURL {
            let fileURL = groupURL.appendingPathComponent("\(year)_\(cacheFileName)")
            if FileManager.default.fileExists(atPath: fileURL.path),
               let data = try? Data(contentsOf: fileURL),
               let result = try? JSONDecoder().decode([String: HolidayInfo].self, from: data) {
                return result
            }
        }
        // 2. 硬编码兜底（2026 国务院发布）
        if year == 2026 { return HardcodedHolidays.data2026 }
        return nil
    }

    /// 写入某年缓存
    static func save(holidays: [String: HolidayInfo], year: Int) {
        guard let groupURL = appGroupURL else { return }
        let fileURL = groupURL.appendingPathComponent("\(year)_\(cacheFileName)")
        try? JSONEncoder().encode(holidays).write(to: fileURL)
    }

    /// 清除所有缓存
    static func clear() {
        guard let groupURL = appGroupURL else { return }
        let files = (try? FileManager.default.contentsOfDirectory(at: groupURL, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.lastPathComponent.contains(cacheFileName) {
            try? FileManager.default.removeItem(at: file)
        }
    }
}
