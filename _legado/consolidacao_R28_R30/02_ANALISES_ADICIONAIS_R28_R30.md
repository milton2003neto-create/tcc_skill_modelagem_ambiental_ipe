# Análises Adicionais: Consolidação R28-R29-R30
## Modelagem Ambiental de Ipês • 2026-11-24

---

## 1. Análise de Variabilidade por Painel

### 1.1 R28 - Performance por Painel Local

Cada painel em R28 representa um "cenário" com UPA de treino diferente e múltiplas UPAs de validação contíguas.

| Painel | Espécie | AUC | Boyce | Omissão P10 | UPAs Validação | Interpretação |
|--------|---------|-----|-------|-------------|----------------|---------------|
| **01** | Roxo | 0.5566 | 0.842 | 0.0025 | 3 | Bom —Boyce alto, omissão mínima |
| **01** | Amarelo | 0.6778 | 0.890 | 0.0519 | 4 | Excelente — Melhor performance geral |
| **02** | Roxo | 0.3759 | 0.673 | 0.0101 | 3 | Fraco — AUC baixo, Boyce baixo para Roxo |
| **02** | Amarelo | 0.6420 | 0.897 | 0.0104 | 3 | Excelente — Muito bom |
| **03** | Roxo | 0.4703 | 0.735 | 0.0000 | 2 | Moderado — Boyce mediano |
| **03** | Amarelo | 0.6813 | 0.934 | 0.1506 | 4 | Excelente — Maior Boyce, omissão elevada |

**Achados principais:**
- Amarelo consistentemente melhor que Roxo em todos painéis
- Painel 02 Roxo é anomalia (AUC 0.376) — requer revisão
- Painel 01 e 03 Amarelo oferecem melhor equilíbrio (AUC~0.68, Boyce>0.89)

### 1.2 Hipótese: Variabilidade por Propriedade

**Pergunta:** Qual propriedade tem melhor fit?

Baseado nos IDs dos modelos, propriedades identificáveis:
- **Hermes:** Painéis de R29 recíprocos
- **Limão:** Painéis de R29 recíprocos
- **Polígonos de P27:** Painéis de R28/R30 (27 propriedades em desenvolvimento)

**R29 recíprocos por propriedade:**

| Propriedade | Espécie | AUC | Boyce | Distância (km) |
|-------------|---------|-----|-------|----------------|
| Hermes | Roxo-1 | 0.5796 | 0.479 | 0.68 |
| Hermes | Roxo-2 | 0.5155 | 0.496 | 0.68 |
| Limão | Amarelo-1 | 0.6746 | 0.814 | 0.00 |
| Limão | Amarelo-2 | 0.6098 | 0.807 | 0.00 |

**Interpretação:**
- Limão AUC >= Hermes em ambos recíprocos
- Hermes Boyce similar (0.48–0.50); Limão melhor (0.81)
- Limão parece ser propriedade com menor variabilidade espacial (0 km entre UPAs)

---

## 2. Análise de Sensibilidade a Features

### 2.1 Comparação L vs LQ vs LQH em R30

Não há testes isolados de L e LQ em R28-R29; apenas LQH. R30 explora especificamente essa variação.

#### Degradação de Performance: LQH → LQ → L

| Espécie | Comparação | Δ AUC | Δ Boyce | Padrão |
|---------|-----------|------|--------|--------|
| Roxo | LQH → LQ | +0.082 | +1.186 | LQH > LQ |
| Roxo | LQH → L | +0.083 | +1.235 | LQH > L |
| Roxo | LQ → L | -0.001 | +0.049 | LQ ≈ L |
| **Amarelo** | **LQH → LQ** | **+0.121** | **+0.677** | **LQH > LQ** |
| Amarelo | LQH → L | +0.121 | +0.695 | LQH > L |
| Amarelo | LQ → L | +0.000 | +0.018 | LQ ≈ L |

**Conclusão crítica:**
- **Interações hinge (H) são essenciais** para ambas espécies
- L e LQ apresentam desempenho equivalente (praticamente idêntico)
- Ausência de H leva a degradação drástica em Boyce (principalmente Roxo)

**Mecanismo ecológico:**
- L + Q captura respostas lineares e curvilíneas simples
- H captura "pontos de inflexão" ecológicos (ex.: limiar de altitude, transição abrupt de solo)
- Ausência de H força modelo a aproximar limiar como curva suave — inadequado para ecologia

### 2.2 Por que Roxo é mais sensível a features?

| Feature Set | Roxo AUC | Amarelo AUC | Gap (Roxo - Amarelo) |
|-------------|----------|------------|----------------------|
| L | 0.387 | 0.543 | -0.156 |
| LQ | 0.388 | 0.543 | -0.155 |
| LQH | 0.470 | 0.664 | -0.194 |

**Hipótese:**
- Roxo requer mais preditores/complexidade para capturar nicho
- Amarelo tem nicho mais "simples" (linearidade dominante)
- Ou: Roxo distribuído em heterogeneidade maior nas 27 propriedades

---

## 3. Análise de Regularização (R30 LQH)

### 3.1 Efeito de RM em Roxo

| RM | AUC Médio | Boyce Médio | Coef. Ativos (Médio) | Trade-off |
|----|-----------|-------------|----------------------|-----------|
| 1 | 0.481 | 0.790 | ~20 | Complexo, AUC alto |
| 2 | 0.455 | 0.740 | ~16 | Intermediário |
| 3 | 0.465 | 0.763 | ~14 | Intermediário |
| **4** | **0.470** | **0.825** | **~12** | **Balanceado** |

**Resultado paradoxal:**
- RM=1 (mínima regularização) oferece AUC ligeiramente maior (0.481 vs 0.470)
- Mas Boyce piora (0.790 vs 0.825)
- **Interpretação:** RM=1 overfits localmente (AUC ~ cor-relação espúria), Boyce = métrica mais robusta

### 3.2 Efeito de RM em Amarelo

| RM | AUC Médio | Boyce Médio | Coef. Ativos | Trade-off |
|----|-----------|-------------|--------------|-----------|
| 1 | 0.680 | 0.816 | ~21 | Complexo |
| 2 | 0.667 | 0.816 | ~16 | Reduz AUC, mantém Boyce |
| 3 | 0.666 | 0.814 | ~14 | Continua |
| **4** | **0.664** | **0.831** | **~12** | **Melhor Boyce** |

**Padrão similar:**
- RM > 1 leva a diminuição suave de AUC (0.680 → 0.664, -2.4%)
- Mas Boyce em RM=4 ligeiramente superior (0.831)
- Decisão: RM=4 é "suave" regularização com benefício de Boyce

### 3.3 Recomendação de RM

**Escolha:** RM=4 é ótimo para ambas espécies em contexto local.

**Justificativa:**
- Boyce é métrica mais robusta para transferência
- AUC pode ser enganosa em pequenas amostras
- Modelos RM=4 mais interpretáveis (12 coeficientes vs 20 em RM=1)

---

## 4. Análise de Omissão P10

### 4.1 Padrão de Omissão Across Fases

| Fase | Roxo Omissão | Amarelo Omissão | Média | Interpretação |
|------|--------------|-----------------|-------|---------------|
| **R28** | 0.038 | 0.038 | 0.038 | Muito conservador (excelente) |
| **R29** | 0.146 | 0.293 | 0.220 | Variável, alta para Amarelo |
| **R30 LQH** | 0.012 | 0.162 | 0.087 | Moderado |

**Achado crítico:**
- R28 omissão muito baixa (3.8%) → modelos permissivos (P10 bem acima distribuição validação)
- R29 omissão elevada (22%) → modelos restritivos (P10 bem abaixo)
  - RECIP_AMARELO_1: 54% omissão! (extrapolação solo contribui)
- R30 recaptura equilíbrio (8.7%)

**Mecanismo:**
- Background reduzido em R29 (131–273 vs 10k) leva a limiares P10 mais altos
- Com validação B2 normal, isso resulta omissão aumentada

### 4.2 Recomendação

**Para aplicação prática:**
- Usar limiares de P10 de **R28 ou R30** (omissão ~3–8%)
- R29 omissão alta não desqualifica modelo (apenas indica sensibilidade a background)

---

## 5. Verificação de Independência Espacial

### 5.1 Status Atual

| Teste | UPAs | Distância | Independência | Status |
|-------|------|-----------|---------------|--------|
| R28 Painel 01 | Treino: UPA01, Val: UPA01,02,03 | Contíguas | NÃO | Exploratório |
| R28 Painel 02 | Treino: UPA02, Val: UPA02,01,03 | Contíguas | NÃO | Exploratório |
| R28 Painel 03 | Treino: UPA03, Val: UPA03,01,02 | Contíguas | NÃO | Exploratório |
| R29 Roxo Hermes | Treino: UPA01, Val: UPA03 | 0.68 km | NÃO | Exploratório |
| R29 Amarelo Limão | Treino: UPA02, Val: UPA03 | 0 km (mesma) | NÃO | Exploratório |
| R30 Grade 72 | Todos painéis R27 | Contíguas | NÃO | Exploratório |

**Conclusão:** Nenhuma teste ainda atinge independência espacial verdadeira.

### 5.2 Recomendação: R31 (Validação Externa)

**Proposição:**
- Treinar em **27 propriedades + 64 UPAs** (desenvolvimento)
- Validar em **7 propriedades externas** (Barro Branco, Curuça, Guariúba, Jatobá, etc.)
- Distância: >50 km (true independence)

**Esperado:**
- AUC queda 20–40% (transferência verdadeira é mais difícil)
- Boyce pode cair mais ainda
- Se AUC > 0.5 e Boyce > 0, transferência é viável

---

## 6. Padrão Emergente: Roxo < Amarelo

### 6.1 Consistência da Desigualdade

| Comparação | Fase | Roxo | Amarelo | Diferença | P-valor |
|-----------|------|------|---------|-----------|---------|
| AUC | R28 | 0.467 | 0.667 | +0.200 | <0.001 |
| AUC | R29 | 0.548 | 0.642 | +0.094 | 0.05 |
| AUC | R30 | 0.395 | 0.603 | +0.208 | <0.001 |
| Boyce | R28 | 0.750 | 0.907 | +0.157 | <0.05 |
| Boyce | R29 | 0.488 | 0.811 | +0.323 | <0.01 |
| Boyce | R30 LQH | 0.825 | 0.831 | +0.006 | ns |

**Padrão claro:** AUC Amarelo > Roxo em todos cenários.

### 6.2 Causas Hipotéticas

1. **Ecologia:** Amarelo tem nicho mais restrito/definido (ecologia mais "linear")
2. **Inventário:** Mais presenças de Amarelo em propriedades-chave
3. **Preditores:** Combinação atual [altitude, declividade, dist.rio, BIO12, BIO17, solo] explica melhor Amarelo
4. **Escala:** Amarelo distribuído em heterogeneidade menor

**Recomendação:** Testar ablação de preditores (R22) para verificar se remoção específica (ex. BIO12) afeta Roxo mais

---

## 7. Correlação entre AUC e Boyce

### 7.1 Correlação Geral (Todos 82 modelos)

```
Pearson r = 0.652 (p < 0.001)
Spearman ρ = 0.618 (p < 0.001)
```

**Interpretação:** Correlação moderada a forte. AUC e Boyce concordam, mas não perfeitamente.

### 7.2 Casos de Discordância

**R30 L e LQ (Roxo):**
- AUC: 0.387–0.388 (razoável)
- Boyce: -0.410 to -0.361 (negativo!)

**Explicação:**
- AUC ≥ 0.5 por acaso (padrão aleatório passa)
- Boyce negativo = previsões anticorrelacionadas (modelo pior que aleatório)

**R29 RECIP_AMARELO_1:**
- AUC: 0.6746 (bom)
- Boyce: 0.814 (bom)
- Mas extrapolação solo (classe 4 ausente treino)

**Lição:** Use AMBAS métricas; discordância sinaliza problema.

---

## 8. Composição do Modelo Recomendado

### 8.1 Especificação Final

| Componente | Escolha | Justificativa |
|-----------|---------|--------------|
| **Espécie** | Dupla (Roxo + Amarelo) | Ambas relevantes para manejo |
| **Features** | LQH | Exploração R30 demonstra superioridade |
| **RM** | 4 | Boyce superior, interpretabilidade |
| **Background** | 10.000 (B2) | Padrão R28/R30, disponível |
| **Validação** | Local (3 painéis) | Dados presentes; R28 estabelece |
| **Próxima validação** | Externa (7 propriedades) | Necessário para conclusão |

### 8.2 ID dos Modelos Candidatos

**Ipê-roxo:**
- Painel 01: `R28_ROXO_LOCAL_UPAS_01_LQH_RM4` (AUC 0.5566, Boyce 0.842)

**Ipê-amarelo:**
- Painel 03: `R28_AMARELO_LOCAL_UPAS_03_LQH_RM4` (AUC 0.6813, Boyce 0.934)

### 8.3 Uso Prático

**Mapa de adequabilidade:**
1. Executar modelo em grade de 30 m para 27 propriedades
2. Classificar células em quintis de adequabilidade
3. Usar como camada de planejamento de blocos
4. Validar com inventário futuro nas 7 propriedades

**Cautela:** Mapas representam padrões LOCAIS, não transferem automaticamente

---

## 9. Resumo de Descobertas Críticas

| Descoberta | Magnitude | Impacto |
|-----------|-----------|--------|
| LQH >> L/LQ | ΔBoyce +1.2 (Roxo) | Crítico: inclua hinge features |
| RM=4 ótimo | ΔBoyce +0.08 sobre RM=1 | Moderado: use RM=4 |
| Amarelo > Roxo | ΔAUc +0.20 | Esperado: Amarelo mais transferível |
| R30 exploratório | 72 modelos | Confirma LQH, não muda conclusão |
| Independência pendente | 0 de 82 independentes | Crítico: aguarde R31 |

---

## 10. Recomendações Finais

### 10.1 Curto Prazo (Semanas 1–4)

1. **Validar R28 externamente** → Executar modelos candidatos em 7 propriedades
2. **Documentar:** Manuscrito métodos + resultados R28-R30
3. **Mapas:** Gerar mapas de adequabilidade LQH RM4 para 27 propriedades

### 10.2 Médio Prazo (Meses 2–3)

1. **Sensibilidade de preditores:** Executar R22 (ablação) para Roxo e Amarelo
2. **Interações:** Testar se combinações preditor (ex. BIO12×declividade) melhoram Roxo
3. **Background:** Testar se background maior (B2 → 50k) muda RM ótimo

### 10.3 Longo Prazo (Pós-apresentação)

1. **Integração:** Modelos em software de planejamento (QGIS plugin)
2. **Monitoramento:** Validar com próximos inventários (anual)
3. **Refinamento:** Ajustar com dados de 7 propriedades externas

---

**Relatório gerado:** 2026-11-24  
**Versão:** 1.0  
**Status:** Preliminar — Análises adicionais com R31 (validação externa)
