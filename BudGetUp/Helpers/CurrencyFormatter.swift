import Foundation
import SwiftUI

extension Int {
    /// Formato COP: $1.200.000
    var cop: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "COP"
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: self)) ?? "$\(self)"
    }

    /// Formato compacto: $1.2M / $850K
    var copCompact: String {
        let abs = Swift.abs(self)
        let sign = self < 0 ? "-" : ""
        if abs >= 1_000_000 {
            let val = Double(abs) / 1_000_000
            return "\(sign)$\(val.formatted(.number.precision(.fractionLength(1))))M"
        } else if abs >= 1_000 {
            let val = Double(abs) / 1_000
            return "\(sign)$\(val.formatted(.number.precision(.fractionLength(0))))K"
        }
        return "\(sign)$\(abs)"
    }
}

extension Calendar {
    static func monthKey(for date: Date) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        return "\(comps.year!)-\(String(format: "%02d", comps.month!))"
    }

    static func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "es_CO")
        return formatter.string(from: date).capitalized
    }
}

// MARK: - Appearance

enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var label: String {
        switch self {
        case .system: return "Sistema"
        case .light:  return "Claro"
        case .dark:   return "Oscuro"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - Card press animation

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .brightness(configuration.isPressed ? 0.06 : 0)
            .animation(.spring(duration: 0.25, bounce: 0.5), value: configuration.isPressed)
    }
}

enum NavTitleMode { case large, inline }

extension View {
    @ViewBuilder
    func navigationTitleMode(_ mode: NavTitleMode) -> some View {
        #if os(iOS)
        if mode == .large {
            self.navigationBarTitleDisplayMode(.large)
        } else {
            self.navigationBarTitleDisplayMode(.inline)
        }
        #else
        self
        #endif
    }
}
