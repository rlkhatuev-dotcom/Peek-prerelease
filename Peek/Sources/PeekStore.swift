import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class PeekStore: ObservableObject {
    @Published var data: Snapshot { didSet { save() } }
    @Published var activeModeID: UUID?
    @Published var startedAt: Date?
    @Published var distractedAt: Date?
    @Published var distractionAccumulated: TimeInterval = 0
    @Published var now = Date()
    @Published var pendingAwaySeconds: Int = 0
    @Published var events: [DistractionEvent] = []
    @Published var manualReason = "Другое приложение"
    private var wentInactiveAt: Date?
    private let file: URL
    private var ticker: Timer?
    private let sessionKey = "peek.activeSession"

    init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        file = folder.appendingPathComponent("peek.json")
        if let bytes = try? Data(contentsOf: file), let saved = try? JSONDecoder().decode(Snapshot.self, from: bytes) {
            data = saved
        } else { data = Snapshot() }
        if let saved = UserDefaults.standard.dictionary(forKey: sessionKey),
           let id = saved["modeID"] as? String,
           let uuid = UUID(uuidString:id),
           let start = saved["startedAt"] as? Date,
           data.modes.contains(where:{$0.id == uuid}) {
            activeModeID = uuid
            startedAt = start
            distractedAt = saved["distractedAt"] as? Date
            distractionAccumulated = saved["distractionAccumulated"] as? Double ?? 0
            pendingAwaySeconds = saved["pendingAwaySeconds"] as? Int ?? 0
            if let away = saved["wentInactiveAt"] as? Date, distractedAt == nil {
                pendingAwaySeconds += max(0,Int(Date().timeIntervalSince(away)))
            }
            if let stored = saved["events"] as? Data,
               let decoded = try? JSONDecoder().decode([DistractionEvent].self, from:stored) { events = decoded }
        }
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.now = Date() }
        }
    }
    var darkMode: Bool {
        get { data.darkMode }
        set { data.darkMode = newValue }
    }
    var activeMode: FocusMode? { data.modes.first { $0.id == activeModeID } }
    var elapsed: Int { guard let startedAt else { return 0 }; return max(0,Int(now.timeIntervalSince(startedAt))) }
    var distraction: Int {
        Int(distractionAccumulated + (distractedAt.map { now.timeIntervalSince($0) } ?? 0))
    }
    func save() {
        guard let bytes = try? JSONEncoder().encode(data) else { return }
        try? bytes.write(to:file, options:.atomic)
    }
    func update(_ mode: FocusMode) {
        guard let i = data.modes.firstIndex(where:{$0.id == mode.id}) else { return }
        data.modes[i] = mode
    }
    func addMode(_ name: String) {
        data.modes.append(.init(name:name,symbol:"sparkles",duration:60,reminderDelay:30,reminders:true,reminderText:"Вернись к задаче",allowedApps:"",tint:5))
    }
    private func saveSession() {
        guard let activeModeID, let startedAt else {
            UserDefaults.standard.removeObject(forKey: sessionKey)
            return
        }
        var session: [String: Any] = ["modeID":activeModeID.uuidString,"startedAt":startedAt,"distractionAccumulated":distractionAccumulated,"pendingAwaySeconds":pendingAwaySeconds]
        if let eventBytes = try? JSONEncoder().encode(events) { session["events"] = eventBytes }
        if let distractedAt { session["distractedAt"] = distractedAt }
        if let wentInactiveAt { session["wentInactiveAt"] = wentInactiveAt }
        UserDefaults.standard.set(session,forKey:sessionKey)
    }
    func appDidEnterBackground() {
        guard startedAt != nil, wentInactiveAt == nil else { return }
        wentInactiveAt = Date()
        saveSession()
    }
    func appDidBecomeActive() {
        now = Date()
        guard let away = wentInactiveAt else { return }
        wentInactiveAt = nil
        // iOS does not reveal why we left the app: call, lock screen, or another app.
        // Do not silently classify the entire interval as distraction.
        if startedAt != nil, distractedAt == nil {
            pendingAwaySeconds += max(0, Int(Date().timeIntervalSince(away)))
        }
        saveSession()
    }
    func classifyAwayTime(asDistraction: Bool, reason: String = "Другое приложение") {
        guard startedAt != nil else { pendingAwaySeconds = 0; return }
        if asDistraction {
            distractionAccumulated += Double(pendingAwaySeconds)
            if pendingAwaySeconds > 0 { events.append(.init(reason:reason,seconds:pendingAwaySeconds)) }
        }
        pendingAwaySeconds = 0
        saveSession()
    }
    func start(_ mode: FocusMode) {
        activeModeID = mode.id
        startedAt = Date()
        distractedAt = nil
        distractionAccumulated = 0
        now = Date()
        pendingAwaySeconds = 0
        wentInactiveAt = nil
        events = []
        manualReason = "Другое приложение"
        saveSession()
    }
    func beginDistraction() {
        guard startedAt != nil, distractedAt == nil else { return }
        distractedAt = Date()
        saveSession()
        if let mode = activeMode, mode.reminders, mode.reminderDelay > 0 {
            let content = UNMutableNotificationContent()
            content.title = "peek. · \(mode.name)"
            content.body = mode.reminderText
            content.sound = .default
            let request = UNNotificationRequest(identifier:"peek-distraction", content:content, trigger:UNTimeIntervalNotificationTrigger(timeInterval:TimeInterval(mode.reminderDelay), repeats:false))
            UNUserNotificationCenter.current().add(request)
        }
    }
    func endDistraction() {
        if let distractedAt {
            let seconds = max(0,Int(Date().timeIntervalSince(distractedAt)))
            distractionAccumulated += Double(seconds)
            if seconds > 0 { events.append(.init(reason:manualReason,seconds:seconds)) }
        }
        distractedAt = nil
        saveSession()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers:["peek-distraction"])
    }
    func finish(completed: Bool) {
        guard let mode = activeMode, let startedAt else { return }
        endDistraction()
        // Unclassified time away is not silently marked as distraction.
        data.records.insert(.init(modeName:mode.name,startedAt:startedAt,totalSeconds:Int(Date().timeIntervalSince(startedAt)),distractionSeconds:min(distraction,Int(Date().timeIntervalSince(startedAt))),completed:completed,events:events,unclassifiedSeconds:pendingAwaySeconds),at:0)
        self.startedAt = nil
        self.activeModeID = nil
        distractionAccumulated = 0
        pendingAwaySeconds = 0
        wentInactiveAt = nil
        events = []
        saveSession()
    }
    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options:[.alert,.sound,.badge]) { _,_ in }
    }
    func payDebt(_ id: UUID, amount: Double) {
        guard let i = data.debts.firstIndex(where:{$0.id == id}), amount > 0, amount <= data.debts[i].total - data.debts[i].paid else { return }
        data.debts[i].paid += amount
        data.money.insert(.init(title:"Погашение: \(data.debts[i].title)",amount:amount,isIncome:false),at:0)
    }
}
