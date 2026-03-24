import SwiftUI

struct StatsView: View {
    @Environment(LensViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    let totalPairs = viewModel.totalPairsUsed()
                    let avgWear = viewModel.averageWearDays()
                    let compliance = viewModel.complianceRate()
                    let streak = viewModel.longestStreak()

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
                                color: .blue
                            )
                            StatCard(
                                title: "Avg Wear",
                                value: String(format: "%.1f days", avgWear),
                                icon: "clock",
                                color: .purple
                            )
                            StatCard(
                                title: "On-Time Rate",
                                value: "\(Int(compliance * 100))%",
                                icon: "checkmark.circle",
                                color: compliance >= 0.8 ? .green : .orange
                            )
                            StatCard(
                                title: "Best Streak",
                                value: "\(streak) pairs",
                                icon: "flame",
                                color: .orange
                            )
                        }
                        .padding(.horizontal)

                        // Compliance explanation
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About Your Stats")
                                .font(.headline)

                            Text("**On-Time Rate** measures how often you replace your lenses within the recommended schedule (with a 1-day grace period).")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("**Best Streak** is your longest run of consecutive on-time replacements.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
