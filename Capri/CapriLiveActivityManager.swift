import ActivityKit
import Foundation

struct CapriLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String
        var message: String
        var mood: String
    }

    var name: String
}

@MainActor
final class CapriLiveActivityManager: ObservableObject {
    static let shared = CapriLiveActivityManager()
    private var activity: Activity<CapriLiveActivityAttributes>?

    func start(status: String = "онлайн", message: String = "Капri рядом") {
        guard #available(iOS 16.1, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        end()

        let attributes = CapriLiveActivityAttributes(name: "Капри")
        let state = CapriLiveActivityAttributes.ContentState(status: status, message: message, mood: InteractionStore.shared.state.mood.title)
        let content = ActivityContent(state: state, staleDate: nil)

        do {
            activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            activity = nil
        }
    }

    func update(status: String, message: String) {
        guard #available(iOS 16.1, *), let activity else { return }
        let state = CapriLiveActivityAttributes.ContentState(status: status, message: message, mood: InteractionStore.shared.state.mood.title)
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func end() {
        guard #available(iOS 16.1, *), let activity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        self.activity = nil
    }
}
