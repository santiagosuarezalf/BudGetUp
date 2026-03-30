import SwiftUI

struct AccountsView: View {
    @Environment(AppStore.self) private var store
    @State private var showAdd = false
    @State private var editTarget: Account?

    private var sorted: [Account] { store.accounts.sorted { $0.name < $1.name } }

    var body: some View {
        List {
            ForEach(sorted) { acc in
                AccountRowSettings(account: acc)
                    .contentShape(Rectangle())
                    .onTapGesture { editTarget = acc }
            }
            .onDelete { indexSet in
                indexSet.forEach { store.deleteAccount(sorted[$0]) }
            }
        }
        .navigationTitle("Cuentas")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) { AccountFormView() }
        .sheet(item: $editTarget) { acc in AccountFormView(account: acc) }
    }
}

private struct AccountRowSettings: View {
    let account: Account
    var color: Color { Color(hex: account.color) ?? .accentColor }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.15)).frame(width: 34, height: 34)
                Image(systemName: account.type == .credit ? "creditcard.fill" : account.type == .savings ? "banknote" : "building.columns.fill")
                    .foregroundStyle(color).font(.system(size: 15))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name).font(.subheadline)
                Text(account.type.label).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct AccountFormView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var account: Account?

    @State private var name = ""
    @State private var type: AccountType = .checking
    @State private var color = "#007AFF"

    private let colorOptions = [
        "#007AFF", "#0A84FF", "#34C759", "#30D158", "#FF3B30",
        "#FF6B6B", "#FF9500", "#FECA57", "#AF52DE", "#BF5AF2",
        "#5E5CE6", "#30B0C7", "#1DD1A1", "#48DBFB", "#FF375F",
        "#FF6B9D", "#C69B7B", "#636366", "#48484A", "#1C1C1E"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Nombre") { TextField("Ej: Bancolombia", text: $name) }
                Section("Tipo") {
                    Picker("Tipo", selection: $type) {
                        ForEach(AccountType.allCases, id: \.self) { t in Text(t.label).tag(t) }
                    }
                    .pickerStyle(.segmented)
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
            }
            .navigationTitle(account == nil ? "Nueva cuenta" : "Editar cuenta")
            .onAppear { if let a = account { name = a.name; type = a.type; color = a.color } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 360, minHeight: 380)
        #endif
    }

    private func save() {
        if var acc = account {
            acc.name = name; acc.type = type; acc.color = color
            store.updateAccount(acc)
        } else {
            store.addAccount(Account(name: name, type: type, color: color))
        }
        dismiss()
    }
}
