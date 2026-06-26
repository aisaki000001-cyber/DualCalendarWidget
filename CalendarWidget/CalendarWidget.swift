import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 月份偏移存储

struct WidgetMonthStore {
    private static let suiteName = "group.com.dualcalendar.holidays"
    private static let key = "widget_month_offset"

    /// 当前偏移量：0=当前月, -1=上个月, +1=下个月… 范围 -12...+12
    static var offset: Int {
        get { UserDefaults(suiteName: suiteName)?.integer(forKey: key) ?? 0 }
        set { UserDefaults(suiteName: suiteName)?.set(max(-12, min(12, newValue)), forKey: key) }
    }
}

// MARK: - Timeline Entry

struct CalendarEntry: TimelineEntry {
    let date: Date
    let holidayMap: [String: HolidayInfo]
    let monthOffset: Int
}

// MARK: - Timeline Provider

struct CalendarProvider: TimelineProvider {

    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date(), holidayMap: [:], monthOffset: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        let year = Calendar.current.component(.year, from: Date())
        let holidayMap = HolidayCache.load(year: year) ?? [:]
        let offset = WidgetMonthStore.offset
        completion(CalendarEntry(date: Date(), holidayMap: holidayMap, monthOffset: offset))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let now = Date()
        let year = Calendar.current.component(.year, from: now)
        let holidayMap = HolidayCache.load(year: year) ?? [:]
        let offset = WidgetMonthStore.offset

        let entry = CalendarEntry(date: now, holidayMap: holidayMap, monthOffset: offset)

        let calendar = Calendar.current
        let nextMidnight = calendar.date(
            byAdding: .day, value: 1, to: calendar.startOfDay(for: now)
        ) ?? now.addingTimeInterval(3600)

        // 每天午夜自动刷新，翻页由 Intent 触发即时刷新
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }
}

// MARK: - 翻页 Intent

struct NavigateMonthIntent: AppIntent {
    static var title: LocalizedStringResource = "翻页"

    @Parameter(title: "方向")
    var direction: Direction

    enum Direction: String, AppEnum {
        case forward, backward

        static var typeDisplayRepresentation: TypeDisplayRepresentation = "方向"
        static var caseDisplayRepresentations: [Direction: DisplayRepresentation] = [
            .forward: "向后",
            .backward: "向前"
        ]
    }

    init() {
        self.direction = .forward
    }

    init(direction: Direction) {
        self.direction = direction
    }

    func perform() async throws -> some IntentResult {
        let current = WidgetMonthStore.offset
        WidgetMonthStore.offset = direction == .forward ? current + 1 : current - 1
        // 触发 Widget 刷新
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Widget Entry View

struct CalendarWidgetEntryView: View {
    var entry: CalendarEntry
    @Environment(\.widgetFamily) var widgetFamily

    /// 根据偏移量计算起始月份
    private var startingMonth: Date {
        Calendar.current.date(
            byAdding: .month, value: entry.monthOffset, to: Date()
        ) ?? Date()
    }

    var body: some View {
        ZStack(alignment: .top) {
            calendarContent

            // 左上 / 右上翻页小按钮
            HStack {
                navButton(direction: .backward, disabled: entry.monthOffset <= -12)
                Spacer()
                navButton(direction: .forward, disabled: entry.monthOffset >= 12)
            }
            .padding(.horizontal, 2)
            .padding(.top, 1)
        }
    }

    @ViewBuilder
    private var calendarContent: some View {
        switch widgetFamily {
        case .systemLarge:
            VStack(spacing: 4) {
                DualMonthCalendarView(
                    holidayMap: entry.holidayMap,
                    startingMonth: startingMonth,
                    size: .widgetLarge
                )
                Divider().padding(.horizontal, 8)
                TodayInfoView(holidayMap: entry.holidayMap)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 4)
            }

        case .systemMedium:
            DualMonthCalendarView(
                holidayMap: entry.holidayMap,
                startingMonth: startingMonth,
                size: .widgetMedium
            )

        default:
            DualMonthCalendarView(
                holidayMap: entry.holidayMap,
                startingMonth: startingMonth,
                size: .widgetMedium
            )
        }
    }

    // MARK: - 翻页按钮

    private func navButton(direction: NavigateMonthIntent.Direction, disabled: Bool) -> some View {
        Button(intent: NavigateMonthIntent(direction: direction)) {
            Image(systemName: direction == .backward ? "chevron.left" : "chevron.right")
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(disabled ? .clear : .secondary)
                .frame(width: 14, height: 14)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

// MARK: - 今日详情

struct TodayInfoView: View {
    let holidayMap: [String: HolidayInfo]

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("公历").font(.system(size: 7)).foregroundColor(.secondary)
                Text(gregorianString).font(.system(size: 11, weight: .medium))
            }
            if let lunar = lunarDay {
                VStack(alignment: .leading, spacing: 1) {
                    Text("农历").font(.system(size: 7)).foregroundColor(.secondary)
                    Text(lunarString(lunar)).font(.system(size: 11, weight: .medium))
                }
            }
            Spacer()
            if let special = specialToday {
                Text(special)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(specialColor)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(specialColor.opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }

    private var today: Date { Date() }

    private var gregorianString: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "zh_CN")
        df.dateFormat = "M月d日 EEEE"
        return df.string(from: today)
    }

    private var lunarDay: LunarDay? {
        ChineseCalendarService.lunarDay(from: today)
    }

    private func lunarString(_ lunar: LunarDay) -> String {
        lunar.day == 1 ? lunar.monthName : "\(lunar.monthName)\(lunar.dayName)"
    }

    private var specialToday: String? {
        let df = DateFormatter(); df.dateFormat = "MM-dd"
        let key = df.string(from: today)
        if let info = holidayMap[key] {
            return info.isHoliday ? "🎉 \(info.shortName)" : "💼 调休补班"
        }
        if let f = ChineseCalendarService.festival(for: today, holidayInfo: nil) {
            switch f.type {
            case .solarTerm: return "🌿 \(f.name)"
            case .lunar:     return "🎊 \(f.name)"
            case .gregorian: return "🎈 \(f.name)"
            default:         return f.name
            }
        }
        return nil
    }

    private var specialColor: Color {
        let df = DateFormatter(); df.dateFormat = "MM-dd"
        if let info = holidayMap[df.string(from: today)] {
            return info.isHoliday ? .green : .red
        }
        return .teal
    }
}

// MARK: - Widget Configuration

struct CalendarWidget: Widget {
    let kind: String = "com.dualcalendar.widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: CalendarProvider()
        ) { entry in
            CalendarWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("双月日历")
        .description("双月日历 + 农历节日 · 中国节假日调休标注")
        .supportedFamilies([.systemLarge, .systemMedium])
    }
}
