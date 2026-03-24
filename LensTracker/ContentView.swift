import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(LensViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            PrescriptionView()
                .tabItem {
                    Label("Rx", systemImage: "eyeglasses")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
        }
        .tint(.blue)
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.syncWidget()
            Task {
                await NotificationManager.shared.requestAuthorization()
            }
        }
    }
}
