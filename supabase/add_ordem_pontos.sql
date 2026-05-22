-- ============================================================
-- Coluna de ORDEM manual dos pontos (feature "Editar Pontos")
-- Rode UMA vez no SQL Editor do Supabase (a base e compartilhada
-- entre fibromialgia e oculos, entao vale pros dois projetos).
-- Idempotente: pode rodar de novo sem problema.
-- ============================================================

-- 1) cria a coluna (se ainda nao existir)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS ordem integer;

-- 2) inicializa a ordem = numero_ponto para todos os pontos (colaboradores)
--    que ainda nao tem ordem definida. A Natalia ajusta o resto pela tela.
UPDATE public.profiles
SET ordem = numero_ponto
WHERE papel = 'colaborador' AND ordem IS NULL;
