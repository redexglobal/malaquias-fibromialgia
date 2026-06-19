-- ============================================================
-- Acesso do papel 'juridico' (Dr. João) às tabelas jurídicas.
-- A RLS antiga não contemplava o papel 'juridico' (ele via 0 processos).
-- Policies ADITIVAS (OR) — não alteram o que admin/colaboradoras já têm.
-- Seguro e idempotente. Rodar no Supabase -> SQL Editor.
-- ============================================================

-- ATENDIMENTOS JURÍDICOS
DROP POLICY IF EXISTS jur_juridico_all ON public.atendimentos_juridicos;
CREATE POLICY jur_juridico_all ON public.atendimentos_juridicos
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.papel = 'juridico'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.papel = 'juridico'));

-- RETORNOS JURÍDICOS
DROP POLICY IF EXISTS ret_juridico_all ON public.retornos_juridicos;
CREATE POLICY ret_juridico_all ON public.retornos_juridicos
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.papel = 'juridico'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.papel = 'juridico'));
