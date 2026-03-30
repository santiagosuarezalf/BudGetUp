import SwiftUI

struct MonthRibbonView: View {
    let months: [Date]
    @Binding var selectedMonth: Date

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(months, id: \.self) { month in
                        MonthChip(
                            date: month,
                            isSelected: Calendar.current.isDate(month, equalTo: selectedMonth, toGranularity: .month)
                        )
                        .onTapGesture { selectedMonth = month }
                        .id(month)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onAppear {
                proxy.scrollTo(selectedMonth, anchor: .center)
            }
            .onChange(of: selectedMonth) { _, new in
                withAnimation { proxy.scrollTo(new, anchor: .center) }
            }
        }
    }
}

private struct MonthChip: View {
    let date: Date
    let isSelected: Bool

    private var label: String {
        let f = DateFormatter()
        f.dateFormat = "MMM yy"
        f.locale = Locale(identifier: "es_CO")
        return f.string(from: date).capitalized
    }

    var body: some View {
        Text(label)
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
            .animation(.spring(duration: 0.25), value: isSelected)
    }
}
