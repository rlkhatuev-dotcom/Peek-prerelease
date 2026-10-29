import Foundation
import FamilyControls
import SwiftUI

// Requires the Family Controls entitlement, approved for the app target.
// Authorization is not a general-purpose foreground-app, unlock, or call event feed.
@MainActor
final class ScreenTimeAccess: ObservableObject {
    @Published var selection = FamilyActivitySelection()
    @Published var errorMessage: String?

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            errorMessage = nil
        } catch {
            errorMessage = "Не удалось получить разрешение Screen Time: \(error.localizedDescription)"
        }
    }
}

struct ScreenTimePickerView: View {
    @StateObject private var access = ScreenTimeAccess()
    @State private var showPicker = false
    var body: some View {
        Form {
            Section("Приложения, требующие контроля") {
                Button("Разрешить Screen Time") { Task { await access.requestAuthorization() } }
                Button("Выбрать приложения") { showPicker = true }
                if let error = access.errorMessage { Text(error).foregroundStyle(.red) }
            }
            Section {
                Text("Выбор приложений подготовлен. Для фонового мониторинга потребуются DeviceActivity Monitor Extension, entitlement Apple и настройка порогов. Этот экран сам по себе не отслеживает переключения между приложениями.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Screen Time")
        .familyActivityPicker(isPresented:$showPicker,selection:$access.selection)
    }
}
