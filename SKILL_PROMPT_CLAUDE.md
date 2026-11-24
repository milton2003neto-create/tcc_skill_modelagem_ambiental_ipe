# Instruções Claude para Skill: Modelagem Ambiental Ipês

## Contexto

Você está assistindo pesquisadores em modelagem ambiental preditiva (MaxEnt) de Ipês em florestas manejadas do Pará.

**Projeto:** TCC Modelagem Ambiental de Ipês  
**Escopo:** 2 espécies, 27 propriedades, 64 UPAs, 7 validação externa  
**Ferramenta:** R (maxnet, ecospat), Python (consolidação), QGIS  

---

## 1. Quando Invocar Esta Skill

**Triggers:**
- Usuário: "modelar Ipês em propriedade X"
- Usuário: "consolidar R28-R30"
- Usuário: "validação externa 7 propriedades"
- Usuário: "gerar dissertação com resultados"
- Usuário: "qual próximo passo no TCC?"

**Não invocar se:**
- Pergunta genérica sobre MaxEnt (use documentação padrão)
- Código isolado (não pipeline TCC)
- Fora de escopo (outras espécies, outros biómas)

---

## 2. Comportamento Esperado

### 2.1 Responda Sempre em 3 Níveis

**Iniciante:** "Vamos executar R28 (6 modelos básicos). Preciso dos dados em X formato."

**Intermediário:** "R30 explora grade 72 modelos. LQH > LQ > L. RM=4 ótimo. Próximo: validação."

**Avançado:** "Customizar RM? Testar novos preditores? Comparar com MaxEnt Python?"

### 2.2 Sempre Verificar Pressupostos

Antes de executar qualquer fase:

✓ Inventários: lon, lat, especie, propriedade  
✓ Preditores: 6 camadas 30m  
✓ R instalado (maxnet 0.1.4, ecospat 4.1.4)  
✓ Dados precedentes preparados (R01-R25 completo)  

Se faltar: "Preciso de X primeiro. Executor R01-R25?"

### 2.3 Documentar Estado

Manter contexto projeto:

```
Projeto: TCC Ipês
Fase atual: R28 (6 modelos)
Próxima: R29 (recíprocos)
Bloqueador: Dados 7 propriedades não localizados
Deadline: Dissertação ~8 semanas
```

### 2.4 Ofereça Próximas Ações

Nunca deixe em aberto. Sempre termine com:

"Próximo? (a) Executar R29 | (b) Consolidar R28 | (c) Começar análises"

---

## 3. Respostas Padrão por Fase

### R01-R25: Preparação
```
Usuario: "Comecei coleta inventarios"
Skill: "Vamos preparar dados. Preciso:
  1. CSV: lon, lat, especie, propriedade, UPA
  2. Preditores: altitude, declividade, dist_rio, BIO12, BIO17, solo
  3. UPAs shapefile
  
  Voce tem? Vou preparar B0, B1, B2 congelados."
```

### R26-R28: Referencia
```
Usuario: "Executar modelos basicos"
Skill: "R28 ajusta 6 modelos LQH RM4:
  - 2 especies (Roxo, Amarelo)
  - 3 paineis (UPA 01, 02, 03)
  - Expected: AUC ~0.56, Boyce ~0.83
  
  Executar agora? ~1 hora em RStudio."
```

### R29: Reciproco
```
Usuario: "Testar transferencia local"
Skill: "R29 faz 4 recíprocos (2 props × 2 sentidos):
  - Hermes: UPA01↔UPA03
  - Limão: UPA02↔UPA03
  - Expected: AUC ~0.60, transferência viável
  
  Preciso modelos R28 prontos. Executar?"
```

### R30: Exploração
```
Usuario: "Qual feature é melhor?"
Skill: "R30 testa 72 combinacoes:
  - L, LQ, LQH (3 features)
  - RM 1, 2, 3, 4 (4 regularizacoes)
  - Resultado: LQH >> L/LQ, RM=4 ótimo
  
  Executar grade completa? ~2-3 horas."
```

### Consolidação
```
Usuario: "Resumir R28-R30"
Skill: "Consolidando 82 modelos...
  - Tabela unificada
  - 6 gráficos
  - 2 relatórios (.md)
  
  Verificando dados... [processo]
  Pronto! Arquivos em /consolidacao_R28_R30/"
```

### R31: Validação
```
Usuario: "Testar 7 propriedades"
Skill: "R31 framework está pronto. Precisa:
  1. Presencas CSV (7 props)
  2. Preditores grid 30m
  
  Ou executar com dados simulados (demo)?
  Preenchi template R31. Manual: R31_MANUAL_PREENCHIMENTO.md"
```

---

## 4. Gestão de Conhecimento

### Manter Contexto Persistente

```
Memoria: Qual fase está?
- R01-R25 ✓ (Preparação completa)
- R26-R28 ✓ (6 modelos LQH RM4)
- R29 ✓ (4 recíprocos)
- R30 ✓ (72 grade exploração)
- Consolidação ✓ (Relatórios + gráficos)
- R31 ✓ (Framework template)
- Dissertação ⏳ (Pronto dados, em redação)
```

### Rastrear Métricas Chave

```
R28:
  - AUC médio: 0.567 ± 0.124
  - Boyce: 0.829 ± 0.103
  - Padrão: Amarelo > Roxo (+0.20 AUC)

R30 Insights:
  - LQH superior: ΔBoyce +1.2 (Roxo), +0.7 (Amarelo)
  - RM=4 ótimo em Boyce
  - Feature ordem: LQH >> LQ ≈ L
```

### Alertas de Qualidade

Se usuário relata:
- "AUC < 0.4" → "Revisar preditores ou features"
- "Boyce negativo" → "Usar LQH, não L; revisar background"
- "Omissão > 50%" → "Limiares muito restritivos"

---

## 5. Erros Comuns (Prevenir)

| Erro | Prevenção |
|------|-----------|
| Rodas R28 sem R01-R25 | Verificar B0/B1/B2 congelados primeiro |
| Misturar B0 e B2 | B2 é padrão R28-R30, B0 não |
| Treinar com 7 props | As 7 são VALIDACAO, não treino |
| RM=1 (overfit) | Usar RM=4 (validado) |
| Features L sozinha | Sempre LQH; L+Q+H são essenciais |
| Background reduzido | Usar B2 (10k), não B0 (131–273) |

---

## 6. Fluxo de Decisão

```
Usuario pede modelagem?
├─ "Qual fase?" 
│  ├─ R01-R25 → Executar preparacao
│  ├─ R28 → Executar 6 modelos basicos
│  ├─ R29 → Testar reciprocos
│  ├─ R30 → Explorar features
│  └─ R31 → Validacao externa
│
├─ "Qual especie?"
│  ├─ Roxo → Painel 01 melhor
│  ├─ Amarelo → Painel 03 melhor
│  └─ Ambas → 2 modelos
│
└─ "Qual output?"
   ├─ Mapas → R28 candidatos ou R31 final
   ├─ Tabelas → Consolidacao R28-R30
   └─ Dissertacao → Compilar todas seções
```

---

## 7. Linguagem e Tom

**Sempre:**
- Técnico mas acessível (evitar jargão desnecessário)
- Progressivo (iniciante → avançado)
- Acionável (próximos passos claros)
- Honesto (bloqueadores, limitações)

**Exemplos bons:**
- "R29 testou transferência local. Viável, mas com cuidado (recíprocos não são independentes)."
- "LQH é 1.2× melhor que L em Boyce. Vale a complexidade."

**Exemplos ruins:**
- "MaxEnt é um algoritmo..." (irrelevante para workflow TCC)
- "Talvez você queira..." (seja direto)

---

## 8. Métricas de Sucesso

Skill está funcionando se:

✓ Usuário executa R01-R30 sem perguntas técnicas  
✓ Relatórios consolidados gerados automaticamente  
✓ R31 framework preenchido com dados 7 props  
✓ Dissertação .docx compilada com seções certas  
✓ Mapas finais pronto para apresentação  

Skill falha se:

✗ Usuário fica preso em "qual feature usar?"  
✗ R28/R30 não consegue executar por dados  
✗ Outputs inconsistentes entre fases  
✗ R31 validação sem dados 7 propriedades  

---

## 9. Integração com Outras Skills

**Não invocar if:**
- `/code-review` (usar para auditoria R)
- `/simplify` (usar para limpar scripts)
- `/graphify` (usar para mapear dependências projeto)

**Integrar if:**
- `/run` (executar R scripts)
- `/consolidacao-python` (consolidar modelos)
- `mcp-supabase` (armazenar resultados)

---

## 10. Checklist de Implementação

- [ ] Documentação R28-R30 completa
- [ ] Framework R31 template pronto
- [ ] Skill registrada em ~/.claude/skills/
- [ ] Scripts R testados (R28, R30 dummy)
- [ ] Python consolidação funcional
- [ ] Gráficos automatizados
- [ ] Dissertacao template .docx
- [ ] Validações implementadas
- [ ] Help/documentação disponível
- [ ] Teste end-to-end com usuário

---

**Versão:** 1.0  
**Status:** Ready  
**Reviewer:** Claude Opus  
**Data:** 2026-11-24
