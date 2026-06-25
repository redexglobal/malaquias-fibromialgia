-- ============================================================
-- MONITOR DE ERROS — tabela de log
-- Rodar 1x no SQL Editor (idempotente). Guarda erros de JavaScript que
-- acontecem em qualquer máquina. O painel (só da Natália) lê daqui.
-- ============================================================

CREATE TABLE IF NOT EXISTS erros_log (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  mensagem    text,
  origem      text,
  url         text,
  user_email  text,
  papel       text,
  ponto       text,
  user_agent  text,
  criado_em   timestamptz DEFAULT now()
);

ALTER TABLE erros_log ENABLE ROW LEVEL SECURITY;

-- Qualquer usuária logada pode REGISTRAR um erro (insert)
DROP POLICY IF EXISTS erros_insert ON erros_log;
CREATE POLICY erros_insert ON erros_log FOR INSERT TO authenticated WITH CHECK (true);

-- Logado pode LER (o painel é mostrado só pra Natália na interface)
DROP POLICY IF EXISTS erros_select ON erros_log;
CREATE POLICY erros_select ON erros_log FOR SELECT TO authenticated USING (true);

-- Acelera a listagem por data
CREATE INDEX IF NOT EXISTS idx_erros_log_criado ON erros_log (criado_em DESC);
