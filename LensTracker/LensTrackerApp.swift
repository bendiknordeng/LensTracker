import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif

@main
struct LensTrackerApp: App {
    @State private var viewModel = LensViewModel()

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [LensRecord.self, Prescription.self])
    }

    private func configureAppearance() {
#if os(iOS)
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        navigationAppearance.shadowColor = UIColor.clear
        navigationAppearance.titleTextAttributes = [.foregroundColor: UIColor(LensPalette.ink)]
        navigationAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(LensPalette.ink)]

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().tintColor = UIColor(LensPalette.teal)

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        tabAppearance.shadowColor = UIColor.clear

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().tintColor = UIColor(LensPalette.teal)
        UITabBar.appearance().unselectedItemTintColor = UIColor(LensPalette.slate)
#endif
    }
}
