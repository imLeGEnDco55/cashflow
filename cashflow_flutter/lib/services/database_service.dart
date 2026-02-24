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

    return await openDatabase(
      path,
      version: 4,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        emoji TEXT NOT NULL,
        description TEXT NOT NULL,
        isSuperEmoji INTEGER NOT NULL,
        type TEXT NOT NULL DEFAULT 'expense',
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
        paymentDay INTEGER,
        creditLimit REAL
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
        breakdown TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE,
        FOREIGN KEY (targetCardId) REFERENCES cards (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Indexes for performance
    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions(date)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_category ON transactions(categoryId)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add indexes for existing databases
      await db.execute(
        'CREATE INDEX idx_transactions_date ON transactions(date)',
      );
      await db.execute(
        'CREATE INDEX idx_transactions_category ON transactions(categoryId)',
      );
    }
    if (oldVersion < 3) {
      // Add type column to categories
      await db.execute(
        "ALTER TABLE categories ADD COLUMN type TEXT NOT NULL DEFAULT 'expense'",
      );
    }
    if (oldVersion < 4) {
      // Add creditLimit to cards
      await db.execute('ALTER TABLE cards ADD COLUMN creditLimit REAL');
      // Drop budgets table
      await db.execute('DROP TABLE IF EXISTS budgets');
    }
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
