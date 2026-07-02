-- ============================================================
-- JURÍDICO RLS v2 — rodar no Supabase (SQL Editor) — 2026-07-02
--
-- PROBLEMA QUE ISTO CORRIGE (bug silencioso):
--   O André jurídico (papel 'juridico') NÃO conseguia EDITAR os
--   registros criados pelas colaboradoras: a política de UPDATE
--   só permitia admin OU quem criou. O app dizia "Atualizado!"
--   mas o banco ignorava (0 linhas). Com isto, papel 'juridico'
--   passa a poder editar QUALQUER registro jurídico (etapas 3-6
--   do fluxo dele).
-- ============================================================

-- 1) ATENDIMENTOS: papel juridico também pode editar tudo
DROP POLICY IF EXISTS "jur_update" ON public.atendimentos_juridicos;
CREATE POLICY "jur_update" ON public.atendimentos_juridicos
  FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND papel IN ('admin','juridico'))
    OR cadastrado_por = auth.uid()
  );

-- 2) RETORNOS JURÍDICOS: idem
DROP POLICY IF EXISTS "ret_jur_update" ON public.retornos_juridicos;
CREATE POLICY "ret_jur_update" ON public.retornos_juridicos
  FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND papel IN ('admin','juridico'))
    OR cadastrado_por = auth.uid()
  );

-- ============================================================
-- 3) OPCIONAL (recomendado p/ LGPD, rode só se quiser apertar):
--    Hoje o SELECT é USING (true) = qualquer colaboradora logada
--    consegue LER todos os processos jurídicos via API (o app
--    esconde na tela, mas o banco não impede). Este bloco fecha:
--    só admin/juridico leem tudo; colaboradora lê só o que ela
--    mesma cadastrou (o painel "meu resumo" dela continua ok).
-- ============================================================
-- DROP POLICY IF EXISTS "jur_select" ON public.atendimentos_juridicos;
-- CREATE POLICY "jur_select" ON public.atendimentos_juridicos
--   FOR SELECT TO authenticated
--   USING (
--     EXISTS (SELECT 1 FROM public.profiles
--             WHERE id = auth.uid() AND papel IN ('admin','juridico'))
--     OR cadastrado_por = auth.uid()
--   );
-- DROP POLICY IF EXISTS "ret_jur_select" ON public.retornos_juridicos;
-- CREATE POLICY "ret_jur_select" ON public.retornos_juridicos
--   FOR SELECT TO authenticated
--   USING (
--     EXISTS (SELECT 1 FROM public.profiles
--             WHERE id = auth.uid() AND papel IN ('admin','juridico'))
--     OR cadastrado_por = auth.uid()
--   );
