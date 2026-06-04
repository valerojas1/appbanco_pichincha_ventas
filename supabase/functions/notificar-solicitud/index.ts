/**
 * Envía notificación FCM (API HTTP v1 — sin clave Legacy).
 * Secret en Supabase: FCM_SERVICE_ACCOUNT_JSON = contenido del JSON de cuenta de servicio
 * (Firebase → Configuración → Cuentas de servicio → Generar nueva clave privada)
 */
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleAuth } from "npm:google-auth-library@9.15.1";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type TipoNotif =
  | "recibido_comite"
  | "aprobado"
  | "rechazado"
  | "desembolsado";

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

/** Fallback Legacy solo si aún tienes FCM_SERVER_KEY (proyectos antiguos). */
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
    const body = await req.json();
    const solicitudId = String(body.solicitud_id ?? "");
    const tipo = body.tipo as TipoNotif;
    if (!solicitudId || !tipo) {
      return new Response(JSON.stringify({ error: "Parámetros inválidos" }), {
        status: 400,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: sol } = await supabase
      .from("solicitudescredito")
      .select(
        "asesorid, nombres, apellidos, monto, estado, numeroexpediente, fechadesembolso, motivorechazo",
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
        JSON.stringify({ ok: false, mensaje: "Sin token FCM para el asesor" }),
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
        bodyMsg = `Aprobado: ${cliente} — S/ ${sol.monto}. ` +
          (sol.fechadesembolso
            ? `Desembolso estimado: ${sol.fechadesembolso}`
            : "");
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
      return await enviarLegacy(
        legacyKey,
        deviceToken,
        title,
        bodyMsg,
        dataPayload,
      );
    }

    const { token, projectId } = await obtenerAccessToken();
    return await enviarV1(
      token,
      projectId,
      deviceToken,
      title,
      bodyMsg,
      dataPayload,
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } },
    );
  }
});
