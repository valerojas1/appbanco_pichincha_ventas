import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite unificado: visitas pendientes, caché cartera, movimientos, preaprobados.
class AppLocalDatabase {
  AppLocalDatabase._();
  static final AppLocalDatabase instance = AppLocalDatabase._();

  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      join(dir, 'pichincha_ventas_offline.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE visitaspendientes (
            id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            pendientesync INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cartera_diaria_cache (
            asesorid TEXT NOT NULL,
            fecha TEXT NOT NULL,
            payload TEXT NOT NULL,
            synced_at TEXT NOT NULL,
            PRIMARY KEY (asesorid, fecha)
          )
        ''');
        await db.execute('''
          CREATE TABLE movimientos_cache (
            clienteid TEXT NOT NULL,
            asesorid TEXT NOT NULL,
            payload TEXT NOT NULL,
            synced_at TEXT NOT NULL,
            PRIMARY KEY (clienteid, asesorid)
          )
        ''');
        await db.execute('''
          CREATE TABLE preaprobados_cache (
            asesorid TEXT NOT NULL,
            payload TEXT NOT NULL,
            synced_at TEXT NOT NULL,
            PRIMARY KEY (asesorid)
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_meta (
            clave TEXT PRIMARY KEY,
            valor TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  // --- Visitas pendientes ---

  Future<void> insertarVisitaPendiente({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    await db.insert(
      'visitaspendientes',
      {
        'id': id,
        'payload': jsonEncode(payload),
        'pendientesync': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> listarVisitasPendientes() async {
    final db = await database;
    final rows = await db.query(
      'visitaspendientes',
      where: 'pendientesync = ?',
      whereArgs: [1],
      orderBy: 'created_at ASC',
    );
    return rows.map((r) {
      final payload = Map<String, dynamic>.from(
        jsonDecode(r['payload'] as String) as Map,
      );
      return {
        'id': r['id'] as String,
        'payload': payload,
      };
    }).toList();
  }

  Future<int> contarVisitasPendientes() async {
    final db = await database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) as c FROM visitaspendientes WHERE pendientesync = 1',
    );
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<void> marcarVisitaSincronizada(String id) async {
    final db = await database;
    await db.delete('visitaspendientes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> limpiarVisitasPendientes() async {
    final db = await database;
    await db.delete('visitaspendientes');
  }

  // --- Cartera caché ---

  Future<void> guardarCarteraCache({
    required String asesorid,
    required String fecha,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await database;
    await db.insert(
      'cartera_diaria_cache',
      {
        'asesorid': asesorid,
        'fecha': fecha,
        'payload': jsonEncode(items),
        'synced_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> leerCarteraCache({
    required String asesorid,
    required String fecha,
  }) async {
    final db = await database;
    final rows = await db.query(
      'cartera_diaria_cache',
      where: 'asesorid = ? AND fecha = ?',
      whereArgs: [asesorid, fecha],
      limit: 1,
    );
    if (rows.isEmpty) return [];
    final list = jsonDecode(rows.first['payload'] as String) as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> guardarMovimientosCliente({
    required String clienteid,
    required String asesorid,
    required List<Map<String, dynamic>> movimientos,
  }) async {
    final db = await database;
    await db.insert(
      'movimientos_cache',
      {
        'clienteid': clienteid,
        'asesorid': asesorid,
        'payload': jsonEncode(movimientos),
        'synced_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> guardarPreaprobados({
    required String asesorid,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await database;
    await db.insert(
      'preaprobados_cache',
      {
        'asesorid': asesorid,
        'payload': jsonEncode(items),
        'synced_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setMeta(String clave, String valor) async {
    final db = await database;
    await db.insert(
      'sync_meta',
      {'clave': clave, 'valor': valor},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getMeta(String clave) async {
    final db = await database;
    final rows = await db.query(
      'sync_meta',
      where: 'clave = ?',
      whereArgs: [clave],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['valor'] as String?;
  }
}
