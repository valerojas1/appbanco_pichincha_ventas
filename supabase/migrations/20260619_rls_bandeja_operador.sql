-- RLS solicitudescredito: políticas permisivas alineadas al resto del proyecto.
-- (Evita bandeja vacía si RLS queda activo sin política SELECT.)

alter table public.solicitudescredito enable row level security;

drop policy if exists "bandeja_operador_select_pendientes" on public.solicitudescredito;
drop policy if exists "solicitudescredito_anon_all" on public.solicitudescredito;

create policy "solicitudescredito_anon_all"
on public.solicitudescredito
for all
to anon, authenticated
using (true)
with check (true);