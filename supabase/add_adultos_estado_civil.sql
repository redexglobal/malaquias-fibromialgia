-- Adiciona campos "adultos no lar" e "estado civil" no Stage 1 de identificação
-- Rodar uma vez no SQL Editor do Supabase. Idempotente (IF NOT EXISTS).

ALTER TABLE pacientes_fibro
  ADD COLUMN IF NOT EXISTS adultos_no_lar integer,
  ADD COLUMN IF NOT EXISTS estado_civil   text;

ALTER TABLE pacientes_oculos
  ADD COLUMN IF NOT EXISTS adultos_no_lar integer,
  ADD COLUMN IF NOT EXISTS estado_civil   text;
