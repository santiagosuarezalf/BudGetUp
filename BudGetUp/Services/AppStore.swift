import Foundation
import FirebaseFirestore

@Observable
final class AppStore {
    var transactions: [Transaction] = []
    var categories: [Category] = []
    var accounts: [Account] = []
    var debts: [Debt] = []

    private var service: FirestoreService
    private var listeners: [ListenerRegistration] = []

    init(uid: String) {
        self.service = FirestoreService(uid: uid)
        startListening()
    }

    deinit { listeners.forEach { $0.remove() } }

    private func startListening() {
        listeners.append(service.listenTransactions { [weak self] in self?.transactions = $0 })
        listeners.append(service.listenCategories  { [weak self] in self?.categories  = $0 })
        listeners.append(service.listenAccounts    { [weak self] in self?.accounts    = $0 })
        listeners.append(service.listenDebts       { [weak self] in self?.debts       = $0 })
    }

    // MARK: - Transactions
    func addTransaction(_ tx: Transaction) { try? service.saveTransaction(tx) }
    func updateTransaction(_ tx: Transaction) { try? service.saveTransaction(tx) }
    func deleteTransaction(_ tx: Transaction) { service.deleteTransaction(id: tx.id) }

    var allTags: [String] { Array(Set(transactions.flatMap { $0.tags })).sorted() }

    // MARK: - Categories
    func addCategory(_ cat: Category) { try? service.saveCategory(cat) }
    func updateCategory(_ cat: Category) { try? service.saveCategory(cat) }
    func deleteCategory(_ cat: Category) {
        service.deleteCategory(id: cat.id)
        transactions
            .filter { $0.categoryId == cat.id }
            .forEach { var t = $0; t.categoryId = nil; try? service.saveTransaction(t) }
    }

    // MARK: - Accounts
    func addAccount(_ acc: Account) { try? service.saveAccount(acc) }
    func updateAccount(_ acc: Account) { try? service.saveAccount(acc) }
    func deleteAccount(_ acc: Account) {
        service.deleteAccount(id: acc.id)
        transactions
            .filter { $0.accountId == acc.id }
            .forEach { var t = $0; t.accountId = nil; try? service.saveTransaction(t) }
    }

    // MARK: - Debts
    func addDebt(_ debt: Debt) { try? service.saveDebt(debt) }
    func updateDebt(_ debt: Debt) { try? service.saveDebt(debt) }
    func deleteDebt(_ debt: Debt) {
        service.deleteDebt(id: debt.id)
        // Desvincular transacciones de pago asociadas
        transactions
            .filter { $0.debtId == debt.id }
            .forEach { var t = $0; t.debtId = nil; try? service.saveTransaction(t) }
    }

    func totalPaidThisMonth(for debtId: String, in month: Date) -> Int {
        let cal = Calendar.current
        return transactions
            .filter { $0.debtId == debtId && cal.isDate($0.date, equalTo: month, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    func totalPaid(for debtId: String) -> Int {
        transactions
            .filter { $0.debtId == debtId }
            .reduce(0) { $0 + $1.amount }
    }

    func effectiveBalance(for debt: Debt) -> Int {
        let r = debt.monthlyRate
        let refDate = debt.balanceUpdatedAt
        let cal = Calendar.current

        let payments = transactions
            .filter { $0.debtId == debt.id && $0.date > refDate }
            .sorted { $0.date < $1.date }

        if r == 0 {
            let paid = payments.reduce(0) { $0 + $1.amount }
            return max(0, debt.currentBalance - paid)
        }

        var paymentsByMonth: [Date: Int] = [:]
        for tx in payments {
            if let m = cal.date(from: cal.dateComponents([.year, .month], from: tx.date)) {
                paymentsByMonth[m, default: 0] += tx.amount
            }
        }

        guard let refMonth = cal.date(from: cal.dateComponents([.year, .month], from: refDate)),
              let nowMonth = cal.date(from: cal.dateComponents([.year, .month], from: Date()))
        else { return debt.currentBalance }

        var balance = Double(debt.currentBalance)
        var cursor = cal.date(byAdding: .month, value: 1, to: refMonth) ?? refMonth

        while cursor <= nowMonth {
            balance *= (1 + r)
            balance -= Double(paymentsByMonth[cursor] ?? 0)
            cursor = cal.date(byAdding: .month, value: 1, to: cursor) ?? cursor
        }

        return max(0, Int(balance))
    }

    // MARK: - Helpers
    func category(for tx: Transaction) -> Category? {
        guard let id = tx.categoryId else { return nil }
        return categories.first { $0.id == id }
    }

    func account(for tx: Transaction) -> Account? {
        guard let id = tx.accountId else { return nil }
        return accounts.first { $0.id == id }
    }

    func debt(for tx: Transaction) -> Debt? {
        guard let id = tx.debtId else { return nil }
        return debts.first { $0.id == id }
    }
}
