import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const body = await req.json();
    const dni = String(body.dni ?? "").replace(/\D/g, "");
    const ingresos = Number(body.ingresos ?? 0);
    const monto = Number(body.monto ?? 0);
    const destino = String(body.destino ?? "").toLowerCase();

    if (dni.length !== 8) {
      return new Response(JSON.stringify({ error: "DNI inválido" }), {
        status: 400,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: listaNegra } = await supabase
      .from("listasnegras")
      .select("motivo")
      .eq("documento", dni)
      .eq("activo", true)
      .maybeSingle();

    if (listaNegra) {
      return new Response(
        JSON.stringify({
          resultado: "NO PROCEDE",
          mensaje: `Cliente en lista negra: ${listaNegra.motivo}`,
          ratio_deuda_ingreso: monto / Math.max(ingresos, 1),
          en_lista_negra: true,
        }),
        { headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    const ing = ingresos < 1 ? 1 : ingresos;
    const ratio = monto / ing;

    if (monto < 500 || monto > 50000) {
      return new Response(
        JSON.stringify({
          resultado: "NO PROCEDE",
          mensaje: "Monto fuera del rango permitido (S/ 500 – S/ 50,000).",
          ratio_deuda_ingreso: ratio,
        }),
        { headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    if (ratio > 4 || ingresos < 800) {
      return new Response(
        JSON.stringify({
          resultado: "NO PROCEDE",
          mensaje: "Capacidad de pago insuficiente.",
          ratio_deuda_ingreso: ratio,
        }),
        { headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    if (ratio > 2.5 || (destino.includes("invers") && ratio > 2)) {
      return new Response(
        JSON.stringify({
          resultado: "REVISAR",
          mensaje: "Requiere revisión adicional por relación monto/ingreso.",
          ratio_deuda_ingreso: ratio,
        }),
        { headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    if (ratio > 1.8) {
      return new Response(
        JSON.stringify({
          resultado: "REVISAR",
          mensaje: "Evaluación preliminar favorable con observaciones.",
          ratio_deuda_ingreso: ratio,
        }),
        { headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({
        resultado: "APTO",
        mensaje: "Pre-evaluación favorable. Puede continuar con la solicitud.",
        ratio_deuda_ingreso: ratio,
      }),
      { headers: { ...cors, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } },
    );
  }
});
