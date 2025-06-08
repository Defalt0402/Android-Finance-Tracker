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

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await getDatabase();
    return _db!;
  }

  Future<Database> getDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "transactions.db");
    final database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) {
        db.execute("""
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            $_dateColumnName TEXT NOT NULL,
            $_amountColumnName DECIMAL(10, 2) NOT NULL,
            $_referenceColumnName TEXT
          )
        """);
      }
    );
    return database;
  }

  Future<void> insertTransaction(String date, double amount, String? reference) async {
    final db = await database;

    await db.insert(
      'transactions',
      {
        'date': date,
        'amount': amount,
        'reference': reference,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double> getTotalForDay(String date) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT SUM(amount) AS total
      FROM transactions
      WHERE date = ?
    ''', [date]);

    final total = result.first['total'];
    if (total == null) return 0.0;

    if (total is int) {
      return total.toDouble();
    } else if (total is double) {
      return total;
    } else {
      return 0.0;
    }
  }

  Future<double> getTotalForMonth(String yearMonth) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT SUM(amount) AS total
      FROM transactions
      WHERE strftime('%Y-%m', date) = ?
    ''', [yearMonth]);

    final total = result.first['total'];
    if (total == null) return 0.0;

    if (total is int) {
      return total.toDouble();
    } else if (total is double) {
      return total;
    } else {
      return 0.0;
    }
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

  Future<List<Map<String, dynamic>>> getDailyTotalsForMonth(String yearMonth) async {
    final db = await database;

    return await db.rawQuery('''
      SELECT date, SUM(amount) AS total
      FROM transactions
      WHERE strftime('%Y-%m', date) = ?
      GROUP BY date
      ORDER BY date
    ''', [yearMonth]);
  }

}