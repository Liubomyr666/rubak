import SwiftUI

struct ContentView: View {
    @AppStorage("blepServerURL") private var serverURL = ""
    @State private var showSettings = false

    var body: some View {
        Group {
            if serverURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ServerSetupView(serverURL: $serverURL)
            } else {
                ZStack(alignment: .topTrailing) {
                    BLEPWebView(serverURL: serverURL)

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(.black.opacity(0.72))
                            .clipShape(Circle())
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 10)
                }
                .ignoresSafeArea()
                .sheet(isPresented: $showSettings) {
                    NavigationStack {
                        ServerSetupView(serverURL: $serverURL, isSettings: true)
                    }
                }
            }
        }
    }
}

struct ServerSetupView: View {
    @Binding var serverURL: String
    var isSettings = false

    @State private var draft = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.09, blue: 0.14),
                         Color(red: 0.18, green: 0.16, blue: 0.34)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("B")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: 92, height: 92)
                .shadow(color: .blue.opacity(0.35), radius: 25)

                Text("BLEP MAP")
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(isSettings ? "Настройки подключения" : "Подключи приложение к серверу BLEP MAP")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 7) {
                    Text("АДРЕС СЕРВЕРА")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.55))

                    TextField("http://192.168.1.10:3199", text: $draft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .padding(14)
                        .foregroundStyle(.white)
                        .background(.white.opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .frame(maxWidth: 470)

                Button {
                    save()
                } label: {
                    Text(isSettings ? "Сохранить" : "Открыть BLEP MAP")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: 470)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Text("Если сервер работает на ПК, iPhone и ПК должны быть в одной Wi‑Fi сети. Возьми адрес вида http://192.168.x.x:3199 из BLEP_MAP_ADDRESS.txt на компьютере. Для VPS укажи https://твой-домен.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.48))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 470)

                Spacer()
            }
            .padding(24)
        }
        .onAppear {
            draft = serverURL
        }
        .navigationTitle("BLEP MAP")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() {
        var value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty && !value.lowercased().hasPrefix("http://") && !value.lowercased().hasPrefix("https://") {
            value = "http://" + value
        }
        while value.hasSuffix("/") {
            value.removeLast()
        }
        serverURL = value
        if isSettings && !value.isEmpty {
            dismiss()
        }
    }
}
