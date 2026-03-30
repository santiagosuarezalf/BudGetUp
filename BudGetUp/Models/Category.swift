import Foundation

enum CategoryType: String, Codable, CaseIterable {
    case income = "income"
    case expense = "expense"
    case both = "both"
}

struct Category: Identifiable, Codable {
    var id: String
    var name: String
    var color: String
    var icon: String
    var type: CategoryType
    var monthlyBudget: Int?

    init(id: String = UUID().uuidString, name: String, color: String,
         icon: String, type: CategoryType, monthlyBudget: Int? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.type = type
        self.monthlyBudget = monthlyBudget
    }
}
