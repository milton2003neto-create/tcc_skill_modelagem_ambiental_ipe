# =============================================================================
# 11_BUSCA_METODOLOGICA.R
# -----------------------------------------------------------------------------
# O QUE FAZ: busca sistematica da melhor configuracao metodologica, por
#            especie, usando SOMENTE as 27 propriedades de desenvolvimento.
#            As 7 reservadas ficam guardadas para confirmar o vencedor uma vez.
# CRITERIO DO "MELHOR": desempenho em PROPRIEDADE NOVA, na validacao
#   "deixar uma propriedade de fora" (LOPO - leave-one-property-out; Roberts
#   et al., 2017): cada propriedade com presencas vira teste uma vez; as
#   propriedades sem a especie formam um fold extra (so background).
#   Metricas com as predicoes fora do fold empilhadas: AUC, Boyce continuo,
#   omissao P10 (limiar do treino de cada fold) e AUC media DENTRO da
#   propriedade. Pontuacao = media dos postos (rank) das 4 metricas.
# ETAPAS:
#   A) as 57 combinacoes com >= 2 das 6 variaveis, com modelo fixo LQ RM 2;
#   B) as 3 melhores combinacoes x grade L/LQ/LQH x RM 0,5-4 (15 modelos);
#   C) o vencedor (e, para contraste, todas as variaveis) em outros desenhos:
#      propriedade x propriedade (3 e 5 folds), UPA x UPA (3 folds) e
#      aleatorio 50/50 - mostra como o desenho muda as metricas;
#   D) sensibilidade ao background: B2 x novos sorteios de 5.000 e 20.000.
# SAIDAS : resultados/<especie>/07_busca/<data_hora>/  (A..D .csv, graficos,
#          MELHOR_CONFIGURACAO.txt com o passo a passo para chegar nela no app)
# USO    : source("R/11_BUSCA_METODOLOGICA.R"); buscar(especie, nucleos = 2)
# =============================================================================

if (!exists("rodar_grade")) source(file.path("R", "08_TREINAMENTO.R"), encoding = "UTF-8")

#' Avalia uma configuracao numa particao (fpr/fbg = fold de cada presenca/background).
avaliar_cv <- function(pr, bg, vars, fc, rm, fpr, fbg, clamp = TRUE) {
  op <- c(); ob <- c(); omit <- 0; dentro <- c(); erros <- 0
  for (f in sort(unique(c(fpr, fbg)))) {
    tp <- fpr != f; tb <- fbg != f
    dm <- dados_maxnet(pr[tp, ], bg[tb, ], vars); a <- ajuste_seguro(dm$p, dm$x, fc, rm)
    if (is.null(a$modelo)) { erros <- erros + 1; next }
    sb <- prever(a$modelo, bg[!tb, vars, drop = FALSE], clamp); ob <- c(ob, sb)
    if (any(!tp)) {
      sp <- prever(a$modelo, pr[!tp, vars, drop = FALSE], clamp); op <- c(op, sp)
      thr <- stats::quantile(prever(a$modelo, pr[tp, vars, drop = FALSE], clamp), 0.10)
      omit <- omit + sum(sp < thr)
      if (length(sp) >= 10 && length(sb) >= 10) dentro <- c(dentro, auc_postos(sp, sb))
    }
  }
  data.frame(auc = auc_postos(op, ob), boyce = boyce(op, ob), omissao_p10 = omit / length(op),
             auc_dentro = mean(dentro), n_folds = length(unique(c(fpr, fbg))), erros = erros)
}

pontuar <- function(d) {
  r <- cbind(rank(-d$auc), rank(-d$boyce, na.last = TRUE), rank(d$omissao_p10), rank(-d$auc_dentro, na.last = TRUE))
  d$pontuacao <- round(rowMeans(r), 2); d[order(d$pontuacao, -d$auc), ]
}

dados_busca <- function(especie) {
  b <- carregar_dados_especie(especie)
  niv <- levels(b$background$textura_subgrupo)
  fx <- function(d) { d$textura_subgrupo <- factor(as.character(d$textura_subgrupo), levels = niv); d }
  pr <- fx(b$presencas); bg <- fx(b$background)
  props <- sort(unique(pr$propriedade))
  list(pr = pr, bg = bg, props = props,
       lopo_pr = match(pr$propriedade, props),
       lopo_bg = ifelse(bg$propriedade %in% props, match(bg$propriedade, props), length(props) + 1))
}

#' Folds de outros desenhos (unidades de desenvolvimento).
folds_desenho <- function(d, desenho, semente = SEMENTE_PADRAO) {
  if (desenho == "aleatorio_50_50") { set.seed(semente)
    return(list(pr = sample(rep(1:2, length.out = nrow(d$pr))), bg = sample(rep(1:2, length.out = nrow(d$bg))))) }
  modo <- if (startsWith(desenho, "upa")) "upa" else "propriedade"; k <- as.integer(sub(".*_k", "", desenho))
  base <- list(presencas = transform(d$pr, reservada = FALSE), background = transform(d$bg, reservada = FALSE))
  fo <- alocar_folds(tabela_unidades(base, modo), k); col <- if (modo == "upa") "upa_id" else "propriedade"
  list(pr = unname(fo[d$pr[[col]]]), bg = unname(fo[d$bg[[col]]]))
}

grafico_busca_vars <- function(a, especie) {
  a$rot <- sapply(strsplit(a$variaveis, "\\+"), function(v) paste(substr(sub("_.*", "", v), 1, 6), collapse = "+"))
  a <- head(a, 20); a$rot <- factor(a$rot, rev(a$rot))
  ggplot(a, aes(auc, rot, colour = boyce)) + geom_point(size = 3) +
    geom_point(data = a[1, ], shape = 21, size = 6, colour = "black") +
    scale_colour_viridis_c() + labs(x = "AUC em propriedade nova (LOPO)", y = NULL, colour = "Boyce",
    title = paste("20 melhores combinações de variáveis -", ESPECIES[[especie]]),
    subtitle = "Ordem = pontuação (AUC, Boyce, omissão P10 e AUC dentro da propriedade)") + theme_minimal(10)
}

buscar <- function(especie, nucleos = 2, top_vars = 3) {
  t0 <- Sys.time(); pasta <- criar_pasta_saida(especie, "07_busca"); d <- dados_busca(especie)
  vs <- names(VARIAVEIS)
  combos <- unlist(lapply(2:length(vs), function(k) utils::combn(vs, k, simplify = FALSE)), recursive = FALSE)
  cl <- parallel::makeCluster(nucleos); on.exit(parallel::stopCluster(cl))
  parallel::clusterCall(cl, function(r) { setwd(r); suppressMessages(source("R/11_BUSCA_METODOLOGICA.R", encoding = "UTF-8")); NULL }, RAIZ_PROJETO)
  parallel::clusterExport(cl, "d", envir = environment())
  msg <- function(...) message(sprintf("[%s] %s ", format(Sys.time(), "%H:%M"), especie), ...)

  # ---- A: combinacoes de variaveis --------------------------------------------------
  msg("A) ", length(combos), " combinacoes de variaveis (LQ RM2, LOPO, ", length(unique(c(d$lopo_pr, d$lopo_bg))), " folds)...")
  A <- do.call(rbind, parallel::parLapplyLB(cl, combos, function(v)
    cbind(variaveis = paste(v, collapse = "+"), n_vars = length(v), avaliar_cv(d$pr, d$bg, v, "lq", 2, d$lopo_pr, d$lopo_bg))))
  A <- pontuar(A); salvar_csv(A, pasta, "A_COMBINACOES_VARIAVEIS.csv")
  ggsave(file.path(pasta, "G01_COMBINACOES.png"), grafico_busca_vars(A, especie), width = 9, height = 6.5, dpi = 150, bg = "white")

  # ---- B: grade de parametros nas melhores combinacoes ---------------------------------
  g <- expand.grid(rm = c(0.5, 1, 2, 3, 4), fc = c("l", "lq", "lqh"), variaveis = head(A$variaveis, top_vars), stringsAsFactors = FALSE)
  msg("B) ", nrow(g), " modelos (", top_vars, " combinacoes x 15)...")
  B <- do.call(rbind, parallel::parLapplyLB(cl, split(g, seq_len(nrow(g))), function(x)
    cbind(variaveis = x$variaveis, features = toupper(x$fc), rm = x$rm,
          avaliar_cv(d$pr, d$bg, strsplit(x$variaveis, "\\+")[[1]], x$fc, x$rm, d$lopo_pr, d$lopo_bg))))
  B <- pontuar(B); salvar_csv(B, pasta, "B_GRADE_PARAMETROS.csv")
  w <- B[1, ]; wv <- strsplit(w$variaveis, "\\+")[[1]]; wfc <- tolower(w$features)

  # ---- C: desenhos de particao -----------------------------------------------------------
  des <- c("lopo", "propriedade_k3", "propriedade_k5", "upa_k3", "aleatorio_50_50")
  cc <- expand.grid(desenho = des, conjunto = c("vencedor", "todas_6"), stringsAsFactors = FALSE)
  msg("C) desenhos de particao...")
  C <- do.call(rbind, parallel::parLapplyLB(cl, split(cc, seq_len(nrow(cc))), function(x) {
    v <- if (x$conjunto == "vencedor") wv else names(VARIAVEIS)
    f <- if (x$desenho == "lopo") list(pr = d$lopo_pr, bg = d$lopo_bg) else folds_desenho(d, x$desenho)
    cbind(desenho = x$desenho, conjunto = x$conjunto, avaliar_cv(d$pr, d$bg, v, wfc, w$rm, f$pr, f$bg))
  }))
  salvar_csv(C, pasta, "C_DESENHOS.csv")

  # ---- D: sensibilidade ao background ------------------------------------------------------
  msg("D) background...")
  up <- pixels_por_upa(); up <- up[up$propriedade %in% unique(d$bg$propriedade), ]
  D <- do.call(rbind, lapply(c(B2 = 0, novo_5000 = 5000, novo_20000 = 20000), function(n) {
    bg <- if (n == 0) d$bg else { x <- sortear_background(up, n, SEMENTE_PADRAO + n, "BGB")
      x$textura_subgrupo <- factor(as.character(x$textura_subgrupo), levels = levels(d$bg$textura_subgrupo)); x }
    fb <- ifelse(bg$propriedade %in% d$props, match(bg$propriedade, d$props), length(d$props) + 1)
    cbind(n_background = nrow(bg), avaliar_cv(d$pr, bg, wv, wfc, w$rm, d$lopo_pr, fb))
  }))
  D <- cbind(background = rownames(D), D); salvar_csv(D, pasta, "D_BACKGROUND.csv")

  # ---- Relatorio ----------------------------------------------------------------------------
  min_tot <- round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1)
  rel <- c(sprintf("BUSCA METODOLOGICA - %s (%s min; %d combinacoes de variaveis, %d modelos na grade)", ESPECIES[[especie]], min_tot, nrow(A), nrow(B)),
    "Criterio: desempenho em propriedade nova (LOPO: cada propriedade com presencas vira teste uma vez), so desenvolvimento.",
    "", "MELHOR CONFIGURACAO:",
    sprintf("  Variaveis: %s", paste(VARIAVEIS[wv], collapse = "; ")),
    sprintf("  Modelo: features %s, RM %s, clamping, saida cloglog, background B2", w$features, w$rm),
    sprintf("  Em propriedade nova: AUC = %.3f; Boyce = %.2f; omissao P10 = %.1f%%; AUC dentro da propriedade = %.3f",
            w$auc, w$boyce, 100 * w$omissao_p10, w$auc_dentro),
    "", "COMPARACAO COM TODAS AS 6 VARIAVEIS (LQ RM2):",
    with(A[A$n_vars == 6, ], sprintf("  AUC = %.3f; Boyce = %.2f; omissao P10 = %.1f%%; AUC dentro = %.3f", auc, boyce, 100 * omissao_p10, auc_dentro)),
    "", "EFEITO DO DESENHO (mesmo modelo vencedor):",
    apply(C[C$conjunto == "vencedor", ], 1, function(r) sprintf("  %-16s AUC %.3f | Boyce %s | omissao %.1f%%", r[["desenho"]], as.numeric(r[["auc"]]),
                                                               format(round(as.numeric(r[["boyce"]]), 2)), 100 * as.numeric(r[["omissao_p10"]]))),
    "", "BACKGROUND:", apply(D, 1, function(r) sprintf("  %-11s n=%s AUC %.3f | Boyce %.2f", r[["background"]], r[["n_background"]], as.numeric(r[["auc"]]), as.numeric(r[["boyce"]]))),
    "", "COMO CHEGAR NELA NO APP:",
    "  Aba 2: Propriedade x propriedade, sem reservadas -> Gerar recomendacao -> Salvar plano",
    sprintf("  Aba 3: marcar SO: %s -> Salvar escolha", paste(VARIAVEIS[wv], collapse = "; ")),
    sprintf("  Aba 4: B2; features so %s; RM %s -> Salvar configuracao", w$features, w$rm),
    "  Aba 5: Rodar -> Jackknife + ROC -> Salvar.  Aba 6: Validar.",
    "  Teste externo: aba 2 com 'usar reservadas como validacao', repetir 3-5 e validar UMA vez (modo confirmatorio).")
  writeLines(rel, file.path(pasta, "MELHOR_CONFIGURACAO.txt"), useBytes = TRUE)
  registrar_log(pasta, "07_busca", escolhas = list(criterio = "LOPO, pontuacao por postos", combinacoes = nrow(A), grade = nrow(B),
                vencedor = list(variaveis = wv, features = w$features, rm = w$rm), minutos = min_tot), mensagens = rel)
  msg("FIM (", min_tot, " min): ", pasta)
  invisible(list(A = A, B = B, C = C, D = D, pasta = pasta, relatorio = rel))
}
