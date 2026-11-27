# =============================================================================
# 16_FIGURAS_TCC.R
# -----------------------------------------------------------------------------
# Figuras e tabelas finais do TCC (padrao ABNT; analise descritiva no estilo de
# Ferreira, 2009). Todas as figuras usam o mesmo tema e as mesmas cores:
#   ipe-roxo = violeta (#6A4CE2); ipe-amarelo = dourado (#D28E05).
#   F_DENS_<esp>   densidade media +- EP por classe: (a) altitude, (b) declividade,
#                  (c) distancia a hidrografia; tendencia com IC 95%, equacao e R2
#   F_JK_<esp>     Jackknife (ganho de treino): modelo escolhido e modelo com 6 variaveis
#   F_RESP_<esp>   curvas de resposta do modelo escolhido + distribuicao do ambiente
#   F_ROC_<esp>    curvas ROC (treino, validacao cruzada, teste externo)
#   F_MAPA_<esp>   adequabilidade nas propriedades (grupos oeste, central e leste)
#   F_CORREL       correlacao de Pearson/Spearman entre as 6 variaveis (+ TAB_VIF.csv)
#   F_FLUXOGRAMA   etapas da metodologia
# Uso (na pasta do projeto):
#   Rscript R/16_FIGURAS_TCC.R roxo                 (todas as figuras da especie)
#   Rscript R/16_FIGURAS_TCC.R roxo dens jk         (so algumas: dens resp roc tab jk mapa)
#   Rscript R/16_FIGURAS_TCC.R correlacao | fluxo
# =============================================================================
suppressPackageStartupMessages({
  source(file.path("R", "12_TESTE_EXTERNO.R"), encoding = "UTF-8")
  source(file.path("R", "11_BUSCA_METODOLOGICA.R"), encoding = "UTF-8")
  library(ggplot2); library(patchwork); library(sf); library(terra); library(ggspatial)
})
sf_use_s2(FALSE)
options(OutDec = ",")
SAIDA <- file.path(PASTA_RESULTADOS, "_geral", "11_figuras_tcc")
dir.create(SAIDA, recursive = TRUE, showWarnings = FALSE)

NOMES <- c(altitude_m = "Altitude (m)", declividade_graus = "Declividade (graus)",
           dist_rio_raster_m = "Distância à hidrografia (m)", bio12_mm_ano = "BIO12 (mm/ano)",
           bio17_mm_mes = "BIO17 (mm/mês)", textura_subgrupo = "Textura do solo")
COR   <- c(roxo = "#6A4CE2", amarelo = "#D28E05")          # validadas (CVD e visao normal)
CLARO <- c(roxo = "#D9D2F7", amarelo = "#F3DFB3")          # mesma matiz, clara
TXT <- "#191919"; TXT2 <- "#5F5F5F"; GRADE <- "#E6E6E6"

# ---------------- tema unico ----------------
tema <- theme_minimal(base_size = 9, base_family = "sans") +
  theme(text = element_text(colour = TXT),
        panel.grid.major = element_line(colour = GRADE, linewidth = 0.3), panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        axis.line.x = element_line(colour = "#8C8C8C", linewidth = 0.35),
        axis.ticks.x = element_line(colour = "#8C8C8C", linewidth = 0.35), axis.ticks.length = unit(0.08, "cm"),
        axis.text = element_text(colour = TXT2, size = 7.5), axis.title = element_text(colour = TXT2, size = 8),
        plot.title = element_text(face = "bold", size = 8.5, hjust = 0, margin = margin(b = 4)),
        plot.title.position = "plot", plot.subtitle = element_text(colour = TXT2, size = 7, margin = margin(b = 4)),
        legend.text = element_text(colour = TXT, size = 7.5), legend.title = element_text(face = "bold", size = 7.5),
        plot.margin = margin(4, 6, 4, 4))
salvar <- function(p, nome, w = 16, h = 7) {
  ggsave(file.path(SAIDA, paste0(nome, ".png")), p, width = w, height = h, units = "cm", dpi = 300, bg = "white")
  cat("  ", nome, "\n")
}
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d, decimal.mark = ",", big.mark = ".")
fmt_sci <- function(x) {
  if (abs(x) >= 0.001) return(formatC(signif(x, 3), format = "fg", digits = 3, decimal.mark = ","))
  e <- floor(log10(abs(x))); m <- x / 10^e
  sup <- c("0" = "⁰", "1" = "¹", "2" = "²", "3" = "³", "4" = "⁴", "5" = "⁵",
           "6" = "⁶", "7" = "⁷", "8" = "⁸", "9" = "⁹", "-" = "⁻")
  paste0(formatC(m, format = "f", digits = 2, decimal.mark = ","), "×10", paste(sup[strsplit(as.character(e), "")[[1]]], collapse = ""))
}
virg <- function(x) gsub("\\.", ",", format(x, trim = TRUE, scientific = FALSE))

# pastas do teste externo registrado da especie
pastas_especie <- function(especie) {
  r <- do.call(rbind, lapply(list.files(file.path(PASTA_RESULTADOS, "_geral", "teste_externo"), "RESULTADO_TESTE_EXTERNO.csv",
                                        recursive = TRUE, full.names = TRUE), read.csv2))
  pv <- tail(r$pasta_validacao[r$especie == ESPECIES[[especie]]], 1)
  if (!length(pv)) stop("teste externo ainda nao realizado para ", especie)
  pv <- file.path(PASTA_RESULTADOS, especie, "06_validacao", basename(pv))
  tr <- sort(list.dirs(file.path(PASTA_RESULTADOS, especie, "05_treino"), recursive = FALSE))
  list(validacao = pv, treino = tail(tr[basename(tr) <= basename(pv)], 1))
}

# ---------------- 1) densidade por classe (Ferreira, 2009) ----------------
TEXTURAS <- c("2" = "Muito\nargilosa", "3" = "Argilosa", "4" = "Média-\nargilosa", "6" = "Média-\nsiltosa", "7" = "Média-\narenosa")
fig_densidade <- function(especie) {
  pasta <- file.path(PASTA_RESULTADOS, "_geral", "09_ecologia")
  rot_sp <- c(roxo = "Ipê-roxo", amarelo = "Ipê-amarelo")[[especie]]
  d <- read.csv2(file.path(pasta, "01_DENSIDADE_POR_CLASSE.csv")); d <- d[d$especie == rot_sp, ]
  vv <- c("altitude_m", "declividade_graus", "dist_rio_raster_m", "bio12_mm_ano", "bio17_mm_mes")
  ajustes <- list(); cor <- COR[[especie]]
  eixo_y <- expression("Densidade (árvores ha"^-1*")")
  paineis <- lapply(seq_along(vv), function(i) {
    v <- vv[i]; x <- d[d$variavel == v & is.finite(d$dens_media), ]
    m1 <- lm(dens_media ~ x, x); m2 <- lm(dens_media ~ x + I(x^2), x)
    r1 <- summary(m1)$r.squared; r2 <- summary(m2)$r.squared
    usar2 <- (r2 - r1) > 0.1                      # quadratico so quando melhora bem o ajuste
    m <- if (usar2) m2 else m1; cf <- coef(m); fs <- summary(m)$fstatistic
    p <- unname(pf(fs[1], fs[2], fs[3], lower.tail = FALSE))
    ajustes[[v]] <<- data.frame(especie = especie, variavel = v, modelo = ifelse(usar2, "quadratico", "linear"),
      r2_linear = round(r1, 3), r2_quadratico = round(r2, 3), r2_usado = round(summary(m)$r.squared, 3), p = signif(p, 3),
      dens_min = round(min(x$dens_media), 3), dens_max = round(max(x$dens_media), 3),
      classe_max = x$classe[which.max(x$dens_media)], classe_min = x$classe[which.min(x$dens_media)])
    sinal <- function(z) ifelse(z < 0, "−", "+")
    eq <- if (usar2) sprintf("y = %s %s %sx %s %sx²", fmt(cf[1]), sinal(cf[2]), fmt_sci(abs(cf[2])), sinal(cf[3]), fmt_sci(abs(cf[3])))
          else sprintf("y = %s %s %sx", fmt(cf[1]), sinal(cf[2]), fmt_sci(abs(cf[2])))
    eq <- sub("^y = -", "y = −", eq)
    est <- paste0("R² = ", fmt(summary(m)$r.squared, 2), "   p ", ifelse(p < 0.001, "< 0,001", paste("=", fmt(p, 3))))
    xs <- seq(min(x$x), max(x$x), length.out = 150)
    pr <- as.data.frame(predict(m, data.frame(x = xs), interval = "confidence")); pr$x <- xs
    ggplot(x, aes(x, dens_media)) +
      geom_ribbon(data = pr, aes(x, ymin = pmax(lwr, 0), ymax = upr), inherit.aes = FALSE, fill = CLARO[[especie]], alpha = 0.7) +
      geom_line(data = pr, aes(x, fit), colour = cor, linewidth = 0.7) +
      geom_errorbar(aes(ymin = pmax(dens_media - dens_ep, 0), ymax = dens_media + dens_ep), width = 0, linewidth = 0.4, colour = "#4D4D4D") +
      geom_point(shape = 21, fill = cor, colour = "white", stroke = 0.7, size = 2.2) +
      annotate("text", x = -Inf, y = Inf, label = eq, hjust = -0.04, vjust = 1.3, size = 2.1, colour = TXT) +
      annotate("text", x = -Inf, y = Inf, label = est, hjust = -0.06, vjust = 3.1, size = 2.1, colour = TXT2) +
      scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.3)), labels = virg) +
      scale_x_continuous(breaks = scales::breaks_pretty(4), labels = function(z) formatC(z, format = "d", big.mark = ".")) +
      labs(x = NOMES[[v]], y = if (i %in% c(1, 4)) eixo_y else NULL,
           title = paste0("(", letters[i], ") ", sub(" \\(.*", "", NOMES[[v]]))) + tema
  })
  s <- read.csv2(file.path(pasta, "04_DENSIDADE_SOLO.csv"))
  s <- s[s$especie == rot_sp & s$area_ha >= 50 & is.finite(s$dens_media), ]
  s$rot <- factor(TEXTURAS[as.character(s$classe)], levels = TEXTURAS)
  paineis[[6]] <- ggplot(s, aes(rot, dens_media)) +
    geom_col(fill = CLARO[[especie]], width = 0.62) +
    geom_errorbar(aes(ymin = pmax(dens_media - dens_ep, 0), ymax = dens_media + dens_ep), width = 0, linewidth = 0.4, colour = "#4D4D4D") +
    geom_point(shape = 21, fill = cor, colour = "white", stroke = 0.7, size = 2.2) +
    geom_text(aes(y = 0, label = paste0(formatC(area_ha, format = "d", big.mark = "."), " ha")), vjust = -0.6, size = 1.9, colour = TXT2) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.3)), labels = virg) +
    labs(x = "Textura do solo (MapBiomas Solo)", y = NULL, title = "(f) Textura do solo") + tema +
    theme(axis.text.x = element_text(size = 6.5, lineheight = 0.85))
  salvar(wrap_plots(paineis, nrow = 2), paste0("F_DENS_", especie), h = 12)
  aj <- do.call(rbind, ajustes); print(aj[, c("variavel", "modelo", "r2_usado", "p", "dens_min", "dens_max", "classe_max", "classe_min")])
  write.csv2(aj, file.path(SAIDA, paste0("AJUSTES_DENS_", especie, ".csv")), row.names = FALSE)
  print(s[, c("classe", "area_ha", "dens_media", "dens_ep", "n_props")])
}

# ---------------- 2) Jackknife ----------------
jk_seis <- function(especie, fc = "lq", rm = 2) {
  arq <- file.path(SAIDA, paste0("JK_SEIS_", especie, ".csv"))
  if (file.exists(arq)) return(read.csv2(arq))
  d <- dados_busca(especie); vs <- names(NOMES)
  conj <- c(list(todas = vs), setNames(lapply(vs, function(v) v), paste0("so|", vs)),
            setNames(lapply(vs, function(v) setdiff(vs, v)), paste0("sem|", vs)))
  out <- do.call(rbind, lapply(names(conj), function(nm) {
    cat("   JK 6 vars:", nm, "\n"); v <- conj[[nm]]
    dm <- dados_maxnet(d$pr, d$bg, v); a <- ajuste_seguro(dm$p, dm$x, fc, rm)
    data.frame(tipo = c(todas = "Com todas", so = "Somente a variavel", sem = "Sem a variavel")[[sub("\\|.*", "", nm)]],
               variavel = if (nm == "todas") "(todas)" else sub(".*\\|", "", nm),
               ganho_treino = ganho(a$modelo, d$pr[, v, drop = FALSE], d$bg[, v, drop = FALSE], TRUE))
  }))
  write.csv2(out, arq, row.names = FALSE); out
}
painel_jk <- function(jk, titulo, especie, xmax) {
  tod <- jk$ganho_treino[jk$tipo == "Com todas"]
  d <- jk[jk$tipo != "Com todas", ]
  d$tipo <- factor(ifelse(d$tipo == "Somente a variavel", "Somente a variável", "Sem a variável"),
                   levels = c("Sem a variável", "Somente a variável"))
  ordem <- d$variavel[d$tipo == "Somente a variável"][order(d$ganho_treino[d$tipo == "Somente a variável"])]
  d$nome <- factor(NOMES[d$variavel], levels = NOMES[ordem])
  ggplot(d, aes(ganho_treino, nome, fill = tipo)) +
    geom_col(position = position_dodge(width = 0.78), width = 0.72) +
    geom_text(aes(label = fmt(ganho_treino, 2), hjust = ifelse(ganho_treino > 0.35 * xmax, 1.15, -0.15),
                  colour = ifelse(ganho_treino > 0.35 * xmax & tipo == "Somente a variável", "white", TXT)),
              position = position_dodge(width = 0.78), size = 2.1, show.legend = FALSE) + scale_colour_identity() +
    geom_vline(xintercept = tod, linetype = "22", linewidth = 0.45, colour = TXT) +
    annotate("label", x = tod, y = Inf, label = paste0("Todas: ", fmt(tod, 2)), vjust = 1, hjust = 0.5, size = 2.1,
             fill = "white", border.colour = NA, colour = TXT) +
    scale_fill_manual(values = c("Somente a variável" = COR[[especie]], "Sem a variável" = CLARO[[especie]]),
                      breaks = c("Somente a variável", "Sem a variável"), name = NULL) +
    scale_x_continuous(limits = c(0, xmax), expand = expansion(mult = c(0, 0)), labels = virg) +
    scale_y_discrete(expand = expansion(add = c(0.6, 1.1))) +
    labs(x = "Ganho de treino regularizado", y = NULL, title = titulo) + tema +
    theme(panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(colour = GRADE, linewidth = 0.3),
          axis.text.y = element_text(colour = TXT, size = 7.5))
}
fig_jackknife <- function(especie, ps) {
  jk1 <- read.csv2(file.path(ps$treino, "05_JACKKNIFE.csv")); me <- readRDS(file.path(ps$treino, "MODELO_ESCOLHIDO.rds"))
  jk2 <- jk_seis(especie); xmax <- max(c(jk1$ganho_treino, jk2$ganho_treino), na.rm = TRUE) * 1.15
  vs <- paste(sub(" \\(.*", "", NOMES[me$variaveis]), collapse = " + ")
  p <- painel_jk(jk1, paste0("(a) Modelo escolhido: ", vs), especie, xmax) /
       painel_jk(jk2, "(b) Modelo com as seis variáveis", especie, xmax) +
       plot_layout(guides = "collect", heights = c(length(me$variaveis), 6) + 1) &
       theme(legend.position = "bottom", legend.key.size = unit(0.35, "cm"))
  salvar(p, paste0("F_JK_", especie), w = 14, h = 11)
  write.csv2(rbind(transform(jk1[, c("tipo", "variavel", "ganho_treino")], modelo = "escolhido"),
                   transform(jk2, modelo = "seis_variaveis")), file.path(SAIDA, paste0("JK_", especie, ".csv")), row.names = FALSE)
}

# ---------------- 3) curvas de resposta ----------------
fig_resposta <- function(especie, ps) {
  me <- readRDS(file.path(ps$treino, "MODELO_ESCOLHIDO.rds")); d <- dados_busca(especie)
  ref <- lapply(d$bg[, me$variaveis, drop = FALSE], function(z) if (is.factor(z)) names(which.max(table(z))) else mean(z))
  fx <- function(nd) { for (w in names(nd)) if (is.factor(d$bg[[w]])) nd[[w]] <- factor(nd[[w]], levels = levels(d$bg[[w]])); nd }
  ps_ <- lapply(seq_along(me$variaveis), function(i) {
    v <- me$variaveis[i]; tit <- paste0("(", letters[i], ") ", sub(" \\(.*", "", NOMES[[v]]))
    if (is.factor(d$bg[[v]])) {
      niv <- levels(d$bg[[v]]); nd <- as.data.frame(ref)[rep(1, length(niv)), , drop = FALSE]; nd[[v]] <- niv
      nd <- fx(nd); nd$s <- prever(me$maxnet, nd[, me$variaveis, drop = FALSE], me$clamp)
      return(ggplot(nd, aes(.data[[v]], s)) + geom_col(fill = COR[[especie]], width = 0.6) +
               labs(x = NOMES[[v]], y = if (i == 1) "Adequabilidade (cloglog)" else NULL, title = tit) + tema)
    }
    r <- quantile(d$bg[[v]], c(0.005, 0.995)); xs <- seq(r[1], r[2], length.out = 200)
    nd <- as.data.frame(ref)[rep(1, 200), , drop = FALSE]; nd[[v]] <- xs; nd <- fx(nd)
    nd$s <- prever(me$maxnet, nd[, me$variaveis, drop = FALSE], me$clamp)
    top <- max(nd$s) * 1.08; alt <- top * 0.22             # faixa inferior com a distribuicao do ambiente
    den <- function(z, grupo) { k <- density(z[z >= r[1] & z <= r[2]], from = r[1], to = r[2], n = 256)
      data.frame(x = k$x, y = -alt * 1.15 + alt * k$y / max(k$y), g = grupo) }
    dd <- rbind(den(d$bg[[v]], "Ambiente disponível"), den(d$pr[[v]], "Presenças"))
    ggplot() +
      geom_ribbon(data = dd, aes(x, ymin = -alt * 1.15, ymax = y, fill = g), alpha = 0.6) +
      geom_hline(yintercept = 0, colour = "#8C8C8C", linewidth = 0.35) +
      geom_line(data = nd, aes(.data[[v]], s), colour = COR[[especie]], linewidth = 0.9) +
      scale_fill_manual(values = c("Ambiente disponível" = "#BDBDBD", "Presenças" = COR[[especie]]), name = NULL) +
      scale_y_continuous(limits = c(-alt * 1.15, top), breaks = scales::breaks_pretty(4)(c(0, top)), labels = virg,
                         expand = expansion(0)) +
      scale_x_continuous(expand = expansion(0)) +
      labs(x = NOMES[[v]], y = if (i == 1) "Adequabilidade (cloglog)" else NULL, title = tit) + tema +
      theme(axis.line.x = element_blank())
  })
  p <- wrap_plots(ps_, nrow = 1) + plot_layout(guides = "collect") & theme(legend.position = "bottom", legend.key.size = unit(0.35, "cm"))
  salvar(p, paste0("F_RESP_", especie), w = min(16, 6.2 * length(ps_) + 1), h = 7)
}

# ---------------- 4) ROC ----------------
fig_roc <- function(especie, ps) {
  r <- read.csv2(file.path(ps$validacao, "04_ROC.csv"))
  auc <- sub(".*AUC = ([0-9.]+).*", "\\1", r$curva)
  r$conj <- ifelse(grepl("^Treino", r$curva), "Treino", ifelse(grepl("cruzada", r$curva), "Validação cruzada", "Teste externo"))
  r$rot <- paste0(r$conj, "  (AUC = ", gsub("\\.", ",", auc), ")")
  niv <- unique(r$rot[order(match(r$conj, c("Treino", "Validação cruzada", "Teste externo")))])
  r$rot <- factor(r$rot, levels = niv)
  cores <- setNames(c("#9E9E9E", "#4D4D4D", COR[[especie]]), niv)
  ext <- r[r$conj == "Teste externo", ]
  p <- ggplot(r, aes(fpr, tpr, colour = rot)) +
    geom_ribbon(data = ext, aes(x = fpr, ymin = fpr, ymax = tpr), inherit.aes = FALSE, fill = CLARO[[especie]], alpha = 0.55) +
    geom_abline(intercept = 0, slope = 1, colour = "#9E9E9E", linewidth = 0.35, linetype = "22") +
    annotate("text", x = 0.62, y = 0.56, label = "acaso", angle = 45, size = 2.2, colour = "#9E9E9E") +
    geom_line(linewidth = 0.75) + scale_colour_manual(values = cores, name = NULL) +
    coord_equal(expand = FALSE) + scale_x_continuous(labels = virg) + scale_y_continuous(labels = virg) +
    labs(x = "1 − especificidade (taxa de falsos positivos)", y = "Sensibilidade") + tema +
    theme(panel.grid.major.x = element_line(colour = GRADE, linewidth = 0.3), legend.position = "inside",
          legend.position.inside = c(0.64, 0.16), legend.background = element_rect(fill = "white", colour = NA),
          legend.key.width = unit(0.7, "cm"))
  salvar(p, paste0("F_ROC_", especie), w = 9.5, h = 9)
}

# ---------------- 5) mapa de adequabilidade ----------------
graus <- function(eixo) function(v) {
  h <- if (eixo == "x") ifelse(v < 0, "O", "L") else ifelse(v < 0, "S", "N")
  a <- abs(v); g <- floor(a + 1e-9); m <- round((a - g) * 60)
  ifelse(is.na(v), NA, ifelse(m == 0, sprintf("%d°%s", g, h), sprintf("%d°%02d'%s", g, m, h)))
}
fig_mapa <- function(especie, ps) {
  tab <- read.csv2(file.path(PASTA_RESULTADOS, "_geral", "TABELA1_PROPRIEDADES_COM_NOMES.csv"), encoding = "UTF-8")
  chave <- function(s) gsub("[^A-Z0-9]", "_", toupper(iconv(s, "UTF-8", "ASCII//TRANSLIT")))
  tifs <- list.files(file.path(ps$validacao, "mapas"), "_adequabilidade\\.tif$", full.names = TRUE)
  cod <- tab$codigo[match(sub("_adequabilidade\\.tif$", "", basename(tifs)), chave(tab$propriedade))]
  conj <- tab$conjunto[match(cod, tab$codigo)]
  rs <- lapply(tifs, function(f) project(rast(f)[[1]], "EPSG:4674", method = "bilinear"))
  cx <- sapply(rs, function(r) mean(as.vector(ext(r))[1:2]))
  grupo <- cut(cx, c(-Inf, -55, -52, Inf), labels = c("oeste", "centro", "leste"))
  lim <- c(0, max(sapply(rs, function(r) global(r, "max", na.rm = TRUE)[[1]])))
  contornos <- do.call(rbind, lapply(seq_along(rs), function(i)
    st_sf(codigo = cod[i], conjunto = conj[i], geometry = st_union(st_as_sf(as.polygons(rs[[i]] > -1, dissolve = TRUE))))))
  rampa <- c("#F7F4EA", "#E3EBC8", "#B8D98F", "#7CBF6B", "#3E9A55", "#16703F", "#08442A")   # sequencial, 1 matiz (verde)
  painel <- function(g, titulo, norte = FALSE) {
    k <- which(grupo == g); e <- as.vector(Reduce(terra::union, lapply(rs[k], ext)))
    mx <- (e[2] - e[1]) * 0.07; my <- (e[4] - e[3]) * 0.07
    tmpl <- rast(ext(e[1] - mx, e[2] + mx, e[3] - my, e[4] + my), resolution = 0.0006, crs = "EPSG:4674")
    m <- do.call(mosaic, c(lapply(rs[k], function(r) resample(r, tmpl, method = "bilinear")), fun = "max"))
    df <- as.data.frame(m, xy = TRUE, na.rm = TRUE); names(df)[3] <- "s"
    cc <- st_coordinates(suppressWarnings(st_point_on_surface(contornos[k, ])))
    lab <- data.frame(x = cc[, 1], y = cc[, 2], l = contornos$codigo[k], ext = contornos$conjunto[k] == "Teste externo")
    p <- ggplot() + geom_tile(data = df, aes(x, y, fill = s), width = 0.0006, height = 0.0006) +
      geom_sf(data = contornos[k, ], aes(linetype = conjunto == "Teste externo"), fill = NA, colour = "#3A3A3A",
              linewidth = 0.25, show.legend = FALSE) +
      scale_linetype_manual(values = c(`FALSE` = "solid", `TRUE` = "22")) +
      ggrepel::geom_text_repel(data = lab, aes(x, y, label = l, fontface = ifelse(ext, "bold.italic", "plain")),
                               size = 1.9, colour = TXT, bg.color = "white", bg.r = 0.15, segment.size = 0.2,
                               segment.colour = "#5F5F5F", min.segment.length = 0.3, seed = 2, max.overlaps = 50) +
      scale_fill_gradientn(colours = rampa, limits = lim, name = "Adequabilidade (cloglog)", labels = virg,
                           guide = guide_colourbar(title.position = "top", title.hjust = 0.5)) +
      coord_sf(xlim = c(e[1] - mx, e[2] + mx), ylim = c(e[3] - my, e[4] + my), expand = FALSE) +
      scale_x_continuous(breaks = scales::breaks_pretty(2), labels = graus("x")) +
      scale_y_continuous(breaks = scales::breaks_pretty(2), labels = graus("y")) +
      annotation_scale(location = "bl", width_hint = 0.25, height = unit(0.08, "cm"), text_cex = 0.5,
                       bar_cols = c("#3A3A3A", "white"), line_width = 0.4) +
      labs(title = titulo, x = NULL, y = NULL) + theme_void(base_size = 7) +
      theme(panel.background = element_rect(fill = "#F2F2F2", colour = NA),
            panel.border = element_rect(fill = NA, colour = "#8C8C8C", linewidth = 0.4),
            panel.grid.major = element_line(colour = "white", linewidth = 0.3),
            axis.text = element_text(size = 5.5, colour = TXT2), axis.text.y = element_text(angle = 90, hjust = 0.5),
            axis.ticks = element_line(colour = "#8C8C8C", linewidth = 0.3), axis.ticks.length = unit(0.06, "cm"),
            plot.title = element_text(size = 8, face = "bold", margin = margin(b = 3)), plot.margin = margin(3, 4, 3, 4))
    if (norte) p <- p + annotation_north_arrow(location = "tr", height = unit(0.6, "cm"), width = unit(0.45, "cm"),
                          style = north_arrow_orienteering(fill = c("#3A3A3A", "white"), line_col = "#3A3A3A", text_size = 5))
    p
  }
  p <- (painel("oeste", "(a) Grupo oeste", TRUE) | (painel("centro", "(b) Grupo central") / painel("leste", "(c) Grupo leste"))) +
    plot_layout(guides = "collect", widths = c(1.25, 1)) +
    plot_annotation(caption = "Contorno tracejado e código em negrito: propriedades do teste externo.",
                    theme = theme(plot.caption = element_text(size = 6.5, colour = TXT2, hjust = 0))) &
    theme(legend.position = "bottom", legend.key.width = unit(1.6, "cm"), legend.key.height = unit(0.22, "cm"),
          legend.title = element_text(size = 7, face = "bold", colour = TXT), legend.text = element_text(size = 6, colour = TXT2))
  salvar(p, paste0("F_MAPA_", especie), h = 11.5)
}

# ---------------- 6) correlação e VIF ----------------
fig_correlacao <- function() {
  d <- dados_busca("roxo")$bg                        # background comum as duas especies (desenvolvimento)
  x <- data.frame(lapply(d[, names(NOMES)], function(z) if (is.factor(z)) as.numeric(as.character(z)) else z))
  pe <- cor(x, method = "pearson"); sp <- cor(x, method = "spearman"); set.seed(SEMENTE_PADRAO); vif <- usdm::vif(x)
  n <- names(NOMES); g <- expand.grid(a = n, b = n, stringsAsFactors = FALSE)
  g$i <- match(g$a, n); g$j <- match(g$b, n)
  g$r <- ifelse(g$i > g$j, pe[cbind(g$i, g$j)], ifelse(g$i < g$j, sp[cbind(g$i, g$j)], NA))
  curto <- sub(" \\(.*", "", NOMES); curto["dist_rio_raster_m"] <- "Distância à\nhidrografia"; curto["textura_subgrupo"] <- "Textura\ndo solo"
  g$a <- factor(curto[g$a], levels = curto); g$b <- factor(curto[g$b], levels = rev(curto))
  g$txt <- ifelse(is.na(g$r), "", fmt(g$r, 2)); g$txt <- sub("^-", "−", g$txt)
  p <- ggplot(g, aes(a, b)) +
    geom_tile(aes(fill = r), colour = "white", linewidth = 1.2) +
    geom_text(aes(label = txt, colour = abs(r) > 0.5), size = 2.6, show.legend = FALSE) +
    geom_text(data = g[is.na(g$r), ], aes(label = a), size = 2.1, fontface = "bold", colour = TXT, lineheight = 0.85) +
    scale_colour_manual(values = c(`FALSE` = TXT, `TRUE` = "white"), na.value = TXT) +
    scale_fill_gradientn(colours = c("#1F5FA8", "#7FA8D6", "#EFEFEF", "#E39A86", "#B8352A"), limits = c(-1, 1),
                         na.value = "#F7F7F7", name = "r", labels = virg, breaks = c(-1, -0.5, 0, 0.5, 1)) +
    annotate("text", x = 6.5, y = 6.9, label = "Pearson →", hjust = 1, size = 2.3, colour = TXT2, fontface = "italic") +
    annotate("text", x = 0.5, y = 0.1, label = "← Spearman", hjust = 0, size = 2.3, colour = TXT2, fontface = "italic") +
    coord_equal(clip = "off") + labs(x = NULL, y = NULL) + theme_void(base_size = 8) +
    theme(legend.key.height = unit(1.2, "cm"), legend.key.width = unit(0.25, "cm"),
          legend.title = element_text(face = "bold", size = 8), legend.text = element_text(size = 7, colour = TXT2),
          plot.margin = margin(12, 6, 12, 6))
  salvar(p, "F_CORREL", w = 12, h = 10.5)
  vt <- data.frame(variavel = NOMES[vif$Variables], VIF = round(vif$VIF, 2),
                   max_abs_r = sapply(vif$Variables, function(v) round(max(abs(c(pe[v, setdiff(n, v)], sp[v, setdiff(n, v)]))), 2)))
  write.csv2(vt, file.path(SAIDA, "TAB_VIF.csv"), row.names = FALSE); print(vt)
}

# ---------------- 7) tabela do teste externo ----------------
tab_externo <- function(especie, ps) {
  c <- read.csv2(file.path(ps$validacao, "01_COMPARACAO_TREINO_VALIDACAO.csv"))
  u <- read.csv2(file.path(ps$validacao, "02_METRICAS_POR_UNIDADE.csv"))
  write.csv2(c, file.path(SAIDA, paste0("TAB_EXTERNO_", especie, ".csv")), row.names = FALSE)
  write.csv2(u, file.path(SAIDA, paste0("TAB_EXTERNO_UNIDADES_", especie, ".csv")), row.names = FALSE)
  print(c); print(u)
}

# ---------------- 8) fluxograma da metodologia ----------------
# Estilo academico simples: caixas retangulares, contorno preto fino, texto curto.
fig_fluxograma <- function() {
  B <- data.frame(                      # caixas: centro (x, y), meia largura (w), meia altura (h)
    id  = c("inv", "var", "prep", "proc", "extr", "dev", "res", "desc", "sel", "fin", "ext", "map"),
    x   = c(2.6, 7.4, 2.6, 7.4, 5.0, 3.0, 8.3, 1.3, 4.3, 4.3, 6.3, 6.3),
    y   = c(9.3, 9.3, 7.95, 7.95, 6.6, 5.25, 5.25, 3.75, 3.75, 2.4, 1.05, -0.2),
    w   = c(2.05, 2.05, 2.05, 2.05, 2.6, 1.95, 1.5, 1.2, 1.55, 1.55, 1.75, 1.75),
    h   = 0.42,
    txt = c("Inventários florestais a 100%\n34 propriedades (11.326 indivíduos)",
            "Variáveis ambientais\nANADEM, hidrografia, CHELSA, MapBiomas",
            "Árvores com DAP > 10 cm\numa presença por pixel de 30 m",
            "Processamento no QGIS/GDAL\ngrade comum de 30 m",
            "Extração das seis variáveis nas presenças e no background",
            "27 propriedades de desenvolvimento\n(8.680 presenças)",
            "7 propriedades\nreservadas",
            "Análise descritiva\n(densidade por classe)",
            "MaxEnt: seleção com\nvalidação LOPO e grade\nde 945 modelos",
            "Modelo final\n(Jackknife, curvas, ROC)",
            "Teste externo\n(avaliação única)",
            "Mapas de adequabilidade"))
  B$h[B$id == "sel"] <- 0.52
  seta <- function(x, y, xend, yend, lt = "solid") annotate("segment", x = x, y = y, xend = xend, yend = yend,
    linewidth = 0.35, linetype = lt, arrow = arrow(length = unit(0.1, "cm"), type = "closed"))
  linha <- function(x, y) annotate("path", x = x, y = y, linewidth = 0.35)
  g <- function(id, lado) { b <- B[B$id == id, ]
    switch(lado, topo = c(b$x, b$y + b$h), base = c(b$x, b$y - b$h), esq = c(b$x - b$w, b$y), dir = c(b$x + b$w, b$y)) }
  p <- ggplot(B) +
    geom_rect(aes(xmin = x - w, xmax = x + w, ymin = y - h, ymax = y + h), fill = "white", colour = "black", linewidth = 0.35) +
    geom_text(aes(x, y, label = txt), size = 2.35, lineheight = 0.92, colour = "black")
  # dados -> preparo -> extracao
  p <- p + seta(g("inv", "base")[1], g("inv", "base")[2], g("prep", "topo")[1], g("prep", "topo")[2]) +
    seta(g("var", "base")[1], g("var", "base")[2], g("proc", "topo")[1], g("proc", "topo")[2]) +
    linha(c(2.6, 2.6, 4.2), c(7.95 - 0.42, 7.2, 7.2)) + linha(c(7.4, 7.4, 5.8), c(7.95 - 0.42, 7.2, 7.2)) +
    seta(5.0, 7.2, 5.0, 6.6 + 0.42) + linha(c(4.2, 5.8), c(7.2, 7.2))
  # extracao -> divisao
  p <- p + linha(c(5.0, 5.0), c(6.6 - 0.42, 5.9)) + linha(c(3.0, 8.3), c(5.9, 5.9)) +
    seta(3.0, 5.9, 3.0, 5.25 + 0.42) + seta(8.3, 5.9, 8.3, 5.25 + 0.42)
  # desenvolvimento -> descritiva e selecao
  p <- p + linha(c(3.0, 3.0), c(5.25 - 0.42, 4.55)) + linha(c(1.3, 4.3), c(4.55, 4.55)) +
    seta(1.3, 4.55, 1.3, 3.75 + 0.42) + seta(4.3, 4.55, 4.3, 3.75 + 0.52) +
    seta(1.3 + 1.2, 3.75, 4.3 - 1.55, 3.75, "22")
  # selecao -> modelo final -> teste externo -> mapas
  p <- p + seta(4.3, 3.75 - 0.52, 4.3, 2.4 + 0.42) +
    linha(c(4.3, 4.3), c(2.4 - 0.42, 1.65)) + linha(c(4.3, 6.3), c(1.65, 1.65)) + seta(6.3, 1.65, 6.3, 1.05 + 0.42) +
    seta(6.3, 1.05 - 0.42, 6.3, -0.2 + 0.42)
  # reservadas -> teste externo (so no fim)
  p <- p + linha(c(8.3, 8.3), c(5.25 - 0.42, 1.05)) + seta(8.3, 1.05, 6.3 + 1.75, 1.05)
  p <- p + coord_cartesian(xlim = c(0, 10), ylim = c(-0.7, 9.8), expand = FALSE) + theme_void()
  salvar(p, "F_FLUXOGRAMA", w = 15, h = 13)
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args)) {
  if (args[1] == "correlacao") fig_correlacao() else if (args[1] == "fluxo") fig_fluxograma() else {
    e <- args[1]; ps <- tryCatch(pastas_especie(e), error = function(z) NULL)
    so <- if (length(args) > 1) args[-1] else c("dens", "resp", "roc", "tab", "jk", "mapa")
    if ("dens" %in% so) fig_densidade(e)
    if (!is.null(ps)) {
      if ("resp" %in% so) fig_resposta(e, ps); if ("roc" %in% so) fig_roc(e, ps); if ("tab" %in% so) tab_externo(e, ps)
      if ("jk" %in% so) fig_jackknife(e, ps); if ("mapa" %in% so) fig_mapa(e, ps)
    } else cat("Teste externo ainda nao realizado para", e, "- so a figura de densidade foi gerada.\n")
  }
}
