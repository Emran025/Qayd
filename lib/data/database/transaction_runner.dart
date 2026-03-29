import 'package:sqflite_sqlcipher/sqflite.dart';

/// Wraps work in a single SQLite transaction (ACID).
final class DatabaseTransactionRunner {
  DatabaseTransactionRunner(this._db);

  final Database _db;

  Future<T> run<T>(Future<T> Function(Transaction txn) action) {
    return _db.transaction(action);
  }
}
