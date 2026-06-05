import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/category.dart';

class SettingsProvider extends ChangeNotifier {
  String _currency = 'USD';
  String _username = 'User';
  List<Category> _categories = [];

  SettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadSettings();
  }

  String get currency => _currency;
  String get username => _username;
  List<Category> get categories => List.unmodifiable(_categories);
  List<Category> get enabledCategories =>
      _categories.where((c) => c.enabled).toList();

  static const List<Map<String, String>> currencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'country': 'United States'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'country': 'European Union'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£', 'country': 'United Kingdom'},
    {'code': 'PKR', 'name': 'Pakistani Rupee', 'symbol': '₨', 'country': 'Pakistan'},
    {'code': 'IQD', 'name': 'Iraqi Dinar', 'symbol': 'ع.د', 'country': 'Iraq'},
    {'code': 'TRY', 'name': 'Turkish Lira', 'symbol': '₺', 'country': 'Turkey'},
    {'code': 'AED', 'name': 'UAE Dirham', 'symbol': 'د.إ', 'country': 'United Arab Emirates'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': '﷼', 'country': 'Saudi Arabia'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'CA\$', 'country': 'Canada'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$', 'country': 'Australia'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥', 'country': 'Japan'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥', 'country': 'China'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹', 'country': 'India'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'RM', 'country': 'Malaysia'},
    {'code': 'KWD', 'name': 'Kuwaiti Dinar', 'symbol': 'د.ك', 'country': 'Kuwait'},
    {'code': 'QAR', 'name': 'Qatari Riyal', 'symbol': 'ر.ق', 'country': 'Qatar'},
    {'code': 'BDT', 'name': 'Bangladeshi Taka', 'symbol': '৳', 'country': 'Bangladesh'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'symbol': 'Rp', 'country': 'Indonesia'},
    {'code': 'NGN', 'name': 'Nigerian Naira', 'symbol': '₦', 'country': 'Nigeria'},
    {'code': 'EGP', 'name': 'Egyptian Pound', 'symbol': 'E£', 'country': 'Egypt'},
  ];

  Future<void> loadSettings() async {
    _currency = await DatabaseHelper.instance
      .getSetting('currency') ?? 'USD';
    _username = await DatabaseHelper.instance
      .getSetting('username') ?? 'User';
    _categories = await DatabaseHelper.instance.getCategories();
    if (_categories.isEmpty) {
      await DatabaseHelper.instance.seedDefaultCategories();
      _categories = await DatabaseHelper.instance.getCategories();
    }
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    _currency = code;
    await DatabaseHelper.instance.setSetting('currency', code);
    notifyListeners();
  }

  Future<void> setUsername(String name) async {
    _username = name;
    await DatabaseHelper.instance.setSetting('username', name);
    notifyListeners();
  }

  Future<void> toggleCategory(int id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final cat = _categories[index];
    _categories[index] = cat.copyWith(enabled: !cat.enabled);
    await DatabaseHelper.instance.updateCategory(_categories[index]);
    notifyListeners();
  }

  Future<void> renameCategory(int id, String newName) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final cat = _categories[index];
    _categories[index] = cat.copyWith(name: newName);
    await DatabaseHelper.instance.updateCategory(_categories[index]);
    notifyListeners();
  }

  Future<void> addCategory(Category cat) async {
    final id = await DatabaseHelper.instance.insertCategory(cat);
    _categories.add(cat.copyWith(id: id));
    notifyListeners();
  }

  Future<void> deleteCategory(int id) async {
    _categories.removeWhere((c) => c.id == id);
    await DatabaseHelper.instance.deleteCategory(id);
    notifyListeners();
  }

  Future<void> reloadCategories() async {
    _categories = await DatabaseHelper.instance.getCategories();
    notifyListeners();
  }

  String get currencySymbol {
    return currencies.firstWhere(
      (c) => c['code'] == _currency,
      orElse: () => currencies.first,
    )['symbol']!;
  }
}
