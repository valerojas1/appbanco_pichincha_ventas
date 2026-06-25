-- Flujo cliente → operador → admin: origen, bandeja sin asesor y campos parciales

alter table public.solicitudescredito
  add column if not exists origen text default 'app_ventas';

-- Bandeja compartida: solicitud sin operador asignado
alter table public.solicitudescredito
  alter column asesorid drop not null;

-- El cliente envía datos mínimos; el operador completa en la visita
alter table public.solicitudescredito
  alter column fechanacimiento drop not null,
  alter column nombrenegocio drop not null,
  alter column direccionnegocio drop not null;

alter table public.solicitudescredito
  alter column nombrenegocio set default '',
  alter column direccionnegocio set default '',
  alter column gastosestimados set default 0,
  alter column cuotamensual set default 0,
  alter column declaracionjurada set default false;

comment on column public.solicitudescredito.origen is
  'app_cliente | app_ventas — quién originó la solicitud';

create index if not exists idx_solicitudescredito_pendiente_operador
  on public.solicitudescredito (estado, createdat desc)
  where estado = 'pendiente_operador';

create index if not exists idx_solicitudescredito_en_atencion
  on public.solicitudescredito (asesorid, estado)
  where estado = 'en_atencion';
