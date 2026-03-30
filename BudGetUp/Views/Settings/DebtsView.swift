import SwiftUI

// MARK: - DebtsView

struct DebtsView: View {
    @Environment(AppStore.self) private var store
    @State private var showAdd = false
    @State private var editTarget: Debt?

    private var sorted: [Debt] { store.debts.sorted { $0.name < $1.name } }

    var body: some View {
        List {
            ForEach(sorted) { debt in
                DebtRowSettings(debt: debt, effectiveBalance: store.effectiveBalance(for: debt))
                    .contentShape(Rectangle())
                    .onTapGesture { editTarget = debt }
            }
            .onDelete { indexSet in
                indexSet.forEach { store.deleteDebt(sorted[$0]) }
            }
        }
        .navigationTitle("Deudas")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) { DebtFormView() }
        .sheet(item: $editTarget) { debt in DebtFormView(debt: debt) }
    }
}

// MARK: - DebtRowSettings

private struct DebtRowSettings: View {
    let debt: Debt
    let effectiveBalance: Int

    var color: Color { Color(hex: debt.color) ?? .accentColor }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.15)).frame(width: 34, height: 34)
                Image(systemName: debt.type.icon).foregroundStyle(color).font(.system(size: 15))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(debt.name).font(.subheadline)
                Text(debt.type.label).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(effectiveBalance.cop).font(.caption.weight(.semibold))
                Text("\(debt.monthlyPayment.copCompact)/mes").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - DebtFormView

struct DebtFormView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var debt: Debt?

    @State private var name = ""
    @State private var type: DebtType = .creditCard
    @State private var balanceText = ""
    @State private var paymentText = ""
    @State private var color = "#FF6B6B"
    @State private var interestRateText = ""
    @State private var interestType: InterestType = .ea
    @State private var startDate: Date = .now
    @State private var hasStartDate = false
    @State private var initialAmountText = ""
    @State private var termMonthsText = ""

    private let colorOptions = [
        "#FF6B6B", "#FF8E8E", "#FF3B30", "#FF9F43", "#FF9500",
        "#FECA57", "#1DD1A1", "#34C759", "#48DBFB", "#007AFF",
        "#5E5CE6", "#AF52DE", "#BF5AF2", "#636366", "#48484A"
    ]

    private var currentBalance: Int { Int(balanceText) ?? 0 }
    private var currentPayment: Int { Int(paymentText) ?? 0 }
    private var currentRate: Double? {
        guard !interestRateText.isEmpty else { return nil }
        return Double(interestRateText.replacingOccurrences(of: ",", with: "."))
    }

    private var previewDebt: Debt {
        Debt(
            name: name, type: type,
            currentBalance: currentBalance, monthlyPayment: currentPayment, color: color,
            interestRate: currentRate, interestType: interestType,
            startDate: hasStartDate ? startDate : nil,
            initialAmount: Int(initialAmountText),
            termMonths: Int(termMonthsText)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Nombre") {
                    TextField("Ej: Visa Bancolombia", text: $name)
                }
                Section("Tipo") {
                    Picker("Tipo", selection: $type) {
                        ForEach(DebtType.allCases, id: \.self) { t in
                            Label(t.label, systemImage: t.icon).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Monto inicial del crédito (opcional)") {
                    HStack {
                        Text("$").foregroundStyle(.secondary)
                        TextField("0", text: $initialAmountText)
                            .onChange(of: initialAmountText) { _, new in initialAmountText = new.filter { $0.isNumber } }
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                        if let v = Int(initialAmountText) {
                            Text(v.cop).foregroundStyle(.secondary).font(.caption)
                        }
                    }
                }
                Section("Saldo actual") {
                    HStack {
                        Text("$").foregroundStyle(.secondary)
                        TextField("0", text: $balanceText)
                            .onChange(of: balanceText) { _, new in balanceText = new.filter { $0.isNumber } }
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                        if !balanceText.isEmpty, let v = Int(balanceText) {
                            Text(v.cop).foregroundStyle(.secondary).font(.caption)
                        }
                    }
                }
                Section("Cuota mensual") {
                    HStack {
                        Text("$").foregroundStyle(.secondary)
                        TextField("0", text: $paymentText)
                            .onChange(of: paymentText) { _, new in paymentText = new.filter { $0.isNumber } }
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                        if !paymentText.isEmpty, let v = Int(paymentText) {
                            Text(v.cop).foregroundStyle(.secondary).font(.caption)
                        }
                    }
                }
                Section("Plazo original (opcional)") {
                    HStack {
                        TextField("Ej: 36", text: $termMonthsText)
                            .onChange(of: termMonthsText) { _, new in termMonthsText = new.filter { $0.isNumber } }
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                        if !termMonthsText.isEmpty {
                            Text("meses").foregroundStyle(.secondary).font(.caption)
                        }
                    }
                }
                Section("Tasa de interés (opcional)") {
                    Picker("Tipo de tasa", selection: $interestType) {
                        ForEach(InterestType.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        TextField("Ej: 28.5", text: $interestRateText)
                            .onChange(of: interestRateText) { _, new in
                                let filtered = new.filter { $0.isNumber || $0 == "." || $0 == "," }
                                if filtered != new { interestRateText = filtered }
                            }
                        #if os(iOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Text("%").foregroundStyle(.secondary)
                    }
                }
                Section("Fecha de inicio (opcional)") {
                    Toggle("Tengo la fecha de inicio", isOn: $hasStartDate)
                    if hasStartDate {
                        DatePicker("Fecha de inicio", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .accentColor)
                                .frame(width: 30, height: 30)
                                .overlay(Circle().stroke(Color.white, lineWidth: hex == color ? 3 : 0))
                                .shadow(color: .black.opacity(hex == color ? 0.3 : 0), radius: 3)
                                .onTapGesture { color = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                if currentBalance > 0 {
                    calculatorSection
                }
            }
            .navigationTitle(debt == nil ? "Nueva deuda" : "Editar deuda")
            .onAppear { loadIfEditing() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || Int(balanceText) == nil || Int(paymentText) == nil)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 380, minHeight: 560)
        #endif
    }

    @ViewBuilder
    private var calculatorSection: some View {
        let effectiveBalance: Int = debt != nil ? store.effectiveBalance(for: debt!) : currentBalance
        let d = previewDebt
        let monthsRemaining: Int? = currentPayment > 0 ? d.monthsToPayOff(balance: effectiveBalance, payment: currentPayment) : nil
        let paymentCoversInterest: Bool = currentPayment > 0 && monthsRemaining == nil && (currentRate ?? 0) > 0

        // --- Sección de saldo y fecha estimada ---
        Section {
            calcRow(label: "Saldo efectivo", value: effectiveBalance.cop)

            if let month = d.currentMonthInDebt {
                calcRow(label: "Mes actual de la deuda", value: "Mes \(month)\(d.termMonths.map { " de \($0)" } ?? "")")
            }

            if let months = monthsRemaining {
                calcRow(label: "Meses restantes estimados", value: "\(months) meses")
                if let payoffDate = Calendar.current.date(byAdding: .month, value: months, to: .now) {
                    calcRow(label: "Fecha estimada de pago", value: monthYearFormatter.string(from: payoffDate).capitalized)
                }
            } else if paymentCoversInterest {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text("La cuota no cubre los intereses").font(.caption).foregroundStyle(.orange)
                }
            }
        } header: {
            Label("Calculadora", systemImage: "function")
        }

        // --- Línea de tiempo (solo si hay startDate + termMonths + cuota válida) ---
        if let start = d.startDate, let term = d.termMonths, let elapsed = d.currentMonthInDebt {
            Section {
                VStack(spacing: 10) {
                    GeometryReader { geo in
                        let progress = min(Double(elapsed) / Double(term), 1.0)
                        let w = geo.size.width

                        ZStack(alignment: .leading) {
                            // Línea de fondo (punteada simulada con opacidad)
                            Rectangle()
                                .fill(Color.secondary.opacity(0.25))
                                .frame(height: 2)
                            // Segmento pagado
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: w * progress, height: 2)
                            // Punto inicio
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 10, height: 10)
                                .offset(x: -0)
                            // Punto actual
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 10, height: 10)
                                .offset(x: w * progress - 5)
                            // Punto fin (vacío)
                            Circle()
                                .stroke(Color.secondary, lineWidth: 2)
                                .frame(width: 10, height: 10)
                                .offset(x: w - 5)
                        }
                    }
                    .frame(height: 10)

                    HStack {
                        Text(Calendar.monthLabel(for: start))
                            .font(.caption2).foregroundStyle(.secondary)
                        Spacer()
                        if let months = monthsRemaining,
                           let payoffDate = Calendar.current.date(byAdding: .month, value: months, to: .now) {
                            Text(monthYearFormatter.string(from: payoffDate).capitalized)
                                .font(.caption2).foregroundStyle(.secondary)
                        } else {
                            Text("Mes \(term)")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 6)
            } header: {
                Label("Progreso de la deuda", systemImage: "chart.line.downtrend.xyaxis")
            }
        }
    }

    private var monthYearFormatter: DateFormatter {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        fmt.locale = Locale(identifier: "es_CO")
        return fmt
    }

    private func calcRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold))
        }
    }

    private func loadIfEditing() {
        guard let d = debt else { return }
        name = d.name; type = d.type; color = d.color
        balanceText = "\(d.currentBalance)"; paymentText = "\(d.monthlyPayment)"
        if let r = d.interestRate { interestRateText = String(r) }
        interestType = d.interestType
        if let s = d.startDate { hasStartDate = true; startDate = s }
        if let ia = d.initialAmount { initialAmountText = "\(ia)" }
        if let tm = d.termMonths    { termMonthsText    = "\(tm)"  }
    }

    private func save() {
        let balance = Int(balanceText) ?? 0
        let payment = Int(paymentText) ?? 0
        let initAmt = Int(initialAmountText)
        let termMos = Int(termMonthsText)
        if var d = debt {
            if d.currentBalance != balance { d.balanceUpdatedAt = Date() }
            d.name = name; d.type = type; d.currentBalance = balance; d.monthlyPayment = payment; d.color = color
            d.interestRate = currentRate; d.interestType = interestType
            d.startDate = hasStartDate ? startDate : nil
            d.initialAmount = initAmt; d.termMonths = termMos
            store.updateDebt(d)
        } else {
            store.addDebt(Debt(
                name: name, type: type,
                currentBalance: balance, monthlyPayment: payment, color: color,
                interestRate: currentRate, interestType: interestType,
                startDate: hasStartDate ? startDate : nil,
                initialAmount: initAmt, termMonths: termMos,
                balanceUpdatedAt: Date()
            ))
        }
        dismiss()
    }
}
