-- =====================================================================
-- login_rls_backup.sql
-- Estado conhecido como FUNCIONANDO do RLS + função _get_papel
-- Se login quebrar com "Usuário não configurado", rode este arquivo inteiro
-- no SQL Editor do Supabase. É idempotente — pode rodar várias vezes.
--
-- Última atualização: 2026-05-12 (após incidente de login)
-- =====================================================================

-- 1) Função SECURITY DEFINER pra checar papel sem disparar recursão de RLS
CREATE OR REPLACE FUNCTION public._get_papel(uid uuid)
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT papel FROM public.profiles WHERE id = uid LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public._get_papel(uuid) TO authenticated;

-- 2) Limpa todas as policies de profiles e recria do zero (sem recursão)
DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN SELECT polname FROM pg_policy WHERE polrelid='public.profiles'::regclass LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', pol.polname);
  END LOOP;
END $$;

-- SELECT: admin vê tudo, qualquer authenticated vê o próprio profile
CREATE POLICY "profiles_select" ON public.profiles
FOR SELECT TO authenticated
USING (
  public._get_papel(auth.uid()) = 'admin'
  OR id = auth.uid()
);

-- UPDATE: cada um atualiza o próprio
CREATE POLICY "profiles_update_own" ON public.profiles
FOR UPDATE TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- UPDATE: admin pode atualizar qualquer
CREATE POLICY "profiles_update_admin" ON public.profiles
FOR UPDATE TO authenticated
USING (public._get_papel(auth.uid()) = 'admin')
WITH CHECK (public._get_papel(auth.uid()) = 'admin');

-- INSERT: usuário insere própria linha ou admin insere qualquer
CREATE POLICY "profiles_insert" ON public.profiles
FOR INSERT TO authenticated
WITH CHECK (id = auth.uid() OR public._get_papel(auth.uid()) = 'admin');

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3) Garante que os 4 admins têm papel='admin' e ativo=true
UPDATE public.profiles
SET papel = 'admin', ativo = true
WHERE email IN (
  'natalia@malaquias.com',
  'antonio@malaquias.com',
  'drmalaquias@malaquias.com',
  'marcelo@malaquias.com'
);

-- 4) Garante colaboradores com ativo=true (seed legado podia ter null)
UPDATE public.profiles
SET ativo = true
WHERE papel = 'colaborador'
  AND (ativo IS NULL OR ativo = false);

-- 5) Validação — DEVE retornar 4 linhas com papel='admin' e ativo=true
SELECT email, papel, ativo
FROM public.profiles
WHERE email LIKE '%@malaquias.com'
  AND papel = 'admin'
ORDER BY email;

-- 6) Diagnóstico — confirma que admin id bate com auth.users
SELECT
  au.email,
  CASE WHEN au.id = p.id THEN 'OK ✅' ELSE 'MISMATCH ❌' END AS match_status,
  p.papel,
  p.ativo
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
WHERE au.email LIKE '%@malaquias.com'
ORDER BY au.email;
