import Foundation

struct FocusMode: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var symbol: String
    var duration: Int
    var reminderDelay: Int
    var reminders: Bool
    var reminderText: String
    var allowedApps: String
    var tint: Int
    static let presets: [FocusMode] = [
        .init(name:"Работа", symbol:"briefcase", duration:90, reminderDelay:30, reminders:true, reminderText:"Вернись к работе", allowedApps:"", tint:0),
        .init(name:"Тренировка", symbol:"figure.strengthtraining.traditional", duration:120, reminderDelay:60, reminders:true, reminderText:"Продолжай тренировку", allowedApps:"Музыка", tint:1),
        .init(name:"Чтение", symbol:"book", duration:45, reminderDelay:30, reminders:true, reminderText:"Вернись к книге", allowedApps:"Книги", tint:2),
        .init(name:"Учёба", symbol:"graduationcap", duration:60, reminderDelay:30, reminders:true, reminderText:"Вернись к учёбе", allowedApps:"", tint:3),
        .init(name:"Отдых", symbol:"cup.and.saucer", duration:45, reminderDelay:0, reminders:false, reminderText:"Время отдыха", allowedApps:"", tint:4)
    ]
}
struct DistractionEvent: Codable, Identifiable {
    var id = UUID()
    var reason: String
    var seconds: Int
}
struct FocusRecord: Codable, Identifiable {
    var id = UUID()
    var modeName: String
    var startedAt: Date
    var totalSeconds: Int
    var distractionSeconds: Int
    var completed: Bool
    var events: [DistractionEvent]? = nil
    var unclassifiedSeconds: Int? = nil
}
struct MoneyEntry: Codable, Identifiable {
    var id = UUID()
    var title: String
    var amount: Double
    var isIncome: Bool
    var date = Date()
}
struct Debt: Codable, Identifiable {
    var id = UUID()
    var title: String
    var total: Double
    var paid: Double
}
struct Snapshot: Codable {
    var modes = FocusMode.presets
    var records: [FocusRecord] = []
    var money: [MoneyEntry] = [.init(title:"Доход", amount:85000, isIncome:true), .init(title:"Продукты", amount:6200, isIncome:false)]
    var debts: [Debt] = [.init(title:"Личный долг", total:50000, paid:15000)]
    var steps = 6842
    var stepGoal = 10000
    var darkMode = false
}
