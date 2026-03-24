import WidgetKit
import SwiftUI

@main
struct LensTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        LensTrackerWidget()
        LensTrackerLockScreenWidget()
    }
}
