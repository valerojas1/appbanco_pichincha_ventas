-- Ampliar estados válidos del ciclo de vida (cliente → operador → admin)

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
    'en_comite',
    'aprobada',
    'rechazada',
    'desembolsada',
    -- legacy (compatibilidad)
    'pendiente',
    'en_revision'
  ]::text[]));
