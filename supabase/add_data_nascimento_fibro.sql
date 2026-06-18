-- ============================================================
-- Adiciona DATA DE NASCIMENTO ao cadastro de fibromialgia (pedido do coordenador Antônio).
-- Idempotente — rodar 1x no Supabase Dashboard -> SQL Editor.
-- (Sem esta coluna, o sistema salva o resto e ignora o nascimento por graceful degradation.)
-- ============================================================
ALTER TABLE public.pacientes_fibro ADD COLUMN IF NOT EXISTS data_nascimento date;
