import SwiftUI

struct TimerView: View {
    @Environment(LensViewModel.self) private var viewModel
    @State private var showNewPairSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let active = viewModel.activeRecord() {
                        ActiveLensCard(record: active)

                        Button {
                            viewModel.resetTimer()
                        } label: {
                            Label("Change Lenses", systemImage: "arrow.triangle.2.circlepath")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal)

                        DifferentLensTypeActions(currentTypeName: active.lensTypeName)
                            .padding(.horizontal)
                    } else {
                        NoActiveLensView()

                        Button {
                            showNewPairSheet = true
                        } label: {
                            Label("Start Tracking", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("LensTracker")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showNewPairSheet) {
                NewPairSheet()
            }
        }
    }
}

// MARK: - Active Lens Card

private struct ActiveLensCard: View {
    let record: LensRecord
    @State private var now = Date.now
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: record.progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: record.progress)

                VStack(spacing: 4) {
                    Text("\(record.daysRemaining)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(progressColor)

                    Text(record.daysRemaining == 1 ? "day left" : "days left")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 200, height: 200)

            // Info pills
            HStack(spacing: 16) {
                InfoPill(title: "Type", value: record.lensTypeName, icon: "eye")
                InfoPill(title: "Started", value: record.startDate.formatted(.dateTime.month(.abbreviated).day()), icon: "calendar")
                InfoPill(title: "Due", value: record.dueDate.formatted(.dateTime.month(.abbreviated).day()), icon: "bell")
            }

            if record.isOverdue {
                Label("Overdue — please change your lenses!", systemImage: "exclamationmark.triangle.fill")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.red.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
            }
        }
        .padding()
        .onReceive(timer) { _ in now = .now }
    }

    var progressColor: Color {
        if record.isOverdue { return .red }
        if record.daysRemaining <= 3 { return .orange }
        return .blue
    }
}

private struct InfoPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct NoActiveLensView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Active Lenses")
                .font(.title2.weight(.semibold))

            Text("Start tracking a new pair of contact lenses to get reminders when it's time to replace them.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
    }
}

private struct DifferentLensTypeActions: View {
    @Environment(LensViewModel.self) private var viewModel
    let currentTypeName: String

    private var alternativeTypes: [LensType] {
        LensType.allCases.filter { $0.rawValue != currentTypeName }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start a Different Type")
                .font(.headline)

            ForEach(alternativeTypes, id: \.self) { type in
                Button {
                    viewModel.startNewPair(type: type)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.rawValue)
                                .font(.headline)
                            Text("\(type.defaultDays)-day schedule")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - New Pair Sheet

private struct NewPairSheet: View {
    @Environment(LensViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: LensType = .monthly

    var body: some View {
        NavigationStack {
            Form {
                Section("Lens Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(LensType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    HStack {
                        Text("Replacement interval")
                        Spacer()
                        Text("\(selectedType.defaultDays) days")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Start Tracking") {
                        viewModel.selectedLensType = selectedType
                        viewModel.startNewPair()
                        dismiss()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("New Lenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
