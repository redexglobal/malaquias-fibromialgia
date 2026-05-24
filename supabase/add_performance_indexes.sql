-- =====================================================================
-- add_performance_indexes.sql
-- Índices de performance para escalar até 50k+ registros sem lentidão.
-- 100% idempotente — pode rodar várias vezes sem erro.
-- Compartilhado entre fibromialgia e oculos.
-- =====================================================================

-- ===== pacientes_fibro (~ tabela quente do projeto fibro) =====
CREATE INDEX IF NOT EXISTS idx_fibro_criado_em        ON public.pacientes_fibro (criado_em DESC);
CREATE INDEX IF NOT EXISTS idx_fibro_cadastrado_por   ON public.pacientes_fibro (cadastrado_por);
CREATE INDEX IF NOT EXISTS idx_fibro_nome             ON public.pacientes_fibro (nome);
CREATE INDEX IF NOT EXISTS idx_fibro_cpf              ON public.pacientes_fibro (cpf);
-- composto para list-by-ponto-recente (caso mais frequente do colaborador)
CREATE INDEX IF NOT EXISTS idx_fibro_cad_criado       ON public.pacientes_fibro (cadastrado_por, criado_em DESC);

-- ===== pacientes_oculos =====
CREATE INDEX IF NOT EXISTS idx_oculos_criado_em       ON public.pacientes_oculos (criado_em DESC);
CREATE INDEX IF NOT EXISTS idx_oculos_cadastrado_por  ON public.pacientes_oculos (cadastrado_por);
CREATE INDEX IF NOT EXISTS idx_oculos_nome            ON public.pacientes_oculos (nome);
CREATE INDEX IF NOT EXISTS idx_oculos_cpf             ON public.pacientes_oculos (cpf);
CREATE INDEX IF NOT EXISTS idx_oculos_cad_criado      ON public.pacientes_oculos (cadastrado_por, criado_em DESC);

-- ===== profiles (lookup constante por papel/projeto/id) =====
CREATE INDEX IF NOT EXISTS idx_profiles_papel         ON public.profiles (papel);
CREATE INDEX IF NOT EXISTS idx_profiles_projeto       ON public.profiles (projeto);
CREATE INDEX IF NOT EXISTS idx_profiles_papel_proj    ON public.profiles (papel, projeto);
CREATE INDEX IF NOT EXISTS idx_profiles_ordem         ON public.profiles (ordem);

-- ===== mensagens_pontos (caixa de entrada por usuário) =====
CREATE INDEX IF NOT EXISTS idx_msg_para_lido          ON public.mensagens_pontos (para, lido);
CREATE INDEX IF NOT EXISTS idx_msg_criado_em          ON public.mensagens_pontos (criado_em DESC);

-- ===== atendimentos_juridicos (módulo jurídico) =====
CREATE INDEX IF NOT EXISTS idx_jur_projeto            ON public.atendimentos_juridicos (projeto);
CREATE INDEX IF NOT EXISTS idx_jur_criado_em          ON public.atendimentos_juridicos (criado_em DESC);
CREATE INDEX IF NOT EXISTS idx_jur_cadastrado_por     ON public.atendimentos_juridicos (cadastrado_por);
CREATE INDEX IF NOT EXISTS idx_jur_paciente_cpf       ON public.atendimentos_juridicos (paciente_cpf);
CREATE INDEX IF NOT EXISTS idx_jur_status_beneficio   ON public.atendimentos_juridicos (status_beneficio);
CREATE INDEX IF NOT EXISTS idx_jur_proxima_data       ON public.atendimentos_juridicos (proxima_data);
-- composto: listagem padrão da tela (filtra por projeto, ordena por data)
CREATE INDEX IF NOT EXISTS idx_jur_proj_criado        ON public.atendimentos_juridicos (projeto, criado_em DESC);

-- ===== retornos_juridicos =====
CREATE INDEX IF NOT EXISTS idx_ret_jur_atendimento_id ON public.retornos_juridicos (atendimento_id);
CREATE INDEX IF NOT EXISTS idx_ret_jur_projeto        ON public.retornos_juridicos (projeto);
CREATE INDEX IF NOT EXISTS idx_ret_jur_data_retorno   ON public.retornos_juridicos (data_retorno);
CREATE INDEX IF NOT EXISTS idx_ret_jur_criado_em      ON public.retornos_juridicos (criado_em DESC);

-- =====================================================================
-- ANALYZE para o planner do PostgreSQL atualizar estatísticas
-- =====================================================================
ANALYZE public.pacientes_fibro;
ANALYZE public.pacientes_oculos;
ANALYZE public.profiles;
ANALYZE public.mensagens_pontos;
ANALYZE public.atendimentos_juridicos;
ANALYZE public.retornos_juridicos;
