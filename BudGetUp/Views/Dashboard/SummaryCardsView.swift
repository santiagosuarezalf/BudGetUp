import SwiftUI

struct SummaryCardsView: View {
    let income: Int
    let expenses: Int
    let debtPayments: Int
    var onTapIncome:   (() -> Void)? = nil
    var onTapExpenses: (() -> Void)? = nil
    var onTapBalance:  (() -> Void)? = nil
    var onTapDebt:     (() -> Void)? = nil

    var balance: Int { income - expenses - debtPayments }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                SummaryCard(title: "Ingresos", amount: income,   icon: "arrow.down.circle.fill", color: .green)
                    .contentShape(Rectangle())
                    .onTapGesture { onTapIncome?() }
                SummaryCard(title: "Gastos",   amount: expenses, icon: "arrow.up.circle.fill",   color: .red)
                    .contentShape(Rectangle())
                    .onTapGesture { onTapExpenses?() }
                SummaryCard(title: "Balance",  amount: balance,  icon: "equal.circle.fill",      color: balance >= 0 ? .blue : .orange)
                    .contentShape(Rectangle())
                    .onTapGesture { onTapBalance?() }
            }

            if debtPayments > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "creditcard.fill").font(.caption).foregroundStyle(.secondary)
                    Text("Pagos de deuda este mes:").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(debtPayments.cop).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
                .onTapGesture { onTapDebt?() }
            }
        }
    }
}

// MARK: - SummaryCard

private struct SummaryCard: View {
    let title: String
    let amount: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundStyle(color).font(.title3)
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            Text(amount.cop)
                .font(.title2.bold())
                .foregroundStyle(amount < 0 ? .red : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - MonthDetailSheet

struct MonthDetailSheet: View {
    let title: String
    let transactions: [Transaction]
    let color: Color

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var total: Int { transactions.reduce(0) { $0 + $1.amount } }

    private var grouped: [(name: String, total: Int, txs: [Transaction])] {
        let byCategory = Dictionary(grouping: transactions) { tx -> String in
            if let dId = tx.debtId, let d = store.debts.first(where: { $0.id == dId }) { return d.name }
            return store.categories.first(where: { $0.id == tx.categoryId })?.name ?? "Sin categoría"
        }
        return byCategory.map { (name: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }, txs: $0.value) }
            .sorted { $0.total > $1.total }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Total").font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Text(total.cop).font(.subheadline.weight(.semibold)).foregroundStyle(color)
                    }
                    HStack {
                        Text("Transacciones").font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(transactions.count)").font(.subheadline.weight(.semibold))
                    }
                }

                ForEach(grouped, id: \.name) { group in
                    Section {
                        ForEach(group.txs.sorted { $0.date > $1.date }) { tx in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tx.title?.isEmpty == false ? tx.title! : group.name)
                                        .font(.subheadline)
                                    Text(tx.date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(tx.amount.cop).font(.subheadline.weight(.medium))
                            }
                        }
                    } header: {
                        HStack {
                            Text(group.name)
                            Spacer()
                            Text(group.total.cop).fontWeight(.semibold).foregroundStyle(color)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationTitleMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 500)
        #endif
    }
}

// MARK: - BalanceDetailSheet

struct BalanceDetailSheet: View {
    let income: Int
    let expenses: Int
    let debtPayments: Int

    @Environment(\.dismiss) private var dismiss

    private var balance: Int { income - expenses - debtPayments }
    private var maxVal: Double { Double(max(income, expenses + debtPayments, 1)) }

    var body: some View {
        NavigationStack {
            List {
                Section("Composición del mes") {
                    balanceRow(label: "Ingresos",       amount: income,       color: .green,  sign: "+")
                    balanceRow(label: "Gastos",         amount: expenses,     color: .red,    sign: "-")
                    if debtPayments > 0 {
                        balanceRow(label: "Pagos de deuda", amount: debtPayments, color: .orange, sign: "-")
                    }
                }
                Section {
                    HStack {
                        Label("Balance neto", systemImage: "equal.circle.fill")
                            .foregroundStyle(balance >= 0 ? Color.blue : Color.orange)
                        Spacer()
                        Text(balance >= 0 ? "+\(balance.cop)" : balance.cop)
                            .font(.title3.bold())
                            .foregroundStyle(balance >= 0 ? Color.green : Color.red)
                    }
                }
            }
            .navigationTitle("Balance del mes")
            .navigationTitleMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 380, minHeight: 400)
        #endif
    }

    private func balanceRow(label: String, amount: Int, color: Color, sign: String) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(.subheadline)
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.8))
                        .frame(width: geo.size.width * CGFloat(Double(amount) / maxVal), height: 6)
                }
                .frame(height: 6)
            }
            Text("\(sign)\(amount.cop)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 110, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}
