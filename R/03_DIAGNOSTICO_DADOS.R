# =============================================================================
# 03_DIAGNOSTICO_DADOS.R
# -----------------------------------------------------------------------------
# O QUE FAZ: analisa como as ocorrencias de UMA especie estao distribuidas
#            entre propriedades, UPAs e folds, e explica por que isso pode
#            causar AUC baixa e omissao alta. Nao ajusta nenhum modelo.
# ENTRADAS : saida de carregar_dados_especie() (script 02).
# SAIDAS   : resultados/<especie>/01_diagnostico/<data_hora>/
#   01_PRESENCAS_POR_PROPRIEDADE.csv  n de presencas, UPAs, BG, % e fold
#   02_PRESENCAS_POR_UPA.csv          o mesmo por UPA
#   03_INDICADORES_CONCENTRACAO.csv   Gini, n efetivo, % das maiores
#   04_BALANCO_FOLDS.csv              presencas/BG/propriedades por fold
#   05_NOVIDADE_AMBIENTAL_FOLDS.csv   % de presencas de validacao fora da
#                                     amplitude ambiental do treino (por fold)
#   06_SOLO_POR_FOLD.csv              classes de solo novas na validacao
#   07_PRESENCA_VS_BACKGROUND.csv     medianas e teste de Kolmogorov-Smirnov
#   08_AGREGACAO_ESPACIAL.csv         distancia ao vizinho mais proximo
#   G01..G06_*.png                    graficos
#   DIAGNOSTICO_EXPLICADO.txt         interpretacao automatica em portugues
#   LOG_EXECUCAO.txt/.json
# METODOS  : coeficiente de Gini e curva de Lorenz (concentracao); numero
#            efetivo de propriedades = 1/soma(p^2) (indice de Simpson inverso);
#            amplitude univariada (novidade, como no R21); teste de
#            Kolmogorov-Smirnov (presenca x background); razao das distancias
#            medias ao vizinho mais proximo presencas/background (agregacao).
# PACOTES  : dplyr, ggplot2, sf.
# =============================================================================

if (!exists("carregar_dados_especie")) source(file.path("R", "02_CARREGAR_DADOS.R"), encoding = "UTF-8")
suppressPackageStartupMessages({ library(dplyr); library(ggplot2) })

VARS_CONTINUAS <- setdiff(names(VARIAVEIS), VARIAVEIS_CATEGORICAS)

# ---- Funcoes de calculo (pequenas e testaveis) --------------------------------
gini <- function(x) {                       # 0 = igualdade total; 1 = tudo numa unidade
  x <- sort(x); n <- length(x); if (n < 2 || sum(x) == 0) return(NA_real_)
  sum((2 * seq_len(n) - n - 1) * x) / (n * sum(x))
}
n_efetivo <- function(x) { p <- x / sum(x); 1 / sum(p^2) }   # "quantas unidades equivalentes"

#' Distancia media (m) ao vizinho mais proximo; usa amostra para poupar memoria.
dist_vizinho <- function(xy, n_max = 1500, semente = SEMENTE_PADRAO) {
  set.seed(semente)
  if (nrow(xy) > n_max) xy <- xy[sample(nrow(xy), n_max), ]
  d <- as.matrix(stats::dist(xy)); diag(d) <- Inf
  mean(apply(d, 1, min))
}

# ---- Funcao principal ---------------------------------------------------------
#' @param dados  saida de carregar_dados_especie()
#' @param salvar TRUE grava arquivos em resultados/
#' @return lista com tabelas, graficos e texto explicativo
diagnosticar_especie <- function(dados, salvar = TRUE) {
  esp <- dados$especie; pres <- dados$presencas; bg <- dados$background
  nome_esp <- ESPECIES[[esp]]

  # 1. Presencas e background por propriedade ---------------------------------
  t_prop <- full_join(
    pres %>% count(propriedade, name = "n_presencas"),
    bg %>% group_by(propriedade) %>% summarise(n_background = n(), n_upas = n_distinct(upa_id),
                                               fold = first(fold_cv), .groups = "drop"),
    by = "propriedade") %>%
    mutate(n_presencas = coalesce(n_presencas, 0L),
           pct_presencas = round(100 * n_presencas / sum(n_presencas), 2),
           pres_por_100bg = round(100 * n_presencas / n_background, 1)) %>%
    left_join(pres %>% group_by(propriedade) %>% summarise(upas_com_presenca = n_distinct(upa_id)),
              by = "propriedade") %>%
    mutate(upas_com_presenca = coalesce(upas_com_presenca, 0L)) %>%
    arrange(desc(n_presencas))

  # 2. Por UPA ----------------------------------------------------------------
  t_upa <- full_join(pres %>% count(propriedade, upa_id, name = "n_presencas"),
                     bg %>% count(propriedade, upa_id, fold_cv, name = "n_background"),
                     by = c("propriedade", "upa_id")) %>%
    mutate(n_presencas = coalesce(n_presencas, 0L),
           pct_presencas = round(100 * n_presencas / sum(n_presencas), 2)) %>%
    arrange(desc(n_presencas))

  # 3. Concentracao ------------------------------------------------------------
  np <- t_prop$n_presencas
  t_conc <- data.frame(
    indicador = c("Propriedades no dominio (com background)", "Propriedades com presenca",
                  "Propriedades sem presenca (so background)", "UPAs com presenca", "UPAs no dominio",
                  "Gini entre propriedades (0-1)", "N efetivo de propriedades",
                  "% presencas na maior propriedade", "% presencas nas 3 maiores",
                  "% do background em propriedades sem presenca"),
    valor = c(nrow(t_prop), sum(np > 0), sum(np == 0), sum(t_upa$n_presencas > 0), nrow(t_upa),
              round(gini(np), 3), round(n_efetivo(np), 1),
              round(100 * max(np) / sum(np), 1), round(100 * sum(sort(np, TRUE)[1:3]) / sum(np), 1),
              round(100 * sum(t_prop$n_background[np == 0]) / sum(t_prop$n_background), 1)))

  # 4. Balanco dos folds -------------------------------------------------------
  t_fold <- t_prop %>% group_by(fold) %>%
    summarise(propriedades = paste(propriedade[n_presencas > 0], collapse = ", "),
              n_prop_com_presenca = sum(n_presencas > 0), n_presencas = sum(n_presencas),
              n_background = sum(n_background), .groups = "drop") %>%
    mutate(pct_presencas = round(100 * n_presencas / sum(n_presencas), 1))

  # 5. Novidade ambiental: validacao (fold k) x treino (demais folds) ----------
  t_nov <- do.call(rbind, lapply(sort(unique(bg$fold_cv)), function(k) {
    tr <- bg[bg$fold_cv != k, ]; va <- pres[pres$fold_cv == k, ]
    if (!nrow(va)) return(NULL)
    fora <- sapply(VARS_CONTINUAS, function(v) va[[v]] < min(tr[[v]]) | va[[v]] > max(tr[[v]]))
    data.frame(fold = k, n_presencas_validacao = nrow(va),
               t(round(100 * colMeans(fora), 1)),
               pct_fora_em_qualquer = round(100 * mean(rowSums(fora) > 0), 1), check.names = FALSE)
  }))

  # 6. Solo: classes na validacao que nao existem no treino --------------------
  t_solo <- do.call(rbind, lapply(sort(unique(bg$fold_cv)), function(k) {
    cl_tr <- unique(as.character(bg$textura_subgrupo[bg$fold_cv != k]))
    va <- pres[pres$fold_cv == k, ]
    data.frame(fold = k, classes_treino = paste(sort(cl_tr), collapse = " "),
               classes_validacao = paste(sort(unique(as.character(va$textura_subgrupo))), collapse = " "),
               presencas_em_classe_nova = sum(!as.character(va$textura_subgrupo) %in% cl_tr))
  }))

  # 7. Presenca x background (descritivo; NAO prova preferencia ecologica) -----
  t_pb <- do.call(rbind, lapply(VARS_CONTINUAS, function(v) {
    ks <- suppressWarnings(stats::ks.test(pres[[v]], bg[[v]]))
    data.frame(variavel = v, mediana_presenca = round(median(pres[[v]]), 2),
               mediana_background = round(median(bg[[v]]), 2),
               KS_D = round(unname(ks$statistic), 3), p_valor = signif(ks$p.value, 3))
  }))

  # 8. Agregacao espacial ------------------------------------------------------
  xy_p <- projetar_metros(pres); xy_b <- projetar_metros(bg)
  d_p <- dist_vizinho(xy_p); d_b <- dist_vizinho(xy_b, n_max = min(1500, nrow(xy_p)))
  t_agr <- data.frame(medida = c("Dist. media ao vizinho mais proximo - presencas (m)",
                                 "Dist. media ao vizinho mais proximo - background, mesma n (m)",
                                 "Razao presenca/background (<1 = presencas agrupadas)"),
                      valor = round(c(d_p, d_b, d_p / d_b), 2))

  # ---- Graficos -------------------------------------------------------------
  cores_fold <- c(`1` = "#1b9e77", `2` = "#d95f02", `3` = "#7570b3")
  g1 <- ggplot(t_prop, aes(reorder(propriedade, n_presencas), n_presencas, fill = factor(fold))) +
    geom_col() + coord_flip() + scale_fill_manual(values = cores_fold, name = "Fold") +
    labs(x = NULL, y = "N de presencas (1 por pixel de 30 m)",
         title = paste(nome_esp, "- presencas por propriedade")) + theme_minimal(11)
  lor <- data.frame(x = c(0, seq_along(np) / length(np)), y = c(0, cumsum(sort(np)) / sum(np)))
  g2 <- ggplot(lor, aes(x, y)) + geom_abline(linetype = 2, colour = "grey50") + geom_line(linewidth = 1) +
    labs(x = "Fracao acumulada das propriedades", y = "Fracao acumulada das presencas",
         title = sprintf("Curva de Lorenz - Gini = %.2f", gini(np)),
         subtitle = "Quanto mais longe da diagonal, mais concentradas as ocorrencias") + theme_minimal(11)
  g3 <- ggplot(t_fold, aes(factor(fold), n_presencas, fill = factor(fold))) + geom_col(show.legend = FALSE) +
    geom_text(aes(label = paste0(pct_presencas, "%")), vjust = -0.3) +
    scale_fill_manual(values = cores_fold) +
    labs(x = "Fold", y = "N de presencas", title = "Balanco das presencas entre folds") + theme_minimal(11)
  g4 <- ggplot() + geom_point(data = bg, aes(longitude, latitude), colour = "grey80", size = 0.3) +
    geom_point(data = pres, aes(longitude, latitude, colour = factor(fold_cv)), size = 0.6) +
    scale_colour_manual(values = cores_fold, name = "Fold") + coord_equal() +
    labs(title = paste(nome_esp, "- presencas (cor) sobre o background (cinza)")) + theme_minimal(11)
  longo <- rbind(data.frame(tipo = "presenca", pres[, VARS_CONTINUAS]),
                 data.frame(tipo = "background", bg[, VARS_CONTINUAS])) %>%
    tidyr::pivot_longer(-tipo, names_to = "variavel")
  g5 <- ggplot(longo, aes(tipo, value, fill = tipo)) + geom_boxplot(outlier.size = 0.3, show.legend = FALSE) +
    facet_wrap(~variavel, scales = "free_y") +
    labs(x = NULL, y = NULL, title = "Ambiente nas presencas x ambiente disponivel (background)") + theme_minimal(11)
  g6 <- ggplot(t_nov, aes(factor(fold), pct_fora_em_qualquer)) + geom_col(fill = "#c0392b") +
    geom_text(aes(label = paste0(pct_fora_em_qualquer, "%")), vjust = -0.3) + ylim(0, 105) +
    labs(x = "Fold de validacao", y = "% presencas fora da amplitude do treino",
         title = "Novidade ambiental: o modelo teria que extrapolar?") + theme_minimal(11)
  graficos <- list(G01_PRESENCAS_POR_PROPRIEDADE = g1, G02_CURVA_LORENZ = g2, G03_BALANCO_FOLDS = g3,
                   G04_MAPA_PONTOS = g4, G05_PRESENCA_VS_BACKGROUND = g5, G06_NOVIDADE_POR_FOLD = g6)

  texto <- explicar_diagnostico(nome_esp, t_conc, t_fold, t_nov, t_solo, t_agr, t_prop)

  res <- list(especie = esp, tabelas = list(
    `01_PRESENCAS_POR_PROPRIEDADE` = t_prop, `02_PRESENCAS_POR_UPA` = t_upa,
    `03_INDICADORES_CONCENTRACAO` = t_conc, `04_BALANCO_FOLDS` = t_fold,
    `05_NOVIDADE_AMBIENTAL_FOLDS` = t_nov, `06_SOLO_POR_FOLD` = t_solo,
    `07_PRESENCA_VS_BACKGROUND` = t_pb, `08_AGREGACAO_ESPACIAL` = t_agr),
    graficos = graficos, texto = texto)

  if (salvar) {
    pasta <- criar_pasta_saida(esp, "01_diagnostico")
    for (n in names(res$tabelas)) salvar_csv(res$tabelas[[n]], pasta, paste0(n, ".csv"))
    for (n in names(graficos)) ggsave(file.path(pasta, paste0(n, ".png")), graficos[[n]],
                                      width = 8, height = if (n == "G01_PRESENCAS_POR_PROPRIEDADE") 7 else 5.5, dpi = 150, bg = "white")
    writeLines(texto, file.path(pasta, "DIAGNOSTICO_EXPLICADO.txt"), useBytes = TRUE)
    registrar_log(pasta, "01_diagnostico", escolhas = list(especie = nome_esp,
                  background = "B2 (10.000 pontos)", n_presencas = nrow(pres)),
                  mensagens = "Diagnostico descritivo; nenhum modelo ajustado.")
    res$pasta <- pasta
  }
  res
}

# ---- Interpretacao automatica (regras simples e transparentes) ----------------
explicar_diagnostico <- function(nome_esp, t_conc, t_fold, t_nov, t_solo, t_agr, t_prop) {
  v <- setNames(t_conc$valor, t_conc$indicador)
  out <- c(paste0("DIAGNOSTICO DOS DADOS - ", toupper(nome_esp)), strrep("=", 60), "")
  achado <- function(titulo, txt) out <<- c(out, paste0("> ", titulo), strwrap(txt, 90, prefix = "  "), "")

  achado("Concentracao das ocorrencias", sprintf(
    "As presencas estao em %d de %d propriedades. A maior concentra %.1f%% e as 3 maiores %.1f%%. Gini = %.2f; equivale a apenas %.1f propriedades 'iguais'. %s",
    v[["Propriedades com presenca"]], v[["Propriedades no dominio (com background)"]],
    v[["% presencas na maior propriedade"]], v[["% presencas nas 3 maiores"]],
    v[["Gini entre propriedades (0-1)"]], v[["N efetivo de propriedades"]],
    if (v[["Gini entre propriedades (0-1)"]] > 0.6) "CONCENTRACAO ALTA: o modelo aprende sobretudo o ambiente de poucas propriedades e tende a falhar nas demais (baixa transferibilidade)." else "Concentracao moderada."))

  achado("Background sem presenca", sprintf(
    "%d propriedades (%.1f%% do background) nao tem registro da especie, mas entram como ambiente disponivel. Isso e correto (foram inventariadas), mas se o ambiente delas for parecido com o das presencas, a AUC cai: o modelo nao consegue separar presenca de ambiente disponivel.",
    v[["Propriedades sem presenca (so background)"]], v[["% do background em propriedades sem presenca"]]))

  pior <- t_fold[which.min(t_fold$pct_presencas), ]
  achado("Balanco entre folds", sprintf(
    "Fold %s tem so %.1f%% das presencas (%d pontos, propriedades: %s). %s",
    pior$fold, pior$pct_presencas, pior$n_presencas, pior$propriedades,
    if (pior$pct_presencas < 15) "DESBALANCEAMENTO FORTE: quando esse fold e validacao, a metrica e instavel; quando e treino, ele quase nao contribui. Isso ajuda a explicar omissao alta." else "Balanco aceitavel."))

  for (i in seq_len(nrow(t_nov))) {
    r <- t_nov[i, ]
    if (r$pct_fora_em_qualquer >= 20) achado(paste("Novidade ambiental no fold", r$fold), sprintf(
      "%.1f%% das presencas de validacao do fold %s estao FORA da amplitude ambiental do treino em ao menos uma variavel. O modelo tera que EXTRAPOLAR: RISCO de escores baixos e omissao alta (nem sempre acontece - depende da curva de resposta e do clamping; confirmar na validacao). Ver colunas por variavel em 05_NOVIDADE_AMBIENTAL_FOLDS.csv.",
      r$pct_fora_em_qualquer, r$fold))
  }
  sem_nov <- t_fold$fold[t_fold$pct_presencas < 15 & t_fold$fold %in% t_nov$fold[t_nov$pct_fora_em_qualquer < 5]]
  if (length(sem_nov)) achado(paste("Fold", paste(sem_nov, collapse = ", "), "pequeno e sem novidade univariada"),
    "Se houver omissao alta nesse fold, ela NAO se explica por extrapolacao de uma variavel isolada: considerar combinacoes ambientais diferentes, poucas propriedades no fold e fatores nao medidos (luz, historico de exploracao).")
  ns <- t_solo[t_solo$presencas_em_classe_nova > 0, ]
  if (nrow(ns)) achado("Solo", paste0("Ha presencas de validacao em classes de solo inexistentes no treino (fold ",
                        paste(ns$fold, collapse = ", "), "). O modelo nao tem resposta para essas classes."))
  razao <- t_agr$valor[3]
  achado("Agregacao espacial", sprintf(
    "Razao de distancia ao vizinho mais proximo = %.2f. %s", razao,
    if (razao < 0.5) "Presencas MUITO agrupadas: pontos vizinhos carregam informacao repetida (autocorrelacao), o que infla a AUC de treino e piora a transferencia." else "Agrupamento moderado."))
  out <- c(out, "LEMBRETE: estes resultados sao descritivos. Diferencas entre presenca e background",
           "nao provam preferencia ecologica; podem refletir onde os inventarios foram feitos.")
  out
}
