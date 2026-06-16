-- ============================================================
-- RLS: permite ADMIN inserir/editar/excluir locais no historico_natalia
-- (necessário pro botão "Adicionar local" do Relatório Natália funcionar
--  com o login dela). Idempotente — pode rodar de novo sem problema.
-- Roda 1x no Supabase Dashboard -> SQL Editor.
-- ============================================================
ALTER TABLE public.historico_natalia ENABLE ROW LEVEL SECURITY;

-- Leitura pra qualquer admin (caso ainda não exista)
DROP POLICY IF EXISTS historico_natalia_select_admin ON public.historico_natalia;
CREATE POLICY historico_natalia_select_admin ON public.historico_natalia
  FOR SELECT TO authenticated
  USING (public._get_papel(auth.uid()) = 'admin');

-- Escrita (INSERT/UPDATE/DELETE) só admin
DROP POLICY IF EXISTS historico_natalia_write_admin ON public.historico_natalia;
CREATE POLICY historico_natalia_write_admin ON public.historico_natalia
  FOR ALL TO authenticated
  USING (public._get_papel(auth.uid()) = 'admin')
  WITH CHECK (public._get_papel(auth.uid()) = 'admin');
