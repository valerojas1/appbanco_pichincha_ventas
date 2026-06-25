-- Demo E2E: cartera NUEVA SOLICITUD + cliente caso 28 (lista negra)

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
  'Cliente Caso 28 Lista Negra',
  '00000028',
  'NUEVA SOLICITUD',
  4000,
  3,
  current_date,
  'pendiente',
  false,
  0
from public.vwperfilasesor v
where trim(v.codigoempleado) = '100001'
  and not exists (
    select 1 from public.carteradiaria c
    where c.asesorid = v.asesorid
      and c.documento = '00000028'
      and c.fechaasignacion = current_date
  )
limit 1;
