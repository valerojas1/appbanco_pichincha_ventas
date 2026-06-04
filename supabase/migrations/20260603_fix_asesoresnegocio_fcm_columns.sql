-- OBSOLETO si asesoresnegocio no tiene columna asesorid.
-- Usar en su lugar: 20260603_asesores_fcmtokens.sql

-- Solo agrega columnas FCM (sin índice en asesorid):
alter table public.asesoresnegocio
  add column if not exists fcmtoken text,
  add column if not exists fcmtokenupdatedat timestamptz,
  add column if not exists updatedat timestamptz default now();
