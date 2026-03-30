import SwiftUI
import Charts

struct CategorySpendingPoint: Identifiable {
    let id = UUID()
    let name: String
    let amount: Int
    let color: Color
}

struct DonutChartView: View {
    let data: [CategorySpendingPoint]

    private var total: Int { data.reduce(0) { $0 + $1.amount } }

    var body: some View {
        VStack(spacing: 16) {
            Chart(data) { item in
                SectorMark(
                    angle: .value("Gasto", item.amount),
                    innerRadius: .ratio(0.55),
                    angularInset: 1.5
                )
                .foregroundStyle(item.color)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .overlay {
                VStack(spacing: 2) {
                    Text("Total").font(.caption).foregroundStyle(.secondary)
                    Text(total.copCompact).font(.title3.bold())
                }
            }

            // Leyenda
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 6) {
                ForEach(data) { item in
                    HStack(spacing: 6) {
                        Circle().fill(item.color).frame(width: 8, height: 8)
                        Text(item.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Text(item.amount.copCompact)
                            .font(.caption2.weight(.semibold))
                    }
                }
            }
        }
    }
}
