-- Demo: cartera del día con coordenadas para planificación de ruta (asesor 100001).
-- Puntos en Huancayo, Perú. Idempotente: actualiza si ya existe hoy, inserta si no.

with asesor as (
  select asesorid
  from public.vwperfilasesor
  where trim(codigoempleado) = '100001'
  limit 1
),
demos as (
  select *
  from (
    values
      (
        'Cliente Demo Cartera Día'::text,
        '11223344'::text,
        'RENOVACION'::text,
        1500::numeric,
        1,
        -12.0664::double precision,
        -75.2137::double precision,
        'Plaza Huancayo (demo)'::text
      ),
      (
        'María Demo Visita',
        '55667788',
        'NUEVA SOLICITUD',
        3200,
        2,
        -12.0690,
        -75.2100,
        'Jr. Real, Huancayo (demo)'
      ),
      (
        'Pedro Demo Ruta',
        '66778899',
        'RENOVACION',
        2100,
        3,
        -12.0630,
        -75.2180,
        'Av. Giráldez, Huancayo (demo)'
      )
  ) as t(
    nombrecliente,
    documento,
    tipogestion,
    monto,
    prioridad,
    latitud,
    longitud,
    direccion
  )
),
actualizados as (
  update public.carteradiaria c
  set
    nombrecliente = d.nombrecliente,
    tipogestion = d.tipogestion,
    monto = d.monto,
    prioridad = d.prioridad,
    latitud = d.latitud,
    longitud = d.longitud,
    direccion = d.direccion,
    estadovisita = 'pendiente',
    updatedat = now()
  from asesor a
  cross join demos d
  where c.asesorid = a.asesorid
    and c.documento = d.documento
    and c.fechaasignacion = current_date
  returning c.id
)
insert into public.carteradiaria (
  asesorid,
  nombrecliente,
  documento,
  tipogestion,
  monto,
  prioridad,
  fechaasignacion,
  estadovisita,
  moraactiva,
  diasenmora,
  latitud,
  longitud,
  direccion
)
select
  a.asesorid,
  d.nombrecliente,
  d.documento,
  d.tipogestion,
  d.monto,
  d.prioridad,
  current_date,
  'pendiente',
  false,
  0,
  d.latitud,
  d.longitud,
  d.direccion
from asesor a
cross join demos d
where not exists (
  select 1
  from public.carteradiaria c
  where c.asesorid = a.asesorid
    and c.documento = d.documento
    and c.fechaasignacion = current_date
);
