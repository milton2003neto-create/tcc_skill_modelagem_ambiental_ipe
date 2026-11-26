# =============================================================================
# 09_VALIDACAO.R
# -----------------------------------------------------------------------------
# O QUE FAZ: avalia o modelo escolhido (etapa 5) nas unidades de VALIDACAO do
#            plano: metricas globais e por propriedade/UPA, curva ROC treino x
#            validacao cruzada x validacao, novidade ambiental, e exporta mapas
#            (.tif) e pontos (.gpkg) para o QGIS.
#            PROTECAO DO TESTE EXTERNO: se a validacao contem propriedades
#            reservadas, a avaliacao e "confirmatoria": exige confirmacao,
#            registra o protocolo (impressao digital MD5) em
#            resultados/_geral/REGISTRO_TESTE_EXTERNO.csv e avisa se o teste
#            ja foi aberto antes com outro protocolo (deixa de ser independente).
# ENTRADA : MODELO_ESCOLHIDO.rds (+ 03_RESUMO_MODELOS.csv e 06_ROC.csv da etapa 5)
# SAIDAS  : resultados/<especie>/06_validacao/<data_hora>/
#   01_COMPARACAO_TREINO_VALIDACAO.csv, 02_METRICAS_POR_UNIDADE.csv,
#   03_NOVIDADE_AMBIENTAL.csv, 04_ROC.csv, PONTOS_VALIDACAO.gpkg,
#   mapas/<PROP>_adequabilidade.tif (camada 1 = cloglog; 2 = binario P10),
#   G01_ROC.png, G02_AUC_POR_UNIDADE.png, G03_NOTAS.png, G04_MAPA_ACERTOS.png,
#   JUSTIFICATIVA.txt, LOG
# METODO  : AUC presenca-background (Phillips et al., 2006), omissao no limiar
#   P10 e MTP definidos NO TREINO (Radosavljevic & Anderson, 2014), Boyce
#   continuo (Hirzel et al., 2006), AUC dentro de cada unidade (controla a
#   diferenca regional), novidade univariada fora da amplitude do treino
#   (como no R21; Elith et al., 2010). Interpretacao da AUC com cautela
#   (Lobo et al., 2008); corte 0,75 de Ferreira (2009)/Elith et al. (2006).
# PACOTES : maxnet, terra, sf, ecospat, ggplot2, tools (md5).
# =============================================================================

if (!exists("rodar_grade")) source(file.path("R", "08_TREINAMENTO.R"), encoding = "UTF-8")

ARQ_REGISTRO_EXTERNO <- file.path(PASTA_RESULTADOS, "_geral", "REGISTRO_TESTE_EXTERNO.csv")

#' Impressao digital do protocolo (o que define o modelo) - MD5.
protocolo_md5 <- function(me) {
  u <- me$cfg$plano$unidades
  obj <- list(me$especie, me$modelo, sort(me$variaveis), me$parametros$features, me$parametros$rm, me$clamp,
              me$cfg$plano$modo, sort(paste(u$unidade, u$papel, u$fold)), nrow(me$cfg$background$treino), me$cfg$background$origem)
  f <- tempfile(); saveRDS(obj, f, version = 3); unname(tools::md5sum(f))
}

#' Situacao do teste externo para esta especie/protocolo.
situacao_teste_externo <- function(me, base) {
  u <- me$cfg$plano$unidades; reserv <- unique(u$propriedade[u$reservada & u$papel == "validacao"])
  if (!length(reserv)) return(list(confirmatorio = FALSE, reservadas = character(), aberto_antes = FALSE,
                                   texto = "Validacao EXPLORATORIA (sem propriedades reservadas): pode repetir quantas vezes quiser."))
  reg <- if (file.exists(ARQ_REGISTRO_EXTERNO)) utils::read.csv2(ARQ_REGISTRO_EXTERNO, encoding = "UTF-8") else NULL
  md5 <- protocolo_md5(me); ant <- if (is.null(reg)) reg else reg[reg$especie == me$especie, ]
  aberto <- !is.null(ant) && nrow(ant) > 0; mesmo <- aberto && md5 %in% ant$protocolo_md5
  txt <- c(sprintf("Validacao CONFIRMATORIA: inclui reservadas (%s).", paste(reserv, collapse = ", ")),
           if (!aberto) "Primeira abertura do teste externo para esta especie: so faca quando TODAS as escolhas estiverem finais."
           else if (mesmo) "O teste externo ja foi aberto com ESTE MESMO protocolo: repetir nao muda nada (resultado identico)."
           else sprintf("ATENCAO: o teste externo ja foi aberto %d vez(es) com OUTRO protocolo (%s). Se o modelo foi mudado depois de ver o resultado, a avaliacao NAO e mais independente - declarar no TCC.",
                        nrow(ant), paste(unique(ant$data), collapse = ", ")))
  list(confirmatorio = TRUE, reservadas = reserv, aberto_antes = aberto, mesmo_protocolo = mesmo, md5 = md5, texto = txt)
}

registrar_teste_externo <- function(me, sit, auc_val) {
  linha <- data.frame(data = format(Sys.time(), "%Y-%m-%d %H:%M"), especie = me$especie, modelo = me$modelo,
                      protocolo_md5 = sit$md5, reservadas = paste(sit$reservadas, collapse = "; "), auc_validacao = round(auc_val, 4),
                      ja_aberto_antes = sit$aberto_antes)
  reg <- if (file.exists(ARQ_REGISTRO_EXTERNO)) rbind(utils::read.csv2(ARQ_REGISTRO_EXTERNO, encoding = "UTF-8"), linha) else linha
  dir.create(dirname(ARQ_REGISTRO_EXTERNO), recursive = TRUE, showWarnings = FALSE)
  salvar_csv(reg, dirname(ARQ_REGISTRO_EXTERNO), basename(ARQ_REGISTRO_EXTERNO))
}

# ---- Avaliacao ----------------------------------------------------------------------
validar_modelo <- function(me, base, pasta_treino = NA, confirmar_externo = FALSE) {
  sit <- situacao_teste_externo(me, base)
  if (sit$confirmatorio && !confirmar_externo)
    stop("A validacao inclui propriedades RESERVADAS (teste externo). Marque a confirmacao para abrir o teste.")
  cfg <- me$cfg; v <- me$variaveis; m <- me$maxnet; cl <- me$clamp
  col <- if (cfg$plano$modo == "propriedade") "propriedade" else "upa_id"
  niv <- levels(base$background$textura_subgrupo)
  fx <- function(d) { d$textura_subgrupo <- factor(as.character(d$textura_subgrupo), levels = niv); d }
  pr <- fx(marcar_papel(base$presencas, cfg$plano)); bgt <- fx(cfg$background$treino); bgv <- fx(cfg$background$validacao)
  ptr <- pr[pr$papel %in% "treino", ]; pva <- pr[pr$papel %in% "validacao", ]
  if (!nrow(pva)) stop("O plano nao tem presencas de validacao.")
  s_tr <- prever(m, ptr[, v], cl); s_btr <- prever(m, bgt[, v], cl); s_va <- prever(m, pva[, v], cl); s_bva <- prever(m, bgv[, v], cl)
  p10 <- stats::quantile(s_tr, 0.10, names = FALSE); mtp <- min(s_tr)

  # treino x validacao cruzada x validacao
  cv <- if (!is.na(pasta_treino) && file.exists(file.path(pasta_treino, "03_RESUMO_MODELOS.csv"))) {
    r <- utils::read.csv2(file.path(pasta_treino, "03_RESUMO_MODELOS.csv"), encoding = "UTF-8"); r[r$modelo == me$modelo, ] } else NULL
  comp <- data.frame(conjunto = c("Treino (modelo completo)", "Validacao cruzada (media dos folds)", "VALIDACAO"),
    n_presencas = c(nrow(ptr), NA, nrow(pva)), n_background = c(nrow(bgt), NA, nrow(bgv)),
    auc = c(auc_postos(s_tr, s_btr), if (!is.null(cv)) cv$auc_teste else NA, auc_postos(s_va, s_bva)),
    omissao_p10 = c(0.10, if (!is.null(cv)) cv$omissao_p10 else NA, mean(s_va < p10)),
    omissao_mtp = c(0, if (!is.null(cv)) cv$omissao_mtp else NA, mean(s_va < mtp)),
    boyce = c(boyce(s_tr, s_btr), if (!is.null(cv)) cv$boyce else NA, boyce(s_va, s_bva)))

  # por unidade de validacao (AUC dentro da unidade)
  unid <- unique(pva[[col]])
  por_u <- do.call(rbind, lapply(unid, function(u) {
    a <- s_va[pva[[col]] == u]; b <- s_bva[bgv[[col]] %in% u]
    data.frame(unidade = u, n_presencas = length(a), n_background = length(b),
               auc_dentro = if (length(a) >= 5 && length(b) >= 5) auc_postos(a, b) else NA,
               omissao_p10 = mean(a < p10), nota_media_presencas = mean(a), nota_media_background = if (length(b)) mean(b) else NA)
  }))
  por_u$reservada <- por_u$unidade %in% cfg$plano$unidades$unidade[cfg$plano$unidades$reservada]

  # novidade ambiental (univariada) e solo novo
  num <- setdiff(v, VARIAVEIS_CATEGORICAS); ref <- rbind(ptr[, v, drop = FALSE], bgt[, v, drop = FALSE])
  alvo <- rbind(pva[, c(col, v)], bgv[, c(col, v)])
  nov <- do.call(rbind, lapply(unique(alvo[[col]]), function(u) {
    a <- alvo[alvo[[col]] == u, ]
    fora <- sapply(num, function(x) mean(a[[x]] < min(ref[[x]]) | a[[x]] > max(ref[[x]])))
    data.frame(unidade = u, n_pontos = nrow(a), t(round(100 * fora, 1)), pct_fora_qualquer = round(100 * mean(apply(sapply(num, function(x)
      a[[x]] < min(ref[[x]]) | a[[x]] > max(ref[[x]])), 1, any)), 1),
      solo_novo = if ("textura_subgrupo" %in% v) paste(setdiff(unique(as.character(a$textura_subgrupo)), unique(as.character(ref$textura_subgrupo))), collapse = ",") else "")
  }))

  roc <- rbind(transform(pontos_roc(s_tr, s_btr), curva = sprintf("Treino (AUC = %.3f)", comp$auc[1])),
               transform(pontos_roc(s_va, s_bva), curva = sprintf("Validação (AUC = %.3f)", comp$auc[3])))
  if (!is.na(pasta_treino) && file.exists(file.path(pasta_treino, "06_ROC.csv"))) {
    rc <- utils::read.csv2(file.path(pasta_treino, "06_ROC.csv"), encoding = "UTF-8"); rc <- rc[grepl("^Teste", rc$curva), ]
    roc <- rbind(roc, rc[, c("fpr", "tpr", "curva")])
  }

  av <- sit$texto
  if (comp$auc[3] < 0.75) av <- c(av, sprintf("ATENCAO: AUC de validacao %.3f < 0,75 (corte de Ferreira, 2009).", comp$auc[3]))
  if (comp$omissao_p10[3] > 0.2) av <- c(av, sprintf("ATENCAO: omissao P10 na validacao = %.1f%% (esperado ~10%%). Ver novidade ambiental e AUC por unidade.", 100 * comp$omissao_p10[3]))
  if (comp$auc[1] - comp$auc[3] > 0.1) av <- c(av, sprintf("ATENCAO: queda de AUC treino -> validacao de %.3f: transferencia fraca.", comp$auc[1] - comp$auc[3]))
  if (any(nov$pct_fora_qualquer >= 20)) av <- c(av, paste0("ATENCAO: unidades com >= 20% dos pontos fora da amplitude do treino: ",
                                                            paste(nov$unidade[nov$pct_fora_qualquer >= 20], collapse = ", "), "."))
  if (any(nzchar(nov$solo_novo))) av <- c(av, "ATENCAO: classe de solo nova na validacao (o modelo nao conhece).")
  if (any(!is.na(por_u$auc_dentro) & por_u$auc_dentro < 0.6))
    av <- c(av, sprintf("Dentro de %d unidade(s) a AUC < 0,6: o modelo separa bem ENTRE regioes, mas pouco DENTRO da propriedade.",
                        sum(!is.na(por_u$auc_dentro) & por_u$auc_dentro < 0.6)))

  # o teste externo e registrado no momento em que o resultado e CALCULADO (= visto), nao so ao salvar
  if (sit$confirmatorio) registrar_teste_externo(me, sit, comp$auc[3])
  list(especie = me$especie, modelo = me$modelo, situacao = sit, comparacao = comp, por_unidade = por_u, novidade = nov,
       roc = roc, avisos = av, limiares = c(p10 = p10, mtp = mtp), col = col,
       pontos = rbind(data.frame(pva[, c("propriedade", "upa_id", "longitude", "latitude")], tipo = "presenca", nota = s_va),
                      data.frame(bgv[, c("propriedade", "upa_id", "longitude", "latitude")], tipo = "background", nota = s_bva)),
       me = me, pasta_treino = pasta_treino)
}

# ---- Mapas para o QGIS ----------------------------------------------------------------
mapa_propriedade <- function(me, prop, limiar, niveis) {
  mid <- terra::rast(file.path(PASTA_QGIS, "Mascaras UPAs inventariadas V3", prop, "mascara_upas_validas_30m.tif"))
  pil <- pilha_rasters(prop)
  if (!terra::compareGeom(mid, pil, stopOnError = FALSE)) pil <- terra::resample(pil, mid, method = "near")
  cel <- which(terra::values(mid, mat = FALSE) == 1)
  x <- as.data.frame(terra::extract(pil, cel))[, me$variaveis, drop = FALSE]
  if ("textura_subgrupo" %in% names(x)) x$textura_subgrupo <- factor(as.character(x$textura_subgrupo), levels = niveis)
  ok <- stats::complete.cases(x); s <- rep(NA_real_, length(cel)); s[ok] <- prever(me$maxnet, x[ok, , drop = FALSE], me$clamp)
  r <- terra::rast(mid, nlyrs = 2); r[] <- NA; r[[1]][cel] <- s; r[[2]][cel] <- as.integer(s >= limiar)
  names(r) <- c("adequabilidade_cloglog", "binario_P10"); r
}

grafico_auc_unidade <- function(va) {
  d <- va$por_unidade
  ggplot(d, aes(reorder(unidade, auc_dentro), auc_dentro, fill = reservada)) + geom_col() + coord_flip() +
    geom_hline(yintercept = c(0.5, 0.75), linetype = c(2, 3)) +
    scale_fill_manual(values = c(`FALSE` = "#2b83ba", `TRUE` = "#d7191c"), labels = c(`FALSE` = "Desenvolvimento", `TRUE` = "Reservada")) +
    labs(x = NULL, y = "AUC dentro da unidade (presenças × background da própria unidade)", fill = NULL,
         title = "Discriminação DENTRO de cada unidade de validação", subtitle = "Tracejado = acaso (0,5); pontilhado = 0,75") + theme_minimal(11)
}
grafico_notas <- function(va) {
  ggplot(va$pontos, aes(nota, fill = tipo)) + geom_density(alpha = 0.5, colour = NA) +
    geom_vline(xintercept = va$limiares["p10"], linetype = 2) +
    annotate("text", x = va$limiares["p10"], y = Inf, label = "limiar P10 (treino)", vjust = 1.5, hjust = -0.05, size = 3.2) +
    facet_wrap(~propriedade, scales = "free_y") + scale_fill_manual(values = c(presenca = "#7b3294", background = "grey60")) +
    labs(x = "Adequabilidade prevista (cloglog)", y = NULL, fill = NULL, title = "Notas do modelo na validação") + theme_minimal(10)
}
grafico_acertos <- function(va) {
  p <- va$pontos; p$classe <- ifelse(p$tipo == "background", "Background",
                                     ifelse(p$nota >= va$limiares["p10"], "Presença captada", "Presença omitida"))
  ggplot(p, aes(longitude, latitude, colour = classe)) + geom_point(data = p[p$tipo == "background", ], size = 0.3, alpha = 0.4) +
    geom_point(data = p[p$tipo != "background", ], size = 0.9) + coord_equal() +
    scale_colour_manual(values = c(Background = "grey70", `Presença captada` = "#1a9641", `Presença omitida` = "#d7191c")) +
    guides(colour = guide_legend(override.aes = list(size = 3, alpha = 1))) +
    labs(colour = NULL, title = "Presenças de validação captadas × omitidas (limiar P10)") + theme_minimal(11)
}

salvar_validacao <- function(va, base, mapas = c("validacao", "todas", "nenhum")) {
  mapas <- match.arg(mapas); pasta <- criar_pasta_saida(va$especie, "06_validacao")
  salvar_csv(va$comparacao, pasta, "01_COMPARACAO_TREINO_VALIDACAO.csv"); salvar_csv(va$por_unidade, pasta, "02_METRICAS_POR_UNIDADE.csv")
  salvar_csv(va$novidade, pasta, "03_NOVIDADE_AMBIENTAL.csv"); salvar_csv(va$roc, pasta, "04_ROC.csv")
  sf::st_write(sf::st_as_sf(transform(va$pontos, captada_p10 = nota >= va$limiares["p10"]), coords = c("longitude", "latitude"), crs = 4674),
               file.path(pasta, "PONTOS_VALIDACAO.gpkg"), quiet = TRUE, delete_dsn = TRUE)
  gs <- list(G01_ROC = grafico_roc(va$roc, paste("Curva ROC -", va$modelo)), G02_AUC_POR_UNIDADE = grafico_auc_unidade(va),
             G03_NOTAS = grafico_notas(va), G04_MAPA_ACERTOS = grafico_acertos(va))
  for (n in names(gs)) ggsave(file.path(pasta, paste0(n, ".png")), gs[[n]], width = if (n == "G01_ROC") 6.5 else 9,
                              height = if (n == "G01_ROC") 7 else 6, dpi = 150, bg = "white")
  props <- switch(mapas, validacao = unique(va$pontos$propriedade), todas = unique(c(base$presencas$propriedade, base$background$propriedade)), nenhum = character())
  if (length(props)) { dir.create(file.path(pasta, "mapas"), showWarnings = FALSE)
    for (p in props) terra::writeRaster(mapa_propriedade(va$me, p, va$limiares["p10"], levels(base$background$textura_subgrupo)),
                                        file.path(pasta, "mapas", paste0(gsub("[^A-Za-z0-9]", "_", iconv(p, to = "ASCII//TRANSLIT")), "_adequabilidade.tif")),
                                        overwrite = TRUE) }
  writeLines(c(sprintf("Modelo: %s | limiar P10 = %.4f | MTP = %.4f", va$modelo, va$limiares["p10"], va$limiares["mtp"]),
               apply(va$comparacao, 1, function(r) paste(names(r), r, sep = "=", collapse = "; ")), "", va$avisos),
             file.path(pasta, "JUSTIFICATIVA.txt"), useBytes = TRUE)
  registrar_log(pasta, "06_validacao", escolhas = list(modelo = va$modelo, treino = va$pasta_treino, confirmatorio = va$situacao$confirmatorio,
    reservadas = va$situacao$reservadas, protocolo_md5 = va$situacao$md5, mapas = mapas, n_mapas = length(props)), mensagens = va$avisos)
  pasta
}
