-- ============================================================
-- Tabela ATENDIMENTO JURÍDICO — Dr. Malaquias
-- Compartilhada entre fibromialgia e óculos (coluna 'projeto').
-- Idempotente: pode rodar novamente sem problema.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.atendimentos_juridicos (
  id                   uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  -- Dados do Paciente
  paciente_nome        text,
  paciente_cpf         text,
  paciente_endereco    text,
  paciente_cidade      text,
  -- Entrada
  data_entrada         date,
  origem               text,
  numero_protocolo     text,
  observacoes_entrada  text,
  -- Aposentadoria
  tipo_beneficio       text,
  nit_pis              text,
  numero_beneficio     text,
  data_entrada_inss    date,
  status_beneficio     text DEFAULT 'aguardando',
  data_decisao         date,
  -- Saúde
  diagnostico          text,
  cid                  text,
  historico_medico     text,
  -- Advogado
  advogado_nome        text,
  advogado_oab         text,
  advogado_contato     text,
  -- Controle
  andamento_processual text,
  proxima_data         date,
  status_processo      text DEFAULT 'em_andamento',
  observacoes_controle text,
  -- Meta
  cadastrado_por       uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  projeto              text NOT NULL DEFAULT 'fibromialgia',
  criado_em            timestamptz DEFAULT now(),
  atualizado_em        timestamptz DEFAULT now()
);

-- RLS
ALTER TABLE public.atendimentos_juridicos ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "jur_select" ON public.atendimentos_juridicos
  FOR SELECT TO authenticated USING (true);

CREATE POLICY IF NOT EXISTS "jur_insert" ON public.atendimentos_juridicos
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "jur_update" ON public.atendimentos_juridicos
  FOR UPDATE TO authenticated USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND papel = 'admin')
    OR cadastrado_por = auth.uid()
  );

CREATE POLICY IF NOT EXISTS "jur_delete" ON public.atendimentos_juridicos
  FOR DELETE TO authenticated USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND papel = 'admin')
  );
