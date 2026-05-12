-- =====================================================================
-- restore_pontos_views.sql
-- Views consolidadas + RPC por data + RLS para aba "Gestão de Pontos"
-- Projeto Dr. Malaquias — Fibromialgia + Óculos
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0.0) Função SECURITY DEFINER pra checar papel sem disparar RLS recursivo
--      (idempotente — recria sempre)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._get_papel(uid uuid)
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT papel FROM public.profiles WHERE id = uid LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public._get_papel(uuid) TO authenticated;

-- ---------------------------------------------------------------------
-- 0.1) Garante que colaboradores estão `ativo=true` (seed não preencheu)
-- ---------------------------------------------------------------------
UPDATE public.profiles
SET ativo = true
WHERE papel = 'colaborador'
  AND (ativo IS NULL OR ativo = false);

-- ---------------------------------------------------------------------
-- 1) VIEW: v_pontos_fibro — KPIs agregados (sempre, sem filtro de data)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_pontos_fibro AS
SELECT
  p.id,
  p.nome,
  p.nome_ponto,
  p.numero_ponto,
  p.tipo_ponto,
  p.status,
  p.online_at,
  (p.online_at IS NOT NULL AND p.online_at > NOW() - INTERVAL '5 minutes') AS online,
  COALESCE(COUNT(pf.id), 0)                                                            AS total_cadastros,
  COALESCE(COUNT(CASE WHEN pf.criado_em::date = CURRENT_DATE THEN 1 END), 0)           AS cadastros_hoje,
  COALESCE(COUNT(CASE WHEN pf.criado_em > NOW() - INTERVAL '7 days' THEN 1 END), 0)    AS cadastros_semana,
  COALESCE(COUNT(CASE WHEN pf.nivel_dor >= 7 THEN 1 END), 0)                           AS cadastros_dor_alta,
  ROUND(AVG(pf.nivel_dor)::numeric, 1)                                                  AS media_dor,
  MAX(pf.criado_em)                                                                     AS ultimo_cadastro
FROM public.profiles p
LEFT JOIN public.pacientes_fibro pf ON pf.cadastrado_por = p.id
WHERE p.papel = 'colaborador'
  AND p.projeto = 'fibromialgia'
  AND p.ativo = true
GROUP BY p.id, p.nome, p.nome_ponto, p.numero_ponto, p.tipo_ponto, p.status, p.online_at
ORDER BY
  CASE p.tipo_ponto
    WHEN 'fixo' THEN 1
    WHEN 'móvel' THEN 2
    WHEN 'movel' THEN 2
    ELSE 3
  END,
  p.numero_ponto;

-- ---------------------------------------------------------------------
-- 2) VIEW: v_pontos_oculos — equivalente para projeto óculos
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_pontos_oculos AS
SELECT
  p.id,
  p.nome,
  p.nome_ponto,
  p.numero_ponto,
  p.tipo_ponto,
  p.status,
  p.online_at,
  (p.online_at IS NOT NULL AND p.online_at > NOW() - INTERVAL '5 minutes') AS online,
  COALESCE(COUNT(po.id), 0)                                                            AS total_cadastros,
  COALESCE(COUNT(CASE WHEN po.criado_em::date = CURRENT_DATE THEN 1 END), 0)           AS cadastros_hoje,
  COALESCE(COUNT(CASE WHEN po.criado_em > NOW() - INTERVAL '7 days' THEN 1 END), 0)    AS cadastros_semana,
  ROUND(AVG(po.avaliacao)::numeric, 1)                                                  AS media_avaliacao,
  COALESCE(SUM(po.valor_pedido), 0)                                                    AS valor_total,
  MAX(po.criado_em)                                                                     AS ultimo_cadastro
FROM public.profiles p
LEFT JOIN public.pacientes_oculos po ON po.cadastrado_por = p.id
WHERE p.papel = 'colaborador'
  AND p.projeto = 'oculos'
  AND p.ativo = true
GROUP BY p.id, p.nome, p.nome_ponto, p.numero_ponto, p.tipo_ponto, p.status, p.online_at
ORDER BY
  CASE p.tipo_ponto
    WHEN 'fixo' THEN 1
    WHEN 'móvel' THEN 2
    WHEN 'movel' THEN 2
    ELSE 3
  END,
  p.numero_ponto;

GRANT SELECT ON public.v_pontos_fibro  TO authenticated;
GRANT SELECT ON public.v_pontos_oculos TO authenticated;

-- ---------------------------------------------------------------------
-- 3) RPC: get_pontos_por_data_fibro — KPIs em data específica
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_pontos_por_data_fibro(p_data date)
RETURNS TABLE(
  id uuid,
  nome text,
  nome_ponto text,
  numero_ponto int,
  tipo_ponto text,
  status text,
  online_at timestamptz,
  online boolean,
  cadastros_no_dia bigint,
  media_dor numeric,
  cadastros_dor_alta bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p.id,
    p.nome,
    p.nome_ponto,
    p.numero_ponto,
    p.tipo_ponto,
    p.status,
    p.online_at,
    (p.online_at IS NOT NULL AND p.online_at > NOW() - INTERVAL '5 minutes') AS online,
    COALESCE(COUNT(pf.id), 0) AS cadastros_no_dia,
    ROUND(AVG(pf.nivel_dor)::numeric, 1) AS media_dor,
    COALESCE(COUNT(CASE WHEN pf.nivel_dor >= 7 THEN 1 END), 0) AS cadastros_dor_alta
  FROM public.profiles p
  LEFT JOIN public.pacientes_fibro pf
    ON pf.cadastrado_por = p.id
    AND pf.criado_em::date = p_data
  WHERE p.papel = 'colaborador'
    AND p.projeto = 'fibromialgia'
    AND p.ativo = true
  GROUP BY p.id, p.nome, p.nome_ponto, p.numero_ponto, p.tipo_ponto, p.status, p.online_at
  ORDER BY
    CASE p.tipo_ponto WHEN 'fixo' THEN 1 WHEN 'móvel' THEN 2 WHEN 'movel' THEN 2 ELSE 3 END,
    p.numero_ponto;
$$;

GRANT EXECUTE ON FUNCTION public.get_pontos_por_data_fibro(date) TO authenticated;

-- ---------------------------------------------------------------------
-- 4) RPC: get_pontos_por_data_oculos
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_pontos_por_data_oculos(p_data date)
RETURNS TABLE(
  id uuid,
  nome text,
  nome_ponto text,
  numero_ponto int,
  tipo_ponto text,
  status text,
  online_at timestamptz,
  online boolean,
  cadastros_no_dia bigint,
  media_avaliacao numeric,
  valor_total numeric
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p.id,
    p.nome,
    p.nome_ponto,
    p.numero_ponto,
    p.tipo_ponto,
    p.status,
    p.online_at,
    (p.online_at IS NOT NULL AND p.online_at > NOW() - INTERVAL '5 minutes') AS online,
    COALESCE(COUNT(po.id), 0) AS cadastros_no_dia,
    ROUND(AVG(po.avaliacao)::numeric, 1) AS media_avaliacao,
    COALESCE(SUM(po.valor_pedido), 0) AS valor_total
  FROM public.profiles p
  LEFT JOIN public.pacientes_oculos po
    ON po.cadastrado_por = p.id
    AND po.criado_em::date = p_data
  WHERE p.papel = 'colaborador'
    AND p.projeto = 'oculos'
    AND p.ativo = true
  GROUP BY p.id, p.nome, p.nome_ponto, p.numero_ponto, p.tipo_ponto, p.status, p.online_at
  ORDER BY
    CASE p.tipo_ponto WHEN 'fixo' THEN 1 WHEN 'móvel' THEN 2 WHEN 'movel' THEN 2 ELSE 3 END,
    p.numero_ponto;
$$;

GRANT EXECUTE ON FUNCTION public.get_pontos_por_data_oculos(date) TO authenticated;

-- ---------------------------------------------------------------------
-- 5) RLS — pacientes_fibro: admin lê tudo, colaborador lê próprios
-- ---------------------------------------------------------------------
ALTER TABLE public.pacientes_fibro ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pacientes_fibro_select"      ON public.pacientes_fibro;
DROP POLICY IF EXISTS "pacientes_fibro_insert"      ON public.pacientes_fibro;
DROP POLICY IF EXISTS "pacientes_fibro_update_own"  ON public.pacientes_fibro;
DROP POLICY IF EXISTS "pacientes_fibro_update_admin" ON public.pacientes_fibro;

CREATE POLICY "pacientes_fibro_select" ON public.pacientes_fibro
FOR SELECT TO authenticated
USING (
  public._get_papel(auth.uid()) = 'admin'
  OR cadastrado_por = auth.uid()
);

CREATE POLICY "pacientes_fibro_insert" ON public.pacientes_fibro
FOR INSERT TO authenticated
WITH CHECK (cadastrado_por = auth.uid() OR public._get_papel(auth.uid()) = 'admin');

CREATE POLICY "pacientes_fibro_update_own" ON public.pacientes_fibro
FOR UPDATE TO authenticated
USING (cadastrado_por = auth.uid())
WITH CHECK (cadastrado_por = auth.uid());

CREATE POLICY "pacientes_fibro_update_admin" ON public.pacientes_fibro
FOR UPDATE TO authenticated
USING (public._get_papel(auth.uid()) = 'admin')
WITH CHECK (public._get_papel(auth.uid()) = 'admin');

-- ---------------------------------------------------------------------
-- 6) RLS — pacientes_oculos: idem
-- ---------------------------------------------------------------------
ALTER TABLE public.pacientes_oculos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pacientes_oculos_select"       ON public.pacientes_oculos;
DROP POLICY IF EXISTS "pacientes_oculos_insert"       ON public.pacientes_oculos;
DROP POLICY IF EXISTS "pacientes_oculos_update_own"   ON public.pacientes_oculos;
DROP POLICY IF EXISTS "pacientes_oculos_update_admin" ON public.pacientes_oculos;

CREATE POLICY "pacientes_oculos_select" ON public.pacientes_oculos
FOR SELECT TO authenticated
USING (
  public._get_papel(auth.uid()) = 'admin'
  OR cadastrado_por = auth.uid()
);

CREATE POLICY "pacientes_oculos_insert" ON public.pacientes_oculos
FOR INSERT TO authenticated
WITH CHECK (cadastrado_por = auth.uid() OR public._get_papel(auth.uid()) = 'admin');

CREATE POLICY "pacientes_oculos_update_own" ON public.pacientes_oculos
FOR UPDATE TO authenticated
USING (cadastrado_por = auth.uid())
WITH CHECK (cadastrado_por = auth.uid());

CREATE POLICY "pacientes_oculos_update_admin" ON public.pacientes_oculos
FOR UPDATE TO authenticated
USING (public._get_papel(auth.uid()) = 'admin')
WITH CHECK (public._get_papel(auth.uid()) = 'admin');

-- ---------------------------------------------------------------------
-- 7) Validação final
-- ---------------------------------------------------------------------
SELECT 'v_pontos_fibro'  AS view_name, COUNT(*) AS total FROM public.v_pontos_fibro
UNION ALL
SELECT 'v_pontos_oculos' AS view_name, COUNT(*) AS total FROM public.v_pontos_oculos
UNION ALL
SELECT 'rpc_fibro_hoje',  COUNT(*) FROM public.get_pontos_por_data_fibro(CURRENT_DATE)
UNION ALL
SELECT 'rpc_oculos_hoje', COUNT(*) FROM public.get_pontos_por_data_oculos(CURRENT_DATE);
