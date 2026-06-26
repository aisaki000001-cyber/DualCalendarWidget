import SwiftUI

/// 单日单元格
struct DayCellView: View {
    let day: CalendarDay
    var size: CalendarSize = .app
    var tightScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: subtitleSpacing) {
            // 公历日期数字
            Text("\(day.day)")
                .font(dayFont)
                .fontWeight(day.isToday ? .bold : .regular)
                .foregroundColor(dayNumberColor)
                .frame(width: todaySize, height: todaySize)
                .background(todayCircle)
                .overlay(alignment: .topTrailing) {
                    if showHolidayDot {
                        Circle()
                            .fill(.green)
                            .frame(width: dotSize, height: dotSize)
                            .offset(x: dotOffset, y: -dotOffset)
                    } else if showMakeupDot {
                        Circle()
                            .fill(.red)
                            .frame(width: dotSize, height: dotSize)
                            .offset(x: dotOffset, y: -dotOffset)
                    }
                }

            // 副标题（节日 / 农历）— 非本月也显示，跟随整体透明度
            if let subtitle = day.subtitle {
                Text(subtitle)
                    .font(subFont)
                    .foregroundColor(subtitleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, cellPadding)
        .opacity(day.isCurrentMonth ? 1.0 : 0.9)
    }

    // MARK: - 尺寸

    private var cellPadding: CGFloat {
        switch size {
        case .app:           return 2
        case .widgetLarge:   return 2
        case .widgetMedium:  return 0
        }
    }

    private var subtitleSpacing: CGFloat {
        switch size {
        case .app:           return 1
        case .widgetLarge:   return 1
        case .widgetMedium:  return 0
        }
    }

    private var dayFont: Font {
        .system(size: dayBaseSize * tightScale, weight: day.isToday ? .bold : .regular)
    }

    private var subFont: Font {
        .system(size: subBaseSize * tightScale)
    }

    private var dayBaseSize: CGFloat {
        switch size { case .app: return 14; case .widgetLarge: return 13; case .widgetMedium: return 10 }
    }
    private var subBaseSize: CGFloat {
        switch size { case .app: return 8; case .widgetLarge: return 7; case .widgetMedium: return 5 }
    }
    private var todayBaseSize: CGFloat {
        switch size { case .app: return 28; case .widgetLarge: return 24; case .widgetMedium: return 16 }
    }

    private var todaySize: CGFloat {
        todayBaseSize * tightScale
    }

    // MARK: - 今天圆圈

    @ViewBuilder
    private var todayCircle: some View {
        if day.isToday && day.isCurrentMonth {
            Circle()
                .fill(Color.blue)
                .frame(width: todaySize, height: todaySize)
        }
    }

    // MARK: - 节假日圆点标记

    /// 绿点：法定节假日 + 农历节日（不拘本月/非本月）
    private var showHolidayDot: Bool {
        if let info = day.holidayInfo, info.isHoliday { return true }
        if let f = day.festival, f.type == .lunar { return true }
        return false
    }

    /// 红点：调休补班日（非今天，今天已有蓝圈）
    private var showMakeupDot: Bool {
        guard !day.isToday else { return false }
        if let info = day.holidayInfo, !info.isHoliday { return true }
        return false
    }

    private var dotBaseSize: CGFloat {
        switch size { case .app: return 5; case .widgetLarge: return 4; case .widgetMedium: return 3 }
    }
    private var dotSize: CGFloat { dotBaseSize * tightScale }

    private var dotBaseOffset: CGFloat {
        switch size { case .app: return 2; case .widgetLarge: return 1; case .widgetMedium: return 0 }
    }
    private var dotOffset: CGFloat { dotBaseOffset * tightScale }

    // MARK: - 颜色

    private var dayNumberColor: Color {
        if !day.isCurrentMonth { return .secondary }
        if day.isToday { return .white }
        switch day.dayNumberColor {
        case .holiday:       return .green
        case .makeupDay:     return .red
        case .weekend:       return .gray
        default:             return .primary
        }
    }

    private var subtitleColor: Color {
        if !day.isCurrentMonth { return .secondary.opacity(0.6) }
        switch day.subtitleColor {
        case .holiday:            return .green
        case .makeupDay:          return .red
        case .solarTerm:          return .teal
        case .lunarFestival:      return .green
        case .gregorianFestival:  return .purple
        default:                  return .secondary
        }
    }
}
