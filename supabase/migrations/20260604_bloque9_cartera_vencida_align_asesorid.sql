-- Alinear cartera demo: si asesorid en filas es el código empleado (100001),
-- actualizar al asesorid real de vwperfilasesor.

update public.carteravencida cv
set asesorid = v.asesorid,
    updatedat = now()
from public.vwperfilasesor v
where trim(v.codigoempleado) = trim(cv.asesorid)
  and v.asesorid is not null
  and trim(v.asesorid) <> ''
  and trim(v.asesorid) <> trim(cv.asesorid);

-- Respaldo: también por codigoasesor si aplica
update public.carteravencida cv
set asesorid = v.asesorid,
    updatedat = now()
from public.vwperfilasesor v
where trim(v.codigoasesor) = trim(cv.asesorid)
  and v.asesorid is not null
  and trim(v.asesorid) <> ''
  and trim(v.asesorid) <> trim(cv.asesorid);
