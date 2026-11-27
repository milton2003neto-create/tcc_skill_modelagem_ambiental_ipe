# 15_MAPA_LOCALIZACAO.R
# Mapa de localizacao das 34 propriedades (Figura 1 do TCC).
# Limites: malhas territoriais do IBGE (API servicodados.ibge.gov.br, 2024).
# Uso: Rscript R/15_MAPA_LOCALIZACAO.R
suppressPackageStartupMessages({
  library(sf); library(ggplot2); library(ggspatial); library(patchwork); library(ggrepel)
})
sf_use_s2(FALSE)

RAIZ  <- getwd()   # executar a partir da pasta do projeto
GEOM  <- file.path(RAIZ, "..", "..", "TCC - Ipes - Inicio do zero", "01 - Dados originais",
                   "Dados separados", "Geometrias")
SAIDA <- file.path(RAIZ, "resultados", "_geral", "10_mapa")
IBGE  <- file.path(SAIDA, "ibge")
dir.create(IBGE, recursive = TRUE, showWarnings = FALSE)

baixar <- function(url, arq) {
  f <- file.path(IBGE, arq)
  if (!file.exists(f)) download.file(url, f, mode = "wb", quiet = TRUE)
  f
}
api <- "https://servicodados.ibge.gov.br/api"
f_uf  <- baixar(paste0(api, "/v3/malhas/paises/BR?intrarregiao=UF&formato=application/vnd.geo%2Bjson&qualidade=minima"), "br_uf.json")
f_mun <- baixar(paste0(api, "/v3/malhas/estados/15?intrarregiao=municipio&formato=application/vnd.geo%2Bjson&qualidade=intermediaria"), "pa_mun.json")
f_nom <- baixar(paste0(api, "/v1/localidades/estados/15/municipios"), "pa_mun_nomes.json")

uf  <- st_read(f_uf, quiet = TRUE);  st_crs(uf)  <- 4674
mun <- st_read(f_mun, quiet = TRUE); st_crs(mun) <- 4674
nomes <- jsonlite::fromJSON(f_nom)[, c("id", "nome")]
mun$nome <- nomes$nome[match(mun$codarea, as.character(nomes$id))]
pa <- uf[uf$codarea == "15", ]

# --- propriedades (poligono do imovel) ---
tab <- read.csv2(file.path(RAIZ, "resultados", "_geral", "TABELA1_PROPRIEDADES_COM_NOMES.csv"),
                 encoding = "UTF-8")
pastas <- list.dirs(GEOM, recursive = FALSE)
props <- do.call(rbind, lapply(seq_len(nrow(tab)), function(i) {
  pasta <- pastas[toupper(basename(pastas)) == toupper(tab$propriedade[i])]
  shp <- list.files(file.path(pasta, "PROPRIEDADE"), "\\.shp$", full.names = TRUE)[1]
  g <- st_read(shp, quiet = TRUE)
  if (is.na(st_crs(g))) stop("sem SRC: ", shp)
  g <- st_union(st_zm(st_transform(g, 4674)))
  st_sf(codigo = tab$codigo[i], conjunto = tab$conjunto[i],
        roxo = tab$roxo[i] > 0, amarelo = tab$amarelo[i] > 0, geometry = g)
}))
props$ocorrencia <- ifelse(props$roxo & props$amarelo, "Ambas as espécies",
                     ifelse(props$roxo, "Somente ipê-roxo", "Somente ipê-amarelo"))
props$grupo <- ifelse(props$conjunto == "Teste externo", "Teste externo", "Desenvolvimento")
cent <- suppressWarnings(st_point_on_surface(props))
xy <- st_coordinates(cent); cent$x <- xy[, 1]; cent$y <- xy[, 2]

mun_est <- mun[lengths(st_intersects(mun, props)) > 0, ]
cat("Municipios:", paste(sort(mun_est$nome), collapse = "; "), "\n")
write.csv2(data.frame(codigo = props$codigo,
                      municipio = sapply(st_intersects(cent, mun), \(k) paste(mun$nome[k], collapse = "/")),
                      lon = round(cent$x, 4), lat = round(cent$y, 4)),
           file.path(SAIDA, "PROPRIEDADES_MUNICIPIOS.csv"), row.names = FALSE)

# Regioes (agrupamentos de propriedades) para os paineis ampliados
cent$regiao <- cut(cent$x, c(-Inf, -55, -52, Inf), labels = c("oeste", "centro", "leste"))
props$regiao <- cent$regiao
caixas <- do.call(rbind, lapply(levels(cent$regiao), function(r) {
  b <- st_bbox(props[props$regiao == r, ]); m <- 0.08
  st_sf(regiao = r, geometry = st_as_sfc(st_bbox(c(xmin = b[[1]] - m, ymin = b[[2]] - m,
                                                   xmax = b[[3]] + m, ymax = b[[4]] + m), crs = 4674)))
}))
caixas$rot <- c("c", "d", "e")

tema <- theme_bw(base_size = 8, base_family = "sans") +
  theme(panel.grid = element_line(colour = "grey90", linewidth = 0.2), axis.title = element_blank(),
        axis.text = element_text(size = 6), plot.title = element_text(size = 8, face = "bold"))

a <- ggplot() + geom_sf(data = uf, fill = "grey95", colour = "grey60", linewidth = 0.15) +
  geom_sf(data = pa, fill = "grey60", colour = "black", linewidth = 0.3) +
  coord_sf(xlim = c(-74, -34), ylim = c(-34, 6), expand = FALSE) +
  scale_x_continuous(breaks = c(-70, -55, -40)) + scale_y_continuous(breaks = c(0, -15, -30)) +
  labs(title = "(a) Brasil") + tema

b <- ggplot() + geom_sf(data = mun, fill = "white", colour = "grey80", linewidth = 0.1) +
  geom_sf(data = mun_est, fill = "grey75", colour = "grey40", linewidth = 0.2) +
  geom_sf(data = pa, fill = NA, colour = "black", linewidth = 0.4) +
  geom_sf(data = caixas, fill = NA, colour = "red", linewidth = 0.4) +
  geom_sf_text(data = caixas, aes(label = rot), colour = "red", size = 2.6, fontface = "bold",
               nudge_y = 0.75) +
  scale_x_continuous(breaks = c(-56, -52, -48)) + scale_y_continuous(breaks = c(0, -4, -8)) +
  annotation_scale(location = "bl", width_hint = 0.3, text_cex = 0.55, height = unit(0.1, "cm")) +
  labs(title = "(b) Pará") + tema

cores <- c("Somente ipê-roxo" = "#7B3294", "Somente ipê-amarelo" = "#E6AB02", "Ambas as espécies" = "#1B9E77")
painel <- function(r, titulo, norte = FALSE, escala = "bl") {
  bb <- st_bbox(caixas[caixas$regiao == r, ])
  mr <- suppressWarnings(st_point_on_surface(st_crop(mun_est, bb)))
  p <- ggplot() +
    geom_sf(data = mun, fill = "white", colour = "grey60", linewidth = 0.25, linetype = "dashed") +
    geom_sf_text(data = mr, aes(label = nome), size = 2.1, colour = "grey50", fontface = "italic") +
    geom_sf(data = props, aes(fill = ocorrencia), colour = "grey20", linewidth = 0.15, alpha = 0.35) +
    geom_point(data = cent, aes(x, y, fill = ocorrencia, shape = grupo), size = 1.9, stroke = 0.35) +
    geom_text_repel(data = cent[cent$regiao == r, ], aes(x, y, label = codigo), size = 2,
                    min.segment.length = 0, segment.size = 0.2, box.padding = 0.3,
                    max.overlaps = 50, seed = 2) +
    scale_fill_manual(values = cores, name = "Ocorrência", drop = FALSE) +
    scale_shape_manual(values = c("Desenvolvimento" = 21, "Teste externo" = 24), name = "Conjunto") +
    guides(fill = guide_legend(override.aes = list(shape = 21, size = 2.6, alpha = 1))) +
    coord_sf(xlim = bb[c(1, 3)], ylim = bb[c(2, 4)], expand = FALSE) +
    scale_x_continuous(breaks = scales::breaks_pretty(3)) + scale_y_continuous(breaks = scales::breaks_pretty(3)) +
    annotation_scale(location = escala, width_hint = 0.3, text_cex = 0.55, height = unit(0.1, "cm")) +
    labs(title = titulo) + tema
  if (norte) p <- p + annotation_north_arrow(location = "tr", height = unit(0.7, "cm"),
                        width = unit(0.55, "cm"), style = north_arrow_fancy_orienteering(text_size = 5))
  p
}
c_ <- painel("oeste", "(c) Grupo oeste", norte = TRUE, escala = "br")
d  <- painel("centro", "(d) Grupo central")
e  <- painel("leste", "(e) Grupo leste", escala = "br")

fig <- ((a / b) | c_) / (d | e) + plot_layout(guides = "collect", heights = c(2.2, 1)) &
  theme(legend.position = "bottom", legend.box = "vertical", legend.margin = margin(0, 0, 0, 0),
        legend.title = element_text(size = 7.5, face = "bold"), legend.text = element_text(size = 7))
fig <- fig + plot_annotation(caption = "Sistema de referência: SIRGAS 2000 (EPSG:4674). Limites municipais e estaduais: IBGE (2024).",
                             theme = theme(plot.caption = element_text(size = 6.5, hjust = 0)))
ggsave(file.path(SAIDA, "FIGURA1_LOCALIZACAO.png"), fig, width = 16, height = 19, units = "cm", dpi = 300)
cat("ok:", file.path(SAIDA, "FIGURA1_LOCALIZACAO.png"), "\n")
