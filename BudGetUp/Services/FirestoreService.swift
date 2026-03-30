import Foundation
import FirebaseFirestore

final class FirestoreService {
    private let db = Firestore.firestore()
    private let uid: String

    init(uid: String) {
        self.uid = uid
    }

    // MARK: - Paths
    private var txCol: CollectionReference  { db.collection("users/\(uid)/transactions") }
    private var catCol: CollectionReference { db.collection("users/\(uid)/categories") }
    private var accCol: CollectionReference { db.collection("users/\(uid)/accounts") }
    private var debtCol: CollectionReference { db.collection("users/\(uid)/debts") }

    // MARK: - Listeners
    func listenTransactions(_ onChange: @escaping ([Transaction]) -> Void) -> ListenerRegistration {
        txCol.addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            onChange(docs.compactMap { try? $0.data(as: Transaction.self) })
        }
    }

    func listenCategories(_ onChange: @escaping ([Category]) -> Void) -> ListenerRegistration {
        catCol.addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            onChange(docs.compactMap { try? $0.data(as: Category.self) })
        }
    }

    func listenAccounts(_ onChange: @escaping ([Account]) -> Void) -> ListenerRegistration {
        accCol.addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            onChange(docs.compactMap { try? $0.data(as: Account.self) })
        }
    }

    func listenDebts(_ onChange: @escaping ([Debt]) -> Void) -> ListenerRegistration {
        debtCol.addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            onChange(docs.compactMap { try? $0.data(as: Debt.self) })
        }
    }

    // MARK: - Transactions
    func saveTransaction(_ tx: Transaction) throws {
        try txCol.document(tx.id).setData(from: tx)
    }

    func deleteTransaction(id: String) {
        txCol.document(id).delete()
    }

    // MARK: - Categories
    func saveCategory(_ cat: Category) throws {
        try catCol.document(cat.id).setData(from: cat)
    }

    func deleteCategory(id: String) {
        catCol.document(id).delete()
    }

    // MARK: - Accounts
    func saveAccount(_ acc: Account) throws {
        try accCol.document(acc.id).setData(from: acc)
    }

    func deleteAccount(id: String) {
        accCol.document(id).delete()
    }

    // MARK: - Debts
    func saveDebt(_ debt: Debt) throws {
        try debtCol.document(debt.id).setData(from: debt)
    }

    func deleteDebt(id: String) {
        debtCol.document(id).delete()
    }
}
