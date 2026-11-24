# =============================================================================
# TCC IPES - R24 ETAPA 2 - DISTANCIAS GEOMETRICAS REAIS ENTRE 64 UPAs
# NAO reduz propried., NAO altera folds, NAO executa MaxEnt ou teste externo.
# Usar limites de UPAs INVENTARIADAS, nunca imoveis completos ou buffers.
# Requer pacote sf; coordenadas tratadas em SIRGAS2000 geograficas (EPSG:4674)
# com projecao regional equidistante (unica) em metros para zonas UTM 21S e 22S.
# =============================================================================
VERSAO <- 'R24_02_GEOMETRIA_V1_1_20261117'
if (!requireNamespace('sf',quietly=TRUE)) stop('Instale sf: install.packages("sf")')
ler <- function(p) utils::read.csv(p,stringsAsFactors=FALSE,check.names=FALSE,fileEncoding='UTF-8-BOM')
exigir <- function(d,cols,n) { if (!all(cols %in% names(d))) stop('Faltam colunas em ',n,': ',paste(setdiff(cols,names(d)),collapse=', ')) }
cat('\nR24 ETAPA 2: selecione 23_PARES_UPAS.csv do R23 V1_1.\n')
f23 <- normalizePath(file.choose(),winslash='/',mustWork=TRUE)
if (basename(f23)!='23_PARES_UPAS.csv') stop('Selecione 23_PARES_UPAS.csv do R23.')
r23 <- ler(f23)
exigir(r23,c('upa_a','upa_b','propriedade_a','propriedade_b','fold_a','fold_b','dist_pontos_amostrais_min_km'),'R23')
ref <- unique(rbind(
 data.frame(upa_id=sub('^.*\\|\\|','',r23$upa_a),propriedade=r23$propriedade_a,fold_cv=as.integer(r23$fold_a)),
 data.frame(upa_id=sub('^.*\\|\\|','',r23$upa_b),propriedade=r23$propriedade_b,fold_cv=as.integer(r23$fold_b))))
chave <- function(d) paste(d$propriedade,d$upa_id,sep='||')
ref$key <- chave(ref)
if (nrow(r23)!=2016L || nrow(ref)!=64L || length(unique(ref$propriedade))!=27L ||
    anyDuplicated(ref$key) || !setequal(ref$fold_cv,1:3))
  stop('Referencia R23 invalida: 2016 pares, 64 UPAs, 27 propriedades e 3 folds esperados.')
normalizar <- function(x) toupper(gsub('[^A-Za-z0-9]','',iconv(as.character(x),to='ASCII//TRANSLIT',sub='')))
reservadas <- c('BARROBRANCO','CURUCA','GUARIUBA','JATOBA','LOTE01','MARILIA','PALMEIRA')
if (any(normalizar(ref$propriedade)%in%reservadas)) stop('Referencia contem propriedade do TESTE EXTERNO.')
pasta_resultados <- dirname(f23)
while (basename(pasta_resultados)!='06 - Resultados' && dirname(pasta_resultados)!=pasta_resultados)
 pasta_resultados <- dirname(pasta_resultados)
if (basename(pasta_resultados)!='06 - Resultados') stop('Pasta 06 - Resultados nao encontrada.')
saida <- file.path(pasta_resultados,'22 - Geometria das UPAs R24 V1_1')
if (!dir.exists(saida)) dir.create(saida,recursive=TRUE)
if (file.exists(file.path(saida,'24_PARES_UPAS_GEOMETRICOS.csv')))
 stop('R24 ja calculado. Preserve o resultado: ',saida)
cat('\nModo: 1 = GPKG/SHP consolidado, com campos propriedade e upa_id.\n',
    '      2 = Mapeamento revisado da ETAPA 1.\n',sep='')
modo <- trimws(readline('Digite 1 ou 2 e ENTER: '))
if (!(modo %in% c('1','2'))) stop('Modo invalido. Nenhuma fonte modificada.')
# Todas as operacoes topologicas sao planas, em uma unica projecao local em metros.
# Nunca chamamos S2 nos poligonos geograficos; isso evita o erro wk_handle:
# 'Loop 0 is not valid: Edge ... has duplicate vertex ...'.
# A projecao azimutal equidistante esta centrada no dominio regional das 27 propriedades.
# Pequenas diferencas em relacao a distancias geodesicas sao esperadas, auditadas
# por comparacao independente e nao alteram as classificacoes 5/10/20/50 km.
crs_metrico <- '+proj=aeqd +lat_0=-3 +lon_0=-54 +datum=WGS84 +units=m +no_defs +type=crs'
if (is.na(sf::st_crs(crs_metrico))) stop('Falha ao reconhecer SRC de medida regional.')
# Validacao de cada geometria sem alterar os arquivos de origem.
obter_geom <- function(x, identificacao) {
 if (is.na(sf::st_crs(x))) stop('SRC ausente: ',identificacao,'. Nao atribuir SRC por tentativa.')
 tip <- as.character(sf::st_geometry_type(x))
 if (any(!tip %in% c('POLYGON','MULTIPOLYGON','GEOMETRYCOLLECTION')))
  stop('Geometria nao poligonal: ',identificacao)
 if (any(sf::st_is_empty(x))) stop('Geometria vazia em ',identificacao)
 # Crucial: transformar ANTES de validar, reparar ou unir.
 # sf utiliza GEOS para topologia plana no SRC projetado.
 x <- sf::st_transform(x, crs_metrico)
 valido_original <- all(sf::st_is_valid(x))
 antes <- sum(as.numeric(sf::st_area(x)))
 if (!valido_original) {
   x <- sf::st_make_valid(x)
   # Em caso de GEOMETRYCOLLECTION, manter apenas as partes poligonais.
   if (any(as.character(sf::st_geometry_type(x))=='GEOMETRYCOLLECTION')) {
      x <- suppressWarnings(sf::st_collection_extract(x, 'POLYGON'))
   }
 }
 if (!all(sf::st_is_valid(x))) stop('Geometria continua invalida apos reparo em: ',identificacao)
 # Uniao em plano metrico: evita o processamento S2 de vertices e anéis.
 g <- suppressWarnings(sf::st_union(sf::st_geometry(x)))
 if (as.character(sf::st_geometry_type(g))[1]=='GEOMETRYCOLLECTION')
  g <- sf::st_collection_extract(g,'POLYGON')
 if (length(g)!=1L || sf::st_is_empty(g)) stop('Uniao poligonal vazia: ',identificacao)
 tipo <- as.character(sf::st_geometry_type(g))[1]
 if (!tipo %in% c('POLYGON','MULTIPOLYGON')) stop('Uniao nao e poligono: ',identificacao)
 if (!all(sf::st_is_valid(g))) stop('A uniao produziu poligono invalido: ',identificacao)
 depois <- as.numeric(sf::st_area(g))
 # Sem correcoes silenciosas significativas de area, inclusive em geometrias reparadas.
 delta <- abs(depois-antes)
 if (delta > max(1, antes*0.001))
  stop('Alteracao de area >0.1% na uniao/reparo de ',identificacao,
       ': delta=',round(delta,2),' m2. Inspecione os limites antes de prosseguir.')
 list(geom=g[[1]], n_partes_entrada=nrow(x), valido_original=valido_original,
      houve_reparo=!valido_original, delta_area_m2=delta)
}
geom <- vector('list',nrow(ref)); qa <- vector('list',nrow(ref))
fontes <- list(); nfontes <- 0L
if (modo=='1') {
 cat('Escolha a camada vetorial consolidada das UPAs de desenvolvimento.\n')
 f <- normalizePath(file.choose(),winslash='/',mustWork=TRUE)
 if (!grepl('\\.(gpkg|shp)$',f,ignore.case=TRUE)) stop('Escolha arquivo .gpkg ou .shp.')
 camadas <- sf::st_layers(f)
 opcoes <- which(grepl('POLYGON',toupper(camadas$geomtype)))
 if (!length(opcoes)) stop('Nenhuma camada poligonal encontrada.')
 if (length(opcoes)==1L) camada <- camadas$name[opcoes]
 else {
   cat(paste(seq_along(opcoes),camadas$name[opcoes],sep=' : '),sep='\n');cat('\n')
   i <- suppressWarnings(as.integer(readline('Digite o numero da camada: ')))
   if (length(i)!=1L || is.na(i) || !i %in% seq_along(opcoes)) stop('Camada invalida.')
   camada <- camadas$name[opcoes[i]]
 }
 u <- sf::st_read(f,layer=camada,quiet=TRUE)
 exigir(u,c('propriedade','upa_id'),'camada consolidada')
 if (is.na(sf::st_crs(u))) stop('SRC ausente na camada consolidada.')
 u$key <- chave(u)
 # NAO utilizar quaisquer feicoes alem das 64 UPAs referenciadas no R23.
 u <- u[u$key %in% ref$key,,drop=FALSE]
 if (!setequal(u$key,ref$key))
  stop('A camada consolidada nao cobre EXATAMENTE as 64 UPAs do R23.\nAusentes: ',
       paste(setdiff(ref$key,unique(u$key)),collapse='; '))
 for (i in seq_len(nrow(ref))) {
   z <- u[u$key==ref$key[i],,drop=FALSE]
   info <- obter_geom(z,ref$key[i]); geom[[i]] <- info$geom
   qa[[i]] <- data.frame(ref[i,c('propriedade','upa_id','fold_cv')],
     n_feicoes_fonte=info$n_partes_entrada,original_valido=info$valido_original,
     houve_reparo=info$houve_reparo,delta_area_m2=info$delta_area_m2,fonte=f,camada=camada,stringsAsFactors=FALSE)
 }
 nfontes <- 1L; fontes[[1]] <- f
} else {
 cat('Escolha 24_MAPEAMENTO_UPAS_REVISAR.csv com 64 linhas aprovadas.\n')
 mapa_path <- normalizePath(file.choose(),winslash='/',mustWork=TRUE)
 mapa <- ler(mapa_path)
 exigir(mapa,c('propriedade','upa_id','fold_cv','arquivo','camada','filtro_campo','filtro_valor','APROVADO'),'mapeamento')
 mapa$key <- chave(mapa)
 if (nrow(mapa)!=64L || anyDuplicated(mapa$key) || !setequal(mapa$key,ref$key))
  stop('Mapeamento nao corresponde exatamente as 64 UPAs de desenvolvimento.')
 mapa <- mapa[match(ref$key,mapa$key),,drop=FALSE]
 if (any(toupper(trimws(as.character(mapa$APROVADO)))!='SIM'))
  stop('Reveja os caminhos/camadas e coloque APROVADO=SIM nas 64 linhas.')
 if (any(!file.exists(mapa$arquivo)) || any(!nzchar(mapa$camada)))
  stop('Existe caminho ou camada vazia/inexistente no mapeamento.')
 # Usar o mesmo arquivo/camada em UPAs diferentes requer filtro explicito.
 fontekey <- paste(mapa$arquivo,mapa$camada,sep='||')
 multi <- duplicated(fontekey) | duplicated(fontekey,fromLast=TRUE)
 if (any(multi & (!nzchar(mapa$filtro_campo) | !nzchar(mapa$filtro_valor))))
  stop('Fonte poligonal compartilhada por varias UPAs sem campo/valor de filtro.')
 for (i in seq_len(nrow(ref))) {
   f <- normalizePath(mapa$arquivo[i],winslash='/',mustWork=TRUE)
   z <- sf::st_read(f,layer=mapa$camada[i],quiet=TRUE)
   if (nzchar(mapa$filtro_campo[i])) {
     campo <- as.character(mapa$filtro_campo[i]); valor <- as.character(mapa$filtro_valor[i])
     if (!campo %in% names(z)) stop('Campo de filtro inexistente: ',campo,' em ',f)
     z <- z[!is.na(z[[campo]]) & as.character(z[[campo]])==valor,,drop=FALSE]
   }
   if (!nrow(z)) stop('UPA sem feicao apos filtro: ',ref$key[i])
   info <- obter_geom(z,ref$key[i]); geom[[i]] <- info$geom
   qa[[i]] <- data.frame(ref[i,c('propriedade','upa_id','fold_cv')],
     n_feicoes_fonte=info$n_partes_entrada,original_valido=info$valido_original,
     houve_reparo=info$houve_reparo,delta_area_m2=info$delta_area_m2,fonte=f,camada=as.character(mapa$camada[i]),
     stringsAsFactors=FALSE)
   nfontes <- nfontes+1L; fontes[[nfontes]] <- f
   if (i%%10==0 || i==64) cat('UPAs lidas: ',i,'/64\n',sep='')
 }
}
# A malha resultante esta em coordenadas METRICAS regionais (nao lonlat).
upas <- sf::st_sf(ref[,c('propriedade','upa_id','fold_cv')],
  geometry=do.call(sf::st_sfc,c(geom,list(crs=sf::st_crs(crs_metrico)))))
if (nrow(upas)!=64L || any(sf::st_is_empty(upas)) || !all(sf::st_is_valid(upas)))
 stop('A malha final das 64 UPAs nao passou na validacao geometrica.')
# Ponto interno calculado no SRC plano. Converter SOMENTE o ponto para lonlat.
centros_m <- sf::st_point_on_surface(upas)
centros <- sf::st_coordinates(sf::st_transform(centros_m, 4674))
if (nrow(centros)!=64L || any(!is.finite(centros)) ||
    any(centros[,1] < -65 | centros[,1] > -45 |
        centros[,2] < -13 | centros[,2] > 5))
 stop('Coordenadas das UPAs fora da regiao esperada: confira SRC.')
qa <- do.call(rbind,qa)
qa$area_km2 <- as.numeric(sf::st_area(upas))/1e6
qa$longitude_ponto_interno <- centros[,1];qa$latitude_ponto_interno <- centros[,2]
if (any(!is.finite(qa$area_km2) | qa$area_km2<=0)) stop('Area nula ou invalida.')
# Calcular distancias entre contornos no MESMO SRC regional metrico.
mat <- matrix(as.numeric(sf::st_distance(upas)),nrow=64L,ncol=64L)
if (any(!is.finite(mat)) || max(abs(mat-t(mat)))>1) stop('Matriz de distancias assimetrica/invalida.')
chaves <- ref$key
idx <- which(upper.tri(mat),arr.ind=TRUE)
paresupa <- data.frame(upa_a=chaves[idx[,1]],upa_b=chaves[idx[,2]],
  propriedade_a=ref$propriedade[idx[,1]],propriedade_b=ref$propriedade[idx[,2]],
  fold_a=ref$fold_cv[idx[,1]],fold_b=ref$fold_cv[idx[,2]],
  folds_diferentes=ref$fold_cv[idx[,1]]!=ref$fold_cv[idx[,2]],
  distancia_limites_m=mat[idx],distancia_limites_km=mat[idx]/1000,
  stringsAsFactors=FALSE)
# O R23 media distancia entre pontos B2; nao entre limites.
ord_key <- function(a,b) paste(pmin(a,b),pmax(a,b),sep='##')
pkey <- ord_key(paresupa$upa_a,paresupa$upa_b)
rkey <- ord_key(r23$upa_a,r23$upa_b)
if (anyDuplicated(pkey)||anyDuplicated(rkey)||!setequal(pkey,rkey))
 stop('Pares das 64 UPAs divergem do R23: nenhuma saida gravada.')
paresupa$dist_amostral_R23_km <- as.numeric(r23$dist_pontos_amostrais_min_km[match(pkey,rkey)])
paresupa$diferenca_amostral_menos_limites_km <- paresupa$dist_amostral_R23_km - paresupa$distancia_limites_km
paresupa$alerta_limite_maior_que_amostra <- paresupa$diferenca_amostral_menos_limites_km < -0.05
# Intersecao real entre poligonos: diagnosticar sobreposicao versus simples contato.
paresupa$area_intersecao_m2 <- 0
paresupa$contato_ou_sobreposicao <- paresupa$distancia_limites_m<0.5
zero <- which(paresupa$contato_ou_sobreposicao)
if (length(zero)) for (z in zero) {
 i <- idx[z,1];j <- idx[z,2]
 inter <- tryCatch(suppressWarnings(sf::st_intersection(sf::st_geometry(upas[i,]),
                                             sf::st_geometry(upas[j,]))),error=function(e) NULL)
 if (is.null(inter)) {paresupa$area_intersecao_m2[z] <- NA_real_;next}
 paresupa$area_intersecao_m2[z] <- if (!length(inter) || all(sf::st_is_empty(inter))) 0 else sum(as.numeric(sf::st_area(inter)))
}
paresupa$sobreposicao_area_real <- is.finite(paresupa$area_intersecao_m2) & paresupa$area_intersecao_m2>1
# Agregar UPAs da mesma propriedade SEM criar geometria do imovel inteiro.
props <- sort(unique(ref$propriedade))
geom_prop <- lapply(props,function(p) sf::st_union(sf::st_geometry(upas[ref$propriedade==p,]))[[1]])
prop_sf <- sf::st_sf(propriedade=props,geometry=do.call(sf::st_sfc,c(geom_prop,list(crs=sf::st_crs(crs_metrico)))))
fold_prop <- vapply(props,function(p) unique(ref$fold_cv[ref$propriedade==p]),integer(1))
D <- matrix(as.numeric(sf::st_distance(prop_sf)),nrow=length(props))
indp <- which(upper.tri(D),arr.ind=TRUE)
paresprop <- data.frame(propriedade_a=props[indp[,1]],propriedade_b=props[indp[,2]],
  fold_a=fold_prop[indp[,1]],fold_b=fold_prop[indp[,2]],
  folds_diferentes=fold_prop[indp[,1]]!=fold_prop[indp[,2]],
  distancia_limites_upas_m=D[indp],distancia_limites_upas_km=D[indp]/1000,
  stringsAsFactors=FALSE)
# Validar propriedade usando minimo de distancias entre UPAs sem unir limites por inventario.
for (j in seq_len(nrow(paresprop))) {
 z <- paresupa[((paresupa$propriedade_a==paresprop$propriedade_a[j] & paresupa$propriedade_b==paresprop$propriedade_b[j]) |
                (paresupa$propriedade_b==paresprop$propriedade_a[j] & paresupa$propriedade_a==paresprop$propriedade_b[j])),]
 if (!nrow(z) || abs(min(z$distancia_limites_km)-paresprop$distancia_limites_upas_km[j])>0.001)
  stop('Inconsistencia entre agregacao por propriedade e menor distancia entre UPAs: ',j)
}
# Referencia amostral anterior por propriedade, para comparar medidas (nao sobrescrever).
arq_prop_r23 <- file.path(dirname(f23),'23_PARES_PROPRIEDADES.csv')
if (file.exists(arq_prop_r23)) {
 rp <- ler(arq_prop_r23)
 exigir(rp,c('propriedade_a','propriedade_b','dist_pontos_amostrais_min_km'),'pares propriedades R23')
 kp <- ord_key(paresprop$propriedade_a,paresprop$propriedade_b)
 kr <- ord_key(rp$propriedade_a,rp$propriedade_b)
 if (anyDuplicated(kr)||!setequal(kp,kr)) stop('Pares de propriedades R23 divergentes.')
 paresprop$dist_amostral_R23_km <- rp$dist_pontos_amostrais_min_km[match(kp,kr)]
 paresprop$diferenca_amostral_menos_limites_km <- paresprop$dist_amostral_R23_km-paresprop$distancia_limites_upas_km
 paresprop$alerta_limite_maior_que_amostra <- paresprop$diferenca_amostral_menos_limites_km < -0.05
}
# Vizinho de treino em outros folds, por propriedade; NAO muda a atribuicao.
vizinhos <- do.call(rbind,lapply(seq_along(props),function(i) {
 z <- paresprop[paresprop$propriedade_a==props[i] | paresprop$propriedade_b==props[i],,drop=FALSE]
 z$vizinho <- ifelse(z$propriedade_a==props[i],z$propriedade_b,z$propriedade_a)
 z <- z[order(z$distancia_limites_upas_km),,drop=FALSE]
 dif <- z[z$folds_diferentes,,drop=FALSE]
 data.frame(propriedade=props[i],fold_cv=fold_prop[i],
   vizinho_mais_proximo=z$vizinho[1],distancia_km=z$distancia_limites_upas_km[1],
   vizinho_outro_fold=if(nrow(dif))dif$vizinho[1] else NA_character_,
   distancia_outro_fold_km=if(nrow(dif))dif$distancia_limites_upas_km[1] else NA_real_)
}))
# Componentes conectados por limiar: o limiar nao e distancia maxima do grupo.
componentes <- function(n,arestas) {
 pai <- seq_len(n)
 raiz <- function(a) {while(pai[a]!=a) a <- pai[a];a}
 if(nrow(arestas))for (j in seq_len(nrow(arestas))) {
  a <- raiz(arestas[j,1]);b <- raiz(arestas[j,2]);if (a!=b)pai[b] <- a
 }
 roots <- vapply(seq_len(n),raiz,integer(1));match(roots,unique(roots))
}
cen <- list(); grupos <- list()
for (lim in c(5,10,20,50)) {
 liga <- indp[paresprop$distancia_limites_upas_km <= lim,,drop=FALSE]
 comp <- componentes(length(props),liga)
 v <- data.frame(limiar_km=lim,propriedade=props,fold_cv=fold_prop,grupo=comp)
 grupos[[as.character(lim)]] <- v
 conte <- table(comp)
 mult <- sum(vapply(split(v$fold_cv,v$grupo),function(q) length(unique(q))>1,logical(1)))
 cen[[as.character(lim)]] <- data.frame(limiar_km=lim,
  n_pares_propriedades_ate_limiar=sum(paresprop$distancia_limites_upas_km<=lim),
  n_pares_entre_folds_ate_limiar=sum(paresprop$folds_diferentes & paresprop$distancia_limites_upas_km<=lim),
  n_pares_upas_entre_folds_ate_limiar=sum(paresupa$folds_diferentes & paresupa$distancia_limites_km<=lim),
  n_grupos=length(conte),n_grupos_multifold=mult)
}
cen <- do.call(rbind,cen);grupos <- do.call(rbind,grupos)
# Gravar SOMENTE nesta pasta derivada. Checkpoints, fontes e arquivos originais intocados.
grava <- function(d,n) utils::write.csv(d,file.path(saida,n),row.names=FALSE,fileEncoding='UTF-8')
grava(qa,'24_QA_64_UPAS.csv')
grava(paresupa,'24_PARES_UPAS_GEOMETRICOS.csv')
grava(paresprop,'24_PARES_PROPRIEDADES_GEOMETRICOS.csv')
grava(vizinhos,'24_VIZINHOS_OUTRO_FOLD.csv')
grava(cen,'24_CENARIOS_LIMIARES_GEOMETRICOS.csv')
grava(grupos,'24_GRUPOS_POR_LIMIAR_GEOMETRICOS.csv')
sourcepaths <- unique(unlist(fontes));sourcepaths <- sourcepaths[file.exists(sourcepaths)]
manifesto <- data.frame(arquivo=c(f23,sourcepaths),md5=unname(tools::md5sum(c(f23,sourcepaths))),stringsAsFactors=FALSE)
grava(manifesto,'24_MANIFESTO_FONTES.csv')
sf::st_write(sf::st_transform(upas,4674),file.path(saida,'24_UPAS_DESENVOLVIMENTO_CONFERIDAS.gpkg'),
             layer='UPAS_64',quiet=TRUE,delete_dsn=FALSE)
png(file.path(saida,'24_MAPA_UPAS_POR_FOLD.png'),width=1400,height=950,res=130)
tryCatch({
  graphics::par(mar=c(4,4,4,2))
  graphics::plot(sf::st_geometry(upas),col=c('#4F81BD','#E59A51','#479B83')[upas$fold_cv],
    border='gray45',lwd=0.6,main='R24 - UPAs inventariadas por fold (apenas desenvolvimento)')
  graphics::legend('bottomleft',legend=paste('Fold',1:3),fill=c('#4F81BD','#E59A51','#479B83'),bty='n')
},finally=dev.off())
writeLines(c(
 paste('R24 - AUDITORIA GEOMETRICA |',VERSAO),
 paste('Data:',Sys.time()),
 'Somente 27 propriedades e 64 UPAs inventariadas do desenvolvimento.',
 'Distancias entre contornos das UPAs no plano metrico regional (+proj=aeqd, centro -3/-54).',
 'As distancias sao aproximacoes metricas com distorcao regional controlada, nao geodesicas S2.',
 'Geometrias transformadas temporariamente; o GPKG de saida e exportado em SIRGAS2000 EPSG:4674.',
 'Distancia por propriedade: uniao das suas UPAs inventariadas, NAO limite total do imovel.',
 'A verificacao do ambiente de teste externo NAO foi utilizada para calculos.',
 paste('UPAs:',nrow(upas),'pares UPAs:',nrow(paresupa),'pares propriedades:',nrow(paresprop)),
 paste('Geometrias com reparo em memoria:',sum(qa$houve_reparo)),
 paste('Pares UPAs com area de sobreposicao > 1 m2:',sum(paresupa$sobreposicao_area_real)),
 paste('Alertas: distancia poligonal > distancia R23 amostral + 50m:',sum(paresupa$alerta_limite_maior_que_amostra)),
 'Quando geometrias se encostam, a distancia e 0 m.',
 'Limiares 5/10/20/50 km sao exploratorios; o script NAO alterou folds nem excluiu UPAs.',
 'Grupos conexos podem apresentar distancias internas superiores ao limiar por encadeamento.',
 'Proximidade nao prova autocorrelacao espacial; validar agrupamento antes de comparar modelos.',
 '7 propriedades externas de teste e modelos MaxEnt permanecem reservados/intocados.',
 'Proximo passo: AUDITAR resultados R24; somente depois considerar bloco espacial alternativo.'
),file.path(saida,'24_RELATORIO_GEOMETRICO.txt'),useBytes=TRUE)
cat('\nR24 CONCLUIDO.\nResultados: ',saida,'\n',sep='')
cat('Envie os CSVs, 24_RELATORIO_GEOMETRICO.txt e o mapa PNG para auditoria.\n')
