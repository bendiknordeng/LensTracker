import WidgetKit
import SwiftUI

enum WidgetLensPalette {
    static let ink = Color(red: 0.10, green: 0.16, blue: 0.19)
    static let slate = Color(red: 0.28, green: 0.36, blue: 0.41)
    static let sand = Color(red: 0.88, green: 0.82, blue: 0.70)
    static let teal = Color(red: 0.21, green: 0.56, blue: 0.56)
    static let coral = Color(red: 0.87, green: 0.42, blue: 0.35)
    static let gold = Color(red: 0.78, green: 0.60, blue: 0.28)
}

// MARK: - Shared Data (duplicated for widget target)

struct WidgetLensData {
    let startDate: Date
    let replacementDays: Int
    let lensType: String
    let isActive: Bool

    var daysRemaining: Int {
        let elapsed = Calendar.current.dateComponents([.day], from: startDate, to: .now).day ?? 0
        return max(0, replacementDays - elapsed)
    }

    var progress: Double {
        guard replacementDays > 0 else { return 1.0 }
        let elapsed = Calendar.current.dateComponents([.day], from: startDate, to: .now).day ?? 0
        return min(1.0, Double(elapsed) / Double(replacementDays))
    }

    var dueDate: Date {
        Calendar.current.date(byAdding: .day, value: replacementDays, to: startDate) ?? startDate
    }

    var isOverdue: Bool {
        daysRemaining == 0 && isActive
    }

    static func load() -> WidgetLensData? {
        guard let d = UserDefaults(suiteName: "group.com.lenstrack.shared"),
              d.object(forKey: "widget_startDate") != nil else { return nil }
        return WidgetLensData(
            startDate: Date(timeIntervalSince1970: d.double(forKey: "widget_startDate")),
            replacementDays: d.integer(forKey: "widget_replacementDays"),
            lensType: d.string(forKey: "widget_lensType") ?? "Monthly",
            isActive: d.bool(forKey: "widget_isActive")
        )
    }
}

// MARK: - Timeline

struct LensTrackerTimelineEntry: TimelineEntry {
    let date: Date
    let data: WidgetLensData?
}

struct LensTrackerTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> LensTrackerTimelineEntry {
        LensTrackerTimelineEntry(date: .now, data: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (LensTrackerTimelineEntry) -> Void) {
        completion(LensTrackerTimelineEntry(date: .now, data: WidgetLensData.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LensTrackerTimelineEntry>) -> Void) {
        let entry = LensTrackerTimelineEntry(date: .now, data: WidgetLensData.load())
        // Refresh at midnight
        let tomorrow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        completion(Timeline(entries: [entry], policy: .after(tomorrow)))
    }
}

// MARK: - Home Screen Widget

struct LensTrackerWidget: Widget {
    let kind = "LensTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LensTrackerTimelineProvider()) { entry in
            HomeScreenWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetLensBackground()
                }
        }
        .configurationDisplayName("Lens Tracker")
        .description("See when to change your contact lenses.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HomeScreenWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    let entry: LensTrackerTimelineEntry

    var body: some View {
        if let data = entry.data, data.isActive {
            switch family {
            case .systemMedium:
                mediumWidget(data)
            default:
                smallWidget(data)
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "eye")
                    .font(.largeTitle)
                    .foregroundStyle(secondaryTextColor)
                Text("No active lenses")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
            }
            .widgetURL(URL(string: "lenstracker://open"))
        }
    }

    private func smallWidget(_ data: WidgetLensData) -> some View {
        ZStack(alignment: .bottom) {
            timerDial(data, size: 114, lineWidth: 8, numberFont: 34)

            if data.isOverdue {
                Link(destination: URL(string: "lenstracker://reset")!) {
                    Label("Reset", systemImage: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(resetBackgroundColor)
                        .foregroundStyle(primaryTextColor)
                        .clipShape(Capsule())
                }
                .offset(y: 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func mediumWidget(_ data: WidgetLensData) -> some View {
        HStack(spacing: 16) {
            timerDial(data, size: 116, lineWidth: 10, numberFont: 32)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.lensType)
                            .font(.headline)
                            .foregroundStyle(primaryTextColor)
                            .lineLimit(1)
                        Text(data.daysRemaining == 1 ? "1 day remaining" : "\(data.daysRemaining) days remaining")
                            .font(.caption)
                            .foregroundStyle(secondaryTextColor)
                    }

                    Spacer(minLength: 8)

                    if data.isOverdue {
                        Link(destination: URL(string: "lenstracker://reset")!) {
                            Label("Reset", systemImage: "arrow.clockwise")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(resetBackgroundColor)
                                .foregroundStyle(primaryTextColor)
                                .clipShape(Capsule())
                        }
                    }
                }

                HStack(spacing: 8) {
                    mediumPill(title: "Started", value: data.startDate.formatted(.dateTime.month(.abbreviated).day()))
                    mediumPill(title: "Due", value: data.dueDate.formatted(.dateTime.month(.abbreviated).day()))
                }

                Gauge(value: data.progress) { }
                    .gaugeStyle(.accessoryLinearCapacity)
                    .tint(widgetProgressColor(data))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func timerDial(_ data: WidgetLensData, size: CGFloat, lineWidth: CGFloat, numberFont: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: data.progress)
                .stroke(
                    AngularGradient(
                        colors: [widgetProgressColor(data).opacity(0.45), widgetProgressColor(data), dialDepthColor],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(data.daysRemaining)")
                    .font(.system(size: numberFont, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                Text(data.daysRemaining == 1 ? "day left" : "days left")
                    .font(.caption2)
                    .foregroundStyle(secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: size, height: size)
    }

    private func mediumPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(secondaryTextColor)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(primaryTextColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var primaryTextColor: Color {
        isDarkMode ? Color.white.opacity(0.96) : WidgetLensPalette.ink
    }

    private var secondaryTextColor: Color {
        isDarkMode ? Color.white.opacity(0.68) : WidgetLensPalette.slate
    }

    private var trackColor: Color {
        isDarkMode ? Color.white.opacity(0.12) : WidgetLensPalette.slate.opacity(0.16)
    }

    private var dialDepthColor: Color {
        isDarkMode ? Color.white.opacity(0.9) : WidgetLensPalette.ink
    }

    private var cardBackgroundColor: Color {
        isDarkMode ? Color.white.opacity(0.10) : .white.opacity(0.58)
    }

    private var resetBackgroundColor: Color {
        isDarkMode ? Color.white.opacity(0.14) : .white.opacity(0.82)
    }

}

// MARK: - Lock Screen Widget

struct LensTrackerLockScreenWidget: Widget {
    let kind = "LensTrackerLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LensTrackerTimelineProvider()) { entry in
            LockScreenWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    AccessoryWidgetBackground()
                }
        }
        .configurationDisplayName("Lens Timer")
        .description("Days until lens change on your lock screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LockScreenWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: LensTrackerTimelineEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            Text("—")
        }
    }

    private var circularView: some View {
        ZStack {
            if let data = entry.data, data.isActive {
                Gauge(value: data.progress) { }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(widgetProgressColor(data))
                .overlay {
                    VStack(spacing: -1) {
                        Text("\(data.daysRemaining)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                        Image(systemName: "eye")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .widgetAccentable()
                }
            } else {
                Text("—")
            }
        }
    }

    private var rectangularView: some View {
        HStack(spacing: 8) {
            if let data = entry.data, data.isActive {
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.daysRemaining == 1 ? "1 day left" : "\(data.daysRemaining)d left")
                        .font(.headline)
                        .foregroundStyle(WidgetLensPalette.ink)
                    Text(data.lensType)
                        .font(.caption2)
                        .foregroundStyle(WidgetLensPalette.slate)
                }

                Spacer(minLength: 8)

                Gauge(value: data.progress) { }
                    .gaugeStyle(.accessoryLinearCapacity)
                    .tint(widgetProgressColor(data))
            } else {
                Text("No active lenses")
                    .font(.caption)
            }
        }
    }

    private var inlineView: some View {
        Group {
            if let data = entry.data, data.isActive {
                Text("Lens timer: \(data.daysRemaining)d left")
            } else {
                Text("Lens timer: inactive")
            }
        }
    }
}
private struct WidgetLensBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.09, green: 0.12, blue: 0.15),
                        Color(red: 0.11, green: 0.16, blue: 0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        WidgetLensPalette.teal.opacity(0.32),
                        .clear
                    ],
                    center: .topTrailing,
                    startRadius: 10,
                    endRadius: 170
                )

                RadialGradient(
                    colors: [
                        WidgetLensPalette.gold.opacity(0.12),
                        .clear
                    ],
                    center: .bottomLeading,
                    startRadius: 12,
                    endRadius: 180
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.97, blue: 0.94),
                        Color(red: 0.93, green: 0.94, blue: 0.91)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        WidgetLensPalette.sand.opacity(0.28),
                        .clear
                    ],
                    center: .topTrailing,
                    startRadius: 10,
                    endRadius: 160
                )

                RadialGradient(
                    colors: [
                        WidgetLensPalette.teal.opacity(0.16),
                        .clear
                    ],
                    center: .bottomLeading,
                    startRadius: 12,
                    endRadius: 180
                )
            }
        }
    }
}

private func widgetProgressColor(_ data: WidgetLensData) -> Color {
    if data.isOverdue { return WidgetLensPalette.coral }
    if data.daysRemaining <= 3 { return WidgetLensPalette.gold }
    return WidgetLensPalette.teal
}
