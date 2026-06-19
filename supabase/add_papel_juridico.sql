-- ============================================================
-- Libera o papel 'juridico' na tabela profiles (acesso do Dr. João).
-- A trava antiga só aceitava 'admin' e 'colaborador'.
-- Seguro e idempotente — pode rodar de novo sem problema.
-- Rodar 1x no Supabase Dashboard -> SQL Editor.
-- ============================================================
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_papel_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_papel_check
  CHECK (papel IN ('admin','colaborador','juridico'));
