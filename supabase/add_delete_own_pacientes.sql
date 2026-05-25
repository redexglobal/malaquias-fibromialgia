-- =====================================================================
-- add_delete_own_pacientes.sql
-- Permite que o COLABORADOR delete os pacientes que ele MESMO cadastrou.
-- Admin continua podendo deletar qualquer um.
-- Idempotente — pode rodar várias vezes sem erro.
-- =====================================================================

-- ===== pacientes_fibro =====
DROP POLICY IF EXISTS "pacientes_fibro_delete" ON public.pacientes_fibro;
DROP POLICY IF EXISTS "pacientes_fibro_delete_own" ON public.pacientes_fibro;
DROP POLICY IF EXISTS "pacientes_fibro_delete_admin" ON public.pacientes_fibro;

CREATE POLICY "pacientes_fibro_delete_own" ON public.pacientes_fibro
FOR DELETE TO authenticated
USING (
  cadastrado_por = auth.uid()
  OR public._get_papel(auth.uid()) = 'admin'
);

-- ===== pacientes_oculos =====
DROP POLICY IF EXISTS "pacientes_oculos_delete" ON public.pacientes_oculos;
DROP POLICY IF EXISTS "pacientes_oculos_delete_own" ON public.pacientes_oculos;
DROP POLICY IF EXISTS "pacientes_oculos_delete_admin" ON public.pacientes_oculos;

CREATE POLICY "pacientes_oculos_delete_own" ON public.pacientes_oculos
FOR DELETE TO authenticated
USING (
  cadastrado_por = auth.uid()
  OR public._get_papel(auth.uid()) = 'admin'
);

-- =====================================================================
-- Confirma policies criadas
-- =====================================================================
-- SELECT polname, polrelid::regclass, polcmd FROM pg_policy
-- WHERE polrelid IN ('public.pacientes_fibro'::regclass, 'public.pacientes_oculos'::regclass)
-- ORDER BY polrelid::regclass::text, polcmd;
