import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';

class CurrencyService {
  static const String _apiUrl = 'https://open.er-api.com/v6/latest/USD';

  Future<double> convert(double amount, String from, String to) async {
    if (from == to) return amount;
    final db = DatabaseHelper.instance;
    final usdRate = await db.getCurrencyRate(from, 'USD');
    final targetRate = await db.getCurrencyRate('USD', to);

    if (usdRate != null && targetRate != null) {
      return amount * usdRate * targetRate;
    }

    await _fetchAndCacheRates();
    return convert(amount, from, to);
  }

  Future<void> refreshRates() async {
    await _fetchAndCacheRates();
  }

  Future<void> _fetchAndCacheRates() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>;
      final now = DateTime.now();
      final db = DatabaseHelper.instance;

      for (final entry in rates.entries) {
        final toCode = entry.key;
        final rate = (entry.value as num).toDouble();
        await db.setCurrencyRate('USD', toCode, rate, now);
        await db.setCurrencyRate(toCode, 'USD', 1.0 / rate, now);
      }
    } catch (_) {}
  }
}
