import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type CalificacionSbs =
  | "NORMAL"
  | "CPP"
  | "DEFICIENTE"
  | "DUDOSO"
  | "PERDIDA";

interface ResultadoBuro {
  documento: string;
  calificacion: CalificacionSbs;
  enListaNegra: boolean;
  entidades: number;
  deudaTotal: number;
  diasMora: number;
  fuente: "simulado" | "cache";
  consultadoEn: string;
}

const ASESOR_DEMO = "dddddddd-0001-0001-0001-000000000001";
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function resolverAsesorId(
  bodyAsesor: unknown,
  userId: string | null,
): string {
  for (const candidato of [String(bodyAsesor ?? ""), userId ?? ""]) {
    if (UUID_RE.test(candidato)) return candidato;
  }
  return ASESOR_DEMO;
}

function buildRegistroInsert(
  base: Record<string, unknown>,
  listaNegraMotivo: string | null,
) {
  return {
    ...base,
    firma_consentimiento: String(base.firma_consentimiento ?? "simulado"),
    respuesta_json: {
      lista_negra_motivo: listaNegraMotivo,
      fuente: "simulado",
    },
  };
}
function clasificacionDb(calificacion: CalificacionSbs): string {
  const map: Record<CalificacionSbs, string> = {
    NORMAL: "Normal",
    CPP: "CPP",
    DEFICIENTE: "Deficiente",
    DUDOSO: "Dudoso",
    PERDIDA: "Perdida",
  };
  return map[calificacion];
}

function entidadesConDeudaDesdeConteo(
  entidades: number,
  deudaTotal: number,
): { entidad: string; deuda: number }[] {
  if (entidades <= 0 || deudaTotal <= 0) return [];
  const base = Math.floor(deudaTotal / entidades);
  const resto = deudaTotal - base * entidades;
  return Array.from({ length: entidades }, (_, i) => ({
    entidad: `Entidad Financiera ${String.fromCharCode(65 + i)}`,
    deuda: base + (i === 0 ? resto : 0),
  }));
}

function calcularCalificacionSbs(documento: string): Omit<
  ResultadoBuro,
  "documento" | "fuente" | "consultadoEn"
> {
  const ultimos2 = documento.slice(-2);
  const ultimo = documento.slice(-1);
  const penultimo = Number(documento.slice(-2, -1));

  if (documento === "43337037") {
    return {
      calificacion: "PERDIDA",
      enListaNegra: true,
      entidades: 4,
      deudaTotal: 40000,
      diasMora: 210,
    };
  }

  if (ultimos2 === "55") {
    return {
      calificacion: "DEFICIENTE",
      enListaNegra: false,
      entidades: 2,
      deudaTotal: 16000,
      diasMora: 45,
    };
  }

  if (ultimos2 === "52" || ultimos2 === "22") {
    return {
      calificacion: "CPP",
      enListaNegra: false,
      entidades: 2,
      deudaTotal: 18000,
      diasMora: 15,
    };
  }

  if (ultimos2 === "84" || ultimos2 === "34") {
    return {
      calificacion: "DUDOSO",
      enListaNegra: false,
      entidades: 3,
      deudaTotal: 25000,
      diasMora: 95,
    };
  }

  if (ultimo === "8") {
    return {
      calificacion: "CPP",
      enListaNegra: false,
      entidades: 1,
      deudaTotal: 9000,
      diasMora: 20,
    };
  }

  const entidades = Number.isFinite(penultimo) ? penultimo % 3 : 0;
  return {
    calificacion: "NORMAL",
    enListaNegra: false,
    entidades,
    deudaTotal: entidades * 4500,
    diasMora: 0,
  };
}

function resultadoDesdeFila(
  documento: string,
  fila: Record<string, unknown>,
): ResultadoBuro {
  const entidadesRaw = fila.entidades_con_deuda;
  const entidades = Array.isArray(entidadesRaw) ? entidadesRaw.length : 0;
  const calificacionDbVal = String(fila.clasificacion_sbs ?? "Normal");
  const calificacion = calificacionDbVal.toUpperCase() as CalificacionSbs;

  return {
    documento,
    calificacion,
    enListaNegra: fila.enlistanegra === true,
    entidades,
    deudaTotal: Number(fila.deuda_total ?? 0),
    diasMora: Number(fila.dias_mora_historica ?? 0),
    fuente: "cache",
    consultadoEn: String(fila.createdat ?? new Date().toISOString()),
  };
}

function respuestaExtendida(
  resultado: ResultadoBuro,
  extra: Record<string, unknown> = {},
) {
  const entidadesDetalle = entidadesConDeudaDesdeConteo(
    resultado.entidades,
    resultado.deudaTotal,
  );
  const mayorDeuda = entidadesDetalle.length
    ? Math.max(...entidadesDetalle.map((e) => e.deuda))
    : 0;

  return {
    ...resultado,
    clasificacion_sbs: clasificacionDb(resultado.calificacion),
    entidades_con_deuda: entidadesDetalle,
    deuda_total: resultado.deudaTotal,
    mayor_deuda: mayorDeuda,
    dias_mora_historica: resultado.diasMora,
    enlistanegra: resultado.enListaNegra,
    ...extra,
  };
}

async function usuarioDesdeJwt(req: Request): Promise<string | null> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return null;

  const supabaseAuth = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    { global: { headers: { Authorization: authHeader } } },
  );

  const token = authHeader.replace("Bearer ", "");
  const { data: { user } } = await supabaseAuth.auth.getUser(token);
  return user?.id ?? null;
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

    if (body.solo_verificar_reciente === true) {
      const { data: reciente } = await supabase
        .from("consultasburo")
        .select(
          "id, documento, nombres, clasificacion_sbs, deuda_total, enlistanegra, entidades_con_deuda, dias_mora_historica, createdat",
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

    const { data: reciente } = await supabase
      .from("consultasburo")
      .select("*")
      .eq("documento", documento)
      .gte("createdat", hace30.toISOString())
      .order("createdat", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (reciente && !body.reutilizar_consulta_id && !body.forzar_nueva) {
      const resultado = resultadoDesdeFila(documento, reciente);
      const payload = respuestaExtendida(resultado, {
        consulta_id: reciente.id,
        nombres: reciente.nombres,
        reutilizada: true,
        mensaje_reutilizacion:
          "Resultado reutilizado de consulta previa (últimos 30 días).",
        lista_negra_motivo: listaNegra?.motivo ?? null,
      });

      return new Response(JSON.stringify(payload), {
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const usuarioJwt = await usuarioDesdeJwt(req);
    const asesorid = resolverAsesorId(body.asesorid, usuarioJwt);
    const firma = body.firma_consentimiento ?? "simulado";

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
        const enListaNegra = origen.enlistanegra === true || !!listaNegra;
        const payload = buildRegistroInsert({
          documento,
          nombres: body.nombres ?? origen.nombres,
          asesorid,
          clasificacion_sbs: origen.clasificacion_sbs,
          entidades_con_deuda: origen.entidades_con_deuda,
          deuda_total: origen.deuda_total,
          mayor_deuda: origen.mayor_deuda,
          dias_mora_historica: origen.dias_mora_historica,
          enlistanegra: enListaNegra,
          firma_consentimiento: firma,
          reutilizada: true,
          consulta_origen_id: origen.id,
        }, listaNegra?.motivo ?? null);

        const { data: insertada, error } = await supabase
          .from("consultasburo")
          .insert(payload)
          .select()
          .single();

        if (error) throw error;

        const resultado = resultadoDesdeFila(documento, insertada);
        return new Response(
          JSON.stringify(
            respuestaExtendida(resultado, {
              consulta_id: insertada.id,
              nombres: insertada.nombres,
              reutilizada: true,
              mensaje_reutilizacion:
                "Resultado reutilizado de consulta previa (últimos 30 días).",
              lista_negra_motivo: listaNegra?.motivo ?? null,
            }),
          ),
          { headers: { ...cors, "Content-Type": "application/json" } },
        );
      }
    }

    const calculado = calcularCalificacionSbs(documento);
    const enListaNegra = calculado.enListaNegra || !!listaNegra;
    const entidadesDetalle = entidadesConDeudaDesdeConteo(
      calculado.entidades,
      calculado.deudaTotal,
    );
    const mayorDeuda = entidadesDetalle.length
      ? Math.max(...entidadesDetalle.map((e) => e.deuda))
      : 0;
    const consultadoEn = new Date().toISOString();

    const payload = buildRegistroInsert({
      documento,
      nombres: body.nombres ?? null,
      asesorid,
      clasificacion_sbs: clasificacionDb(calculado.calificacion),
      entidades_con_deuda: entidadesDetalle,
      deuda_total: calculado.deudaTotal,
      mayor_deuda: mayorDeuda,
      dias_mora_historica: calculado.diasMora,
      enlistanegra: enListaNegra,
      firma_consentimiento: firma,
      reutilizada: false,
    }, listaNegra?.motivo ?? null);

    const { data: insertada, error } = await supabase
      .from("consultasburo")
      .insert(payload)
      .select()
      .single();

    if (error) throw error;

    const resultado: ResultadoBuro = {
      documento,
      calificacion: calculado.calificacion,
      enListaNegra,
      entidades: calculado.entidades,
      deudaTotal: calculado.deudaTotal,
      diasMora: calculado.diasMora,
      fuente: "simulado",
      consultadoEn: insertada.createdat ?? consultadoEn,
    };

    return new Response(
      JSON.stringify(
        respuestaExtendida(resultado, {
          consulta_id: insertada.id,
          nombres: insertada.nombres,
          reutilizada: false,
          lista_negra_motivo: listaNegra?.motivo ?? null,
        }),
      ),
      { headers: { ...cors, "Content-Type": "application/json" } },
    );
  } catch (e) {
    const msg = e instanceof Error
      ? e.message
      : typeof e === "object" && e !== null
      ? JSON.stringify(e)
      : String(e);
    return new Response(
      JSON.stringify({ error: msg }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } },
    );
  }
});
