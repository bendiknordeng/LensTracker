import SwiftUI

struct TimerView: View {
    @Environment(LensViewModel.self) private var viewModel
    @State private var showNewPairSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                LensScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if let active = viewModel.activeRecord() {
                            ActiveLensCard(record: active)

                            Button {
                                viewModel.resetTimer()
                            } label: {
                                Label("Change Lenses", systemImage: "arrow.triangle.2.circlepath")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [LensPalette.ink, LensPalette.slate],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                                    .background(
                                        LinearGradient(
                                            colors: [LensPalette.teal, LensPalette.ink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Lens Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .lensNavigationChrome()
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
        VStack(spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Active Pair")
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(LensPalette.teal)

                    Text(record.lensTypeName)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(LensPalette.ink)
                }

                Spacer()

                Text(record.isOverdue ? "Overdue" : "In Rotation")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(record.isOverdue ? LensPalette.coral.opacity(0.18) : LensPalette.teal.opacity(0.14))
                    .foregroundStyle(record.isOverdue ? LensPalette.coral : LensPalette.teal)
                    .clipShape(Capsule())
            }

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                progressColor.opacity(0.22),
                                .white.opacity(0.2)
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 120
                        )
                    )
                    .frame(width: 228, height: 228)

                Circle()
                    .stroke(LensPalette.slate.opacity(0.14), lineWidth: 14)
                    .frame(width: 196, height: 196)

                Circle()
                    .trim(from: 0, to: record.progress)
                    .stroke(
                        AngularGradient(
                            colors: [progressColor.opacity(0.45), progressColor, LensPalette.ink],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 196, height: 196)
                    .animation(.easeInOut, value: record.progress)

                VStack(spacing: 6) {
                    Text("\(record.daysRemaining)")
                        .font(.system(size: 58, weight: .bold, design: .rounded))
                        .foregroundStyle(LensPalette.ink)

                    Text(record.daysRemaining == 1 ? "day left" : "days left")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(LensPalette.slate)
                }
            }

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
        .lensHeroCardStyle()
        .padding(.horizontal)
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
                .foregroundStyle(LensPalette.teal)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(LensPalette.ink)
            Text(title)
                .font(.caption2)
                .foregroundStyle(LensPalette.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct NoActiveLensView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye.slash")
                .font(.system(size: 58, weight: .light))
                .foregroundStyle(LensPalette.slate)

            Text("No Active Lenses")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(LensPalette.ink)

            Text("Start tracking a new pair of contact lenses to get reminders when it's time to replace them.")
                .font(.subheadline)
                .foregroundStyle(LensPalette.slate)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .lensHeroCardStyle()
        .padding(.horizontal)
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
            LensSectionTitle(eyebrow: "Switch", title: "Try a different lens cycle")

            ForEach(alternativeTypes, id: \.self) { type in
                Button {
                    viewModel.startNewPair(type: type)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.rawValue)
                                .font(.headline)
                                .foregroundStyle(LensPalette.ink)
                            Text("\(type.defaultDays)-day schedule")
                                .font(.subheadline)
                                .foregroundStyle(LensPalette.slate)
                        }

                        Spacer()

                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                            .foregroundStyle(LensPalette.teal)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .lensCardStyle()
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
