import Foundation

/// 节假日数据服务（网络请求 + 缓存管理）
/// 仅主 App Target 使用，Widget 请用 HolidayCache
final class HolidayService {
    static let shared = HolidayService()

    var holidayMap: [String: HolidayInfo] = [:]
    var isLoading = false
    var errorMessage: String?

    private let baseURL = "https://timor.tech/api/holiday/year"

    /// 硬编码兜底数据（API 被 Cloudflare 墙时使用）
    private func hardcodedMap(for year: Int) -> [String: HolidayInfo] {
        if year == 2026 { return HardcodedHolidays.data2026 }
        return [:]
    }

    // MARK: - 公开方法

    func loadHolidays(for year: Int) async {
        // 1. App Group 缓存
        if let cached = HolidayCache.load(year: year), !cached.isEmpty {
            self.holidayMap = cached
            return
        }
        // 2. 硬编码兜底
        let hardcoded = hardcodedMap(for: year)
        if !hardcoded.isEmpty {
            self.holidayMap = hardcoded
            HolidayCache.save(holidays: hardcoded, year: year)
            // 后台试网络
            Task.detached(priority: .background) { [weak self] in
                await self?.tryNetwork(year: year)
            }
            return
        }
        // 3. 网络请求
        await refreshFromNetwork(year: year)
    }

    func loadCached(for year: Int) -> [String: HolidayInfo] {
        return HolidayCache.load(year: year) ?? [:]
    }

    func refresh(for year: Int) async {
        await refreshFromNetwork(year: year)
    }

    /// 后台静默尝试网络更新（不阻塞 UI）
    private func tryNetwork(year: Int) async {
        do {
            guard let url = URL(string: "\(baseURL)/\(year)") else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            let parsed = try parseResponse(data: data, year: year)
            if !parsed.isEmpty {
                self.holidayMap = parsed
                HolidayCache.save(holidays: parsed, year: year)
            }
        } catch {
            // 静默失败，沿用硬编码数据
        }
    }

    // MARK: - 网络请求

    private func refreshFromNetwork(year: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            guard let url = URL(string: "\(baseURL)/\(year)") else {
                throw URLError(.badURL)
            }
            let (data, _) = try await URLSession.shared.data(from: url)
            let parsed = try parseResponse(data: data, year: year)
            self.holidayMap = parsed
            HolidayCache.save(holidays: parsed, year: year)
        } catch {
            self.errorMessage = "节假日数据加载失败：\(error.localizedDescription)"
            if let cached = HolidayCache.load(year: year) {
                self.holidayMap = cached
            }
        }
        isLoading = false
    }

    private func parseResponse(data: Data, year: Int) throws -> [String: HolidayInfo] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dict = json["holiday"] as? [String: Any]
        else {
            throw NSError(domain: "HolidayService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "API 返回数据格式异常"])
        }
        var result: [String: HolidayInfo] = [:]
        for (key, value) in dict {
            guard let info = value as? [String: Any],
                  let isHoliday = info["holiday"] as? Bool,
                  let name = info["name"] as? String,
                  let date = info["date"] as? String
            else { continue }
            result[String(key)] = HolidayInfo(date: date, isHoliday: isHoliday, name: name)
        }
        return result
    }
}
