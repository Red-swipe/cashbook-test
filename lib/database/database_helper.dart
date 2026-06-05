import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as model;
import '../models/category.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cashbook.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE currency_rates (
        from_code TEXT NOT NULL,
        to_code TEXT NOT NULL,
        rate REAL NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (from_code, to_code)
      )
    ''');

    await db.insert('settings', {'key': 'currency', 'value': 'USD'});
    await db.insert('settings', {'key': 'theme', 'value': 'dark'});
    await db.insert('settings', {'key': 'username', 'value': 'User'});
    await db.insert('settings', {
      'key': 'install_date',
      'value': DateTime.now().toIso8601String()
    });

    await _seedCategories(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          icon_code_point INTEGER NOT NULL,
          icon_font_family TEXT NOT NULL,
          enabled INTEGER NOT NULL DEFAULT 1
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS currency_rates (
          from_code TEXT NOT NULL,
          to_code TEXT NOT NULL,
          rate REAL NOT NULL,
          updated_at TEXT NOT NULL,
          PRIMARY KEY (from_code, to_code)
        )
      ''');

      await _seedCategories(db);
    }
  }

  Future<void> _seedCategories(Database db) async {
    const names = [
      'Food', 'Transport', 'Shopping', 'Bills', 'Salary',
      'Entertainment', 'Health', 'Education', 'Travel',
      'Rent', 'Subscriptions', 'Other',
    ];
    final icons = [
      Icons.restaurant, Icons.directions_car, Icons.shopping_bag,
      Icons.bolt, Icons.work, Icons.play_circle,
      Icons.favorite, Icons.menu_book, Icons.flight,
      Icons.home, Icons.autorenew, Icons.grid_view,
    ];
    for (var i = 0; i < names.length; i++) {
      await db.insert('categories', {
        'name': names[i],
        'icon_code_point': icons[i].codePoint,
        'icon_font_family': icons[i].fontFamily ?? 'MaterialIcons',
        'enabled': 1,
      });
    }
  }

  Future<int> insertTransaction(model.Transaction t) async {
    final db = await database;
    return await db.insert('transactions', t.toMap());
  }

  Future<List<model.Transaction>> getAllTransactions() async {
    final db = await database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((e) => model.Transaction.fromMap(e)).toList();
  }

  Future<int> updateTransaction(model.Transaction t) async {
    final db = await database;
    return await db.update(
      'transactions',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllTransactions() async {
    final db = await database;
    await db.delete('transactions');
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> seedDefaultCategories() async {
    final db = await database;
    await _seedCategories(db);
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'id ASC');
    return result.map((e) => Category.fromMap(e)).toList();
  }

  Future<List<Category>> getEnabledCategories() async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'enabled = ?',
      whereArgs: [1],
      orderBy: 'id ASC',
    );
    return result.map((e) => Category.fromMap(e)).toList();
  }

  Future<int> insertCategory(Category cat) async {
    final db = await database;
    return await db.insert('categories', cat.toMap());
  }

  Future<int> updateCategory(Category cat) async {
    final db = await database;
    return await db.update(
      'categories',
      cat.toMap(),
      where: 'id = ?',
      whereArgs: [cat.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<double?> getCurrencyRate(String from, String to) async {
    final db = await database;
    final result = await db.query(
      'currency_rates',
      where: 'from_code = ? AND to_code = ?',
      whereArgs: [from, to],
    );
    if (result.isEmpty) return null;
    return result.first['rate'] as double;
  }

  Future<void> setCurrencyRate(
      String from, String to, double rate, DateTime updatedAt) async {
    final db = await database;
    await db.insert(
      'currency_rates',
      {
        'from_code': from,
        'to_code': to,
        'rate': rate,
        'updated_at': updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
