import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Caché local de fichas de cliente (sincronización nocturna / uso offline).
class FichaClienteOfflineDb {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      join(dir, 'ficha_cliente_cache.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE ficha_cliente_cache (
            clienteid TEXT PRIMARY KEY,
            asesorid TEXT NOT NULL,
            payload TEXT NOT NULL,
            synced_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE ficha_cliente_sync_meta (
            asesorid TEXT PRIMARY KEY,
            last_sync TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> guardarFicha({
    required String clienteid,
    required String asesorid,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    await db.insert(
      'ficha_cliente_cache',
      {
        'clienteid': clienteid,
        'asesorid': asesorid,
        'payload': jsonEncode(payload),
        'synced_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> leerFicha(String clienteid) async {
    final db = await database;
    final rows = await db.query(
      'ficha_cliente_cache',
      where: 'clienteid = ?',
      whereArgs: [clienteid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(
      jsonDecode(rows.first['payload'] as String) as Map,
    );
  }

  Future<List<String>> listarClienteIdsPorAsesor(String asesorid) async {
    final db = await database;
    final rows = await db.query(
      'ficha_cliente_cache',
      columns: ['clienteid'],
      where: 'asesorid = ?',
      whereArgs: [asesorid],
    );
    return rows.map((r) => r['clienteid'] as String).toList();
  }

  Future<void> marcarSyncAsesor(String asesorid) async {
    final db = await database;
    await db.insert(
      'ficha_cliente_sync_meta',
      {
        'asesorid': asesorid,
        'last_sync': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DateTime?> ultimaSyncAsesor(String asesorid) async {
    final db = await database;
    final rows = await db.query(
      'ficha_cliente_sync_meta',
      where: 'asesorid = ?',
      whereArgs: [asesorid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['last_sync'] as String);
  }
}
