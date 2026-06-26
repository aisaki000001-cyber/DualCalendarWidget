import SwiftUI

/// 显示尺寸模式
enum CalendarSize {
    case app           // 主 App 窗口
    case widgetLarge   // Large 小组件
    case widgetMedium  // Medium 小组件
}

/// 单月日历网格视图
struct MonthGridView: View {
    let month: CalendarMonth
    var size: CalendarSize = .app

    private let weekSymbols = ["日", "一", "二", "三", "四", "五", "六"]

    private let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 0),
        count: 7
    )

    var body: some View {
        VStack(spacing: vstackSpacing) {
            // 月份标题
            Text(month.title)
                .font(titleFont)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .center)

            // 星期头
            HStack(spacing: 0) {
                ForEach(weekSymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(weekFont)
                        .foregroundColor(
                            symbol == "六" || symbol == "日" ? .gray : .secondary
                        )
                        .frame(maxWidth: .infinity)
                }
            }

            // 日期网格
            LazyVGrid(columns: columns, spacing: gridSpacing) {
                ForEach(month.days) { day in
                    DayCellView(day: day, size: size, tightScale: tightScale)
                }
            }
        }
    }

    // MARK: - 尺寸计算

    /// Medium 6行月份收紧比例
    private var tightScale: CGFloat {
        size == .widgetMedium && month.rowCount >= 6 ? 0.93 : 1.0
    }

    private var vstackSpacing: CGFloat {
        switch size {
        case .app:           return 4
        case .widgetLarge:   return 2
        case .widgetMedium:  return 0
        }
    }

    private var gridSpacing: CGFloat {
        switch size {
        case .app:           return 2
        case .widgetLarge:   return 2
        case .widgetMedium:  return 0
        }
    }

    private var titleFont: Font {
        .system(size: titleBaseSize * tightScale, weight: .semibold)
    }
    private var titleBaseSize: CGFloat {
        switch size { case .app: return 16; case .widgetLarge: return 12; case .widgetMedium: return 10 }
    }

    private var weekFont: Font {
        .system(size: weekBaseSize * tightScale, weight: .medium)
    }
    private var weekBaseSize: CGFloat {
        switch size { case .app: return 10; case .widgetLarge: return 8; case .widgetMedium: return 7 }
    }
}

// MARK: - 日历数据构建器

enum CalendarDataBuilder {

    static let calendar: Calendar = {
        var cal = Calendar.current
        cal.locale = Locale(identifier: "zh_CN")
        return cal
    }()

    static func build(
        year: Int, month: Int,
        holidayMap: [String: HolidayInfo]
    ) -> CalendarMonth {
        let today = Date()

        let firstDayComponents = DateComponents(year: year, month: month, day: 1)
        guard let firstDay = calendar.date(from: firstDayComponents) else {
            return CalendarMonth(year: year, month: month, days: [], rowCount: 0)
        }

        let range = calendar.range(of: .day, in: .month, for: firstDay)!
        let daysInMonth = range.count

        // weekday: 1=周日 → leadingOffset = firstWeekday - 1
        let leadingOffset = calendar.component(.weekday, from: firstDay) - 1

        let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstDay)!
        let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)!.count

        var days: [CalendarDay] = []

        // 前后月信息
        let prevMonth = month == 1 ? 12 : month - 1
        let prevYear  = month == 1 ? year - 1 : year
        let nextMonth = month == 12 ? 1 : month + 1
        let nextYear  = month == 12 ? year + 1 : year

        // 前导格 — 用 DateComponents 直接构造，避免偏移计算偏差
        for i in 0..<leadingOffset {
            let dayNum = daysInPreviousMonth - leadingOffset + i + 1
            var comps = DateComponents(year: prevYear, month: prevMonth, day: dayNum)
            comps.hour = 12  // 中午，避免时区边界问题
            let date = calendar.date(from: comps)!
            days.append(makeDay(date: date, day: dayNum,
                                isCurrentMonth: false, holidayMap: holidayMap, today: today))
        }

        // 当月日期
        for d in 1...daysInMonth {
            var comps = DateComponents(year: year, month: month, day: d)
            comps.hour = 12
            let date = calendar.date(from: comps)!
            days.append(makeDay(date: date, day: d,
                                isCurrentMonth: true, holidayMap: holidayMap, today: today))
        }

        // 尾随格 — 强制补满 42 格（6 行），同样用 DateComponents
        let totalCells = 42
        let trailing = totalCells - days.count
        for d in 1...trailing {
            var comps = DateComponents(year: nextYear, month: nextMonth, day: d)
            comps.hour = 12
            let date = calendar.date(from: comps)!
            days.append(makeDay(date: date, day: d,
                                isCurrentMonth: false, holidayMap: holidayMap, today: today))
        }

        // 连休扩展
        days = expandHolidayWeekends(days: days, holidayMap: holidayMap, year: year)

        let rowCount = days.count / 7
        return CalendarMonth(year: year, month: month, days: days, rowCount: rowCount)
    }

    /// 把紧邻法定假日的周末也标记为假期（连休红点）
    private static func expandHolidayWeekends(
        days: [CalendarDay], holidayMap: [String: HolidayInfo], year: Int
    ) -> [CalendarDay] {
        var days = days
        guard !holidayMap.isEmpty else { return days }

        let df = DateFormatter()
        df.dateFormat = "MM-dd"

        var holidayKeys = Set(holidayMap.filter { $0.value.isHoliday }.keys)
        guard !holidayKeys.isEmpty else { return days }

        // 两轮扫描：第一轮标紧邻 API 假日的周末，第二轮标紧邻刚标过的周末
        for _ in 0..<2 {
            for i in 0..<days.count where days[i].isCurrentMonth
                && days[i].isWeekend
                && days[i].holidayInfo == nil
            {
                let prev = calendar.date(byAdding: .day, value: -1, to: days[i].date)!
                let next = calendar.date(byAdding: .day, value: 1, to: days[i].date)!
                let prevKey = df.string(from: prev)
                let nextKey = df.string(from: next)

                if holidayKeys.contains(prevKey) || holidayKeys.contains(nextKey) {
                    let thisKey = df.string(from: days[i].date)
                    days[i].holidayInfo = HolidayInfo(
                        date: "\(year)-\(thisKey)", isHoliday: true, name: "假期"
                    )
                }
            }
            // 把新标记的周末也加入 holidayKeys，供第二轮使用
            for day in days where day.isCurrentMonth && day.holidayInfo?.isHoliday == true {
                holidayKeys.insert(df.string(from: day.date))
            }
        }

        return days
    }

    private static func makeDay(
        date: Date, day: Int, isCurrentMonth: Bool,
        holidayMap: [String: HolidayInfo], today: Date
    ) -> CalendarDay {
        let weekday = calendar.component(.weekday, from: date)
        let isWeekend = (weekday == 1 || weekday == 7)

        let df = DateFormatter()
        df.dateFormat = "MM-dd"
        let key = df.string(from: date)

        let holidayInfo = holidayMap[key]
        let lunarDay = ChineseCalendarService.lunarDay(from: date)
        let festival = ChineseCalendarService.festival(for: date, holidayInfo: holidayInfo)

        return CalendarDay(
            date: date, day: day,
            isCurrentMonth: isCurrentMonth,
            isWeekend: isWeekend,
            isToday: calendar.isDate(date, inSameDayAs: today),
            lunarDay: lunarDay,
            festival: festival,
            holidayInfo: holidayInfo
        )
    }
}
