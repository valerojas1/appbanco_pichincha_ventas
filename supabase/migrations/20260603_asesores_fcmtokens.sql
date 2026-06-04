-- Tokens FCM por asesor (no modifica la tabla asesoresnegocio del negocio).
-- El asesorid es el mismo que devuelve vwperfilasesor al iniciar sesión.

create table if not exists public.asesores_fcmtokens (
  asesorid text primary key,
  fcmtoken text,
  fcmtokenupdatedat timestamptz default now(),
  updatedat timestamptz default now()
);

alter table public.asesores_fcmtokens enable row level security;

drop policy if exists "asesores_fcmtokens_anon_all" on public.asesores_fcmtokens;
create policy "asesores_fcmtokens_anon_all" on public.asesores_fcmtokens
  for all using (true) with check (true);
