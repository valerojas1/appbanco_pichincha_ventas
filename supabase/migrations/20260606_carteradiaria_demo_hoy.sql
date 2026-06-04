-- Demo: cartera del día para el asesor con código 100001 (usa UUID real de vwperfilasesor)
-- Ejecutar en SQL Editor si "Cartera del día" sale vacía con internet.

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
  diasenmora
)
select
  v.asesorid,
  'Cliente Demo Cartera Día',
  '11223344',
  'RENOVACION',
  1500,
  1,
  current_date,
  'pendiente',
  false,
  0
from public.vwperfilasesor v
where trim(v.codigoempleado) = '100001'
  and not exists (
    select 1
    from public.carteradiaria c
    where c.asesorid = v.asesorid
      and c.fechaasignacion = current_date
  )
limit 1;

-- Segundo cliente demo (opcional)
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
  diasenmora
)
select
  v.asesorid,
  'María Demo Visita',
  '55667788',
  'NUEVA SOLICITUD',
  3200,
  2,
  current_date,
  'pendiente',
  false,
  0
from public.vwperfilasesor v
where trim(v.codigoempleado) = '100001'
  and not exists (
    select 1
    from public.carteradiaria c
    where c.asesorid = v.asesorid
      and c.documento = '55667788'
      and c.fechaasignacion = current_date
  )
limit 1;
