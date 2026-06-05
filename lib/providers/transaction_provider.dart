import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];

  List<Transaction> get transactions => _transactions;

  double get totalBalance {
    return _transactions.fold(0, (sum, t) {
      return t.type == 'income' ? sum + t.amount : sum - t.amount;
    });
  }

  double get totalIncome {
    return _transactions
      .where((t) => t.type == 'income')
      .fold(0, (sum, t) => sum + t.amount);
  }

  double get totalExpenses {
    return _transactions
      .where((t) => t.type == 'expense')
      .fold(0, (sum, t) => sum + t.amount);
  }

  List<Transaction> get recentTransactions {
    final sorted = [..._transactions];
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  Map<String, double> get expensesByCategory {
    final Map<String, double> map = {};
    for (final t in _transactions.where((t) => t.type == 'expense')) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  Future<void> loadTransactions() async {
    _transactions = await DatabaseHelper.instance.getAllTransactions();
    notifyListeners();
  }

  Future<void> addTransaction(Transaction t) async {
    await DatabaseHelper.instance.insertTransaction(t);
    await loadTransactions();
  }

  Future<void> updateTransaction(Transaction t) async {
    await DatabaseHelper.instance.updateTransaction(t);
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await loadTransactions();
  }

  Future<void> clearAll() async {
    await DatabaseHelper.instance.clearAllTransactions();
    await loadTransactions();
  }

  List<Transaction> filterByDateRange(DateTime start, DateTime end) {
    return _transactions.where((t) =>
      t.date.isAfter(start.subtract(const Duration(days: 1))) &&
      t.date.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  List<Transaction> filterByCategory(String category) {
    if (category == 'All') return _transactions;
    return _transactions.where((t) => t.category == category).toList();
  }
}
