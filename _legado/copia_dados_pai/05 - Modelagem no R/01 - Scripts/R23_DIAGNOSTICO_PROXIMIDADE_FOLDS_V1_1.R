# ==============================================================================
# TCC IPES | R23 V1.1 - PROXIMIDADE ENTRE PROPRIEDADES / UPAs E FOLDS
# ==============================================================================
# Somente diagnostico: NAO reduz pontos, NAO exclui propriedades, NAO cria folds,
# NAO ajusta MaxEnt, NAO consulta os dados das 7 propriedades de teste externo.
# Dados: 27 propriedades, 64 UPAs inventariadas, 8680 presencas / B2 com 10000.
# Selecione 19_METRICAS_72_MODELOS_B2.csv NA PASTA OFICIAL R19.
# O script usa os arquivos registrados com MD5 no manifesto R19.
#
# IMPORTANTE SOBRE AS DISTANCIAS:
# - Quando usamos coordenadas das amostras, a distancia MINIMA entre pontos
#   e um INDICADOR AMOSTRAL, nao distancia exata entre limites das UPAs.
# - OPCIONALMENTE, passe GPKG/SHP CONSOLIDADO de poligonos das 64 UPAs
#   inventariadas, com campos propriedade e upa_id identicos aos do B2.
#   Neste caso calcula distancia exata entre contornos das UPAs inventariadas.
# - Distancia entre limites de UPAs != distancia entre limites totais dos imoveis.
# - Os limiares de 5/10/20/50 km sao CENARIOS e NAO cortes aprovados.
# ==============================================================================

versao_r23 <- 'R23_PROXIMIDADE_FOLDS_V1_1_20261117'
# Opcional: caminho de uma camada consolidada de poligonos das UPAs inventariadas.
# Exemplo: "C:/.../UPAS_INVENTARIADAS_DESENVOLVIMENTO.gpkg"
CAMINHO_POLIGONOS_UPA <- ''
CAMADA_POLIGONOS_GPKG <- ''   # deixe vazio se houver uma unica camada
# Opcional: CSV com propriedade, upa_id e latitude/longitude (somente desenvolv.).
CAMINHO_COORDENADAS_ALTERNATIVO <- ''
MAX_PONTOS_POR_UPA <- 80L  # subamostra deterministica para distancias amostrais
LIMIARES_KM <- c(5,10,20,50)

cat('\nR23: selecione 19_METRICAS_72_MODELOS_B2.csv NA pasta oficial do R19.\n')
arq19 <- normalizePath(file.choose(),winslash='/',mustWork=TRUE)
if (basename(arq19) != '19_METRICAS_72_MODELOS_B2.csv')
  stop('Selecione o CSV ORIGINAL 19_METRICAS_72_MODELOS_B2.csv.')
pasta19 <- dirname(arq19)
pasta_resultados <- pasta19
while (basename(pasta_resultados) != '06 - Resultados' &&
       dirname(pasta_resultados) != pasta_resultados)
  pasta_resultados <- dirname(pasta_resultados)
if (basename(pasta_resultados) != '06 - Resultados')
  stop('O R19 precisa estar dentro da pasta 06 - Resultados.')
raiz <- dirname(pasta_resultados)
saida <- file.path(pasta_resultados,'21 - Independencia espacial R23 V1_1')

ler <- function(f) read.csv(f,stringsAsFactors=FALSE,
                check.names=FALSE,fileEncoding='UTF-8-BOM')
exigir <- function(d,campo,rotulo) {
  faltam <- setdiff(campo,names(d))
  if (length(faltam)) stop('Faltam colunas em ',rotulo,': ',paste(faltam,collapse=', '))
}
md5 <- function(f) unname(tools::md5sum(f))
manifesto_path <- file.path(pasta19,'19_MANIFESTO_ENTRADAS.csv')
if (!file.exists(manifesto_path)) stop('Manifesto oficial do R19 ausente.')
man <- ler(manifesto_path)
exigir(man,c('arquivo','caminho','md5'),'manifesto R19')
localizar <- function(nome) {
  z <- man[man$arquivo==nome,,drop=FALSE]
  if (nrow(z)!=1L) stop('Fonte sem registro unico no manifesto: ',nome)
  p <- gsub('\\\\','/',as.character(z$caminho[1]))
  possibilidades <- p
  for (ancora in c('04 - Dados para o MaxEnt/','06 - Resultados/')) {
    pos <- regexpr(ancora,p,fixed=TRUE)[1]
    if (pos>0L) possibilidades <- c(possibilidades,
                                   file.path(raiz,substring(p,pos)))
  }
  possibilidades <- unique(possibilidades)
  existentes <- possibilidades[file.exists(possibilidades)]
  ok <- existentes[tolower(vapply(existentes,md5,character(1)))==
                    tolower(as.character(z$md5[1]))]
  if (!length(ok)) stop('Fonte com MD5 correto nao localizada: ',nome,
    '\nO R23 nao substitui uma fonte por outra de mesmo nome.')
  normalizePath(ok[1],winslash='/',mustWork=TRUE)
}

arq_pres <- localizar('05_PRESENCAS_UM_POR_PIXEL_30M.csv')
arq_bg <- localizar('18_BACKGROUND_B2_10000_COM_FOLDS.csv')
pres <- ler(arq_pres)
bg <- ler(arq_bg)
m <- ler(arq19)
exigir(pres,c('especie','propriedade','upa_id','fold_cv'),'presencas R05')
exigir(bg,c('propriedade','upa_id','fold_cv'),'background B2 R18')
exigir(m,c('id','especie','fold_cv'),'metricas R19')
if (nrow(pres)!=8680L || nrow(bg)!=10000L || nrow(m)!=72L ||
    length(unique(bg$propriedade))!=27L ||
    nrow(unique(bg[,c('propriedade','upa_id')]))!=64L ||
    anyDuplicated(m$id) || !setequal(unique(bg$fold_cv),1:3) ||
    !setequal(unique(pres$fold_cv),1:3))
  stop('Preflight: contagens diferentes do protocolo R19/R22. Nenhuma saida gravada.')

norm <- function(x) {
  v <- iconv(as.character(x),to='ASCII//TRANSLIT',sub='')
  if (anyNA(v)) stop('Falha de encoding nos nomes de propriedades.')
  toupper(trimws(gsub('[ _-]+',' ',v)))
}
reservadas <- c('BARRO BRANCO','CURUCA','GUARIUBA','JATOBA',
                'LOTE 01','MARILIA','PALMEIRA')
if (any(norm(c(pres$propriedade,bg$propriedade)) %in% reservadas))
  stop('Seguranca: propriedade do TESTE EXTERNO nas entradas.')
if (!setequal(unique(pres$propriedade),unique(bg$propriedade)))
  stop('Propriedades de presencas e background diferentes.')
propfold <- unique(rbind(pres[,c('propriedade','fold_cv')],
                         bg[,c('propriedade','fold_cv')]))
if (anyDuplicated(propfold$propriedade) || nrow(propfold)!=27L)
  stop('Uma propriedade pertence a mais de um fold.')
upa_fold <- unique(bg[,c('propriedade','upa_id','fold_cv')])
if (anyDuplicated(paste(upa_fold$propriedade,upa_fold$upa_id,sep='||')))
  stop('UPA foi atribuida a mais de um fold.')
chave <- function(d) paste(d$propriedade,d$upa_id,sep='||')
if (!all(chave(pres) %in% chave(bg)))
  stop('Presenca encontrada fora da base das 64 UPAs inventariadas.')

# --------------------------------------------------------------------------
# 1. Extrair coordenadas geograficas, preferencialmente de B2.
# --------------------------------------------------------------------------
cn <- function(x) gsub('[^a-z0-9]','',tolower(iconv(x,to='ASCII//TRANSLIT')))
coluna <- function(d,candidatos) {
  n <- cn(names(d)); i <- match(candidatos,n); i <- i[!is.na(i)]
  if (length(i)) names(d)[i[1]] else NA_character_
}
extrair_latlon <- function(d,rotulo) {
  lon <- coluna(d,c('longitude','long','lon','longitudegraus','londecimal','xgeografica'))
  lat <- coluna(d,c('latitude','lat','latitudegraus','latdecimal','ygeografica'))
  if (!is.na(lon) && !is.na(lat)) {
    xx <- suppressWarnings(as.numeric(d[[lon]]))
    yy <- suppressWarnings(as.numeric(d[[lat]]))
    if (all(is.finite(xx)) && all(is.finite(yy)) &&
        all(xx > -75 & xx < -43) && all(yy > -17 & yy < 8)) {
      return(data.frame(longitude=xx,latitude=yy))
    }
    stop('Coordenadas geograficas invalidas em ',rotulo,': ',lon,', ',lat,
         '. Confira a origem; NAO force um SRC.')
  }
  # UTM: so transforma se easting, northing e EPSG EXPLICITOS existem.
  e <- coluna(d,c('xutm','utmx','eastutm','easting','coordxutm','coordeste'))
  n <- coluna(d,c('yutm','utmy','northutm','northing','coordyutm','coordnorte'))
  epsg <- coluna(d,c('epsgutm','epsg','srcepsg','codigoepsg'))
  if (!is.na(e) && !is.na(n) && !is.na(epsg)) {
    if (!requireNamespace('sf',quietly=TRUE))
      stop('Instale o pacote sf para converter UTM (install.packages("sf")).')
    ep <- as.integer(d[[epsg]])
    if (anyNA(ep) || !all(ep %in% c(31981L,31982L)))
      stop('EPSG UTM divergente de SIRGAS 2000 UTM 21S/22S em ',rotulo)
    x <- as.numeric(d[[e]]); y <- as.numeric(d[[n]])
    if (any(!is.finite(x)) || any(!is.finite(y))) stop('UTM invalida em ',rotulo)
    res <- data.frame(longitude=rep(NA_real_,nrow(d)),latitude=rep(NA_real_,nrow(d)))
    for (cr in unique(ep)) {
      ix <- which(ep==cr)
      z <- sf::st_as_sf(data.frame(e=x[ix],n=y[ix]),coords=c('e','n'),crs=cr)
      z <- sf::st_transform(z,4674)
      co <- sf::st_coordinates(z)
      res$longitude[ix] <- co[,1]; res$latitude[ix] <- co[,2]
    }
    return(res)
  }
  NULL
}

pontos <- NULL
fonte_coords <- NA_character_
for (tipo in c('B2','PRESENCAS')) {
  d <- if (tipo=='B2') bg else pres
  c <- extrair_latlon(d,tipo)
  if (!is.null(c)) {
    pontos <- cbind(d[,c('propriedade','upa_id','fold_cv'),drop=FALSE],c)
    fonte_coords <- tipo
    break
  }
}
if (is.null(pontos)) {
  alternativa <- CAMINHO_COORDENADAS_ALTERNATIVO
  if (nzchar(alternativa)) {
    if (!file.exists(alternativa)) stop('CSV alternativo nao encontrado.')
    d <- ler(alternativa)
    exigir(d,c('propriedade','upa_id'),'CSV alternativo')
    # Nunca trazer para a analise registros de propriedades externas.
    d <- d[chave(d) %in% chave(bg),,drop=FALSE]
    c <- extrair_latlon(d,'CSV alternativo')
    if (is.null(c)) stop('CSV alternativo nao contem lat/lon ou UTM+EPSG.')
    d <- cbind(d[,c('propriedade','upa_id'),drop=FALSE],c)
    d <- merge(d,upa_fold,by=c('propriedade','upa_id'),all.x=TRUE,sort=FALSE)
    if (anyNA(d$fold_cv) || !setequal(chave(d),chave(bg)))
      stop('CSV alternativo nao cobre as mesmas 64 UPAs inventariadas.')
    pontos <- d
    fonte_coords <- 'CSV_ALTERNATIVO'
  }
}
if (!is.null(pontos)) {
  if (anyNA(pontos) || !setequal(chave(pontos),chave(bg)))
    stop('Coordenadas nao cobrem as mesmas UPAs do B2.')
  if (!all(pontos$fold_cv == upa_fold$fold_cv[
        match(chave(pontos),chave(upa_fold))]))
    stop('Folds das coordenadas diferem do B2.')
}

# --------------------------------------------------------------------------
# 2. Poligonos opcionais: arquivos com as 64 UPAs, id exato do R18.
# --------------------------------------------------------------------------
geom_upa <- NULL; geom_prop <- NULL
fonte_poligonos <- NA_character_
if (nzchar(CAMINHO_POLIGONOS_UPA)) {
  if (!requireNamespace('sf',quietly=TRUE))
    stop('Instale o pacote sf para calcular distancia de poligonos.')
  if (!file.exists(CAMINHO_POLIGONOS_UPA)) stop('Poligonos nao encontrados.')
  args <- list(dsn=CAMINHO_POLIGONOS_UPA,quiet=TRUE)
  if (nzchar(CAMADA_POLIGONOS_GPKG)) args$layer <- CAMADA_POLIGONOS_GPKG
  u <- do.call(sf::st_read,args)
  exigir(u,c('propriedade','upa_id'),'poligonos consolidados')
  if (is.na(sf::st_crs(u))) stop('Poligonos nao tem SRC declarado: nao force.')
  if (!all(as.character(sf::st_geometry_type(u)) %in% c('POLYGON','MULTIPOLYGON')))
    stop('Arquivo selecionado nao possui apenas geometrias de poligono.')
  # Filtra APENAS as UPAs do desenvolvimento antes de qualquer distancia.
  u <- u[chave(u) %in% chave(bg),,drop=FALSE]
  if (!setequal(chave(u),chave(bg)) || any(sf::st_is_empty(u)))
    stop('Poligonos nao cobrem exatamente as 64 UPAs inventariadas.')
  u <- sf::st_transform(sf::st_make_valid(u),4674)
  sf::sf_use_s2(TRUE)
  grupos <- split(seq_len(nrow(u)),chave(u))
  geoms <- sf::st_geometry(u)
  union_g <- lapply(grupos,function(i) sf::st_union(geoms[i])[[1]])
  geom_upa <- do.call(sf::st_sfc,c(unname(union_g),list(crs=4674)))
  names(geom_upa) <- names(grupos)
  props <- split(seq_along(grupos),vapply(strsplit(names(grupos),'\\|\\|'),`[`,character(1),1))
  geom_prop <- do.call(sf::st_sfc,c(lapply(props,function(i) sf::st_union(geom_upa[i])[[1]]),list(crs=4674)))
  names(geom_prop) <- names(props)
  fonte_poligonos <- normalizePath(CAMINHO_POLIGONOS_UPA,winslash='/',mustWork=TRUE)
}
if (is.null(pontos) && is.null(geom_upa)) {
  stop('R23 nao encontrou coordenadas em B2 nem em R05.\n',
    'Colunas B2: ',paste(names(bg),collapse=', '),'\n',
    'Colunas R05: ',paste(names(pres),collapse=', '),'\n',
    'Defina CAMINHO_POLIGONOS_UPA com GPKG consolidado OU ',
    'CAMINHO_COORDENADAS_ALTERNATIVO com colunas propriedade,upa_id,latitude,longitude.\n',
    'Nao e possivel calcular distancias reais a partir apenas de atributos ambientais.')
}

# --------------------------------------------------------------------------
# 3. Estatisticas ambientais das propriedades (somente B2).
# --------------------------------------------------------------------------
variaveis <- c('altitude_m','declividade_graus','dist_rio_raster_m',
               'bio12_mm_ano','bio17_mm_mes')
exigir(bg,variaveis,'background B2')
for (v in variaveis) if (!is.numeric(bg[[v]]) || any(!is.finite(bg[[v]])))
  stop('Preditora invalida no B2: ',v)
props <- sort(unique(as.character(bg$propriedade)))
upas <- sort(unique(chave(bg)))
if (any(grepl('\\|\\|',props))) stop('Identificadores de propriedade invalidos.')
contagem <- as.data.frame(table(bg$propriedade),stringsAsFactors=FALSE)
names(contagem) <- c('propriedade','n_background')
propinfo <- merge(propfold,contagem,by='propriedade',sort=TRUE)
for (sp in c('Ipe-roxo','Ipe-amarelo')) {
  nome <- if (sp=='Ipe-roxo') 'n_roxo' else 'n_amarelo'
  tab <- table(factor(pres$propriedade[pres$especie==sp],levels=props))
  propinfo[[nome]] <- as.integer(tab[match(propinfo$propriedade,names(tab))])
}
ambmed <- t(vapply(props,function(p) vapply(variaveis,function(v)
  stats::median(bg[[v]][bg$propriedade==p]),numeric(1)),numeric(length(variaveis))))
rownames(ambmed) <- props; colnames(ambmed) <- variaveis
DP <- vapply(bg[,variaveis,drop=FALSE],stats::sd,numeric(1))
if (any(!is.finite(DP) | DP==0)) stop('Variavel ambiental com DP nulo.')
amb_z <- sweep(ambmed,2,DP,'/')

solo <- as.character(bg$textura_subgrupo)
classes <- sort(unique(solo))
H <- t(vapply(props,function(p) {
  z <- table(factor(solo[bg$propriedade==p],levels=classes)); as.numeric(z)/sum(z)
},numeric(length(classes))))
rownames(H) <- props

# Coordenadas amostrais: amostragem deterministica e limitada por UPA.
if (!is.null(pontos)) {
  ids <- split(seq_len(nrow(pontos)),chave(pontos))
  amostrar <- function(ix,n) {
    if(length(ix)<=n) ix else ix[unique(round(seq(1,length(ix),length.out=n)))]
  }
  ind <- unlist(lapply(ids,amostrar,n=MAX_PONTOS_POR_UPA),use.names=FALSE)
  ps <- pontos[ind,,drop=FALSE]
  # Raio terrestre medio 6371,0088 km; coordenadas em graus.
  # base::pi nao pode ser confundido com uma matriz de indices de pares.
  # A forma matricial e preservada inclusive para 1 ponto x 1 ponto.
  haversine_matriz <- function(a,b) {
    stopifnot(all(c('latitude','longitude') %in% names(a)),
              all(c('latitude','longitude') %in% names(b)),
              nrow(a)>0L, nrow(b)>0L)
    rad <- base::pi / 180
    lat_a <- as.numeric(a$latitude) * rad
    lat_b <- as.numeric(b$latitude) * rad
    lon_a <- as.numeric(a$longitude) * rad
    lon_b <- as.numeric(b$longitude) * rad
    dlat <- outer(lat_a,lat_b,'-')
    dlon <- outer(lon_a,lon_b,'-')
    h <- sin(dlat/2)^2 + outer(cos(lat_a),cos(lat_b),'*') * sin(dlon/2)^2
    # pmin/pmax podem descartar as dimensoes; restaure-as explicitamente.
    dist <- 2 * 6371.0088 * asin(sqrt(pmin(1,pmax(0,as.vector(h)))))
    matrix(dist,nrow=nrow(a),ncol=nrow(b))
  }
  # Testes internos antes de processar os pares das 64 UPAs:
  # zero km na origem; cerca de 111,2 km para 1 grau no equador;
  # dimensoes preservadas em matrizes 1x1 e 2x3.
  p0 <- data.frame(latitude=0,longitude=0)
  p1 <- data.frame(latitude=0,longitude=1)
  teste_11 <- haversine_matriz(p0,p0)
  teste_12 <- haversine_matriz(p0,p1)
  teste_23 <- haversine_matriz(p0[rep(1,2),,drop=FALSE],
                              p1[rep(1,3),,drop=FALSE])
  if (!identical(dim(teste_11),c(1L,1L)) ||
      !identical(dim(teste_23),c(2L,3L)) ||
      abs(teste_11[1,1])>1e-9 ||
      abs(teste_12[1,1]-111.195)>0.01 ||
      any(!is.finite(teste_23)))
    stop('Falha no autoteste da distancia Haversine, antes de analisar os dados.')
  rm(p0,p1,teste_11,teste_12,teste_23)
  ponto_min <- function(i,j) {
    a <- ps[i,,drop=FALSE]; b <- ps[j,,drop=FALSE]
    if (!nrow(a) || !nrow(b)) return(NA_real_)
    min(haversine_matriz(a,b))
  }
  igprop <- split(seq_len(nrow(ps)),ps$propriedade)
  igupa <- split(seq_len(nrow(ps)),chave(ps))
  centro <- t(vapply(props,function(p) {
    a <- ps[igprop[[p]],,drop=FALSE]
    c(lon=mean(a$longitude),lat=mean(a$latitude))
  },numeric(2)))
  rownames(centro) <- props
} else {
  centro <- matrix(NA_real_,length(props),2,dimnames=list(props,c('lon','lat')))
}

# Coordenadas de superficies de poligonos para mapa esquematico opcional.
if (!is.null(geom_prop) && is.null(pontos)) {
  cc <- sf::st_coordinates(sf::st_point_on_surface(geom_prop))
  centro[names(geom_prop),] <- cc[,1:2]
}

# --------------------------------------------------------------------------
# 4. Matrizes de proximidade e pares sem mistura treino x teste.
# --------------------------------------------------------------------------
par_idx <- function(n) t(utils::combn(seq_len(n),2))
indices_propriedades <- par_idx(length(props))
upai <- par_idx(length(upas))
pares <- data.frame(propriedade_a=props[indices_propriedades[,1]],
                    propriedade_b=props[indices_propriedades[,2]],stringsAsFactors=FALSE)
pares$fold_a <- propinfo$fold_cv[match(pares$propriedade_a,propinfo$propriedade)]
pares$fold_b <- propinfo$fold_cv[match(pares$propriedade_b,propinfo$propriedade)]
pares$folds_diferentes <- pares$fold_a!=pares$fold_b
pares$dist_pontos_amostrais_min_km <- NA_real_
pares$dist_upas_poligonos_min_km <- NA_real_
pares$dist_centros_amostrais_km <- NA_real_
pares$dist_ambiental_padronizada <- NA_real_
pares$dist_textura_hellinger <- NA_real_
pares$delta_mediana_BIO12_mm_ano <- NA_real_
pares$delta_mediana_BIO17_mm_mes <- NA_real_

for (i in seq_len(nrow(pares))) {
  a <- pares$propriedade_a[i]; b <- pares$propriedade_b[i]
  if (!is.null(pontos)) {
    pares$dist_pontos_amostrais_min_km[i] <- ponto_min(igprop[[a]],igprop[[b]])
    xa <- data.frame(longitude=centro[a,1],latitude=centro[a,2])
    xb <- data.frame(longitude=centro[b,1],latitude=centro[b,2])
    pares$dist_centros_amostrais_km[i] <- haversine_matriz(xa,xb)[1,1]
  }
  if (!is.null(geom_prop))
    pares$dist_upas_poligonos_min_km[i] <- as.numeric(sf::st_distance(
       geom_prop[match(a,names(geom_prop))],geom_prop[match(b,names(geom_prop))]))/1000
  pares$dist_ambiental_padronizada[i] <- sqrt(sum((amb_z[a,]-amb_z[b,])^2))
  pares$dist_textura_hellinger[i] <- sqrt(sum((sqrt(H[a,])-sqrt(H[b,]))^2))/sqrt(2)
  pares$delta_mediana_BIO12_mm_ano[i] <- ambmed[a,'bio12_mm_ano']-ambmed[b,'bio12_mm_ano']
  pares$delta_mediana_BIO17_mm_mes[i] <- ambmed[a,'bio17_mm_mes']-ambmed[b,'bio17_mm_mes']
}

parupa <- data.frame(upa_a=upas[upai[,1]],upa_b=upas[upai[,2]],
                     stringsAsFactors=FALSE)
ua <- upa_fold[match(parupa$upa_a,chave(upa_fold)),,drop=FALSE]
ub <- upa_fold[match(parupa$upa_b,chave(upa_fold)),,drop=FALSE]
parupa$propriedade_a <- ua$propriedade
parupa$propriedade_b <- ub$propriedade
parupa$fold_a <- ua$fold_cv; parupa$fold_b <- ub$fold_cv
parupa$mesma_propriedade <- parupa$propriedade_a==parupa$propriedade_b
parupa$folds_diferentes <- parupa$fold_a!=parupa$fold_b
parupa$dist_pontos_amostrais_min_km <- NA_real_
parupa$dist_poligonos_upa_km <- NA_real_
for (i in seq_len(nrow(parupa))) {
  if (!is.null(pontos))
    parupa$dist_pontos_amostrais_min_km[i] <- ponto_min(
      igupa[[parupa$upa_a[i]]],igupa[[parupa$upa_b[i]]])
  if (!is.null(geom_upa))
    parupa$dist_poligonos_upa_km[i] <- as.numeric(sf::st_distance(
       geom_upa[match(parupa$upa_a[i],names(geom_upa))],
       geom_upa[match(parupa$upa_b[i],names(geom_upa))]))/1000
}

# Distancia principal para graficos/cenarios; rotulo explicito no resultado.
if (!is.null(geom_prop)) {
  pares$distancia_diagnostica_km <- pares$dist_upas_poligonos_min_km
  parupa$distancia_diagnostica_km <- parupa$dist_poligonos_upa_km
  tipo_distancia <- 'EXATA_ENTRE_POLIGONOS_DAS_UPAS_INVENTARIADAS'
} else {
  pares$distancia_diagnostica_km <- pares$dist_pontos_amostrais_min_km
  parupa$distancia_diagnostica_km <- parupa$dist_pontos_amostrais_min_km
  tipo_distancia <- 'APROXIMADA_MINIMA_ENTRE_PONTOS_AMOSTRADOS'
}
if (anyNA(pares$distancia_diagnostica_km) || anyNA(parupa$distancia_diagnostica_km))
  stop('Distancias insuficientes. Nenhuma saida sera gravada.')

# Vizinho mais proximo de CADA propriedade: no mesmo fold e em outro fold.
vizinhos <- do.call(rbind,lapply(props,function(p) {
  z <- pares[pares$propriedade_a==p | pares$propriedade_b==p,,drop=FALSE]
  z$outro <- ifelse(z$propriedade_a==p,z$propriedade_b,z$propriedade_a)
  z <- z[order(z$distancia_diagnostica_km),,drop=FALSE]
  outro_fold <- z[z$folds_diferentes,,drop=FALSE]
  mesmo_fold <- z[!z$folds_diferentes,,drop=FALSE]
  data.frame(propriedade=p,
    fold_cv=propfold$fold_cv[match(p,propfold$propriedade)],
    vizinho_mais_proximo=z$outro[1],
    dist_vizinho_mais_proximo_km=z$distancia_diagnostica_km[1],
    vizinho_outro_fold=if(nrow(outro_fold))outro_fold$outro[1] else NA_character_,
    dist_mais_proximo_outro_fold_km=if(nrow(outro_fold))outro_fold$distancia_diagnostica_km[1] else NA_real_,
    vizinho_mesmo_fold=if(nrow(mesmo_fold))mesmo_fold$outro[1] else NA_character_,
    dist_mais_proximo_mesmo_fold_km=if(nrow(mesmo_fold))mesmo_fold$distancia_diagnostica_km[1] else NA_real_)
}))

# Cenários de cluster por ligação simples; nao escolher limiar agora.
componentes <- function(n,arestas) {
  p <- seq_len(n)
  raiz_de <- function(i) { while(p[i]!=i) i<-p[i]; i }
  if (nrow(arestas)) for (j in seq_len(nrow(arestas))) {
    a<-raiz_de(arestas[j,1]); b<-raiz_de(arestas[j,2])
    if(a!=b) p[b]<-a
  }
  vapply(seq_len(n),raiz_de,integer(1))
}
clusters <- list(); resumos <- list()
for (t in LIMIARES_KM) {
  ids <- which(pares$distancia_diagnostica_km<=t)
  componentes_p <- componentes(length(props),indices_propriedades[ids,,drop=FALSE])
  cod <- match(componentes_p,unique(componentes_p))
  cl <- data.frame(limiar_km=t,propriedade=props,grupo=cod,
     fold_cv=propfold$fold_cv[match(props,propfold$propriedade)])
  cl$n_roxo <- propinfo$n_roxo[match(props,propinfo$propriedade)]
  cl$n_amarelo <- propinfo$n_amarelo[match(props,propinfo$propriedade)]
  clusters[[as.character(t)]] <- cl
  resumos[[as.character(t)]] <- data.frame(
    limiar_km=t,tipo_distancia=tipo_distancia,
    n_pares_propriedades_ate_limiar=length(ids),
    n_pares_entre_folds_ate_limiar=sum(pares$folds_diferentes[ids]),
    n_pares_upas_entre_folds_ate_limiar=sum(parupa$folds_diferentes &
                                             parupa$distancia_diagnostica_km<=t),
    n_grupos=length(unique(cod)),
    n_grupos_multifold=sum(vapply(split(cl$fold_cv,cl$grupo),
                                    function(z) length(unique(z))>1L,logical(1))),
    stringsAsFactors=FALSE)
}
clusters <- do.call(rbind,clusters); rownames(clusters)<-NULL
resumos <- do.call(rbind,resumos); rownames(resumos)<-NULL

# Propriedades dos folds problemáticos e vizinhos de outro fold.
alvo <- data.frame(propriedade=c('CEDRO','SANTA LÚCIA','TOPAZIO',
              'ÁGUAS CLARAS','AVEIRO','ESPERANÇA - PRAINHA','MURURÉ',
              'PINHO','SAFIRA','VALE VERDE'),
              especie=c(rep('Ipe-roxo',3),rep('Ipe-amarelo',7)),
              fold_critico=c(rep(3L,3),rep(2L,7)))
alvo <- merge(alvo,vizinhos,by='propriedade',all.x=TRUE,sort=FALSE)
if (anyNA(alvo$fold_cv) || any(alvo$fold_cv != alvo$fold_critico))
  stop('Lista dos folds criticos diverge do R19. Confira o protocolo.')

# Integrar AUC local C0 do R22, se existir, SEM recalcular modelos.
arq_auc22 <- file.path(pasta_resultados,'20 - Ablacao de variaveis R22 V1',
                       '22_AUC_OMISSAO_POR_PROPRIEDADE.csv')
if (file.exists(arq_auc22)) {
  z <- ler(arq_auc22)
  exigir(z,c('especie','fold_cv','conjunto','propriedade','auc_local_b2',
             'omissao_local'),'AUC local R22')
  z <- z[z$conjunto=='C0_COMPLETO',c('especie','fold_cv','propriedade',
                                     'auc_local_b2','omissao_local')]
  if(anyDuplicated(z[,c('especie','fold_cv','propriedade')]))
    stop('R22 contem C0 duplicado por propriedade.')
  alvo <- merge(alvo,z,by.x=c('propriedade','especie','fold_critico'),
                by.y=c('propriedade','especie','fold_cv'),all.x=TRUE,sort=FALSE)
}

# --------------------------------------------------------------------------
# 5. Registrar resultados em NOVA pasta. Nao sobrescrever nem reiniciar R22.
# --------------------------------------------------------------------------
if (dir.exists(saida)) stop('A pasta R23 ja existe; preserve a execucao anterior: ',saida)
dir.create(saida,recursive=TRUE,showWarnings=FALSE)
escrever <- function(x,nome) write.csv(x,file.path(saida,nome),row.names=FALSE,
                                       fileEncoding='UTF-8')
escrever(propinfo,'23_PROPRIEDADES_FOLDS_E_CONTAGENS.csv')
escrever(pares,'23_PARES_PROPRIEDADES.csv')
escrever(parupa,'23_PARES_UPAS.csv')
escrever(vizinhos,'23_VIZINHOS_MAIS_PROXIMOS.csv')
escrever(resumos,'23_CENARIOS_LIMIARES.csv')
escrever(clusters,'23_GRUPOS_POR_LIMIAR.csv')
escrever(alvo,'23_FOLDS_CRITICOS_E_VIZINHOS.csv')
escrever(data.frame(variavel=variaveis,dp_global_b2=unname(DP)),
         '23_ESCALAS_AMBIENTAIS.csv')
escrever(data.frame(propriedade=props,ambmed,check.names=FALSE),
         '23_MEDIANAS_PREDITORES_POR_PROPRIEDADE.csv')
escrever(data.frame(arquivo=c(arq19,manifesto_path,arq_pres,arq_bg),
           md5=vapply(c(arq19,manifesto_path,arq_pres,arq_bg),md5,character(1))),
         '23_MANIFESTO_FONTES.csv')

png(file.path(saida,'23_DISTANCIA_VIZINHO_OUTRO_FOLD.png'),width=1450,height=820,res=140)
op <- par(mar=c(5,15,4,2))
z <- vizinhos[order(vizinhos$dist_mais_proximo_outro_fold_km),]
barplot(z$dist_mais_proximo_outro_fold_km,names.arg=z$propriedade,
        horiz=TRUE,las=1,cex.names=.65,col='gray60',
        xlab='Distancia ate amostras/UPAs de outro fold (km)',
        main='R23 | proximidade entre folds - diagnostico')
par(op); dev.off()

if (all(is.finite(centro))) {
  png(file.path(saida,'23_MAPA_ESQUEMATICO_FOLDS.png'),width=1450,height=950,res=140)
  op <- par(mar=c(5,5,4,2))
  fc <- propfold$fold_cv[match(props,propfold$propriedade)]
  cores <- c('#4477AA','#CC8844','#228877')
  plot(centro[,1],centro[,2],col=cores[fc],pch=19,cex=1.2,
       xlab='Longitude',ylab='Latitude',main='R23 | centros amostrais / UPAs (nao e mapa de limites)')
  text(centro[,1],centro[,2],labels=props,pos=4,cex=.55,offset=.35)
  legend('bottomleft',legend=paste('Fold',1:3),col=cores,pch=19,bty='n')
  par(op); dev.off()
}

texto <- c('TCC IPES | R23 - DIAGNOSTICO ESPACIAL (SEM MODELAGEM)',
  paste('Codigo:',versao_r23),paste('Executado:',Sys.time()),
  '27 propriedades de desenvolvimento, 64 UPAs inventariadas.',
  'Presencas: 8680; Background B2: 10000; modelos ajustados: ZERO.',
  paste('Tipo de distancia:',tipo_distancia),
  paste('Coordenadas:',ifelse(is.na(fonte_coords),'nao usadas',fonte_coords)),
  paste('Poligonos:',ifelse(is.na(fonte_poligonos),'nao usados',fonte_poligonos)),
  'A minima entre pontos amostrados NAO e distancia exata de divisas.',
  'V1.1 corrige colisao pi/matriz de pares e garante matriz Haversine (autotestes 1x1 e 2x3).',
  'Quando usados poligonos, as geometrias sao UPAs inventariadas, nao imoveis inteiros.',
  '5/10/20/50 km sao cenarios exploratorios; agrupamentos nao foram aplicados.',
  'Amostragem espacial (pontos): deterministica, ate 80 por UPA.',
  'Distancia ambiental: euclidiana entre MEDIANAS de cinco preditores divididas pelo DP B2.',
  'Distancia textura: Hellinger das proporcoes de categorias; NAO codigos numericos.',
  'Distancias e correlacoes exploratorias nao estabelecem autocorrelacao efetiva.',
  'Os folds anteriores estao INTACTOS. Nenhuma exclusao de propriedade/UPA.',
  'As 7 propriedades de TESTE EXTERNO nao sao usadas na analise.',
  'NUNCA interpretar UPAs nao inventariadas como ausencia; nao foram carregadas.',
  'Proximo passo: conferir distancias com limites vetoriais completos antes de reduzir areas.',
  paste('Saida:',saida), '', 'CENARIOS DE PROXIMIDADE:',
  capture.output(print(resumos,row.names=FALSE)))
writeLines(texto,file.path(saida,'23_RELATORIO_DIAGNOSTICO.txt'),useBytes=TRUE)
writeLines(capture.output(sessionInfo()),file.path(saida,'23_SESSION_INFO.txt'),useBytes=TRUE)
cat('\nR23 concluido.\nPasta: ',saida,'\n',sep='')
cat('Pares de propriedades: ',nrow(pares),'; pares de UPAs: ',nrow(parupa),'\n',sep='')
cat('Tipo de distancia: ',tipo_distancia,'\n',sep='')
cat('Nenhuma propriedade foi removida, nenhum fold foi alterado.\n')
