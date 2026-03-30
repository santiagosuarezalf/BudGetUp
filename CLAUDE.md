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
Services/AppStore.swift        ← @Observable. Estado central: [Transaction], [Category], [Account], [Debt]
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

- **Transaction:** `amount: Int`, `type: TransactionType (.income/.expense)`, `date: Date`, `tags: [String]`, `categoryId: String?`, `accountId: String?`, `debtId: String?`, `title: String?` — decoder tolerante para retrocompat. Si `debtId != nil` es un pago de deuda.
- **Category:** `name`, `color` (hex String), `icon` (SF Symbol name o emoji), `type: CategoryType (.income/.expense/.both)`, `monthlyBudget: Int?`
- **Account:** `name`, `type: AccountType (.checking/.credit/.savings)`, `color` (hex String)
- **Debt:** `name`, `type: DebtType (.creditCard/.loan)`, `currentBalance: Int`, `monthlyPayment: Int`, `color`, `interestRate: Double?`, `interestType: InterestType (.ea/.na)`, `startDate: Date?`, `initialAmount: Int?`, `termMonths: Int?`, `balanceUpdatedAt: Date` — ancla para simular saldo efectivo con interés compuesto mes a mes

## Helpers clave

**`Helpers/CurrencyFormatter.swift`**
- `Int.cop` → `"$1.200.000"` (formato completo COP)
- `Int.copCompact` → `"$1.2M"` / `"$850K"` (formato compacto)
- `Calendar.monthLabel(for:)` → `"Marzo 2026"` (locale `es_CO`)
- `Calendar.monthKey(for:)` → `"2026-03"` (para agrupar)
- `AppearanceMode` — enum `.system/.light/.dark` con `colorScheme: ColorScheme?`. Persiste en `@AppStorage("appearanceMode")`. Se aplica con `.preferredColorScheme(...)` en `BudGetUpApp`.
- `CardPressStyle` — `ButtonStyle` con `scaleEffect + brightness + spring(bounce: 0.5)`. Usado en las tarjetas de resumen de `SummaryCardsView`.
- `NavTitleMode` — enum `.large/.inline` + extensión `View.navigationTitleMode(_:)` con `#if os(iOS)` para evitar error de compilación en macOS.

**`Color(hex:)`** — extensión en `CategoryBudgetView.swift` que parsea hex strings a `Color`

**`String.isEmoji`** — extensión en `CategoriesView.swift`. Retorna `true` si el primer escalar Unicode es un emoji. Usada en `CategoryIcon` para decidir si renderizar `Image(systemName:)` o `Text(icon)`.

**`CategoryIcon`** — view helper en `CategoriesView.swift`. Renderiza el ícono de una categoría (SF Symbol o emoji) dado `icon: String`, `color: Color` y `size: CGFloat`. Reutilizada en `CategoryRowSettings`, `CategoryChip` y `TransactionRow`.

## Estructura de vistas

```
ContentView
├── [macOS] NavigationSplitView
│   ├── sidebar: DashboardView, BudgetTabView, DebtsView, SettingsView
│   └── detail: DashboardView
└── [iOS] TabView (4 tabs)
    ├── DashboardView   "Inicio"
    ├── BudgetTabView   "Presupuesto"
    ├── DebtsView       "Deuda"       ← envuelto en NavigationStack
    └── SettingsView    "Ajustes"

DashboardView
├── [showHistorical=false]
│   ├── MonthRibbonView      ← cinta horizontal scrollable de meses
│   ├── SummaryCardsView     ← tarjetas Ingresos/Gastos/Balance/Deuda — tapeables con CardPressStyle
│   ├── Picker 4 gráficas (iconos únicamente — segmented)
│   │   ├── RadarChartView      ← gasto real vs presupuesto por categoría
│   │   ├── LineChartView       ← ingresos vs gastos últimos 5 meses
│   │   ├── DonutChartView      ← distribución de gasto por categoría (SectorMark)
│   │   └── CategoryBarsView    ← barras horizontales por categoría, ordenadas por monto
│   └── TransactionListView  ← lista agrupada por día con context menu (editar/eliminar)
├── [showHistorical=true]
│   └── HistoricalView       ← lista todos los meses; tap navega al mes
└── SpeedDialFAB             ← botón + que se expande en Gasto / Ingreso / Pago de deuda
                                Al seleccionar, abre AddTransactionView con tipo pre-configurado

BudgetTabView               ← en CategoryBudgetView.swift
├── MonthRibbonView
├── Barras presupuesto vs gasto por categoría (incluye pagos de deuda)
└── Sheet historial por categoría

DebtsView + DebtFormView    ← en DebtsView.swift
├── Lista de deudas con saldo efectivo simulado
├── Formulario: tipo, saldo, cuota, tasa E.A./N.A.M.V., plazo, fecha inicio
├── Calculadora: meses restantes, fecha estimada de pago, línea de tiempo
└── effectiveBalance() en AppStore: simula saldo mes a mes con interés compuesto desde balanceUpdatedAt

SettingsView
├── Sección "Visualización": Picker apariencia (Sistema/Claro/Oscuro)
├── CategoriesView + CategoryFormView  ← CRUD categorías
├── AccountsView + AccountFormView     ← CRUD cuentas
└── DebtsView + DebtFormView           ← CRUD deudas (también accesible desde tab Deuda)
```

## Consideraciones iOS vs macOS

- `#if os(macOS)` / `#else` para `.windowStyle`, `.windowToolbarStyle`, `.frame(minWidth:minHeight:)`, `.menuStyle(.borderlessButton)`
- FAB usa `.safeAreaInset(edge: .bottom, alignment: .trailing)` en el ScrollView — nunca `ZStack` con padding fijo
- `.navigationBarTitleDisplayMode` es iOS-only — usar siempre `.navigationTitleMode(_:)` (extensión en `CurrencyFormatter.swift`)
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

## Colecciones Firestore (actualizado)

```
users/{uid}/transactions
users/{uid}/categories
users/{uid}/accounts
users/{uid}/debts
```

## Lo que NO va al repo

`.gitignore` excluye `GoogleService-Info.plist`, `*.sqlite`, `*.store`, `*.db`, `DerivedData/`

## Repo en GitHub

https://github.com/santiagosuarezalf/BudGetUp
