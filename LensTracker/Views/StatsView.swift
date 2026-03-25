import SwiftUI

struct StatsView: View {
    @Environment(LensViewModel.self) private var viewModel
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                LensScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        let totalPairs = viewModel.totalPairsUsed()
                        let avgWear = viewModel.averageWearDays()
                        let compliance = viewModel.complianceRate()
                        let streak = viewModel.longestStreak()

                        LensSectionTitle(eyebrow: "Insights", title: "See the habits behind your lens routine.")
                            .padding(.horizontal)
                            .padding(.top, 8)

                        if totalPairs == 0 {
                            ContentUnavailableView(
                                "No Stats Yet",
                                systemImage: "chart.bar",
                                description: Text("Start tracking your lenses to see statistics here.")
                            )
                        } else {
                            LazyVGrid(columns: [.init(), .init()], spacing: 16) {
                                StatCard(
                                    title: "Total Pairs",
                                    value: "\(totalPairs)",
                                    icon: "eye",
                                    color: LensPalette.teal
                                )
                                StatCard(
                                    title: "Avg Wear",
                                    value: String(format: "%.1f days", avgWear),
                                    icon: "clock",
                                    color: LensPalette.gold
                                )
                                StatCard(
                                    title: "On-Time Rate",
                                    value: "\(Int(compliance * 100))%",
                                    icon: "checkmark.circle",
                                    color: compliance >= 0.8 ? LensPalette.teal : LensPalette.coral
                                )
                                StatCard(
                                    title: "Best Streak",
                                    value: "\(streak) pairs",
                                    icon: "flame",
                                    color: LensPalette.coral
                                )
                            }
                            .padding(.horizontal)

                            VStack(alignment: .leading, spacing: 10) {
                                LensSectionTitle(eyebrow: "How to Read", title: "What these numbers mean")

                                Text("**On-Time Rate** measures how often you replace your lenses within the recommended schedule, with a one-day grace period.")
                                    .font(.subheadline)
                                    .foregroundStyle(LensPalette.slate)

                                Text("**Best Streak** is your longest run of consecutive on-time replacements.")
                                    .font(.subheadline)
                                    .foregroundStyle(LensPalette.slate)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lensCardStyle()
                            .padding(.horizontal)

                            Button(role: .destructive) {
                                showResetConfirmation = true
                            } label: {
                                Label("Reset History and Stats", systemImage: "trash")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(LensPalette.coral.opacity(0.16))
                                    .foregroundStyle(LensPalette.coral)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .lensNavigationChrome()
            .confirmationDialog(
                "Reset History and Stats",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    viewModel.resetAllLensHistory()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently removes all tracked lens history and resets the stats screen.")
            }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(LensPalette.ink)

            Text(title)
                .font(.caption)
                .foregroundStyle(LensPalette.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .lensCardStyle()
    }
}
