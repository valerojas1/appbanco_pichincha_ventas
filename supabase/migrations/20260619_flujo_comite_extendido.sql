-- Flujo extendido: recibido_comite → en_evaluacion → aprobada/condicionada/rechazada → desembolsada

alter table public.solicitudescredito
  add column if not exists montodaprobado numeric,
  add column if not exists codigocondicion text,
  add column if not exists motivocondicion text,
  add column if not exists fechaevaluacion timestamptz,
  add column if not exists fecharecibidocomite timestamptz;

alter table public.solicitudescredito
  drop constraint if exists solicitudescredito_estado_check;

alter table public.solicitudescredito
  add constraint solicitudescredito_estado_check
  check (estado = any (array[
    'pendiente_operador',
    'en_atencion',
    'documentos_pendientes',
    'completa',
    'enviada',
    'recibido_comite',
    'en_evaluacion',
    'en_comite',
    'aprobada',
    'condicionada',
    'rechazada',
    'desembolsada',
    'pendiente',
    'en_revision'
  ]::text[]));

-- Caso 28 demo: lista negra (bloqueo total del flujo)
insert into public.listasnegras (documento, motivo, activo)
values ('00000028', 'Caso 28 — Lista negra (demo)', true)
on conflict (documento) do update
  set motivo = excluded.motivo, activo = true;
