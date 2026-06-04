import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function demoBuro(documento: string) {
  const seed = documento.split("").reduce((a, c) => a + c.charCodeAt(0), 0);
  const sbsOptions = ["Normal", "CPP", "Deficiente"];
  const sbs = sbsOptions[seed % sbsOptions.length];
  const entidades = [
    { entidad: "Entidad Financiera A", deuda: (seed % 7) * 1200 },
    { entidad: "Entidad Financiera B", deuda: (seed % 5) * 800 },
  ].filter((e) => e.deuda > 0);
  const deudaTotal = entidades.reduce((s, e) => s + e.deuda, 0);
  const mayorDeuda = entidades.length
    ? Math.max(...entidades.map((e) => e.deuda))
    : 0;
  const diasMora = seed % 90;
  return { sbs, entidades, deudaTotal, mayorDeuda, diasMora };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const body = await req.json();
    const documento = String(body.documento ?? "").replace(/\D/g, "");
    if (documento.length !== 8) {
      return new Response(JSON.stringify({ error: "DNI inválido" }), {
        status: 400,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const hace30 = new Date();
    hace30.setDate(hace30.getDate() - 30);

    const { data: listaNegra } = await supabase
      .from("listasnegras")
      .select("motivo")
      .eq("documento", documento)
      .eq("activo", true)
      .maybeSingle();

    const enListaNegra = !!listaNegra;

    if (body.solo_verificar_reciente === true) {
      const { data: reciente } = await supabase
        .from("consultasburo")
        .select(
          "id, documento, nombres, clasificacion_sbs, deuda_total, enlistanegra, createdat",
        )
        .eq("documento", documento)
        .gte("createdat", hace30.toISOString())
        .order("createdat", { ascending: false })
        .limit(1)
        .maybeSingle();

      return new Response(
        JSON.stringify({
          tiene_reciente: !!reciente,
          consulta_reciente: reciente ?? null,
        }),
        { headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    const asesorid = String(body.asesorid ?? "");
    const firma = body.firma_consentimiento;
    if (!asesorid || !firma) {
      return new Response(
        JSON.stringify({ error: "asesorid y firma_consentimiento requeridos" }),
        { status: 400, headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    const reutilizarId = body.reutilizar_consulta_id as string | undefined;
    if (reutilizarId) {
      const { data: origen } = await supabase
        .from("consultasburo")
        .select("*")
        .eq("id", reutilizarId)
        .eq("documento", documento)
        .gte("createdat", hace30.toISOString())
        .maybeSingle();

      if (origen) {
        const payload = {
          documento,
          nombres: body.nombres ?? origen.nombres,
          asesorid,
          clasificacion_sbs: origen.clasificacion_sbs,
          entidades_con_deuda: origen.entidades_con_deuda,
          deuda_total: origen.deuda_total,
          mayor_deuda: origen.mayor_deuda,
          dias_mora_historica: origen.dias_mora_historica,
          enlistanegra: enListaNegra,
          lista_negra_motivo: listaNegra?.motivo ?? null,
          firma_consentimiento: firma,
          reutilizada: true,
          consulta_origen_id: origen.id,
        };

        const { data: insertada, error } = await supabase
          .from("consultasburo")
          .insert(payload)
          .select()
          .single();

        if (error) throw error;

        return new Response(
          JSON.stringify({
            consulta_id: insertada.id,
            documento,
            nombres: insertada.nombres,
            clasificacion_sbs: insertada.clasificacion_sbs,
            entidades_con_deuda: insertada.entidades_con_deuda,
            deuda_total: insertada.deuda_total,
            mayor_deuda: insertada.mayor_deuda,
            dias_mora_historica: insertada.dias_mora_historica,
            enlistanegra: insertada.enlistanegra,
            lista_negra_motivo: insertada.lista_negra_motivo,
            reutilizada: true,
            mensaje_reutilizacion:
              "Resultado reutilizado de consulta previa (últimos 30 días).",
            createdat: insertada.createdat,
          }),
          { headers: { ...cors, "Content-Type": "application/json" } },
        );
      }
    }

    const demo = demoBuro(documento);
    const payload = {
      documento,
      nombres: body.nombres ?? null,
      asesorid,
      clasificacion_sbs: demo.sbs,
      entidades_con_deuda: demo.entidades,
      deuda_total: demo.deudaTotal,
      mayor_deuda: demo.mayorDeuda,
      dias_mora_historica: demo.diasMora,
      enlistanegra: enListaNegra,
      lista_negra_motivo: listaNegra?.motivo ?? null,
      firma_consentimiento: firma,
      reutilizada: false,
    };

    const { data: insertada, error } = await supabase
      .from("consultasburo")
      .insert(payload)
      .select()
      .single();

    if (error) throw error;

    return new Response(
      JSON.stringify({
        consulta_id: insertada.id,
        documento,
        nombres: insertada.nombres,
        clasificacion_sbs: insertada.clasificacion_sbs,
        entidades_con_deuda: insertada.entidades_con_deuda,
        deuda_total: insertada.deuda_total,
        mayor_deuda: insertada.mayor_deuda,
        dias_mora_historica: insertada.dias_mora_historica,
        enlistanegra: insertada.enlistanegra,
        lista_negra_motivo: insertada.lista_negra_motivo,
        reutilizada: false,
        createdat: insertada.createdat,
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
