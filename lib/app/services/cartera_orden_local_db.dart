import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class CarteraOrdenLocalDb {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      join(dir, 'carteraordenlocal.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE carteraordenlocal (
            asesorid TEXT NOT NULL,
            fecha TEXT NOT NULL,
            carteraid TEXT NOT NULL,
            posicion INTEGER NOT NULL,
            PRIMARY KEY (asesorid, fecha, carteraid)
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> guardarOrden({
    required String asesorid,
    required String fecha,
    required List<String> carteraIdsEnOrden,
  }) async {
    final db = await database;
    final batch = db.batch();
    batch.delete(
      'carteraordenlocal',
      where: 'asesorid = ? AND fecha = ?',
      whereArgs: [asesorid, fecha],
    );
    for (var i = 0; i < carteraIdsEnOrden.length; i++) {
      batch.insert('carteraordenlocal', {
        'asesorid': asesorid,
        'fecha': fecha,
        'carteraid': carteraIdsEnOrden[i],
        'posicion': i,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<Map<String, int>> cargarOrden({
    required String asesorid,
    required String fecha,
  }) async {
    final db = await database;
    final rows = await db.query(
      'carteraordenlocal',
      where: 'asesorid = ? AND fecha = ?',
      whereArgs: [asesorid, fecha],
      orderBy: 'posicion ASC',
    );
    return {
      for (final row in rows)
        row['carteraid'] as String: row['posicion'] as int,
    };
  }
}
