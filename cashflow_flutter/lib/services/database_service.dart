import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/finance.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      databaseFactory = databaseFactoryFfi;
      sqfliteFfiInit();
    }

    _database = await _initDB('cashflow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        emoji TEXT NOT NULL,
        description TEXT NOT NULL,
        isSuperEmoji INTEGER NOT NULL,
        aliases TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        colorEmoji TEXT NOT NULL,
        cutOffDay INTEGER,
        paymentDay INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        date TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        targetCardId TEXT,
        isRecurring INTEGER NOT NULL,
        breakdown TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        categoryId TEXT PRIMARY KEY,
        "limit" REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // --- CRUD Operations ---

  // Categories
  Future<void> saveCategories(List<FinanceCategory> items) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('categories');
      for (var item in items) {
        await txn.insert('categories', item.toMap());
      }
    });
  }

  Future<List<FinanceCategory>> getCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => FinanceCategory.fromMap(json)).toList();
  }

  Future<void> updateCategory(FinanceCategory item) async {
    final db = await instance.database;
    await db.update(
      'categories',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await instance.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Cards
  Future<void> saveCards(List<FinanceCard> items) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('cards');
      for (var item in items) {
        await txn.insert('cards', item.toMap());
      }
    });
  }

  Future<List<FinanceCard>> getCards() async {
    final db = await instance.database;
    final result = await db.query('cards');
    return result.map((json) => FinanceCard.fromMap(json)).toList();
  }

  Future<void> updateCard(FinanceCard item) async {
    final db = await instance.database;
    await db.update(
      'cards',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteCard(String id) async {
    final db = await instance.database;
    await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  // Transactions
  Future<void> saveTransactions(List<Transaction> items) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      for (var item in items) {
        await txn.insert('transactions', item.toMap());
      }
    });
  }

  // Quick insert for new transactions
  Future<void> insertTransaction(Transaction item) async {
    final db = await instance.database;
    await db.insert('transactions', item.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    final db = await instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Transaction>> getTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((json) => Transaction.fromMap(json)).toList();
  }

  Future<void> updateTransaction(Transaction item) async {
    final db = await instance.database;
    await db.update(
      'transactions',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Budgets
  Future<void> saveBudgets(List<Budget> items) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('budgets');
      for (var item in items) {
        await txn.insert('budgets', item.toMap());
      }
    });
  }

  Future<List<Budget>> getBudgets() async {
    final db = await instance.database;
    final result = await db.query('budgets');
    return result.map((json) => Budget.fromMap(json)).toList();
  }

  Future<void> updateBudget(Budget item) async {
    final db = await instance.database;
    await db.insert(
      'budgets',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBudget(String categoryId) async {
    final db = await instance.database;
    await db.delete(
      'budgets',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
  }

  // Settings
  Future<void> setSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isNotEmpty) {
      return result.first['value'] as String;
    }
    return null;
  }
}
