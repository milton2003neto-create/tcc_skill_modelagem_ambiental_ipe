# =============================================================================
# 05_SELECAO_TREINO_VALIDACAO.R
# -----------------------------------------------------------------------------
# O QUE FAZ: define, para UMA especie, quais unidades (propriedades OU UPAs)
#            vao para TREINO e quais para VALIDACAO, e como o treino e dividido
#            em folds internos (validacao cruzada usada para escolher o modelo).
#            1) RECOMENDA automaticamente, com justificativa;
#            2) o usuario pode ALTERAR livremente (mover unidades, excluir,
#               mudar folds) - a funcao checar_plano() impede que uma unidade
#               esteja em treino e validacao ao mesmo tempo.
# DOIS DESENHOS (metodologias):
#   "propriedade": unidades = propriedades inteiras. Treino e validacao em
#        propriedades diferentes -> avalia TRANSFERENCIA ENTRE PROPRIEDADES
#        (validacao espacial em blocos; Roberts et al., 2017).
#   "upa": unidades = UPAs. Uma propriedade pode ter UPAs no treino e na
#        validacao -> avalia TRANSFERENCIA LOCAL entre UPAs (como Ferreira, 2009,
#        e R27-R30). UPAs vizinhas compartilham ambiente: a ferramenta avisa
#        a distancia ate a UPA de treino mais proxima.
# ENTRADAS : carregar_dados_especie() (02) + carregar_reservadas() (04).
# SAIDAS   : resultados/<especie>/02_selecao/<data_hora>/
#   PLANO_SELECAO.rds (usado nas etapas seguintes), 01_UNIDADES.csv,
#   02_COMPOSICAO_FOLDS.csv (quais propriedades/UPAs em cada fold - para o TCC),
#   03_AVISOS.txt, JUSTIFICATIVA.txt, G01_MAPA_SELECAO.png, LOG.
# METODOS  : ordenacao das unidades no gradiente ambiental (1o componente
#   principal das medianas ambientais do background de cada unidade) e escolha
#   espacada ao longo dele (validacao representativa); folds internos por
#   alocacao gulosa balanceando o numero de presencas; checagem de novidade
#   ambiental (amplitude univariada) e de proximidade (distancia minima entre
#   pontos de unidades diferentes, em metros, EPSG:5880).
# =============================================================================

if (!exists("carregar_reservadas")) source(file.path("R", "04_PREPARAR_PROPRIEDADES_RESERVADAS.R"), encoding = "UTF-8")
suppressPackageStartupMessages({ library(dplyr); library(ggplot2) })
VARS_CONTINUAS <- setdiff(names(VARIAVEIS), VARIAVEIS_CATEGORICAS)

#' Junta desenvolvimento + reservadas numa unica base da especie.
carregar_base_completa <- function(especie) {
  d <- carregar_dados_especie(especie); r <- carregar_reservadas(especie)
  for (k in c("presencas", "background")) {
    d[[k]]$reservada <- FALSE; r[[k]]$reservada <- TRUE
    r[[k]]$textura_subgrupo <- factor(r[[k]]$textura_subgrupo)
    d[[k]] <- rbind(d[[k]], r[[k]])
    d[[k]]$textura_subgrupo <- factor(as.character(d[[k]]$textura_subgrupo))
  }
  d
}

#' Tabela de unidades (uma linha por propriedade ou UPA).
tabela_unidades <- function(base, modo = c("propriedade", "upa")) {
  modo <- match.arg(modo); col <- if (modo == "propriedade") "propriedade" else "upa_id"
  bg <- base$background; pr <- base$presencas
  bg$unidade <- bg[[col]]; pr$unidade <- pr[[col]]
  u <- bg %>% group_by(unidade) %>%
    summarise(propriedade = first(propriedade), reservada = first(reservada), fold_original = first(fold_cv),
              n_background = n(), n_upas = n_distinct(upa_id),
              across(all_of(VARS_CONTINUAS), median, .names = "med_{.col}"), .groups = "drop") %>%
    left_join(pr %>% count(unidade, name = "n_presencas"), by = "unidade") %>%
    mutate(n_presencas = coalesce(n_presencas, 0L))
  # posicao no gradiente ambiental (PC1 das medianas padronizadas)
  m <- scale(as.matrix(u[, paste0("med_", VARS_CONTINUAS)]))
  m[is.na(m)] <- 0
  u$gradiente_pc1 <- round(stats::prcomp(m)$x[, 1], 3)
  u %>% arrange(desc(n_presencas))
}

#' Distribui unidades em k folds balanceando presencas (alocacao gulosa:
#' a maior unidade vai para o fold com menos presencas, e assim por diante).
alocar_folds <- function(unid, k = 3) {
  unid <- unid[order(-unid$n_presencas, -unid$n_background), ]
  carga_p <- numeric(k); carga_b <- numeric(k); f <- integer(nrow(unid))
  for (i in seq_len(nrow(unid))) {
    j <- if (unid$n_presencas[i] > 0) which.min(carga_p) else which.min(carga_b)
    f[i] <- j; carga_p[j] <- carga_p[j] + unid$n_presencas[i]; carga_b[j] <- carga_b[j] + unid$n_background[i]
  }
  setNames(f, unid$unidade)
}

#' RECOMENDACAO automatica.
#' @param pct_validacao  % alvo das presencas na validacao (ex.: 25)
#' @param min_presencas  minimo de presencas para uma unidade ser candidata a validacao
#' @param usar_reservadas TRUE = validacao = as 7 propriedades reservadas
#' @param k_folds        numero de folds internos no treino
recomendar_plano <- function(base, modo = "propriedade", pct_validacao = 25, min_presencas = 30,
                             usar_reservadas = FALSE, k_folds = 3) {
  u <- tabela_unidades(base, modo); just <- character()
  total <- sum(u$n_presencas[usar_reservadas | !u$reservada]); alvo <- total * pct_validacao / 100
  if (usar_reservadas) {
    val <- u$unidade[u$reservada]
    just <- c(just, sprintf("Validacao = unidades das 7 propriedades reservadas (%d unidades, %d presencas = %.0f%% do total).",
                            length(val), sum(u$n_presencas[u$reservada]), 100 * sum(u$n_presencas[u$reservada]) / total))
  } else {
    cand <- u[u$n_presencas >= min_presencas & u$n_presencas < max(u$n_presencas), ]
    if (modo == "upa") {   # no maximo 1 UPA por propriedade, e a propriedade precisa manter UPA com presenca no treino
      mult <- u %>% filter(n_presencas > 0) %>% count(propriedade) %>% filter(n >= 2) %>% pull(propriedade)
      cand <- cand[cand$propriedade %in% mult, ]
      cand <- cand %>% group_by(propriedade) %>% slice_min(abs(n_presencas - median(n_presencas)), n = 1, with_ties = FALSE) %>% ungroup()
    }
    cand <- cand[!cand$reservada, ]
    cand <- cand[order(cand$gradiente_pc1), ]
    val <- character()
    if (nrow(cand)) {   # m unidades espacadas no gradiente; escolhe m cuja soma fica mais perto do alvo
      opc <- lapply(seq_len(nrow(cand)), function(m) unique(round(seq(1, nrow(cand), length.out = m))))
      soma <- vapply(opc, function(i) sum(cand$n_presencas[i]), 0)
      val <- cand$unidade[opc[[which.min(abs(soma - alvo))]]]
    }
    if (!length(val) && nrow(cand)) val <- cand$unidade
    just <- c(just,
      sprintf("Alvo: ~%d%% das presencas na validacao (%d de %d). Escolhidas %d unidades com >= %d presencas, espacadas ao longo do gradiente ambiental (PC1) para que a validacao represente ambientes variados.",
              pct_validacao, round(alvo), total, length(val), min_presencas),
      "A maior unidade foi mantida no treino (retira-la tiraria grande parte da informacao do modelo).",
      if (modo == "upa") "Desenho UPA: no maximo 1 UPA de validacao por propriedade, e so em propriedades que mantem outra UPA com presenca no treino (como no R27)." else NULL)
  }
  u$papel <- ifelse(u$unidade %in% val, "validacao", ifelse(u$reservada, "reservada", "treino"))
  if (!usar_reservadas) just <- c(just, "As 7 propriedades reservadas ficam PROTEGIDAS (fora do treino e da validacao) - voce pode move-las manualmente.")
  tr <- u[u$papel == "treino", ]
  u$fold <- NA_integer_
  fo <- alocar_folds(tr, k_folds); u$fold[match(names(fo), u$unidade)] <- fo
  just <- c(just, sprintf("Treino dividido em %d folds internos por %s, balanceando o numero de presencas (alocacao gulosa). Cada fold e validado com o modelo treinado nos demais - isso serve para ESCOLHER a configuracao; a validacao final e outra.",
                          k_folds, if (modo == "propriedade") "propriedade inteira" else "UPA inteira"))
  plano <- list(especie = base$especie, modo = modo, unidades = u,
                parametros = list(pct_validacao = pct_validacao, min_presencas = min_presencas,
                                  usar_reservadas = usar_reservadas, k_folds = k_folds),
                justificativa = just, origem = "recomendacao automatica")
  checar_plano(plano, base)
}

#' Aplica alteracoes do usuario: vetores de unidades para validacao/treino/exclusao
#' (se 'treino' for dado, o que nao estiver em treino nem validacao fica "reservada") e
#' (opcional) folds manuais (vetor nomeado unidade -> fold).
editar_plano <- function(plano, base, validacao = NULL, treino = NULL, excluir = character(), folds_manuais = NULL, k_folds = NULL) {
  u <- plano$unidades
  if (!is.null(validacao) && is.null(treino))      # so a validacao mudou: reservadas continuam protegidas
    u$papel <- ifelse(u$unidade %in% validacao, "validacao", ifelse(u$reservada, "reservada", "treino"))
  if (!is.null(treino)) u$papel <- ifelse(u$unidade %in% validacao, "validacao", ifelse(u$unidade %in% treino, "treino", "reservada"))
  u$papel[u$unidade %in% excluir] <- "excluida"
  k <- k_folds %||% plano$parametros$k_folds
  u$fold <- NA_integer_
  tr <- u[u$papel == "treino", ]; fo <- alocar_folds(tr, k); u$fold[match(names(fo), u$unidade)] <- fo
  if (length(folds_manuais)) { i <- match(names(folds_manuais), u$unidade); ok <- !is.na(i) & u$papel[i] == "treino"
    u$fold[i[ok]] <- as.integer(folds_manuais[ok]) }
  plano$unidades <- u; plano$parametros$k_folds <- k; plano$origem <- "editado pelo usuario"
  checar_plano(plano, base)
}
`%||%` <- function(a, b) if (is.null(a)) b else a

#' Confere o plano e gera avisos + tabela de composicao.
checar_plano <- function(plano, base) {
  u <- plano$unidades; av <- character()
  stopifnot(!anyDuplicated(u$unidade))   # cada unidade tem UM unico papel -> nunca em treino e validacao
  col <- if (plano$modo == "propriedade") "propriedade" else "upa_id"
  pr <- base$presencas; bg <- base$background
  pr$papel <- u$papel[match(pr[[col]], u$unidade)]; bg$papel <- u$papel[match(bg[[col]], u$unidade)]
  pr$fold <- u$fold[match(pr[[col]], u$unidade)]; bg$fold <- u$fold[match(bg[[col]], u$unidade)]

  n_val <- sum(pr$papel == "validacao"); n_tr <- sum(pr$papel == "treino")
  if (n_val < 30) av <- c(av, sprintf("CRITICO: so %d presencas na validacao (< 30): metricas muito instaveis.", n_val))
  if (n_tr < 100) av <- c(av, sprintf("CRITICO: so %d presencas no treino.", n_tr))
  comp <- u %>% filter(papel %in% c("treino", "validacao")) %>%
    mutate(grupo = ifelse(papel == "validacao", "VALIDACAO", paste("TREINO - fold", fold))) %>%
    group_by(grupo) %>%
    summarise(n_unidades = n(), propriedades = paste(sort(unique(propriedade)), collapse = ", "),
              unidades = paste(sort(unidade), collapse = "; "),
              unidades_com_presenca = sum(n_presencas > 0), n_presencas = sum(n_presencas),
              n_background = sum(n_background), .groups = "drop") %>%
    mutate(pct_presencas = round(100 * n_presencas / sum(n_presencas), 1))
  pf <- comp[startsWith(comp$grupo, "TREINO"), ]
  if (any(pf$n_presencas == 0)) av <- c(av, "CRITICO: ha fold de treino sem presencas - mude o numero de folds ou mova unidades.")
  else if (any(pf$pct_presencas < 10)) av <- c(av, paste("ATENCAO: fold(s) com < 10% das presencas:", paste(pf$grupo[pf$pct_presencas < 10], collapse = ", ")))
  # novidade ambiental da validacao em relacao ao background de treino
  tr_bg <- bg[bg$papel == "treino", ]; va <- pr[pr$papel == "validacao", ]
  if (nrow(va)) {
    fora <- sapply(VARS_CONTINUAS, function(v) va[[v]] < min(tr_bg[[v]]) | va[[v]] > max(tr_bg[[v]]))
    pct <- 100 * colMeans(fora); tot <- 100 * mean(rowSums(fora) > 0)
    if (tot >= 20) av <- c(av, sprintf("ATENCAO: %.0f%% das presencas de validacao estao fora da amplitude ambiental do treino (%s). Espere omissao alta por extrapolacao.",
                                       tot, paste(names(pct)[pct >= 10], collapse = ", ")))
    nov_solo <- setdiff(unique(as.character(va$textura_subgrupo)), unique(as.character(tr_bg$textura_subgrupo)))
    if (length(nov_solo)) av <- c(av, paste("ATENCAO: classe(s) de solo na validacao ausentes no treino:", paste(nov_solo, collapse = ", ")))
  }
  # proximidade: distancia minima entre pontos de validacao e de treino (m)
  prox <- NULL
  if (nrow(va)) {
    pv <- rbind(va[, c(col, "longitude", "latitude")], bg[bg$papel == "validacao", c(col, "longitude", "latitude")])
    pt <- rbind(pr[pr$papel == "treino", c(col, "longitude", "latitude")], tr_bg[, c(col, "longitude", "latitude")])
    xv <- projetar_metros(pv); xt <- projetar_metros(pt)
    prox <- do.call(rbind, lapply(split(seq_len(nrow(pv)), pv[[col]]), function(ii) {
      dmin <- Inf; jt <- 0
      for (ch in split(seq_len(nrow(xt)), ceiling(seq_len(nrow(xt)) / 4000))) {
        d <- sqrt(outer(xv[ii, 1], xt[ch, 1], "-")^2 + outer(xv[ii, 2], xt[ch, 2], "-")^2)
        w <- which(d == min(d), arr.ind = TRUE)[1, ]; if (min(d) < dmin) { dmin <- min(d); jt <- ch[w[2]] }
      }
      data.frame(unidade_validacao = pv[[col]][ii[1]], dist_min_treino_km = round(dmin / 1000, 2),
                 unidade_treino_mais_proxima = pt[[col]][jt])
    }))
    perto <- prox[prox$dist_min_treino_km < 1, ]
    if (nrow(perto)) av <- c(av, sprintf("ATENCAO: %d unidade(s) de validacao a menos de 1 km do treino (%s): validacao NAO e independente no espaco; interprete como transferencia local.",
                                         nrow(perto), paste(perto$unidade_validacao, collapse = "; ")))
  }
  if (any(u$reservada & u$papel == "treino")) av <- c(av, paste("REGISTRO: propriedade(s) reservada(s) movida(s) para o TREINO:",
                                                             paste(unique(u$propriedade[u$reservada & u$papel == "treino"]), collapse = ", "),
                                                             "- justificar no TCC."))
  if (!length(av)) av <- "Nenhum problema encontrado."
  plano$composicao <- comp; plano$proximidade <- prox; plano$avisos <- av
  plano
}

#' Salva o plano (arquivos + mapa + log).
salvar_plano <- function(plano, base) {
  pasta <- criar_pasta_saida(plano$especie, "02_selecao")
  saveRDS(plano, file.path(pasta, "PLANO_SELECAO.rds"))
  salvar_csv(plano$unidades, pasta, "01_UNIDADES.csv")
  salvar_csv(plano$composicao, pasta, "02_COMPOSICAO_FOLDS.csv")
  if (!is.null(plano$proximidade)) salvar_csv(plano$proximidade, pasta, "04_PROXIMIDADE_VALIDACAO.csv")
  writeLines(plano$avisos, file.path(pasta, "03_AVISOS.txt"), useBytes = TRUE)
  writeLines(plano$justificativa, file.path(pasta, "JUSTIFICATIVA.txt"), useBytes = TRUE)
  ggsave(file.path(pasta, "G01_MAPA_SELECAO.png"), grafico_mapa_plano(plano, base), width = 8, height = 6, dpi = 150, bg = "white")
  registrar_log(pasta, "02_selecao", escolhas = list(
    especie = ESPECIES[[plano$especie]], desenho = plano$modo, origem = plano$origem,
    validacao = plano$unidades$unidade[plano$unidades$papel == "validacao"],
    excluidas = plano$unidades$unidade[plano$unidades$papel == "excluida"],
    folds_treino = with(plano$unidades[plano$unidades$papel == "treino", ], paste(unidade, "-> fold", fold)),
    parametros = plano$parametros), mensagens = plano$avisos)
  pasta
}

grafico_mapa_plano <- function(plano, base) {
  col <- if (plano$modo == "propriedade") "propriedade" else "upa_id"
  u <- plano$unidades; lab <- ifelse(u$papel == "treino", paste("Treino fold", u$fold), ifelse(u$papel == "validacao", "Validacao", ifelse(u$papel == "reservada", "Reservada (protegida)", "Excluida")))
  bg <- base$background; pr <- base$presencas
  bg$grupo <- lab[match(bg[[col]], u$unidade)]; pr$grupo <- lab[match(pr[[col]], u$unidade)]
  ggplot() + geom_point(data = bg, aes(longitude, latitude, colour = grupo), size = 0.25, alpha = 0.4) +
    geom_point(data = pr, aes(longitude, latitude, colour = grupo), size = 1.1, shape = 17) +
    coord_equal() + theme_minimal(11) + guides(colour = guide_legend(override.aes = list(size = 3, alpha = 1))) +
    labs(colour = NULL, title = sprintf("%s - desenho por %s", ESPECIES[[plano$especie]], plano$modo),
         subtitle = "Triangulos = presencas; pontos pequenos = background")
}
