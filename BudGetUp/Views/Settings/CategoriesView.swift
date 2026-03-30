import SwiftUI

// MARK: - Helper

extension String {
    var isEmoji: Bool {
        unicodeScalars.first.map { $0.properties.isEmoji && $0.value > 127 } ?? false
    }
}

// MARK: - Icon View

struct CategoryIcon: View {
    let icon: String
    let color: Color
    let size: CGFloat

    var body: some View {
        if icon.isEmoji {
            Text(icon)
                .font(.system(size: size * 0.55))
                .frame(width: size, height: size)
        } else {
            Image(systemName: icon)
                .font(.system(size: size * 0.42))
                .foregroundStyle(color)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - CategoriesView

enum CategorySortMode { case nameAsc, nameDesc, grouped }

struct CategoriesView: View {
    @Environment(AppStore.self) private var store
    @State private var showAdd = false
    @State private var editTarget: Category?
    @State private var typeFilter: CategoryType? = nil
    @State private var sortMode: CategorySortMode = .nameAsc

    private var isFiltered: Bool { typeFilter != nil || sortMode != .nameAsc }

    private var filtered: [Category] {
        let base = typeFilter == nil ? store.categories : store.categories.filter { $0.type == typeFilter }
        switch sortMode {
        case .nameAsc:  return base.sorted { $0.name < $1.name }
        case .nameDesc: return base.sorted { $0.name > $1.name }
        case .grouped:
            let order: [CategoryType] = [.expense, .income, .both]
            return base.sorted {
                let ia = order.firstIndex(of: $0.type) ?? 0
                let ib = order.firstIndex(of: $1.type) ?? 0
                return ia == ib ? $0.name < $1.name : ia < ib
            }
        }
    }

    var body: some View {
        List {
            ForEach(filtered) { cat in
                CategoryRowSettings(category: cat)
                    .contentShape(Rectangle())
                    .onTapGesture { editTarget = cat }
            }
            .onDelete { indexSet in
                indexSet.forEach { store.deleteCategory(filtered[$0]) }
            }
        }
        .navigationTitle("Categorías")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Section("Filtrar por tipo") {
                        Button { typeFilter = nil } label: {
                            Label("Todos", systemImage: typeFilter == nil ? "checkmark" : "")
                        }
                        Button { typeFilter = .expense } label: {
                            Label("Gastos", systemImage: typeFilter == .expense ? "checkmark" : "")
                        }
                        Button { typeFilter = .income } label: {
                            Label("Ingresos", systemImage: typeFilter == .income ? "checkmark" : "")
                        }
                        Button { typeFilter = .both } label: {
                            Label("Ambos", systemImage: typeFilter == .both ? "checkmark" : "")
                        }
                    }
                    Section("Ordenar") {
                        Button { sortMode = .nameAsc } label: {
                            Label("A → Z", systemImage: sortMode == .nameAsc ? "checkmark" : "")
                        }
                        Button { sortMode = .nameDesc } label: {
                            Label("Z → A", systemImage: sortMode == .nameDesc ? "checkmark" : "")
                        }
                        Button { sortMode = .grouped } label: {
                            Label("Ingresos y gastos juntos", systemImage: sortMode == .grouped ? "checkmark" : "")
                        }
                    }
                } label: {
                    Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showAdd) { CategoryFormView() }
        .sheet(item: $editTarget) { cat in CategoryFormView(category: cat) }
    }
}

// MARK: - CategoryRowSettings

private struct CategoryRowSettings: View {
    let category: Category
    var color: Color { Color(hex: category.color) ?? .accentColor }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 34, height: 34)
                CategoryIcon(icon: category.icon, color: color, size: 34)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name).font(.subheadline)
                Text(category.type == .income ? "Ingreso" : category.type == .expense ? "Gasto" : "Ambos")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let b = category.monthlyBudget {
                Text(b.cop).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - CategoryFormView

struct CategoryFormView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var category: Category?

    @State private var name = ""
    @State private var color = "#5E5CE6"
    @State private var icon = "tag.fill"
    @State private var type: CategoryType = .expense
    @State private var budgetText = ""
    @State private var useEmoji = false
    @State private var emojiInput = ""

    private let iconOptions = [
        "car.fill", "fork.knife", "house.fill", "bolt.fill", "tram.fill",
        "bag.fill", "heart.fill", "book.fill", "gamecontroller.fill", "airplane",
        "cross.fill", "dumbbell.fill", "music.note", "pawprint.fill", "tag.fill",
        "creditcard.fill", "banknote", "briefcase.fill", "graduationcap.fill", "gift.fill",
        "cart.fill", "bus.fill", "figure.walk", "theatermasks.fill", "leaf.fill",
        "drop.fill", "flame.fill", "star.fill", "bell.fill", "wrench.fill"
    ]

    private let colorOptions = [
        "#FF6B6B", "#FF8E8E", "#FF3B30", "#FF9F43", "#FF9500",
        "#FECA57", "#FFD60A", "#1DD1A1", "#34C759", "#30D158",
        "#48DBFB", "#30B0C7", "#007AFF", "#0A84FF", "#5E5CE6",
        "#BF5AF2", "#AF52DE", "#FF375F", "#FF6B9D", "#C69B7B",
        "#636366", "#8E8E93", "#48484A", "#1C1C1E", "#2C2C2E"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Nombre") { TextField("Ej: Gasolina", text: $name) }
                Section("Tipo") {
                    Picker("Tipo", selection: $type) {
                        Text("Gasto").tag(CategoryType.expense)
                        Text("Ingreso").tag(CategoryType.income)
                        Text("Ambos").tag(CategoryType.both)
                    }
                    .pickerStyle(.segmented)
                }
                Section("Ícono") {
                    Picker("", selection: $useEmoji) {
                        Text("SF Symbol").tag(false)
                        Text("Emoji").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)

                    if useEmoji {
                        HStack {
                            TextField("Escribe un emoji", text: $emojiInput)
                                .onChange(of: emojiInput) { _, new in
                                    // Limitar a 1 emoji (hasta 2 escalares para emojis compuestos)
                                    let scalars = new.unicodeScalars
                                    if scalars.count > 2 {
                                        emojiInput = String(String.UnicodeScalarView(scalars.prefix(2)))
                                    }
                                    if !emojiInput.isEmpty { icon = emojiInput }
                                }
                            if !emojiInput.isEmpty {
                                Text(emojiInput).font(.largeTitle)
                            }
                        }
                        #if os(iOS)
                        Text("Abre el teclado de emojis con el botón 🌐")
                            .font(.caption).foregroundStyle(.secondary)
                        #else
                        Text("Abre el teclado de emojis con ⌘ + Ctrl + Espacio")
                            .font(.caption).foregroundStyle(.secondary)
                        #endif
                    } else {
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 12) {
                            ForEach(iconOptions, id: \.self) { sf in
                                Image(systemName: sf)
                                    .font(.title3)
                                    .foregroundStyle(sf == icon ? .white : Color(hex: color) ?? .accentColor)
                                    .frame(width: 40, height: 40)
                                    .background(sf == icon ? (Color(hex: color) ?? .accentColor) : (Color(hex: color) ?? .accentColor).opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture { icon = sf }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .accentColor)
                                .frame(width: 30, height: 30)
                                .overlay(Circle().stroke(Color.white, lineWidth: hex == color ? 3 : 0))
                                .shadow(color: .black.opacity(hex == color ? 0.3 : 0), radius: 3)
                                .onTapGesture { color = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Presupuesto mensual (opcional)") {
                    HStack {
                        Text("$")
                        TextField("Sin límite", text: $budgetText)
                            .onChange(of: budgetText) { _, new in budgetText = new.filter { $0.isNumber } }
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                    }
                }
            }
            .navigationTitle(category == nil ? "Nueva categoría" : "Editar categoría")
            .onAppear { loadIfEditing() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 540)
        #endif
    }

    private func loadIfEditing() {
        guard let cat = category else { return }
        name = cat.name; color = cat.color; type = cat.type
        if let b = cat.monthlyBudget { budgetText = "\(b)" }
        if cat.icon.isEmoji {
            useEmoji = true
            emojiInput = cat.icon
            icon = cat.icon
        } else {
            useEmoji = false
            icon = cat.icon
        }
    }

    private func save() {
        let budget = Int(budgetText)
        let finalIcon = useEmoji ? (emojiInput.isEmpty ? "tag.fill" : emojiInput) : icon
        if var cat = category {
            cat.name = name; cat.color = color; cat.icon = finalIcon; cat.type = type; cat.monthlyBudget = budget
            store.updateCategory(cat)
        } else {
            store.addCategory(Category(name: name, color: color, icon: finalIcon, type: type, monthlyBudget: budget))
        }
        dismiss()
    }
}
