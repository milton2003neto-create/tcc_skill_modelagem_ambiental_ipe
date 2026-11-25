# ================================================================
# TCC IPES - R26 V1.1 - ELEGIBILIDADE DE UPAS PARA VALIDACAO
# Base R. NAO roda MaxEnt, NAO altera folds e NAO modifica entradas.
# Cada UPA inventariada aparece em duas linhas (uma por especie).
# Protocolo: R26 a R30 - validacao por UPAs / escala espacial.
# ================================================================

inicio <- Sys.time()
localizar_script <- function() {
  arqs <- lapply(sys.frames(), function(f) f$ofile)
  arqs <- Filter(function(x) !is.null(x) && length(x) == 1L && nzchar(x), arqs)
  if (length(arqs)) return(dirname(normalizePath(arqs[[length(arqs)]], winslash='/', mustWork=TRUE)))
  return(getwd())
}
pasta_script <- localizar_script()
pasta_entrada <- file.path(pasta_script, '01_ENTRADAS_COPIAS')
n_pres <- '05_PRESENCAS_UM_POR_PIXEL_30M.csv'
n_bg   <- '18_BACKGROUND_B2_10000_COM_FOLDS.csv'
n_qa   <- '24_QA_64_UPAS.csv'
n_dist <- '24_PARES_UPAS_GEOMETRICOS.csv'
if (!file.exists(file.path(pasta_entrada, n_pres))) {
  cat('Selecione a COPIA do arquivo ', n_pres, ' na pasta 01_ENTRADAS_COPIAS.\n', sep='')
  pasta_entrada <- dirname(file.choose())
}
arquivos <- file.path(pasta_entrada, c(n_pres,n_bg,n_qa,n_dist))
if (!all(file.exists(arquivos))) stop('Faltam arquivos de entrada na mesma pasta: ', paste(basename(arquivos)[!file.exists(arquivos)],collapse=', '))

# MD5 fixado na geracao do pacote; interrompe para evitar versoes trocadas.
md5_esperado <- c(
  '05_PRESENCAS_UM_POR_PIXEL_30M.csv' = 'bff06ba0a3e5e541055dcfd93c2bdb2b',
  '18_BACKGROUND_B2_10000_COM_FOLDS.csv' = 'b6d249987029182e3109654fa866d626',
  '24_QA_64_UPAS.csv' = '4fed9a083960fbf4cc39481d519445bd',
  '24_PARES_UPAS_GEOMETRICOS.csv' = 'd31304b73ae3e4424d9b2fbe5806ba26'
)
md5_encontrado <- unname(tools::md5sum(arquivos))
if (!identical(unname(md5_encontrado), unname(md5_esperado))) {
  diverg <- basename(arquivos)[md5_encontrado != unname(md5_esperado)]
  stop('Arquivos nao correspondem as fontes do R26 previamente auditadas: ', paste(diverg,collapse=', '),'. Nenhum resultado novo gravado.')
}
ler <- function(nome) utils::read.csv(file.path(pasta_entrada,nome), fileEncoding='UTF-8', stringsAsFactors=FALSE, check.names=FALSE)
A<-ler(n_pres); B<-ler(n_bg); Q<-ler(n_qa); D<-ler(n_dist)
exigir_colunas <- function(d, nomes, rotulo) {aus<-setdiff(nomes,names(d));if(length(aus))stop('Colunas ausentes em ',rotulo,': ',paste(aus,collapse=', '))}
exigir_colunas(A,c('propriedade','upa_id','fold_cv','especie'),'presencas')
exigir_colunas(B,c('propriedade','upa_id','fold_cv'),'background')
exigir_colunas(Q,c('propriedade','upa_id','fold_cv','area_km2','longitude_ponto_interno','latitude_ponto_interno'),'QA')
exigir_colunas(D,c('upa_a','upa_b','distancia_limites_km'),'distancias')
if(nrow(A)!=8680 || nrow(B)!=10000 || nrow(Q)!=64 || nrow(D)!=2016)stop('Contagens de entradas inesperadas. Nenhum resultado gerado.')
if(length(unique(Q$upa_id))!=64 || length(unique(Q$propriedade))!=27)stop('Identificacao das UPAs/propriedades nao confere.')
if(!identical(sort(unique(A$upa_id)),sort(Q$upa_id)) || !identical(sort(unique(B$upa_id)),sort(Q$upa_id)))stop('Chaves UPAs R05/R18/R24 nao conferem.')
folds <- stats::setNames(as.integer(Q$fold_cv),Q$upa_id)
props <- stats::setNames(Q$propriedade,Q$upa_id)
if(any(A$fold_cv!=folds[A$upa_id])||any(B$fold_cv!=folds[B$upa_id])||any(Q$propriedade!=props[Q$upa_id])||any(A$propriedade!=props[A$upa_id])||any(B$propriedade!=props[B$upa_id])) stop('Divergencia fold ou propriedade entre fontes.')
if(!identical(sort(unique(A$especie)),sort(c('Ipe-roxo','Ipe-amarelo'))))stop('Especies inesperadas.')

# Distancias de LIMITES R24 (projecao metrico regional), nao de centros amostrais.
limpar_chave <- function(s) vapply(strsplit(as.character(s),'||',fixed=TRUE),function(x) tail(x,1),character(1))
D$a <- limpar_chave(D$upa_a); D$b <- limpar_chave(D$upa_b)
if(!identical(sort(unique(c(D$a,D$b))),sort(Q$upa_id)))stop('Chaves do R24 nao coincidem com as UPAs.')
dist_entre <- function(upa,outras){
 if (!length(outras))return(NA_real_)
 mask <- (D$a==upa & D$b %in% outras)|(D$b==upa & D$a %in% outras)
 if(!any(mask))stop('Par geometrico ausente para: ',upa)
 min(as.numeric(D$distancia_limites_km[mask]))
}

# Matriz das 64 UPAs
M <- Q[order(Q$propriedade,Q$upa_id), c('propriedade','upa_id','fold_cv','area_km2','longitude_ponto_interno','latitude_ponto_interno')]
row.names(M)<-NULL
names(M)[names(M)=='area_km2']<-'area_upa_km2'
n_bg <- table(B$upa_id)
M$n_bg_b2 <- as.integer(n_bg[M$upa_id])
for (e in c('Ipe-roxo','Ipe-amarelo')) {
 nm <- if(e=='Ipe-roxo')'n_roxo' else 'n_amarelo'
 tab <- table(A$upa_id[A$especie==e])
 v <- as.integer(tab[M$upa_id]);v[is.na(v)]<-0L;M[[nm]]<-v
}
M$n_ambas_especies <- as.integer(M$n_roxo>0 & M$n_amarelo>0)
M$n_outra_especie <- as.integer(M$n_roxo>0 | M$n_amarelo>0)
M$upas_na_propriedade <- as.integer(table(M$propriedade)[M$propriedade])
if(sum(M$n_bg_b2)!=10000L||sum(M$n_roxo)!=3248L||sum(M$n_amarelo)!=5432L||sum(M$n_ambas_especies)!=1L)stop('Totais de UPAs nao conferem.')

T <- list();k <- 0L
for (i in seq_len(nrow(M))) for (esp in c('Ipe-roxo','Ipe-amarelo')) {
 r <- M[i,,drop=FALSE];nome <- if(esp=='Ipe-roxo')'n_roxo' else 'n_amarelo'
 local <- M[M$propriedade==r$propriedade,,drop=FALSE]
 outras <- local[local$upa_id!=r$upa_id,,drop=FALSE]
 n <- as.integer(r[[nome]]);nr <- as.integer(sum(outras[[nome]]));nbr<-as.integer(sum(outras$n_bg_b2))
 irma_com_presenca <- outras$upa_id[outras[[nome]]>0]
 # Distancias calculadas no R24 entre os LIMITES das UPAs.
 # NA quando nao houver outra UPA na mesma propriedade (ou com a especie).
 dist_all <- dist_entre(as.character(r$upa_id), as.character(outras$upa_id))
 dist_sp  <- dist_entre(as.character(r$upa_id), as.character(irma_com_presenca))
 if (length(dist_all) != 1L || length(dist_sp) != 1L) {
   stop('R26: distancia nao escalar para ', r$upa_id, ' / ', esp)
 }
 candidata <- n>=30 && r$n_bg_b2>=30 && nr>=30 && nbr>=30
 situacao <- if(n==0) 'SEM_REGISTRO_NESTA_UPA_INVENTARIADA' else
   if(n<30)'MENOS_30_PRESENCAS_VAL_NA_UPA' else
   if(nrow(outras)==0)'PROPRIEDADE_COM_UMA_UPA' else
   if(nr<30)'OUTRAS_UPAS_MENOS_30_PRESENCAS_TREINO' else
   if(nbr<30)'OUTRAS_UPAS_MENOS_30_BACKGROUND_TREINO' else
   'CANDIDATA_RESERVA_UPA_INDIVIDUAL'
 k<-k+1L
 T[[k]] <- data.frame(propriedade=r$propriedade,upa_id=r$upa_id,fold_original=r$fold_cv,especie=esp,
   n_presencas_upa=n,n_bg_upa=r$n_bg_b2,n_outras_upas=nrow(outras),
   n_presencas_outras_upas_prop=nr,n_bg_outras_upas_prop=nbr,
   n_upas_com_presenca_na_prop=sum(local[[nome]]>0),
   n_upas_com_30_presencas_na_prop=sum(local[[nome]]>=30),
   dist_outra_upa_prop_mais_proxima_km=dist_all,
   dist_outra_upa_com_especie_km=dist_sp,
   contato_ou_sobreposicao_upa_mesma_especie=as.integer(!is.na(dist_sp) && dist_sp==0),
   candidata_reserva_upa=as.integer(candidata),situacao=situacao,area_upa_km2=r$area_upa_km2)
}
T <- do.call(rbind,T);row.names(T)<-NULL
C <- T[T$candidata_reserva_upa==1L,,drop=FALSE]
C$desenho <- 'VALIDACAO_UMA_UPA_TREINAR_OUTRAS_UPAS_MESMA_PROPRIEDADE'
C$observacao <- 'DIAGNOSTICO; nao e divisao aprovada; confirmar separacao e independencia no R27'

# Totais por especie x propriedade
R<-list(); l<-0L
for(esp in c('Ipe-roxo','Ipe-amarelo'))for(prop in sort(unique(M$propriedade))){
 z<-T[T$propriedade==prop & T$especie==esp,,drop=FALSE]
 l<-l+1L;R[[l]]<-data.frame(propriedade=prop,especie=esp,n_upas=nrow(z),
  n_upas_com_presenca=sum(z$n_presencas_upa>0),n_upas_com30=sum(z$n_presencas_upa>=30),
  n_p=sum(z$n_presencas_upa),n_bg=sum(z$n_bg_upa),n_candidatas=sum(z$candidata_reserva_upa))
}
Prop<-do.call(rbind,R);row.names(Prop)<-NULL
S<-list();F<-list()
for(esp in c('Ipe-roxo','Ipe-amarelo')){
 z<-T[T$especie==esp,,drop=FALSE];p<-Prop[Prop$especie==esp,,drop=FALSE]
 S[[esp]]<-data.frame(especie=esp,n_presencas=sum(z$n_presencas_upa),n_upas_inventariadas=nrow(z),
 n_upas_com_presenca=sum(z$n_presencas_upa>0),n_upas_com_30mais=sum(z$n_presencas_upa>=30),
 n_propriedades_com_presenca=sum(p$n_p>0),
 n_propriedades_2mais_upas_com_presenca=sum(p$n_upas_com_presenca>=2),
 n_propriedades_2mais_upas_30mais=sum(p$n_upas_com30>=2),
 n_candidatas_upa_val=sum(z$candidata_reserva_upa),
 n_propriedades_com_candidatas=sum(p$n_candidatas>0))
 for(f in 1:3){g<-z[z$fold_original==f,,drop=FALSE]
 F[[paste(esp,f)]]<-data.frame(especie=esp,fold_original=f,n_upas=nrow(g),n_presencas=sum(g$n_presencas_upa),n_background=sum(g$n_bg_upa),n_candidatas=sum(g$candidata_reserva_upa))}
}
Summary<-do.call(rbind,S);row.names(Summary)<-NULL
Folds<-do.call(rbind,F);row.names(Folds)<-NULL

Pairs<-list();k<-0L
for (esp in c('Ipe-roxo','Ipe-amarelo')) for (prop in sort(unique(M$propriedade))) {
 z<-T[T$especie==esp & T$propriedade==prop & T$n_presencas_upa>=30 & T$n_bg_upa>=30,,drop=FALSE]
 if(nrow(z)<2)next
 for(i in seq_len(nrow(z)-1)) for(j in seq.int(i+1L,nrow(z))) {
 k<-k+1L
 Pairs[[k]]<-data.frame(especie=esp,propriedade=prop,upa_a=z$upa_id[i],n_presencas_a=z$n_presencas_upa[i],n_bg_a=z$n_bg_upa[i],
 upa_b=z$upa_id[j],n_presencas_b=z$n_presencas_upa[j],n_bg_b=z$n_bg_upa[j],distancia_limites_km=dist_entre(z$upa_id[i],z$upa_id[j]),
 contato_ou_sobreposicao=as.integer(dist_entre(z$upa_id[i],z$upa_id[j])==0),
 candidata_reciproca='SIM_DIAGNOSTICO_NAO_APLICAR')
 }
}
Pairs<-do.call(rbind,Pairs);row.names(Pairs)<-NULL
if(nrow(T)!=128||nrow(C)!=43||nrow(Pairs)!=28)stop('Matriz de elegibilidade nao reproduziu as contagens de auditoria.')

# Saida nova: nunca sobrescreve as versoes anteriores
stamp<-format(Sys.time(),'%Y%m%d_%H%M%S')
saida<-file.path(pasta_script,paste0('03_RESULTADOS_R_EXECUCAO_',stamp))
if(dir.exists(saida))stop('Pasta de saida ja existe: ',saida)
dir.create(saida,recursive=TRUE,showWarnings=FALSE)
gravar<-function(obj,nome)utils::write.csv(obj,file.path(saida,nome),row.names=FALSE,fileEncoding='UTF-8',na='')
gravar(M,'26_MATRIZ_64_UPAS.csv')
gravar(T,'26_ELEGIBILIDADE_POR_ESPECIE_128.csv')
gravar(C,'26_CANDIDATAS_RESERVA_UPA.csv')
gravar(Prop,'26_RESUMO_27_PROPRIEDADES_POR_ESPECIE.csv')
gravar(Summary,'26_RESUMO_ELEGIBILIDADE.csv')
gravar(Folds,'26_RESUMO_FOLDS_ORIGINAIS.csv')
gravar(Pairs,'26_PARES_RECIPROCOS_CANDIDATOS.csv')
gravar(Q,'26_QA_GEOMETRIAS_R24_REFERENCIA.csv')
manifest<-data.frame(arquivo=basename(arquivos),md5=md5_encontrado,bytes=as.numeric(file.info(arquivos)$size))
gravar(manifest,'26_MANIFESTO_ENTRADAS.csv')

# Figuras didaticas de suporte, sem inferencia de independencia.
graph_png<-function(nome,codigo){grDevices::png(file.path(saida,nome),width=1300,height=730,res=140);on.exit(grDevices::dev.off());codigo()}
graph_png('26_ELEGIBILIDADE_GRAFICO.png',function(){
 mat<-rbind(Summary$n_upas_com_presenca,Summary$n_upas_com_30mais,Summary$n_candidatas_upa_val)
 colnames(mat)<-c('Ipe-roxo','Ipe-amarelo')
 graphics::barplot(mat,beside=TRUE,col=c('gray30','gray55','gray80'),ylim=c(0,55),
  main='R26 - Triagem de UPAs por especie',ylab='Numero de UPAs',
  legend.text=c('Com registro','Pelo menos 30 presencas','Candidata de reserva individual'),args.legend=list(x='topright',bty='n',cex=.9))
})
graph_png('26_PROPRIEDADES_REPLICADAS_GRAFICO.png',function(){
 mat<-rbind(Summary$n_propriedades_2mais_upas_com_presenca,Summary$n_propriedades_2mais_upas_30mais)
 colnames(mat)<-c('Ipe-roxo','Ipe-amarelo')
 graphics::barplot(mat,beside=TRUE,col=c('gray40','gray75'),ylim=c(0,21),
 main='R26 - Propriedades com multiplas UPAs por especie',ylab='Numero de propriedades',
 legend.text=c('2+ UPAs com registro','2+ UPAs com pelo menos 30 presencas'),args.legend=list(x='topleft',bty='n'))
})
texto<-c('TCC IPES - R26 V1.1 ELEGIBILIDADE DAS UPAS',
 paste('Executado:',Sys.time()),'R26 e DIAGNOSTICO; NAO define folds.',
 '64 UPAs, 27 propriedades, 8680 presencas, 10000 backgrounds B2.',
 sprintf('Roxo: %d UPAs candidatas, %d propriedades candidatas.',Summary$n_candidatas_upa_val[1],Summary$n_propriedades_com_candidatas[1]),
 sprintf('Amarelo: %d UPAs candidatas, %d propriedades candidatas.',Summary$n_candidatas_upa_val[2],Summary$n_propriedades_com_candidatas[2]),
 'O piso de 30 presencas/30 background e exploratorio e nao substitui checagem espacial.',
 'Uma UPA sem registro de especie foi inventariada para ambas, mas BG nao equivale a ausencia de arvore.',
 paste('Pares reciprocos com distancia zero (contato/sobreposicao):',sum(Pairs$contato_ou_sobreposicao),'de',nrow(Pairs)),
 'Pares candidatos reciprocos nao sao folds aprovados.',
 'Modelos do R19 nao podem ser reutilizados em particoes novas por UPA.',
 'As 7 propriedades reservadas para teste externo nao foram consultadas.',
 paste('Arquivos salvos em:',saida),
 paste('Tempo total (s):',round(as.numeric(difftime(Sys.time(),inicio,units='secs')),1)))
writeLines(texto,file.path(saida,'26_RELATORIO_DIAGNOSTICO.txt'),useBytes=TRUE)
cat('\nR26 CONCLUIDO!\n',paste(texto,collapse='\n'),'\n')
