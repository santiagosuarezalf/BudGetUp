# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es este proyecto

**BudGetUp** — app de presupuesto personal multiplatforma (macOS + iPhone) construida en SwiftUI. Reemplaza el sistema anterior en Notion de Santiago.

- **Moneda:** COP (pesos colombianos, enteros — sin decimales)
- **Auth:** Firebase email/password
- **Base de datos:** Firebase Firestore (sync en tiempo real entre Mac e iPhone)
- **Sin CloudKit** — se descartó porque requiere cuenta de desarrollador de pago
- **Plataformas:** macOS 14+ y iOS 17+ desde un solo codebase con `#if os(macOS)`

## Cómo compilar y correr

Abrir `BudGetUp.xcodeproj` en Xcode. No hay scripts de terminal — todo se hace desde Xcode:

- **Mac:** ⌘B para compilar, ⌘R para correr
- **iPhone:** Conectar iPhone, seleccionarlo como destino en la barra de Xcode, ⌘R
- **Firebase no expira** — no hay que renovar credenciales. Solo la firma de desarrollo personal (~7 días) si se desconecta el iPhone de la Mac

## Arquitectura

```
App/BudGetUpApp.swift          ← Entry point. FirebaseApp.configure() PRIMERO, luego AuthService. RootView privado maneja la lógica de auth (loading → SignInView | ContentView)
Services/AuthService.swift     ← @MainActor @Observable. Firebase email/password auth
Services/AppStore.swift        ← @Observable. Estado central: [Transaction], [Category], [Account]
Services/FirestoreService.swift ← CRUD + listeners de Firestore
Models/                        ← Structs Codable (NO SwiftData). IDs como String (UUID)
Views/ContentView.swift        ← macOS: NavigationSplitView | iOS: TabView
```

### Flujo de datos

```
Firestore ──listener──▶ FirestoreService ──▶ AppStore ──@Environment──▶ Views
Views ──user action──▶ AppStore.add/update/delete ──▶ FirestoreService.save ──▶ Firestore
```

### Colecciones Firestore

```
users/{uid}/transactions
users/{uid}/categories
users/{uid}/accounts
```

### Inyección de dependencias

- `AuthService` → inyectado en el root (`BudGetUpApp`) con `.environment(authService)`
- `AppStore` → creado en `RootView` con el `uid` del usuario autenticado, pasado con `.environment(AppStore(uid: uid))`
- Todas las vistas acceden con `@Environment(AppStore.self)` y `@Environment(AuthService.self)`

## Modelos

Todos son `struct Codable` con `id: String` (UUID como String para Firestore):

- **Transaction:** `amount: Int`, `type: TransactionType (.income/.expense)`, `date: Date`, `tags: [String]` (default `[]`, reemplazó `note`), `categoryId: String?`, `accountId: String?` — soporta add, update y delete. Decoder personalizado para retrocompat con documentos Firestore viejos que tenían `note`.
- **Category:** `name`, `color` (hex String), `icon` (SF Symbol name), `type: CategoryType (.income/.expense/.both)`, `monthlyBudget: Int?`
- **Account:** `name`, `type: AccountType (.checking/.credit/.savings)`, `color` (hex String)

## Helpers clave

**`Helpers/CurrencyFormatter.swift`**
- `Int.cop` → `"$1.200.000"` (formato completo COP)
- `Int.copCompact` → `"$1.2M"` / `"$850K"` (formato compacto)
- `Calendar.monthLabel(for:)` → `"Marzo 2026"` (locale `es_CO`)
- `Calendar.monthKey(for:)` → `"2026-03"` (para agrupar)

**`Color(hex:)`** — extensión en `CategoryBudgetView.swift` que parsea hex strings a `Color`

**`String.isEmoji`** — extensión en `CategoriesView.swift`. Retorna `true` si el primer escalar Unicode es un emoji. Usada en `CategoryIcon` para decidir si renderizar `Image(systemName:)` o `Text(icon)`.

**`CategoryIcon`** — view helper en `CategoriesView.swift`. Renderiza el ícono de una categoría (SF Symbol o emoji) dado `icon: String`, `color: Color` y `size: CGFloat`. Reutilizada en `CategoryRowSettings`, `CategoryChip` y `TransactionRow`.

## Estructura de vistas

```
ContentView
├── [macOS] NavigationSplitView
│   ├── sidebar: links a DashboardView y SettingsView
│   └── detail: DashboardView
└── [iOS] TabView
    ├── DashboardView  (tab "Presupuesto")
    └── SettingsView   (tab "Ajustes")

DashboardView
├── [showHistorical=false]
│   ├── MonthRibbonView      ← cinta horizontal scrollable de meses
│   ├── SummaryCardsView     ← tarjetas Ingresos / Gastos / Balance
│   ├── Picker radar/línea
│   │   ├── RadarChartView   ← custom Canvas+Path, gasto real vs presupuesto por categoría
│   │   └── LineChartView    ← Swift Charts, ingresos vs gastos mes a mes
│   ├── CategoryBudgetView   ← barras de progreso presupuesto vs gasto por categoría (solo si hay categorías con budget)
│   └── TransactionListView  ← lista agrupada por día
├── [showHistorical=true]
│   └── HistoricalView       ← lista todos los meses con mini-barras ingresos/gastos; tap navega al mes
└── FAB (+)                  ← .safeAreaInset(edge: .bottom) — respeta tab bar en iOS

SettingsView
├── CategoriesView + CategoryFormView  ← CRUD categorías
└── AccountsView + AccountFormView     ← CRUD cuentas
```

## Consideraciones iOS vs macOS

- `#if os(macOS)` / `#else` para `.windowStyle`, `.windowToolbarStyle`, `.frame(minWidth:minHeight:)`, `.menuStyle(.borderlessButton)`
- FAB usa `.safeAreaInset(edge: .bottom, alignment: .trailing)` en el ScrollView — nunca `ZStack` con padding fijo
- `AddTransactionView` usa `.scrollDismissesKeyboard(.interactively)` en el Form
- `INFOPLIST_KEY_UILaunchScreen_Generation = YES` en el pbxproj — sin esto iOS no usa el área completa de la pantalla (iPhone 15 Pro / Dynamic Island)

## Swift 6 / Concurrencia

- `AuthService` es `@MainActor` para evitar data races con el listener de Firebase
- El handle del listener es `nonisolated(unsafe) var handle` para poder usarlo en `deinit`
- `FirebaseApp.configure()` **debe** correr antes de inicializar `AuthService`. Por eso en `BudGetUpApp.init()` se usa `_authService = State(initialValue: AuthService())` después de configure, no como valor por defecto de la propiedad

## Archivos de configuración importantes

- `BudGetUp/GoogleService-Info.plist` — credenciales de Firebase (NO subir a git)
- `BudGetUp/BudGetUp.entitlements` — solo `app-sandbox` y `network.client`
- `BudGetUp.xcodeproj/project.pbxproj` — editado manualmente. SDKROOT=auto, SUPPORTED_PLATFORMS="macosx iphoneos iphonesimulator", IPHONEOS_DEPLOYMENT_TARGET=17.0, TARGETED_DEVICE_FAMILY="1,2", DEVELOPMENT_TEAM=4P22M73X87

## Lo que NO va al repo

`.gitignore` excluye `GoogleService-Info.plist`, `*.sqlite`, `*.store`, `*.db`, `DerivedData/`
