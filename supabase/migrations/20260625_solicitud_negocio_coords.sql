-- Coordenadas GPS del local/negocio en solicitudes de crédito (app cliente → operador)

alter table public.solicitudescredito
  add column if not exists latitudnegocio double precision,
  add column if not exists longitudnegocio double precision;

comment on column public.solicitudescredito.latitudnegocio is
  'Latitud WGS84 del local del negocio (grados decimales). Enviada desde app cliente.';

comment on column public.solicitudescredito.longitudnegocio is
  'Longitud WGS84 del local del negocio (grados decimales). Enviada desde app cliente.';

create index if not exists idx_solicitudescredito_coords_negocio
  on public.solicitudescredito (latitudnegocio, longitudnegocio)
  where latitudnegocio is not null and longitudnegocio is not null;
