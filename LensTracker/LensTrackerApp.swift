import SwiftUI
import SwiftData

@main
struct LensTrackerApp: App {
    @State private var viewModel = LensViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
        .modelContainer(for: [LensRecord.self, Prescription.self])
    }
}
