import Foundation

enum DebtType: String, Codable, CaseIterable {
    case creditCard = "creditCard"
    case loan = "loan"

    var label: String {
        switch self {
        case .creditCard: return "Tarjeta de crédito"
        case .loan:       return "Préstamo / Crédito"
        }
    }

    var icon: String {
        switch self {
        case .creditCard: return "creditcard.fill"
        case .loan:       return "banknote.fill"
        }
    }
}

enum InterestType: String, Codable, CaseIterable {
    case ea = "ea"   // Efectiva Anual
    case na = "na"   // Nominal Anual

    var label: String { self == .ea ? "E.A." : "N.A.M.V." }
}

struct Debt: Identifiable, Codable {
    var id: String
    var name: String
    var type: DebtType
    var currentBalance: Int    // Saldo snapshot cuando se ingresó/editó la deuda
    var monthlyPayment: Int
    var color: String
    var interestRate: Double?
    var interestType: InterestType
    var startDate: Date?
    var initialAmount: Int?    // Monto original del crédito al inicio
    var termMonths: Int?       // Plazo original en meses
    var balanceUpdatedAt: Date // Cuándo se guardó currentBalance (para simulación con interés)

    init(id: String = UUID().uuidString, name: String, type: DebtType,
         currentBalance: Int, monthlyPayment: Int, color: String = "#FF6B6B",
         interestRate: Double? = nil, interestType: InterestType = .ea,
         startDate: Date? = nil,
         initialAmount: Int? = nil, termMonths: Int? = nil,
         balanceUpdatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.type = type
        self.currentBalance = currentBalance
        self.monthlyPayment = monthlyPayment
        self.color = color
        self.interestRate = interestRate
        self.interestType = interestType
        self.startDate = startDate
        self.initialAmount = initialAmount
        self.termMonths = termMonths
        self.balanceUpdatedAt = balanceUpdatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(String.self, forKey: .id)
        name           = try c.decode(String.self, forKey: .name)
        type           = try c.decode(DebtType.self, forKey: .type)
        currentBalance = try c.decode(Int.self, forKey: .currentBalance)
        monthlyPayment = try c.decode(Int.self, forKey: .monthlyPayment)
        color          = (try? c.decode(String.self, forKey: .color)) ?? "#FF6B6B"
        interestRate   = try? c.decode(Double.self, forKey: .interestRate)
        interestType   = (try? c.decode(InterestType.self, forKey: .interestType)) ?? .ea
        startDate      = try? c.decode(Date.self, forKey: .startDate)
        initialAmount      = try? c.decode(Int.self, forKey: .initialAmount)
        termMonths         = try? c.decode(Int.self, forKey: .termMonths)
        balanceUpdatedAt   = (try? c.decode(Date.self, forKey: .balanceUpdatedAt)) ?? Date()
    }

    // MARK: - Financial computeds

    var monthlyRate: Double {
        guard let r = interestRate, r > 0 else { return 0 }
        let rate = r / 100
        return interestType == .ea ? pow(1 + rate, 1.0 / 12) - 1 : rate / 12
    }

    func monthsToPayOff(balance: Int, payment: Int) -> Int? {
        let r = monthlyRate
        let b = Double(balance)
        let p = Double(payment)
        guard p > 0, b > 0 else { return nil }
        if r == 0 { return Int(ceil(b / p)) }
        guard p > b * r else { return nil }
        return Int(ceil(-log(1 - b * r / p) / log(1 + r)))
    }

    func suggestedPayment(balance: Int, months: Int) -> Int {
        let r = monthlyRate
        let b = Double(balance)
        guard b > 0, months > 0 else { return 0 }
        if r == 0 { return Int(ceil(b / Double(months))) }
        let factor = pow(1 + r, Double(months))
        return Int(ceil(b * r * factor / (factor - 1)))
    }

    var currentMonthInDebt: Int? {
        guard let start = startDate else { return nil }
        return Calendar.current.dateComponents([.month], from: start, to: .now).month.map { max(1, $0 + 1) }
    }
}
