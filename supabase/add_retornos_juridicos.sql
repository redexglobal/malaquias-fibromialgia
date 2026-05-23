-- ============================================================
-- Tabela RETORNOS JURÍDICOS — Dr. Malaquias
-- Registra cada retorno/visita de acompanhamento jurídico.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.retornos_juridicos (
  id                     uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  atendimento_id         uuid REFERENCES public.atendimentos_juridicos(id) ON DELETE CASCADE,
  -- Paciente (denormalizado para facilitar queries)
  paciente_nome          text,
  paciente_cpf           text,
  -- Visita
  data_retorno           date,
  -- Status no momento do retorno
  status_beneficio_atual text DEFAULT 'aguardando',
  status_processo_atual  text DEFAULT 'em_andamento',
  -- Conteúdo
  andamento              text,
  proxima_data           date,
  observacoes            text,
  -- Meta
  cadastrado_por         uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  projeto                text NOT NULL DEFAULT 'fibromialgia',
  criado_em              timestamptz DEFAULT now(),
  atualizado_em          timestamptz DEFAULT now()
);

ALTER TABLE public.retornos_juridicos ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "ret_jur_select" ON public.retornos_juridicos
  FOR SELECT TO authenticated USING (true);

CREATE POLICY IF NOT EXISTS "ret_jur_insert" ON public.retornos_juridicos
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "ret_jur_update" ON public.retornos_juridicos
  FOR UPDATE TO authenticated USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND papel = 'admin')
    OR cadastrado_por = auth.uid()
  );

CREATE POLICY IF NOT EXISTS "ret_jur_delete" ON public.retornos_juridicos
  FOR DELETE TO authenticated USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND papel = 'admin')
  );
