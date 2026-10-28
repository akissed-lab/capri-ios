import SwiftUI

@main
struct CapriApp: App {
    init() {
        // Делегат уведомлений ставим до появления окна: иначе тап,
        // который запустил приложение, потеряется.
        Notifier.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @StateObject private var store = ChatStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ChatView(store: store, memory: store.memory)
            .environmentObject(store.speaker)
            .environmentObject(store.listener)
            .onAppear {
                Notifier.shared.requestIfNeeded()
                Notifier.shared.reschedule(name: store.memory.name)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Notifier.shared.refreshStatus()
                    if Notifier.shared.consumePendingTap() {
                        store.missedYou()
                    }
                } else if phase == .background {
                    Notifier.shared.reschedule(name: store.memory.name)
                }
            }
    }
}
