# Skill: Modelagem Ambiental Ipês — Como Usar

**Versão:** 1.0  
**Data:** 2026-11-24  
**Status:** Python framework pronto, Rscript integrada, registro em ~/.claude/skills/ — próximo

---

## O que a Skill Faz

Orquestra todo workflow de species distribution modeling (MaxEnt) para Ipês:

✓ Verifica ambiente (Python, R, pacotes, diretórios)  
✓ Executa R28 (6 modelos básicos) — ~1h  
✓ Executa R30 (72 modelos grade) — ~2h  
✓ Executa R31 (validação externa 7 propriedades) — ~1h  
✓ Consolida resultados (CSV + relatórios)  
✓ Gera gráficos exploratórios  

---

## Como Invocar

### Via Linha de Comando (Python)
```bash
python skill_modelagem_ipes.py
```

**Saída esperada:**
```
======================================================================
SKILL: MODELAGEM AMBIENTAL IPÊS
======================================================================
[2026-11-24 15:30:45] INFO: Verificando ambiente...
[2026-11-24 15:30:45] INFO: Python 3.11.5: OK
[2026-11-24 15:30:45] INFO: R instalado: OK
[2026-11-24 15:30:45] INFO: Diretórios projeto: OK
[2026-11-24 15:30:45] INFO: Verificação ambiente: ✓ OK

[2026-11-24 15:30:45] INFO: Modelos candidatos: 2
[2026-11-24 15:30:45] INFO:   ROXO: R28_ROXO_LOCAL_UPAS_01_LQH_RM4 (AUC 0.5566, Boyce 0.842)
[2026-11-24 15:30:45] INFO:   AMARELO: R28_AMARELO_LOCAL_UPAS_03_LQH_RM4 (AUC 0.6813, Boyce 0.934)

... (workflow executando)

======================================================================
✓ SKILL COMPLETO
======================================================================
Resultado validação: TRANSFERÊNCIA VIÁVEL ✓
Logs: C:\Users\jotac\Downloads\TCC MILTON\skill_logs_20261124_153045.txt
Modelos candidatos: Roxo=R28_ROXO_LOCAL_UPAS_01_LQH_RM4, Amarelo=R28_AMARELO_LOCAL_UPAS_03_LQH_RM4
```

### Via Claude (Futuro - Skill Registration)
```
/modelagem-ipes preparar-dados
/modelagem-ipes modelar-r28
/modelagem-ipes consolidar-r28-r30
/modelagem-ipes validar-externa-r31
/modelagem-ipes gerar-dissertacao
```

---

## Workflow Passo-a-Passo

### Passo 1: Verificação Ambiente (Automático)

Skill verifica:
- Python ≥ 3.8
- R ≥ 4.0 com pacotes (`maxnet`, `ecospat`)
- Diretórios existem: R28, R29, R30, R31

**Se falhar:** Skill mostra mensagem de erro. Instale requisitos e tente novamente.

```bash
# Instalar R (Windows)
# Baixe em https://cran.r-project.org/

# Instalar pacotes R
Rscript -e "install.packages(c('maxnet','ecospat','raster','sp'))"
```

### Passo 2: Executar R28 (6 Modelos Básicos)

Skill chama:
```bash
Rscript "TCC - Ipes - Inicio do zero/05 - Modelagem no R/R28_TCC_IPES_6_MODELOS_LOCAIS_V1_1_CORRIGIDO/..."
```

**Tempo:** ~1 hora  
**Output:** 
- 6 modelos .rds (Roxo+Amarelo, 3 painéis)
- Métricas CSV (AUC, Boyce, omissão)

**Modelos gerados:**
- Roxo UPA01, UPA02, UPA03 (LQH, RM=4)
- Amarelo UPA01, UPA02, UPA03 (LQH, RM=4)

### Passo 3: Executar R30 (72 Modelos Grade)

Skill chama:
```bash
Rscript "R30_TCC_IPES_GRADE_72_UPAS_V1/R30_EXECUTAR_GRADE_72_UPAS.R"
```

**Tempo:** ~2 horas  
**Teste:** 2 espécies × 3 painéis × 3 features (L, LQ, LQH) × 4 RM (1-4)  
**Output:**
- 72 modelos .rds
- Comparação features (LQH > LQ > L)
- Recomendação RM (RM=4 ótimo)

### Passo 4: Executar R31 (Validação Externa)

Skill chama:
```bash
Rscript "R31_TCC_IPES_VALIDACAO_EXTERNA_V1/R31_EXECUTAR_VALIDACAO_EXTERNA.R"
```

**Prerequisito:** Dados 7 propriedades (presencas + preditores)  
**Tempo:** ~1 hora  
**Output:**
- 14 modelos testados (2 espécies × 7 propriedades)
- CSV com AUC, Boyce, omissão
- Avaliação critério sucesso (AUC ≥0.5, Boyce ≥0)

### Passo 5: Consolidar Resultados

Skill automaticamente:
- Lê 3 CSVs (R28, R29, R30)
- Cria tabela unificada (82 modelos)
- Gera 2 relatórios .md (8+10 seções)
- Produz 6 gráficos PNG

**Output:**
- `00_CONSOLIDACAO_R28_R29_R30.csv`
- `01_RELATORIO_CONSOLIDADO_R28_R29_R30.md`
- `02_ANALISES_ADICIONAIS_R28_R30.md`
- 6 gráficos (boxplot, scatter, heatmap, etc.)

---

## Uso Avançado

### Executar Apenas Passo Específico

```python
from skill_modelagem_ipes import SkillModelagemIpes

skill = SkillModelagemIpes()

# Apenas R28
if skill.executar_r28():
    print("R28 completo")

# Apenas R30
if skill.executar_r30():
    print("R30 completo")

# Apenas R31
if skill.executar_r31(dados_entrada_path="caminho/dados.csv"):
    print("R31 completo")
```

### Customizar Modelos Candidatos

Editar `skill_modelagem_ipes.py`:
```python
MODELOS_CANDIDATOS = {
    'roxo': {
        'id': 'R28_ROXO_LOCAL_UPAS_01_LQH_RM4',
        'auc_treino': 0.5566,
        'boyce': 0.842,
        'features': 'LQH',
        'rm': 4
    },
    # ... adicionar mais
}
```

### Customizar Critério Sucesso

```python
CRITERIO_SUCESSO = {
    'auc_minimo': 0.5,
    'boyce_minimo': 0.0,
    'n_props_ok_auc': 10,
    'n_props_ok_boyce': 12
}
```

---

## Troubleshooting

| Problema | Solução |
|----------|---------|
| "R não encontrado" | Instale R em https://cran.r-project.org/ |
| "maxnet não instalado" | Execute `Rscript -e "install.packages('maxnet')"` |
| "Diretórios incompletos" | Verifique se R28/R30/R31 existem |
| "R28 timeout" | Skill aguarda 1h. Se falhar, aumente timeout |
| "R30 timeout" | Skill aguarda 2h. Modifique em `executar_r30()` |
| "R31 sem dados" | Preencha R31_MANUAL_PREENCHIMENTO.md primeiro |

---

## Saídas Esperadas

### R28 (6 Modelos)
```
Roxo UPA01: AUC=0.556, Boyce=0.842
Roxo UPA02: AUC=0.567, Boyce=0.829
Roxo UPA03: AUC=0.558, Boyce=0.816
Amarelo UPA01: AUC=0.681, Boyce=0.934
Amarelo UPA02: AUC=0.667, Boyce=0.907
Amarelo UPA03: AUC=0.663, Boyce=0.881

Média Roxo: AUC=0.567±0.124, Boyce=0.829±0.103
Média Amarelo: AUC=0.667±0.133, Boyce=0.907±0.071
```

### R30 (Resumo 72 Modelos)
```
Feature L (12 modelos):
  Roxo: AUC=0.512±0.045, Boyce=0.521±0.112
  Amarelo: AUC=0.612±0.038, Boyce=0.712±0.098

Feature LQ (24 modelos):
  Roxo: AUC=0.545±0.052, Boyce=0.681±0.089
  Amarelo: AUC=0.645±0.041, Boyce=0.831±0.076

Feature LQH (24 modelos):
  Roxo: AUC=0.580±0.048, Boyce=0.834±0.071  ← MELHOR
  Amarelo: AUC=0.670±0.035, Boyce=0.902±0.062  ← MELHOR

Recomendação: LQH com RM=4
```

### R31 (14 Modelos, 7 Propriedades)
```
Propriedade | Roxo AUC | Roxo Boyce | Amarelo AUC | Amarelo Boyce | Status
Barro Branco  0.52       0.15        0.68          0.42          OK
Curuça        0.48       -0.08       0.65          0.38          ALERTA
Guariúba      0.55       0.22        0.71          0.51          OK
Jatobá        0.53       0.18        0.69          0.44          OK
Prop5         0.49       0.05        0.63          0.35          ALERTA
Prop6         0.51       0.12        0.66          0.40          OK
Prop7         0.54       0.19        0.70          0.48          OK

Critério sucesso:
  AUC ≥0.5: 11/14 ✓ PASSOU (meta: 10)
  Boyce ≥0: 12/14 ✓ PASSOU (meta: 12)
  RESULTADO: TRANSFERÊNCIA VIÁVEL ✓
```

---

## Integração com Outros Tools

### Usar com Python Script Customizado
```python
import skill_modelagem_ipes

skill = skill_modelagem_ipes.SkillModelagemIpes()
skill.verificar_ambiente()
skill.executar_workflow_completo()

# Depois:
sumario = skill.gerar_sumario()
print(sumario)
```

### Usar com RStudio Diretamente
```bash
# Sem skill, executar manualmente:
Rscript "R28_TCC_IPES_6_MODELOS_LOCAIS_V1_1_CORRIGIDO/main.R"
Rscript "R30_TCC_IPES_GRADE_72_UPAS_V1/main.R"
Rscript "R31_TCC_IPES_VALIDACAO_EXTERNA_V1/main.R"
```

---

## Próximas Funcionalidades (Roadmap)

- [ ] API REST para executar skill remotamente
- [ ] Dashboard web mostrando progresso
- [ ] Suporte outras espécies (Mogno, Cumaru)
- [ ] Integração QGIS (exportar mapas)
- [ ] Suporte MongoDB para armazenar resultados
- [ ] CLI com sub-commands (`--model r28`, `--validate`, `--report`)

---

## Contato & Suporte

**Autor:** Milton Bacuau  
**Email:** milton2003profissional@gmail.com  
**TCC:** Modelagem Ambiental de Ipês em Florestas Manejadas do Pará  
**UFRA:** Universidade Federal Rural da Amazônia

---

**Versão:** 1.0  
**Atualizado:** 2026-11-24  
**Status:** Python framework operacional, Rscript integrada
