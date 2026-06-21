-- ============================================================
-- SIGILO DA ÁREA JURÍDICA — Dr. Malaquias
-- Regra: SÓ admin + diretor jurídico (papel 'juridico' = Dr. André) VEEM os dados.
--   - Atendente (colaborador) PODE cadastrar (INSERT), mas NÃO lê (SELECT) nenhum dado.
--   - O contador "quantos encaminhei" do atendente vem por função agregada (sem dados).
-- Reseta as policies das tabelas jurídicas para um estado limpo e conhecido.
-- Seguro/idempotente. Rodar no Supabase -> SQL Editor.
-- ============================================================

-- ---------- ATENDIMENTOS JURÍDICOS ----------
ALTER TABLE public.atendimentos_juridicos ENABLE ROW LEVEL SECURITY;

-- remove QUALQUER policy antiga dessa tabela (estado limpo)
DO $$ DECLARE p record; BEGIN
  FOR p IN SELECT policyname FROM pg_policies WHERE schemaname='public' AND tablename='atendimentos_juridicos' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.atendimentos_juridicos', p.policyname);
  END LOOP;
END $$;

-- SELECT: só admin + jurídico (André)
CREATE POLICY jur_sel_adm ON public.atendimentos_juridicos FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id=auth.uid() AND p.papel IN ('admin','juridico')));
-- INSERT: qualquer autenticado pode registrar (gravando como seu); admin/jurídico também
CREATE POLICY jur_ins_all ON public.atendimentos_juridicos FOR INSERT TO authenticated
  WITH CHECK (cadastrado_por = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id=auth.uid() AND p.papel IN ('admin','juridico')));
-- UPDATE / DELETE: só admin + jurídico
CREATE POLICY jur_upd_adm ON public.atendimentos_juridicos FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id=auth.uid() AND p.papel IN ('admin','juridico')));
CREATE POLICY jur_del_adm ON public.atendimentos_juridicos FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id=auth.uid() AND p.papel IN ('admin','juridico')));

-- ---------- RETORNOS JURÍDICOS (só admin + jurídico em tudo) ----------
ALTER TABLE public.retornos_juridicos ENABLE ROW LEVEL SECURITY;
DO $$ DECLARE p record; BEGIN
  FOR p IN SELECT policyname FROM pg_policies WHERE schemaname='public' AND tablename='retornos_juridicos' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.retornos_juridicos', p.policyname);
  END LOOP;
END $$;
CREATE POLICY ret_adm_all ON public.retornos_juridicos FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id=auth.uid() AND p.papel IN ('admin','juridico')))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id=auth.uid() AND p.papel IN ('admin','juridico')));

-- ---------- CONTADOR AGREGADO DO ATENDENTE (sem expor dados) ----------
-- Devolve só CONTAGENS dos cadastros feitos pelo PRÓPRIO usuário logado.
CREATE OR REPLACE FUNCTION public.get_juridico_meus_stats()
RETURNS json LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT json_build_object(
    'total', (SELECT COUNT(*) FROM public.atendimentos_juridicos WHERE cadastrado_por = auth.uid()),
    'por_mes', COALESCE((SELECT json_agg(t) FROM (
        SELECT to_char(COALESCE(data_entrada, criado_em::date),'YYYY-MM') AS mes, COUNT(*) AS n
        FROM public.atendimentos_juridicos WHERE cadastrado_por = auth.uid()
        GROUP BY 1 ORDER BY 1) t), '[]'::json),
    'por_status', COALESCE((SELECT json_agg(t) FROM (
        SELECT COALESCE(status_beneficio,'aguardando') AS status, COUNT(*) AS n
        FROM public.atendimentos_juridicos WHERE cadastrado_por = auth.uid()
        GROUP BY 1) t), '[]'::json)
  );
$$;
GRANT EXECUTE ON FUNCTION public.get_juridico_meus_stats() TO authenticated;
