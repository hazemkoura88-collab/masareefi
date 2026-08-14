import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Expense {
  final int? id;
  final double amount;
  final String merchant;
  final DateTime date;
  final String cardLast4;
  final String type;
  final String category;
  final String smsHash;

  Expense({
    this.id,
    required this.amount,
    required this.merchant,
    required this.date,
    required this.cardLast4,
    required this.type,
    required this.category,
    required this.smsHash,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'date': date.toIso8601String(),
      'cardLast4': cardLast4,
      'type': type,
      'category': category,
      'smsHash': smsHash,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      merchant: map['merchant'],
      date: DateTime.parse(map['date']),
      cardLast4: map['cardLast4'],
      type: map['type'],
      category: map['category'],
      smsHash: map['smsHash'],
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('masareefi.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        merchant TEXT NOT NULL,
        date TEXT NOT NULL,
        cardLast4 TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        smsHash TEXT UNIQUE NOT NULL
      )
    ''');
  }

  Future<bool> insertExpense(Expense expense) async {
    final db = await instance.database;
    try {
      await db.insert('expenses', expense.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((json) => Expense.fromMap(json)).toList();
  }
}