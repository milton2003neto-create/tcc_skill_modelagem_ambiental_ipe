# =============================================================================
# TCC IPES | R31 V1 - VALIDACAO EXTERNA EM 7 PROPRIEDADES
# =============================================================================
# Testar transferibilidade de modelos R28 LQH RM4
# Treino: 27 propriedades + 64 UPAs (R28)
# Validacao: 7 propriedades externas
# =============================================================================

versao <- 'R31_VALIDACAO_EXTERNA_V1_20261124'
versao_r28 <- 'R28_UPAS_B2_LQH_RM4_V1_1_20261118'

for (pacote in c('maxnet','ecospat','raster','sp')) {
  if (!requireNamespace(pacote,quietly=TRUE))
    stop('Instale ',pacote,' com install.packages("',pacote,'")',call.=FALSE)
}

parar <- function(ok,mensagem) {
  if (!isTRUE(ok)) stop('R31: ',mensagem,call.=FALSE)
}

ler <- function(p) utils::read.csv(p,fileEncoding='UTF-8-BOM',
                                  check.names=FALSE,stringsAsFactors=FALSE)

localizar_pasta <- function() {
  fontes <- unlist(lapply(sys.frames(),function(f) {
    if(is.null(f$ofile)) character() else as.character(f$ofile)
  }),use.names=FALSE)
  if(length(fontes)) {
    p <- dirname(normalizePath(tail(fontes,1),winslash='/',mustWork=TRUE))
    if(file.exists(file.path(p,'LEIA_PRIMEIRO.txt'))) return(p)
  }
  if(file.exists('LEIA_PRIMEIRO.txt'))
    return(normalizePath('.',winslash='/',mustWork=TRUE))
  stop('R31: extraia o pacote COMPLETO e abra o script nele.',call.=FALSE)
}

pasta <- localizar_pasta()
entrada <- file.path(pasta,'01_ENTRADAS_EXTERNAS')
saida <- file.path(pasta,'02_RESULTADOS_R31')

cat('R31 — VALIDACAO EXTERNA\n')
cat('Pasta base:', pasta, '\n')
cat('Versao:', versao, '\n')
cat('=============================================================================\n\n')

# =============================================================================
# VERIFICACOES INICIAIS
# =============================================================================

cat('PREFLIGHT CHECKS\n')
cat('---------\n')

# 1. Verificar que arquivos de entrada existem
cat('Verificando 01_ENTRADAS_EXTERNAS...\n')
parar(dir.exists(entrada), 'Pasta 01_ENTRADAS_EXTERNAS nao encontrada')

# 2. Verificar CSV de presencas
presencas_roxo <- file.path(entrada, 'Presencas_Roxo_7props.csv')
presencas_amarelo <- file.path(entrada, 'Presencas_Amarelo_7props.csv')

parar(file.exists(presencas_roxo), 'Presencas_Roxo_7props.csv nao encontrado')
parar(file.exists(presencas_amarelo), 'Presencas_Amarelo_7props.csv nao encontrado')

cat('  Presencas Roxo: OK\n')
cat('  Presencas Amarelo: OK\n')

# 3. Criar pasta saida
if (!dir.exists(saida)) dir.create(saida, recursive=TRUE, showWarnings=FALSE)
cat('Pasta 02_RESULTADOS_R31: OK\n')

# 4. Versoes dos pacotes
cat('\nVersoes dos pacotes:\n')
cat('  maxnet:', packageVersion('maxnet'), '\n')
cat('  ecospat:', packageVersion('ecospat'), '\n')

cat('\nPREFLIGHT OK — Pronto para validacao externa\n')
cat('=============================================================================\n\n')

# =============================================================================
# LEITURA DE PRESENCAS EXTERNAS
# =============================================================================

cat('LEITURA DE DADOS\n')
cat('----------------\n')

df_roxo <- ler(presencas_roxo)
df_amarelo <- ler(presencas_amarelo)

cat('Presencas Roxo: ', nrow(df_roxo), ' registros\n')
cat('Presencas Amarelo: ', nrow(df_amarelo), ' registros\n')

# Esperado: colunas lon, lat, propriedade
campos_roxo <- c('lon', 'lat', 'propriedade')
campos_amarelo <- c('lon', 'lat', 'propriedade')

parar(all(campos_roxo %in% names(df_roxo)),
      paste('Presencas Roxo sem colunas:', paste(campos_roxo, collapse=', ')))
parar(all(campos_amarelo %in% names(df_amarelo)),
      paste('Presencas Amarelo sem colunas:', paste(campos_amarelo, collapse=', ')))

cat('Estrutura: OK\n')

# Sumario por propriedade
cat('\nDistribuicao por propriedade:\n')
cat('  Roxo:\n')
print(table(df_roxo$propriedade))
cat('  Amarelo:\n')
print(table(df_amarelo$propriedade))

# =============================================================================
# LEITURA DE PREDITORES (TEMPLATE)
# =============================================================================

cat('\n')
cat('=============================================================================\n')
cat('PREDITORES EXTERNOS\n')
cat('=============================================================================\n\n')

# TEMPLATE: Substituir pela logica de leitura de preditores
# Esperado: grid ou data.frame com colunas
# altitude, declividade, dist_rio, BIO12, BIO17, solo (como fator)

cat('[TEMPLATE] Aguardando dados de preditores:\n')
cat('  - altitude\n')
cat('  - declividade\n')
cat('  - dist_rio\n')
cat('  - BIO12\n')
cat('  - BIO17\n')
cat('  - solo (categorico: 2,3,4,6,7)\n\n')

# =============================================================================
# CARREGAMENTO DE MODELOS R28 (TEMPLATE)
# =============================================================================

cat('=============================================================================\n')
cat('MODELOS R28 — CANDIDATOS PARA VALIDACAO\n')
cat('=============================================================================\n\n')

# TEMPLATE: Carregar RDS de R28
# modelo_roxo <- readRDS('path_to_R28_ROXO_LOCAL_UPAS_01_LQH_RM4.rds')
# modelo_amarelo <- readRDS('path_to_R28_AMARELO_LOCAL_UPAS_03_LQH_RM4.rds')

cat('[TEMPLATE] Modelos R28 a carregar:\n')
cat('  - R28_ROXO_LOCAL_UPAS_01_LQH_RM4.rds\n')
cat('  - R28_AMARELO_LOCAL_UPAS_03_LQH_RM4.rds\n\n')

# =============================================================================
# PREDICOES (TEMPLATE)
# =============================================================================

cat('=============================================================================\n')
cat('PREDICOES EM GRID 7 PROPRIEDADES EXTERNAS\n')
cat('=============================================================================\n\n')

cat('[TEMPLATE] Passos:\n')
cat('  1. Aplicar modelo_roxo em grid preditores\n')
cat('  2. Aplicar modelo_amarelo em grid preditores\n')
cat('  3. Usar predict(..., type="cloglog", clamp=TRUE)\n\n')

# =============================================================================
# CALCULO DE METRICAS (TEMPLATE)
# =============================================================================

cat('=============================================================================\n')
cat('METRICAS DE VALIDACAO\n')
cat('=============================================================================\n\n')

cat('[TEMPLATE] Calcular para cada propriedade externa:\n')
cat('  - AUC (previsoes vs presencas validacao)\n')
cat('  - Boyce (ecospat.boyce)\n')
cat('  - Omissao P10 (usar limiares de R28)\n')
cat('  - Coeficientes ativos\n\n')

# =============================================================================
# SAIDAS (TEMPLATE)
# =============================================================================

cat('=============================================================================\n')
cat('GERANDO SAIDAS\n')
cat('=============================================================================\n\n')

# CSV de validacao
validacao_template <- data.frame(
  id = character(),
  especie = character(),
  propriedade = character(),
  n_presencas = integer(),
  auc = numeric(),
  boyce = numeric(),
  status_boyce = character(),
  omissao_p10 = numeric(),
  limiar_p10 = numeric(),
  mediana_score = numeric(),
  status = character(),
  stringsAsFactors = FALSE
)

cat('[TEMPLATE] Estrutura CSV saida:\n')
cat('  Colunas:', paste(names(validacao_template), collapse=', '), '\n')
cat('  Linhas esperadas: 2 (Roxo + Amarelo) x 7 propriedades = 14\n\n')

# Salvar template CSV
csv_path <- file.path(saida, '31_VALIDACAO_EXTERNA_7_PROPRIEDADES.csv')
utils::write.csv(validacao_template, csv_path, row.names=FALSE, fileEncoding='UTF-8')
cat('Template CSV salvo:', csv_path, '\n\n')

# =============================================================================
# RELATORIO (TEMPLATE)
# =============================================================================

relatorio <- paste('
R31 — VALIDACAO EXTERNA TEMPLATE
Versao:', versao, '
Data:', Sys.Date(), '

TEMPLATE FRAMEWORK — Aguardando preenchimento dados

Modelos R28 candidatos:
  - Roxo: R28_ROXO_LOCAL_UPAS_01_LQH_RM4 (AUC 0.5566, Boyce 0.842)
  - Amarelo: R28_AMARELO_LOCAL_UPAS_03_LQH_RM4 (AUC 0.6813, Boyce 0.934)

Propriedades externas: 7 (Barro Branco, Curuça, Guariúba, Jatobá, etc.)

Entrada esperada:
  - Presencas_Roxo_7props.csv
  - Presencas_Amarelo_7props.csv
  - Preditores 30m (altitude, declividade, dist_rio, BIO12, BIO17, solo)

Saida esperada:
  - 31_VALIDACAO_EXTERNA_7_PROPRIEDADES.csv
  - 31_MAPAS_ROXO_*.png
  - 31_MAPAS_AMARELO_*.png

Esperado: AUC 20-40% menor vs R28 (transferencia verdadeira)
Criterio sucesso: AUC > 0.5, Boyce > 0 em >= 5/7 propriedades

Status: Template pronto
Proxima etapa: Preencher dados 7 propriedades
')

relatorio_path <- file.path(saida, '31_RELATORIO_TEMPLATE.txt')
cat(relatorio, file=relatorio_path)
cat('Relatorio template salvo:', relatorio_path, '\n\n')

cat('=============================================================================\n')
cat('R31 FRAMEWORK TEMPLATE COMPLETO\n')
cat('Status: Aguardando dados 7 propriedades externas\n')
cat('Arquivos gerados em:', saida, '\n')
cat('=============================================================================\n')
