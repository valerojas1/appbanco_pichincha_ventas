-- Bloque 8: transmisión electrónica, expediente, notas internas, FCM token

alter table public.solicitudescredito
  add column if not exists numeroexpediente text,
  add column if not exists analistaasignado text,
  add column if not exists fechaeenvio timestamptz,
  add column if not exists fechacomite timestamptz,
  add column if not exists fechaaprobacion timestamptz,
  add column if not exists fechadesembolso timestamptz,
  add column if not exists motivorechazo text;

create index if not exists idx_solicitudescredito_asesor_estado
  on public.solicitudescredito (asesorid, estado);

create table if not exists public.solicitudesnotasinternas (
  id uuid primary key default gen_random_uuid(),
  solicitudid uuid not null references public.solicitudescredito(id) on delete cascade,
  asesorid text not null,
  autornombre text not null,
  perfilautor text not null default 'operador',
  contenido text not null,
  createdat timestamptz not null default now()
);

create index if not exists idx_notas_solicitud
  on public.solicitudesnotasinternas (solicitudid, createdat desc);

-- Token FCM del asesor (vincula con asesorid del perfil)
-- Si la tabla YA existía en el proyecto, IF NOT EXISTS no agrega columnas.
-- Usar también: 20260603_fix_asesoresnegocio_fcm_columns.sql
create table if not exists public.asesoresnegocio (
  asesorid text primary key,
  fcmtoken text,
  fcmtokenupdatedat timestamptz,
  updatedat timestamptz not null default now()
);

alter table public.asesoresnegocio
  add column if not exists fcmtoken text,
  add column if not exists fcmtokenupdatedat timestamptz,
  add column if not exists updatedat timestamptz default now();

alter table public.solicitudesnotasinternas enable row level security;
alter table public.asesoresnegocio enable row level security;

create policy "notas_anon_all" on public.solicitudesnotasinternas
  for all using (true) with check (true);

create policy "asesores_fcm_anon_all" on public.asesoresnegocio
  for all using (true) with check (true);

-- Habilitar Realtime en solicitudescredito (ejecutar en dashboard si falla):
-- alter publication supabase_realtime add table solicitudescredito;
