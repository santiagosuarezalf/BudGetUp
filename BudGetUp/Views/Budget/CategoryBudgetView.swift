import SwiftUI

struct CategoryBudgetItem {
    let category: Category
    let spent: Int
}

struct CategoryBudgetView: View {
    let items: [CategoryBudgetItem]
    var onTap: ((Category) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Presupuesto por categoría")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)

            ForEach(items.filter { $0.category.monthlyBudget != nil }, id: \.category.id) { item in
                BudgetRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture { onTap?(item.category) }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct BudgetRow: View {
    let item: CategoryBudgetItem

    private var budget: Int { item.category.monthlyBudget ?? 0 }
    private var progress: Double { budget > 0 ? min(Double(item.spent) / Double(budget), 1.2) : 0 }
    private var isOver: Bool { item.spent > budget }
    private var diff: Int { abs(item.spent - budget) }
    private var categoryColor: Color { Color(hex: item.category.color) ?? .accentColor }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                CategoryIcon(icon: item.category.icon, color: categoryColor, size: 20)
                    .frame(width: 20)
                Text(item.category.name)
                    .font(.subheadline)
                Spacer()
                if isOver {
                    Label("+\(diff.copCompact)", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                } else {
                    Text("\(item.spent.copCompact) / \(budget.copCompact)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.12))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isOver ? Color.orange : categoryColor)
                        .frame(width: geo.size.width * min(progress, 1.0), height: 6)
                        .animation(.spring(duration: 0.4), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - CategoryHistoryView

struct CategoryHistoryView: View {
    let category: Category
    let transactions: [Transaction]

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var color: Color { Color(hex: category.color) ?? .accentColor }

    private var groupedByMonth: [(key: String, label: String, total: Int, txs: [Transaction])] {
        let dict = Dictionary(grouping: transactions) { Calendar.monthKey(for: $0.date) }
        return dict.keys.sorted(by: >).map { key in
            let txs = (dict[key] ?? []).sorted { $0.date > $1.date }
            let label = Calendar.monthLabel(for: txs.first?.date ?? .now)
            let total = txs.reduce(0) { $0 + $1.amount }
            return (key: key, label: label, total: total, txs: txs)
        }
    }

    private var grandTotal: Int { transactions.reduce(0) { $0 + $1.amount } }

    var body: some View {
        NavigationStack {
            List {
                if transactions.isEmpty {
                    ContentUnavailableView(
                        "Sin transacciones",
                        systemImage: "tray",
                        description: Text("Aún no hay transacciones en esta categoría")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        HStack {
                            Text("Total histórico")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(grandTotal.cop)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(color)
                        }
                        HStack {
                            Text("Transacciones")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(transactions.count)")
                                .font(.subheadline.weight(.semibold))
                        }
                    }

                    ForEach(groupedByMonth, id: \.key) { group in
                        Section {
                            ForEach(group.txs) { tx in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tx.date, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        if !tx.tags.isEmpty {
                                            Text(tx.tags.joined(separator: " "))
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                    Spacer()
                                    Text("-\(tx.amount.cop)")
                                        .font(.subheadline.weight(.medium))
                                }
                            }
                        } header: {
                            HStack {
                                Text(group.label)
                                Spacer()
                                Text(group.total.cop)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(color)
                            }
                        }
                    }
                }
            }
            .navigationTitle(category.name)
            .navigationTitleMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 500)
        #endif
    }
}

// MARK: - BudgetTabView

struct BudgetTabView: View {
    @Environment(AppStore.self) private var store

    @State private var selectedMonth: Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: .now)) ?? .now
    }()
    @State private var historyCategory: Category? = nil

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
        store.transactions.filter {
            Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var budgetItems: [CategoryBudgetItem] {
        store.categories
            .filter { $0.monthlyBudget != nil && ($0.type == .expense || $0.type == .both) }
            .map { cat in
                let spent = monthTransactions
                    .filter { $0.type == .expense && $0.categoryId == cat.id }
                    .reduce(0) { $0 + $1.amount }
                return CategoryBudgetItem(category: cat, spent: spent)
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    MonthRibbonView(months: availableMonths, selectedMonth: $selectedMonth)

                    if budgetItems.filter({ $0.category.monthlyBudget != nil }).isEmpty {
                        ContentUnavailableView(
                            "Sin presupuesto",
                            systemImage: "chart.bar",
                            description: Text("Asigna un presupuesto mensual a tus categorías en Ajustes")
                        )
                        .padding(.top, 40)
                    } else {
                        CategoryBudgetView(
                            items: budgetItems,
                            onTap: { cat in historyCategory = cat }
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Presupuesto")
        }
        .sheet(item: $historyCategory) { cat in
            CategoryHistoryView(
                category: cat,
                transactions: store.transactions.filter { $0.categoryId == cat.id }
            )
        }
    }
}

// MARK: - Color hex helper
extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let rgb = UInt64(h, radix: 16) else { return nil }
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
