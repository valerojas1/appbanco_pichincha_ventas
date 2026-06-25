-- Defaults para insert mínimo desde app cliente

alter table public.solicitudescredito
  alter column estadocivil set default 'soltero',
  alter column gradoinstruccion set default 'secundaria',
  alter column tiponegocio set default 'Comercio',
  alter column destinocredito set default 'Capital de Trabajo';
