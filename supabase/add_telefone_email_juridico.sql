-- ============================================================
-- Adiciona Telefone e E-mail ao cadastro jurídico (Etapa 1 — Dados do Paciente).
-- Idempotente — rodar 1x no Supabase Dashboard -> SQL Editor.
-- (O sistema tem fallback: salva sem esses campos enquanto a coluna não existir,
--  então nada quebra antes de rodar este SQL — mas telefone/email só gravam depois.)
-- ============================================================
ALTER TABLE public.atendimentos_juridicos ADD COLUMN IF NOT EXISTS paciente_telefone text;
ALTER TABLE public.atendimentos_juridicos ADD COLUMN IF NOT EXISTS paciente_email text;
