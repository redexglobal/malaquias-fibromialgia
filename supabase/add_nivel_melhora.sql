-- Adiciona campo "nível de melhora" no Stage 4 da Conclusão
-- Valores: -2 (piorou muito), -1 (piorou pouco), 0 (sem mudança),
--          1 (melhorou pouco), 2 (melhorou bastante), 3 (muito melhor/recuperado)
-- NULL = primeira consulta / não se aplica
-- Idempotente (IF NOT EXISTS).

ALTER TABLE pacientes_fibro
  ADD COLUMN IF NOT EXISTS nivel_melhora integer;

ALTER TABLE pacientes_oculos
  ADD COLUMN IF NOT EXISTS nivel_melhora integer;
