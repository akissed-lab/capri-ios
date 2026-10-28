import SwiftUI

struct LiveActionBar: View {
    let onPet: () -> Void
    let onUpset: () -> Void
    let onCheer: () -> Void
    let onMusic: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ActionChip(title: "Погладить", icon: "hand.raised.fill", color: Accent.pink, action: onPet)
                ActionChip(title: "Порадовать", icon: "heart.fill", color: Accent.violet, action: onCheer)
                ActionChip(title: "Намекнуть на обиду", icon: "face.dashed.fill", color: .orange, action: onUpset)
                ActionChip(title: "Поставить вайб", icon: "music.note", color: .cyan, action: onMusic)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .background(.ultraThinMaterial)
    }
}

struct ActionChip: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            Haptics.soft()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    pressed = false
                }
            }
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(LinearGradient(colors: [color.opacity(0.9), color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            )
            .scaleEffect(pressed ? 0.95 : 1.0)
            .shadow(color: color.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct MusicReactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: InteractionStore
    @State private var title = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Background()
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Реакция на музыку")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Напиши название трека/жанр — Капри отреагирует в вайбе")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 12)

                    TextField("например: фонк, lofi, джаз...", text: $title)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                        .foregroundStyle(.white)

                    Button {
                        if let reaction = store.reactToMusic(title) {
                            NotificationCenter.default.post(name: .capriMusicReaction, object: reaction)
                        }
                        dismiss()
                    } label: {
                        Text("Показать реакцию")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Accent.gradient))
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

                    Spacer()
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

extension Notification.Name {
    static let capriMusicReaction = Notification.Name("capriMusicReaction")
}
