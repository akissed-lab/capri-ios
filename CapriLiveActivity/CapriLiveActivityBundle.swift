import WidgetKit
import SwiftUI

struct CapriLiveActivityView: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CapriLiveActivityAttributes.self) { context in
            // Экран блокировки / баннер
            HStack(spacing: 12) {
                Image("CapriLive")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Капри")
                            .font(.system(size: 14, weight: .semibold))
                        Text("• \(context.state.status)")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Text(context.state.message)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(14)
            .background(
                LinearGradient(colors: [Color(red: 0.12, green: 0.06, blue: 0.18), Color(red: 0.16, green: 0.07, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .activityBackgroundTint(.clear)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image("CapriLive")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Капри")
                                .font(.system(size: 12, weight: .semibold))
                            Text(context.state.status)
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.mood)
                        .font(.system(size: 11))
                        .foregroundStyle(.pink)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.message)
                        .font(.system(size: 12))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            } compactLeading: {
                Image("CapriLive")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .clipShape(Circle())
            } compactTrailing: {
                Text(context.state.status)
                    .font(.system(size: 10))
            } minimal: {
                Image("CapriLive")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .clipShape(Circle())
            }
        }
    }
}

@main
struct CapriLiveActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        CapriLiveActivityView()
    }
}
