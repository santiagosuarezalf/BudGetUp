import SwiftUI
import Charts

enum ChartMode { case radar, line }

struct DashboardView: View {
    @Environment(AppStore.self) private var store
    @Environment(AuthService.self) private var auth

    @State private var selectedMonth: Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: .now)) ?? .now
    }()
    @State private var showHistorical = false
    @State private var showAddTransaction = false
    @State private var chartMode: ChartMode = .radar
    @State private var txTypeFilter: TransactionType? = nil
    @State private var showIncomeDetail   = false
    @State private var showExpenseDetail  = false
    @State private var showBalanceDetail  = false
    @State private var showDebtDetail     = false

    private var availableMonths: [Date] {
        let cal = Calendar.current
        var months = Set<Date>()
        for tx in store.transactions {
            if let m = cal.date(from: cal.dateComponents([.year, .month], from: tx.date)) {
                months.insert(m)
            }
        }
        if let current = cal.date(from: cal.dateComponents([.year, .month], from: .now)) {
            months.insert(current)
        }
        return months.sorted()
    }

    private var monthTransactions: [Transaction] {
        let cal = Calendar.current
        return store.transactions.filter {
            cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var totalIncome: Int {
        monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    private var totalExpenses: Int {
        monthTransactions.filter { $0.type == .expense && $0.debtId == nil }.reduce(0) { $0 + $1.amount }
    }
    private var totalDebtPayments: Int {
        monthTransactions.filter { $0.debtId != nil }.reduce(0) { $0 + $1.amount }
    }

    private var radarData: [RadarChartDataPoint] {
        store.categories
            .filter { $0.type == .expense || $0.type == .both }
            .compactMap { cat in
                let spent = monthTransactions
                    .filter { $0.type == .expense && $0.categoryId == cat.id }
                    .reduce(0) { $0 + $1.amount }
                guard spent > 0 || cat.monthlyBudget != nil else { return nil }
                return RadarChartDataPoint(
                    label: cat.name,
                    value: Double(spent) / 1000,
                    budget: Double(cat.monthlyBudget ?? 0) / 1000,
                    color: Color(hex: cat.color) ?? .accentColor
                )
            }
    }

    private var lineData: [MonthlyChartData] {
        availableMonths.suffix(5).map { month in
            let cal = Calendar.current
            let txs = store.transactions.filter {
                cal.isDate($0.date, equalTo: month, toGranularity: .month)
            }
            return MonthlyChartData(
                month: month,
                income: txs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount },
                expenses: txs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            )
        }
    }

    private var filteredMonthTransactions: [Transaction] {
        guard let f = txTypeFilter else { return monthTransactions }
        return monthTransactions.filter { $0.type == f }
    }

    private var fab: some View {
        Button { showAddTransaction = true } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor, in: Circle())
                .shadow(color: .accentColor.opacity(0.4), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .padding(24)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text(showHistorical ? "Histórico" : Calendar.monthLabel(for: selectedMonth))
                        .font(.title2.bold())
                    Spacer()
                    Toggle("Histórico", isOn: $showHistorical.animation())
                        .toggleStyle(.button)
                        .controlSize(.small)
                    Menu {
                        Button(role: .destructive) { auth.signOut() } label: {
                            Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle").foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if showHistorical {
                    HistoricalView(months: availableMonths, store: store) { month in
                        selectedMonth = month
                        showHistorical = false
                    }
                } else {
                    MonthRibbonView(months: availableMonths, selectedMonth: $selectedMonth)

                    SummaryCardsView(
                        income: totalIncome, expenses: totalExpenses, debtPayments: totalDebtPayments,
                        onTapIncome:   { showIncomeDetail   = true },
                        onTapExpenses: { showExpenseDetail  = true },
                        onTapBalance:  { showBalanceDetail  = true },
                        onTapDebt:     { showDebtDetail     = true }
                    )
                    .padding(.horizontal, 16)

                    VStack(spacing: 12) {
                        Picker("Gráfica", selection: $chartMode) {
                            Label("Radar", systemImage: "circle.hexagongrid.fill").tag(ChartMode.radar)
                            Label("Línea", systemImage: "chart.line.uptrend.xyaxis").tag(ChartMode.line)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)

                        Group {
                            if chartMode == .radar {
                                if radarData.isEmpty {
                                    emptyChartPlaceholder(text: "Agrega gastos para ver el radar")
                                } else {
                                    RadarChartView(dataPoints: radarData)
                                        .frame(height: 280)
                                        .padding(.horizontal, 32)
                                }
                            } else {
                                if lineData.allSatisfy({ $0.income == 0 && $0.expenses == 0 }) {
                                    emptyChartPlaceholder(text: "Agrega transacciones para ver la línea")
                                } else {
                                    LineChartView(data: lineData)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        .animation(.spring(duration: 0.3), value: chartMode)
                    }
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)

                    Picker("", selection: $txTypeFilter) {
                        Text("Todos").tag(Optional<TransactionType>(nil))
                        Text("Gastos").tag(Optional(TransactionType.expense))
                        Text("Ingresos").tag(Optional(TransactionType.income))
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)

                    TransactionListView(transactions: filteredMonthTransactions)
                }
            }
            .padding(.vertical, 8)
        }
        .safeAreaInset(edge: .bottom, alignment: .trailing) { fab }
        .sheet(isPresented: $showAddTransaction) { AddTransactionView() }
        .sheet(isPresented: $showIncomeDetail) {
            MonthDetailSheet(
                title: "Ingresos",
                transactions: monthTransactions.filter { $0.type == .income },
                color: .green
            )
        }
        .sheet(isPresented: $showExpenseDetail) {
            MonthDetailSheet(
                title: "Gastos",
                transactions: monthTransactions.filter { $0.type == .expense && $0.debtId == nil },
                color: .red
            )
        }
        .sheet(isPresented: $showBalanceDetail) {
            BalanceDetailSheet(income: totalIncome, expenses: totalExpenses, debtPayments: totalDebtPayments)
        }
        .sheet(isPresented: $showDebtDetail) {
            MonthDetailSheet(
                title: "Pagos de deuda",
                transactions: monthTransactions.filter { $0.debtId != nil },
                color: .orange
            )
        }
    }

    private func emptyChartPlaceholder(text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(.secondary)
            .frame(height: 140).frame(maxWidth: .infinity)
    }
}

struct HistoricalView: View {
    let months: [Date]
    let store: AppStore
    let onSelectMonth: (Date) -> Void

    var body: some View {
        VStack(spacing: 1) {
            ForEach(months.reversed(), id: \.self) { month in
                HistoricalRow(
                    month: month,
                    transactions: store.transactions.filter {
                        Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month)
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture { onSelectMonth(month) }
                Divider().padding(.horizontal, 16)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
}

private struct HistoricalRow: View {
    let month: Date
    let transactions: [Transaction]

    private var income: Int { transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount } }
    private var expenses: Int { transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    private var balance: Int { income - expenses }
    private var maxVal: Int { max(income, expenses, 1) }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Calendar.monthLabel(for: month)).font(.subheadline.weight(.medium))
                Text(balance >= 0 ? "+\(balance.copCompact)" : balance.copCompact)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(balance >= 0 ? .green : .red)
            }
            .frame(width: 110, alignment: .leading)

            GeometryReader { geo in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3).fill(.green.opacity(0.7))
                        .frame(width: geo.size.width * CGFloat(income) / CGFloat(maxVal) * 0.5)
                    RoundedRectangle(cornerRadius: 3).fill(.red.opacity(0.7))
                        .frame(width: geo.size.width * CGFloat(expenses) / CGFloat(maxVal) * 0.5)
                    Spacer()
                }
            }
            .frame(height: 8)

            Spacer()
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
