-- =====================================================================
-- add_performance_indexes_v2.sql
-- Indices adicionais para v2 da otimizacao — escala 50k+ registros.
-- 100% idempotente: pode rodar varias vezes sem erro.
-- Roda DEPOIS do add_performance_indexes.sql (que ja criou os basicos).
-- Compartilhado entre fibromialgia e oculos.
-- =====================================================================

-- ===== pacientes_fibro =====
-- Aba "Retorno do Dia" filtra proximo_retorno = <data>
CREATE INDEX IF NOT EXISTS idx_fibro_proximo_retorno     ON public.pacientes_fibro (proximo_retorno) WHERE proximo_retorno IS NOT NULL;

-- Aba Calendario filtra por proximo_retorno em range mensal
CREATE INDEX IF NOT EXISTS idx_fibro_data_consulta       ON public.pacientes_fibro (data_consulta) WHERE data_consulta IS NOT NULL;

-- Busca por nome (icontains): trigram pra LIKE/ILIKE rapido (50x mais rapido em buscas substring)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_fibro_nome_trgm           ON public.pacientes_fibro USING gin (nome gin_trgm_ops);

-- Para agrupamento por cpf (aba Pacientes — _renderPacientesUnicos)
CREATE INDEX IF NOT EXISTS idx_fibro_cpf_norm            ON public.pacientes_fibro ((regexp_replace(cpf, '\D', '', 'g'))) WHERE cpf IS NOT NULL;

-- Para realtime/dashboard "hoje" — filter por data
CREATE INDEX IF NOT EXISTS idx_fibro_criado_em_date      ON public.pacientes_fibro (((criado_em AT TIME ZONE 'America/Sao_Paulo')::date));

-- nivel_dor para Analise de Melhora e KPI medio
CREATE INDEX IF NOT EXISTS idx_fibro_nivel_dor           ON public.pacientes_fibro (nivel_dor) WHERE nivel_dor IS NOT NULL;

-- nivel_melhora para Analise de Melhora
CREATE INDEX IF NOT EXISTS idx_fibro_nivel_melhora       ON public.pacientes_fibro (nivel_melhora) WHERE nivel_melhora IS NOT NULL;

-- ===== pacientes_oculos (mesma estrategia) =====
CREATE INDEX IF NOT EXISTS idx_oculos_data_entrega       ON public.pacientes_oculos (data_entrega) WHERE data_entrega IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_oculos_status_pedido      ON public.pacientes_oculos (status_pedido);
CREATE INDEX IF NOT EXISTS idx_oculos_nome_trgm          ON public.pacientes_oculos USING gin (nome gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_oculos_cpf_norm           ON public.pacientes_oculos ((regexp_replace(cpf, '\D', '', 'g'))) WHERE cpf IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_oculos_criado_em_date     ON public.pacientes_oculos (((criado_em AT TIME ZONE 'America/Sao_Paulo')::date));
CREATE INDEX IF NOT EXISTS idx_oculos_nivel_melhora      ON public.pacientes_oculos (nivel_melhora) WHERE nivel_melhora IS NOT NULL;

-- ===== profiles =====
-- Busca de profile por email (usado em validacao auth) — ja indexado pelo Supabase, mas garantia
CREATE INDEX IF NOT EXISTS idx_profiles_email_lower      ON public.profiles ((lower(email))) WHERE email IS NOT NULL;
-- Lookups por numero_ponto (badge P01-P25 do admin)
CREATE INDEX IF NOT EXISTS idx_profiles_numero_ponto     ON public.profiles (numero_ponto) WHERE numero_ponto IS NOT NULL;

-- ===== atendimentos_juridicos (lazy mas critico no admin) =====
-- Schema real: advogado_nome / advogado_oab / advogado_contato (NAO existe 'advogado')
CREATE INDEX IF NOT EXISTS idx_jur_status_proc           ON public.atendimentos_juridicos (status_processo);
CREATE INDEX IF NOT EXISTS idx_jur_tipo_beneficio        ON public.atendimentos_juridicos (tipo_beneficio);
CREATE INDEX IF NOT EXISTS idx_jur_advogado_nome         ON public.atendimentos_juridicos (advogado_nome) WHERE advogado_nome IS NOT NULL;

-- =====================================================================
-- ANALYZE para o planner do PostgreSQL atualizar estatisticas
-- =====================================================================
ANALYZE public.pacientes_fibro;
ANALYZE public.pacientes_oculos;
ANALYZE public.profiles;
ANALYZE public.atendimentos_juridicos;
ANALYZE public.retornos_juridicos;
ANALYZE public.mensagens_pontos;

-- =====================================================================
-- CONFIRMACAO: lista todos os indices criados nessa migration
-- =====================================================================
SELECT schemaname, tablename, indexname FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;
