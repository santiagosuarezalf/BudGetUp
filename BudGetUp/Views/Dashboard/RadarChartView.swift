import SwiftUI

struct RadarChartDataPoint {
    let label: String
    let value: Double    // gasto real
    let budget: Double   // presupuesto (0 si no tiene)
    let color: Color
}

struct RadarChartView: View {
    let dataPoints: [RadarChartDataPoint]

    private let rings = 4

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size * 0.38

            ZStack {
                // Grid rings
                ForEach(1...rings, id: \.self) { ring in
                    RadarGridShape(points: dataPoints.count, fraction: Double(ring) / Double(rings))
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                        .frame(width: size, height: size)
                        .position(center)
                }

                // Axes
                ForEach(dataPoints.indices, id: \.self) { i in
                    let angle = angleFor(index: i, total: dataPoints.count)
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: point(center: center, radius: radius, angle: angle))
                    }
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                }

                // Budget polygon (outer reference)
                if dataPoints.contains(where: { $0.budget > 0 }) {
                    RadarPolygon(
                        center: center,
                        radius: radius,
                        fractions: dataPoints.map { d in
                            d.budget > 0 ? min(d.value / d.budget, 1.5) : 0
                        }
                    )
                    .fill(Color.accentColor.opacity(0.08))

                    RadarPolygon(
                        center: center,
                        radius: radius,
                        fractions: dataPoints.map { d in
                            d.budget > 0 ? min(d.value / d.budget, 1.5) : 0
                        }
                    )
                    .stroke(Color.accentColor.opacity(0.5), lineWidth: 2)
                }

                // Labels
                ForEach(dataPoints.indices, id: \.self) { i in
                    let angle = angleFor(index: i, total: dataPoints.count)
                    let labelRadius = radius + 28
                    let pos = point(center: center, radius: labelRadius, angle: angle)

                    VStack(spacing: 2) {
                        Text(dataPoints[i].label)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text(dataPoints[i].value.formatted(.number.precision(.fractionLength(0))) + "K")
                            .font(.caption2)
                            .foregroundStyle(dataPoints[i].color)
                    }
                    .position(pos)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func angleFor(index: Int, total: Int) -> Double {
        let step = (2 * Double.pi) / Double(total)
        return step * Double(index) - Double.pi / 2
    }

    private func point(center: CGPoint, radius: Double, angle: Double) -> CGPoint {
        CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }
}

private struct RadarGridShape: Shape {
    let points: Int
    let fraction: Double

    func path(in rect: CGRect) -> Path {
        guard points >= 3 else { return Path() }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * fraction
        var path = Path()
        for i in 0..<points {
            let angle = (2 * Double.pi / Double(points)) * Double(i) - Double.pi / 2
            let p = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}

private struct RadarPolygon: Shape {
    let center: CGPoint
    let radius: Double
    let fractions: [Double]

    func path(in rect: CGRect) -> Path {
        guard fractions.count >= 3 else { return Path() }
        var path = Path()
        for (i, fraction) in fractions.enumerated() {
            let angle = (2 * Double.pi / Double(fractions.count)) * Double(i) - Double.pi / 2
            let r = radius * max(0, min(fraction, 1.5))
            let p = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}
