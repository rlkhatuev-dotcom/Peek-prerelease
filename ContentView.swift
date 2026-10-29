import SwiftUI

private let palette: [Color] = [Color(red:0.88,green:0.91,blue:0.98),Color(red:0.87,green:0.95,blue:0.83),Color(red:0.98,green:0.90,blue:0.86),Color(red:0.92,green:0.88,blue:0.98),Color(red:0.98,green:0.94,blue:0.81),Color(red:0.85,green:0.94,blue:0.92)]
private func money(_ value: Double) -> String { value.formatted(.currency(code:"RUB").precision(.fractionLength(0))) }
private func clock(_ seconds: Int) -> String { String(format:"%02d:%02d:%02d",seconds/3600,(seconds/60)%60,seconds%60) }

struct ContentView: View {
    @EnvironmentObject private var store: PeekStore
    @State private var tab = 0
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        TabView(selection:$tab) {
            NavigationStack { HomeView(tab:$tab) }.tabItem { Label("Главная",systemImage:"house") }.tag(0)
            NavigationStack { ModesView() }.tabItem { Label("Режимы",systemImage:"timer") }.tag(1)
            NavigationStack { JournalView() }.tabItem { Label("Дневник",systemImage:"chart.bar") }.tag(2)
            NavigationStack { StepsView() }.tabItem { Label("Шаги",systemImage:"figure.walk") }.tag(3)
            NavigationStack { FinanceView() }.tabItem { Label("Финансы",systemImage:"wallet.pass") }.tag(4)
        }
        .tint(.primary)
        .onAppear { store.requestNotifications() }
        .onChange(of:scenePhase) { _, phase in
            switch phase {
            case .background: store.appDidEnterBackground()
            case .active: store.appDidBecomeActive()
            default: break
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: PeekStore
    @Binding var tab: Int
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                Text("Твой день").font(.largeTitle.bold())
                VStack(alignment:.leading,spacing:16) {
                    Image(systemName:"sparkles").font(.title)
                    Text("Время сосредоточиться").font(.title2.bold())
                    Text("Выбери занятие и следи за результатом.").foregroundStyle(.secondary)
                    Button("Выбрать режим") { tab = 1 }.buttonStyle(.borderedProminent)
                }.frame(maxWidth:.infinity,alignment:.leading).padding(24).background(palette[3],in:RoundedRectangle(cornerRadius:24)).foregroundStyle(.black)
                HStack(spacing:12) {
                    summary("Шаги","\(store.data.steps)","figure.walk",palette[1]) { tab = 3 }
                    summary("Баланс",money(store.data.money.reduce(0) { $0 + ($1.isIncome ? $1.amount : -$1.amount) }),"wallet.pass",palette[2]) { tab = 4 }
                }
                VStack(alignment:.leading,spacing:8) {
                    Text("Результаты").font(.headline)
                    Text("Занятий: \(store.data.records.count)")
                    Text("Отвлечений: \(store.data.records.reduce(0) {$0+$1.distractionSeconds}/60) мин")
                }.frame(maxWidth:.infinity,alignment:.leading).padding().background(.regularMaterial,in:RoundedRectangle(cornerRadius:18))
                Toggle("Тёмная тема",isOn:Binding(get:{store.darkMode},set:{store.darkMode=$0}))
            }.padding()
        }.navigationTitle("peek.").navigationBarTitleDisplayMode(.inline)
    }
    private func summary(_ title:String,_ value:String,_ icon:String,_ bg:Color,action:@escaping ()->Void)->some View {
        Button(action:action) { VStack(alignment:.leading,spacing:12) { Image(systemName:icon); Text(title).font(.caption); Text(value).font(.headline).minimumScaleFactor(0.6).lineLimit(1) }.frame(maxWidth:.infinity,alignment:.leading).padding().background(bg,in:RoundedRectangle(cornerRadius:18)).foregroundStyle(.black) }
    }
}

struct ModesView: View {
    @EnvironmentObject private var store: PeekStore
    @State private var newName = ""
    private let columns = [GridItem(.flexible()),GridItem(.flexible())]
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18) {
                Text("Мои режимы").font(.largeTitle.bold())
                LazyVGrid(columns:columns,spacing:12) {
                    ForEach(store.data.modes) { mode in
                        NavigationLink { ModeSettingsView(modeID:mode.id) } label: {
                            VStack(alignment:.leading,spacing:20) {
                                HStack { Image(systemName:mode.symbol).font(.title2); Spacer(); Image(systemName:"arrow.up.right") }
                                VStack(alignment:.leading,spacing:5) { Text(mode.name).font(.headline); Text("\(mode.duration) минут").font(.caption) }
                            }.frame(maxWidth:.infinity,alignment:.leading).padding(18).background(palette[mode.tint % palette.count],in:RoundedRectangle(cornerRadius:22)).foregroundStyle(.black)
                        }
                    }
                }
                VStack(alignment:.leading,spacing:12) {
                    Text("Свой режим").font(.headline)
                    TextField("Название",text:$newName).textFieldStyle(.roundedBorder)
                    Button("Добавить режим") { let name = newName.trimmingCharacters(in:.whitespacesAndNewlines); guard !name.isEmpty else {return}; store.addMode(name);newName="" }.disabled(newName.trimmingCharacters(in:.whitespaces).isEmpty)
                }.padding().background(.regularMaterial,in:RoundedRectangle(cornerRadius:18))
            }.padding()
        }.navigationTitle("peek.").navigationBarTitleDisplayMode(.inline)
    }
}

struct ModeSettingsView: View {
    @EnvironmentObject private var store: PeekStore
    let modeID: UUID
    @State private var showSession = false
    private var mode: FocusMode? { store.data.modes.first {$0.id == modeID} }
    private func binding<T>(_ keyPath: WritableKeyPath<FocusMode,T>, fallback:T) -> Binding<T> {
        Binding(get:{mode?[keyPath:keyPath] ?? fallback},set:{ value in guard var m=mode else{return};m[keyPath:keyPath]=value;store.update(m)})
    }
    var body: some View {
        Form {
            if let mode {
                Section {
                    HStack { Image(systemName:mode.symbol).font(.title);Text(mode.name).font(.title2.bold()) }.padding(.vertical,8)
                }.listRowBackground(palette[mode.tint % palette.count])
                Section("Продолжительность") {
                    Stepper("\(mode.duration) минут",value:binding(\.duration,fallback:60),in:15...240,step:15)
                }
                Section("Отвлечения") {
                    Toggle("Напоминать",isOn:binding(\.reminders,fallback:true))
                    Picker("Через",selection:binding(\.reminderDelay,fallback:30)) {
                        Text("Не напоминать").tag(0)
                        Text("30 секунд").tag(30)
                        Text("1 минуту").tag(60)
                        Text("2 минуты").tag(120)
                    }
                    TextField("Текст уведомления",text:binding(\.reminderText,fallback:""))
                }
                Section("Разрешённые приложения (заметка)") {
                    TextField("Например, Музыка",text:binding(\.allowedApps,fallback:""))
                    Text("Это поле пока не управляет системными ограничениями iOS.").font(.caption).foregroundStyle(.secondary)
                    NavigationLink("Настроить Screen Time") { ScreenTimePickerView() }
                }
                Section {
                    Button("Начать занятие") { store.start(mode);showSession=true }.font(.headline).frame(maxWidth:.infinity)
                }
            }
        }.navigationTitle(mode?.name ?? "Режим")
            .navigationDestination(isPresented:$showSession) { SessionView() }
    }
}

struct SessionView: View {
    @EnvironmentObject private var store: PeekStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirming = false
    var body: some View {
        VStack(spacing:22) {
            Spacer()
            Image(systemName:store.activeMode?.symbol ?? "timer").font(.system(size:40))
            Text(store.activeMode?.name ?? "Занятие").font(.title.bold())
            Text(clock(store.elapsed)).font(.system(size:48,weight:.light,design:.rounded)).monospacedDigit()
            ProgressView(value:min(Double(store.elapsed)/Double(max(store.activeMode?.duration ?? 1,1)*60),1))
            Text("Цель: \(store.activeMode?.duration ?? 0) минут").foregroundStyle(.secondary)
            VStack(spacing:10) {
                Text("Отвлечение: \(clock(store.distraction))").font(.title3.monospacedDigit())
                Button(store.distractedAt == nil ? "Начать отвлечение" : "Вернуться к занятию") {
                    if store.distractedAt == nil { store.beginDistraction() } else { store.endDistraction() }
                }.buttonStyle(.borderedProminent).tint(store.distractedAt == nil ? .orange : .green)
            }.padding(20).frame(maxWidth:.infinity).background(.regularMaterial,in:RoundedRectangle(cornerRadius:20))
            if store.pendingAwaySeconds > 0 {
                VStack(alignment:.leading,spacing:10) {
                    Text("Ты отсутствовал в peek. \(clock(store.pendingAwaySeconds))")
                        .font(.headline)
                    Text("iOS не сообщает, был ли это звонок, блокировка или другое приложение. Учитывать время как отвлечение?")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button("Да, отвлечение") { store.classifyAwayTime(asDistraction:true) }
                            .buttonStyle(.borderedProminent)
                        Button("Нет") { store.classifyAwayTime(asDistraction:false) }
                            .buttonStyle(.bordered)
                    }
                }.padding().background(.regularMaterial,in:RoundedRectangle(cornerRadius:18))
            }
            Spacer()
            Button("Завершить занятие") { confirming=true }.buttonStyle(.bordered)
        }.padding().navigationBarBackButtonHidden()
            .confirmationDialog("Ты выполнил запланированное?",isPresented:$confirming,titleVisibility:.visible) {
                Button("Да, выполнено") { store.finish(completed:true);dismiss() }
                Button("Нет, не выполнено") { store.finish(completed:false);dismiss() }
                Button("Продолжить занятие",role:.cancel) {}
            }
    }
}

struct JournalView: View {
    @EnvironmentObject private var store: PeekStore
    var body: some View {
        List {
            Section("Всего") {
                LabeledContent("Занятий","\(store.data.records.count)")
                LabeledContent("В фокусе",clock(store.data.records.reduce(0) {$0+max(0,$1.totalSeconds-$1.distractionSeconds)}))
                LabeledContent("Отвлечений",clock(store.data.records.reduce(0) {$0+$1.distractionSeconds}))
            }
            Section("История") {
                if store.data.records.isEmpty { Text("Пока нет записей").foregroundStyle(.secondary) }
                ForEach(store.data.records) { r in
                    VStack(alignment:.leading,spacing:6) {
                        HStack { Text(r.modeName).font(.headline);Spacer();Image(systemName:r.completed ? "checkmark.circle.fill" : "circle.dashed").foregroundStyle(r.completed ? .green : .orange) }
                        Text(r.startedAt,style:.date).font(.caption).foregroundStyle(.secondary)
                        Text("Время \(clock(r.totalSeconds)) · Отвлечения \(clock(r.distractionSeconds))").font(.subheadline)
                    }.padding(.vertical,5)
                }
            }
        }.navigationTitle("Дневник")
    }
}

struct StepsView: View {
    @EnvironmentObject private var store: PeekStore
    var body: some View {
        VStack(spacing:20) {
            Spacer()
            Image(systemName:"figure.walk").font(.system(size:50)).foregroundStyle(.green)
            Text("\(store.data.steps)").font(.system(size:52,weight:.semibold,design:.rounded))
            Text("из \(store.data.stepGoal) шагов").foregroundStyle(.secondary)
            ProgressView(value:min(Double(store.data.steps)/Double(store.data.stepGoal),1))
            Stepper("Цель: \(store.data.stepGoal)",value:Binding(get:{store.data.stepGoal},set:{store.data.stepGoal=$0}),in:2000...30000,step:1000)
            Button("Демо: +1000 шагов") { store.data.steps += 1000 }.buttonStyle(.bordered)
            Text("Пока демонстрационные шаги. Реальные данные потребуют подключения HealthKit.").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Spacer()
        }.padding().navigationTitle("Шагомер")
    }
}

struct FinanceView: View {
    @EnvironmentObject private var store: PeekStore
    @State private var title = ""
    @State private var amount = ""
    @State private var kind = 0
    @State private var debtPayment: [UUID:String] = [:]
    private var balance:Double {store.data.money.reduce(0) {$0+($1.isIncome ? $1.amount : -$1.amount)}}
    var body: some View {
        Form {
            Section("Баланс") { Text(money(balance)).font(.largeTitle.bold()) }
            Section("Новая операция") {
                Picker("Тип",selection:$kind) {Text("Расход").tag(0);Text("Доход").tag(1);Text("Долг").tag(2)}.pickerStyle(.segmented)
                TextField("Название",text:$title)
                TextField("Сумма",text:$amount).keyboardType(.decimalPad)
                Button("Добавить") {
                    let n=Double(amount.replacingOccurrences(of:",",with:".")) ?? 0
                    guard n>0,!title.trimmingCharacters(in:.whitespaces).isEmpty else{return}
                    if kind==2 {store.data.debts.insert(.init(title:title,total:n,paid:0),at:0)}
                    else {store.data.money.insert(.init(title:title,amount:n,isIncome:kind==1),at:0)}
                    title="";amount=""
                }
            }
            Section("Операции") {
                ForEach(store.data.money) { t in
                    HStack { Text(t.title);Spacer();Text((t.isIncome ? "+" : "−")+money(t.amount)).foregroundStyle(t.isIncome ? .green : .primary) }
                }
            }
            Section("Долги") {
                ForEach(store.data.debts) { d in
                    VStack(alignment:.leading,spacing:8) {
                        Text(d.title).font(.headline)
                        Text("Осталось: \(money(d.total-d.paid))")
                        ProgressView(value:d.total>0 ? d.paid/d.total : 1)
                        if d.paid<d.total {
                            HStack {
                                TextField("Сумма платежа",text:Binding(get:{debtPayment[d.id] ?? ""},set:{debtPayment[d.id]=$0})).keyboardType(.decimalPad)
                                Button("Оплатить") { let n=Double((debtPayment[d.id] ?? "").replacingOccurrences(of:",",with:".")) ?? 0;store.payDebt(d.id,amount:n);debtPayment[d.id]="" }
                            }
                        }
                    }.padding(.vertical,4)
                }
            }
        }.navigationTitle("Финансы")
    }
}
