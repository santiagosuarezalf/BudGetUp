import Foundation

enum AccountType: String, Codable, CaseIterable {
    case checking = "checking"
    case credit = "credit"
    case savings = "savings"

    var label: String {
        switch self {
        case .checking: return "Corriente"
        case .credit:   return "Crédito"
        case .savings:  return "Ahorro"
        }
    }
}

struct Account: Identifiable, Codable {
    var id: String
    var name: String
    var type: AccountType
    var color: String

    init(id: String = UUID().uuidString, name: String, type: AccountType, color: String) {
        self.id = id
        self.name = name
        self.type = type
        self.color = color
    }
}
