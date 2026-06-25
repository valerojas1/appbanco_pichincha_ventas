# Recordatorios del proyecto

## Bloque 8 — Push desde Supabase (punto 4)

**Estado:** verificado y funcionando.

- Secret `FCM_SERVICE_ACCOUNT_JSON` configurado en Supabase.
- Edge Function `notificar-solicitud` desplegada (API HTTP v1).
- Token FCM del asesor en tabla `asesores_fcmtokens`.
- Prueba manual desde Firebase Console: OK.
- Prueba vía función Supabase (`curl` o cambio de estado + invoke): OK.

La prueba de Firebase solo valida el canal FCM; la función Supabase envía notificaciones de negocio (comité, aprobado, rechazado, desembolsado).

- Automático al cambiar `estado`: `docs/GUIA_NOTIFICACIONES_AUTOMATICAS.md`
- Firebase y token: `docs/GUIA_FCM_FIREBASE.md` sección 9.
