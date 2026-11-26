# =============================================================================
# 07_BACKGROUND_E_PARAMETROS.R
# -----------------------------------------------------------------------------
# O QUE FAZ: (a) define o BACKGROUND do treino (e da validacao);
#            (b) define a GRADE de parametros do maxnet (features x RM, clamping);
#            (c) ESTIMA tempo e memoria ANTES de rodar o treinamento.
# ENTRADAS: plano (etapa 2), variaveis escolhidas (etapa 3), mascaras e rasters
#           30 m de cada propriedade (pasta do QGIS).
# SAIDAS  : resultados/<especie>/04_parametros/<data_hora>/
#   CONFIG_MODELAGEM.rds (tudo que a etapa 5 precisa), 01_RESUMO_BACKGROUND.csv,
#   02_GRADE_PARAMETROS.csv, 03_ESTIMATIVA_CUSTO.csv, BACKGROUND.gpkg (QGIS),
#   G01_MAPA_BACKGROUND.png, JUSTIFICATIVA.txt, LOG
# METODO  :
#   Background - opcao 1: reaproveitar o B2 (10.000 pts nas UPAs inventariadas,
#     mesma densidade usada em R01-R30), todo ou subamostra estratificada;
#     opcao 2: NOVO sorteio aleatorio de N pontos nos pixels validos das UPAs
#     de treino, cota por UPA proporcional a area (n. de pixels), com semente.
#     Referencias: Phillips & Dudik (2008); Barbet-Massin et al. (2012) - 10.000
#     pontos sao suficientes para o MaxEnt.
#   Parametros - classes de features (L, Q, H, P) e multiplicador de
#     regularizacao RM (Phillips et al., 2017 - maxnet; Radosavljevic &
#     Anderson, 2014; Muscarella et al., 2014). Saida cloglog.
#   Custo - cronometra 1 ajuste real de cada classe de feature e multiplica
#     pelo numero de ajustes (grade x (k folds + 1) + Jackknife).
# PACOTES : maxnet, terra, sf, ps (memoria livre), ggplot2.
# =============================================================================

if (!exists("analisar_variaveis")) source(file.path("R", "06_SELECAO_VARIAVEIS.R"), encoding = "UTF-8")
if (!exists("pilha_rasters")) source(file.path("R", "04_PREPARAR_PROPRIEDADES_RESERVADAS.R"), encoding = "UTF-8")

FEATURES_DISPONIVEIS <- c("L (linear)" = "l", "LQ (linear + quadratica)" = "lq", "H (hinge)" = "h",
                          "LQH" = "lqh", "LQHP (com produto)" = "lqhp")

# ---- Pixels validos por UPA (cache) --------------------------------------------
pixels_por_upa <- function(forcar = FALSE) {
  arq <- file.path(PASTA_RESULTADOS, "_geral", "00_pixels_por_upa.csv")
  if (!forcar && file.exists(arq)) return(utils::read.csv2(arq, encoding = "UTF-8"))
  props <- list.dirs(file.path(PASTA_QGIS, "Mascaras UPAs inventariadas V3"), full.names = FALSE, recursive = FALSE)
  tab <- do.call(rbind, lapply(props, function(p) {
    ok <- terra::values(terra::rast(file.path(PASTA_QGIS, "Mascaras UPAs inventariadas V3", p, "mascara_upas_validas_30m.tif")), mat = FALSE)
    id <- terra::values(terra::rast(file.path(PASTA_QGIS, "Mascaras UPAs inventariadas V3", p, "mascara_upa_id_30m.tif")), mat = FALSE)
    t <- table(id[which(ok == 1)])
    data.frame(propriedade = p, upa_id = paste0(p, "|UPA ", sprintf("%02d", as.integer(names(t)))), pixels = as.integer(t))
  }))
  dir.create(dirname(arq), recursive = TRUE, showWarnings = FALSE); salvar_csv(tab, dirname(arq), basename(arq))
  tab
}

#' UPAs (com pixels) que pertencem as unidades de um papel no plano.
upas_do_papel <- function(plano, papel) {
  px <- pixels_por_upa(); col <- if (plano$modo == "propriedade") "propriedade" else "upa_id"
  px[px[[col]] %in% plano$unidades$unidade[plano$unidades$papel %in% papel], ]
}

#' Sorteia n pontos nos pixels validos das UPAs dadas (cota proporcional a area).
sortear_background <- function(upas, n, semente, prefixo = "BGN") {
  set.seed(semente)
  upas$cota <- as.integer(round(n * upas$pixels / sum(upas$pixels)))
  out <- lapply(split(upas, upas$propriedade), function(u) {
    prop <- u$propriedade[1]
    mid <- terra::rast(file.path(PASTA_QGIS, "Mascaras UPAs inventariadas V3", prop, "mascara_upa_id_30m.tif"))
    ok  <- terra::values(terra::rast(file.path(PASTA_QGIS, "Mascaras UPAs inventariadas V3", prop, "mascara_upas_validas_30m.tif")), mat = FALSE)
    idv <- terra::values(mid, mat = FALSE); pil <- pilha_rasters(prop)
    if (!terra::compareGeom(mid, pil, stopOnError = FALSE)) pil <- terra::resample(pil, mid, method = "near")
    validos <- which(ok == 1); id_val <- idv[validos]; rm(ok)
    cel <- unlist(lapply(seq_len(nrow(u)), function(i) {
      num <- as.integer(sub(".*UPA ", "", u$upa_id[i])); c_u <- validos[id_val == num]
      c_u[sample.int(length(c_u), min(u$cota[i], length(c_u)))]
    }))
    if (!length(cel)) return(NULL)
    ll <- sf::st_coordinates(sf::st_transform(sf::st_as_sf(as.data.frame(terra::xyFromCell(mid, cel)), coords = c("x", "y"),
                                                           crs = terra::crs(mid)), 4674))
    data.frame(tipo = "background", propriedade = prop, upa_id = paste0(prop, "|UPA ", sprintf("%02d", as.integer(idv[cel]))),
               fold_cv = NA, longitude = ll[, 1], latitude = ll[, 2], terra::extract(pil, cel))
  })
  bg <- do.call(rbind, out); bg <- bg[stats::complete.cases(bg[, names(VARIAVEIS)]), ]
  bg$id_background <- sprintf("%s_%05d", prefixo, seq_len(nrow(bg)))
  bg$textura_subgrupo <- factor(bg$textura_subgrupo); rownames(bg) <- NULL
  bg
}

#' Subamostra estratificada (por UPA) de um background existente.
subamostrar <- function(bg, n, semente) {
  if (n >= nrow(bg)) return(bg)
  set.seed(semente); q <- round(n * table(bg$upa_id) / nrow(bg))
  bg[unlist(lapply(names(q), function(u) { i <- which(bg$upa_id == u); i[sample.int(length(i), min(q[[u]], length(i)))] })), ]
}

# ---- Recomendacao de background ------------------------------------------------
recomendar_background <- function(plano, base) {
  bg <- marcar_papel(base$background, plano); pr <- marcar_papel(base$presencas, plano)
  n_b2 <- sum(bg$papel %in% "treino"); px <- sum(upas_do_papel(plano, "treino")$pixels)
  n_pr <- sum(pr$papel %in% "treino")
  list(origem = "b2", n = n_b2, n_b2_treino = n_b2, pixels_treino = px, n_pres_treino = n_pr,
       texto = c(sprintf("Treino: %d presencas, %s pixels validos de 30 m nas UPAs de treino.", n_pr, format(px, big.mark = ".", decimal.mark = ",")),
                 sprintf("RECOMENDADO: reaproveitar o B2 (%d pontos no treino = %.1f%% dos pixels).", n_b2, 100 * n_b2 / px),
                 "Motivo: e o mesmo background das rodadas R01-R30 (resultados comparaveis) e ja tem a densidade padrao do projeto.",
                 "Phillips & Dudik (2008) e Barbet-Massin et al. (2012): ~10.000 pontos bastam para o MaxEnt; aumentar muito so aumenta o tempo.",
                 sprintf("Um NOVO sorteio faz sentido para testar sensibilidade (ex.: N = 10.000 so no treino, %.1f%% dos pixels) ou outra semente.",
                         100 * min(1, 10000 / px)),
                 "A validacao continua com o background na MESMA densidade do B2, para que as AUCs sejam comparaveis."))
}

#' Monta o background final. origem: "b2" (todo/subamostra) ou "novo".
preparar_background <- function(plano, base, origem = "b2", n = NULL, semente = SEMENTE_PADRAO, novo_na_validacao = FALSE) {
  bg <- marcar_papel(base$background, plano)
  b2_tr <- bg[bg$papel %in% "treino", ]; b2_va <- bg[bg$papel %in% "validacao", ]
  if (origem == "b2") {
    tr <- if (is.null(n)) b2_tr else subamostrar(b2_tr, n, semente); va <- b2_va
  } else {
    up_tr <- upas_do_papel(plano, "treino")
    tr <- sortear_background(up_tr, n, semente, "BGN_TR")
    va <- if (novo_na_validacao && any(plano$unidades$papel == "validacao")) {
      up_va <- upas_do_papel(plano, "validacao")
      sortear_background(up_va, round(n * sum(up_va$pixels) / sum(up_tr$pixels)), semente + 1, "BGN_VA")
    } else b2_va
  }
  tr <- marcar_papel(tr, plano); va <- marcar_papel(va, plano)
  tr$textura_subgrupo <- factor(as.character(tr$textura_subgrupo), levels = levels(base$background$textura_subgrupo))
  va$textura_subgrupo <- factor(as.character(va$textura_subgrupo), levels = levels(base$background$textura_subgrupo))
  resumo <- rbind(
    data.frame(conjunto = "TREINO", fold = as.integer(names(table(tr$fold))), n_background = as.integer(table(tr$fold))),
    data.frame(conjunto = "VALIDACAO", fold = NA, n_background = nrow(va)))
  list(origem = origem, n_pedido = n, semente = semente, novo_na_validacao = novo_na_validacao,
       treino = tr, validacao = va, resumo = resumo)
}

# ---- Grade de parametros e custo ------------------------------------------------
recomendar_grade <- function() {
  list(features = c("l", "lq", "lqh"), rm = c(0.5, 1, 2, 3, 4), clamp = TRUE,
       texto = c("RECOMENDADO: features L, LQ e LQH x RM 0,5 / 1 / 2 / 3 / 4 (15 modelos), clamping ligado, saida cloglog.",
                 "Do simples (L) ao flexivel (LQH): permite ver se o ganho de complexidade se sustenta na validacao cruzada.",
                 "RM de 0,5 a 4 cobre a faixa usual (Radosavljevic & Anderson, 2014; Muscarella et al., 2014).",
                 "No R19 (manual do TCC) o melhor regional foi LQH com RM entre 2 e 4 - a grade inclui essa faixa.",
                 "H (hinge puro) e LQHP (produto) sao opcionais: mais flexiveis, mais lentos e com maior risco de sobreajuste.",
                 "Clamping: fora da faixa do treino a resposta fica 'congelada' no ultimo valor conhecido - evita extrapolacoes absurdas."))
}

grade_parametros <- function(features, rm) {
  g <- expand.grid(rm = sort(unique(rm)), features = features, stringsAsFactors = FALSE)[, 2:1]
  g$modelo <- sprintf("%s_RM%s", toupper(g$features), format(g$rm)); g
}

#' Dados no formato do maxnet (p = 1 presenca / 0 background).
dados_maxnet <- function(pres, bg, variaveis) {
  d <- rbind(pres[, variaveis, drop = FALSE], bg[, variaveis, drop = FALSE])
  list(p = c(rep(1, nrow(pres)), rep(0, nrow(bg))), x = d)
}

#' Ajusta o maxnet. Equivale a maxnet(..., addsamplestobackground = TRUE), mas
#' adiciona as presencas ao background de forma VETORIZADA: a versao interna do
#' maxnet 0.1.4 compara cada presenca com cada background convertendo para texto
#' (custo quadratico: ~5 min por ajuste com ~11 mil pontos). Aqui: segundos.
ajustar_maxnet <- function(p, x, features, rm) {
  chave <- do.call(paste, c(lapply(x, as.character), sep = "|"))
  novo <- which(p == 1)[!(chave[p == 1] %in% chave[p == 0])]
  x2 <- rbind(x, x[novo, , drop = FALSE]); p2 <- c(p, rep(0, length(novo)))
  maxnet::maxnet(p2, x2, maxnet::maxnet.formula(p, x, classes = features), regmult = rm, addsamplestobackground = FALSE)
}

#' Cronometra 1 ajuste por classe de feature e estima tempo/memoria totais.
estimar_custo <- function(pres_tr, bg_tr, variaveis, grade, k, jackknife = TRUE) {
  dm <- dados_maxnet(pres_tr, bg_tr, variaveis); seg <- c(); mb <- c()
  for (fc in unique(grade$features)) {
    t0 <- Sys.time(); m <- ajustar_maxnet(dm$p, dm$x, fc, 1)
    seg[fc] <- as.numeric(difftime(Sys.time(), t0, units = "secs")); mb[fc] <- as.numeric(utils::object.size(m)) / 2^20
  }
  n_aj <- k + 1                                      # k ajustes da validacao cruzada + 1 com todo o treino
  t_grade <- sum(seg[grade$features]) * n_aj
  n_jk <- if (jackknife) 2 * length(variaveis) * n_aj else 0
  t_jk <- n_jk * max(seg)
  mem_mod <- sum(mb[grade$features])                 # modelos finais guardados
  livre <- tryCatch(ps::ps_system_memory()$avail / 2^20, error = function(e) NA)
  tab <- data.frame(item = c("Ajustes da grade", "Ajustes do Jackknife (so no modelo escolhido)", "TOTAL"),
                    n_ajustes = c(nrow(grade) * n_aj, n_jk, nrow(grade) * n_aj + n_jk),
                    minutos = round(c(t_grade, t_jk, t_grade + t_jk) / 60, 1))
  av <- c(sprintf("Tempo de 1 ajuste com todo o treino: %s.", paste(sprintf("%s = %.1f s", toupper(names(seg)), seg), collapse = "; ")),
          sprintf("Tempo total estimado: ~%.0f min (estimativa; pode variar +-50%%).", (t_grade + t_jk) / 60),
          sprintf("Memoria: modelos guardados ~%.0f MB; memoria livre agora ~%s MB.", mem_mod, if (is.na(livre)) "?" else round(livre)))
  if ((t_grade + t_jk) / 60 > 60) av <- c(av, "ATENCAO: mais de 1 hora. Reduza a grade (menos RMs ou sem H/LQHP) ou rode com o PC livre.")
  if (!is.na(livre) && livre < 1024) av <- c(av, "ATENCAO: menos de 1 GB de RAM livre. Feche navegador/outros programas antes de treinar.")
  if (!is.na(livre) && mem_mod * 3 > livre) av <- c(av, "CRITICO: a memoria pode nao bastar. Reduza a grade.")
  list(tabela = tab, segundos_por_feature = seg, mb_por_modelo = mb, memoria_livre_mb = livre, avisos = av)
}

# ---- Grafico e salvamento ---------------------------------------------------------
grafico_background <- function(bgc, base, plano) {
  pr <- marcar_papel(base$presencas, plano); pr <- pr[pr$papel %in% c("treino", "validacao"), ]
  d <- rbind(data.frame(bgc$treino[, c("longitude", "latitude")], grupo = "Background - treino"),
             data.frame(bgc$validacao[, c("longitude", "latitude")], grupo = "Background - validação"),
             data.frame(pr[, c("longitude", "latitude")], grupo = ifelse(pr$papel == "treino", "Presença - treino", "Presença - validação")))
  ggplot(d, aes(longitude, latitude, colour = grupo)) + geom_point(size = 0.4, alpha = 0.5) + coord_equal() +
    scale_colour_manual(values = c("Background - treino" = "grey55", "Background - validação" = "#fdae61",
                                   "Presença - treino" = "#542788", "Presença - validação" = "#d73027")) +
    guides(colour = guide_legend(override.aes = list(size = 3, alpha = 1))) +
    labs(colour = NULL, title = sprintf("Background (%s) e presenças", if (bgc$origem == "b2") "B2" else "novo sorteio")) + theme_minimal(11)
}

salvar_config <- function(especie, plano, base, bgc, variaveis, grade, clamp, custo, pasta_plano = NA, pasta_var = NA) {
  pasta <- criar_pasta_saida(especie, "04_parametros")
  cfg <- list(especie = especie, plano = plano, variaveis = variaveis, background = bgc, grade = grade, clamp = clamp,
              k = length(unique(stats::na.omit(plano$unidades$fold[plano$unidades$papel == "treino"]))),
              custo = custo, pasta_plano = pasta_plano, pasta_variaveis = pasta_var, criado = format(Sys.time()))
  saveRDS(cfg, file.path(pasta, "CONFIG_MODELAGEM.rds"))
  salvar_csv(bgc$resumo, pasta, "01_RESUMO_BACKGROUND.csv"); salvar_csv(grade, pasta, "02_GRADE_PARAMETROS.csv")
  if (!is.null(custo)) salvar_csv(custo$tabela, pasta, "03_ESTIMATIVA_CUSTO.csv")
  g <- rbind(transform(bgc$treino[, c("id_background", "propriedade", "upa_id", "fold", "longitude", "latitude")], conjunto = "treino"),
             transform(bgc$validacao[, c("id_background", "propriedade", "upa_id", "fold", "longitude", "latitude")], conjunto = "validacao"))
  sf::st_write(sf::st_as_sf(g, coords = c("longitude", "latitude"), crs = 4674), file.path(pasta, "BACKGROUND.gpkg"), quiet = TRUE, delete_dsn = TRUE)
  ggsave(file.path(pasta, "G01_MAPA_BACKGROUND.png"), grafico_background(bgc, base, plano), width = 8, height = 6, dpi = 150, bg = "white")
  writeLines(c(sprintf("Background: %s; treino = %d pontos; validacao = %d pontos; semente = %s.",
                       if (bgc$origem == "b2") "B2 reaproveitado" else "NOVO sorteio", nrow(bgc$treino), nrow(bgc$validacao), bgc$semente),
               paste("Variaveis:", paste(VARIAVEIS[variaveis], collapse = "; ")),
               paste("Grade:", paste(grade$modelo, collapse = ", ")), paste("Clamping:", clamp),
               if (!is.null(custo)) custo$avisos), file.path(pasta, "JUSTIFICATIVA.txt"), useBytes = TRUE)
  registrar_log(pasta, "04_parametros", escolhas = list(
    background_origem = bgc$origem, n_background_treino = nrow(bgc$treino), n_background_validacao = nrow(bgc$validacao),
    n_pedido = bgc$n_pedido, semente = bgc$semente, novo_na_validacao = bgc$novo_na_validacao,
    variaveis = variaveis, features = unique(grade$features), rm = unique(grade$rm), clamp = clamp,
    saida = "cloglog", plano = pasta_plano, escolha_variaveis = pasta_var),
    mensagens = if (!is.null(custo)) custo$avisos else "Custo nao estimado.")
  pasta
}
