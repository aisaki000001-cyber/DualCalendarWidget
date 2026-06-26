import SwiftUI

/// 双月并排日历视图
struct DualMonthCalendarView: View {
    let holidayMap: [String: HolidayInfo]
    var startingMonth: Date = Date()
    var size: CalendarSize = .app

    var body: some View {
        HStack(alignment: .top, spacing: separatorSpacing) {
            MonthGridView(month: currentMonthData, size: size)
            separator
            MonthGridView(month: nextMonthData, size: size)
        }
        .padding(padding)
    }

    // MARK: - 月份

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.locale = Locale(identifier: "zh_CN")
        return cal
    }

    private var currentMonthData: CalendarMonth {
        let comps = calendar.dateComponents([.year, .month], from: startingMonth)
        return CalendarDataBuilder.build(
            year: comps.year!, month: comps.month!, holidayMap: holidayMap
        )
    }

    private var nextMonthData: CalendarMonth {
        guard let next = calendar.date(byAdding: .month, value: 1, to: startingMonth)
        else { return currentMonthData }
        let comps = calendar.dateComponents([.year, .month], from: next)
        return CalendarDataBuilder.build(
            year: comps.year!, month: comps.month!, holidayMap: holidayMap
        )
    }

    // MARK: - 布局

    private var padding: CGFloat {
        switch size {
        case .app:           return 16
        case .widgetLarge:   return 4
        case .widgetMedium:  return 2
        }
    }

    private var separatorSpacing: CGFloat {
        switch size {
        case .app:           return 16
        case .widgetLarge:   return 4
        case .widgetMedium:  return 2
        }
    }

    @ViewBuilder
    private var separator: some View {
        if size == .app {
            Divider()
        } else {
            Rectangle()
                .fill(.quaternary)
                .frame(width: 1)
        }
    }
}

// MARK: - 图例

struct CalendarLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            dot(.green, "节假日")
            dot(.red, "调休补班")
            dot(.teal, "节气")
            dot(.purple, "公历节日")
            dot(.gray, "周末")
        }
        .font(.caption2)
        .padding(.bottom, 8)
    }

    private func dot(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text).foregroundColor(.secondary)
        }
    }
}
