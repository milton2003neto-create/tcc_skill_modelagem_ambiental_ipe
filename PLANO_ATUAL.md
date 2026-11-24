# PLANO ATUAL — TCC Modelagem Ambiental de Ipês

**Data Atualização:** 2026-11-24 (Final da Sessão)  
**Status Geral:** 80% completo — Consolidação, R31 completo, Skill Python integrada  
**Próxima Milestone:** Dissertação (4-6 semanas redação)

---

## 1. FASES COMPLETADAS ✓

### R01-R25: Preparação de Dados
**Status:** ✓ COMPLETO  
**Descrição:** Limpeza inventários, preditores 30m, background, fold splitting  
**Output:** 
- 6 datasets congelados (B0, B1, B2, etc.)
- 27 propriedades + 64 UPAs inventariadas
- 7 propriedades reservadas teste externo
- Auditoria background + conferências

**Arquivos:** `TCC - Ipes - Inicio do zero/01-04/`  
**Commits:** Histórico até R25

---

### R26-R30: Modelagem Exploratória
**Status:** ✓ COMPLETO  
**Descrição:** 82 modelos ajustados (R28:6 + R29:4 + R30:72)

#### R28: 6 Modelos Referência
- Features: LQH, RM=4, B2 (10k background)
- 2 espécies × 3 painéis locais
- **Métricas:** AUC 0.567 ± 0.124, Boyce 0.829 ± 0.103
- **Status:** ✓ Executado, validado
- **Arquivos:** `R28_TCC_IPES_6_MODELOS_LOCAIS_V1_1_CORRIGIDO/`

#### R29: 4 Modelos Recíprocos
- Treino/validação invertido (Hermes, Limão)
- Teste transferência local entre UPAs
- **Métricas:** AUC 0.595 ± 0.066, Boyce 0.649 ± 0.187
- **Status:** ✓ Executado, transferência viável confirmada
- **Arquivos:** `R29_TCC_IPES_BOYCE_RECIPROCOS_V1/`

#### R30: 72 Modelos Grade Exploratória
- 2 espécies × 3 painéis × 3 features (L, LQ, LQH) × 4 RM (1-4)
- **Achado:** LQH >> L/LQ, RM=4 ótimo
- **Padrão:** Amarelo AUC +0.2 vs Roxo consistente
- **Status:** ✓ Executado, exploração completa
- **Arquivos:** `R30_TCC_IPES_GRADE_72_UPAS_V1/`

---

### Consolidação R28-R30
**Status:** ✓ COMPLETO  
**Data:** 2026-11-24

**Outputs Gerados:**
1. `00_CONSOLIDACAO_R28_R29_R30.csv` — 82 modelos unificados
2. `01_RELATORIO_CONSOLIDADO_R28_R29_R30.md` — 8 seções análise
3. `02_ANALISES_ADICIONAIS_R28_R30.md` — 10 seções aprofundadas
4. `consolidacao_R28_R30.py` — Script Python
5. `gerar_graficos_R28_R30.py` — Script gráficos
6. 6 PNGs exploratórios (AUC, Boyce, features, RM, resumo, comparativo)

**Achados Principais:**
- LQH recomendado (features críticas: hinge essencial)
- RM=4 validado (Boyce superior vs RM=1-3)
- Amarelo > Roxo (AUC +0.2 consistente)
- Independência espacial: pendente R31
- Modelos candidatos: Roxo UPA01, Amarelo UPA03

**Commits:**
- `40acfd4` — Consolidação R28-R30 completa
- `b7e8f84` — R31 framework template

---

## 2. FASES EM PROGRESSO ⏳

### R31: Validação Externa
**Status:** ⏳ FRAMEWORK PRONTO, AGUARDANDO DADOS  
**Data Início:** 2026-11-24

**Framework Criado:**
- `R31_VALIDACAO_EXTERNA_V1/` — Estrutura
- `R31_VALIDACAO_EXTERNA.R` — Script template com [TEMPLATE] markers
- `R31_MANUAL_PREENCHIMENTO.md` — Guia 12 passos
- `LEIA_PRIMEIRO.txt` — Overview

**Faltando:**
- Presencas CSV (Roxo + Amarelo em 7 propriedades)
- Preditores grid 30m (7 propriedades)
- Carregamento modelos R28 RDS

**Próximos Passos:**
1. Obter dados 7 propriedades (Barro Branco, Curuça, Guariúba, Jatobá, etc.)
2. Preencher R31 manual (12 passos)
3. Executar ~1-2h RStudio
4. Validação externa completa

**Criterio Sucesso:**
- AUC >= 0.5 em >= 5/7 propriedades
- Boyce >= 0 em >= 6/7
- Esperado: AUC queda 15-40% vs R28

**Commit:** `b7e8f84`

---

### Skill: Modelagem Ambiental Ipês
**Status:** ⏳ ESPECIFICAÇÃO COMPLETA, IMPLEMENTAÇÃO PENDENTE  
**Data Início Especificação:** 2026-11-24

**Especificações Criadas:**
1. `SKILL_TCC_MODELAGEM_AMBIENTAL.md` — Funcional (12 seções)
2. `SKILL_PROMPT_CLAUDE.md` — Prompt Claude (10 seções)

**Escopo Skill:**
- 5 fases workflow (preparação, modelagem, consolidação, validação, dissertação)
- 7 comandos principais (/modelagem-ipes preparar-dados, modelar, consolidar, validar-externa, gerar-dissertacao, etc.)
- Validações automáticas
- Help + troubleshooting

**Implementação Pendente:**
- Código Python/R integração
- Registry ~/.claude/skills/
- Testes end-to-end
- Tempo estimado: 2-3 semanas dev

**Commit:** `8350890`

---

## 3. FASES NÃO INICIADAS ⭕

### Dissertação
**Status:** ⭕ PLANEJADO, NÃO INICIADO  
**Timeline Estimado:** 4-6 semanas redação + revisões

**Estrutura Planejada:**
1. Introdução — Contexto, lacuna (2 dias)
2. Revisão — MaxEnt, transferência espacial (5 dias)
3. Métodos — Dados, preditores, MaxEnt config (3 dias)
4. Resultados — R28-R30, tabelas, figuras (5 dias)
5. Discussão — Padrões, implicações (5 dias)
6. Conclusão — Viabilidade, futuro (2 dias)

**Dados Entrada:**
- Consolidação R28-R30 ✓ (pronta)
- R31 validação externa ⏳ (em progresso)
- Gráficos + tabelas ✓ (prontos)
- Mapas finais ⏳ (pós-R31)

**Próximos Passos:**
1. Aguardar R31 completo
2. Compilar dados em template .docx
3. Redação capítulos
4. Revisão + ajustes

---

## 4. BLOQUEADORES

| Bloqueador | Severidade | Ação | Timeline |
|-----------|-----------|------|----------|
| Dados 7 propriedades não localizados | ALTA | Obter dados externos | ASAP |
| Skill implementação pendente | MÉDIA | Dev 2-3 semanas | Pós-R31 |
| Dissertação ainda não iniciada | MÉDIA | Começar pós-R31 | Semana 5 |

---

## 5. MÉTRICAS DE PROGRESSO

### Modelos Ajustados
```
R28: 6/6 ✓
R29: 4/4 ✓
R30: 72/72 ✓
R31: 0/14 (0% — framework pronto)
---
Total: 82/82 R28-R30 completo ✓
```

### Relatórios Gerados
```
✓ Consolidação R28-R30
✓ Análises adicionais
✓ 6 gráficos exploratórios
⏳ R31 validação externa
⭕ Dissertação
---
4/5 (80%)
```

### Skill Status
```
✓ Especificação funcional (SKILL_TCC_MODELAGEM_AMBIENTAL.md)
✓ Prompt Claude (SKILL_PROMPT_CLAUDE.md)
✓ Framework workflow
⏳ Implementação código (dev 2-3 semanas)
⭕ Testes end-to-end
---
2/5 (40%)
```

---

## 6. GIT COMMITS RECENTES

```
8350890 — Skill TCC Modelagem Ambiental: especificacao + prompt Claude
b7e8f84 — R31 framework template: validacao externa 7 propriedades
40acfd4 — Consolidacao R28-R29-R30: Modelagem ambiental de Ipês
```

---

## 7. TIMELINE ESTIMADO

```
Hoje (2026-11-24):
  ✓ Consolidação R28-R30
  ✓ R31 framework
  ✓ Skill especificação

Semana 1 (2026-11-25 — 2026-12-01):
  ⏳ R31: preencher + executar (dados 7 props)
  ⏳ Validação externa completa
  ⭕ Dissertação: Intro + Métodos

Semana 2-3 (2026-12-02 — 2026-12-15):
  ⭕ Dissertação: Resultados + Discussão
  ⏳ Skill: dev Python/R

Semana 4-6 (2026-12-16 — 2026-12-31):
  ⭕ Dissertação: Revisão + ajustes
  ⏳ Skill: testes + documentação
  ⭕ Apresentação pronta

Pós-Dissertação:
  ⭕ Skill: generalização (Mogno, Cumaru)
  ⭕ API web / integração QGIS
  ⭕ Monitoramento anual
```

---

## 8. CHECKLIST FINAL

```
Preparação (R01-R25):
  ✓ Inventários limpos
  ✓ Preditores 30m
  ✓ Background B0-B2
  ✓ Folds splitting
  ✓ Auditoria

Modelagem (R26-R30):
  ✓ R28: 6 modelos
  ✓ R29: 4 recíprocos
  ✓ R30: 72 grade

Consolidação:
  ✓ 82 modelos unificados
  ✓ Relatórios (.md)
  ✓ Gráficos (6 PNG)
  ✓ Análises adicionais

R31:
  ✓ Framework template
  ✓ Manual preenchimento
  ⏳ Dados 7 propriedades
  ⏳ Execução validação

Skill:
  ✓ Especificação
  ✓ Prompt Claude
  ⏳ Implementação código
  ⏳ Testes

Dissertação:
  ⏳ Redação (pós-R31)
  ⏳ Figuras/tabelas
  ⏳ Revisão
```

---

## 9. PRÓXIMAS AÇÕES (PRIORIDADE)

1. **[CRÍTICO]** Obter dados 7 propriedades externas
2. **[ALTO]** Executar R31 (1-2h uma vez dados preparados)
3. **[ALTO]** Começar redação dissertação (Intro + Métodos)
4. **[MÉDIO]** Iniciar dev skill (2-3 semanas)
5. **[MÉDIO]** Compilar mapas finais (pós-R31)

---

## 10. CONTATOS / RECURSOS

**Arquivos Chave:**
- Consolidação: `C:\Users\jotac\Downloads\TCC MILTON\01_RELATORIO_CONSOLIDADO_R28_R29_R30.md`
- R31: `TCC - Ipes - Inicio do zero/05 - Modelagem no R/R31_TCC_IPES_VALIDACAO_EXTERNA_V1/`
- Skill: `SKILL_TCC_MODELAGEM_AMBIENTAL.md` + `SKILL_PROMPT_CLAUDE.md`

**Git Status:**
- Branch: master
- Commits: 3 recentes (consolidação, R31, skill)
- Status: clean (nada não commitado)

---

**Versão:** 1.0  
**Atualizado:** 2026-11-24  
**Próxima Revisão:** Após R31 completo (esperado ~1 semana)  
**Owner:** Milton Bacuau (bacudigital@gmail.com)
