# =============================================================================
# 13_GRADE_COMPLETA.R
# -----------------------------------------------------------------------------
# O QUE FAZ: grade FATORIAL COMPLETA, por especie, com a mesma validacao LOPO
#            da busca (R/11): TODAS as 63 combinacoes das 6 variaveis (1 a 6
#            variaveis) x features L/LQ/LQH x RM 0,5/1/2/3/4 = 945 modelos.
#            Serve para mostrar na discussao que tudo foi testado e por que o
#            modelo escolhido foi escolhido (tabela completa + resumos).
# SEGURANCA: cada modelo avaliado e gravado na hora em GRADE_COMPLETA.csv; se o
#            R cair (pouca RAM), rodar de novo continua de onde parou.
# SAIDAS : resultados/<especie>/08_grade_completa/
#          GRADE_COMPLETA.csv          - os 945 modelos com AUC, Boyce, P10, AUC dentro
#          RESUMO_POR_VARIAVEL.csv     - desempenho medio COM x SEM cada variavel
#          RESUMO_POR_NVARS.csv        - melhor/mediana por numero de variaveis
#          RESUMO_POR_FEATURE_RM.csv   - efeito de features x RM
#          G_*.png                     - graficos
# USO    : Rscript R/13_GRADE_COMPLETA.R roxo 2    (especie, nucleos)
# =============================================================================

if (!exists("avaliar_cv")) source(file.path("R", "11_BUSCA_METODOLOGICA.R"), encoding = "UTF-8")

grade_completa <- function(especie, nucleos = 2) {
  pasta <- file.path(RAIZ_PROJETO, "resultados", especie, "08_grade_completa")
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  arq <- file.path(pasta, "GRADE_COMPLETA.csv")
  d <- dados_busca(especie); vs <- names(VARIAVEIS)
  combos <- unlist(lapply(seq_along(vs), function(k) utils::combn(vs, k, simplify = FALSE)), recursive = FALSE)
  g <- expand.grid(rm = c(0.5, 1, 2, 3, 4), fc = c("l", "lq", "lqh"),
                   variaveis = vapply(combos, paste, "", collapse = "+"), stringsAsFactors = FALSE)
  g$id <- paste(g$variaveis, g$fc, g$rm, sep = "|")
  feitos <- if (file.exists(arq)) utils::read.csv(arq, stringsAsFactors = FALSE)$id else character()
  falta <- g[!g$id %in% feitos, ]
  message(sprintf("[%s] %s: %d modelos no total, %d ja feitos, %d faltando",
                  format(Sys.time(), "%H:%M"), especie, nrow(g), length(feitos), nrow(falta)))
  if (nrow(falta)) {
    cl <- parallel::makeCluster(nucleos); on.exit(parallel::stopCluster(cl))
    parallel::clusterCall(cl, function(r) { setwd(r); suppressMessages(source("R/11_BUSCA_METODOLOGICA.R", encoding = "UTF-8")); NULL }, RAIZ_PROJETO)
    parallel::clusterExport(cl, "d", envir = environment())
    # lotes do tamanho do numero de nucleos: grava apos cada lote
    lotes <- split(falta, ceiling(seq_len(nrow(falta)) / nucleos))
    for (i in seq_along(lotes)) {
      r <- do.call(rbind, parallel::parLapply(cl, split(lotes[[i]], seq_len(nrow(lotes[[i]]))), function(x) {
        v <- strsplit(x$variaveis, "\\+")[[1]]; t1 <- Sys.time()
        cbind(id = x$id, variaveis = x$variaveis, n_vars = length(v), features = toupper(x$fc), rm = x$rm,
              avaliar_cv(d$pr, d$bg, v, x$fc, x$rm, d$lopo_pr, d$lopo_bg),
              segundos = round(as.numeric(difftime(Sys.time(), t1, units = "secs"))))
      }))
      utils::write.table(r, arq, sep = ",", row.names = FALSE, col.names = !file.exists(arq), append = file.exists(arq))
      if (i %% 10 == 0) message(sprintf("[%s] %s: %d/%d", format(Sys.time(), "%H:%M"), especie,
                                        length(feitos) + i * nucleos, nrow(g)))
      gc(verbose = FALSE)
    }
  }
  resumir_grade(especie)
}

resumir_grade <- function(especie) {
  pasta <- file.path(RAIZ_PROJETO, "resultados", especie, "08_grade_completa")
  G <- utils::read.csv(file.path(pasta, "GRADE_COMPLETA.csv"), stringsAsFactors = FALSE)
  G <- G[!duplicated(G$id), ]; G$id <- NULL
  G <- pontuar(G); G$posicao <- seq_len(nrow(G))
  salvar_csv(G, pasta, "GRADE_COMPLETA_ORDENADA.csv")
  vs <- names(VARIAVEIS)
  # COM x SEM cada variavel (todos os modelos)
  pv <- do.call(rbind, lapply(vs, function(v) {
    com <- grepl(v, G$variaveis, fixed = TRUE)
    data.frame(variavel = v, nome = VARIAVEIS[[v]],
               auc_com = mean(G$auc[com]), auc_sem = mean(G$auc[!com]),
               boyce_com = mean(G$boyce[com], na.rm = TRUE), boyce_sem = mean(G$boyce[!com], na.rm = TRUE),
               auc_sozinha_melhor = max(G$auc[G$variaveis == v]),
               presente_no_top10 = sum(com[1:10]), presente_no_top50 = sum(com[1:50]))
  }))
  pv$ganho_auc <- pv$auc_com - pv$auc_sem; pv <- pv[order(-pv$ganho_auc), ]
  salvar_csv(pv, pasta, "RESUMO_POR_VARIAVEL.csv")
  nv <- do.call(rbind, lapply(split(G, G$n_vars), function(x) data.frame(n_vars = x$n_vars[1], modelos = nrow(x),
        auc_max = max(x$auc), auc_mediana = stats::median(x$auc), boyce_mediana = stats::median(x$boyce, na.rm = TRUE),
        melhor = x$variaveis[1], melhor_features = x$features[1], melhor_rm = x$rm[1])))
  salvar_csv(nv, pasta, "RESUMO_POR_NVARS.csv")
  fr <- stats::aggregate(cbind(auc, boyce, omissao_p10) ~ features + rm, G, mean)
  salvar_csv(fr, pasta, "RESUMO_POR_FEATURE_RM.csv")

  rot <- function(x) sapply(strsplit(x, "\\+"), function(v) paste(substr(sub("_.*", "", v), 1, 6), collapse = "+"))
  t30 <- head(G, 30); t30$rot <- factor(paste0(rot(t30$variaveis), " ", t30$features, " RM", t30$rm), rev(paste0(rot(t30$variaveis), " ", t30$features, " RM", t30$rm)))
  ggsave(file.path(pasta, "G1_TOP30.png"), ggplot(t30, aes(auc, rot, colour = boyce)) + geom_point(size = 3) +
    scale_colour_viridis_c() + labs(x = "AUC em propriedade nova (LOPO)", y = NULL, colour = "Boyce",
    title = paste("30 melhores de", nrow(G), "modelos -", ESPECIES[[especie]])) + theme_minimal(10),
    width = 9, height = 8, dpi = 150, bg = "white")
  ggsave(file.path(pasta, "G2_NVARS.png"), ggplot(G, aes(factor(n_vars), auc)) + geom_boxplot(outlier.size = .7) +
    labs(x = "Numero de variaveis", y = "AUC em propriedade nova (LOPO)", title = paste("Todos os", nrow(G), "modelos -", ESPECIES[[especie]])) +
    theme_minimal(11), width = 7, height = 5, dpi = 150, bg = "white")
  ggsave(file.path(pasta, "G3_FEATURES_RM.png"), ggplot(fr, aes(rm, auc, colour = features)) + geom_line() + geom_point() +
    labs(x = "Multiplicador de regularizacao (RM)", y = "AUC media (LOPO)", colour = "Features",
    title = paste("Efeito das features e do RM -", ESPECIES[[especie]])) + theme_minimal(11), width = 7, height = 5, dpi = 150, bg = "white")
  pl <- rbind(data.frame(nome = pv$nome, tipo = "Com a variavel", auc = pv$auc_com), data.frame(nome = pv$nome, tipo = "Sem a variavel", auc = pv$auc_sem))
  ggsave(file.path(pasta, "G4_COM_SEM_VARIAVEL.png"), ggplot(pl, aes(auc, nome, fill = tipo)) + geom_col(position = "dodge") +
    coord_cartesian(xlim = c(min(pl$auc) - .03, max(pl$auc) + .01)) + labs(x = "AUC media dos modelos (LOPO)", y = NULL, fill = NULL,
    title = paste("Contribuicao de cada variavel em todos os modelos -", ESPECIES[[especie]])) + theme_minimal(10),
    width = 9, height = 5, dpi = 150, bg = "white")
  message("Resumo salvo em ", pasta)
  invisible(G)
}

if (sys.nframe() == 0) {
  a <- commandArgs(TRUE)
  grade_completa(a[1], if (length(a) > 1) as.integer(a[2]) else 2)
}
