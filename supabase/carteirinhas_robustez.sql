-- ============================================================
-- CARTEIRINHAS — Robustez / performance de LONGO PRAZO
-- Rodar 1x no SQL Editor (idempotente). Cria índices que mantêm
-- a verificação do QR e as buscas por CPF rápidas mesmo com a
-- tabela crescendo por anos.
-- ============================================================

-- 1) Acelera a "2ª via" (procurar carteirinha do paciente+tipo ativa)
CREATE INDEX IF NOT EXISTS idx_carteirinhas_pac_tipo
  ON carteirinhas (paciente_id, tipo, ativo);

-- 2) Acelera a verificação pública do QR E qualquer busca por CPF.
--    Índice funcional pelos DÍGITOS do CPF (igual ao usado na função verificar_carteirinha).
CREATE INDEX IF NOT EXISTS idx_pacientes_fibro_cpf_digits
  ON pacientes_fibro ((regexp_replace(coalesce(cpf,''), '\D', '', 'g')));

-- 3) (Opcional, ajuda relatórios por data) índice por data de consulta
CREATE INDEX IF NOT EXISTS idx_pacientes_fibro_data_consulta
  ON pacientes_fibro (data_consulta);

-- Pronto. Estes índices só ACELERAM — não mudam nenhum dado.
