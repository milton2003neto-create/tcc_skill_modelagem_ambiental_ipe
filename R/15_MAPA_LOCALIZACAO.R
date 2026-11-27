# 15_MAPA_LOCALIZACAO.R
# Mapa de localizacao das 34 propriedades (Figura 1 do TCC).
# Limites: IBGE (API de malhas v3). Fundo: Esri World Imagery (pacote maptiles).
# Uso (na pasta do projeto): Rscript R/15_MAPA_LOCALIZACAO.R
suppressPackageStartupMessages({
  library(sf); library(terra); library(maptiles); library(ggplot2)
  library(ggspatial); library(patchwork); library(ggrepel)
})
sf_use_s2(FALSE)

RAIZ  <- getwd()
GEOM  <- file.path(RAIZ, "..", "..", "TCC - Ipes - Inicio do zero", "01 - Dados originais",
                   "Dados separados", "Geometrias")
SAIDA <- file.path(RAIZ, "resultados", "_geral", "10_mapa")
IBGE  <- file.path(SAIDA, "ibge"); TILES <- file.path(SAIDA, "tiles")
dir.create(IBGE, recursive = TRUE, showWarnings = FALSE)
dir.create(TILES, recursive = TRUE, showWarnings = FALSE)

baixar <- function(url, arq) {
  f <- file.path(IBGE, arq)
  if (!file.exists(f)) download.file(url, f, mode = "wb", quiet = TRUE)
  f
}
api <- "https://servicodados.ibge.gov.br/api"
uf  <- st_read(baixar(paste0(api, "/v3/malhas/paises/BR?intrarregiao=UF&formato=application/vnd.geo%2Bjson&qualidade=minima"), "br_uf.json"), quiet = TRUE)
mun <- st_read(baixar(paste0(api, "/v3/malhas/estados/15?intrarregiao=municipio&formato=application/vnd.geo%2Bjson&qualidade=intermediaria"), "pa_mun.json"), quiet = TRUE)
st_crs(uf) <- 4674; st_crs(mun) <- 4674
nomes <- jsonlite::fromJSON(baixar(paste0(api, "/v1/localidades/estados/15/municipios"), "pa_mun_nomes.json"))
mun$nome <- nomes$nome[match(mun$codarea, as.character(nomes$id))]
pa <- uf[uf$codarea == "15", ]

# ---------------- propriedades ----------------
tab <- read.csv2(file.path(RAIZ, "resultados", "_geral", "TABELA1_PROPRIEDADES_COM_NOMES.csv"), encoding = "UTF-8")
pastas <- list.dirs(GEOM, recursive = FALSE)
props <- do.call(rbind, lapply(seq_len(nrow(tab)), function(i) {
  pasta <- pastas[toupper(basename(pastas)) == toupper(tab$propriedade[i])]
  g <- st_read(list.files(file.path(pasta, "PROPRIEDADE"), "\\.shp$", full.names = TRUE)[1], quiet = TRUE)
  st_sf(codigo = tab$codigo[i], conjunto = tab$conjunto[i], roxo = tab$roxo[i] > 0,
        amarelo = tab$amarelo[i] > 0, geometry = st_union(st_zm(st_transform(g, 4674))))
}))
props$ocorrencia <- factor(ifelse(props$roxo & props$amarelo, "Ambas as espécies",
                           ifelse(props$roxo, "Ipê-roxo", "Ipê-amarelo")),
                           levels = c("Ipê-roxo", "Ipê-amarelo", "Ambas as espécies"))
props$grupo <- factor(ifelse(props$conjunto == "Teste externo", "Teste externo", "Desenvolvimento"))
cent <- suppressWarnings(st_point_on_surface(props))
xy <- st_coordinates(cent); cent$x <- xy[, 1]; cent$y <- xy[, 2]
props$regiao <- cent$regiao <- cut(cent$x, c(-Inf, -55, -52, Inf), labels = c("oeste", "centro", "leste"))
mun_est <- mun[lengths(st_intersects(mun, props)) > 0, ]
write.csv2(data.frame(codigo = props$codigo,
                      municipio = sapply(st_intersects(cent, mun), \(k) paste(mun$nome[k], collapse = "/"))),
           file.path(SAIDA, "PROPRIEDADES_MUNICIPIOS.csv"), row.names = FALSE)

# ---------------- utilidades ----------------
cores <- c("Ipê-roxo" = "#C77DFF", "Ipê-amarelo" = "#FFD60A", "Ambas as espécies" = "#2EF2A0")

caixa <- function(x, m = 0.06, asp = 1) {          # caixa com proporcao fixa (asp = largura/altura)
  b <- st_bbox(x); cx <- mean(b[c(1, 3)]); cy <- mean(b[c(2, 4)])
  w <- (b[[3]] - b[[1]]) / 2 + m; h <- (b[[4]] - b[[2]]) / 2 + m
  if (w / h < asp) w <- h * asp else h <- w / asp
  st_bbox(c(xmin = cx - w, ymin = cy - h, xmax = cx + w, ymax = cy + h), crs = st_crs(4674))
}
fundo <- function(bb, zoom, nome) {                 # imagem de satelite como data.frame RGB
  arq <- file.path(TILES, paste0(nome, ".tif"))
  if (!file.exists(arq)) {
    r <- get_tiles(st_as_sfc(bb), provider = "Esri.WorldImagery", zoom = zoom, crop = TRUE,
                   cachedir = TILES)
    r <- project(r, "EPSG:4674", method = "bilinear")
    if (ncol(r) > 900) r <- aggregate(r, fact = ceiling(ncol(r) / 900))
    writeRaster(r, arq, overwrite = TRUE)
  }
  r <- rast(arq)
  d <- as.data.frame(r, xy = TRUE, na.rm = TRUE)
  d$hex <- rgb(pmin(d[[3]], 255), pmin(d[[4]], 255), pmin(d[[5]], 255), maxColorValue = 255)
  d[, c("x", "y", "hex")]
}
graus <- function(eixo) function(v) {               # 56°20'O / 3°10'S
  h <- if (eixo == "x") ifelse(v < 0, "O", "L") else ifelse(v < 0, "S", "N")
  a <- abs(v); g <- floor(a + 1e-9); m <- round((a - g) * 60)
  ifelse(is.na(v), NA, ifelse(m == 0, sprintf("%d°%s", g, h), sprintf("%d°%02d'%s", g, m, h)))
}
tema <- theme_void(base_size = 8, base_family = "sans") +
  theme(panel.border = element_rect(fill = NA, colour = "grey15", linewidth = 0.5),
        panel.grid.major = element_line(colour = alpha("white", 0.35), linewidth = 0.2, linetype = "dotted"),
        axis.text = element_text(size = 5.5, colour = "grey25"),
        axis.text.y = element_text(angle = 90, hjust = 0.5),
        axis.ticks = element_line(colour = "grey25", linewidth = 0.25),
        axis.ticks.length = unit(0.08, "cm"),
        plot.title = element_text(size = 8, face = "bold", margin = margin(b = 2)),
        plot.margin = margin(3, 4, 3, 4))
escala <- function(loc = "bl") annotation_scale(location = loc, width_hint = 0.28, height = unit(0.09, "cm"),
  text_cex = 0.5, text_col = "white", bar_cols = c("white", "grey20"), line_col = "white",
  pad_x = unit(0.15, "cm"), pad_y = unit(0.15, "cm"))
norte <- function(cor = "white") annotation_north_arrow(location = "tr", height = unit(0.6, "cm"),
  width = unit(0.45, "cm"), pad_x = unit(0.12, "cm"), pad_y = unit(0.12, "cm"),
  style = north_arrow_orienteering(fill = c(cor, "grey20"), line_col = "grey20", text_col = cor, text_size = 5))

# ---------------- (a) Brasil ----------------
area <- caixa(props, m = 0.25, asp = 3)
a <- ggplot() +
  geom_sf(data = uf, fill = "grey92", colour = "white", linewidth = 0.2) +
  geom_sf(data = pa, fill = "#4F772D", colour = "grey20", linewidth = 0.3) +
  geom_sf(data = st_as_sfc(area), fill = NA, colour = "red", linewidth = 0.45) +
  annotate("text", x = -52.5, y = -6.2, label = "PA", size = 2.4, fontface = "bold", colour = "white") +
  coord_sf(xlim = c(-74.5, -34), ylim = c(-34, 5.5), expand = FALSE) +
  scale_x_continuous(breaks = c(-70, -55, -40), labels = graus("x")) +
  scale_y_continuous(breaks = c(0, -15, -30), labels = graus("y")) +
  labs(title = "(a) Brasil") + tema +
  theme(panel.background = element_rect(fill = "#DCEBF5", colour = NA),
        panel.grid.major = element_line(colour = "white", linewidth = 0.2))

# ---------------- (b) região de estudo ----------------
grp <- do.call(rbind, lapply(levels(props$regiao), function(r)
  st_sf(regiao = r, geometry = st_as_sfc(caixa(props[props$regiao == r, ], m = 0.05, asp = 1.15)))))
grp$rot <- c("c", "d", "e")
f_b <- fundo(area, 8, "regiao")
mun_r <- suppressWarnings(st_crop(mun, area))
rot_mun <- suppressWarnings(st_point_on_surface(st_crop(mun_est, area)))
xy <- st_coordinates(rot_mun); rot_mun$x <- xy[, 1]; rot_mun$y <- xy[, 2]
gxy <- st_coordinates(suppressWarnings(st_centroid(grp)))
grp$xmin <- sapply(st_geometry(grp), \(g) st_bbox(g)[[1]]); grp$ytop <- sapply(st_geometry(grp), \(g) st_bbox(g)[[4]])
b <- ggplot() +
  geom_raster(data = f_b, aes(x, y, fill = hex)) + scale_fill_identity() +
  geom_sf(data = mun_r, fill = NA, colour = alpha("white", 0.55), linewidth = 0.2, linetype = "dashed") +
  geom_sf(data = grp, fill = NA, colour = "red", linewidth = 0.5) +
  geom_label(data = grp, aes(xmin, ytop, label = rot), colour = "white", fill = "red", size = 2.4, fontface = "bold",
             label.size = 0, label.padding = unit(0.06, "cm"), hjust = 0, vjust = 1, label.r = unit(0, "cm")) +
  annotate("text", x = -54.75, y = -2.1, label = "Rio Amazonas", colour = "#BFE3FF", size = 1.9, fontface = "italic", angle = 8) +
  annotate("text", x = -55.2, y = -3.25, label = "Rio Tapajós", colour = "#BFE3FF", size = 1.9, fontface = "italic", angle = 72) +
  geom_point(data = cent, aes(x, y, colour = ocorrencia), size = 0.7, show.legend = FALSE) +
  geom_text_repel(data = rot_mun, aes(x, y, label = nome), size = 2, colour = "white", fontface = "italic",
                  bg.color = "grey15", bg.r = 0.12, seed = 3, segment.color = NA, force = 0.5) +
  scale_colour_manual(values = cores) +
  coord_sf(xlim = area[c(1, 3)], ylim = area[c(2, 4)], expand = FALSE) +
  scale_x_continuous(breaks = seq(-56, -51, 1), labels = graus("x")) +
  scale_y_continuous(breaks = seq(-4, -1, 1), labels = graus("y")) +
  escala() + norte() + labs(title = "(b) Região de estudo") + tema

# ---------------- (c–e) grupos ----------------
painel <- function(r, titulo, zoom) {
  bb <- caixa(props[props$regiao == r, ], m = 0.05, asp = 1.15)
  f <- fundo(bb, zoom, paste0("grupo_", r))
  mr <- suppressWarnings(st_crop(mun, bb))
  ggplot() +
    geom_raster(data = f, aes(x, y, fill = hex)) + scale_fill_identity() +
    geom_sf(data = mr, fill = NA, colour = alpha("white", 0.6), linewidth = 0.25, linetype = "dashed") +
    geom_sf(data = props, aes(colour = ocorrencia, linetype = grupo), fill = NA, linewidth = 0.55, key_glyph = "path") +
    geom_text_repel(data = cent[cent$regiao == r, ], aes(x, y, label = codigo), size = 2.05,
                    colour = "white", fontface = "bold", bg.color = "grey10", bg.r = 0.15,
                    min.segment.length = 0.3, segment.colour = "white", segment.size = 0.25,
                    box.padding = 0.25, max.overlaps = 50, seed = 4) +
    scale_colour_manual(values = cores, name = "Ocorrência", drop = FALSE) +
    scale_linetype_manual(values = c("Desenvolvimento" = "solid", "Teste externo" = "22"),
                          name = "Conjunto", drop = FALSE) +
    coord_sf(xlim = bb[c(1, 3)], ylim = bb[c(2, 4)], expand = FALSE) +
    scale_x_continuous(breaks = scales::breaks_pretty(3), labels = graus("x")) +
    scale_y_continuous(breaks = scales::breaks_pretty(3), labels = graus("y")) +
    escala() + labs(title = titulo) + tema
}
c_ <- painel("oeste",  "(c) Grupo oeste",   10)
d  <- painel("centro", "(d) Grupo central", 11)
e  <- painel("leste",  "(e) Grupo leste",   10)

leg <- guides(colour = guide_legend(order = 1, override.aes = list(linewidth = 1)),
              linetype = guide_legend(order = 2, override.aes = list(colour = "white", linewidth = 0.7)))
fig <- (a + b + plot_layout(widths = c(1, 2.9))) / (c_ + d + e) +
  plot_layout(heights = c(1, 1.25), guides = "collect") +
  plot_annotation(caption = paste0("Sistema de referência geodésico: SIRGAS 2000 (EPSG:4674). ",
                                   "Limites: IBGE (2024). Imagem: Esri World Imagery (2026)."),
                  theme = theme(plot.caption = element_text(size = 6, hjust = 0, colour = "grey25"))) &
  leg & theme(legend.position = "bottom", legend.direction = "horizontal",
              legend.title = element_text(size = 7, face = "bold"), legend.text = element_text(size = 6.5),
              legend.key = element_rect(fill = "grey30", colour = NA),
              legend.key.width = unit(0.7, "cm"), legend.key.height = unit(0.3, "cm"),
              legend.spacing.x = unit(0.4, "cm"))
ggsave(file.path(SAIDA, "FIGURA1_LOCALIZACAO.png"), fig, width = 16, height = 11.6, units = "cm",
       dpi = 300, bg = "white")
cat("ok\n")
