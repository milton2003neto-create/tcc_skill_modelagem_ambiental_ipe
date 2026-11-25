# =============================================================================
# 06_SELECAO_VARIAVEIS.R
# -----------------------------------------------------------------------------
# O QUE FAZ: analisa redundancia (multicolinearidade) entre as 6 variaveis,
#            RECOMENDA um conjunto com justificativa e deixa o usuario escolher.
# ENTRADA : plano da etapa 2 (so as unidades de TREINO sao usadas -> a
#           validacao nao influencia a escolha das variaveis).
# SAIDAS  : resultados/<especie>/03_variaveis/<data_hora>/
#   01_CORRELACAO_PEARSON.csv, 02_CORRELACAO_SPEARMAN.csv, 03_VIF.csv,
#   04_SOLO_ETA.csv, 05_AUC_UNIVARIADA.csv, 06_RECOMENDACAO.csv,
#   ESCOLHA_VARIAVEIS.rds, JUSTIFICATIVA.txt, G01..G04 .png, LOG
# METODO  :
#   - Correlacao de Pearson (linear) e de Spearman (postos, robusta) entre as
#     variaveis continuas no BACKGROUND de treino (= ambiente disponivel).
#     Limiar |r| > 0,7 (Dormann et al., 2013). Padrao: usa o MAIOR |r| das duas.
#   - VIF (fator de inflacao da variancia; usdm::vif). Limiar 5 (conservador)
#     ou 10 (Naimi et al., 2014).
#   - Solo (categorica): razao de correlacao eta = sqrt(R2 de lm(x ~ solo)).
#   - AUC univariada (indicativa): GLM binomial presenca x background com
#     termo quadratico (continuas) ou fator (solo). Em cada par redundante,
#     recomenda manter a variavel que mais discrimina.
# PACOTES : usdm (VIF), ggplot2, dplyr, tidyr.
# =============================================================================

if (!exists("recomendar_plano")) source(file.path("R", "05_SELECAO_TREINO_VALIDACAO.R"), encoding = "UTF-8")

#' Marca papel e fold de cada ponto conforme o plano da etapa 2.
marcar_papel <- function(df, plano) {
  col <- if (plano$modo == "propriedade") "propriedade" else "upa_id"
  i <- match(df[[col]], plano$unidades$unidade)
  df$papel <- plano$unidades$papel[i]; df$fold <- plano$unidades$fold[i]
  df
}

#' AUC por postos (Mann-Whitney): prob. de uma presenca ter nota maior que um background.
auc_postos <- function(sp, sb) {
  r <- rank(c(sp, sb)); n1 <- length(sp); n0 <- length(sb)
  (sum(r[seq_len(n1)]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}

#' Matriz usada na regra: Pearson, Spearman ou o MAIOR |r| das duas (mais rigoroso).
matriz_regra <- function(P, S, metodo) {
  if (metodo == "pearson") P else if (metodo == "spearman") S else ifelse(abs(P) >= abs(S), P, S)
}

vif_seguro <- function(df) {
  if (ncol(df) < 2) return(data.frame(Variables = names(df), VIF = 1))
  usdm::vif(df)
}

analisar_variaveis <- function(plano, base, limiar_r = 0.7, limiar_vif = 5, metodo = "maior") {
  pr <- marcar_papel(base$presencas, plano); bg <- marcar_papel(base$background, plano)
  pr <- pr[pr$papel %in% "treino", ]; bg <- bg[bg$papel %in% "treino", ]
  vars <- names(VARIAVEIS); num <- setdiff(vars, VARIAVEIS_CATEGORICAS)
  bg$textura_subgrupo <- droplevels(bg$textura_subgrupo)

  P <- stats::cor(bg[, num], method = "pearson", use = "complete.obs")
  S <- stats::cor(bg[, num], method = "spearman", use = "complete.obs")
  M <- matriz_regra(P, S, metodo)
  vif_all <- vif_seguro(bg[, num])
  eta <- data.frame(variavel = num, eta_com_solo = sapply(num, function(v)
    sqrt(summary(stats::lm(bg[[v]] ~ bg$textura_subgrupo))$r.squared)), row.names = NULL)

  # AUC univariada (indicativa, no treino)
  dd <- rbind(transform(pr[, vars], y = 1), transform(bg[, vars], y = 0))
  dd$textura_subgrupo <- factor(as.character(dd$textura_subgrupo))
  auc <- sapply(vars, function(v) {
    f <- if (v %in% VARIAVEIS_CATEGORICAS) stats::as.formula(paste("y ~", v)) else stats::as.formula(sprintf("y ~ %s + I(%s^2)", v, v))
    s <- stats::predict(suppressWarnings(stats::glm(f, data = dd, family = stats::binomial())))
    auc_postos(s[dd$y == 1], s[dd$y == 0])
  })
  auc_tab <- data.frame(variavel = vars, rotulo = unname(VARIAVEIS[vars]), auc_univariada = round(auc, 3), row.names = NULL)

  # ---- Recomendacao -----------------------------------------------------------
  rec <- vars; motivo <- setNames(rep("mantida", length(vars)), vars)
  ij <- which(abs(M) > limiar_r & upper.tri(M), arr.ind = TRUE)
  if (nrow(ij)) {
    ij <- ij[order(-abs(M[ij])), , drop = FALSE]
    for (k in seq_len(nrow(ij))) {
      a <- num[ij[k, 1]]; b <- num[ij[k, 2]]
      if (!(a %in% rec && b %in% rec)) next
      sai <- if (auc[a] >= auc[b]) b else a; fica <- setdiff(c(a, b), sai)
      rec <- setdiff(rec, sai)
      motivo[sai] <- sprintf("removida: |r %s| = %.2f com %s (> %.2f) e AUC univariada menor (%.3f vs %.3f)",
                             metodo, abs(M[a, b]), VARIAVEIS[[fica]], limiar_r, auc[sai], auc[fica])
    }
  }
  repeat {
    nr <- intersect(rec, num); if (length(nr) < 2) break
    v <- vif_seguro(bg[, nr]); if (max(v$VIF) <= limiar_vif) break
    sai <- v$Variables[which.max(v$VIF)]; rec <- setdiff(rec, sai)
    motivo[sai] <- sprintf("removida: VIF = %.2f (> %g)", max(v$VIF), limiar_vif)
  }
  vif_rec <- vif_seguro(bg[, intersect(rec, num), drop = FALSE])
  recom <- data.frame(variavel = vars, rotulo = unname(VARIAVEIS[vars]), recomendada = vars %in% rec,
                      motivo = unname(motivo[vars]), auc_univariada = round(auc[vars], 3),
                      vif_todas = round(vif_all$VIF[match(vars, vif_all$Variables)], 2), row.names = NULL)

  just <- c(
    sprintf("Analise feita SOMENTE no treino: %d presencas e %d pontos de background (%s).", nrow(pr), nrow(bg),
            paste(unique(plano$unidades$unidade[plano$unidades$papel == "treino"]), collapse = ", ")),
    "A correlacao e o VIF usam o BACKGROUND (ambiente disponivel), como recomendado para modelos presenca-background.",
    sprintf("Regra: em cada par com |r de %s| > %.2f (Dormann et al., 2013) remove-se a variavel com MENOR AUC univariada;",
            metodo, limiar_r),
    sprintf("depois remove-se, uma a uma, a variavel com maior VIF enquanto algum VIF > %g (Naimi et al., 2014).", limiar_vif),
    paste0("Recomendadas: ", paste(VARIAVEIS[rec], collapse = ", "), "."),
    if (any(recom$motivo != "mantida")) paste("-", recom$rotulo[!recom$recomendada], ":", recom$motivo[!recom$recomendada])
    else "Nenhuma variavel redundante pelos limiares escolhidos: todas recomendadas.",
    {
      pp <- which(abs(P) > limiar_r - 0.15 & upper.tri(P), arr.ind = TRUE)
      if (nrow(pp)) paste0("Pares PERTO do limiar (Pearson ou Spearman >= ", limiar_r - 0.15, "): ",
                           paste(sprintf("%s x %s (Pearson %.2f; Spearman %.2f)", VARIAVEIS[num[pp[, 1]]], VARIAVEIS[num[pp[, 2]]],
                                         P[pp], S[pp]), collapse = "; "), ". Vale citar no TCC.")
    },
    if (any(eta$eta_com_solo > limiar_r)) paste0("ATENCAO: solo muito associado a ", paste(VARIAVEIS[eta$variavel[eta$eta_com_solo > limiar_r]], collapse = ", "),
                                                  " (eta > ", limiar_r, "); considere manter so um.") else
      "O solo nao e redundante com as continuas (eta <= limiar).",
    "A AUC univariada e so indicativa (modelo simples no proprio treino). A importancia real sai do Jackknife na etapa de treinamento.",
    "A decisao final e do usuario: variaveis com sentido ecologico claro podem ser mantidas mesmo correlacionadas, desde que justificado.")

  list(especie = base$especie, plano_origem = plano$origem, limiar_r = limiar_r, limiar_vif = limiar_vif, metodo = metodo,
       pearson = P, spearman = S, vif = vif_all, vif_recomendadas = vif_rec, eta = eta, auc = auc_tab,
       recomendacao = recom, recomendadas = rec, justificativa = just, n_pres = nrow(pr), n_bg = nrow(bg),
       pr = pr[, c(vars, "propriedade")], bg = bg[, c(vars, "propriedade")])
}

#' Confere a escolha manual do usuario (avisos de redundancia).
checar_escolha <- function(res, escolha) {
  av <- character(); num <- intersect(escolha, setdiff(names(VARIAVEIS), VARIAVEIS_CATEGORICAS))
  if (length(escolha) < 2) av <- c(av, "CRITICO: escolha pelo menos 2 variaveis.")
  M <- matriz_regra(res$pearson, res$spearman, res$metodo)
  if (length(num) >= 2) {
    m <- M[num, num]; ij <- which(abs(m) > res$limiar_r & upper.tri(m), arr.ind = TRUE)
    for (k in seq_len(nrow(ij))) av <- c(av, sprintf("ATENCAO: %s e %s correlacionadas (|r| = %.2f). Justifique se mantiver as duas.",
                                                     VARIAVEIS[num[ij[k, 1]]], VARIAVEIS[num[ij[k, 2]]], abs(m[ij[k, 1], ij[k, 2]])))
    v <- vif_seguro(res$bg[, num])
    if (any(v$VIF > res$limiar_vif)) av <- c(av, paste0("ATENCAO: VIF acima de ", res$limiar_vif, ": ",
                                                        paste(sprintf("%s = %.1f", VARIAVEIS[v$Variables[v$VIF > res$limiar_vif]], v$VIF[v$VIF > res$limiar_vif]), collapse = "; ")))
  }
  dif <- setdiff(union(escolha, res$recomendadas), intersect(escolha, res$recomendadas))
  if (length(dif)) av <- c(av, paste("REGISTRO: escolha difere da recomendacao em:", paste(VARIAVEIS[dif], collapse = ", ")))
  if (!length(av)) av <- "OK: escolha igual a recomendacao e sem redundancia."
  av
}

# ---- Graficos -----------------------------------------------------------------
grafico_correlacao <- function(res) {
  f <- function(m, nome) { d <- as.data.frame(as.table(m)); names(d) <- c("a", "b", "r"); d$metodo <- nome; d }
  d <- rbind(f(res$pearson, "Pearson"), f(res$spearman, "Spearman"))
  d$a <- factor(VARIAVEIS[as.character(d$a)], VARIAVEIS); d$b <- factor(VARIAVEIS[as.character(d$b)], rev(VARIAVEIS))
  ggplot(d, aes(a, b, fill = r)) + geom_tile(colour = "white") +
    geom_text(aes(label = sprintf("%.2f", r), fontface = ifelse(abs(r) > res$limiar_r & r < 0.999, "bold", "plain")), size = 3.5) +
    scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b", limits = c(-1, 1)) +
    facet_wrap(~metodo) + labs(x = NULL, y = NULL, fill = "r",
                               title = "Correlação entre variáveis (background de treino)",
                               subtitle = sprintf("Negrito = |r| > %.2f", res$limiar_r)) +
    theme_minimal(11) + theme(axis.text.x = element_text(angle = 35, hjust = 1))
}
grafico_vif <- function(res) {
  d <- res$vif; d$rotulo <- VARIAVEIS[d$Variables]
  ggplot(d, aes(reorder(rotulo, VIF), VIF, fill = VIF > res$limiar_vif)) + geom_col() + coord_flip() +
    geom_hline(yintercept = res$limiar_vif, linetype = 2, colour = "red") +
    scale_fill_manual(values = c(`FALSE` = "#4daf4a", `TRUE` = "#e41a1c"), guide = "none") +
    labs(x = NULL, y = "VIF (todas as contínuas juntas)", title = "Fator de inflação da variância") + theme_minimal(11)
}
grafico_densidades <- function(res) {
  num <- setdiff(names(VARIAVEIS), VARIAVEIS_CATEGORICAS)
  d <- rbind(transform(res$pr[, num], grupo = "Presença"), transform(res$bg[, num], grupo = "Background"))
  d <- tidyr::pivot_longer(d, all_of(num), names_to = "variavel"); d$variavel <- VARIAVEIS[d$variavel]
  ggplot(d, aes(value, fill = grupo)) + geom_density(alpha = 0.45, colour = NA) + facet_wrap(~variavel, scales = "free") +
    scale_fill_manual(values = c(Presença = "#7b3294", Background = "grey60")) +
    labs(x = NULL, y = "densidade", fill = NULL, title = "Presença × background no treino",
         subtitle = "Curvas separadas = a variável ajuda a distinguir onde o ipê ocorre") + theme_minimal(11) + theme(legend.position = "top")
}
grafico_auc_univ <- function(res) {
  d <- res$recomendacao
  ggplot(d, aes(reorder(rotulo, auc_univariada), auc_univariada, fill = recomendada)) + geom_col() + coord_flip(ylim = c(0.45, max(0.8, d$auc_univariada))) +
    geom_hline(yintercept = 0.5, linetype = 2) + scale_fill_manual(values = c(`TRUE` = "#1b7837", `FALSE` = "grey65"), labels = c(`TRUE` = "Recomendada", `FALSE` = "Não recomendada")) +
    labs(x = NULL, y = "AUC univariada (indicativa)", fill = NULL, title = "Quanto cada variável sozinha separa presença de background") +
    theme_minimal(11) + theme(legend.position = "top")
}

salvar_variaveis <- function(res, escolha, pasta_plano = NA) {
  pasta <- criar_pasta_saida(res$especie, "03_variaveis")
  av <- checar_escolha(res, escolha)
  salvar_csv(data.frame(variavel = rownames(res$pearson), round(res$pearson, 3), check.names = FALSE), pasta, "01_CORRELACAO_PEARSON.csv")
  salvar_csv(data.frame(variavel = rownames(res$spearman), round(res$spearman, 3), check.names = FALSE), pasta, "02_CORRELACAO_SPEARMAN.csv")
  salvar_csv(res$vif, pasta, "03_VIF.csv"); salvar_csv(res$eta, pasta, "04_SOLO_ETA.csv")
  salvar_csv(res$auc, pasta, "05_AUC_UNIVARIADA.csv")
  salvar_csv(transform(res$recomendacao, escolhida = variavel %in% escolha), pasta, "06_RECOMENDACAO.csv")
  saveRDS(list(especie = res$especie, variaveis = escolha, recomendadas = res$recomendadas, avisos = av,
               limiar_r = res$limiar_r, limiar_vif = res$limiar_vif, metodo = res$metodo, pasta_plano = pasta_plano),
          file.path(pasta, "ESCOLHA_VARIAVEIS.rds"))
  writeLines(c(res$justificativa, "", "ESCOLHA DO USUARIO:", paste("-", VARIAVEIS[escolha]), "", av), file.path(pasta, "JUSTIFICATIVA.txt"), useBytes = TRUE)
  gs <- list(G01_CORRELACAO = grafico_correlacao(res), G02_VIF = grafico_vif(res),
             G03_DENSIDADES = grafico_densidades(res), G04_AUC_UNIVARIADA = grafico_auc_univ(res))
  for (n in names(gs)) ggsave(file.path(pasta, paste0(n, ".png")), gs[[n]], width = 9, height = 5.5, dpi = 150, bg = "white")
  registrar_log(pasta, "03_variaveis", escolhas = list(variaveis_escolhidas = escolha, recomendadas = res$recomendadas,
                metodo = res$metodo, limiar_r = res$limiar_r, limiar_vif = res$limiar_vif, plano = pasta_plano,
                n_presencas_treino = res$n_pres, n_background_treino = res$n_bg), mensagens = av)
  pasta
}
