# CHANGELOG

Sistema Dr. Malaquias — Projeto Fibromialgia.

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/).

## [Pontos v2] - 2026-05-13

### Adicionado
- Aba "Gestão de Pontos" restaurada (visível apenas para admin).
- 25 cards interativos (20 fixos + 5 móveis) por projeto.
- Views Supabase `v_pontos_fibro` e `v_pontos_oculos` com KPIs agregados (total, hoje, semana, dor alta, média de dor).
- RPCs `get_pontos_por_data_fibro` e `get_pontos_por_data_oculos` para consultas por data específica do passado.
- Filtros na seção Pontos:
  - Slider de dor 0–10 (fibro).
  - Chips temporais: Todos / Dor Alta (7+) / Hoje / Semana.
  - Date picker (sobrescreve filtros temporais quando ativo).
- Modal de detalhes ao clicar no card:
  - KPIs em linha: Hoje / Esta Semana / Total Geral.
  - Filtros: busca por nome/WhatsApp + intervalo de datas (default últimos 30 dias).
  - Cadastros agrupados por data com sticky header.
  - Métrica por linha: dor (fibro) ou status+valor (óculos).
  - Botão "Exportar CSV" respeitando filtros aplicados (BOM UTF-8 pra Excel BR).
  - Footer com contador "Exibindo X de Y cadastros".
  - Aviso de limite 500 quando atingido.

### Segurança
- RLS configurada nas tabelas `profiles`, `pacientes_fibro`, `pacientes_oculos`.
- Admin vê tudo; colaborador vê só os próprios cadastros (`cadastrado_por = auth.uid()`).
- Função `_get_papel` `SECURITY DEFINER` previne recursão infinita de RLS.

### Backup
- Tag `stable-login-2026-05-12` (estado anterior estável do login, antes do refator).
- Branch `backup/stable-login-2026-05-12` congelada como fallback.
- Tag `stable-pontos-2026-05-13` (este estado, cards funcionando com filtros e modal).
- Script de recuperação: `supabase/migrations/login_rls_backup.sql` idempotente.

### Arquitetura
- Refator cirúrgico em 4 fases incrementais (commits separados) pra isolar regressão.
- IDs e nomes de função preservados (`#sec-pontos`, `#pontos-grid`, `updatePontos`, `openPontoDetalhe`).
- Heatmap, score bars, botões ✏️/ON-OFF e presença online intactos.
- Todo código novo envolvido em `try/catch` pra erro não propagar e quebrar o app.

### Commits da release
1. `feat(pontos): fase 1/4 — usa view v_pontos_{fibro,oculos} no updatePontos`
2. `feat(pontos): fase 2/4 — UI dos filtros (slider, chips, date picker, legenda)`
3. `feat(pontos): fase 3/4 — JS dos filtros funcionais (chips, slider, data, RPC por data)`
4. `feat(pontos): fase 4/4 — modal de cadastros agrupados por data + exportar CSV`
