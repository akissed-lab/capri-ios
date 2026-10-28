import SwiftUI
import UIKit

struct FloatingCapriOverlay: View {
    @EnvironmentObject private var store: ChatStore
    @ObservedObject private var theme = ThemeStore.shared
    @ObservedObject private var interactions = InteractionStore.shared

    @State private var offset: CGSize = CGSize(width: UIScreen.main.bounds.width - 90, height: UIScreen.main.bounds.height - 220)
    @State private var showMenu = false
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            if showMenu {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            showMenu = false
                        }
                    }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack(alignment: .bottomTrailing) {
                        if showMenu {
                            VStack(spacing: 8) {
                                GestureChip(title: "Погладить", icon: "hand.tap.fill") {
                                    Haptics.soft()
                                    store.draft = "погладить капри"
                                    store.send()
                                    close()
                                }
                                GestureChip(title: "Порадовать", icon: "heart.fill") {
                                    Haptics.soft()
                                    store.draft = "порадовать капри"
                                    store.send()
                                    close()
                                }
                                GestureChip(title: "Намекнуть на обиду", icon: "exclamationmark.bubble.fill") {
                                    Haptics.soft()
                                    store.draft = "обидеть капри"
                                    store.send()
                                    close()
                                }
                            }
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                            )
                            .shadow(color: theme.preset.glow.opacity(0.4), radius: 18, y: 10)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                            .padding(.bottom, 8)
                            .offset(x: -10)
                        }

                        CapriSpriteView(isActive: store.isThinking || store.speaker.isSpeaking, size: 86)
                            .scaleEffect(scale)
                            .shadow(color: theme.preset.glow.opacity(0.6), radius: showMenu ? 26 : 18)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = value.translation
                                    }
                                    .onEnded { value in
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            offset.width += value.translation.width
                                            offset.height += value.translation.height
                                            // Притяжение к краю
                                            let screen = UIScreen.main.bounds
                                            if offset.width > screen.width * 0.6 {
                                                offset.width = screen.width - 110
                                            }
                                            if offset.width < 40 {
                                                offset.width = 40
                                            }
                                            if offset.height > screen.height * 0.7 {
                                                offset.height = screen.height - 260
                                            }
                                            if offset.height < 120 {
                                                offset.height = 120
                                            }
                                            scale = 1.0
                                        }
                                    }
                            )
                            .onLongPressGesture(minimumDuration: 0.25) {
                                Haptics.medium()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showMenu.toggle()
                                    scale = showMenu ? 1.08 : 1.0
                                }
                            }
                            .onTapGesture {
                                Haptics.light()
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    scale = 0.96
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                        scale = 1.0
                                    }
                                }
                                // Лёгкая реакция тапом
                                store.draft = ""
                                let mem = store.memory
                                mem.add(ChatMessage(role: .assistant, text: randomTap()))
                                store.speaker.speak(randomTap())
                                CapriLiveActivityManager.shared.update(status: store.speaker.isSpeaking ? "говорит..." : "онлайн", message: "Капри рядом")
                            }
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 90)
            }
            .offset(x: offset.width - UIScreen.main.bounds.width + 110, y: offset.height - UIScreen.main.bounds.height + 200)
        }
        .allowsHitTesting(true)
    }

    private func close() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            showMenu = false
            scale = 1.0
        }
    }

    private func randomTap() -> String {
        let items = [
            "М-м? Чего хочешь?",
            "Тапаешь меня... интересный подход.",
            "Хм, любопытный. Дальше думай.",
            "Не томи, говори прямо.",
            "Я тут. Чего задумал?",
            "Ой, смелый."
        ]
        return items.randomElement() ?? items[0]
    }
}

struct GestureChip: View {
    let title: String
    let icon: String
    let action: () -> Void
    @ObservedObject private var theme = ThemeStore.shared

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                Capsule(style: .continuous)
                    .fill(theme.gradient)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
