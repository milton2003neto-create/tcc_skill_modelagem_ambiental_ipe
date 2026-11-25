# =============================================================================
# 04_PREPARAR_PROPRIEDADES_RESERVADAS.R
# -----------------------------------------------------------------------------
# O QUE FAZ: monta presencas e background das 7 propriedades reservadas
#            (Barro Branco, Curuca, Guariuba, Jatoba, Lote 01, Marilia,
#            Palmeira) no MESMO formato das 27 de desenvolvimento, para que
#            possam ser usadas na validacao (ou movidas para o treino).
#            NAO calcula nenhuma metrica de desempenho - so prepara dados.
# ENTRADAS (pasta do QGIS, por propriedade):
#   Pontos com variaveis/<PROP>.gpkg           arvores com as 6 variaveis
#   Mascaras UPAs inventariadas V3/<PROP>/      mascara_upa_id_30m.tif e
#                                              mascara_upas_validas_30m.tif
#   Altitude e declividade/<PROP>/, Distancia aos rios/<PROP>/,
#   Clima e solo alinhados/<PROP>/              rasters 30 m (UTM)
# SAIDAS : resultados/_geral/00_reservadas/
#   PRESENCAS_RESERVADAS.csv, BACKGROUND_RESERVADAS.csv, RESUMO.csv, LOG
# METODO : mesmos criterios do desenvolvimento - DAP > 10 cm; 1 presenca por
#   especie por pixel de 30 m; background sorteado aleatoriamente nos pixels
#   validos das UPAs inventariadas com a MESMA densidade do B2
#   (pontos por pixel valido), estratificado por UPA (cota proporcional a area).
# PACOTES: sf (ler GeoPackage), terra (rasters, celulas, extracao).
# =============================================================================

if (!exists("carregar_dados_especie")) source(file.path("R", "02_CARREGAR_DADOS.R"), encoding = "UTF-8")

PASTA_QGIS <- file.path(PASTA_DADOS, "03 - Trabalho no QGIS", "02 - Arquivos gerados")
ARQ_RESERVADAS <- file.path(PASTA_RESULTADOS, "_geral", "00_reservadas")
NOME_CIENTIFICO <- c(roxo = "Handroanthus impetiginosus", amarelo = "Handroanthus serratifolius")

#' Le os 6 rasters de uma propriedade como uma pilha (mesma grade da mascara).
pilha_rasters <- function(prop) {
  r <- terra::rast(c(
    file.path(PASTA_QGIS, "Altitude e declividade", prop, "altitude_utm30m.tif"),
    file.path(PASTA_QGIS, "Altitude e declividade", prop, "declividade_graus_utm30m.tif"),
    file.path(PASTA_QGIS, "Distancia aos rios", prop, "distancia_rios_utm30m.tif"),
    file.path(PASTA_QGIS, "Clima e solo alinhados", prop, "bio12_utm30m.tif"),
    file.path(PASTA_QGIS, "Clima e solo alinhados", prop, "bio17_utm30m.tif"),
    file.path(PASTA_QGIS, "Clima e solo alinhados", prop, "textura_solo_utm30m.tif")))
  names(r) <- names(VARIAVEIS)
  r
}

#' Densidade do B2: pontos de background por pixel valido nas 27 propriedades.
densidade_b2 <- function() {
  pl <- carregar_plano_folds()
  10000 / sum(pl$pixels_validos_6[pl$conjunto == "DESENVOLVIMENTO"])
}

preparar_reservadas <- function(semente = SEMENTE_PADRAO, forcar = FALSE) {
  if (!forcar && file.exists(file.path(ARQ_RESERVADAS, "BACKGROUND_RESERVADAS.csv"))) {
    message("Reservadas ja preparadas (use forcar = TRUE para refazer).")
    return(invisible(ARQ_RESERVADAS))
  }
  dir.create(ARQ_RESERVADAS, recursive = TRUE, showWarnings = FALSE)
  dens <- densidade_b2(); set.seed(semente)
  pres_all <- list(); bg_all <- list(); resumo <- list(); msgs <- character()

  for (prop in PROPRIEDADES_RESERVADAS) {
    mask_id <- terra::rast(file.path(PASTA_QGIS, "Mascaras UPAs inventariadas V3", prop, "mascara_upa_id_30m.tif"))
    mask_ok <- terra::rast(file.path(PASTA_QGIS, "Mascaras UPAs inventariadas V3", prop, "mascara_upas_validas_30m.tif"))
    pilha <- pilha_rasters(prop)
    if (!terra::compareGeom(mask_id, pilha, stopOnError = FALSE)) {
      pilha <- terra::resample(pilha, mask_id, method = "near"); msgs <- c(msgs, paste(prop, ": rasters reamostrados para a grade da mascara"))
    }
    epsg <- terra::crs(mask_id, describe = TRUE)$code

    # --- Presencas: DAP > 10 cm, 1 por especie por pixel -----------------------
    pts <- sf::st_read(file.path(PASTA_QGIS, "Pontos com variaveis", paste0(prop, ".gpkg")), quiet = TRUE)
    pts <- sf::st_transform(pts, terra::crs(mask_id))
    pts <- pts[pts$elegivel_dap_gt10 == 1, ]
    xy <- sf::st_coordinates(pts)
    pts$celula_raster <- terra::cellFromXY(mask_id, xy)
    pts$upa_id <- paste0(prop, "|UPA ", sprintf("%02d", as.integer(pts$upa)))
    for (esp in names(NOME_CIENTIFICO)) {
      p <- pts[startsWith(pts$nome_cientifico, NOME_CIENTIFICO[[esp]]), ]
      p <- p[!duplicated(p$celula_raster), ]
      if (!nrow(p)) next
      d <- sf::st_drop_geometry(p)
      pres_all[[length(pres_all) + 1]] <- data.frame(
        tipo = "presenca", especie = ESPECIES[[esp]], propriedade = prop, upa_id = d$upa_id, fold_cv = NA,
        longitude = as.numeric(d$longitude), latitude = as.numeric(d$latitude),
        as.data.frame(lapply(d[, names(VARIAVEIS)], as.numeric)), celula_raster = d$celula_raster)
    }

    # --- Background: mesma densidade do B2, cota por UPA ----------------------
    validos <- which(terra::values(mask_ok, mat = FALSE) == 1)
    upas <- terra::values(mask_id, mat = FALSE)[validos]
    n_tot <- round(length(validos) * dens)
    cotas <- round(n_tot * table(upas) / length(upas))
    cel <- unlist(lapply(names(cotas), function(u) {
      c_u <- validos[upas == as.numeric(u)]; c_u[sample.int(length(c_u), min(cotas[[u]], length(c_u)))]
    }))
    v <- terra::extract(pilha, cel)
    ll <- sf::st_coordinates(sf::st_transform(sf::st_as_sf(as.data.frame(terra::xyFromCell(mask_id, cel)),
                                                           coords = c("x", "y"), crs = terra::crs(mask_id)), 4674))
    bg <- data.frame(tipo = "background", propriedade = prop,
                     upa_id = paste0(prop, "|UPA ", sprintf("%02d", as.integer(terra::values(mask_id, mat = FALSE)[cel]))),
                     fold_cv = NA, longitude = ll[, 1], latitude = ll[, 2], v, celula_raster = cel)
    bg <- bg[stats::complete.cases(bg[, names(VARIAVEIS)]), ]
    bg$id_background <- sprintf("BGR_%s_%05d", gsub("[^A-Z0-9]", "", toupper(iconv(prop, to = "ASCII//TRANSLIT"))), seq_len(nrow(bg)))
    bg_all[[prop]] <- bg
    resumo[[prop]] <- data.frame(propriedade = prop, epsg = epsg, pixels_validos = length(validos),
                                 n_background = nrow(bg), n_upas = length(cotas))
  }
  pres <- do.call(rbind, pres_all); bg <- do.call(rbind, bg_all); res <- do.call(rbind, resumo)
  cont <- as.data.frame.matrix(table(pres$propriedade, pres$especie))
  res <- cbind(res, cont[match(res$propriedade, rownames(cont)), , drop = FALSE]); res[is.na(res)] <- 0
  salvar_csv(pres, ARQ_RESERVADAS, "PRESENCAS_RESERVADAS.csv")
  salvar_csv(bg, ARQ_RESERVADAS, "BACKGROUND_RESERVADAS.csv")
  salvar_csv(res, ARQ_RESERVADAS, "RESUMO.csv")
  registrar_log(ARQ_RESERVADAS, "00_reservadas",
                escolhas = list(semente = semente, densidade_bg_por_pixel = signif(dens, 4), criterio = "DAP > 10 cm; 1 por pixel 30 m"),
                mensagens = c(msgs, "Somente preparacao de dados; nenhuma metrica de desempenho calculada."))
  print(res)
  invisible(ARQ_RESERVADAS)
}

#' Le as reservadas preparadas no formato de carregar_dados_especie().
carregar_reservadas <- function(especie) {
  if (!file.exists(file.path(ARQ_RESERVADAS, "BACKGROUND_RESERVADAS.csv"))) preparar_reservadas()
  pres <- utils::read.csv2(file.path(ARQ_RESERVADAS, "PRESENCAS_RESERVADAS.csv"), encoding = "UTF-8")
  bg   <- utils::read.csv2(file.path(ARQ_RESERVADAS, "BACKGROUND_RESERVADAS.csv"), encoding = "UTF-8")
  pres <- pres[pres$especie == ESPECIES[[especie]], ]
  pres$id_background <- NA_character_
  list(presencas = pres[, c(COLUNAS_COMUNS, "id_background")], background = bg[, c(COLUNAS_COMUNS, "id_background")])
}
