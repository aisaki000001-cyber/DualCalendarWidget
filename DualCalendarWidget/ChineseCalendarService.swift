import Foundation

/// 中国农历 + 节气 + 节日服务
/// 用于小组件中显示农历日期和节日名称
struct ChineseCalendarService {

    // MARK: - 农历转换

    /// 系统内置中国农历 Calendar
    private static let lunarCalendar: Calendar = {
        var cal = Calendar(identifier: .chinese)
        cal.locale = Locale(identifier: "zh_CN")
        return cal
    }()

    /// 将公历日期转为农历日期
    static func lunarDay(from date: Date) -> LunarDay? {
        let comps = lunarCalendar.dateComponents([.month, .day, .isLeapMonth], from: date)
        guard let month = comps.month, let day = comps.day else { return nil }
        return LunarDay(
            month: month,
            day: day,
            isLeapMonth: comps.isLeapMonth ?? false
        )
    }

    /// 获取指定农历月的天数（用于判断腊月是否有三十）
    static func daysInLunarMonth(year: Int, month: Int) -> Int {
        var cal = Calendar(identifier: .chinese)
        cal.locale = Locale(identifier: "zh_CN")

        // 构造该农历月第一天的公历日期
        let comps = DateComponents(
            calendar: cal,
            year: year, month: month, day: 1
        )
        guard let firstDay = comps.date else { return 30 }

        // 下个月第一天往前推一天
        guard let nextMonth = cal.date(byAdding: .month, value: 1, to: firstDay),
              let lastDay = cal.date(byAdding: .day, value: -1, to: nextMonth)
        else { return 30 }

        return cal.component(.day, from: lastDay)
    }

    // MARK: - 节日查找

    /// 查找某一天的节日/节气（优先级：特殊节日 > 节气 > 农历节日 > 公历节日）
    static func festival(for date: Date, holidayInfo: HolidayInfo?) -> Festival? {
        // 注意：不在这里根据 API holidayInfo 返回节日名
        // 那样会导致连休每一天（如春节 9 天）都显示"春节"
        // 由 CalendarDay.subtitle 统一管理优先级：节日/节气 > 农历 > API兜底

        // 1. 农历节日 + 除夕
        if let lunar = lunarDay(from: date) {
            // 除夕：腊月最后一天
            if lunar.month == 12 {
                let maxDay = daysInLunarMonth(
                    year: Calendar.current.component(.year, from: date),
                    month: 12
                )
                if lunar.day == maxDay {
                    return Festival(name: "除夕", type: .lunar)
                }
            }

            // 腊八
            if lunar.month == 12 && lunar.day == 8 {
                return Festival(name: "腊八", type: .lunar)
            }

            // 春节
            if lunar.month == 1 && lunar.day == 1 {
                return Festival(name: "春节", type: .lunar)
            }
            // 元宵节
            if lunar.month == 1 && lunar.day == 15 {
                return Festival(name: "元宵节", type: .lunar)
            }
            // 端午节
            if lunar.month == 5 && lunar.day == 5 {
                return Festival(name: "端午节", type: .lunar)
            }
            // 七夕
            if lunar.month == 7 && lunar.day == 7 {
                return Festival(name: "七夕", type: .lunar)
            }
            // 中秋节
            if lunar.month == 8 && lunar.day == 15 {
                return Festival(name: "中秋节", type: .lunar)
            }
            // 重阳节
            if lunar.month == 9 && lunar.day == 9 {
                return Festival(name: "重阳节", type: .lunar)
            }
        }

        // 3. 廿四节气
        if let term = solarTerm(for: date) {
            return Festival(name: term, type: .solarTerm)
        }

        // 4. 公历节日
        if let gf = gregorianFestival(for: date) {
            return gf
        }

        return nil
    }

    // MARK: - 公历节日

    private static func gregorianFestival(for date: Date) -> Festival? {
        let cal = Calendar.current
        let month = cal.component(.month, from: date)
        let day = cal.component(.day, from: date)

        // 固定日期节日
        let fixedFestivals: [String: (Int, Int, String)] = [
            "01-01": (1, 1, "元旦"),
            "02-14": (2, 14, "情人节"),
            "03-08": (3, 8, "妇女节"),
            "03-12": (3, 12, "植树节"),
            "05-01": (5, 1, "劳动节"),
            "05-04": (5, 4, "青年节"),
            "06-01": (6, 1, "儿童节"),
            "07-01": (7, 1, "建党节"),
            "08-01": (8, 1, "建军节"),
            "09-10": (9, 10, "教师节"),
            "10-01": (10, 1, "国庆节"),
            "12-25": (12, 25, "圣诞节"),
        ]

        for (_, value) in fixedFestivals {
            let (m, d, name) = value
            if month == m && day == d {
                return Festival(name: name, type: .gregorian)
            }
        }

        // 浮动日期节日（用 day 范围判定，避免 weekOfMonth 差异）
        let weekday = cal.component(.weekday, from: date) // 1=周日
        // 母亲节：5月第2个周日（8-14日）
        if month == 5, weekday == 1, day >= 8, day <= 14 {
            return Festival(name: "母亲节", type: .gregorian)
        }
        // 父亲节：6月第3个周日（15-21日）
        if month == 6, weekday == 1, day >= 15, day <= 21 {
            return Festival(name: "父亲节", type: .gregorian)
        }
        // 感恩节：11月第4个周四（22-28日）
        if month == 11, weekday == 5, day >= 22, day <= 28 {
            return Festival(name: "感恩节", type: .gregorian)
        }

        return nil
    }

    // MARK: - 廿四节气

    /// 廿四节气名称（按顺序）
    private static let solarTermNames = [
        "小寒", "大寒", "立春", "雨水", "惊蛰", "春分",
        "清明", "谷雨", "立夏", "小满", "芒种", "夏至",
        "小暑", "大暑", "立秋", "处暑", "白露", "秋分",
        "寒露", "霜降", "立冬", "小雪", "大雪", "冬至"
    ]

    /// 廿四节气 C 值（21 世纪适用）
    /// 公式：date = floor(Y * 0.2422 + C) - floor(Y / 4)
    /// 其中 Y = 年份后两位
    private static let solarTermC: [Double] = [
        5.4055, 20.12,  3.87,   18.73,  5.63,   20.646, // 小寒…春分
        4.81,   20.1,    5.52,   21.04,  5.678,  21.37,  // 清明…夏至
        7.108,  22.83,   7.5,    23.13,  7.646,  23.042, // 小暑…秋分
        8.318,  23.438,  7.438,  22.36,  7.18,   21.94   // 寒露…冬至
    ]

    /// 廿四节气对应月份
    private static let solarTermMonths = [
        1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6,
        7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12
    ]

    /// 查找某天是否是廿四节气
    static func solarTerm(for date: Date) -> String? {
        let cal = Calendar.current
        let year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)
        let day = cal.component(.day, from: date)

        let y = Double(year % 100)

        for i in 0..<24 {
            // 小寒/大寒 使用 (Y-1)
            let yVal = i <= 1 ? (y - 1) : y
            var termDay = Int(yVal * 0.2422 + solarTermC[i])

            // 闰年修正（部分节气）
            let leapAdjust = Int(y / 4)
            // 对于前两个节气，leap adjustment uses (Y-1)
            if i <= 1 {
                termDay -= Int((y - 1) / 4)
            } else {
                termDay -= leapAdjust
            }

            if solarTermMonths[i] == month && termDay == day {
                return solarTermNames[i]
            }
        }

        return nil
    }
}
