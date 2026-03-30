import SwiftUI

struct AddTransactionView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var transaction: Transaction? = nil

    @State private var titleText = ""
    @State private var amountText = ""
    @State private var type: TransactionType = .expense
    @State private var selectedCategoryId: String?
    @State private var selectedAccountId: String?
    @State private var date = Date.now
    @State private var tags: [String] = []
    @State private var tagInput = ""
    @State private var showAddCategory = false
    @State private var showAddAccount = false
    @State private var showAccountPicker = false
    @State private var isDebtPayment = false
    @State private var selectedDebtId: String?

    private var amount: Int { Int(amountText.filter { $0.isNumber }) ?? 0 }
    private var filteredCategories: [Category] {
        store.categories.filter { $0.type == .both || $0.type.rawValue == type.rawValue }
    }
    private var canSave: Bool { amount > 0 && selectedCategoryId != nil }

    private var tagSuggestions: [String] {
        guard !tagInput.isEmpty else { return [] }
        let query = tagInput.lowercased().trimmingCharacters(in: .whitespaces)
        return store.allTags
            .filter { $0.contains(query) && !tags.contains($0) }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Campo de nombre prominente
                Section {
                    TextField("Nombre de la transacción", text: $titleText)
                        .font(.title3)
                }

                Section("Monto (COP)") {
                    HStack {
                        Text("$").foregroundStyle(.secondary)
                        TextField("0", text: $amountText)
                            .onChange(of: amountText) { _, new in
                                amountText = new.filter { $0.isNumber }
                            }
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                        if !amountText.isEmpty {
                            Text(amount.cop).foregroundStyle(.secondary).font(.caption)
                        }
                    }
                }

                Section("Tipo") {
                    Picker("Tipo", selection: $type) {
                        Label("Gasto", systemImage: "arrow.up.circle").tag(TransactionType.expense)
                        Label("Ingreso", systemImage: "arrow.down.circle").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { _, _ in selectedCategoryId = nil }
                }

                Section {
                    if filteredCategories.isEmpty {
                        Text("Crea categorías en Ajustes").foregroundStyle(.secondary).font(.caption)
                    } else {
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 12) {
                            ForEach(filteredCategories) { cat in
                                CategoryChip(category: cat, isSelected: selectedCategoryId == cat.id)
                                    .onTapGesture { selectedCategoryId = cat.id }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    HStack {
                        Text("Categoría")
                        Spacer()
                        Button { showAddCategory = true } label: {
                            Image(systemName: "plus").font(.caption.weight(.semibold))
                        }
                    }
                }

                Section {
                    if store.accounts.isEmpty {
                        Text("Crea cuentas en Ajustes").foregroundStyle(.secondary).font(.caption)
                    } else {
                        Button {
                            showAccountPicker = true
                        } label: {
                            HStack {
                                if let id = selectedAccountId,
                                   let acc = store.accounts.first(where: { $0.id == id }) {
                                    Circle()
                                        .fill(Color(hex: acc.color) ?? .accentColor)
                                        .frame(width: 10, height: 10)
                                    Text(acc.name)
                                    Text("· \(acc.type.label)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Ninguna").foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    HStack {
                        Text("Cuenta")
                        Spacer()
                        Button { showAddAccount = true } label: {
                            Image(systemName: "plus").font(.caption.weight(.semibold))
                        }
                    }
                }

                Section("Fecha") {
                    DatePicker("Fecha", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                }

                // Pago de deuda — solo visible para gastos cuando hay deudas registradas
                if type == .expense && !store.debts.isEmpty {
                    Section {
                        Toggle("Es pago de deuda", isOn: $isDebtPayment.animation())
                            .onChange(of: isDebtPayment) { _, on in
                                if !on { selectedDebtId = nil }
                            }
                        if isDebtPayment {
                            Picker("Deuda", selection: $selectedDebtId) {
                                Text("Seleccionar…").tag(Optional<String>(nil))
                                ForEach(store.debts.sorted { $0.name < $1.name }) { debt in
                                    Label(debt.name, systemImage: debt.type.icon).tag(Optional(debt.id))
                                }
                            }
                        }
                    } header: {
                        Text("Deuda")
                    }
                }

                Section("Hashtags") {
                    if !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag).font(.caption).foregroundStyle(.secondary)
                                        Button {
                                            tags.removeAll { $0 == tag }
                                        } label: {
                                            Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.regularMaterial, in: Capsule())
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    TextField("Agregar #hashtag...", text: $tagInput)
                        .onSubmit { addCurrentTag() }
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif

                    if !tagSuggestions.isEmpty {
                        ForEach(tagSuggestions, id: \.self) { suggestion in
                            Button {
                                tags.append(suggestion)
                                tagInput = ""
                            } label: {
                                Text(suggestion).font(.subheadline).foregroundStyle(.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(transaction == nil ? "Nueva transacción" : "Editar transacción")
            .onAppear { loadIfEditing() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showAddCategory) { CategoryFormView() }
            .sheet(isPresented: $showAddAccount) { AccountFormView() }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerSheet(
                    accounts: store.accounts,
                    selectedId: $selectedAccountId
                )
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 600)
        #endif
    }

    private func loadIfEditing() {
        guard let tx = transaction else { return }
        titleText = tx.title ?? ""
        amountText = "\(tx.amount)"
        type = tx.type
        selectedCategoryId = tx.categoryId
        selectedAccountId = tx.accountId
        date = tx.date
        tags = tx.tags
        if let dId = tx.debtId {
            isDebtPayment = true
            selectedDebtId = dId
        }
    }

    private func addCurrentTag() {
        let raw = tagInput.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")
        guard !raw.isEmpty else { return }
        let tag = raw.hasPrefix("#") ? raw : "#\(raw)"
        if !tags.contains(tag) { tags.append(tag) }
        tagInput = ""
    }

    private func save() {
        if !tagInput.isEmpty { addCurrentTag() }
        let debtId = isDebtPayment ? selectedDebtId : nil
        let savedTitle = titleText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : titleText.trimmingCharacters(in: .whitespaces)
        if var tx = transaction {
            tx.amount = amount; tx.type = type; tx.date = date
            tx.tags = tags; tx.categoryId = selectedCategoryId
            tx.accountId = selectedAccountId; tx.debtId = debtId
            tx.title = savedTitle
            store.updateTransaction(tx)
        } else {
            store.addTransaction(Transaction(
                amount: amount, type: type, date: date,
                tags: tags, categoryId: selectedCategoryId,
                accountId: selectedAccountId, debtId: debtId,
                title: savedTitle
            ))
        }
        dismiss()
    }
}

// MARK: - AccountPickerSheet

private struct AccountPickerSheet: View {
    let accounts: [Account]
    @Binding var selectedId: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedId = nil
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(.secondary)
                            .frame(width: 10, height: 10)
                        Text("Ninguna").foregroundStyle(.primary)
                        Spacer()
                        if selectedId == nil {
                            Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)

                ForEach(accounts.sorted { $0.name < $1.name }) { acc in
                    Button {
                        selectedId = acc.id
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: acc.color) ?? .accentColor)
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(acc.name).foregroundStyle(.primary)
                                Text(acc.type.label).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedId == acc.id {
                                Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Seleccionar cuenta")
            .navigationTitleMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 300, minHeight: 300)
        #endif
    }
}

// MARK: - CategoryChip

private struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    var color: Color { Color(hex: category.color) ?? .accentColor }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isSelected ? color : color.opacity(0.15))
                    .frame(width: 44, height: 44)
                CategoryIcon(icon: category.icon, color: isSelected ? .white : color, size: 44)
            }
            Text(category.name).font(.caption2).foregroundStyle(isSelected ? color : .secondary).lineLimit(1)
        }
        .padding(.vertical, 4)
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}
