-- ============================================================
-- RANKING DE CADASTROS POR PONTO (agregado, por período)
-- SECURITY DEFINER: ignora RLS e devolve só CONTAGEM por ponto (zero dado de
-- paciente exposto) — assim cada colaboradora vê o ranking de TODOS os pontos
-- (a "competição") sem ver cadastro de ninguém. Idempotente.
-- Rodar 1x no Supabase Dashboard -> SQL Editor.
-- ============================================================

-- FIBRO
CREATE OR REPLACE FUNCTION public.get_ranking_fibro(p_de date, p_ate date)
RETURNS TABLE(numero_ponto integer, nome_ponto text, total bigint)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT pr.numero_ponto, pr.nome_ponto, COUNT(pf.id) AS total
  FROM public.profiles pr
  LEFT JOIN public.pacientes_fibro pf
    ON pf.cadastrado_por = pr.id
   AND pf.criado_em >= p_de::timestamp
   AND pf.criado_em <  ((p_ate::date) + 1)::timestamp
  WHERE pr.papel = 'colaborador' AND pr.projeto = 'fibromialgia'
  GROUP BY pr.numero_ponto, pr.nome_ponto
  ORDER BY COUNT(pf.id) DESC, pr.numero_ponto;
$$;
GRANT EXECUTE ON FUNCTION public.get_ranking_fibro(date, date) TO authenticated, anon;

-- ÓCULOS
CREATE OR REPLACE FUNCTION public.get_ranking_oculos(p_de date, p_ate date)
RETURNS TABLE(numero_ponto integer, nome_ponto text, total bigint)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT pr.numero_ponto, pr.nome_ponto, COUNT(po.id) AS total
  FROM public.profiles pr
  LEFT JOIN public.pacientes_oculos po
    ON po.cadastrado_por = pr.id
   AND po.criado_em >= p_de::timestamp
   AND po.criado_em <  ((p_ate::date) + 1)::timestamp
  WHERE pr.papel = 'colaborador' AND pr.projeto = 'oculos'
  GROUP BY pr.numero_ponto, pr.nome_ponto
  ORDER BY COUNT(po.id) DESC, pr.numero_ponto;
$$;
GRANT EXECUTE ON FUNCTION public.get_ranking_oculos(date, date) TO authenticated, anon;
