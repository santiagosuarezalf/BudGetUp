import SwiftUI
import Charts

struct MonthlyChartData: Identifiable {
    let id = UUID()
    let month: Date
    let income: Int
    let expenses: Int

    var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        f.locale = Locale(identifier: "es_CO")
        return f.string(from: month).capitalized
    }
}

struct LineChartView: View {
    let data: [MonthlyChartData]

    var body: some View {
        Chart {
            ForEach(data) { d in
                LineMark(
                    x: .value("Mes", d.monthLabel),
                    y: .value("COP", d.income)
                )
                .foregroundStyle(.green)
                .symbol(.circle)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Mes", d.monthLabel),
                    y: .value("COP", d.income)
                )
                .foregroundStyle(.green.opacity(0.08))
                .interpolationMethod(.catmullRom)
            }
            .foregroundStyle(by: .value("Tipo", "Ingresos"))

            ForEach(data) { d in
                LineMark(
                    x: .value("Mes", d.monthLabel),
                    y: .value("COP", d.expenses)
                )
                .foregroundStyle(.red)
                .symbol(.circle)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Mes", d.monthLabel),
                    y: .value("COP", d.expenses)
                )
                .foregroundStyle(.red.opacity(0.08))
                .interpolationMethod(.catmullRom)
            }
            .foregroundStyle(by: .value("Tipo", "Gastos"))
        }
        .chartForegroundStyleScale(["Ingresos": Color.green, "Gastos": Color.red])
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Int.self) {
                        Text(v.copCompact)
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartLegend(position: .top, alignment: .leading)
        .frame(height: 200)
    }
}
