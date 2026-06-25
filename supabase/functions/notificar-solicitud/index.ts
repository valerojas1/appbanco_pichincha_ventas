/**
 * Envía notificación FCM (API HTTP v1 — sin clave Legacy).
 *
 * Modos de entrada:
 * 1) Manual: { "solicitud_id": "uuid", "tipo": "aprobado" }
 * 2) Database Webhook (UPDATE en solicitudescredito): payload con record / old_record
 *
 * Secret: FCM_SERVICE_ACCOUNT_JSON (ver docs/GUIA_FCM_FIREBASE.md)
 * Opcional: WEBHOOK_SECRET — header x-webhook-secret debe coincidir
 */
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleAuth } from "npm:google-auth-library@9.15.1";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-webhook-secret",
};

type TipoNotif =
  | "recibido_comite"
  | "aprobado"
  | "condicionado"
  | "rechazado"
  | "desembolsado";

const TIPOS_VALIDOS: TipoNotif[] = [
  "recibido_comite",
  "aprobado",
  "condicionado",
  "rechazado",
  "desembolsado",
];

function tipoDesdeEstado(estado: string): TipoNotif | null {
  switch (estado) {
    case "recibido_comite":
    case "en_comite":
      return "recibido_comite";
    case "aprobada":
      return "aprobado";
    case "condicionada":
      return "condicionado";
    case "rechazada":
      return "rechazado";
    case "desembolsada":
      return "desembolsado";
    default:
      return null;
  }
}

type PayloadEntrada = {
  solicitudId: string;
  tipo: TipoNotif;
  origen: "manual" | "webhook";
};

function parseEntrada(body: Record<string, unknown>): PayloadEntrada | null {
  const solicitudManual = String(body.solicitud_id ?? "");
  const tipoManual = body.tipo as string;
  if (
    solicitudManual &&
    tipoManual &&
    TIPOS_VALIDOS.includes(tipoManual as TipoNotif)
  ) {
    return {
      solicitudId: solicitudManual,
      tipo: tipoManual as TipoNotif,
      origen: "manual",
    };
  }

  if (body.type !== "UPDATE") return null;

  const record = body.record as Record<string, unknown> | undefined;
  const oldRecord = body.old_record as Record<string, unknown> | undefined;
  if (!record) return null;

  const nuevoEstado = String(record.estado ?? "");
  const viejoEstado = String(oldRecord?.estado ?? "");
  if (!nuevoEstado || nuevoEstado === viejoEstado) return null;

  const tipo = tipoDesdeEstado(nuevoEstado);
  if (!tipo) return null;

  const solicitudId = String(record.id ?? "");
  if (!solicitudId) return null;

  return { solicitudId, tipo, origen: "webhook" };
}

function verificarWebhookSecret(req: Request): boolean {
  const esperado = Deno.env.get("WEBHOOK_SECRET");
  if (!esperado) return true;
  const recibido = req.headers.get("x-webhook-secret") ?? "";
  return recibido === esperado;
}

async function obtenerAccessToken(): Promise<{ token: string; projectId: string }> {
  const raw = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (!raw) {
    throw new Error(
      "FCM_SERVICE_ACCOUNT_JSON no configurado. Ver docs/GUIA_FCM_FIREBASE.md sección 8",
    );
  }

  const credentials = JSON.parse(raw);
  const projectId = credentials.project_id as string;
  if (!projectId) throw new Error("JSON sin project_id");

  const auth = new GoogleAuth({
    credentials,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const client = await auth.getClient();
  const tokenResponse = await client.getAccessToken();
  const token = tokenResponse.token;
  if (!token) throw new Error("No se obtuvo access token de Google");

  return { token, projectId };
}

async function enviarLegacy(
  serverKey: string,
  deviceToken: string,
  title: string,
  bodyMsg: string,
  data: Record<string, string>,
): Promise<Response> {
  const fcmRes = await fetch("https://fcm.googleapis.com/fcm/send", {
    method: "POST",
    headers: {
      Authorization: `key=${serverKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      to: deviceToken,
      notification: { title, body: bodyMsg },
      data,
    }),
  });
  const fcmJson = await fcmRes.json();
  return new Response(
    JSON.stringify({ ok: fcmRes.ok, modo: "legacy", fcm: fcmJson }),
    { headers: { ...cors, "Content-Type": "application/json" } },
  );
}

async function enviarV1(
  accessToken: string,
  projectId: string,
  deviceToken: string,
  title: string,
  bodyMsg: string,
  data: Record<string, string>,
): Promise<Response> {
  const url =
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const fcmRes = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token: deviceToken,
        notification: { title, body: bodyMsg },
        data,
      },
    }),
  });

  const fcmJson = await fcmRes.json();
  return new Response(
    JSON.stringify({ ok: fcmRes.ok, modo: "v1", fcm: fcmJson }),
    { headers: { ...cors, "Content-Type": "application/json" } },
  );
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    if (!verificarWebhookSecret(req)) {
      return new Response(JSON.stringify({ error: "Webhook no autorizado" }), {
        status: 401,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const body = await req.json() as Record<string, unknown>;
    const entrada = parseEntrada(body);

    if (!entrada) {
      return new Response(
        JSON.stringify({
          ok: true,
          omitido: true,
          mensaje:
            "Sin notificación: estado no cambió, no es notificable, o payload inválido",
        }),
        { headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    const { solicitudId, tipo, origen } = entrada;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: sol } = await supabase
      .from("solicitudescredito")
      .select(
        "asesorid, nombres, apellidos, monto, montodaprobado, codigocondicion, estado, numeroexpediente, fechadesembolso, motivorechazo",
      )
      .eq("id", solicitudId)
      .single();

    if (!sol) throw new Error("Solicitud no encontrada");

    const { data: asesor } = await supabase
      .from("asesores_fcmtokens")
      .select("fcmtoken")
      .eq("asesorid", sol.asesorid)
      .maybeSingle();

    const deviceToken = asesor?.fcmtoken;
    if (!deviceToken) {
      return new Response(
        JSON.stringify({
          ok: false,
          origen,
          mensaje: "Sin token FCM para el asesor",
          asesorid: sol.asesorid,
        }),
        { headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    const cliente = `${sol.nombres} ${sol.apellidos}`.trim();
    let title = "Solicitud de crédito";
    let bodyMsg = "";

    switch (tipo) {
      case "recibido_comite":
        title = "Recibido en comité";
        bodyMsg =
          `La solicitud de ${cliente} fue recibida en comité de crédito.`;
        break;
      case "aprobado":
        title = "Crédito aprobado";
        bodyMsg = `Aprobado: ${cliente} — S/ ${sol.montodaprobado ?? sol.monto}. ` +
          (sol.fechadesembolso
            ? `Desembolso estimado: ${sol.fechadesembolso}`
            : "");
        break;
      case "condicionado":
        title = "Crédito condicionado";
        bodyMsg =
          `Condicionado: ${cliente} — S/ ${sol.montodaprobado ?? sol.monto}. ` +
          `Caso ${sol.codigocondicion ?? ""}`;
        break;
      case "rechazado":
        title = "Solicitud rechazada";
        bodyMsg =
          `Rechazada: ${cliente}. Motivo: ${sol.motivorechazo ?? "No indicado"}`;
        break;
      case "desembolsado":
        title = "Desembolso realizado";
        bodyMsg = `Desembolsado: ${cliente} — S/ ${sol.monto}`;
        break;
    }

    const dataPayload = {
      solicitud_id: solicitudId,
      tipo,
      expediente: String(sol.numeroexpediente ?? ""),
    };

    const legacyKey = Deno.env.get("FCM_SERVER_KEY");
    if (legacyKey && !Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")) {
      const res = await enviarLegacy(
        legacyKey,
        deviceToken,
        title,
        bodyMsg,
        dataPayload,
      );
      return res;
    }

    const { token, projectId } = await obtenerAccessToken();
    const res = await enviarV1(
      token,
      projectId,
      deviceToken,
      title,
      bodyMsg,
      dataPayload,
    );

    const resBody = await res.clone().json();
    return new Response(
      JSON.stringify({ ...resBody, origen, tipo, solicitud_id: solicitudId }),
      { headers: { ...cors, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } },
    );
  }
});
