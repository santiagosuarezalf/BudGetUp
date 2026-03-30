import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case income = "income"
    case expense = "expense"
}

struct Transaction: Identifiable, Codable {
    var id: String
    var amount: Int
    var type: TransactionType
    var date: Date
    var tags: [String]
    var categoryId: String?
    var accountId: String?
    var debtId: String?        // Si está presente, es un pago de deuda
    var title: String?         // Nombre personalizado (nil = mostrar categoría)

    init(id: String = UUID().uuidString, amount: Int, type: TransactionType,
         date: Date = .now, tags: [String] = [],
         categoryId: String? = nil, accountId: String? = nil,
         debtId: String? = nil, title: String? = nil) {
        self.id = id
        self.amount = amount
        self.type = type
        self.date = date
        self.tags = tags
        self.categoryId = categoryId
        self.accountId = accountId
        self.debtId = debtId
        self.title = title
    }

    // Decoder tolerante: maneja documentos viejos sin campos nuevos
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        amount = try c.decode(Int.self, forKey: .amount)
        type = try c.decode(TransactionType.self, forKey: .type)
        date = try c.decode(Date.self, forKey: .date)
        tags = (try? c.decode([String].self, forKey: .tags)) ?? []
        categoryId = try? c.decode(String.self, forKey: .categoryId)
        accountId = try? c.decode(String.self, forKey: .accountId)
        debtId = try? c.decode(String.self, forKey: .debtId)
        title = try? c.decode(String.self, forKey: .title)
    }
}
