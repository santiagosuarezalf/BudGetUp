import SwiftUI

struct CategoryBarsView: View {
    let data: [CategorySpendingPoint]

    private var maxAmount: Int { data.first?.amount ?? 1 }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(data) { item in
                HStack(spacing: 10) {
                    Text(item.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 90, alignment: .leading)
                        .lineLimit(1)

                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.color.opacity(0.85))
                            .frame(width: geo.size.width * CGFloat(item.amount) / CGFloat(maxAmount))
                            .animation(.spring(duration: 0.5, bounce: 0.2), value: item.amount)
                    }
                    .frame(height: 18)

                    Text(item.amount.copCompact)
                        .font(.caption.weight(.semibold))
                        .frame(width: 60, alignment: .trailing)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
