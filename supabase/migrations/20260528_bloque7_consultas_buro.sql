-- Bloque 7: consulta buró + listas negras (auditoría Ley 29733)
create table if not exists public.consultasburo (
  id uuid primary key default gen_random_uuid(),
  documento text not null,
  nombres text,
  asesorid text not null,
  clasificacion_sbs text not null default 'Normal',
  entidades_con_deuda jsonb not null default '[]'::jsonb,
  deuda_total numeric not null default 0,
  mayor_deuda numeric not null default 0,
  dias_mora_historica int not null default 0,
  enlistanegra boolean not null default false,
  lista_negra_motivo text,
  firma_consentimiento text,
  fecha_consentimiento timestamptz not null default now(),
  reutilizada boolean not null default false,
  consulta_origen_id uuid references public.consultasburo(id),
  createdat timestamptz not null default now()
);

create index if not exists idx_consultasburo_documento_fecha
  on public.consultasburo (documento, createdat desc);

create table if not exists public.listasnegras (
  id uuid primary key default gen_random_uuid(),
  documento text not null unique,
  motivo text,
  activo boolean not null default true,
  createdat timestamptz not null default now()
);

-- Demo lista negra
insert into public.listasnegras (documento, motivo, activo)
values
  ('99999999', 'Fraude reportado — demo', true),
  ('88776655', 'Incumplimiento grave — demo', true)
on conflict (documento) do nothing;

alter table public.consultasburo enable row level security;
alter table public.listasnegras enable row level security;

create policy "consultasburo_anon_all" on public.consultasburo
  for all using (true) with check (true);

create policy "listasnegras_anon_select" on public.listasnegras
  for select using (true);
