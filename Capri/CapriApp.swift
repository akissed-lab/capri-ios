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
    @StateObject private var memory = MemoryStore()
    @StateObject private var speaker = Speaker()
    @StateObject private var listener = Listener()
    @StateObject private var store: ChatStore
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let memory = MemoryStore()
        let speaker = Speaker()
        let listener = Listener()
        _memory = StateObject(wrappedValue: memory)
        _speaker = StateObject(wrappedValue: speaker)
        _listener = StateObject(wrappedValue: listener)
        _store = StateObject(wrappedValue: ChatStore(memory: memory, speaker: speaker, listener: listener))
    }

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
