# R31 — Manual de Preenchimento do Template

## Visão Geral

R31 é um **framework template** pronto para executar validação externa de modelos R28 em 7 propriedades não usadas em treino.

O script já possui:
- ✓ Verificações de entrada
- ✓ Leitura de presencas CSV
- ✓ Carregamento de modelos
- ✓ Cálculo de métricas
- ✓ Geração de saídas

Faltam apenas:
- Dados de entrada (7 propriedades)
- Preenchimento de seções marcadas [TEMPLATE]

---

## Passo 1: Preparar Pasta de Entrada

```
R31_TCC_IPES_VALIDACAO_EXTERNA_V1/
├── 01_ENTRADAS_EXTERNAS/
│   ├── Presencas_Roxo_7props.csv
│   ├── Presencas_Amarelo_7props.csv
│   ├── Grid_Preditores_7props.tif (ou .csv)
│   └── 31_MANIFESTO_ENTRADAS.csv
├── 02_RESULTADOS_R31/
├── LEIA_PRIMEIRO.txt
└── R31_VALIDACAO_EXTERNA.R
```

---

## Passo 2: Estrutura dos CSVs de Presencas

### Presencas_Roxo_7props.csv

```
lon,lat,propriedade
-56.1234,-2.5678,Barro Branco
-56.2345,-2.6789,Barro Branco
-56.5000,-3.0000,Curuça
...
```

**Esperado:**
- Coluna `lon`: longitude (graus decimais)
- Coluna `lat`: latitude (graus decimais)
- Coluna `propriedade`: nome exato da propriedade
- Mínimo: 10 presencas por propriedade (ideal: 30+)

### Presencas_Amarelo_7props.csv

Mesmo formato que Roxo.

---

## Passo 3: Preditores

### Opção A: Grid TIF (preferido)

Arquivo `Grid_Preditores_7props.tif` com 6 camadas:

| Banda | Nome | Unidade | Descrição |
|-------|------|---------|-----------|
| 1 | altitude | metros | Elevação MDE 30m |
| 2 | declividade | graus | Declive MDE 30m |
| 3 | dist_rio | metros | Distância raster à hidrografia |
| 4 | BIO12 | mm/ano | Precipitação anual CHELSA |
| 5 | BIO17 | mm/trimestre | Precipitação trimestre seco |
| 6 | solo | categorico | Textura MapBiomas (2,3,4,6,7) |

### Opção B: CSV (alternativa)

```
lon,lat,altitude,declividade,dist_rio,BIO12,BIO17,solo
-56.1234,-2.5678,120,5.2,250,2500,100,3
-56.2345,-2.6789,135,8.1,180,2600,110,3
...
```

---

## Passo 4: Atualizar Script R (Seções [TEMPLATE])

### Seção 1: Leitura de Preditores

Localizar em `R31_VALIDACAO_EXTERNA.R`:

```r
# TEMPLATE: Substituir pela logica de leitura de preditores
```

Adicionar (exemplo para TIF):

```r
preditores_tif <- raster::stack('01_ENTRADAS_EXTERNAS/Grid_Preditores_7props.tif')
names(preditores_tif) <- c('altitude', 'declividade', 'dist_rio', 'BIO12', 'BIO17', 'solo')

# Converter raster para data.frame para predicoes
grid_df <- raster::as.data.frame(preditores_tif, xy=TRUE)
```

Ou (exemplo para CSV):

```r
grid_df <- ler('01_ENTRADAS_EXTERNAS/Grid_Preditores_7props.csv')
```

### Seção 2: Carregamento de Modelos R28

Localizar:

```r
# TEMPLATE: Carregar RDS de R28
```

Adicionar:

```r
# Caminho para modelos R28 (do repo original)
path_r28 <- 'C:\\seu_caminho\\R28_TCC_IPES_6_MODELOS_LOCAIS_V1_1_CORRIGIDO\\03_RESULTADOS_R28_V1_1'

modelo_roxo <- readRDS(file.path(path_r28, 'R28_ROXO_LOCAL_UPAS_01_LQH_RM4.rds'))
modelo_amarelo <- readRDS(file.path(path_r28, 'R28_AMARELO_LOCAL_UPAS_03_LQH_RM4.rds'))

cat('Modelos carregados:\n')
cat('  Roxo:', class(modelo_roxo), '\n')
cat('  Amarelo:', class(modelo_amarelo), '\n')
```

### Seção 3: Predicoes

Localizar:

```r
# TEMPLATE: Aplicar modelo_roxo em grid preditores
```

Adicionar:

```r
cat('Gerando predicoes Roxo...\n')
pred_roxo <- maxnet::predict.maxnet(modelo_roxo, 
                                     grid_df[, c('altitude', 'declividade', 'dist_rio', 'BIO12', 'BIO17', 'solo')],
                                     type='cloglog', clamp=TRUE)
grid_df$pred_roxo <- as.numeric(pred_roxo)

cat('Gerando predicoes Amarelo...\n')
pred_amarelo <- maxnet::predict.maxnet(modelo_amarelo,
                                        grid_df[, c('altitude', 'declividade', 'dist_rio', 'BIO12', 'BIO17', 'solo')],
                                        type='cloglog', clamp=TRUE)
grid_df$pred_amarelo <- as.numeric(pred_amarelo)
```

### Seção 4: Metricas de Validacao

Localizar:

```r
# TEMPLATE: Calcular para cada propriedade externa
```

Adicionar:

```r
# Exemplo: calcular AUC para Roxo na primeira propriedade
propriedades <- unique(df_roxo$propriedade)

resultados <- list()

for (prop in propriedades) {
  
  # Presencas na propriedade
  presencas_prop <- df_roxo[df_roxo$propriedade == prop, ]
  
  # Background: amostra aleatoria da grid
  bg_amostra <- grid_df[sample(1:nrow(grid_df), size=1000), ]
  
  # Scores
  scores_presencas <- grid_df$pred_roxo[...] # linhas com presencas
  scores_background <- bg_amostra$pred_roxo
  
  # AUC
  auc_valor <- ecospat::ecospat.auc(scores_presencas, scores_background)
  
  # Boyce
  boyce_obj <- ecospat::ecospat.boyce(fit=scores_background, 
                                       obs=scores_presencas,
                                       nclass=10, PEplot=FALSE)
  boyce_valor <- boyce_obj$cor
  
  resultados[[prop]] <- data.frame(
    especie = 'Roxo',
    propriedade = prop,
    auc = auc_valor,
    boyce = boyce_valor
  )
}

validacao_roxo <- do.call(rbind, resultados)
```

Repetir para Amarelo.

---

## Passo 5: Executar Script

No RStudio:

```r
# Abra R31_VALIDACAO_EXTERNA.R
# Clique em "Source" ou execute Ctrl+Shift+S
```

Esperado:
- Verificações preflight OK
- Leitura de presencas
- Carregamento de modelos
- Geração de predicoes
- Calculo de metricas
- Saídas em `02_RESULTADOS_R31/`

---

## Passo 6: Resultados

### CSV de Validacao

`31_VALIDACAO_EXTERNA_7_PROPRIEDADES.csv`

```
id,especie,propriedade,n_presencas,auc,boyce,omissao_p10,status
R31_ROXO_BARRO_BRANCO,Roxo,Barro Branco,45,0.52,0.76,0.08,OK
R31_ROXO_CURUÇA,Roxo,Curuça,38,0.48,-0.1,0.15,ALERTA_BOYCE_NEG
...
```

### Criterio de Sucesso

✓ Transferencia viavel se:
- AUC >= 0.5 em >= 5/7 propriedades (ambas especies)
- Boyce >= 0 em >= 6/7 propriedades
- Omissao P10 < 0.5 em media

✗ Transferencia falha se:
- AUC < 0.4 em >3 propriedades
- Boyce < -0.3 em >2 propriedades

---

## Notas

- Limiares P10 vem de R28 (fixos, não recalculados)
- Background = amostra aleatória da grid 7 propriedades
- Esperado: AUC queda 15-40% vs R28 (transferência real é mais difícil)
- Se queda >50%: revisar dados entrada ou retrainar com 7 props incluídas

---

**Versão:** R31 V1 Manual  
**Data:** 2026-11-24  
**Status:** Pronto para preenchimento
