# ÍNDICE COMPLETO — TCC Ipês

**Data:** 2026-11-24  
**Status:** 80% (R01-R30 ✓, R31 framework ✓, Dissertação ⏳)  
**Autor:** Milton Bacuau

---

## 📋 DOCUMENTAÇÃO PRINCIPAL

### Leia Primeiro
1. **[README.md](README.md)** — Overview projeto, problema, solução, fases, como usar
2. **[RESUMO_EXECUTIVO.md](RESUMO_EXECUTIVO.md)** — Para banca: problema → solução → impacto → timeline
3. **[PLANO_ATUAL.md](PLANO_ATUAL.md)** — Status atual, checklist, bloqueadores, próximas ações

### Documentação Skill
4. **[SKILL_COMO_USAR.md](SKILL_COMO_USAR.md)** — Como executar, passo-a-passo, troubleshooting
5. **[SKILL_TCC_MODELAGEM_AMBIENTAL.md](TCC%20-%20Ipes%20-%20Inicio%20do%20zero/05%20-%20Modelagem%20no%20R/SKILL_TCC_MODELAGEM_AMBIENTAL.md)** — Especificação 12 seções
6. **[SKILL_PROMPT_CLAUDE.md](SKILL_PROMPT_CLAUDE.md)** — Instruções Claude para Skill

### Relatórios Consolidados
7. **[01_RELATORIO_CONSOLIDADO_R28_R29_R30.md](01_RELATORIO_CONSOLIDADO_R28_R29_R30.md)** — Análise 8 seções (resumo, R28, R29, R30, features, RM, omissão, conclusões)
8. **[02_ANALISES_ADICIONAIS_R28_R30.md](02_ANALISES_ADICIONAIS_R28_R30.md)** — Análise aprofundada 10 seções

---

## 📊 DADOS & RESULTADOS

### Consolidação
- **[00_CONSOLIDACAO_R28_R29_R30.csv](00_CONSOLIDACAO_R28_R29_R30.csv)** — 82 modelos unificados (ID, AUC, Boyce, omissão, RM, features, espécie, painel)

### Gráficos Exploratórios (6 PNGs)
- `01_BOXPLOT_AUC_POR_FEATURE_E_RM.png` — Distribuição AUC
- `02_SCATTER_AUC_VS_BOYCE.png` — Correlação métricas
- `03_HEATMAP_BOYCE_ESPECIE_PAINEL_RM.png` — Padrões por features
- `04_RESUMO_FEATURES_IMPORTANCIA.png` — Feature ranking
- `05_COMPARATIVO_ROXO_VS_AMARELO.png` — Espécies
- `06_ANALISE_OMISSAO_P10.png` — Sensibilidade limiares

---

## 🛠️ CÓDIGO & SCRIPTS

### Python
- **[skill_modelagem_ipes.py](skill_modelagem_ipes.py)** — Skill Python (512 linhas, orquestração R28-R31)
- **[consolidacao_R28_R30.py](consolidacao_R28_R30.py)** — Lê 3 CSVs (R28/R29/R30), unifica, exporta
- **[gerar_graficos_R28_R30.py](gerar_graficos_R28_R30.py)** — Gera 6 gráficos exploratórios

### R Scripts

#### R28 (6 Modelos Básicos)
- **[TCC - Ipes - Inicio do zero/05 - Modelagem no R/R28_TCC_IPES_6_MODELOS_LOCAIS_V1_1_CORRIGIDO/](TCC%20-%20Ipes%20-%20Inicio%20do%20zero/05%20-%20Modelagem%20no%20R/R28_TCC_IPES_6_MODELOS_LOCAIS_V1_1_CORRIGIDO/)**
  - Treina 6 modelos LQH RM=4 (Roxo+Amarelo, 3 painéis)
  - Output: 6 .rds + CSV métricas

#### R29 (Recíprocos Validação Local)
- **[TCC - Ipes - Inicio do zero/05 - Modelagem no R/R29_TCC_IPES_BOYCE_RECIPROCOS_V1/](TCC%20-%20Ipes%20-%20Inicio%20do%20zero/05%20-%20Modelagem%20no%20R/R29_TCC_IPES_BOYCE_RECIPROCOS_V1/)**
  - 4 modelos recíprocos (teste transferência)
  - Output: 4 .rds + CSV métricas

#### R30 (72 Grade Exploração)
- **[TCC - Ipes - Inicio do zero/05 - Modelagem no R/R30_TCC_IPES_GRADE_72_UPAS_V1/](TCC%20-%20Ipes%20-%20Inicio%20do%20zero/05%20-%20Modelagem%20no%20R/R30_TCC_IPES_GRADE_72_UPAS_V1/)**
  - 2 espécies × 3 painéis × 3 features (L/LQ/LQH) × 4 RM (1-4)
  - Output: 72 .rds + CSV métricas

#### R31 (Validação Externa)
- **[TCC - Ipes - Inicio do zero/05 - Modelagem no R/R31_TCC_IPES_VALIDACAO_EXTERNA_V1/](TCC%20-%20Ipes%20-%20Inicio%20do%20zero/05%20-%20Modelagem%20no%20R/R31_TCC_IPES_VALIDACAO_EXTERNA_V1/)**
  - [R31_VALIDACAO_EXTERNA.R](TCC%20-%20Ipes%20-%20Inicio%20do%20zero/05%20-%20Modelagem%20no%20R/R31_TCC_IPES_VALIDACAO_EXTERNA_V1/R31_VALIDACAO_EXTERNA.R) — Script template com [TEMPLATE] markers
  - [R31_MANUAL_PREENCHIMENTO.md](TCC%20-%20Ipes%20-%20Inicio%20do%20zero/05%20-%20Modelagem%20no%20R/R31_TCC_IPES_VALIDACAO_EXTERNA_V1/R31_MANUAL_PREENCHIMENTO.md) — 12 passos preenchimento
  - [LEIA_PRIMEIRO.txt](TCC%20-%20Ipes%20-%20Inicio%20do%20zero/05%20-%20Modelagem%20no%20R/R31_TCC_IPES_VALIDACAO_EXTERNA_V1/LEIA_PRIMEIRO.txt) — Overview R31

#### R31 Simulador
- **[R31_SIMULADOR_VALIDACAO_EXTERNA.html](R31_SIMULADOR_VALIDACAO_EXTERNA.html)** — Simulador web interativo (HTML+JS+CSS)

---

## 📈 DADOS BRUTOS

### Preparação (R01-R25)
- **[TCC - Ipes - Inicio do zero/01-04/](TCC%20-%20Ipes%20-%20Inicio%20do%20zero/01-04/)** — Inventários brutos, shapefiles, preditores, datasets congelados

### Resultados R28
- **[TCC - Ipes - Inicio do zero/05 - Modelagem no R/R28_.../03_RESULTADOS_R28_V1_1/](TCC%20-%20Ipes%20-%20Inicio%20do%20zero/05%20-%20Modelagem%20no%20R/R28_TCC_IPES_6_MODELOS_LOCAIS_V1_1_CORRIGIDO/03_RESULTADOS_R28_V1_1/)**
  - 6 modelos .rds
  - CSV métricas
  - Relatório execução

### Resultados R29
- **[TCC - Ipes - Inicio do zero/05 - Modelagem no R/R29_.../RESULTADOS_R29/](TCC%20-%20Ipes%20-%20Inicio%20do%20zero/05%20-%20Modelagem%20no%20R/R29_TCC_IPES_BOYCE_RECIPROCOS_V1/RESULTADOS_R29/)**
  - 4 modelos .rds
  - CSV métricas

### Resultados R30
- **[TCC - Ipes - Inicio do zero/05 - Modelagem no R/R30_.../RESULTADOS_R30_GRADE/](TCC%20-%20Ipes%20-%20Inicio%20do%20zero/05%20-%20Modelagem%20no%20R/R30_TCC_IPES_GRADE_72_UPAS_V1/RESULTADOS_R30_GRADE/)**
  - 72 modelos .rds
  - CSV comparação (features × RM)

---

## 🎓 DISSERTAÇÃO (Pendente)

**Status:** Não iniciada (20% do projeto)

**Capítulos planejados:**
1. **Introdução** — Contexto, lacuna, objetivo (2 dias)
2. **Revisão Bibliográfica** — MaxEnt, transferência, Ipês (5 dias)
3. **Métodos** — Dados, preditores, MaxEnt config (3 dias)
4. **Resultados** — R28-R30, tabelas, figuras (5 dias)
5. **Discussão** — Padrões, implicações, limitações (5 dias)
6. **Conclusão** — Viabilidade, futuro (2 dias)

**Timeline:** 4-6 semanas redação + revisão (esperado Dez 2026)

**Dados entrada:**
- ✓ Consolidação R28-R30 (pronta)
- ✓ Gráficos (6 PNGs prontos)
- ⏳ R31 validação externa (framework pronto, dados pending)
- ⏳ Mapas finais (após R31)

---

## 🔄 GIT COMMITS RECENTES

```
0e41176 — Docs: Resumo Executivo TCC
06066f8 — Docs: README + Skill Como Usar
3f2a062 — Projeto TCC Ipês: 80% - Status final sessão
9e3019f — Skill Python: Integração Rscript (executar R28-R31)
b7e8f84 — R31 framework template: validacao externa 7 propriedades
40acfd4 — Consolidacao R28-R29-R30: Modelagem ambiental de Ipês
```

**Branch:** master  
**Remote:** [git history]  
**Status:** Sem mudanças não commitadas

---

## 📋 CHECKLIST PROJETO

### Preparação ✓
- [x] Inventários limpos e validados
- [x] Preditores preparados (6 camadas 30m)
- [x] Datasets congelados (B0, B1, B2)
- [x] Folds splitting (treino/validação)

### Modelagem ✓
- [x] R28: 6 modelos básicos
- [x] R29: 4 recíprocos
- [x] R30: 72 grade exploração
- [x] Consolidação (CSV + relatórios + gráficos)

### R31 ⏳
- [x] Framework template criado
- [x] Script R31 escrito com [TEMPLATE] markers
- [x] Manual preenchimento (12 passos)
- [x] Simulador web
- [ ] Dados 7 propriedades (presencas + preditores)
- [ ] Executar R31 (~1-2h)
- [ ] Validação externa completa

### Skill ⏳
- [x] Especificação SKILL_TCC_MODELAGEM_AMBIENTAL.md
- [x] Prompt Claude SKILL_PROMPT_CLAUDE.md
- [x] Python class SkillModelagemIpes
- [x] Métodos Rscript (R28/R30/R31/workflow)
- [ ] Registrar em ~/.claude/skills/
- [ ] Testes end-to-end
- [ ] Documentação final

### Dissertação ⏳
- [ ] Introdução (1-2 dias)
- [ ] Revisão bibliográfica (3-5 dias)
- [ ] Métodos (1-3 dias)
- [ ] Resultados (3-5 dias)
- [ ] Discussão (3-5 dias)
- [ ] Conclusão (1-2 dias)
- [ ] Revisão + ajustes (3-5 dias)

---

## 🚀 PRÓXIMAS AÇÕES (Prioridade)

1. **[CRÍTICO]** Obter dados 7 propriedades (presencas + preditores 30m)
2. **[ALTO]** Executar R31 (validação externa)
3. **[ALTO]** Começar dissertação (Intro + Métodos)
4. **[MÉDIO]** Skill dev + testes (paralelo)
5. **[MÉDIO]** Compilar mapas finais

---

## 📞 CONTATO

**Autor:** Milton Bacuau  
**Email:** bacudigital@gmail.com  
**Instituição:** UFRA (Universidade Federal Rural da Amazônia)  
**TCC:** Modelagem Ambiental de Ipês em Florestas Manejadas do Pará

---

## 📚 REFERÊNCIAS RÁPIDAS

| O que procura | Onde encontrar |
|---------------|----------------|
| Como usar skill | SKILL_COMO_USAR.md |
| Métricas projeto | 00_CONSOLIDACAO_R28_R29_R30.csv |
| Análises aprofundadas | 01_RELATORIO_*.md, 02_ANALISES_*.md |
| R31 preencher | R31_MANUAL_PREENCHIMENTO.md |
| Preencher R31 | R31_VALIDACAO_EXTERNA.R + LEIA_PRIMEIRO.txt |
| Status atual | PLANO_ATUAL.md |
| Timeline | RESUMO_EXECUTIVO.md seção 8 |
| Descobertas chave | RESUMO_EXECUTIVO.md seção 4 |
| Skill especificação | SKILL_TCC_MODELAGEM_AMBIENTAL.md |
| Python code | skill_modelagem_ipes.py |
| Gráficos | 6 PNGs em raiz projeto |

---

**Data atualização:** 2026-11-24  
**Versão:** 1.0  
**Status:** 80% completo (R01-R30 ✓, R31 framework ✓, Dissertação ⏳)
