-- Seguro de desgravamen opcional en solicitudes de crédito.
ALTER TABLE public.solicitudescredito
  ADD COLUMN IF NOT EXISTS incluyesegurodesgravamen boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.solicitudescredito.incluyesegurodesgravamen IS
  'Indica si la cuota incluye prima de seguro de desgravamen.';
