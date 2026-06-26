import Foundation

/// 国务院办公厅发布的 2026 年节假日安排（硬编码兜底）
/// 来源：国办发明电〔2025〕7号（2025年11月4日发布）
struct HardcodedHolidays {

    /// key: "MM-dd", value: HolidayInfo
    static let data2026: [String: HolidayInfo] = {
        var map = [String: HolidayInfo]()

        // ── 元旦：1月1日-3日（周四至周六），1月4日（周日）上班 ──
        map["01-01"] = HolidayInfo(date: "2026-01-01", isHoliday: true, name: "元旦")
        map["01-02"] = HolidayInfo(date: "2026-01-02", isHoliday: true, name: "元旦")
        map["01-03"] = HolidayInfo(date: "2026-01-03", isHoliday: true, name: "元旦")
        map["01-04"] = HolidayInfo(date: "2026-01-04", isHoliday: false, name: "元旦补班")

        // ── 春节：2月15日-23日（周日-周一，共9天），2月14日/28日（周六）上班 ──
        for d in 15...23 {
            let key = String(format: "02-%02d", d)
            map[key] = HolidayInfo(date: "2026-\(key)", isHoliday: true, name: "春节")
        }
        map["02-14"] = HolidayInfo(date: "2026-02-14", isHoliday: false, name: "春节补班")
        map["02-28"] = HolidayInfo(date: "2026-02-28", isHoliday: false, name: "春节补班")

        // ── 清明节：4月4日-6日（周六-周一），不调休 ──
        map["04-04"] = HolidayInfo(date: "2026-04-04", isHoliday: true, name: "清明节")
        map["04-05"] = HolidayInfo(date: "2026-04-05", isHoliday: true, name: "清明节")
        map["04-06"] = HolidayInfo(date: "2026-04-06", isHoliday: true, name: "清明节")

        // ── 劳动节：5月1日-5日（周五-周二），5月9日（周六）上班 ──
        for d in 1...5 {
            let key = String(format: "05-%02d", d)
            map[key] = HolidayInfo(date: "2026-\(key)", isHoliday: true, name: "劳动节")
        }
        map["05-09"] = HolidayInfo(date: "2026-05-09", isHoliday: false, name: "劳动节补班")

        // ── 端午节：6月19日-21日（周五-周日），不调休 ──
        map["06-19"] = HolidayInfo(date: "2026-06-19", isHoliday: true, name: "端午节")
        map["06-20"] = HolidayInfo(date: "2026-06-20", isHoliday: true, name: "端午节")
        map["06-21"] = HolidayInfo(date: "2026-06-21", isHoliday: true, name: "端午节")

        // ── 中秋节：9月25日-27日（周五-周日），不调休 ──
        map["09-25"] = HolidayInfo(date: "2026-09-25", isHoliday: true, name: "中秋节")
        map["09-26"] = HolidayInfo(date: "2026-09-26", isHoliday: true, name: "中秋节")
        map["09-27"] = HolidayInfo(date: "2026-09-27", isHoliday: true, name: "中秋节")

        // ── 国庆节：10月1日-7日（周四-周三），9月20日/10月10日上班 ──
        for d in 1...7 {
            let key = String(format: "10-%02d", d)
            map[key] = HolidayInfo(date: "2026-\(key)", isHoliday: true, name: "国庆节")
        }
        map["09-20"] = HolidayInfo(date: "2026-09-20", isHoliday: false, name: "国庆补班")
        map["10-10"] = HolidayInfo(date: "2026-10-10", isHoliday: false, name: "国庆补班")

        return map
    }()
}
