-- =====================================================================
-- cleanup_demo_data.sql
-- Limpeza dos dados de demonstração ANTES do cliente começar a usar
-- pra valer.
--
-- IDEMPOTENTE: pode rodar mais de uma vez sem efeito colateral.
-- TRANSACIONAL: tudo dentro de BEGIN/COMMIT — se algo falhar, rollback automático.
--
-- ⚠️ ROLE COMO REVISAR ANTES DE EXECUTAR:
--    1. Confira as contagens no SELECT de validação no fim do arquivo
--    2. Se quiser DRY-RUN, troca COMMIT por ROLLBACK no fim e roda
--    3. Quando confirmar, mantém COMMIT e roda no SQL Editor
--
-- O QUE DELETA:
--    - pacientes_fibro  com cpf LIKE '999.%' OU [DEMO] nas observações
--    - pacientes_oculos com cpf LIKE '999.%' OU [DEMO] nas observações
--    - mensagens_pontos com [DEMO] na mensagem  (skip se tabela não existir)
--    - feedback_semanal com [DEMO] nas observações  (skip se tabela não existir)
--    - historico_natalia em atualizado_em = '2026-05-13 23:00:00' (marcador demo)
--    - online_at dos colaboradores volta pra NULL (reset de presença)
--
-- O QUE MANTÉM (NÃO TOCA):
--    - Snapshot __SNAPSHOT__ no historico_natalia (audit trail útil)
--    - Histórico real (Visão do Futuro, Goiânia Viva, Indiara, etc.)
--    - TODOS os profiles (admins + colaboradores)
--    - TODAS as policies de RLS
--    - TUDO de auth (usuários, senhas, sessões)
--    - Views v_pontos_*, RPCs get_pontos_por_data_*
-- =====================================================================

BEGIN;

-- 1) pacientes_fibro
DELETE FROM public.pacientes_fibro
WHERE cpf LIKE '999.%'
   OR observacoes LIKE '%[DEMO]%';

-- 2) pacientes_oculos
DELETE FROM public.pacientes_oculos
WHERE cpf LIKE '999.%'
   OR observacoes LIKE '%[DEMO]%';

-- 3) mensagens_pontos (skip silencioso se tabela não existir)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'mensagens_pontos'
  ) THEN
    EXECUTE 'DELETE FROM public.mensagens_pontos WHERE mensagem LIKE ''%[DEMO]%''';
  END IF;
END $$;

-- 4) feedback_semanal (skip silencioso se tabela não existir)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'feedback_semanal'
  ) THEN
    EXECUTE 'DELETE FROM public.feedback_semanal WHERE observacoes LIKE ''%[DEMO]%''';
  END IF;
END $$;

-- 5) historico_natalia — só remove o marcador específico de demo
DELETE FROM public.historico_natalia
WHERE atualizado_em = '2026-05-13 23:00:00';

-- 6) Reset de presença dos colaboradores (volta a NULL — começam offline)
UPDATE public.profiles
SET online_at = NULL
WHERE papel = 'colaborador';

-- =====================================================================
-- VALIDAÇÃO — contagens pós-limpeza pra você revisar antes do COMMIT
-- =====================================================================
SELECT 'pacientes_fibro' AS tabela, COUNT(*) AS restantes FROM public.pacientes_fibro
UNION ALL
SELECT 'pacientes_oculos', COUNT(*) FROM public.pacientes_oculos
UNION ALL
SELECT 'profiles_admin', COUNT(*) FROM public.profiles WHERE papel = 'admin'
UNION ALL
SELECT 'profiles_colaborador', COUNT(*) FROM public.profiles WHERE papel = 'colaborador'
UNION ALL
SELECT 'profiles_online', COUNT(*) FROM public.profiles WHERE online_at IS NOT NULL
UNION ALL
SELECT 'historico_natalia_real', COUNT(*) FROM public.historico_natalia
  WHERE nome NOT LIKE '__SNAPSHOT__%'
UNION ALL
SELECT 'historico_natalia_snapshot', COUNT(*) FROM public.historico_natalia
  WHERE nome LIKE '__SNAPSHOT__%';

-- =====================================================================
-- ⬇️ COMMIT FINAL — se a validação acima estiver OK
-- ⬇️ Se quiser DRY-RUN, troca COMMIT por ROLLBACK e roda primeiro
-- =====================================================================
COMMIT;
