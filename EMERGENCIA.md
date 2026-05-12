# 🚨 PROCEDIMENTO DE EMERGÊNCIA — Sistema Dr. Malaquias

## Se o sistema quebrar:

### CENÁRIO A — Código quebrou (login não funciona / cards sumiram)
```bash
cd "C:/Users/Vilson Moto Paiva/malaquias-fibromialgia"
git fetch --all --tags
git reset --hard stable-pontos-v1-2026-05-13
git push --force origin master
```
Repete pra `malaquias-oculos`. Aguarda 1 min, hard refresh.

### CENÁRIO B — Banco quebrou (views/RLS sumiram)
1. Abre https://supabase.com/dashboard/project/vuylzbefjwbtibhnczih/sql/new
2. Cola conteúdo de `supabase/migrations/login_rls_backup.sql`
3. Run

### CENÁRIO C — Senha de admin perdida
```sql
UPDATE auth.users SET
  encrypted_password = crypt('Natalia@2026', gen_salt('bf')),
  email_confirmed_at = COALESCE(email_confirmed_at, NOW())
WHERE email = 'natalia@malaquias.com';
```
Troca email + senha conforme necessário.

## Credenciais dos 4 admins
- antonio@malaquias.com / Antonio@2026
- natalia@malaquias.com / Natalia@2026
- drmalaquias@malaquias.com / Malaquias@2026
- marcelo@malaquias.com / Marcelo@2026

## Backups disponíveis
- Tag: `stable-pontos-v1-2026-05-13` (versão dourada com 25 cards)
- Tag: `stable-login-2026-05-12` (versão anterior, só login)
- Branch: `backup/pontos-v1-2026-05-13` (congelada)
- Branch: `backup/stable-login-2026-05-12` (congelada)

## URLs
- Fibro: https://malaquias-fibromialgia.vercel.app
- Óculos: https://malaquias-oculos.vercel.app
- Supabase: https://supabase.com/dashboard/project/vuylzbefjwbtibhnczih
