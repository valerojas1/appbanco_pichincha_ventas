# Bloques compartidos: App Ventas → App Clientes (Banco Pichincha)

Documento de referencia para desarrollar la **app de clientes** manteniendo consistencia con **appbanco_pichincha_ventas**. Solo incluye funcionalidades con vínculo real hacia una banca móvil de clientes. Ambas apps usan el **mismo proyecto Supabase**.

**Código de referencia (ventas):** `lib/app/` (services, models, viewmodels), `supabase/migrations/`, `supabase/functions/`.

---

## Qué NO replicar en la app clientes (solo ventas / asesores)

| Área | Motivo |
|------|--------|
| Login por código empleado (`@empleados.pichincha.pe`, `vwperfilasesor`) | Rol operativo interno |
| Cartera del día, rutas, geocercas, fichas de campo, visitas, resultados de visita | Gestión de campo del asesor |
| Cartera vencida + acciones de cobranza con GPS | Cobranza operativa |
| Monitor de asesores, metas, dashboard/productividad de asesor | Supervisión interna |
| Cliente desertor, notas internas de solicitud | Registro interno |
| Transmisión electrónica completa (pasos asesor → comité) | Flujo back-office del asesor |
| Scoring vía RPC `evaluarcreditocampo` ligado a `fichascampo` | Evaluación en visita, no self-service |
| FCM en `asesores_fcmtokens` / `asesoresnegocio` | Tokens de asesores |

---

## Consideraciones globales Supabase (ambas apps)

1. **Mismo proyecto:** URL y anon key en `lib/app/core/supabase_config.dart` (ventas). La app clientes debe apuntar al mismo `supabaseUrl` / `supabaseAnonKey` o variables de entorno equivalentes.
2. **RLS actual:** Varias tablas tienen políticas permisivas de demo (`using (true)`). **Antes de producción clientes**, definir políticas por `auth.uid()` vinculado a `clientes.id` o `clientes.documento` — nunca exponer filas de otros clientes ni datos de asesores.
3. **Identificación cliente en solicitudes:** `solicitudescredito` se filtra hoy por `asesorid` y `dni`; la app clientes debe usar **`dni` = documento del usuario autenticado** (y/o agregar columna `clienteid` en migración futura).
4. **Auth separado:** Ventas: `signInWithPassword` + email sintético de empleado. Clientes: flujo propio (ej. DNI + OTP, magic link, etc.) con fila en `clientes` ligada a `auth.users`.
5. **Storage:** bucket `documentos-solicitudes` — políticas de lectura/escritura solo para rutas `{solicitudId}/` del cliente dueño.
6. **Realtime:** Habilitar en tablas que el cliente observe (`solicitudescredito`, `alertascartera`, etc.) con filtros RLS, no filtros solo en cliente Dart.
7. **Edge Functions:** Reutilizar donde aplique; extender payload para rol `cliente` (sin `asesorid` obligatorio en consultas iniciadas por el cliente).

---

## Bloque 1 — Autenticación y sesión

**En ventas:** `AuthService`, `AuthOficialViewModel`, `auth_constants.dart` — sesión Supabase Auth, perfil desde `vwperfilasesor`, bloqueo por intentos, cierre por inactividad (8 h).

**En app clientes (hacer):**
- Registro/login del titular (documento, teléfono, contraseña o OTP).
- Tras login, cargar perfil desde `clientes` (`eq('auth_user_id', uid)` o por `documento`).
- Misma librería: `supabase_flutter`, `flutter_secure_storage` para refresh token.
- **No** usar dominio `@empleados.pichincha.pe`.

**Supabase:** Vista/tabla `clientes`; opcional `vwperfilcliente`. Política: cada usuario solo lee/actualiza su fila.

**Referencia ventas:** `lib/app/services/auth_service.dart`, `lib/app/view/auth/`.

---

## Bloque 2 — Perfil y posición financiera del cliente

**En ventas:** Ficha del cliente — datos maestros, semáforo SBS, deuda, mora, último pago. Servicio `FichaClienteService`, pantalla `ficha_cliente_screen.dart`.

**En app clientes (hacer):**
- Pantalla “Mi perfil” / “Mi situación crediticia”.
- Consultar `clientes` por `id` o `documento`.
- Posición en vivo: Edge Function `consulta-posicion` (`clienteid` / `documento`); fallback a campos en `clientes` si offline.
- Mostrar clasificación SBS, deuda total, cuentas en mora, días de mora (mismos modelos: `ClienteFichaModel`, `PosicionClienteModel`).

**Tablas / funciones:** `clientes`, `consulta-posicion` (invoke).

**Referencia ventas:** `lib/app/services/ficha_cliente_service.dart`, `lib/app/model/cliente_ficha_model.dart`, `lib/app/model/posicion_cliente_model.dart`.

---

## Bloque 3 — Créditos, pagos e historial

**En ventas:** En ficha: últimos créditos (`creditos`), gráfico 12 meses (`pagosmensuales`), amortización en wizard de solicitud (`amortizacion_francesa.dart`).

**En app clientes (hacer):**
- Listado de créditos activos/cerrados del cliente (`creditos` where `clienteid`).
- Detalle: monto, plazo, TEA, fechas desembolso.
- Historial de pagos mensuales (últimos 12 periodos).
- Simulador de cuota (reutilizar lógica de `SolicitudCreditoData.cuotaMensual` / `AmortizacionFrancesa` en UI, sin insertar solicitud).

**Tablas:** `creditos`, `pagosmensuales`.

**Referencia ventas:** `lib/app/model/credito_historial_model.dart`, `lib/app/model/pago_mensual_model.dart`, `lib/app/core/amortizacion_francesa.dart`.

---

## Bloque 4 — Ofertas preaprobadas, campañas y alertas

**En ventas:** Oferta en ficha (`creditospreaprobados`), campañas en cartera (`campanasactivas`), alertas (`alertascartera`), lista `vwclientesfinancieros` en home.

**En app clientes (hacer):**
- Banner “Tienes un crédito preaprobado” con monto, plazo, TEA, vigencia.
- Campañas activas filtradas por `clienteid` o documento (`campanasactivas`, `activa = true`).
- Centro de alertas: mora, vencimiento de pago, promociones (`alertascartera`).
- Opcional: resumen tipo `ClienteFinancieroModel` si existe vista `vwclientesfinancieros` filtrada por cliente.

**Tablas / vistas:** `creditospreaprobados`, `campanasactivas`, `alertascartera`, `vwclientesfinancieros`, `preaprobados`, `movimientoscliente` (movimientos recientes — usado en sync nocturna ventas).

**Referencia ventas:** `lib/app/services/campana_activa_service.dart`, `lib/app/model/campana_activa_model.dart`, `lib/app/model/alerta_cartera_model.dart`, `lib/app/services/cliente_credito_service.dart`.

---

## Bloque 5 — Solicitudes de crédito (seguimiento del cliente)

**En ventas:** Wizard de alta, borradores locales, tablero por estado, detalle, estados en `EstadoSolicitud`.

**En app clientes (hacer):**
- **Solo lectura + acciones limitadas** del ciclo iniciado por asesor o por el propio cliente:
  - Listar `solicitudescredito` where `dni` = documento autenticado.
  - Mostrar estado: `documentos_pendientes` → `desembolsada` / `rechazada` (ver `estado_solicitud.dart`).
  - Campos visibles: monto, plazo, expediente, analista (si aplica), fechas (`fechaeenvio`, `fechaaprobacion`, `fechadesembolso`, `motivorechazo`).
- Realtime: suscripción a cambios en `solicitudescredito` filtrada por `dni` (equivalente a `SolicitudEstadoService.suscribirCambios`, cambiando filtro de `asesorid` a `dni`).
- **No** implementar transmisión al comité ni notas internas.

**Tablas:** `solicitudescredito` (columnas Bloque 8 en migración `20260528_bloque8_transmision_solicitudes.sql`).

**Referencia ventas:** `lib/app/model/estado_solicitud.dart`, `lib/app/services/solicitud_estado_service.dart`, `lib/app/view/home/solicitudes_tablero_screen.dart`.

---

## Bloque 6 — Documentos del expediente

**En ventas:** Captura con cámara, nitidez, subida a Storage, registro en `solicitudesdocumentos`, catálogo en `TipoDocumentoConfig`.

**En app clientes (hacer):**
- Ver estado de documentos requeridos por solicitud (lista desde `solicitudesdocumentos` + URLs del bucket `documentos-solicitudes`).
- Subir documentos **solo si** el flujo lo permite al cliente (mismos `tipodocumento`: DNI, foto negocio, etc.); rutas `{solicitudId}/{tipo}.jpg`.
- Validar que la solicitud pertenece al cliente antes de upload.
- Opcional: visor de imagen (referencia `visor_documento_screen.dart`).

**Storage / tablas:** bucket `documentos-solicitudes`, tabla `solicitudesdocumentos`.

**Referencia ventas:** `lib/app/services/solicitud_documento_service.dart`, `lib/app/model/tipo_documento_config.dart`.

---

## Bloque 7 — Buró de crédito y consentimiento (Ley 29733)

**En ventas:** Edge `consulta-buro`, tabla `consultasburo`, lista negra `listasnegras`, firma de consentimiento, reutilización 30 días.

**En app clientes (hacer):**
- Pantalla de autorización con firma (base64) antes de consulta o solicitud.
- Invocar `consulta-buro` con `documento` del cliente y `firma_consentimiento` (sin `asesorid` o con identificador sistema).
- Mostrar resultado resumido (clasificación SBS, deuda total) — no exponer auditoría de otros usuarios.
- Bloqueo si `listasnegras.activo` para su documento (mismo comportamiento que `lista_negra_bloqueo_dialog`).

**Tablas / funciones:** `consultasburo`, `listasnegras`, `supabase/functions/consulta-buro/`, migración `20260528_bloque7_consultas_buro.sql`.

**Referencia ventas:** `lib/app/services/consulta_buro_service.dart`, `lib/app/view/home/consulta_buro_screen.dart`.

---

## Bloque 8 — Pre-evaluación / simulación de crédito

**En ventas:** Edge `pre-evaluar`, pantalla pre-evaluación para prospectos (asesor captura datos).

**En app clientes (hacer):**
- Simulador self-service: ingresos, tipo negocio, monto, destino → invoke `pre-evaluar`.
- Mostrar recomendación / elegibilidad (`PreEvaluacionResultadoModel`) sin crear solicitud automática, o botón “Solicitar” que abre flujo con asesor.
- Cola offline opcional (ventas usa SharedPreferences); en clientes puede ser menos crítico.

**Función:** `pre-evaluar`.

**Referencia ventas:** `lib/app/services/preevaluacion_service.dart`, `lib/app/view/home/pre_evaluacion_screen.dart`.

---

## Bloque 9 — Notificaciones push al cliente

**En ventas:** FCM para asesores (`fcm_token_service`, `notificar-solicitud` → token en `asesores_fcmtokens`). Tipos: comité, aprobado, rechazado, desembolsado.

**En app clientes (hacer):**
- Tabla dedicada ej. `clientes_fcmtokens` (`clienteid`, `fcmtoken`, `updatedat`).
- Extender Edge `notificar-solicitud` (o nueva `notificar-cliente`) para enviar al **cliente** cuando cambie `estado` en `solicitudescredito` (aprobada, rechazada, desembolsada).
- Misma configuración Firebase / secret `FCM_SERVICE_ACCOUNT_JSON` en Supabase.
- Deep link a detalle de solicitud o alerta.

**Referencia ventas:** `docs/GUIA_FCM_FIREBASE.md`, `lib/app/services/fcm_messaging_service.dart`, `supabase/functions/notificar-solicitud/index.ts`.

---

## Bloque 10 — UX transversal (tema, offline, red)

**En ventas:** Tema oscuro/amarillo (`app_theme.dart`), banner offline, sync local SQLite para fichas y borradores.

**En app clientes (hacer):**
- Reutilizar paleta y patrones de tarjetas para marca consistente (no copiar menú de asesor).
- `connectivity_plus` + mensaje sin conexión.
- Caché local solo de **datos del cliente logueado** (equivalente ligero a `FichaClienteOfflineDb`, sin cartera de terceros).
- **No** portar WorkManager de sync nocturna de cartera del asesor.

**Referencia ventas:** `lib/app/ui/theme/app_theme.dart`, `lib/app/ui/widgets/modo_offline_banner.dart`, `lib/app/services/ficha_cliente_offline_db.dart`.

---

## Matriz rápida: tablas y funciones compartidas

| Recurso | Ventas | Clientes |
|---------|--------|----------|
| `clientes` | Lectura ficha | Perfil propio |
| `creditos`, `pagosmensuales` | Historial en ficha | Mis productos |
| `creditospreaprobados`, `campanasactivas` | Oferta/campaña | Promociones |
| `alertascartera` | En ficha | Notificaciones in-app |
| `solicitudescredito` | CRUD + estados asesor | Seguimiento por `dni` |
| `solicitudesdocumentos` + Storage | Captura asesor | Ver/subir propios |
| `consultasburo`, `listasnegras` | Asesor + firma | Consentimiento propio |
| `consulta-posicion`, `pre-evaluar`, `consulta-buro` | Invoke | Invoke (rol cliente) |
| `vwperfilasesor`, `carteradiaria`, `carteravencida` | Sí | **No** |

---

## Orden sugerido de implementación (app clientes)

1. Bloque 1 (auth + `clientes`) + Supabase RLS base.  
2. Bloque 2 y 3 (perfil, créditos, pagos).  
3. Bloque 5 y 6 (seguimiento solicitud + documentos).  
4. Bloque 4 (ofertas y alertas).  
5. Bloque 7 y 8 (buró consentimiento, simulador).  
6. Bloque 9 (push).  
7. Bloque 10 (pulido offline/tema).

---

## Estructura del proyecto ventas (mapa para el agente)

```
lib/app/
  core/          # supabase_config, auth_constants, amortización, semáforos
  model/         # DTOs alineados a tablas Supabase
  services/      # Acceso datos (reutilizar contratos, no copiar lógica de asesor)
  viewmodel/     # Estado UI
  view/          # Pantallas (referencia de flujos, no copiar menú completo)
  navigation/    # Rutas y menú por perfil oficial
supabase/
  migrations/    # Esquema compartido — revisar antes de nuevas columnas
  functions/     # Edge Functions compartidas o a extender
docs/            # Guías FCM, bloques 9–10 ventas (solo operación asesor)
```

---

*Generado a partir del análisis de `appbanco_pichincha_ventas`. Actualizar si se agregan módulos nuevos en ventas con impacto en clientes.*
