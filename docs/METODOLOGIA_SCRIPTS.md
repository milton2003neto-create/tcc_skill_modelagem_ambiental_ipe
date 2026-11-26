---
title: "Ferramenta de Modelagem Ambiental dos Ipês – Documentação metodológica dos scripts"
subtitle: "TCC – UFRA · ipê-roxo (*Handroanthus impetiginosus*) e ipê-amarelo (*H. serratifolius*)"
lang: pt-BR
---

# 1. Visão geral

A ferramenta foi escrita em R (≥ 4.2) com interface Shiny (`app.R`). Toda a análise está nos
scripts numerados da pasta `R/`; a interface apenas chama essas funções, de modo que cada etapa pode
ser reproduzida sem o app. Cada espécie tem um fluxo independente. Em todas as etapas a ferramenta
**recomenda** uma escolha (com justificativa escrita) e o usuário **decide**; cada execução grava suas
saídas em `resultados/<espécie>/<etapa>/<data_hora>/`, com um registro (`LOG_EXECUCAO.txt/.json`)
contendo data, versão do R e dos pacotes, pasta de dados e todas as escolhas feitas.

O algoritmo é o MaxEnt na implementação `maxnet` (Phillips et al., 2017), que ajusta o modelo como
uma regressão logística penalizada (lasso) com o pacote `glmnet` (Friedman et al., 2010), sem Java.

| Etapa (aba do app) | Script | Pasta de saída |
|---|---|---|
| Preparação | `00_SETUP_PACOTES_E_TESTES.R`, `01_CONFIGURACAO_E_FUNCOES.R`, `02_CARREGAR_DADOS.R` | `resultados/_geral/00_setup/` |
| 1. Diagnóstico | `03_DIAGNOSTICO_DADOS.R` | `01_diagnostico/` |
| 2. Treino / validação | `04_PREPARAR_PROPRIEDADES_RESERVADAS.R`, `05_SELECAO_TREINO_VALIDACAO.R` | `_geral/00_reservadas/`, `02_selecao/` |
| 3. Variáveis | `06_SELECAO_VARIAVEIS.R` | `03_variaveis/` |
| 4. Background e parâmetros | `07_BACKGROUND_E_PARAMETROS.R` | `04_parametros/` |
| 5. Treinamento | `08_TREINAMENTO.R` | `05_treino/` |
| 6. Validação | `09_VALIDACAO.R` | `06_validacao/` |

## 1.1 Dados de entrada

- **Presenças**: árvores inventariadas com DAP > 10 cm, uma por espécie por pixel de 30 m
  (`05_PRESENCAS_UM_POR_PIXEL_30M.csv`), em 27 propriedades de desenvolvimento.
- **Background B2**: 10.000 pontos aleatórios nos pixels válidos das 64 UPAs inventariadas das 27
  propriedades (`18_BACKGROUND_B2_10000_COM_FOLDS.csv`).
- **Propriedades reservadas** (teste externo): Barro Branco, Curuçá, Guariúba, Jatobá, Lote 01,
  Marília e Palmeira.
- **Preditores (30 m)**: altitude e declividade (ANADEM), distância à hidrografia, BIO12 –
  precipitação anual e BIO17 – precipitação do trimestre mais seco (CHELSA; Karger et al., 2017) e
  textura do solo (MapBiomas Solo, categórica).

# 2. Scripts

## 00_SETUP_PACOTES_E_TESTES.R – preparação do ambiente

- **Objetivo**: verificar a versão do R, instalar os pacotes que faltam (binários do CRAN, sem Rtools)
  e testar cada componente antes do uso.
- **Testes**: ajuste `maxnet` LQH em dados simulados; índice de Boyce (`ecospat`); leitura/escrita
  de raster (`terra`) e vetor (`sf`); VIF (`usdm`); gravação de gráfico (`ggplot2`); presença do
  pandoc; existência de todos os arquivos de dados. Java não é necessário.
- **Saída**: `00_RESULTADO_SETUP.csv` + log.

## 01_CONFIGURACAO_E_FUNCOES.R e 02_CARREGAR_DADOS.R – configuração e leitura

- Localizam a raiz do projeto e a pasta de dados (alterável em `config_local.R`), definem nomes das
  variáveis, espécies, propriedades reservadas e a semente padrão (20261125).
- Funções comuns: criação de pastas com data e hora, registro de log, gravação de CSV (separador `;`,
  UTF-8).
- `carregar_dados_especie()` lê presenças, background e plano de folds; a textura do solo é tratada
  como fator. `projetar_metros()` converte coordenadas de SIRGAS 2000 (EPSG:4674) para Policônica
  SIRGAS 2000 (EPSG:5880) para cálculos de distância.

## 03_DIAGNOSTICO_DADOS.R – diagnóstico dos dados (aba 1)

- **Objetivo**: identificar, antes de modelar, características dos dados que levam a AUC baixa e
  omissão alta.
- **Procedimentos**:
  - presenças por propriedade e por UPA; proporção do background em propriedades sem a espécie;
  - **concentração**: coeficiente de Gini e curva de Lorenz das presenças por propriedade; **N efetivo**
    = inverso do índice de Simpson, 1/Σpᵢ² (Hill, 1973), que expressa a quantas propriedades
    igualmente ricas os dados equivalem;
  - **balanço dos folds** (porcentagem de presenças por fold);
  - **novidade ambiental univariada** de cada fold em relação aos demais (porcentagem de pontos fora
    da amplitude do treino; Elith et al., 2010) e classes de solo ausentes no treino;
  - **presença × background**: teste de Kolmogorov–Smirnov por variável;
  - **agregação espacial**: razão entre a distância média ao vizinho mais próximo das presenças e a
    de pontos do background (análoga ao índice de Clark & Evans, 1954); valores < 1 indicam
    agrupamento.
- **Saídas**: tabelas 01–08, gráficos G01–G06 e `DIAGNOSTICO_EXPLICADO.txt`. A novidade é tratada
  como **risco** de omissão, não como causa certa.

## 04_PREPARAR_PROPRIEDADES_RESERVADAS.R – dados das 7 reservadas

- **Objetivo**: montar presenças e background das reservadas no mesmo formato das 27 de
  desenvolvimento. **Nenhuma métrica de desempenho é calculada**.
- **Método**: presenças dos GeoPackages de pontos com variáveis (DAP > 10 cm, uma por pixel de 30 m,
  identificada pela célula da máscara de UPAs); background sorteado nos pixels válidos das UPAs com a
  **mesma densidade do B2** (10.000 ÷ pixels válidos das 27 propriedades), com cota por UPA
  proporcional à área; valores dos 6 rasters extraídos com `terra`.

## 05_SELECAO_TREINO_VALIDACAO.R – plano de treino e validação (aba 2)

- **Desenhos**: **propriedade × propriedade** (cada unidade é uma propriedade inteira) ou
  **UPA × UPA** (cada unidade é uma UPA; a validação usa no máximo uma UPA por propriedade, e só de
  propriedades que mantêm outra UPA com presenças no treino).
- **Recomendação**: (i) as unidades são ordenadas no primeiro eixo de uma PCA das medianas ambientais
  (gradiente); (ii) candidatas à validação têm ≥ 30 presenças e não são a maior unidade; (iii) escolhem-se
  unidades espaçadas ao longo do gradiente até a soma de presenças mais próxima do alvo (padrão 25%);
  (iv) as unidades de treino são distribuídas em *k* folds por alocação gulosa que equilibra o número
  de presenças. Trata-se de validação cruzada em blocos espaciais (Roberts et al., 2017; Valavi et
  al., 2019).
- **Proteção**: as reservadas ficam fora dos dois conjuntos, salvo decisão explícita do usuário. Uma
  unidade nunca pode estar no treino e na validação ao mesmo tempo (verificação automática).
- **Verificações**: presenças mínimas, fold com menos de 10% das presenças, novidade ≥ 20%, classe de
  solo nova e **distância mínima** (km) entre pontos de validação e de treino (< 1 km indica que parte
  da validação mede transferência local).
- **Saídas**: `02_COMPOSICAO_FOLDS.csv` (quais propriedades/UPAs em cada fold e na validação, com
  presenças e background), unidades, avisos, proximidade, justificativa, mapa e `PLANO_SELECAO.rds`.

## 06_SELECAO_VARIAVEIS.R – multicolinearidade (aba 3)

- **Dados**: apenas o background das unidades de **treino** (ambiente disponível), para que a
  validação não influencie a escolha.
- **Procedimentos**: correlação de Pearson e de Spearman entre as variáveis contínuas; fator de
  inflação da variância (VIF, `usdm`; Naimi et al., 2014); associação do solo com as contínuas pela
  razão de correlação η = √R² de `lm(x ~ solo)`; AUC univariada indicativa (GLM binomial com termo
  quadrático ou fator).
- **Regra de recomendação**: em cada par com |r| > 0,7 (Dormann et al., 2013) – por padrão o **maior**
  |r| entre Pearson e Spearman – remove-se a variável de menor AUC univariada; em seguida remove-se,
  uma a uma, a de maior VIF enquanto algum VIF > 5. O usuário pode manter variáveis correlacionadas com
  justificativa ecológica; a ferramenta registra a diferença.

## 07_BACKGROUND_E_PARAMETROS.R – background, grade e custo (aba 4)

- **Background**: (a) reaproveitar o B2 (todo ou subamostra estratificada por UPA) – recomendado, pois
  mantém comparabilidade com as rodadas R01–R30; ou (b) novo sorteio aleatório de N pontos nos pixels
  válidos das UPAs de treino, cota proporcional à área, com semente registrada. Cerca de 10.000 pontos
  são suficientes para o MaxEnt (Phillips & Dudík, 2008; Barbet-Massin et al., 2012). A validação
  mantém a densidade do B2, para AUCs comparáveis.
- **Grade**: classes de *features* L, LQ, LQH (recomendadas), H e LQHP (opcionais) × multiplicador de
  regularização RM (padrão 0,5; 1; 2; 3; 4) (Radosavljevic & Anderson, 2014; Muscarella et al., 2014);
  *clamping* ligado; saída cloglog.
- **Custo**: cronometra um ajuste real por classe de *feature* e multiplica pelo número de ajustes
  (modelos × (k + 1) + Jackknife); informa memória livre (`ps`) e alerta se < 1 GB.
- **Nota técnica (eficiência)**: na versão 0.1.4 do `maxnet`, a opção `addsamplestobackground = TRUE`
  compara cada presença com cada ponto de background convertendo as linhas em texto (custo
  quadrático; ≈ 5 min por ajuste com ~11 mil pontos). A função `ajustar_maxnet()` faz a mesma
  operação – adiciona ao background as presenças cujo vetor ambiental não existe no background – de
  forma vetorizada e chama `maxnet(..., addsamplestobackground = FALSE)`. As predições coincidem com as
  da implementação original (correlação 0,99995) e o tempo cai para 1–10 s por ajuste.
- **Nota técnica (uma variável)**: o `glmnet` exige ao menos duas colunas; um modelo com uma única
  variável contínua e *feature* L gera uma só. Nesse caso a coluna é duplicada; no lasso a soma dos dois
  coeficientes equivale ao coeficiente único, sem alterar as predições.

## 08_TREINAMENTO.R – grade, seleção, Jackknife e ROC (aba 5)

- **Validação cruzada em blocos**: para cada modelo da grade e cada fold, o modelo é ajustado com os
  demais folds e avaliado no fold retirado; depois é ajustado com todo o treino.
- **Métricas por fold**: AUC presença–background de treino e de teste (estatística de Mann–Whitney);
  **AUC_dif** = AUC treino − AUC teste (indicador de sobreajuste; Warren & Seifert, 2011);
  **omissão P10** (fração das presenças de teste abaixo do 10º percentil das notas das presenças de
  treino) e **omissão MTP** (abaixo da menor nota de treino) (Radosavljevic & Anderson, 2014); **índice
  de Boyce contínuo** (Hirzel et al., 2006; `ecospat`); **ganho de teste**.
- **Modelo completo**: número de coeficientes não nulos e **AICc** aproximado, com a saída bruta
  normalizada sobre o background (Warren & Seifert, 2011).
- **Erros e convergência**: cada ajuste é executado com captura de erros e avisos (por exemplo, a não
  convergência do `glmnet`), registrados em `04_ERROS_AVISOS.csv`.
- **Recomendação (critério sequencial)**: menor omissão P10 média (tolerância de +2 pontos
  percentuais); entre os empatados, maior AUC de teste média; depois, menor número de coeficientes
  (Radosavljevic & Anderson, 2014; Kass et al., 2021). O usuário pode escolher outro modelo.
- **Jackknife** (Phillips et al., 2006; Ferreira, 2009): para o modelo escolhido, ajusta-se o modelo
  com **somente** cada variável, **sem** cada variável e com **todas**; calculam-se o ganho de treino, o
  ganho de teste e a AUC de teste (média dos folds). Ganho = média, nas presenças, do logaritmo da
  probabilidade normalizada sobre o background + log(nº de pontos de background), como no MaxEnt.
- **Curva ROC**: sensibilidade × (1 − especificidade) para o treino (modelo completo) e para o teste
  (predições fora do fold, empilhadas), com a diagonal do acaso (AUC = 0,5) e a referência 0,75.
- **Saídas**: `01_COMPOSICAO_FOLDS.csv`, métricas por fold, resumo de todos os modelos, erros e
  avisos, Jackknife, ROC, todos os modelos (`MODELOS_GRADE.rds`), modelo escolhido
  (`MODELO_ESCOLHIDO.rds`), gráficos G01–G03 e justificativa.

## 09_VALIDACAO.R – validação e teste externo (aba 6)

- **Métricas**: AUC, omissão P10 e MTP (**limiares definidos no treino**) e Boyce, lado a lado para
  treino, validação cruzada e validação; **AUC dentro de cada unidade** (presenças × background da
  própria propriedade/UPA), que separa a discriminação entre regiões da discriminação local; novidade
  ambiental univariada e classes de solo novas; curva ROC das três situações.
- **Interpretação**: a AUC com background mede discriminação entre presença e ambiente disponível, não
  entre presença e ausência, e deve ser interpretada com cautela (Lobo et al., 2008); o corte 0,75 segue
  Elith et al. (2006) e Ferreira (2009).
- **Proteção do teste externo**: se a validação contém propriedades reservadas, a avaliação é
  **confirmatória** – exige confirmação explícita, e cada abertura é registrada em
  `resultados/_geral/REGISTRO_TESTE_EXTERNO.csv` com uma impressão digital MD5 do protocolo
  (variáveis, parâmetros, plano e background). Se o teste for aberto novamente com outro protocolo, a
  ferramenta avisa que a avaliação deixou de ser independente.
- **Exportação para o QGIS**: `.tif` por propriedade (camada 1 = adequabilidade cloglog; camada 2 =
  mapa binário no limiar P10), calculados nos pixels válidos das UPAs, e `PONTOS_VALIDACAO.gpkg`
  (presenças e background com nota e situação captada/omitida).

# 3. Reprodutibilidade

- Sementes aleatórias registradas no log (padrão 20261125).
- Versões do R e dos pacotes registradas em cada execução.
- Arquivos `.rds` guardam o plano, a configuração, os modelos e o modelo escolhido, permitindo refazer
  qualquer etapa seguinte sem repetir as anteriores.

# 4. Pacotes

`maxnet` (Phillips et al., 2017), `glmnet` (Friedman et al., 2010), `ecospat` (Di Cola et al., 2017),
`terra` (Hijmans), `sf` (Pebesma, 2018), `usdm` (Naimi et al., 2014), `ggplot2`, `dplyr`, `tidyr`,
`shiny`, `bslib`, `DT`, `ps`, `jsonlite`, `rmarkdown`.

# 5. Referências

BARBET-MASSIN, M. et al. Selecting pseudo-absences for species distribution models: how, where and how many? *Methods in Ecology and Evolution*, v. 3, p. 327–338, 2012.

BARVE, N. et al. The crucial role of the accessible area in ecological niche modeling and species distribution modeling. *Ecological Modelling*, v. 222, p. 1810–1819, 2011.

CLARK, P. J.; EVANS, F. C. Distance to nearest neighbor as a measure of spatial relationships in populations. *Ecology*, v. 35, p. 445–453, 1954.

DI COLA, V. et al. ecospat: an R package to support spatial analyses and modeling of species niches and distributions. *Ecography*, v. 40, p. 774–787, 2017.

DORMANN, C. F. et al. Collinearity: a review of methods to deal with it and a simulation study evaluating their performance. *Ecography*, v. 36, p. 27–46, 2013.

ELITH, J. et al. Novel methods improve prediction of species' distributions from occurrence data. *Ecography*, v. 29, p. 129–151, 2006.

ELITH, J.; KEARNEY, M.; PHILLIPS, S. The art of modelling range-shifting species. *Methods in Ecology and Evolution*, v. 1, p. 330–342, 2010.

FERREIRA, G. C. *Modelagem ambiental de espécies de árvores [...]*. 2009. [completar: título completo, tipo de trabalho e instituição conforme o PDF].

FRIEDMAN, J.; HASTIE, T.; TIBSHIRANI, R. Regularization paths for generalized linear models via coordinate descent. *Journal of Statistical Software*, v. 33, n. 1, p. 1–22, 2010.

HILL, M. O. Diversity and evenness: a unifying notation and its consequences. *Ecology*, v. 54, p. 427–432, 1973.

HIRZEL, A. H. et al. Evaluating the ability of habitat suitability models to predict species presences. *Ecological Modelling*, v. 199, p. 142–152, 2006.

KARGER, D. N. et al. Climatologies at high resolution for the earth's land surface areas. *Scientific Data*, v. 4, 170122, 2017.

KASS, J. M. et al. ENMeval 2.0: redesigned for customizable and reproducible modeling of species' niches and distributions. *Methods in Ecology and Evolution*, v. 12, p. 1602–1608, 2021.

LOBO, J. M.; JIMÉNEZ-VALVERDE, A.; REAL, R. AUC: a misleading measure of the performance of predictive distribution models. *Global Ecology and Biogeography*, v. 17, p. 145–151, 2008.

MUSCARELLA, R. et al. ENMeval: an R package for conducting spatially independent evaluations and estimating optimal model complexity for Maxent ecological niche models. *Methods in Ecology and Evolution*, v. 5, p. 1198–1205, 2014.

NAIMI, B. et al. Where is positional uncertainty a problem for species distribution modelling? *Ecography*, v. 37, p. 191–203, 2014.

PEBESMA, E. Simple features for R: standardized support for spatial vector data. *The R Journal*, v. 10, p. 439–446, 2018.

PHILLIPS, S. J.; ANDERSON, R. P.; SCHAPIRE, R. E. Maximum entropy modeling of species geographic distributions. *Ecological Modelling*, v. 190, p. 231–259, 2006.

PHILLIPS, S. J.; DUDÍK, M. Modeling of species distributions with Maxent: new extensions and a comprehensive evaluation. *Ecography*, v. 31, p. 161–175, 2008.

PHILLIPS, S. J. et al. Sample selection bias and presence-only distribution models: implications for background and pseudo-absence data. *Ecological Applications*, v. 19, p. 181–197, 2009.

PHILLIPS, S. J. et al. Opening the black box: an open-source release of Maxent. *Ecography*, v. 40, p. 887–893, 2017.

RADOSAVLJEVIC, A.; ANDERSON, R. P. Making better Maxent models of species distributions: complexity, overfitting and evaluation. *Journal of Biogeography*, v. 41, p. 629–643, 2014.

ROBERTS, D. R. et al. Cross-validation strategies for data with temporal, spatial, hierarchical, or phylogenetic structure. *Ecography*, v. 40, p. 913–929, 2017.

VALAVI, R. et al. blockCV: an R package for generating spatially or environmentally separated folds for k-fold cross-validation of species distribution models. *Methods in Ecology and Evolution*, v. 10, p. 225–232, 2019.

WARREN, D. L.; SEIFERT, S. N. Ecological niche modeling in Maxent: the importance of model complexity and the performance of model selection criteria. *Ecological Applications*, v. 21, p. 335–342, 2011.
