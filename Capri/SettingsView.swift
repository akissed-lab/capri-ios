import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: ChatStore
    @ObservedObject var memory: MemoryStore
    @ObservedObject private var notifier = Notifier.shared

    @Environment(\.dismiss) private var dismiss

    @AppStorage("capri_api_key") private var apiKey = ""
    @AppStorage("capri_base_url") private var baseURL = ""
    @AppStorage("capri_model") private var model = ""
    @AppStorage("capri_tts") private var tts = true
    @AppStorage("capri_pitch") private var pitch = 1.22
    @AppStorage("capri_notif") private var notifications = true
    @AppStorage("capri_intensity") private var intensity = 0.6

    @State private var showReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Ключ API", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Адрес API", text: $baseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    TextField("Модель", text: $model)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Нейросеть")
                } footer: {
                    Text("Ключ хранится только на телефоне. Если Google отвечает про регион — включи VPN: из России Gemini напрямую не пускает. Пустые адрес и модель — значения по умолчанию.")
                }

                Section {
                    Toggle("Озвучивать ответы", isOn: $tts)
                    HStack {
                        Image(systemName: "tortoise")
                        Slider(value: $pitch, in: 0.9...1.6, step: 0.02)
                        Image(systemName: "hare")
                    }
                    Button("Послушать голос") {
                        Config.ttsOn = true
                        store.speaker.speak("Привет. Это мой голос, привыкай.")
                    }
                } header: {
                    Text("Голос")
                } footer: {
                    Text("Ползунок выше — голос выше и звонче. Если в системе скачан улучшенный русский голос, Капри выберет его сама.")
                }

                Section {
                    Toggle("Скучать и звать", isOn: notificationsBinding)
                    Picker("Как часто", selection: intensityBinding) {
                        Text("Редко").tag(0.3)
                        Text("Обычно").tag(0.6)
                        Text("Часто").tag(0.9)
                    }
                    Button("Проверить через 8 секунд") {
                        Notifier.shared.testSoon(name: memory.name)
                    }
                } header: {
                    Text("Уведомления")
                } footer: {
                    Text(notifier.authorized
                         ? "Капри присылает пару сообщений в день в случайное время с 10 до 23. Без сервера, всё на телефоне."
                         : "Разреши уведомления — иначе Капри не сможет скучать вслух.")
                }

                Section {
                    TextField("Как тебя зовут", text: $memory.name)
                        .textInputAutocapitalization(.words)
                    ForEach(memory.facts, id: \.self) { fact in
                        HStack {
                            Text(fact)
                            Spacer()
                            Button {
                                if let index = memory.facts.firstIndex(of: fact) {
                                    memory.removeFact(at: index)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button("Забыть всё", role: .destructive) {
                        showReset = true
                    }
                } header: {
                    Text("Память")
                } footer: {
                    Text("Имя и факты Капри запоминает сама из фраз вроде «меня зовут Ярослав» или «я люблю пиццу».")
                }

                Section {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                    Link("Ключ Gemini", destination: URL(string: "https://aistudio.google.com/apikey")!)
                    Link("Как включить VPN на iPhone", destination: URL(string: "https://support.apple.com/ru-ru/guide/iphone/iph3e504502/ios")!)
                } header: {
                    Text("О приложении")
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
            .confirmationDialog("Стереть память и переписку?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Забыть всё", role: .destructive) {
                    memory.reset()
                }
                Button("Отмена", role: .cancel) {}
            }
        }
    }

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { notifications },
            set: { value in
                notifications = value
                Config.notificationsOn = value
                if value {
                    Task {
                        _ = await Notifier.shared.request()
                        Notifier.shared.reschedule(name: memory.name)
                    }
                } else {
                    Notifier.shared.cancelAll()
                }
            }
        )
    }

    private var intensityBinding: Binding<Double> {
        Binding(
            get: { intensity },
            set: { value in
                intensity = value
                Config.intensity = value
                Notifier.shared.reschedule(name: memory.name)
            }
        )
    }
}

struct KeySetupView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("capri_api_key") private var apiKey = ""

    @State private var value = ""

    var body: some View {
        ZStack {
            Background()
            VStack(spacing: 18) {
                Spacer(minLength: 24)
                Avatar(size: 84)
                Text("Я переехала в твой iPhone")
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)
                Text("Осталось дать мне ключ Gemini — тот же, что у Капри на компьютере. Он останется только на телефоне.")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)

                SecureField("Ключ API", text: $value)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )

                Button {
                    apiKey = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    dismiss()
                } label: {
                    Text("Сохранить")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Accent.gradient)
                        )
                }
                .disabled(value.trimmingCharacters(in: .whitespacesAndNewlines).count < 10)
                .opacity(value.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 ? 0.5 : 1)

                Link("Где взять ключ", destination: URL(string: "https://aistudio.google.com/apikey")!)
                    .font(.system(size: 14))

                Text("Если ответы не приходят и пишет про регион — включи VPN: Google не любит российские адреса.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)

                Spacer(minLength: 24)
            }
            .padding(24)
        }
        .interactiveDismissDisabled()
    }
}
