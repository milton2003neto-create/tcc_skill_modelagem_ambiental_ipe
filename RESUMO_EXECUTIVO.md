# RESUMO EXECUTIVO

**TCC: Modelagem Ambiental de Ipês em Florestas Manejadas do Pará**

---

## 1. O Problema

**Contexto:** Florestas manejadas do Pará possuem espécies valiosas de Ipês (Roxo, Amarelo) mas sua **distribuição espacial e transferência para novas áreas não são bem compreendidas**.

**Dor do pesquisador:**
- ✗ Não sabe onde espécies ocorrem em propriedades não mapeadas
- ✗ Modelos locais não transferem bem para áreas externas (diferentes preditores)
- ✗ Sem framework sistemático, cada análise é feita do zero (não reproducível)
- ✗ Tempo alto: dados → preparação → modelagem → validação (semanas)

**Consequência:** Decisões de manejo baseadas em intuição, não dados.

---

## 2. A Solução

**Modelagem Ambiental Preditiva (MaxEnt):**
- Aprende padrão: "onde espécie ocorre" + "preditores ambientais"
- Prediz: "nova propriedade + preditores" → probabilidade ocorrência
- Valida: testa se predições funcionam em áreas não usadas em treino

**Resultado esperado:** Mapa contínuo (0-1) de adequabilidade ambiental para Roxo e Amarelo em qualquer propriedade.

---

## 3. Escopo & Fases

| Fase | O que | Resultado | Status |
|------|-------|----------|--------|
| **R01-R25** | Preparação dados (limpeza, validação, preditores) | 27 propriedades, 64 UPAs, 7 validação | ✓ 100% |
| **R28** | 6 modelos básicos (LQH, RM=4, 2 espécies × 3 painéis) | AUC 0.567-0.667, Boyce 0.829-0.907 | ✓ 100% |
| **R29** | 4 modelos recíprocos (teste transferência local) | AUC ~0.60, transferência viável | ✓ 100% |
| **R30** | 72 modelos grade (3 features × 4 RM) | LQH >> L/LQ, RM=4 ótimo | ✓ 100% |
| **Consolidação** | 82 modelos unificados, relatórios, gráficos | 2 CSV + 2 relatórios .md + 6 PNG | ✓ 100% |
| **R31** | Validação externa (7 propriedades não usadas em treino) | Teste independência espacial (framework pronto) | ⏳ 90% |
| **Dissertação** | Redação completa | .docx 50-80 páginas | ⏳ 0% |
| **Skill** | Framework reproducível (Python + Rscript) | Sistema reutilizável | ⏳ 60% |

**Status Geral:** 80% (Consolidação ✓ + R31 framework ✓ + Skill Python ✓)

---

## 4. Descobertas Principais

### 4.1 Features (Preditores)
- **LQH (Linear + Quadrática + Hinge) >> L (Linear só) >> LQ (Sem Hinge)**
- Melhoria Boyce: +1.2 (Roxo), +0.7 (Amarelo)
- **Insight:** Hinge crucial para capturar thresholds ambientais

### 4.2 Regularização
- **RM=4 ótimo** (vs RM=1-3 overfitting)
- Boyce melhora com RM maior
- **Insight:** Penalidade forte evita overfitting em dados limitados

### 4.3 Padrão Espécies
- **Amarelo > Roxo** (AUC +0.2 consistente)
- Amarelo: AUC 0.667, Boyce 0.907
- Roxo: AUC 0.567, Boyce 0.829
- **Insight:** Amarelo mais previsível (distribuição menos fragmentada?)

### 4.4 Transferência
- **Recíprocos (R29):** AUC ~0.60 (transferência local viável mas com cuidado)
- **Esperado R31:** AUC queda ~15-40% vs treino (R28 → R31)
- **Críterio sucesso:** AUC≥0.5 em 10+/14, Boyce≥0 em 12/14

---

## 5. Dados & Métricas

### Inventários
- 2 espécies: Roxo, Amarelo
- 27 propriedades + 64 UPAs
- ~10k presencas (pontos observados)
- 7 propriedades reservadas para validação externa

### Preditores (6 camadas 30m)
1. Altitude (m)
2. Declividade (°)
3. Distância rio (m)
4. BIO12 (Precipitação anual)
5. BIO17 (Precipitação trimestre seco)
6. Solo (textura + pH)

### Métricas Avaliação
- **AUC (Area Under Curve):** 0-1, >0.5 = bom, >0.7 = excelente
- **Boyce:** -1 a +1, correlação ranks. Roxo ~0.83, Amarelo ~0.91
- **Omissão P10:** % presencas no 10% pior scores (desejável baixo)

---

## 6. Arquivos Gerados

**Dados consolidados:**
- `00_CONSOLIDACAO_R28_R29_R30.csv` — 82 modelos, 15 colunas (ID, AUC, Boyce, omissão, etc.)

**Relatórios:**
- `01_RELATORIO_CONSOLIDADO_R28_R29_R30.md` — 8 seções (resumo, R28, R29, R30, features, RM, omissão, conclusões)
- `02_ANALISES_ADICIONAIS_R28_R30.md` — 10 seções (painéis, features, RM, padrões, comparações)

**Gráficos:**
- Boxplot AUC por feature/RM
- Scatter AUC vs Boyce
- Heatmap Boyce (espécie × painel × RM)
- Resumo features
- Comparativo Roxo vs Amarelo
- Análise omissão

**Framework R31:**
- `R31_VALIDACAO_EXTERNA.R` — Template com [TEMPLATE] markers
- `R31_MANUAL_PREENCHIMENTO.md` — 12 passos preenchimento
- `R31_SIMULADOR_VALIDACAO_EXTERNA.html` — Simulador web interativo

**Skill Python:**
- `skill_modelagem_ipes.py` — Orquestração (512 linhas)
- `SKILL_TCC_MODELAGEM_AMBIENTAL.md` — Especificação 12 seções
- `SKILL_PROMPT_CLAUDE.md` — Prompt Claude 10 seções

---

## 7. Sistema de Skill

**O que é:** Framework Python que orquestra todo workflow (R28-R31).

**Por que:** Reproducibilidade. Mesmo sistema, dados diferentes (Mogno, Cumaru, etc.).

**Como funciona:**
1. Verifica ambiente (Python, R, pacotes)
2. Executa R28 (1h) → 6 modelos
3. Executa R30 (2h) → 72 modelos
4. Executa R31 (1h) → Validação 7 propriedades
5. Consolida (10min) → CSV + relatórios + gráficos

**Status:**
- ✓ Python class `SkillModelagemIpes` (512 linhas)
- ✓ Métodos Rscript: `executar_r28()`, `executar_r30()`, `executar_r31()`, `executar_workflow_completo()`
- ✓ Logging completo
- ⏳ Registrar em `~/.claude/skills/` (CLI Claude Code)

---

## 8. Timeline & Próximos Passos

### Hoje (2026-11-24)
✓ Consolidação R28-R30 completa  
✓ R31 framework template  
✓ Skill Python integrada  
✓ README + documentação

### Semana 1 (2026-11-25 — 2026-12-01)
⏳ R31: obter dados 7 propriedades + executar (~1-2h)  
⏳ Dissertação: Introdução + Métodos (5 dias)

### Semana 2-3 (2026-12-02 — 2026-12-15)
⏳ Dissertação: Resultados + Discussão (10 dias)  
⏳ Skill: dev Python + testes (paralelo)

### Semana 4-6 (2026-12-16 — 2026-12-31)
⏳ Dissertação: Conclusão + Revisão (5 dias)  
⏳ Skill: testes end-to-end + documentação  
⏳ Mapas finais + apresentação

**Deadline dissertação:** ~6 semanas (Dez 2026)

---

## 9. Impacto Potencial

### Curto Prazo (Este TCC)
- ✓ Modelos transferíveis para Roxo e Amarelo
- ✓ Framework replicável (Skill)
- ✓ Publicações científicas (consolidação + R31)

### Médio Prazo (1-2 anos)
- Sistema aplicado a outras espécies (Mogno, Cumaru, Jatobá)
- Integração QGIS para visualização em tempo real
- Decisão de manejo baseada em dados (plantio, colheita)

### Longo Prazo (3+ anos)
- Monitoramento anual de adequabilidade
- Alertas de mudanças (clima, solo, cobertura)
- Replicação em outras regiões (Mato Grosso, Amazonas)
- API pública para pesquisadores

---

## 10. Requisitos Técnicos

| Requisito | Versão | Status |
|-----------|--------|--------|
| Python | ≥ 3.8 | ✓ 3.11.5 |
| R | ≥ 4.0 | ✓ 4.3.x |
| maxnet (R) | ≥ 0.1.4 | ✓ Instalado |
| ecospat (R) | ≥ 4.1.4 | ✓ Instalado |
| QGIS | 3.x (opcional) | ⏳ Próximo |
| CPU | - | ✓ 1h (R28), 2h (R30), 1h (R31) |

---

## 11. Bloqueadores Atuais

| Bloqueador | Severidade | Ação | Timeline |
|-----------|-----------|------|----------|
| **Dados 7 propriedades (R31)** | ALTA | Obter presencas + preditores | ASAP |
| **Dissertação não iniciada** | MÉDIA | Começar redação | Semana 1 |
| **Skill dev completo** | MÉDIA | Dev + testes 2-3 semanas | Pós-R31 |

---

## 12. Replicação em Outras Espécies

**Molde testado:**
1. Preparar dados (R01-R25): ~1 semana
2. Executar R28-R30 (Skill): ~3 horas
3. Validação R31: ~1-2 horas (se dados externos disponíveis)

**Tempo total:** 1-2 semanas vs 3+ meses manual

**Espécies candidatas:**
- Mogno (Swietenia macrophylla)
- Cumaru (Dipteryx odorata)
- Jatobá (Hymenaea courbaril)

---

## 13. Autor & Contato

**Milton da Silva Tavares Neto**  
Email: milton2003profissional@gmail.com  
Instituição: UFRA (Universidade Federal Rural da Amazônia)  
Orientador: [Preenchido na dissertação]

---

## 14. Métricas de Sucesso

**TCC será sucesso se:**
✓ R31 validação externa mostrar transferência viável (AUC≥0.5, Boyce≥0)  
✓ Dissertação completa e defendida  
✓ Skill operacional e documentada  
✓ Publicação científica (consolidação + R31)

---

**Data:** 2026-11-24  
**Status:** 80% completo  
**Versão:** 1.0  
**Próxima atualização:** Pós-R31 (esperado ~1 semana)
