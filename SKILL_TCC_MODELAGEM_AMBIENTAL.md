# Skill: TCC Modelagem Ambiental de Ipês

## Visão Geral

Skill para assistir pesquisadores em modelagem ambiental preditiva de duas espécies de Ipês em florestas manejadas.

**Escopo:** 
- Modelagem MaxEnt local + exploratória
- Validação transferência espacial
- Geração mapas adequabilidade
- Análises consolidadas

**Usuários:** Pesquisadores TCC, colaboradores UFRA.

**Tempo de execução:** Workflow completo ~2 semanas.

---

## 1. Fase 1: Preparação de Dados (R01-R25)

### Entrada
- Inventários florestais (CSV): lon, lat, especie, propriedade
- MDEs, BIO12, BIO17, hidrografia, solo
- UPAs shapefile

### Workflow
1. **R01-R10:** Limpeza inventários, preparação preditores
2. **R11-R20:** Background, fold splitting, auditoria
3. **R21-R25:** Planejamento blocos, elegibilidade

### Saída
- 6 datasets congelados (B0, B1, B2, etc.)
- 27 propriedades + 64 UPAs inventariadas
- 7 propriedades reservadas teste externo

### Skill: Executar Preparação
```
skill: modelagem-ipes-preparacao
input: pasta com inventarios + preditores
output: 6 CSVs congelados + relatórios auditoria
```

---

## 2. Fase 2: Modelagem Local + Exploratória (R26-R30)

### Entrada
- 6 datasets B0-B2 (R01-R25)
- Modelos candidatos: LQH RM4

### R28: 6 Modelos Referência
```
- 2 espécies (Roxo, Amarelo)
- 3 painéis locais (UPA 01, 02, 03)
- Features: LQH
- RM: 4
- Output: AUC 0.567, Boyce 0.829
```

### R29: Validação Recíproca
```
- 2 espécies
- 2 propriedades (Hermes, Limão)
- Teste: UPA A treino → UPA B validacao
- Output: AUC 0.595, Boyce 0.649 (transferência local viável)
```

### R30: Grade Exploratória 72 Modelos
```
- 2×3 painéis × 3 features (L, LQ, LQH) × 4 RM (1-4)
- Achado: LQH >> L/LQ, RM=4 ótimo
- Padrão: Amarelo AUC +0.2 vs Roxo
```

### Skill: Executar Modelagem
```
skill: modelagem-ipes-modelos
input: dataset B2, propriedades 27+64 UPAs
phase: R28 | R29 | R30
output: 82 modelos, tabelas, gráficos
```

---

## 3. Fase 3: Consolidação Análises (R28-R30)

### Workflow
1. Consolidar 82 modelos em CSV único
2. Comparar AUC/Boyce/Omissão por fase
3. Validar features: LQH > LQ > L
4. Análises adicionais: variabilidade, padrões
5. Gerar 6 gráficos exploratórios

### Output
- `01_RELATORIO_CONSOLIDADO_R28_R29_R30.md` (8 seções)
- `02_ANALISES_ADICIONAIS_R28_R30.md` (10 seções)
- 6 PNGs (AUC, Boyce, features, RM, resumo)

### Skill: Consolidação
```
skill: modelagem-ipes-consolidar
input: R28, R29, R30 CSVs
output: relatórios + gráficos
```

---

## 4. Fase 4: Validação Externa (R31)

### Entrada
- 2 modelos R28 candidatos (Roxo + Amarelo)
- 7 propriedades externas
- Preditores + inventários 7 props

### Workflow
1. Treinar em 27 props + 64 UPAs
2. Validar em 7 props não usadas
3. Calcular AUC, Boyce, omissão
4. Gerar mapas adequabilidade

### Criterio Sucesso
- AUC >= 0.5 em >= 5/7 propriedades
- Boyce >= 0 em >= 6/7
- Esperado: AUC queda 15-40% vs R28

### Skill: Validação Externa
```
skill: modelagem-ipes-validacao
input: modelos R28, dados 7 propriedades
output: tabela validacao, 2 mapas, relatório
```

---

## 5. Fase 5: Dissertação

### Componentes
1. **Introdução:** Contexto, lacuna
2. **Revisão:** MaxEnt, transferência espacial
3. **Métodos:** Inventários, preditores, MaxEnt config
4. **Resultados:** Tabelas AUC/Boyce, mapas, R31
5. **Discussão:** Padrões, implicações manejo
6. **Conclusão:** Viabilidade, futuro

### Outputs
- 2 mapas finais (Roxo + Amarelo)
- 10+ tabelas
- 20+ figuras (R28-R30 + gráficos)

### Skill: Gerar Dissertação
```
skill: modelagem-ipes-dissertacao
input: todos relatórios, gráficos, dados R31
output: template .docx pronto redação
```

---

## 6. Skill Command Reference

### Preparação
```
/modelagem-ipes preparar-dados
  --inventarios: path/inventarios.csv
  --preditores: path/preditores/
  --upas: path/upas.shp
```

### Modelagem
```
/modelagem-ipes modelar
  --dataset: B2
  --phase: R28 | R29 | R30
  --especie: roxo | amarelo | ambas
```

### Consolidação
```
/modelagem-ipes consolidar R28 R29 R30
  --output: consolidacao/
```

### Validação
```
/modelagem-ipes validar-externa
  --modelos: path/R28/*.rds
  --propriedades: 7
  --preditores: path/grid_7props.tif
```

### Dissertação
```
/modelagem-ipes gerar-dissertacao
  --secoes: metodos | resultados | discussao | tudo
```

---

## 7. Arquitetura Skill

### Responsabilidades

**Preparação (R01-R25):**
- Validar entradas
- Executar scripts R sequenciais
- Auditoria outputs

**Modelagem (R26-R30):**
- Verificar pressupostos
- Executar modelos
- Consolidar métricas

**Consolidação:**
- Integrar 82 modelos
- Gerar gráficos
- Relatórios MD

**Validação (R31):**
- Preencher template R31
- Executar validação externa
- Mapas + tabelas

**Dissertação:**
- Compilar seções
- Tabelas/figuras
- Template .docx

### Dados Persistentes

```
~/.claude/skills/tcc-modelagem/
├── config.json (parametros)
├── manifesto.csv (entradas congeladas)
├── R28_modelos/ (candidatos)
├── R30_grade/ (exploracao)
└── datasets/ (B0-B2)
```

---

## 8. Validações Automáticas

Skill verifica antes execução:

✓ Inventários: lon, lat, especie, propriedade  
✓ Preditores: 6 camadas (altitude, declividade, dist_rio, BIO12, BIO17, solo)  
✓ Preditores: resolução 30m, extent cobre UPAs  
✓ UPAs: shapefile válido, colunas id/nome  
✓ Modelos: RDS carregável, compatível ecospat v4.1.4  
✓ CSVs: encoding UTF-8, colunas esperadas  

Se falhar: parar, mensagem clara, não continuar.

---

## 9. Recomendações de Uso

### Para Pesquisadores Iniciantes
```
1. /modelagem-ipes setup                    # Verifica ambiente R
2. /modelagem-ipes preparar-dados           # Executa R01-R25
3. /modelagem-ipes modelar --phase R28      # Executa R28
4. /modelagem-ipes consolidar R28           # Relatórios
```

### Para Pesquisadores Avançados
```
1. Customizar config.json (RM, features, etc.)
2. /modelagem-ipes modelar --phase R30      # Exploração
3. /modelagem-ipes validar-externa          # R31
4. /modelagem-ipes gerar-dissertacao        # Compilar
```

### Para Colaboradores
```
1. /modelagem-ipes status                   # Ver progresso
2. /modelagem-ipes revisar-outputs          # QA
3. /modelagem-ipes exportar-resultados      # ZIP
```

---

## 10. Troubleshooting

| Erro | Causa | Solução |
|------|-------|---------|
| "Presencas < 10 por propriedade" | Inventário incompleto | Revisar coleta dados |
| "Preditores resolução 1km" | Grid muito grossa | Usar 30m ou resampling |
| "Modelo não carrega" | RDS incompatível | Retrainar em R28 |
| "AUC < 0.4" | Preditores ruins ou nicho pequeno | Testar novos preditores |
| "Boyce negativo" | Features inadequadas | Usar LQH, não L |

---

## 11. Outputs Padrão

Cada fase gera:

**R28:** 6 RDS, `28_METRICAS_6_MODELOS.csv`, gráficos, relatório  
**R29:** 4 RDS, `29_METRICAS_4_RECIPROCOS.csv`, auditoria Boyce  
**R30:** 72 RDS, `30_METRICAS_72_AVALIACOES.csv`, grade exploração  
**R31:** `31_VALIDACAO_EXTERNA_7_PROPRIEDADES.csv`, 2 mapas, relatório  

Todos em UTF-8, estrutura consistente.

---

## 12. Próximos Passos (Pós-Dissertação)

- **Skill Integração:** Widget QGIS para upload dados → mapas
- **API:** Serviço web para colaboradores remotos
- **Generalização:** Template Mogno, Cumaru, Cedro (outras espécies)
- **Monitoramento:** Validação anual com novos inventários

---

**Versão:** 1.0  
**Data:** 2026-11-24  
**Status:** Framework definido, pronto implementação  
**Tempo Est. Dev:** 2–3 semanas  
**Usuários Alvo:** Pesquisadores TCC, colaboradores UFRA, parceiros externos
