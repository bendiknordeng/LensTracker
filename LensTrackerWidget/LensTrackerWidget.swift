import WidgetKit
import SwiftUI

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
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Lens Tracker")
        .description("See when to change your contact lenses.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HomeScreenWidgetView: View {
    @Environment(\.widgetFamily) private var family
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
                    .foregroundStyle(.secondary)
                Text("No active lenses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                        .background(.thinMaterial)
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
                            .lineLimit(1)
                        Text(data.daysRemaining == 1 ? "1 day remaining" : "\(data.daysRemaining) days remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    if data.isOverdue {
                        Link(destination: URL(string: "lenstracker://reset")!) {
                            Label("Reset", systemImage: "arrow.clockwise")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.thinMaterial)
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
                    .tint(progressColor(data))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func timerDial(_ data: WidgetLensData, size: CGFloat, lineWidth: CGFloat, numberFont: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: data.progress)
                .stroke(progressColor(data), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(data.daysRemaining)")
                    .font(.system(size: numberFont, weight: .bold, design: .rounded))
                    .foregroundStyle(progressColor(data))
                Text(data.daysRemaining == 1 ? "day left" : "days left")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: size, height: size)
    }

    private func mediumPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func progressColor(_ data: WidgetLensData) -> Color {
        if data.isOverdue { return .red }
        if data.daysRemaining <= 3 { return .orange }
        return .blue
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
                .overlay {
                    VStack(spacing: 1) {
                        Text("\(data.daysRemaining)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                        Text("d")
                            .font(.system(size: 9, weight: .medium))
                    }
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
                    Text(data.lensType)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Gauge(value: data.progress) { }
                    .gaugeStyle(.accessoryLinearCapacity)
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
