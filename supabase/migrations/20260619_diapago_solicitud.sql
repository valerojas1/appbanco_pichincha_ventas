-- Día del mes en que vencen las cuotas del crédito.
ALTER TABLE public.solicitudescredito
  ADD COLUMN IF NOT EXISTS diapago integer;

COMMENT ON COLUMN public.solicitudescredito.diapago IS
  'Día del mes (1-28) en que vence cada cuota mensual.';
