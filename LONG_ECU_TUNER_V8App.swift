import SwiftUI

@main
struct LONG_ECU_TUNER_V8App: App {
    @StateObject private var vm = TunerViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .preferredColorScheme(.dark)
        }
    }
}
