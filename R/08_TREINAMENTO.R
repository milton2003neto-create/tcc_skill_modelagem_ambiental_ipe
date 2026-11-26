# =============================================================================
# 08_TREINAMENTO.R
# -----------------------------------------------------------------------------
# O QUE FAZ: roda TODOS os modelos da grade (features x RM) na validacao
#            cruzada por blocos (folds de propriedades/UPAs do plano), registra
#            erros/avisos/convergencia, lista as metricas de todos, RECOMENDA um
#            modelo com justificativa e deixa o usuario escolher outro.
#            Para o modelo escolhido: Jackknife (estilo MaxEnt/Ferreira 2009) e
#            curva ROC (treino x teste da validacao cruzada).
# ENTRADA : CONFIG_MODELAGEM.rds (etapa 4) + presencas (base completa).
# SAIDAS  : resultados/<especie>/05_treino/<data_hora>/
#   01_COMPOSICAO_FOLDS.csv  (quais propriedades/UPAs em cada fold - para o TCC)
#   02_METRICAS_POR_FOLD.csv, 03_RESUMO_MODELOS.csv, 04_ERROS_AVISOS.csv,
#   05_JACKKNIFE.csv, 06_ROC.csv, MODELOS_GRADE.rds, MODELO_ESCOLHIDO.rds,
#   G01_MODELOS.png, G02_JACKKNIFE.png, G03_ROC.png, JUSTIFICATIVA.txt, LOG
# METODO  :
#   Validacao cruzada em blocos espaciais (Roberts et al., 2017; Valavi et al.,
#   2019): cada fold (grupo de propriedades/UPAs) e deixado de fora uma vez.
#   Metricas no fold de teste: AUC presenca-background; omissao P10 (limiar =
#   10o percentil das notas das presencas de treino) e MTP (menor nota de
#   treino); indice de Boyce continuo (Hirzel et al., 2006; ecospat);
#   AUC_dif = AUC treino - AUC teste (sobreajuste; Warren & Seifert, 2011).
#   AICc aproximado com a saida bruta normalizada no background (Warren &
#   Seifert, 2011). Escolha recomendada pelo criterio SEQUENCIAL: menor
#   omissao P10 media e, entre os empatados (ate +2 p.p.), maior AUC de teste
#   media (Radosavljevic & Anderson, 2014; Kass et al., 2021).
#   Jackknife: ganho de treino, ganho de teste e AUC de teste com a variavel
#   SOZINHA, SEM a variavel e com TODAS (Phillips et al., 2006; Ferreira, 2009).
#   Ganho = media do log da probabilidade normalizada nas presencas + log(n bg).
# PACOTES : maxnet, glmnet, ecospat, ggplot2.
# =============================================================================

if (!exists("ajustar_maxnet")) source(file.path("R", "07_BACKGROUND_E_PARAMETROS.R"), encoding = "UTF-8")

# ---- Dados de treino a partir da configuracao ------------------------------------
dados_treino_cfg <- function(cfg, base) {
  pr <- marcar_papel(base$presencas, cfg$plano); pr <- pr[pr$papel %in% "treino", ]
  niv <- levels(base$background$textura_subgrupo)
  fx <- function(d) { d$textura_subgrupo <- factor(as.character(d$textura_subgrupo), levels = niv); d }
  list(pr = fx(pr), bg = fx(cfg$background$treino), v = cfg$variaveis, k = sort(unique(stats::na.omit(pr$fold))), clamp = cfg$clamp)
}

prever <- function(m, x, clamp, tipo = "cloglog") {
  x <- as.data.frame(x); if (!is.null(m$coluna_dup)) x[[".dup"]] <- x[[m$coluna_dup]]
  as.numeric(stats::predict(m, x, type = tipo, clamp = clamp))
}

#' Ganho estilo MaxEnt: media de log(P normalizada no background) nas presencas + log(n bg).
ganho <- function(m, pres, bg, clamp) {
  lp <- prever(m, pres, clamp, "link"); lb <- prever(m, bg, clamp, "link"); mx <- max(lb)
  mean(lp - mx - log(sum(exp(lb - mx)))) + log(length(lb))
}

aicc_maxnet <- function(m, pres, bg, clamp) {
  lp <- prever(m, pres, clamp, "link"); lb <- prever(m, bg, clamp, "link"); mx <- max(lb)
  ll <- sum(lp - mx - log(sum(exp(lb - mx)))); K <- sum(m$betas != 0); n <- length(lp)
  if (K >= n - 1) return(NA_real_)
  2 * K - 2 * ll + 2 * K * (K + 1) / (n - K - 1)
}

boyce <- function(sp, sb) tryCatch(suppressWarnings(ecospat::ecospat.boyce(fit = c(sb, sp), obs = sp, PEplot = FALSE)$cor),
                                   error = function(e) NA_real_)

#' Ajuste com captura de erros e avisos (convergencia do glmnet etc.).
ajuste_seguro <- function(p, x, fc, rm) {
  av <- character()
  m <- withCallingHandlers(tryCatch(ajustar_maxnet(p, x, fc, rm), error = function(e) structure(conditionMessage(e), class = "erro")),
                           warning = function(w) { av <<- c(av, conditionMessage(w)); invokeRestart("muffleWarning") })
  list(modelo = if (inherits(m, "erro")) NULL else m, erro = if (inherits(m, "erro")) as.character(m) else NA_character_, avisos = unique(av))
}

# ---- Grade completa --------------------------------------------------------------
rodar_grade <- function(cfg, base, progresso = NULL) {
  d <- dados_treino_cfg(cfg, base); g <- cfg$grade; met <- list(); log_av <- list(); modelos <- list()
  tot <- nrow(g) * (length(d$k) + 1); i <- 0; t0 <- Sys.time()
  for (j in seq_len(nrow(g))) {
    fc <- g$features[j]; rm <- g$rm[j]; nome <- g$modelo[j]
    for (f in d$k) {
      i <- i + 1; if (!is.null(progresso)) progresso(i, tot, sprintf("%s - fold %s", nome, f))
      ptr <- d$pr[d$pr$fold != f, ]; btr <- d$bg[d$bg$fold != f, ]; pte <- d$pr[d$pr$fold == f, ]; bte <- d$bg[d$bg$fold == f, ]
      dm <- dados_maxnet(ptr, btr, d$v); a <- ajuste_seguro(dm$p, dm$x, fc, rm)
      log_av[[length(log_av) + 1]] <- data.frame(modelo = nome, fold = f, erro = a$erro,
                                                 avisos = if (length(a$avisos)) paste(a$avisos, collapse = " | ") else NA_character_)
      if (is.null(a$modelo)) next
      s_tr <- prever(a$modelo, ptr[, d$v], d$clamp); s_btr <- prever(a$modelo, btr[, d$v], d$clamp)
      s_te <- prever(a$modelo, pte[, d$v], d$clamp); s_bte <- prever(a$modelo, bte[, d$v], d$clamp)
      auc_tr <- auc_postos(s_tr, s_btr); auc_te <- auc_postos(s_te, s_bte)
      met[[length(met) + 1]] <- data.frame(modelo = nome, features = toupper(fc), rm = rm, fold = f,
        n_pres_teste = nrow(pte), n_bg_teste = nrow(bte), auc_treino = auc_tr, auc_teste = auc_te, auc_dif = auc_tr - auc_te,
        omissao_p10 = mean(s_te < stats::quantile(s_tr, 0.10)), omissao_mtp = mean(s_te < min(s_tr)),
        boyce = boyce(s_te, s_bte), ganho_teste = ganho(a$modelo, pte[, d$v], bte[, d$v], d$clamp))
    }
    # modelo completo (todo o treino)
    i <- i + 1; if (!is.null(progresso)) progresso(i, tot, sprintf("%s - modelo completo", nome))
    dm <- dados_maxnet(d$pr, d$bg, d$v); a <- ajuste_seguro(dm$p, dm$x, fc, rm)
    log_av[[length(log_av) + 1]] <- data.frame(modelo = nome, fold = "completo", erro = a$erro,
                                               avisos = if (length(a$avisos)) paste(a$avisos, collapse = " | ") else NA_character_)
    modelos[[nome]] <- a$modelo
  }
  met <- do.call(rbind, met); log_av <- do.call(rbind, log_av)
  res <- resumir_modelos(met, modelos, d, g)
  list(especie = cfg$especie, cfg = cfg, metricas_fold = met, resumo = res$resumo, recomendado = res$recomendado,
       justificativa = res$justificativa, erros_avisos = log_av, modelos = modelos,
       composicao = cfg$plano$composicao, minutos = round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1))
}

resumir_modelos <- function(met, modelos, d, g, tol_p10 = 0.02) {
  r <- stats::aggregate(cbind(auc_treino, auc_teste, auc_dif, omissao_p10, omissao_mtp, boyce, ganho_teste) ~ modelo,
                        data = met, FUN = function(x) mean(x, na.rm = TRUE), na.action = na.pass)
  sd_auc <- stats::aggregate(auc_teste ~ modelo, met, stats::sd); names(sd_auc)[2] <- "auc_teste_dp"
  r <- merge(merge(g, r, by = "modelo", all.x = TRUE), sd_auc, by = "modelo", all.x = TRUE)
  r$n_coef <- sapply(r$modelo, function(m) if (is.null(modelos[[m]])) NA else sum(modelos[[m]]$betas != 0))
  r$aicc <- sapply(r$modelo, function(m) if (is.null(modelos[[m]])) NA else
    aicc_maxnet(modelos[[m]], d$pr[, d$v], d$bg[, d$v], d$clamp))
  r$delta_aicc <- r$aicc - min(r$aicc, na.rm = TRUE)
  ok <- r[!is.na(r$omissao_p10), ]
  cand <- ok[ok$omissao_p10 <= min(ok$omissao_p10) + tol_p10, ]
  rec <- cand$modelo[order(-cand$auc_teste, cand$n_coef)][1]
  r$recomendado <- r$modelo == rec
  num <- sapply(r, is.numeric); r[num] <- lapply(r[num], round, 4)
  r <- r[order(r$omissao_p10, -r$auc_teste), ]
  x <- r[r$modelo == rec, ]; mA <- r[which.max(r$auc_teste), ]; mI <- r[which.min(r$aicc), ]
  just <- c(
    sprintf("Criterio sequencial: 1) menor omissao P10 media nos folds de teste (tolerancia +%g p.p.); 2) maior AUC de teste media; 3) menos coeficientes.", 100 * tol_p10),
    sprintf("RECOMENDADO: %s - omissao P10 = %.1f%%, AUC teste = %.3f (dp %.3f), AUC treino-teste = %.3f, Boyce = %.2f, %d coeficientes.",
            rec, 100 * x$omissao_p10, x$auc_teste, x$auc_teste_dp, x$auc_dif, x$boyce, x$n_coef),
    sprintf("Para comparar: maior AUC de teste = %s (%.3f; P10 %.1f%%); menor AICc = %s.", mA$modelo, mA$auc_teste, 100 * mA$omissao_p10, mI$modelo),
    if (x$auc_dif > 0.1) "ATENCAO: AUC treino muito maior que a de teste (> 0,10) -> sinal de sobreajuste; considere RM maior." else
      "Diferenca treino-teste pequena (<= 0,10): sem sinal forte de sobreajuste.",
    if (x$omissao_p10 > 0.3) "ATENCAO: omissao P10 alta (> 30%; o esperado e ~10%) -> o modelo transfere mal entre propriedades (ver diagnostico: concentracao e novidade ambiental)." else NULL,
    if (x$auc_teste < 0.7) "ATENCAO: AUC de teste < 0,70 (discriminacao fraca). Ferreira (2009) usou 0,75 como corte." else NULL,
    "Voce pode escolher outro modelo na tabela - a escolha fica registrada no log.")
  list(resumo = r, recomendado = rec, justificativa = just)
}

# ---- Jackknife (modelo escolhido) ------------------------------------------------
rodar_jackknife <- function(tr, modelo, base, progresso = NULL) {
  d <- dados_treino_cfg(tr$cfg, base); gg <- tr$cfg$grade[tr$cfg$grade$modelo == modelo, ]
  conj <- c(list(todas = d$v), setNames(lapply(d$v, function(v) v), paste0("so|", d$v)))
  if (length(d$v) > 1) conj <- c(conj, setNames(lapply(d$v, function(v) setdiff(d$v, v)), paste0("sem|", d$v)))
  tot <- length(conj) * (length(d$k) + 1); i <- 0; out <- list()
  for (nm in names(conj)) {
    vs <- conj[[nm]]; teste <- c()
    for (f in d$k) {
      i <- i + 1; if (!is.null(progresso)) progresso(i, tot, paste("Jackknife", nm, "fold", f))
      ptr <- d$pr[d$pr$fold != f, ]; btr <- d$bg[d$bg$fold != f, ]; pte <- d$pr[d$pr$fold == f, ]; bte <- d$bg[d$bg$fold == f, ]
      dm <- dados_maxnet(ptr, btr, vs); a <- ajuste_seguro(dm$p, dm$x, gg$features, gg$rm); if (is.null(a$modelo)) next
      teste <- rbind(teste, c(auc = auc_postos(prever(a$modelo, pte[, vs, drop = FALSE], d$clamp), prever(a$modelo, bte[, vs, drop = FALSE], d$clamp)),
                              ganho = ganho(a$modelo, pte[, vs, drop = FALSE], bte[, vs, drop = FALSE], d$clamp)))
    }
    i <- i + 1; if (!is.null(progresso)) progresso(i, tot, paste("Jackknife", nm, "completo"))
    dm <- dados_maxnet(d$pr, d$bg, vs); a <- ajuste_seguro(dm$p, dm$x, gg$features, gg$rm)
    tipo <- sub("\\|.*", "", nm); var <- if (nm == "todas") "(todas)" else sub(".*\\|", "", nm)
    out[[nm]] <- data.frame(tipo = c(todas = "Com todas", so = "Somente a variavel", sem = "Sem a variavel")[[tipo]], variavel = var,
      ganho_treino = if (is.null(a$modelo)) NA else ganho(a$modelo, d$pr[, vs, drop = FALSE], d$bg[, vs, drop = FALSE], d$clamp),
      ganho_teste = if (is.null(teste)) NA else mean(teste[, "ganho"]), auc_teste = if (is.null(teste)) NA else mean(teste[, "auc"]))
  }
  jk <- do.call(rbind, out); rownames(jk) <- NULL
  jk$rotulo <- ifelse(jk$variavel == "(todas)", "(todas)", VARIAVEIS[jk$variavel])
  jk
}

grafico_jackknife <- function(jk, modelo) {
  tod <- jk[jk$tipo == "Com todas", ]; d <- jk[jk$tipo != "Com todas", ]
  d <- tidyr::pivot_longer(d, c(ganho_treino, ganho_teste, auc_teste), names_to = "metrica")
  ref <- tidyr::pivot_longer(tod, c(ganho_treino, ganho_teste, auc_teste), names_to = "metrica")
  lab <- c(ganho_treino = "Ganho de treino", ganho_teste = "Ganho de teste", auc_teste = "AUC de teste")
  d$metrica <- factor(lab[d$metrica], lab); ref$metrica <- factor(lab[ref$metrica], lab)
  ggplot(d, aes(value, rotulo, fill = tipo)) + geom_col(position = position_dodge(0.8), width = 0.75) +
    geom_vline(data = ref, aes(xintercept = value), colour = "red", linewidth = 0.9) +
    facet_wrap(~metrica, scales = "free_x") +
    scale_fill_manual(values = c("Sem a variavel" = "#41b6c4", "Somente a variavel" = "#253494")) +
    labs(x = NULL, y = NULL, fill = NULL, title = paste("Jackknife das variáveis -", modelo),
         subtitle = "Linha vermelha = modelo com todas as variáveis") + theme_minimal(11) + theme(legend.position = "top")
}

# ---- Curva ROC ---------------------------------------------------------------------
pontos_roc <- function(sp, sb, n_max = 400) {
  s <- c(sp, sb); y <- c(rep(1, length(sp)), rep(0, length(sb))); o <- order(-s)
  tpr <- cumsum(y[o]) / length(sp); fpr <- cumsum(1 - y[o]) / length(sb)
  i <- unique(round(seq(1, length(s), length.out = min(n_max, length(s)))))
  data.frame(fpr = c(0, fpr[i]), tpr = c(0, tpr[i]))
}

#' ROC do modelo escolhido: treino (modelo completo) e teste (predicoes fora do fold, empilhadas).
roc_modelo <- function(tr, modelo, base) {
  d <- dados_treino_cfg(tr$cfg, base); gg <- tr$cfg$grade[tr$cfg$grade$modelo == modelo, ]; m <- tr$modelos[[modelo]]
  sp <- c(); sb <- c()
  for (f in d$k) {
    dm <- dados_maxnet(d$pr[d$pr$fold != f, ], d$bg[d$bg$fold != f, ], d$v); a <- ajuste_seguro(dm$p, dm$x, gg$features, gg$rm)
    if (is.null(a$modelo)) next
    sp <- c(sp, prever(a$modelo, d$pr[d$pr$fold == f, d$v], d$clamp)); sb <- c(sb, prever(a$modelo, d$bg[d$bg$fold == f, d$v], d$clamp))
  }
  tp <- prever(m, d$pr[, d$v], d$clamp); tb <- prever(m, d$bg[, d$v], d$clamp)
  rbind(transform(pontos_roc(tp, tb), curva = sprintf("Treino (AUC = %.3f)", auc_postos(tp, tb))),
        transform(pontos_roc(sp, sb), curva = sprintf("Teste - validação cruzada (AUC = %.3f)", auc_postos(sp, sb))))
}

grafico_roc <- function(roc, titulo = "Curva ROC", corte = 0.75) {
  ggplot(roc, aes(fpr, tpr, colour = curva)) + geom_line(linewidth = 1) +
    geom_abline(linetype = 2, colour = "grey40") +
    annotate("text", x = 0.75, y = 0.68, label = "Aleatório (AUC = 0,5)", colour = "grey40", size = 3.2, angle = 38) +
    coord_equal() + scale_colour_manual(values = c("#d7191c", "#2b83ba", "#1a9641", "#fdae61")) +
    labs(x = "1 - especificidade (fração do background prevista como adequada)", y = "Sensibilidade (presenças captadas)",
         colour = NULL, title = titulo, subtitle = sprintf("Referência: AUC >= %.2f (Ferreira, 2009)", corte)) +
    theme_minimal(11) + theme(legend.position = "bottom", legend.direction = "vertical")
}

grafico_modelos <- function(tr, escolhido = tr$recomendado) {
  r <- tr$resumo
  ggplot(r, aes(omissao_p10 * 100, auc_teste, colour = features, label = paste0("RM", rm))) +
    geom_errorbar(aes(ymin = auc_teste - auc_teste_dp, ymax = auc_teste + auc_teste_dp), width = 0, alpha = 0.4) +
    geom_point(size = 3) + geom_text(size = 2.8, vjust = -0.9, show.legend = FALSE) +
    geom_point(data = r[r$modelo == escolhido, ], shape = 21, size = 7, colour = "black", stroke = 1.2) +
    geom_vline(xintercept = 10, linetype = 3) +
    labs(x = "Omissão P10 média nos folds de teste (%)  - ideal ~10%", y = "AUC de teste média (barra = dp)", colour = "Features",
         title = "Todos os modelos da grade", subtitle = paste("Círculo = escolhido:", escolhido)) + theme_minimal(11)
}

# ---- Salvar ---------------------------------------------------------------------------
salvar_treino <- function(tr, escolhido, jk = NULL, roc = NULL, pasta_cfg = NA) {
  pasta <- criar_pasta_saida(tr$especie, "05_treino")
  salvar_csv(tr$composicao, pasta, "01_COMPOSICAO_FOLDS.csv"); salvar_csv(tr$metricas_fold, pasta, "02_METRICAS_POR_FOLD.csv")
  salvar_csv(transform(tr$resumo, escolhido = modelo == escolhido), pasta, "03_RESUMO_MODELOS.csv")
  salvar_csv(tr$erros_avisos, pasta, "04_ERROS_AVISOS.csv")
  if (!is.null(jk)) { salvar_csv(jk, pasta, "05_JACKKNIFE.csv")
    ggsave(file.path(pasta, "G02_JACKKNIFE.png"), grafico_jackknife(jk, escolhido), width = 11, height = 5.5, dpi = 150, bg = "white") }
  if (!is.null(roc)) { salvar_csv(roc, pasta, "06_ROC.csv")
    ggsave(file.path(pasta, "G03_ROC.png"), grafico_roc(roc, paste("Curva ROC -", escolhido)), width = 6.5, height = 7, dpi = 150, bg = "white") }
  ggsave(file.path(pasta, "G01_MODELOS.png"), grafico_modelos(tr, escolhido), width = 9, height = 6, dpi = 150, bg = "white")
  saveRDS(tr$modelos, file.path(pasta, "MODELOS_GRADE.rds"))
  saveRDS(list(especie = tr$especie, modelo = escolhido, maxnet = tr$modelos[[escolhido]], parametros = tr$cfg$grade[tr$cfg$grade$modelo == escolhido, ],
               variaveis = tr$cfg$variaveis, clamp = tr$cfg$clamp, cfg = tr$cfg, recomendado = tr$recomendado, pasta_cfg = pasta_cfg),
          file.path(pasta, "MODELO_ESCOLHIDO.rds"))
  n_av <- sum(!is.na(tr$erros_avisos$avisos)); n_er <- sum(!is.na(tr$erros_avisos$erro))
  writeLines(c(tr$justificativa, "", paste("ESCOLHIDO PELO USUARIO:", escolhido, if (escolhido != tr$recomendado) "(diferente do recomendado)" else "(= recomendado)"),
               sprintf("Ajustes com erro: %d; com avisos (ex.: convergencia do glmnet): %d. Detalhes em 04_ERROS_AVISOS.csv.", n_er, n_av),
               "", "COMPOSICAO DOS FOLDS:", apply(tr$composicao[, c("grupo", "unidades", "n_presencas")], 1, paste, collapse = " | ")),
             file.path(pasta, "JUSTIFICATIVA.txt"), useBytes = TRUE)
  registrar_log(pasta, "05_treino", escolhas = list(modelo_escolhido = escolhido, modelo_recomendado = tr$recomendado,
    grade = tr$cfg$grade$modelo, variaveis = tr$cfg$variaveis, configuracao = pasta_cfg, minutos_grade = tr$minutos,
    jackknife = !is.null(jk)), mensagens = c(tr$justificativa, sprintf("erros=%d avisos=%d", n_er, n_av)))
  pasta
}
