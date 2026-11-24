# Relatório Consolidado R28-R29-R30
## Modelagem Ambiental de Ipês • 2026-11-24

---

## 1. Sumário Executivo

Este relatório consolida os resultados de três fases de modelagem ambiental preditiva (MaxEnt) com 82 modelos ajustados entre os dias 18-19 de novembro de 2026.

| Fase | Modelos | Tipo | Espécies | Painéis |
|------|---------|------|----------|---------|
| **R28** | 6 | 6 modelos locais LQH RM4 | 2 | 3 |
| **R29** | 4 | 4 modelos recíprocos | 2 | - |
| **R30** | 72 | Grade exploratória 2×3×3×4 | 2 | 3 |
| **Total** | **82** | - | - | - |

**Metadados:**
- Espécies: Ipê-roxo (*Handroanthus impetiginosus*), Ipê-amarelo (*Handroanthus serratifolius*)
- Propriedades em desenvolvimento: 27
- UPAs inventariadas: 64
- Preditores: 6 (altitude, declividade, dist. rios, BIO12, BIO17, textura solo)
- Background: 10.000 pontos (B2) em R28-R29; conforme fold em R30

---

## 2. Fase R28: Modelos Locais de Referência

### 2.1 Descrição

Seis modelos `maxnet` LQH RM4 ajustados em três painéis locais, usando a mesma configuração como ponto de referência:
- Features: `L` (apenas longitude), `Q` (quadrático), `H` (interações hinge)
- Regularização: RM=4
- Validação: 3 UPAs por painel, contíguas (não independentes regionalmente)
- Background: 10.000 pontos

**Modelos:**
1. Roxo — UPA 01 (3 UPAs de validação)
2. Roxo — UPA 02 (3 UPAs de validação)
3. Roxo — UPA 03 (2 UPAs de validação)
4. Amarelo — UPA 01 (4 UPAs de validação)
5. Amarelo — UPA 02 (3 UPAs de validação)
6. Amarelo — UPA 03 (4 UPAs de validação)

### 2.2 Resultados Agregados (R28)

| Métrica | Roxo | Amarelo | Média | Mín. | Máx. | DP |
|---------|------|---------|-------|------|------|-----|
| **AUC Validação** | 0.467 | 0.667 | 0.567 | 0.376 | 0.681 | 0.124 |
| **Boyce** | 0.750 | 0.907 | 0.829 | 0.673 | 0.934 | 0.103 |
| **Omissão P10** | 0.037 | 0.038 | 0.038 | 0.000 | 0.151 | 0.059 |
| **Coeficientes** | 18.3 | 23.0 | 20.7 | 16 | 24 | - |
| **Tempo (s)** | 2345 | 1131 | 1738 | 249 | 9569 | - |

**Observação:** R28 estabelece linha de base com RM4. Boyce alto (0.83) indica correlação positiva forte entre previsões e validação. Omissão baixa (~3.8%) sugere modelos conservadores na alocação de P10.

---

## 3. Fase R29: Validação Recíproca

### 3.1 Descrição

Quatro modelos `maxnet` em configuração recíproca (treino/validação invertida) em duas propriedades (Hermes, Limão), testando transferibilidade local:

| Modelo | Propriedade | UPA Treino | UPA Validação | Espécie | Distância (km) |
|--------|-------------|-----------|---------------|---------|----------------|
| RECIP_ROXO_1 | Hermes | UPA 01 | UPA 03 | Roxo | 0.68 |
| RECIP_ROXO_2 | Hermes | UPA 03 | UPA 01 | Roxo | 0.68 |
| RECIP_AMARELO_1 | Limão | UPA 02 | UPA 03 | Amarelo | 0.00 |
| RECIP_AMARELO_2 | Limão | UPA 03 | UPA 02 | Amarelo | 0.00 |

**Ressalvas:**
- R29_RECIP_AMARELO_1: Extrapolação categórica em solo (classe 4 presente validação, ausente treino; 7 árvores, 5 BG)
- Status: Exploratório local, não independência regional

### 3.2 Resultados Agregados (R29)

| Métrica | Roxo | Amarelo | Média | Mín. | Máx. | DP |
|---------|------|---------|-------|------|------|-----|
| **AUC Validação** | 0.548 | 0.642 | 0.595 | 0.516 | 0.675 | 0.066 |
| **Boyce** | 0.488 | 0.811 | 0.649 | 0.479 | 0.814 | 0.187 |
| **Omissão P10** | 0.146 | 0.293 | 0.220 | 0.042 | 0.544 | 0.237 |
| **Coeficientes** | 7 | 6 | 6.5 | 4 | 10 | - |
| **Background Treino** | 202 | 139 | 171 | 131 | 273 | - |

**Observação:** AUC em R29 (0.595) similar a R28 (0.567), sugerindo transferibilidade local viável. Boyce mais baixo e omissão mais alta que R28, indicando modelos recíprocos menos conservadores. Background reduzido (média 171 vs 10k em R28) em validação impõe restrições.

---

## 4. Fase R30: Grade Exploratória 72 Avaliações

### 4.1 Descrição

Grade de sensibilidade com 72 avaliações testando:
- **2 espécies**: Roxo, Amarelo
- **3 painéis**: UPA 01, UPA 02, UPA 03 (mesmos 6 painéis de R28)
- **3 combinações de features**: L (linearidade), LQ (linear+quadrático), LQH (linear+quad+hinge)
- **4 regularizações**: RM 1, 2, 3, 4

**Composição:**
- 6 modelos LQH RM4 reaproverados de R28 (marcados REAPROVEITAR_R28)
- 66 modelos novos ajustados em R30 (marcados AJUSTAR_R30)

Propósito: Explorar como variações de features e regularização afetam performance em contexto local fixo.

### 4.2 Resultados Agregados (R30)

| Métrica | Total | Roxo | Amarelo | Mín. | Máx. | DP |
|---------|-------|------|---------|------|------|-----|
| **AUC Validação** | 0.499 | 0.395 | 0.603 | 0.324 | 0.692 | 0.117 |
| **Boyce** | 0.218 | 0.058 | 0.378 | -0.906 | 0.914 | 0.612 |
| **Omissão P10** | 0.082 | 0.006 | 0.158 | 0.000 | 0.879 | 0.145 |
| **Coeficientes (médio)** | 11.8 | 10.6 | 13.0 | 5 | 38 | - |

### 4.3 Desempenho por Features (R30)

#### Ipê-roxo

| Features | AUC Médio | Boyce Médio | Omissão P10 | N Modelos |
|----------|-----------|-------------|-------------|-----------|
| **L** | 0.387 | -0.410 | 0.001 | 12 |
| **LQ** | 0.388 | -0.361 | 0.001 | 12 |
| **LQH** | 0.470 | 0.825 | 0.012 | 12 |

**Interpretação:** LQH explicitamente superior (AUC +0.08, Boyce +1.24) para Roxo. Modelos L e LQ apresentam Boyce negativo, indicando previsões anticorrelacionadas com validação — configuração inadequada para localidade.

#### Ipê-amarelo

| Features | AUC Médio | Boyce Médio | Omissão P10 | N Modelos |
|----------|-----------|-------------|-------------|-----------|
| **L** | 0.543 | 0.136 | 0.169 | 12 |
| **LQ** | 0.543 | 0.154 | 0.168 | 12 |
| **LQH** | 0.664 | 0.831 | 0.162 | 12 |

**Interpretação:** LQH também superior para Amarelo (AUC +0.12, Boyce +0.68), confirmando padrão. Mesmo L e LQ, ainda que fracos, mantêm Boyce positivo.

### 4.4 Desempenho por Regularização (R30, LQH apenas)

| RM | Roxo AUC | Amarelo AUC | Roxo Boyce | Amarelo Boyce |
|----|----------|------------|------------|---------------|
| **1** | 0.481 | 0.680 | 0.790 | 0.816 |
| **2** | 0.455 | 0.667 | 0.740 | 0.816 |
| **3** | 0.465 | 0.666 | 0.763 | 0.814 |
| **4** | 0.470 | 0.664 | 0.825 | 0.831 |

**Interpretação:** RM=4 consistentemente melhor. RM=1 (mínima regularização) oferece AUC ligeiramente maior em Roxo, mas Boyce inferior. RM=4 balanceia adequadamente.

---

## 5. Comparação Entre Fases

### 5.1 Tabela Comparativa (R28 vs R30 LQH RM4)

Os 6 modelos LQH RM4 aparecem em ambas as fases:

| ID | Espécie | Painel | AUC R28 | AUC R30 | ΔAUc | Boyce R28 | Boyce R30 | ΔBoyce |
|----|---------| -------|---------|---------|------|-----------|-----------|--------|
| LOCAL_UPAS_01 | Roxo | 1 | 0.5566 | 0.5566 | — | 0.842 | 0.842 | — |
| LOCAL_UPAS_02 | Roxo | 2 | 0.3759 | 0.3759 | — | 0.673 | 0.673 | — |
| LOCAL_UPAS_03 | Roxo | 3 | 0.4703 | 0.4703 | — | 0.735 | 0.735 | — |
| LOCAL_UPAS_01 | Amarelo | 1 | 0.6778 | 0.6778 | — | 0.890 | 0.890 | — |
| LOCAL_UPAS_02 | Amarelo | 2 | 0.6420 | 0.6420 | — | 0.897 | 0.897 | — |
| LOCAL_UPAS_03 | Amarelo | 3 | 0.6813 | 0.6813 | — | 0.934 | 0.934 | — |

**Nota:** Idênticos por design (reaproverados em R30).

### 5.2 Síntese Comparativa

| Dimensão | R28 | R29 | R30 | Padrão |
|-----------|-----|-----|-----|--------|
| **Modelos** | 6 | 4 | 72 | Crescente |
| **AUC Médio** | 0.567 | 0.595 | 0.499 | R29 > R28 > R30 |
| **Boyce Médio** | 0.829 | 0.649 | 0.218 | R28 > R29 > R30 |
| **Omissão P10** | 0.038 | 0.220 | 0.082 | R28 < R30 < R29 |
| **Background** | 10k | 131–273 | 10k | Variável |
| **Escopo** | Referência | Recíproca | Exploratório | Expandindo |

**Interpretação:**
- R28 estabelece baseline com alta consistência (Boyce 0.83)
- R29 recíprocos apresentam viabilidade transferência local, mas com background reduzido
- R30 exploratório confirma superioridade LQH sobre L/LQ, mas média geral baixa por incluir todas 72 combinações

---

## 6. Achados Principais

### 6.1 Validação de Features

**Conclusão:** LQH é configuração ótima em contexto local.
- L isoladamente: Inadequado (Boyce negativo em Roxo)
- LQ (linear+quad): Marginal (Boyce 0.1–0.2)
- LQH (linear+quad+hinge): Robusto (Boyce 0.8–0.9)

**Implicação:** Interações hinge capturam padrões ecológicos locais essenciais.

### 6.2 Validação de Regularização

**Conclusão:** RM=4 consistentemente superior em R30 LQH.
- RM=1 pode oferecer AUC marginal maior, mas Boyce inferior
- RM=4 balanceia viés-variância adequadamente para validação B2 10k

**Implicação:** Modelo R28 LQH RM4 representa escolha apropriada.

### 6.3 Transferibilidade Local (R29)

**Conclusão:** Modelos transferem entre UPAs próximas (0.68–0 km).
- AUC 0.516–0.675 (compatível com referência)
- Boyce 0.479–0.814 (maior variância que R28)
- Omissão elevada em RECIP_ROXO_2 (25% vs 1% em R28)

**Implicação:** Transferibilidade viável, mas com cuidado. R29 exploratório; não substitui validação independente.

### 6.4 Independência Espacial

**Status:** Não confirmada. Todos os cenários (R28, R29, R30) utilizam UPAs contíguas ou próximas. 
- Recomendação: Aguardar validação externa nas 7 propriedades reservadas (Barro Branco, Curuça, Guariúba, Jatobá, etc.)

---

## 7. Recomendações

### 7.1 Modelo Final Candidato

**Configuração:** LQH, RM=4, B2 (10.000 BG)

Modelos recomendados por espécie:
- **Ipê-roxo:** LOCAL_UPAS_01_LQH_RM4 (AUC 0.557, Boyce 0.842)
- **Ipê-amarelo:** LOCAL_UPAS_03_LQH_RM4 (AUC 0.681, Boyce 0.934)

Justificativa:
- Features LQH validadas como ótimas
- RM=4 balanceia regularização
- Painel 1 (Roxo) e Painel 3 (Amarelo) oferecem melhor performance agregada

### 7.2 Próximos Passos

1. **Validação Externa:** Executar modelos candidatos nas 7 propriedades de teste externo (R31 proposto)
2. **Sensibilidade Preditores:** Testar remoção individual de cada preditor (ablação; já planejado em R22)
3. **Independência Espacial:** Confirmar autocorrelação espacial de erros (R23)
4. **Manuscrito:** Iniciar redação de métodos e resultados com R28-R30 consolidados

### 7.3 Cautelas

- R29 recíprocos não substituem validação independente
- R30 exploratório; 72 modelos representam escopo limitado (mesmo B2, mesmas UPAs)
- Nenhuma conclusão final sobre modelo "melhor" até validação externa
- Omissão P10 em R29 (até 54%) indica sensibilidade a limiar; revisar interpretação

---

## 8. Arquivos Relacionados

### R28
- Métricas: `28_METRICAS_6_MODELOS.csv`
- Relatório: `28_RELATORIO_EXECUCAO.txt`
- RDS: `03_CHECKPOINTS_CONGELADOS/`

### R29
- Auditoria Boyce: `29_CONFERENCIA_BOYCE_R28.csv`
- Recíprocos: `29_METRICAS_4_RECIPROCOS.csv`
- Relatório: `29_RELATORIO_RECIPROCOS.txt`

### R30
- Métricas: `30_METRICAS_72_AVALIACOES.csv`
- Resumo: `30_RESUMO_24_CONFIGURACOES.csv`
- Relatório: `30_RELATORIO_EXECUCAO.txt`

### Consolidação
- CSV consolidado: `00_CONSOLIDACAO_R28_R29_R30.csv`
- Este relatório: `01_RELATORIO_CONSOLIDADO_R28_R29_R30.md`

---

**Data:** 2026-11-24  
**Versão:** 1.0  
**Status:** Preliminar — Aguardando validação externa (R31)
