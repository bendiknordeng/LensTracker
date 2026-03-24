import WidgetKit
import SwiftUI

// MARK: - Shared Data (duplicated for widget target)

private struct WidgetLensData {
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
    let entry: LensTrackerTimelineEntry

    var body: some View {
        if let data = entry.data, data.isActive {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: data.progress)
                        .stroke(progressColor(data), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(data.daysRemaining)")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(progressColor(data))
                        Text("days")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 70, height: 70)

                if data.isOverdue {
                    Text("Change now!")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                } else {
                    Text("Due \(data.dueDate.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
        }
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
                Gauge(value: data.progress) {
                    Image(systemName: "eye")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .overlay {
                    VStack(spacing: 0) {
                        Text("\(data.daysRemaining)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                        Text("days")
                            .font(.system(size: 8))
                    }
                }
            } else {
                Image(systemName: "eye.slash")
            }
        }
    }

    private var rectangularView: some View {
        HStack {
            if let data = entry.data, data.isActive {
                Gauge(value: data.progress) {
                    Image(systemName: "eye")
                } currentValueLabel: {
                    Text("\(data.daysRemaining)")
                }
                .gaugeStyle(.accessoryLinearCapacity)

                Text(data.isOverdue ? "Overdue!" : "\(data.daysRemaining)d left")
                    .font(.headline)
            } else {
                Text("No active lenses")
                    .font(.caption)
            }
        }
    }

    private var inlineView: some View {
        Group {
            if let data = entry.data, data.isActive {
                if data.isOverdue {
                    Text("👁 Lenses overdue!")
                } else {
                    Text("👁 \(data.daysRemaining)d until lens change")
                }
            } else {
                Text("👁 No active lenses")
            }
        }
    }
}
