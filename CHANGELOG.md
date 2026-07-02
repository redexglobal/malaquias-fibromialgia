# CHANGELOG

Sistema Dr. Malaquias — Projeto Fibromialgia.

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/).

## [Charme Fino] - 2026-07-02 (sw v57)

### Adicionado
- Sidebar: item levanta no hover + letra/ícone acendem com luz verde suave (pedido do Vilson: fino, elegante, sem cibernético).
- KPIs do dashboard (Únicos/Hoje/Semana/Dor): no hover a linha de luz do topo intensifica, ícone ganha halo e escala sutil, valor ganha brilho delicado.
- Wizard jurídico: sugestões de cidade ao digitar (`datalist` com as 13 cidades canônicas) — limpa a grafia na raiz.
- Painéis Carteirinhas e Monitor de Erros: controles (inputs, labels, listas) agora seguem o tema escuro/claro via CSS vars (cartões impressos continuam brancos, como devem).

### Banco (rodado no dashboard em 2026-07-02)
- Bloco LGPD do `juridico_rls_v2.sql` aplicado: colaboradora só lê o jurídico que ela mesma cadastrou (verificado ao vivo: ponto 23 vê 0 de 59; RPC do resumo dela segue OK).

## [Jurídico v3 + Brilho] - 2026-07-02 (sw v56)

### Adicionado
- Relatório Jurídico (André): dropdowns de Região e Cidade (inclui cidades dos pontos do fibro, mesmo sem processo), chips de filtro removíveis, gráfico novo "Evolução Mensal", drill-down clicável nos 3 gráficos (status/benefício/mês) e lista de pacientes auto-expandida quando há filtro.
- Painel Jurídico (jdash): barra de filtro Região/Cidade acima dos KPIs — tudo (KPIs, gráficos, prazos) respeita o filtro.
- Cadastrados (jurídico): filtros de Região e Cidade na barra; aba Dashboard agora visível também para o papel `juridico` e respeita os filtros ativos; coluna Ponto visível para o André jurídico.
- CSS "Brilho Digital": glow verde sutil (botões, KPIs, nav ativo), `:focus-visible`, `prefers-reduced-motion`, contraste do texto auxiliar no tema claro.

### Corrigido
- Tipo de benefício agora é normalizado nos gráficos ("APOSENTADORIA"/"aposentadoria" contavam separado).
- `jurSalvar` detecta update de 0 linhas (RLS) e avisa em vez de fingir sucesso.

### Segurança / Banco
- `supabase/juridico_rls_v2.sql` (RODAR NO DASHBOARD): papel `juridico` passa a poder editar registros criados pelas colaboradoras (antes o UPDATE era ignorado em silêncio). Bloco opcional endurece o SELECT (LGPD).
- `MAX_ROWS` 20000 → 60000 (o teto seria atingido em ~2 meses no ritmo atual); lista de cadastrados jurídicos 2000 → 5000.

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
