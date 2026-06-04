-- Bloque 9: Recuperación de cartera vencida + acciones de cobranza

create table if not exists public.carteravencida (
  id uuid primary key default gen_random_uuid(),
  asesorid text not null,
  dni text not null,
  nombrecliente text not null,
  telefono text,
  numerocredito text not null,
  saldovencido numeric(14, 2) not null default 0,
  diasmora integer not null default 0,
  fechavencimiento date,
  ultimaaccionat timestamptz,
  createdat timestamptz not null default now(),
  updatedat timestamptz not null default now()
);

create index if not exists idx_carteravencida_asesor_mora
  on public.carteravencida (asesorid, diasmora desc);

create table if not exists public.accionescobranza (
  id uuid primary key default gen_random_uuid(),
  carteravencidaid uuid not null references public.carteravencida(id) on delete cascade,
  asesorid text not null,
  tipo text not null check (tipo in ('visita', 'llamada', 'mensaje')),
  resultado text not null check (
    resultado in (
      'compromiso_pago',
      'pago_parcial',
      'sin_contacto',
      'se_niega'
    )
  ),
  montocompromiso numeric(14, 2),
  fechacompromiso date,
  montopago numeric(14, 2),
  observaciones text,
  latitud double precision,
  longitud double precision,
  registradoat timestamptz not null default now()
);

create index if not exists idx_accionescobranza_cartera
  on public.accionescobranza (carteravencidaid, registradoat desc);

alter table public.carteravencida enable row level security;
alter table public.accionescobranza enable row level security;

create policy "carteravencida_anon_all" on public.carteravencida
  for all using (true) with check (true);

create policy "accionescobranza_anon_all" on public.accionescobranza
  for all using (true) with check (true);

-- Realtime (ejecutar en dashboard si falla):
-- alter publication supabase_realtime add table carteravencida;

-- Datos demo (asesorid = código de login demo)
insert into public.carteravencida (
  asesorid, dni, nombrecliente, telefono, numerocredito,
  saldovencido, diasmora, fechavencimiento
)
select
  t.asesorid, t.dni, t.nombrecliente, t.telefono, t.numerocredito,
  t.saldovencido, t.diasmora, t.fechavencimiento
from (values
  ('100001', '44556677', 'María López Vega', '999111222', 'CR-2024-00891', 1250.00::numeric, 18, (current_date - 18)),
  ('100001', '33445566', 'Carlos Mendoza Ruiz', '988222333', 'CR-2023-01502', 890.50::numeric, 42, (current_date - 42)),
  ('100001', '22334455', 'Rosa Quispe Mamani', '977333444', 'CR-2024-02110', 2100.00::numeric, 75, (current_date - 75)),
  ('100002', '55667788', 'Juan Paredes Díaz', '966444555', 'CR-2024-03001', 450.00::numeric, 8, (current_date - 8)),
  ('100002', '66778899', 'Ana Torres Castro', '955555666', 'CR-2023-00987', 3200.00::numeric, 55, (current_date - 55))
) as t(
  asesorid, dni, nombrecliente, telefono, numerocredito,
  saldovencido, diasmora, fechavencimiento
)
where not exists (
  select 1 from public.carteravencida c
  where c.asesorid = t.asesorid and c.numerocredito = t.numerocredito
);
