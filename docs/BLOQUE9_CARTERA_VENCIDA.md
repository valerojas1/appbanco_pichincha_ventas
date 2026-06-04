# Bloque 9 — Recuperación de cartera vencida

## Migración

Ejecutar en Supabase SQL Editor o con CLI:

```bash
supabase db push
# o el archivo:
# supabase/migrations/20260604_bloque9_cartera_vencida.sql
```

Habilitar **Realtime** en la tabla `carteravencida` (Dashboard → Database → Publications → `supabase_realtime`):

```sql
alter publication supabase_realtime add table carteravencida;
```

## App

Menú lateral → **Cartera vencida**.

- Lista filtrada por `asesorid` del login y `diasmora > 0`.
- Encabezado: suma de `saldovencido`.
- Semáforo: 1–30 amarillo, 31–60 naranja, >60 rojo.
- Tocar cliente → formulario de cobranza (tipo, resultado, GPS, hora).
- **Compromiso de pago**: notificación local el día acordado a las 9:00 (zona Lima).
- **Pago parcial**: actualiza `saldovencido` en Supabase; el listado se refresca vía Realtime.

## Datos demo

Tras la migración, el asesor `100001` tiene 3 clientes en mora; `100002` tiene 2.

Si la lista sale vacía, ejecuta también:

```sql
-- supabase/migrations/20260604_bloque9_cartera_vencida_align_asesorid.sql
```

Eso alinea `carteravencida.asesorid` con el `asesorid` real de `vwperfilasesor` (el login usa código `100001`, pero el perfil puede tener otro id).

## Tablas

| Tabla | Uso |
|-------|-----|
| `carteravencida` | Cartera en mora por asesor |
| `accionescobranza` | Historial de gestiones |
