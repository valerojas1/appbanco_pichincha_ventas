# Bloque 10 — Modo offline, sincronización y reportes

## Modo offline

- Patrón **ViewModel → Repository → red / SQLite** (ej. `CarteraRepository`).
- Banner **Modo offline** en la parte superior del shell cuando no hay red.
- Cola SQLite `visitaspendientes` con `pendientesync=1`; al reconectar se envía en lote.
- Borradores: `solicitudesborrador` / cola envío (existente).
- Orden cartera: `carteraordenlocal` (existente).

## Sincronización al reconectar

- `PendingSyncRepository` sincroniza visitas, fichas, pre-evaluaciones y solicitudes en cola.
- Botón **ENVIAR** en el banner si hay pendientes y hay red.

## Sincronización nocturna (22:00)

- `workmanager` programa tarea diaria.
- Descarga: cartera del día siguiente, fichas, movimientos (3 meses si existe tabla), preaprobados vigentes.
- Notificación local: *"Tu cartera de mañana está lista — X clientes"*.

Requiere sesión activa (perfil en almacenamiento seguro).

## Reportes (Supervisor / Administrador)

| Menú | Función |
|------|---------|
| **Monitor asesores** | Mapa + tabla visitados/total, Realtime `carteradiaria` |
| **Productividad mensual** | Tabla + gráfico barras + exportar PDF |

## SQL recomendado

```sql
alter publication supabase_realtime add table carteradiaria;
```

Archivo: `supabase/migrations/20260605_bloque10_realtime_carteradiaria.sql`

## Prueba offline — Cartera del día (flujo exacto)

La lista **no se descarga sola** sin internet. Primero debes **guardar una copia** en el celular.

### Paso A — Con WiFi/datos (obligatorio)

1. Login (`100001` / `asesor123`).
2. Menú → **Cartera del día**.
3. Espera a que termine el spinner y **veas clientes en la lista**.
   - Si sale vacío **con internet**, en Supabase no hay filas de `carteradiaria` para **hoy** y tu `asesorid`. Inserta datos de prueba (ver abajo) y repite.

En ese momento la app guarda la cartera de hoy en SQLite del teléfono.

### Paso B — Sin red

4. Activa **modo avión** (o apaga WiFi).
5. Arriba debe aparecer el banner naranja: **Modo offline**.
6. Entra otra vez a **Cartera del día**, o **desliza hacia abajo** para refrescar.
7. Deberías ver **la misma lista** que en el paso A (desde caché).

### Paso C — Visita en cola (opcional)

8. Abre un cliente → registra visita sin red.
9. Vuelve a tener internet → banner **ENVIAR** o sincronización automática.

### Datos demo en Supabase (si la lista online está vacía)

`carteradiaria.asesorid` es **UUID**, no el código `100001`. Ejecuta en SQL Editor:

```sql
-- Archivo completo:
-- supabase/migrations/20260606_carteradiaria_demo_hoy.sql
```

O verifica tu UUID:

```sql
select asesorid, codigoempleado, nombre, apellido
from vwperfilasesor
where codigoempleado = '100001';
```

## Prueba reportes

Login supervisor/admin → **Monitor asesores** / **Productividad mensual**.
