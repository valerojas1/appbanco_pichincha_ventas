import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../model/solicitud_credito_data.dart';

class SolicitudesBorradorDb {
  static Database? _db;
  static const _uuid = Uuid();

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      join(dir, 'solicitudes_borrador.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE solicitudesborrador (
            id TEXT PRIMARY KEY,
            asesorid TEXT NOT NULL,
            paso_actual INTEGER NOT NULL,
            nombre_display TEXT NOT NULL,
            monto REAL NOT NULL,
            payload TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE solicitudes_cola_envio (
            id TEXT PRIMARY KEY,
            asesorid TEXT NOT NULL,
            nombre_display TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<String> guardarBorrador(SolicitudCreditoData data) async {
    final db = await database;
    final id = data.borradorIdLocal ?? _uuid.v4();
    data.borradorIdLocal = id;
    final nombre = data.nombreCompleto.isEmpty
        ? 'Sin nombre'
        : data.nombreCompleto;
    await db.insert(
      'solicitudesborrador',
      {
        'id': id,
        'asesorid': data.asesorid,
        'paso_actual': data.pasoActual + 1,
        'nombre_display': nombre,
        'monto': data.monto,
        'payload': jsonEncode(data.toJson()),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  Future<List<SolicitudBorradorResumen>> listarPorAsesor(String asesorid) async {
    final db = await database;
    final rows = await db.query(
      'solicitudesborrador',
      where: 'asesorid = ?',
      whereArgs: [asesorid],
      orderBy: 'updated_at DESC',
    );
    return rows
        .map(
          (r) => SolicitudBorradorResumen(
            id: r['id'] as String,
            nombre: r['nombre_display'] as String,
            pasoAlcanzado: r['paso_actual'] as int,
            fechaActualizacion: r['updated_at'] as String,
            monto: (r['monto'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<SolicitudCreditoData?> cargarBorrador(String id) async {
    final db = await database;
    final rows = await db.query(
      'solicitudesborrador',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final map = Map<String, dynamic>.from(
      jsonDecode(rows.first['payload'] as String) as Map,
    );
    return SolicitudCreditoData.fromJson(map);
  }

  Future<void> eliminarBorrador(String id) async {
    final db = await database;
    await db.delete('solicitudesborrador', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> encolarEnvio(SolicitudCreditoData data) async {
    final db = await database;
    final id = _uuid.v4();
    await db.insert('solicitudes_cola_envio', {
      'id': id,
      'asesorid': data.asesorid,
      'nombre_display': data.nombreCompleto,
      'payload': jsonEncode(data.toJson()),
      'created_at': DateTime.now().toIso8601String(),
    });
    if (data.borradorIdLocal != null) {
      await eliminarBorrador(data.borradorIdLocal!);
    }
  }

  Future<List<Map<String, dynamic>>> listarColaEnvio() async {
    final db = await database;
    return db.query('solicitudes_cola_envio', orderBy: 'created_at ASC');
  }

  Future<int> contarColaEnvio() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM solicitudes_cola_envio');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<void> eliminarDeCola(String id) async {
    final db = await database;
    await db.delete('solicitudes_cola_envio', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> limpiarColaEnvio() async {
    final db = await database;
    await db.delete('solicitudes_cola_envio');
  }
}
