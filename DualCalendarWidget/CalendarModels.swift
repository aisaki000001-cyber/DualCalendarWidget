import Foundation

// MARK: - 农历日期

/// 农历日期信息
struct LunarDay: Equatable {
    /// 农历月 1-12
    let month: Int
    /// 农历日 1-30
    let day: Int
    /// 是否闰月
    let isLeapMonth: Bool

    /// 农历月中文名（正月、二月…腊月）
    var monthName: String {
        let names = [
            "正月", "二月", "三月", "四月", "五月", "六月",
            "七月", "八月", "九月", "十月", "冬月", "腊月"
        ]
        let name = month <= 12 ? names[month - 1] : "?"
        return isLeapMonth ? "闰\(name)" : name
    }

    /// 农历日中文名（初一、初二…三十）
    var dayName: String {
        let prefixes = [
            "初一", "初二", "初三", "初四", "初五",
            "初六", "初七", "初八", "初九", "初十",
            "十一", "十二", "十三", "十四", "十五",
            "十六", "十七", "十八", "十九", "二十",
            "廿一", "廿二", "廿三", "廿四", "廿五",
            "廿六", "廿七", "廿八", "廿九", "三十"
        ]
        return day <= 30 ? prefixes[day - 1] : "?"
    }

    /// 简洁显示（只显示日，如"初一"）
    var shortName: String { dayName }

    /// 是否是初一（用于显示月份）
    var isFirstDay: Bool { day == 1 }
}

// MARK: - 节日/节气

/// 节日或节气
struct Festival: Equatable {
    /// 显示名称
    let name: String
    /// 类型：节气、农历节日、公历节日
    let type: FestivalType

    enum FestivalType: Equatable {
        case solarTerm    // 二十四节气
        case lunar        // 农历节日（春节、端午等）
        case gregorian    // 公历节日（父亲节、元旦等）
        case holiday      // 国务院法定节假日
    }

    /// 是否比农历日期优先显示
    var overridesLunarDisplay: Bool { true }
}

// MARK: - 节假日（国务院放假安排）

/// 节假日/调休信息（来自 API）
struct HolidayInfo: Codable, Equatable {
    let date: String       // "2026-10-01"
    let isHoliday: Bool    // true=放假，false=调休补班
    let name: String       // "国庆节"

    var shortName: String {
        if name.contains("元旦") { return "元旦" }
        if name.contains("春节") { return "春节" }
        if name.contains("清明") { return "清明" }
        if name.contains("劳动") { return "劳动" }
        if name.contains("端午") { return "端午" }
        if name.contains("中秋") { return "中秋" }
        if name.contains("国庆") { return "国庆" }
        if name.contains("补班") || name.contains("调休") { return "班" }
        return String(name.prefix(2))
    }
}

// MARK: - 日历中的某一天

struct CalendarDay: Identifiable, Equatable {
    let id = UUID()
    /// 完整公历日期
    let date: Date
    /// 日期数字 1-31
    let day: Int
    /// 是否属于当前月份
    let isCurrentMonth: Bool
    /// 是否周末（周六或周日）
    let isWeekend: Bool
    /// 是否今天
    let isToday: Bool
    /// 农历日期
    var lunarDay: LunarDay?
    /// 节日/节气（优先于农历显示）
    var festival: Festival?
    /// 国务院节假日/调休（来自 API）
    var holidayInfo: HolidayInfo?

    // MARK: - 显示逻辑

    /// 副标题显示的内容（优先级：补班 > 节日/节气 > 农历 > API兜底）
    var subtitle: String? {
        // 1. 调休补班
        if let info = holidayInfo, !info.isHoliday { return "班" }
        // 2. 节日/节气（仅真正节日当天显示，连休假期的其他天跳过）
        if let f = festival { return f.name }
        // 3. 农历日期（连休期间的非节日天也显示自己的农历）
        if let lunar = lunarDay { return lunar.dayName }
        // 4. API 法定假日兜底（无农历数据的极端情况）
        if let info = holidayInfo, info.isHoliday { return info.shortName }
        return nil
    }

    /// 副标题颜色
    var subtitleColor: DisplayColor {
        if let info = holidayInfo {
            return info.isHoliday ? .holiday : .makeupDay
        }
        if let f = festival {
            switch f.type {
            case .solarTerm:  return .solarTerm
            case .lunar:      return .lunarFestival
            case .gregorian:  return .gregorianFestival
            case .holiday:    return .holiday
            }
        }
        if isWeekend { return .weekend }
        return .normal
    }

    /// 日期数字的颜色
    var dayNumberColor: DisplayColor {
        if !isCurrentMonth { return .otherMonth }
        if let info = holidayInfo {
            return info.isHoliday ? .holiday : .makeupDay
        }
        if isWeekend { return .weekend }
        return .normal
    }

    enum DisplayColor {
        case normal
        case weekend
        case holiday
        case makeupDay
        case solarTerm
        case lunarFestival
        case gregorianFestival
        case otherMonth

        var swiftUIColor: String {
            switch self {
            case .normal:               return "primary"
            case .weekend:              return "gray"
            case .holiday:              return "red"
            case .makeupDay:            return "orange"
            case .solarTerm:            return "teal"
            case .lunarFestival:        return "red"
            case .gregorianFestival:    return "purple"
            case .otherMonth:           return "clear"
            }
        }
    }
}

// MARK: - 日历月份

struct CalendarMonth: Identifiable {
    let id = UUID()
    let year: Int
    let month: Int
    let days: [CalendarDay]
    /// 该月日历占几行（5 或 6）
    let rowCount: Int

    var title: String {
        "\(year)年\(month)月"
    }
}
