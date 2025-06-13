import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';


class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();

  final String _tableName = "transactions";
  final String _dateColumnName = "date";
  final String _amountColumnName = "amount";
  final String _referenceColumnName = "reference";
  final String _typeColumnName = "type";

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await getDatabase();
    return _db!;
  }

  Future<Database> getDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "transaction.db");
    final database = await openDatabase(
      databasePath,
      version: 2,
      onCreate: (db, version) {
        db.execute("""
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            $_dateColumnName TEXT NOT NULL,
            $_amountColumnName DECIMAL(10, 2) NOT NULL,
            $_referenceColumnName TEXT,
            $_typeColumnName TEXT NOT NULL DEFAULT 'spend'
          )
        """);
      }
    );
    return database;
  }

  Future<void> insertTransaction(String date, double amount, String? reference, String? type) async {
    final db = await database;

    await db.insert(
      'transactions',
      {
        'date': date,
        'amount': amount,
        'reference': reference,
        'type': type
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double> getTotalForDay(String date) async {
    final db = await database;

    final spendResult = await db.rawQuery('''
      SELECT SUM(amount) AS total
      FROM transactions
      WHERE date = ?
      AND type = 'spend'
    ''', [date]);

    final gainResult = await db.rawQuery('''
      SELECT SUM(amount) AS total
      FROM transactions
      WHERE date = ?
      AND type = 'gain'
    ''', [date]);

    final spend = (spendResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final gain = (gainResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final total = spend - gain;
    if (total == null) return 0.0;

    return total;

  }

  Future<double> getTotalForMonth(String yearMonth) async {
    final db = await database;

    final spendResult = await db.rawQuery('''
      SELECT SUM(amount) AS total
      FROM transactions
      WHERE strftime('%Y-%m', date) = ?
      AND type = 'spend'
    ''', [yearMonth]);

    final gainResult = await db.rawQuery('''
      SELECT SUM(amount) AS total
      FROM transactions
      WHERE strftime('%Y-%m', date) = ?
      AND type = 'gain'
    ''', [yearMonth]);

    final spend = (spendResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final gain = (gainResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final total = spend - gain;
    if (total == null) return 0.0;

    return total;
  }

  Future<List<Map<String, dynamic>>> getTransactionsForDay(String date) async {
    final db = await database;

    return await db.query(
      'transactions',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionsForMonth(String yearMonth) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'transactions',
      where: 'date LIKE ?',
      whereArgs: ['$yearMonth%'],
      orderBy: 'date ASC',
    );

    return results;
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllTransactions() async {
    final db = await database;
    await db.delete('transactions');
  }
}