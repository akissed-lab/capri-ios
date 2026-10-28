import SwiftUI
import UIKit
import Combine

enum Accent {
    static let pink = Color(red: 1.00, green: 0.24, blue: 0.54)
    static let violet = Color(red: 0.55, green: 0.36, blue: 0.98)
    static let gradient = LinearGradient(
        colors: [pink, violet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum Haptics {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

struct Background: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.03, blue: 0.07),
                Color(red: 0.09, green: 0.04, blue: 0.13)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .overlay(
            RadialGradient(
                colors: [Accent.pink.opacity(0.20), .clear],
                center: .topTrailing,
                startRadius: 8,
                endRadius: 420
            )
            .ignoresSafeArea()
        )
    }
}

struct Avatar: View {
    var size: CGFloat = 38
    var pulse: Bool = false

    @State private var animate = false

    var body: some View {
        ZStack {
            if pulse {
                Circle()
                    .fill(Accent.gradient)
                    .frame(width: size + 10, height: size + 10)
                    .blur(radius: 14)
                    .opacity(animate ? 0.6 : 0.25)
                    .scaleEffect(animate ? 1.08 : 0.96)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: animate)
            }

            Circle().fill(Accent.gradient)
            Text("C")
                .font(.system(size: size * 0.46, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
        .shadow(color: Accent.pink.opacity(pulse ? 0.65 : 0.45), radius: pulse ? 14 : 10)
        .onAppear {
            if pulse {
                animate = true
            }
        }
        .onChange(of: pulse) { _, newValue in
            animate = newValue
        }
    }
}

struct ChatView: View {
    @ObservedObject var store: ChatStore
    @ObservedObject var memory: MemoryStore
    @EnvironmentObject private var listener: Listener
    @EnvironmentObject private var speaker: Speaker

    @State private var showSettings = false
    @State private var showKeySetup = false

    var body: some View {
        ZStack {
            Background()
            VStack(spacing: 0) {
                header
                Divider().overlay(Color.white.opacity(0.08))
                messageList
                inputBar
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView(store: store, memory: memory)
        }
        .fullScreenCover(isPresented: $showKeySetup) {
            KeySetupView()
        }
        .alert("Микрофон", isPresented: micAlertBinding) {
            Button("Ок", role: .cancel) { listener.error = nil }
        } message: {
            Text(listener.error ?? "")
        }
        .onAppear {
            listener.onFinish = { text in
                store.draft = text
                store.send()
            }
            store.greetIfNeeded()
            showKeySetup = !Config.keyConfigured
            Notifier.shared.requestIfNeeded()
            if Notifier.shared.consumePendingTap() {
                store.missedYou()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .capriMissedTap)) { _ in
            if Notifier.shared.consumePendingTap() {
                store.missedYou()
            }
        }
    }

    private var micAlertBinding: Binding<Bool> {
        Binding(
            get: { listener.error != nil },
            set: { newValue in
                if !newValue { listener.error = nil }
            }
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            CapriSpriteView(isActive: store.isThinking || speaker.isSpeaking, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text("Капри")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text(statusText)
                    .font(.system(size: 12))
                    .foregroundStyle(statusColor)
            }
            Spacer()
            Button {
                speaker.stop()
            } label: {
                Image(systemName: speaker.isSpeaking ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(speaker.isSpeaking ? 0.9 : 0.5))
            }
            .padding(.trailing, 4)
            Button {
                showSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var statusText: String {
        if listener.isRecording { return "слушаю…" }
        if store.isThinking { return "печатает…" }
        if speaker.isSpeaking { return "говорит" }
        return "онлайн"
    }

    private var statusColor: Color {
        if listener.isRecording { return Accent.pink }
        if store.isThinking || speaker.isSpeaking { return Accent.violet }
        return Color.white.opacity(0.55)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(memory.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                            .transition(.asymmetric(insertion: .move(edge: message.role == .assistant ? .leading : .trailing).combined(with: .opacity), removal: .opacity))
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: memory.messages.count)
                    }
                    if store.isThinking {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: memory.messages.count) { _, _ in scroll(proxy) }
            .onChange(of: store.isThinking) { _, _ in scroll(proxy) }
            .onAppear { scroll(proxy, animated: false) }
        }
    }

    private func scroll(_ proxy: ScrollViewProxy, animated: Bool = true) {
        DispatchQueue.main.async {
            let action = {
                if store.isThinking {
                    proxy.scrollTo("typing", anchor: .bottom)
                } else if let last = memory.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
            if animated {
                withAnimation(.easeOut(duration: 0.25), action)
            } else {
                action()
            }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Button {
                toggleMic()
            } label: {
                Image(systemName: listener.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(listener.isRecording ? Color.white : Accent.pink)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(listener.isRecording ? AnyShapeStyle(Accent.gradient) : AnyShapeStyle(Color.white.opacity(0.08)))
                    )
                    .scaleEffect(listener.isRecording ? 1.08 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: listener.isRecording)
            }
            .accessibilityLabel(listener.isRecording ? "Остановить запись" : "Голосом")

            TextField("Напиши Капри…", text: $store.draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .onSubmit { store.send() }

            Button {
                Haptics.medium()
                store.send()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Accent.gradient))
            }
            .disabled(store.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(store.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            .scaleEffect(store.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: store.draft)
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }

    private func toggleMic() {
        if listener.isRecording {
            Haptics.light()
            listener.stop()
        } else {
            Haptics.medium()
            speaker.stop()
            Task { await listener.start() }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 48) }
            Text(message.text)
                .font(.system(size: 16))
                .foregroundStyle(message.role == .user ? Color.white : Color.white.opacity(0.92))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(message.role == .user
                              ? AnyShapeStyle(Accent.gradient)
                              : AnyShapeStyle(Color.white.opacity(0.08)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(message.role == .assistant ? 0.12 : 0.18), lineWidth: 1)
                )
                .shadow(color: message.role == .user ? Accent.pink.opacity(0.28) : Color.black.opacity(0.25), radius: 12, y: 6)
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = message.text
                        Haptics.selection()
                    } label: {
                        Label("Скопировать", systemImage: "doc.on.doc")
                    }
                }
            if message.role == .assistant { Spacer(minLength: 48) }
        }
    }
}

struct TypingIndicator: View {
    @State private var phase = 0
    private let timer = Timer.publish(every: 0.32, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == index ? 1.25 : 0.8)
                    .opacity(phase == index ? 0.95 : 0.35)
                    .animation(.spring(response: 0.28, dampingFraction: 0.6), value: phase)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 18)
        .padding(.vertical, 8)
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}
