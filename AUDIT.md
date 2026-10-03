# Project Code Audit Report

This document contains a file-by-file audit of the entire codebase (`lib/` and `test/`), detailing compilation errors, runtime exceptions, logic errors, deprecated API usages, and design/UX bugs.

---

## 1. Entry Points & Main Shell

### `lib/main.dart`
- **Status:** No critical errors.
- **Observations:** Properly initializes `WidgetsBinding` and locks orientation to portrait.

### `lib/app.dart`
- **Logic Error / UX Bug:** In `_MainShellState.initState()`, `loadTheme()`, `loadSettings()`, and `loadTransactions()` are called asynchronously in `addPostFrameCallback`. However, `SettingsProvider` constructor also calls `_init()` which invokes `loadSettings()`, causing redundant initial database calls.
- **UI Bug:** `BottomNavigationBar` inside `MainShell` duplicates navigation functionality while standalone unused widget `BottomNavBar` exists in `lib/widgets/bottom_nav_bar.dart`.

---

## 2. Models

### `lib/models/category.dart`
- **Compiler / Analyzer Warning:** Line 23 uses `// ignore: non_const_argument_for_const_parameter` above `IconData(iconCodePoint, fontFamily: iconFontFamily)`. While functional, storing runtime icon code points without validation or font fallback can cause missing icon rendering if font family strings do not match installed material font icons.

### `lib/models/transaction.dart`
- **Type Safety / Runtime Error Risk:** In `Transaction.fromMap(Map<String, dynamic> map)`, `map['amount']` is cast directly. In SQLite, double/integer values returned from queries might be `int` or `num` if entered without decimals. Calling `(map['amount'] as num).toDouble()` is safer to prevent runtime `type 'int' is not a subtype of type 'double'` type cast exceptions.

---

## 3. Database

### `lib/database/database_helper.dart`
- **Logic / Migration Error:** In `_upgradeDB`, if `oldVersion < 2`, `_seedCategories(db)` is called. If the database already had categories or was created with version 1, re-running `_seedCategories` causes `UNIQUE constraint failed: categories.name` errors when inserting duplicate default category names.
- **SQL Error / Data Integrity Risk:** In `insertCategory`, inserting a category name that conflicts with an existing unique name without specifying `conflictAlgorithm` throws an unhandled SQLite exception.
- **Logic Error:** In `getCurrencyRate`, returned rate is cast as `result.first['rate'] as double`. SQLite can store numeric values as `int` or `real`, causing potential cast failures.

---

## 4. Providers

### `lib/providers/theme_provider.dart`
- **State Synchronization Bug:** `toggleTheme()` toggles `_themeMode` in memory first (`_themeMode = isDark ? ThemeMode.light : ThemeMode.dark;`) and notifies listeners. But `isDark` getter evaluates `_themeMode == ThemeMode.dark`. If current theme is `dark`, assigning `_themeMode = ThemeMode.light` makes `isDark` `false`. Consequently, setting `DatabaseHelper.instance.setSetting('theme', isDark ? 'dark' : 'light')` saves `'light'` as expected, but setting logic relies on toggled getter evaluation which can be error-prone if accessed asynchronously.

### `lib/providers/settings_provider.dart`
- **Logic / Unhandled Exception Error:** In `addCategory`, `addCategory(Category cat)` inserts `cat` into DB and gets an ID, but does not check if category name already exists, resulting in unhandled SQLite unique constraint exceptions.
- **Logic Error:** `currencies` list contains duplicate symbols/currency entries (`JPY` and `CNY` both share `'¥'`, `USD` and `CAD` use `$` vs `CA$`), and fallback logic in `currencySymbol` defaults to `currencies.first` (`USD`) instead of returning `$` or throwing/handling unknown codes.

### `lib/providers/transaction_provider.dart`
- **Logic Error:** `filterByDateRange` subtracts and adds 1 day (`start.subtract(const Duration(days: 1))`), which unintentionally includes transactions from the preceding and following days rather than matching strict date boundaries (00:00:00 to 23:59:59).

---

## 5. Services

### `lib/services/currency_service.dart`
- **Logic Error / Infinite Loop Risk:** In `convert(amount, from, to)`, if `_fetchAndCacheRates()` fails (e.g. offline or API down), `convert` calls itself recursively (`return convert(amount, from, to);`), leading to infinite recursion and a StackOverflow error.
- **Exception Handling Bug:** Empty `catch (_)` block swallows network failures completely without notifying the caller or fallback mechanism.

### `lib/services/export_service.dart`
- **Compilation / Deprecation Warnings:**
  - Uses deprecated `Share.shareXFiles(...)` API on lines 32 and 78. Package `share_plus` requires `SharePlus.instance.share(...)` or `Share.shareXFiles` migration depending on installed version.
- **Formatting Bug:** `NumberFormat('#,##0.0', 'en_US')` formats amounts with only 1 decimal place (e.g. `$100.0` instead of `$100.00`).

---

## 6. Theme & Styling

### `lib/theme/app_colors.dart`
- **Status:** Clean constant definitions.

### `lib/theme/app_theme.dart`
- **Status:** ThemeData correctly configures dark and light mode themes.

### `lib/theme/colored_context.dart`
- **Status:** Context extensions for colors are correctly defined.

---

## 7. UI Screens

### `lib/screens/home/home_screen.dart`
- **UI Bug:** `_RecentActivityHeader` contains a "See All" `TextButton` with an empty `onPressed: () {}` callback that performs no navigation.
- **UX Bug:** Total balance calculation on summary card scales text down without scroll options on extremely large numbers.

### `lib/screens/pulse/pulse_screen.dart`
- **Logic Error / Empty State Bug:** When no expense transactions exist, `PieChart` is supplied with empty sections or zero totals, which can throw runtime visual assertion errors in `fl_chart`.

### `lib/screens/vault/vault_screen.dart`
- **Logic Error:** Date range filtering logic in `_CalendarWidget` uses strict comparison for dates (`date.isAfter(pickStart!) && date.isBefore(pickEnd!)`), missing start/end day bounds when transactions occur on the start or end dates themselves.

### `lib/screens/settings/settings_screen.dart`
- **Status:** Functional settings management, but export actions lack error handling if device storage/share picker is unavailable.

### `lib/screens/settings/categories_screen.dart`
- **Compilation Error:** Line 73 contains duplicate variable definition `_`:
  ```dart
  itemBuilder: (context, index, _) // 'The name '_' is already defined'
  ```

### `lib/screens/settings/widgets/settings_tile.dart`
- **Compilation Error:** Line 70 contains invalid syntax / experimental language feature:
  ```dart
  ?trailing, // 'This requires the null-aware-elements language feature to be enabled'
  ```
  Should be written as `if (trailing != null) trailing!`.

### `lib/screens/settings/widgets/settings_section.dart`
- **Status:** Clean wrapper widget for settings tiles.

### `lib/screens/log_transaction/log_transaction_screen.dart`
- **Logic / UX Bug:** Numpad input parser allows entering multiple decimal points (e.g., `10.5.2`), leading to `FormatException` when parsing amount to `double`.

### `lib/screens/transaction_detail/transaction_detail_screen.dart`
- **UX / Navigation Bug:** After editing a transaction in `LogTransactionScreen` bottom sheet, `TransactionDetailScreen` does not dynamically refresh its displayed instance unless popped back or re-fetched from provider.

---

## 8. Shared Widgets

### `lib/widgets/bottom_nav_bar.dart`
- **Dead Code:** Unused file returning `Placeholder()`.

### `lib/widgets/empty_state.dart`
- **Dead Code:** Unused file returning `Placeholder()`.

### `lib/widgets/transaction_tile.dart`
- **Dead Code:** Unused file returning `Placeholder()`.

---

## 9. Tests

### `test/widget_test.dart`
- **Test Failure / Missing Setup:** Test calls `await tester.pumpWidget(const CashbookApp());` without initializing `sqfliteFfiInit()` and `databaseFactory = databaseFactoryFfi;`, causing sqflite database errors during widget testing environment execution.
