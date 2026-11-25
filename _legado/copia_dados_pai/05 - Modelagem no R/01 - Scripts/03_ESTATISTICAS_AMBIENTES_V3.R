# TCC - R03 V3. Analise da disponibilidade AMBIENTAL no conjunto de desenvolvimento.
# A mesma amostra espacial do R02 serve como referencia para ambas as especies.
# Nao usa dados de TESTE, nao calcula p-valores sobre pixels dependentes.
for(p in c('ggplot2','terra')) if(!requireNamespace(p,quietly=TRUE))stop('Instale ',p)
cat('Selecione BACKGROUND_COMUM_DESENVOLVIMENTO.csv criado pelo R02 V3.\n')
arq<-normalizePath(file.choose(),winslash='/',mustWork=TRUE)
achar<-function(p){d<-dirname(p);repeat{
 if(dir.exists(file.path(d,'03 - Trabalho no QGIS')) && dir.exists(file.path(d,'06 - Resultados')))return(d)
 pp<-dirname(d);if(pp==d)stop('Raiz TCC nao encontrada');d<-pp}}
raiz<-achar(arq)
entrada<-file.path(raiz,'04 - Dados para o MaxEnt','03 - Background V3')
if(dirname(arq)!=normalizePath(entrada,winslash='/',mustWork=TRUE) ||
   basename(arq)!='BACKGROUND_COMUM_DESENVOLVIMENTO.csv')stop('Arquivo de background V3 incorreto')
saida<-file.path(raiz,'06 - Resultados','02 - Estatisticas dos ambientes - V3')
if(dir.exists(saida))stop('Resultados existentes preservados. Nao sobrescrever: ',saida)
bg<-read.csv(arq,fileEncoding='UTF-8',stringsAsFactors=FALSE,check.names=FALSE)
part<-read.csv2(file.path(entrada,'02_PARTICAO_APROVADA.csv'),fileEncoding='UTF-8',stringsAsFactors=FALSE)
if(nrow(bg)==0 || anyDuplicated(bg$id_background) ||
   anyDuplicated(paste(bg$propriedade,bg$celula_raster,sep='|')) ||
   any(bg$propriedade %in% part$propriedade[part$conjunto=='TESTE']))
  stop('Background duplicado ou vazamento de teste.')
vars<-c('altitude_m','declividade_graus','dist_rio_raster_m','bio12_mm_ano','bio17_mm_mes')
campos<-c('propriedade','upa_id','textura_subgrupo',vars)
if(!all(campos%in%names(bg)))stop('Campos ambientais ausentes')
for(v in c(vars,'textura_subgrupo')){
 bg[[v]]<-as.numeric(bg[[v]])
 if(any(!is.finite(bg[[v]])))stop('Valores nao finitos em ',v)
}
leg_file<-file.path(raiz,'02 - Fontes ambientais','MapBiomas Solo',
  'LEGENDA_MapBiomas_Solo_C3_Subgrupo_0_30cm.csv')
if(!file.exists(leg_file))stop('Falta legenda original de solo: ',leg_file)
leg<-read.csv2(leg_file,fileEncoding='UTF-8-BOM',stringsAsFactors=FALSE)
if(!all(c('codigo','classe')%in%names(leg)))stop('Legenda sem codigo/classe')
leg$codigo<-as.integer(leg$codigo)
if(!setequal(leg$codigo,1:9) || anyDuplicated(leg$codigo))stop('Legenda de solo invalida')
bg$textura_nome<-leg$classe[match(bg$textura_subgrupo,leg$codigo)]
if(anyNA(bg$textura_nome))stop('Classe textural nao encontrada na legenda')
resumir<-function(x){
 q<-quantile(x,c(.05,.25,.5,.75,.95),na.rm=TRUE)
 data.frame(n=length(x),media=mean(x),desvio_padrao=sd(x),minimo=min(x),
  p05=q[1],p25=q[2],mediana=q[3],p75=q[4],p95=q[5],maximo=max(x),
  valores_distintos_30m=length(unique(x)),row.names=NULL)
}
res<-do.call(rbind,lapply(vars,function(v)
 cbind(variavel=v,resumir(bg[[v]]))))
por_propriedade<-do.call(rbind,lapply(split(bg,bg$propriedade),function(x)
 do.call(rbind,lapply(vars,function(v){
  y<-resumir(x[[v]])
  data.frame(propriedade=x$propriedade[1],variavel=v,n=length(x[[v]]),
    media=y$media,dp=y$desvio_padrao,n_valores_distintos=y$valores_distintos_30m)
 }))))
por_upa<-do.call(rbind,lapply(split(bg,bg$upa_id),function(x)
 do.call(rbind,lapply(vars,function(v){
  y<-resumir(x[[v]])
  data.frame(propriedade=x$propriedade[1],upa_id=x$upa_id[1],
   variavel=v,n=length(x[[v]]),media=y$media,
   dp=y$desvio_padrao,n_valores_distintos=y$valores_distintos_30m)
 }))))
solo<-as.data.frame(table(bg$textura_subgrupo,bg$textura_nome),stringsAsFactors=FALSE)
names(solo)<-c('codigo','classe','n');solo<-solo[solo$n>0,,drop=FALSE]
solo$percentual<-100*solo$n/nrow(bg)
correl<-stats::cor(bg[,vars,drop=FALSE],method='pearson')
cor_long<-as.data.frame(as.table(correl),stringsAsFactors=FALSE)
names(cor_long)<-c('variavel_1','variavel_2','r')
# Fração APROXIMADA da variação de cada preditor associada a diferenças
# entre propriedades, estimada na amostra de background (nao inferencial).
particao_variancia<-do.call(rbind,lapply(vars,function(v){
 y<-bg[[v]];m<-mean(y);p<-split(y,bg$propriedade)
 media_prop<-vapply(p,mean,numeric(1));n_prop<-lengths(p)
 var_t<-mean((y-m)^2)
 var_e<-sum(n_prop*(media_prop-m)^2)/length(y)
 data.frame(variavel=v,n_propriedades=length(p),
     variancia_total=var_t,variancia_entre_prop=var_e,
     proporcao_entre_prop=if(var_t>0)var_e/var_t else NA_real_)
}))
# Resolucao CHELSA nativa ~1km: valores_distintos_30m nao significa
# celulas nativas independentes; reamostragem pode criar valores intermediarios.
dir.create(saida,recursive=TRUE)
save_csv<-function(x,n)write.csv(x,file.path(saida,n),row.names=FALSE,fileEncoding='UTF-8')
save_csv(res,'03_RESUMO_NUMERICO.csv');save_csv(por_propriedade,'03_POR_PROPRIEDADE.csv')
save_csv(por_upa,'03_POR_UPA.csv');save_csv(solo,'03_SOLO.csv')
save_csv(cor_long,'03_CORRELACOES.csv')
save_csv(particao_variancia,'03_VARIANCIA_ENTRE_PROPRIEDADES.csv')
# Conferencia da resolucao NATIVA da CHELSA, sem confundir os 30m alinhados
# com observacoes climaticas independentes. Conta celulas NATIVAS
# amostradas por UPA (isto e limite inferior do total de celulas na UPA).
fonte_chelsa<-file.path(raiz,'02 - Fontes ambientais','CHELSA',
 '1980-2021 - Feito com script 04')
clima_nativo<-c(bio12_mm_ano='BIO12_CHELSA_1980_2021.tif',
 bio17_mm_mes='BIO17_CHELSA_1980_2021.tif')
checagens<-list();faltando<-character()
if(!all(c('longitude','latitude')%in%names(bg)))stop('Background sem coordenadas geograficas')
for(v in names(clima_nativo)){
 caminho<-file.path(fonte_chelsa,clima_nativo[[v]])
 if(!file.exists(caminho)){
   faltando<-c(faltando,paste('Raster nativo NAO encontrado:',caminho));next
 }
 r<-terra::rast(caminho)
 p<-terra::vect(bg,geom=c('longitude','latitude'),crs='EPSG:4674')
 if(terra::crs(p)!=terra::crs(r))p<-terra::project(p,terra::crs(r))
 cel<-as.integer(terra::cellFromXY(r,terra::crds(p)))
 for(id in unique(bg$upa_id)){
  jj<-which(bg$upa_id==id);validas<-unique(cel[jj][!is.na(cel[jj])])
  checagens[[length(checagens)+1L]]<-data.frame(
    propriedade=bg$propriedade[jj[1]],upa_id=id,variavel=v,
    n_pontos_background=length(jj),n_celulas_climaticas_nativas_amostradas=length(validas),
    pontos_sem_celula_nativa=sum(is.na(cel[jj])),
    resolucao_raster_x=terra::res(r)[1],resolucao_raster_y=terra::res(r)[2],
    crs_raster=terra::crs(r,proj=TRUE))
 }
}
if(length(checagens))save_csv(do.call(rbind,checagens),'03_CELULAS_CHELSA_NATIVAS_POR_UPA.csv')
writeLines(c('QUANTIDADE DE CELULAS CLIMATICAS NATIVAS',
 'Contagem feita sobre os centros dos pontos de BG amostrados, NAO toda UPA.',
 'Nao basta contar valores distintos dos rasters REAMOSTRADOS a 30m.',
 if(length(faltando))faltando else 'Os arquivos nativos de BIO12 e BIO17 foram localizados.'),
 file.path(saida,'03_RESOLUCAO_CHELSA_NOTAS.txt'))

if(requireNamespace('writexl',quietly=TRUE))
 writexl::write_xlsx(list(Resumo=res,Por_propriedade=por_propriedade,
   Por_UPA=por_upa,Solo=solo,Correlacoes=cor_long,
   Variancia_entre_propriedades=particao_variancia),
   file.path(saida,'03_RESUMO_AMBIENTES.xlsx'))
rotulos<-c(altitude_m='Altitude (m)',declividade_graus='Declividade (graus)',
 dist_rio_raster_m='Distância aos rios (m)',bio12_mm_ano='BIO12 (mm/ano)',
 bio17_mm_mes='BIO17 (mm/mês)')
tema<-function()ggplot2::theme_minimal(base_size=12)+
 ggplot2::theme(plot.title=ggplot2::element_text(face='bold'),
  panel.grid.minor=ggplot2::element_blank(),strip.text=ggplot2::element_text(face='bold'))
for(v in vars){
 p<-ggplot2::ggplot(bg,ggplot2::aes(x=.data[[v]]))+
  ggplot2::geom_histogram(bins=35,fill='#457B87',colour='white',linewidth=.25)+
  ggplot2::labs(title=paste('Ambiente disponível:',rotulos[v]),x=rotulos[v],
    y='Pixels amostrados',caption='Somente UPAs de desenvolvimento | correlações não inferenciais')+tema()
 nome<-file.path(saida,paste0('03_',v))
 ggplot2::ggsave(paste0(nome,'.png'),p,width=9,height=5,dpi=300,bg='white')
 ggplot2::ggsave(paste0(nome,'.pdf'),p,width=9,height=5,bg='white')
}
solo$classe<-factor(solo$classe,levels=leg$classe[order(leg$codigo)])
ps<-ggplot2::ggplot(solo,ggplot2::aes(x=classe,y=percentual))+
 ggplot2::geom_col(fill='#6E8F73',width=.7)+ggplot2::coord_flip()+
 ggplot2::labs(title='Textura do solo no domínio de desenvolvimento',
  subtitle='MapBiomas Solo C3, 0–30 cm | amostra de pixels das UPAs',
  x=NULL,y='Percentual dos pontos de background (%)')+tema()
ggplot2::ggsave(file.path(saida,'03_SOLO.png'),ps,width=10,height=6,dpi=300,bg='white')
ggplot2::ggsave(file.path(saida,'03_SOLO.pdf'),ps,width=10,height=6,bg='white')
cor_long$variavel_1<-factor(cor_long$variavel_1,levels=vars)
cor_long$variavel_2<-factor(cor_long$variavel_2,levels=rev(vars))
pp<-ggplot2::ggplot(cor_long,ggplot2::aes(x=variavel_1,y=variavel_2,fill=r))+
 ggplot2::geom_tile(color='white')+
 ggplot2::geom_text(ggplot2::aes(label=round(r,2)),size=3.7)+
 ggplot2::scale_fill_gradient2(low='#4B83AB',mid='white',high='#C66B52',midpoint=0,limits=c(-1,1))+
 ggplot2::coord_equal()+
 ggplot2::labs(title='Correlação exploratória entre preditores',
   subtitle='Background comum das UPAs de desenvolvimento; dependência espacial não corrigida',
   x=NULL,y=NULL,fill='Pearson r')+tema()+
 ggplot2::theme(axis.text.x=ggplot2::element_text(angle=45,hjust=1))
ggplot2::ggsave(file.path(saida,'03_CORRELACOES.png'),pp,width=9,height=7,dpi=300,bg='white')
ggplot2::ggsave(file.path(saida,'03_CORRELACOES.pdf'),pp,width=9,height=7,bg='white')
writeLines(c('R 03 V3 — AMBIENTES DISPONIVEIS','Uma unica amostra ambiental comum as duas especies.',
 'So UPAs inventariadas de DESENVOLVIMENTO; testes reservados nao consultados.',
 'Variancia entre propriedades e descritiva, nao preferencia ecologica.',
 'CHELSA nativa aproximadamente 1 km; 30 m alinhados NAO sao independentes.',
 'Codigos de solo sao classes categoricas, nao numeros continuos.',
 paste('N pontos:',nrow(bg)),paste('R:',R.version.string)),
 file.path(saida,'03_NOTAS_METODOLOGICAS.txt'))
cat('R03 v3 CONCLUIDO:',saida,'\n')
