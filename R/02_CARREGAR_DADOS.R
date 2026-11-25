# =============================================================================
# 02_CARREGAR_DADOS.R
# -----------------------------------------------------------------------------
# O QUE FAZ: le os dados ja preparados no TCC (QGIS 01-13 e R01-R19) e devolve,
#            para UMA especie, uma tabela de presencas e uma de background
#            (ambiente disponivel) com as mesmas colunas.
# ENTRADAS : 05_PRESENCAS_UM_POR_PIXEL_30M.csv  (presencas DAP > 10 cm,
#              1 registro por especie por pixel de 30 m, 27 propriedades)
#            18_BACKGROUND_B2_10000_COM_FOLDS.csv (B2: 10.000 pontos sorteados
#              dentro das 64 UPAs inventariadas, com cotas por UPA - R18)
#            05_PLANO_FOLDS_V3.csv (folds por propriedade e as 7 reservadas)
# SAIDAS   : lista com $presencas, $background, $plano (data.frames).
# PACOTES  : utils (read.csv) e sf (projecao das coordenadas para metros).
# OBS.     : o background e COMUM as duas especies (e o ambiente das UPAs
#            inventariadas). Background NAO e ausencia comprovada.
# =============================================================================

if (!exists("RAIZ_PROJETO")) source(file.path("R", "01_CONFIGURACAO_E_FUNCOES.R"), encoding = "UTF-8")

COLUNAS_COMUNS <- c("tipo", "propriedade", "upa_id", "fold_cv", "longitude", "latitude", names(VARIAVEIS))

#' Le o plano de folds (inclui as 7 propriedades reservadas como "TESTE").
carregar_plano_folds <- function() {
  pl <- utils::read.csv2(ARQUIVOS$plano_folds, encoding = "UTF-8", check.names = FALSE)
  names(pl)[1] <- "propriedade"            # remove eventual BOM do Excel
  pl
}

#' Carrega presencas e background de uma especie.
#' @param especie "roxo" ou "amarelo"
carregar_dados_especie <- function(especie = c("roxo", "amarelo")) {
  especie <- match.arg(especie)
  pres <- utils::read.csv(ARQUIVOS$presencas, encoding = "UTF-8")
  pres <- pres[pres$especie == ESPECIES[[especie]], ]
  pres$tipo <- "presenca"

  bg <- utils::read.csv(ARQUIVOS$background_b2, encoding = "UTF-8")
  bg$tipo <- "background"

  pres <- pres[, COLUNAS_COMUNS]
  bg   <- bg[, c(COLUNAS_COMUNS, "id_background")]
  pres$id_background <- NA_character_

  # Textura do solo e categorica: codigos NAO tem ordem (2 nao e "menor" que 3).
  pres$textura_subgrupo <- factor(pres$textura_subgrupo)
  bg$textura_subgrupo   <- factor(bg$textura_subgrupo)

  list(especie = especie, presencas = pres, background = bg, plano = carregar_plano_folds())
}

#' Converte lon/lat (SIRGAS 2000) para metros (SIRGAS 2000 / Brazil Polyconic,
#' EPSG:5880), necessario para medir distancias reais entre pontos.
projetar_metros <- function(df) {
  s <- sf::st_as_sf(df, coords = c("longitude", "latitude"), crs = 4674)
  sf::st_coordinates(sf::st_transform(s, 5880))
}
