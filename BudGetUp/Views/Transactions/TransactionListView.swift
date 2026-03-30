import SwiftUI

struct TransactionListView: View {
    @Environment(AppStore.self) private var store
    let transactions: [Transaction]

    private var grouped: [(key: Date, value: [Transaction])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: transactions) { cal.startOfDay(for: $0.date) }
        return dict.sorted { $0.key > $1.key }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Transacciones")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            if transactions.isEmpty {
                ContentUnavailableView(
                    "Sin transacciones",
                    systemImage: "tray",
                    description: Text("Agrega una con el botón +")
                )
                .frame(minHeight: 120)
            } else {
                ForEach(grouped, id: \.key) { day, txs in
                    Section {
                        ForEach(txs.sorted { $0.date > $1.date }) { tx in
                            ContextMenuRow(transaction: tx, store: store)
                        }
                    } header: {
                        Text(day, style: .date)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 4)
                    }
                }
            }
        }
    }
}

// MARK: - ContextMenuRow

private struct ContextMenuRow: View {
    let transaction: Transaction
    let store: AppStore
    @State private var showEdit = false

    var body: some View {
        TransactionRow(transaction: transaction, store: store)
            .contextMenu {
                Button {
                    showEdit = true
                } label: {
                    Label("Editar", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    store.deleteTransaction(transaction)
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            } preview: {
                TransactionRow(transaction: transaction, store: store)
                    .padding(.horizontal, 4)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .sheet(isPresented: $showEdit) {
                AddTransactionView(transaction: transaction)
            }
    }
}

// MARK: - TransactionRow

struct TransactionRow: View {
    let transaction: Transaction
    let store: AppStore

    private var sign: String { transaction.type == .income ? "+" : "-" }
    private var amountColor: Color {
        if transaction.type == .income { return .green }
        if transaction.debtId != nil   { return .orange }
        return .primary
    }
    private var category: Category? { store.category(for: transaction) }
    private var account: Account? { store.account(for: transaction) }
    private var debt: Debt? { store.debt(for: transaction) }
    private var categoryColor: Color {
        if let debt { return Color(hex: debt.color) ?? .secondary }
        return Color(hex: category?.color ?? "#8E8E93") ?? .secondary
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                if let debt {
                    Image(systemName: debt.type.icon)
                        .font(.system(size: 15))
                        .foregroundStyle(categoryColor)
                } else {
                    CategoryIcon(icon: category?.icon ?? "creditcard", color: categoryColor, size: 36)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                if let debt {
                    Text(debt.name).font(.subheadline)
                    Text("Pago de deuda").font(.caption).foregroundStyle(.secondary)
                } else {
                    Text(transaction.title?.isEmpty == false ? transaction.title! : (category?.name ?? "Sin categoría")).font(.subheadline)
                    if !transaction.tags.isEmpty {
                        Text(transaction.tags.joined(separator: " "))
                            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(sign)\(transaction.amount.cop)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(amountColor)
                if let acc = account {
                    Text(acc.name).font(.caption2).foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
