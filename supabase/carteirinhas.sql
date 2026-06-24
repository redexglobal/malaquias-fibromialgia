-- ============================================================
-- CARTEIRINHAS AGF — tabela + verificação pública + campos RG
-- Rodar 1x no SQL Editor do Supabase. Idempotente (pode rodar de novo sem erro).
-- ============================================================

-- 1) Campos novos no cadastro do paciente (RG + órgão expedidor)
ALTER TABLE pacientes_fibro ADD COLUMN IF NOT EXISTS rg text;
ALTER TABLE pacientes_fibro ADD COLUMN IF NOT EXISTS orgao_expedidor text;

-- 2) Tabela de carteirinhas — o "id" (uuid aleatório) é o CÓDIGO PÚBLICO do QR
CREATE TABLE IF NOT EXISTS carteirinhas (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  paciente_id  uuid,
  tipo         text NOT NULL DEFAULT 'fibromialgia',  -- 'fibromialgia' | 'cronicas'
  numero       text,
  nome         text,
  cpf          text,
  emitida_em   date DEFAULT now(),
  validade     date,
  ativo        boolean DEFAULT true,
  emitida_por  uuid,
  criado_em    timestamptz DEFAULT now()
);

-- 3) RLS: quem está logado (admin/colaborador) cria e vê; o público NÃO lê a tabela direto
ALTER TABLE carteirinhas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS carteirinhas_select ON carteirinhas;
CREATE POLICY carteirinhas_select ON carteirinhas FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS carteirinhas_insert ON carteirinhas;
CREATE POLICY carteirinhas_insert ON carteirinhas FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS carteirinhas_update ON carteirinhas;
CREATE POLICY carteirinhas_update ON carteirinhas FOR UPDATE TO authenticated USING (true);

-- 4) Função PÚBLICA de verificação (SECURITY DEFINER): devolve SÓ o mínimo seguro.
--    Datas de atendimento = data_consulta das linhas do mesmo CPF.
CREATE OR REPLACE FUNCTION verificar_carteirinha(p_token uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  c           carteirinhas%ROWTYPE;
  v_cpf       text;
  v_datas     date[];
BEGIN
  SELECT * INTO c FROM carteirinhas WHERE id = p_token;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('encontrada', false);
  END IF;

  v_cpf := regexp_replace(coalesce(c.cpf,''), '\D', '', 'g');

  IF length(v_cpf) = 11 THEN
    SELECT array_agg(d ORDER BY d)
      INTO v_datas
      FROM (
        SELECT DISTINCT data_consulta AS d
          FROM pacientes_fibro
         WHERE regexp_replace(coalesce(cpf,''), '\D','','g') = v_cpf
           AND data_consulta IS NOT NULL
      ) s;
  END IF;

  RETURN jsonb_build_object(
    'encontrada',   true,
    'nome',         c.nome,
    'tipo',         c.tipo,
    'numero',       c.numero,
    'emitida_em',   c.emitida_em,
    'validade',     c.validade,
    'ativo',        c.ativo,
    'atendimentos', coalesce(to_jsonb(v_datas), '[]'::jsonb)
  );
END;
$$;

-- 5) Liberar o PÚBLICO (anon) a chamar SÓ essa função (nada além disso)
GRANT EXECUTE ON FUNCTION verificar_carteirinha(uuid) TO anon;
