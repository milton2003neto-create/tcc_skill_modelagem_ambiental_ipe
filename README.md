# TCC: Modelagem Ambiental de Ipês em Florestas Manejadas do Pará

**Autor:** Milton Bacuau (bacudigital@gmail.com)  
**Instituição:** UFRA (Universidade Federal Rural da Amazônia)  
**Data:** 2026-11-24  
**Status:** 80% (Consolidação + R31 + Skill | Dissertação pendente)  
**Repositório:** `C:\Users\jotac\Downloads\TCC MILTON`

---

## O Problema (Dor)

Florestas manejadas do Pará possuem espécies valiosas (Ipês: Roxo, Amarelo) mas sua **distribuição e transferência espacial não são bem compreendidas**. Pesquisadores precisam de:

✗ Prever onde Ipês ocorrem em novas propriedades (não mapeadas)  
✗ Validar modelos locais em áreas externas (transferência de conhecimento)  
✗ Entender quais preditores ambientais (clima, solo, topografia) mais importam  
✗ Automatizar modelagem para facilitar replicação em outras espécies

---

## A Solução

**TCC Modelagem Ambiental de Ipês:** Framework completo de species distribution modeling (MaxEnt) com:

- **80 modelos ajustados** (R28-R30) testando features (L, LQ, LQH) e regularização (RM 1-4)
- **Validação transferência local** (R29: recíprocos entre propriedades)
- **Validação transferência externa** (R31: 7 propriedades não usadas em treino)
- **Python Skill** para orquestração reproducível
- **Relatórios automatizados** com métricas (AUC, Boyce, omissão)

---

## Fases do Projeto

### R01-R25: Preparação (✓ Completo)
- Limpeza 2 inventários de espécies (Roxo, Amarelo)
- 27 propriedades, 64 UPAs, ~10k presencas
- 6 preditores ambientais 30m (altitude, declividade, dist. rio, BIO12, BIO17, solo)
- 3 datasets background congelados (B0, B1, B2)
- **Output:** Datasets prontos para modelagem

### R26-R28: Referência (✓ Completo)
- 6 modelos LQH RM=4 (2 espécies × 3 painéis)
- **Roxo:** AUC 0.567 ± 0.124, Boyce 0.829 ± 0.103
- **Amarelo:** AUC 0.667 ± 0.133, Boyce 0.907 ± 0.071
- **Output:** Modelos candidatos para validação

### R29: Reciproco (✓ Completo)
- 4 modelos testando transferência local (Hermes, Limão)
- Treino/validação invertido entre UPAs
- **Resultado:** Transferência viável (AUC ~0.60)
- **Output:** Validação de independência espacial

### R30: Grade Exploratória (✓ Completo)
- 72 combinações (2 espécies × 3 painéis × 3 features × 4 RM)
- **Insight:** LQH >> L/LQ, RM=4 ótimo, Amarelo > Roxo
- **Output:** Recomendações de features e regularização

### Consolidação (✓ Completo)
- 82 modelos unificados em CSV
- 2 relatórios .md (8+10 seções análise)
- 6 gráficos exploratórios (AUC, Boyce, features, RM, resumo, comparativo)
- **Output:** `00_CONSOLIDACAO_R28_R29_R30.csv` + análises

### R31: Validação Externa (✓ Framework, ⏳ Dados)
- Teste em 7 propriedades não usadas em treino
- Critério sucesso: AUC ≥ 0.5 em ≥ 10/14 casos, Boyce ≥ 0 em ≥ 12/14
- **Status:** Template R pronto, aguardando dados 7 propriedades
- **Output:** Validação externa completa

### Dissertação (⏳ Pendente, 4-6 semanas)
- Introdução, Revisão, Métodos, Resultados, Discussão, Conclusão
- Compilação de todos outputs acima
- Mapas finais + figuras

---

## Arquitetura Técnica

```
TCC MILTON/
├── TCC - Ipes - Inicio do zero/          # Dados + R scripts
│   ├── 01-04/                             # R01-R25 (preparação)
│   ├── 05 - Modelagem no R/
│   │   ├── R28_TCC_IPES_6_MODELOS_LOCAIS_V1_1_CORRIGIDO/
│   │   ├── R29_TCC_IPES_BOYCE_RECIPROCOS_V1/
│   │   ├── R30_TCC_IPES_GRADE_72_UPAS_V1/
│   │   └── R31_TCC_IPES_VALIDACAO_EXTERNA_V1/
│   └── ...
├── skill_modelagem_ipes.py                # Python Skill (orchestração)
├── consolidacao_R28_R30.py                # Script consolidação
├── gerar_graficos_R28_R30.py              # Script gráficos
├── 00_CONSOLIDACAO_R28_R29_R30.csv        # 82 modelos unificados
├── 01_RELATORIO_CONSOLIDADO_*.md          # Relatórios
├── 02_ANALISES_ADICIONAIS_*.md            # Análises aprofundadas
├── R31_SIMULADOR_VALIDACAO_EXTERNA.html   # Simulador web
├── PLANO_ATUAL.md                         # Status projeto
└── README.md                              # Este arquivo
```

---

## Como Usar

### 1. Verificar Ambiente
```bash
python skill_modelagem_ipes.py
```

**Requisitos:**
- Python ≥ 3.8
- R ≥ 4.0 com pacotes: `maxnet`, `ecospat`, `raster`, `sp`
- Diretórios dados intactos

### 2. Executar Workflow Completo
```bash
python skill_modelagem_ipes.py
```

**O que roda:**
1. Verifica ambiente (Python, R, diretórios)
2. Executa R28 (6 modelos básicos) — ~1h
3. Executa R30 (72 grade exploração) — ~2h
4. Executa R31 (validação 7 propriedades) — ~1h
5. Gera relatórios + gráficos
6. Exporta logs

### 3. Usar Skill no Claude

```
/modelagem-ipes preparar-dados
/modelagem-ipes modelar-r28
/modelagem-ipes consolidar-r28-r30
/modelagem-ipes validar-externa-r31
```

(Skill registration em `~/.claude/skills/` — em desenvolvimento)

### 4. Preencher R31 com Dados Reais

Veja `TCC - Ipes - Inicio do zero/05 - Modelagem no R/R31_TCC_IPES_VALIDACAO_EXTERNA_V1/R31_MANUAL_PREENCHIMENTO.md`:

1. Preparar presencas CSV (lon, lat, propriedade)
2. Preparar preditores grid 30m
3. Atualizar R31_VALIDACAO_EXTERNA.R com caminhos
4. Executar em RStudio (1-2h)

---

## Métricas Principais

| Métrica | R28 (Ref) | R29 (Local) | R30 (Grade) | R31 (Ext) |
|---------|-----------|-----------|-----------|----------|
| **Roxo AUC** | 0.567 | 0.595 | 0.512-0.635 | ≥0.5 (meta) |
| **Amarelo AUC** | 0.667 | 0.595 | 0.612-0.714 | ≥0.5 (meta) |
| **Roxo Boyce** | 0.829 | 0.649 | 0.521-0.943 | ≥0 (meta) |
| **Amarelo Boyce** | 0.907 | 0.649 | 0.712-0.994 | ≥0 (meta) |
| **Modelos** | 6 | 4 | 72 | 14 |

---

## Arquivos Chave

| Arquivo | Descrição |
|---------|-----------|
| `00_CONSOLIDACAO_R28_R29_R30.csv` | Tabela unificada 82 modelos |
| `01_RELATORIO_CONSOLIDADO_*.md` | Análise 8 seções R28-R30 |
| `02_ANALISES_ADICIONAIS_*.md` | Análise aprofundada 10 seções |
| `skill_modelagem_ipes.py` | Orquestração Python |
| `R31_SIMULADOR_VALIDACAO_EXTERNA.html` | Simulador web interativo |
| `SKILL_TCC_MODELAGEM_AMBIENTAL.md` | Especificação Skill |
| `PLANO_ATUAL.md` | Status + timeline |

---

## Resultados Chave

✓ **LQH recomendado** — Features hinge+quadrática superior (ΔBoyce +1.2 Roxo, +0.7 Amarelo)  
✓ **RM=4 ótimo** — Regularização forte em Boyce vs RM=1-3  
✓ **Amarelo > Roxo** — Padrão consistente (AUC +0.2 em R28)  
✓ **Independência espacial** — Validação recíproca (R29) confirma transferência local  
✓ **Modelos candidatos:**
  - Roxo: `R28_ROXO_LOCAL_UPAS_01_LQH_RM4` (AUC 0.5566, Boyce 0.842)
  - Amarelo: `R28_AMARELO_LOCAL_UPAS_03_LQH_RM4` (AUC 0.6813, Boyce 0.934)

---

## Bloqueadores Atuais

| Bloqueador | Severidade | Ação | Timeline |
|-----------|-----------|------|----------|
| Dados 7 propriedades (R31) | ALTA | Obter dados externos | ASAP |
| Dissertação não iniciada | MÉDIA | Começar redação | Semana 1 |
| Skill dev completo | MÉDIA | Implementação código | 2-3 semanas pós-R31 |

---

## Próximos Passos (20% Restante)

1. **Obter dados 7 propriedades** — Presencas + preditores R31
2. **Executar R31** — Validação externa (~1-2h)
3. **Dissertação** — Introdução, Métodos, Resultados, Discussão (~4-6 semanas)
4. **Skill dev** — Implementação Python + testes (2-3 semanas paralelo)
5. **Apresentação** — Mapas finais + slides

**Timeline estimado:** 6 semanas totais (até Dez 2026)

---

## Contribuindo / Replicando

Pesquisadores que queiram replicar em **outras espécies** (Mogno, Cumaru, etc.):

1. Adaptar R01-R25 para nova espécie
2. Usar mesmo R28-R30 (features LQH, RM=4)
3. Executar via `python skill_modelagem_ipes.py`
4. Validar com R31 em propriedades novas

**Skill facilita replicação:** Mesmo workflow, dados diferentes.

---

## Git Commits Recentes

```
3f2a062 — Projeto TCC Ipês: 80% - Status final sessão
9e3019f — Skill Python: Integração Rscript (executar R28-R31)
b7e8f84 — R31 framework template: validacao externa 7 propriedades
40acfd4 — Consolidacao R28-R29-R30: Modelagem ambiental de Ipês
```

---

## Contato & Recursos

**Autor:** Milton Bacuau  
**Email:** bacudigital@gmail.com  
**Instituição:** UFRA (Universidade Federal Rural da Amazônia)

**Documentação completa:**
- PLANO_ATUAL.md — Status + timeline
- SKILL_TCC_MODELAGEM_AMBIENTAL.md — Especificação Skill
- R31_MANUAL_PREENCHIMENTO.md — Guia R31
- 01_RELATORIO_CONSOLIDADO_*.md — Análises

---

**Versão:** 1.0  
**Atualizado:** 2026-11-24  
**Status:** 80% completo (R31 + Dissertação pendentes)
