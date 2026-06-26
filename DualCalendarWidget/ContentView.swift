import SwiftUI

struct ContentView: View {
    @State private var holidayMap: [String: HolidayInfo] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var startingMonth = Date()
    @State private var selectedYear: Int

    private let service = HolidayService.shared

    init() {
        let year = Calendar.current.component(.year, from: Date())
        _selectedYear = State(initialValue: year)
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            DualMonthCalendarView(
                holidayMap: holidayMap,
                startingMonth: startingMonth,
                size: .app
            )

            CalendarLegend()
                .padding(.top, 8)

            statusBar
        }
        .frame(minWidth: 620, idealWidth: 660,
               minHeight: 420, idealHeight: 480)
        .task {
            await service.loadHolidays(for: selectedYear)
            syncFromService()
        }
    }

    // MARK: - 工具栏

    private var toolbar: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)

            Picker("年份", selection: $selectedYear) {
                ForEach(2024...2028, id: \.self) { year in
                    Text("\(String(year))年").tag(year)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 80)
            .onChange(of: selectedYear) { newYear in
                Task {
                    await service.loadHolidays(for: newYear)
                    syncFromService()
                    let cal = Calendar.current
                    let currentYear = cal.component(.year, from: Date())
                    startingMonth = newYear == currentYear
                        ? Date()
                        : cal.date(from: DateComponents(year: newYear, month: 1, day: 1))!
                }
            }

            Text(currentMonthRange)
                .font(.title3)
                .fontWeight(.medium)

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)

            Spacer()

            // 今日日期信息
            HStack(spacing: 8) {
                Text(todayGregorian)
                    .font(.system(size: 12, weight: .medium))
                if let lunar = todayLunar {
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(lunar)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                if let special = todaySpecial {
                    Text(special)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(todaySpecialColor)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - 状态栏

    @ViewBuilder
    private var statusBar: some View {
        if isLoading {
            HStack {
                ProgressView().scaleEffect(0.7).controlSize(.small)
                Text("加载节假日数据...")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(.bottom, 6)
        } else if let error = errorMessage {
            Text(error)
                .font(.caption).foregroundColor(.orange)
                .padding(.bottom, 6)
        }
    }

    // MARK: - 同步服务状态

    private func syncFromService() {
        holidayMap = service.holidayMap
        isLoading = service.isLoading
        errorMessage = service.errorMessage
    }

    // MARK: - 今日信息

    private var todayGregorian: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "zh_CN")
        df.dateFormat = "M月d日 EEE"
        return df.string(from: Date())
    }

    private var todayLunar: String? {
        guard let lunar = ChineseCalendarService.lunarDay(from: Date()) else { return nil }
        return "\(lunar.monthName)\(lunar.dayName)"
    }

    private var todaySpecial: String? {
        let df = DateFormatter()
        df.dateFormat = "MM-dd"
        let key = df.string(from: Date())
        if let info = holidayMap[key] {
            return info.isHoliday ? info.shortName : "补班"
        }
        if let f = ChineseCalendarService.festival(for: Date(), holidayInfo: nil) {
            return f.name
        }
        return nil
    }

    private var todaySpecialColor: Color {
        let df = DateFormatter()
        df.dateFormat = "MM-dd"
        let key = df.string(from: Date())
        if let info = holidayMap[key] {
            return info.isHoliday ? .green : .red
        }
        return .teal
    }

    // MARK: - 计算 & 操作

    private var currentMonthRange: String {
        let cal = Calendar.current
        let m1 = cal.component(.month, from: startingMonth)
        let m2 = cal.component(.month, from: nextMonthDate)
        return "\(m1)月 — \(m2)月"
    }

    private var nextMonthDate: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: startingMonth) ?? startingMonth
    }

    private func previousMonth() {
        startingMonth = Calendar.current.date(byAdding: .month, value: -1, to: startingMonth) ?? startingMonth
    }

    private func nextMonth() {
        startingMonth = Calendar.current.date(byAdding: .month, value: 1, to: startingMonth) ?? startingMonth
    }

}
