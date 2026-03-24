import SwiftUI

struct HistoryView: View {
    @Environment(LensViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            ZStack {
                LensScreenBackground()

                Group {
                    let records = viewModel.allRecords()
                    if records.isEmpty {
                        ContentUnavailableView(
                            "No History",
                            systemImage: "clock.arrow.circlepath",
                            description: Text("Your lens change history will appear here once you start tracking.")
                        )
                    } else {
                        List {
                            ForEach(records, id: \.id) { record in
                                HistoryRow(record: record)
                            }
                            .onDelete { offsets in
                                for i in offsets {
                                    viewModel.deleteRecord(records[i])
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .lensNavigationChrome()
        }
    }
}

private struct HistoryRow: View {
    let record: LensRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.lensTypeName)
                        .font(.headline)
                        .foregroundStyle(LensPalette.ink)
                    if record.isActive {
                        Text("Active")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(LensPalette.teal)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(LensPalette.teal.opacity(0.16))
                            .clipShape(Capsule())
                    }
                }

                Text("\(record.startDate.formatted(.dateTime.month(.abbreviated).day())) → \(endDateText)")
                    .font(.subheadline)
                    .foregroundStyle(LensPalette.slate)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("\(wornDays)d")
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(statusColor)
                Text("of \(record.replacementDays)d")
                    .font(.caption)
                    .foregroundStyle(LensPalette.slate)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(Color.clear)
        .lensCardStyle()
    }

    private var endDateText: String {
        if record.isActive { return "now" }
        return record.endDate?.formatted(.dateTime.month(.abbreviated).day()) ?? "—"
    }

    private var wornDays: Int {
        if record.isActive { return record.daysElapsed }
        guard let end = record.endDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: record.startDate, to: end).day ?? 0
    }

    private var statusColor: Color {
        if wornDays > record.replacementDays { return .red }
        if wornDays >= record.replacementDays - 2 { return .orange }
        return LensPalette.ink
    }
}
