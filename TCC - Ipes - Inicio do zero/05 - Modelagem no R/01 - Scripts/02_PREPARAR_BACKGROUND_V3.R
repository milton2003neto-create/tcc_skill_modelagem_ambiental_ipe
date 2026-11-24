# TCC - R 02 V3 | Planejamento espacial, verificacao de esforco e background
# Script autorreproduzivel. Fonte: QGIS 12 V3. Nunca altera entradas originais.
# EXECUCAO 1: cria CSV de particao e parametros e sai, sem sortear background.
# EXECUCAO 2: apos revisao e aprovacao, cria o background COMUM de calibracao.
# Nao define que 10000 e numero obrigatorio; exibe o dominio elegivel e
# candidatos para uma escolha documentada. Reserva PROPRIEDADES INTEIRAS.
# ATENCAO: os testes historicamente podem ja ter sido analisados; reter
# propriedades no novo ajuste nao constitui teste historicamente cego.
if (!requireNamespace('terra',quietly=TRUE))
  stop('Instale terra: install.packages("terra")')
cat('Selecione 12_UPAS_UNICAS.csv produzido pelo QGIS 12 V3.\n')
arq <- normalizePath(file.choose(),winslash='/',mustWork=TRUE)
achar_raiz <- function(p){d<-dirname(p);repeat{
  if(dir.exists(file.path(d,'04 - Dados para o MaxEnt')) &&
     dir.exists(file.path(d,'03 - Trabalho no QGIS')))return(d)
  pai<-dirname(d);if(d==pai)stop('Raiz TCC nao encontrada');d<-pai
}}
raiz<-achar_raiz(arq)
conf<-file.path(raiz,'03 - Trabalho no QGIS','03 - Conferencias','12C - Dominio inventariado V3')
if(normalizePath(dirname(arq),winslash='/',mustWork=TRUE)!=
   normalizePath(conf,winslash='/',mustWork=TRUE) ||
   basename(arq)!='12_UPAS_UNICAS.csv')stop('Selecione o CSV ORIGINAL do QGIS 12 V3.')
base<-file.path(raiz,'03 - Trabalho no QGIS','02 - Arquivos gerados')
planejamento<-file.path(raiz,'04 - Dados para o MaxEnt','03 - Planejamento metodologico V3')
saida<-file.path(raiz,'04 - Dados para o MaxEnt','03 - Background V3')
ler2<-function(p) read.csv2(p,fileEncoding='UTF-8-BOM',stringsAsFactors=FALSE,check.names=FALSE)
lerq<-function(p) read.table(p,header=TRUE,sep=';',dec='.',fileEncoding='UTF-8-BOM',stringsAsFactors=FALSE,check.names=FALSE,quote='\"')
upas_todas<-lerq(arq)
propriedades<-lerq(file.path(conf,'12_RESUMO_PROPRIEDADES.csv'))
stopifnot(nrow(propriedades)==34, nrow(upas_todas)==84,
          sum(upas_todas$numero_feicoes)==85,
          sum(upas_todas$n_roxo)==5381,sum(upas_todas$n_amarelo)==5945,
          sum(upas_todas$n_roxo_dap_gt10)==5377,
          sum(upas_todas$n_amarelo_dap_gt10)==5945,
          !anyDuplicated(upas_todas$upa_id), !anyDuplicated(propriedades$propriedade))
# CONFIRMACAO DOCUMENTADA: UPAs sem qualquer registro bruto NAO foram inventariadas.
if (any((upas_todas$n_roxo+upas_todas$n_amarelo>0)!=(upas_todas$inventariada=='SIM')))
 stop('Elegibilidade do inventario nao coincide com os registros brutos')
upas<-upas_todas[upas_todas$inventariada=='SIM',,drop=FALSE]
if(nrow(upas)!=78 || sum(upas_todas$inventariada=='NAO')!=6)
 stop('Era esperado encontrar 78 UPAs inventariadas e 6 sem inventario. Conferir origem.')
if (any(upas$pixels_validos_6<1)) stop('UPA inventariada sem celulas elegiveis.')
# Os nomes n_roxo/n_amarelo nas tabelas de planejamento passam a significar
# o numero ANALITICO com DAP estritamente maior que 10 cm.
upas$n_roxo <- upas$n_roxo_dap_gt10
upas$n_amarelo <- upas$n_amarelo_dap_gt10
propriedades$n_roxo <- propriedades$n_roxo_dap_gt10
propriedades$n_amarelo <- propriedades$n_amarelo_dap_gt10
if(any(upas$pixels_validos_6<1))stop('Existem UPAs sem pixels completos. Revise QGIS 12 V3.')
if(any(propriedades$pixels_sem_6>0)) {
 stop('Ha pixels de UPA sem 6 preditores. Leia cobertura e decida tratamento ANTES do R02.')
}
if(file.exists(file.path(conf,'12_SOBREPOSICOES_UPAS.csv'))) {
 sobre<-ler2(file.path(conf,'12_SOBREPOSICOES_UPAS.csv'))
 if(nrow(sobre)>0)message('ATENCAO: sobreposicoes entre UPAs documentadas. Verificar no relatorio.')
}
# Cotas proporcionais ao numero de pixels elegiveis, com minimo 1 por UPA;
# a quota nao pode superar a capacidade fisica da UPA.
quotas<-function(cap,n){
 cap<-as.integer(cap);q<-rep(1L,length(cap));rest<-as.integer(n-length(cap))
 if(any(cap<1) || rest<0 || n>sum(cap))stop('Cotas impossiveis')
 while(rest>0){
  livre<-cap-q;ativos<-which(livre>0)
  if(!length(ativos))stop('Nao ha capacidade para completar a amostra')
  ideal<-rest*livre[ativos]/sum(livre[ativos]);add<-pmin(livre[ativos],floor(ideal))
  if(sum(add)==0L){add[which.max(ideal)]<-1L}
  q[ativos]<-q[ativos]+add;rest<-rest-sum(add)
 }
 q
}

if(!dir.exists(planejamento)){
 dir.create(planejamento,recursive=TRUE)
 # PROPOSTA, NAO divisao definitiva: blocos inteiros por especie e
 # UMA particao territorial unica que exclui essas propriedades do treino
 # de AMBAS as especies. A proposta ja foi inspecionada historicamente,
 # portanto nao se deve declarar um teste historicamente cego.
 cand<-sort(propriedades$propriedade)
 teste_proposto<-c('BARRO BRANCO','MARILIA','LOTE 01',
                   'CURUÇA','GUARIÚBA','JATOBÁ','PALMEIRA')
 if(!all(teste_proposto %in% cand))stop('Nomes das propriedades do teste nao coincidem com os dados: ',
                                      paste(setdiff(teste_proposto,cand),collapse=', '))
 stage<-ifelse(cand %in% teste_proposto,'TESTE','DESENVOLVIMENTO')
 tab<-data.frame(propriedade=cand,conjunto=stage,
   observacao=ifelse(stage=='TESTE','PROPOSTA — PRECISA REVISAO','PROPOSTA'),
   stringsAsFactors=FALSE)
 write.csv2(tab,file.path(planejamento,'02_PARTICAO_PROPOSTA.csv'),row.names=FALSE,fileEncoding='UTF-8')
 parametro<-data.frame(
  campo=c('particao_aprovada','esforco_comparavel_aprovado','n_background_final',
           'background_aprovado','semente','distancia_minima_teste_km','justificativa_tamanho'),
  valor=c('NAO','NAO','0','NAO','20261110','5',
          'PENDENTE: avaliar area valida, quotas por UPA e estabilidade da amostragem'),
  stringsAsFactors=FALSE)
 write.csv2(parametro,file.path(planejamento,'02_PARAMETROS.csv'),row.names=FALSE,fileEncoding='UTF-8')
 resumo<-aggregate(cbind(n_roxo,n_amarelo,pixels_validos_6,area_ha)~propriedade,data=upas,sum)
 resumo<-merge(resumo,tab,by='propriedade',sort=FALSE)
 write.csv2(resumo,file.path(planejamento,'02_DIAGNOSTICO_PARTICAO.csv'),row.names=FALSE,fileEncoding='UTF-8')
 # Compara tamanhos candidatos quanto a disponibilidade fisica de pixels e
 # representatividade das UPAs no plano proposto, NAO usa dados de teste.
 candidatas<-upas[upas$propriedade %in% tab$propriedade[tab$conjunto=='DESENVOLVIMENTO'],,drop=FALSE]
 propostas<-c(1000L,2500L,5000L,10000L)
 detalhe<-list();sintese<-list()
 for(tam in propostas){
  if(tam<nrow(candidatas) || tam>sum(candidatas$pixels_validos_6))next
  q<-quotas(candidatas$pixels_validos_6,tam)
  detalhe[[as.character(tam)]]<-data.frame(n_candidato=tam,
     propriedade=candidatas$propriedade,upa_id=candidatas$upa_id,
     pixels_validos=candidatas$pixels_validos_6,cota=q,
     percentual_pixels_sorteados=100*q/candidatas$pixels_validos_6)
  sintese[[as.character(tam)]]<-data.frame(n_candidato=tam,
     upas_amostradas=length(q),n_pixels_elegiveis=sum(candidatas$pixels_validos_6),
     percentual_amostrado=100*tam/sum(candidatas$pixels_validos_6),
     minimo_pontos_por_upa=min(q),mediana_pontos_por_upa=median(q),
     maximo_pontos_por_upa=max(q),upas_com_menos_de_10=sum(q<10))
 }
 if(length(detalhe)){
  write.csv2(do.call(rbind,detalhe),file.path(planejamento,'02_COTAS_CANDIDATAS.csv'),
     row.names=FALSE,fileEncoding='UTF-8')
  write.csv2(do.call(rbind,sintese),file.path(planejamento,'02_TAMANHOS_CANDIDATOS.csv'),
     row.names=FALSE,fileEncoding='UTF-8')
 }

 roteiro<-c('REVISAO DA PARTICAO E DO ESFORCO AMOSTRAL',
 'Proposta TESTE: BARRO BRANCO, MARILIA, LOTE 01, CURUCA, GUARIUBA, JATOBA, PALMEIRA.',
 'Confirme UPAs, contagens e distancias espaciais usando 12_PROXIMIDADE_ENTRE_PROPRIEDADES.csv.',
 'IMPORTANTE: as propriedades de teste ja foram inspecionadas em auditorias: nao e teste historicamente cego.',
 'Confirmado pelo usuario: ambas especies procuradas NAS UPAs INVENTARIADAS.',
 'Edite 02_PARTICAO_PROPOSTA.csv (TESTE / DESENVOLVIMENTO).',
 'Edite em 02_PARAMETROS.csv: particao_aprovada=SIM; esforco_comparavel_aprovado=SIM;',
 'n_background_final=numero justificado; background_aprovado=SIM; justificativa_tamanho=texto.',
 'distancia_minima_teste_km=limite minimo de triagem, nao prova de independencia espacial.',
 'Confira 02_TAMANHOS_CANDIDATOS.csv e 02_COTAS_CANDIDATAS.csv.',
 'Tamanhos candidatos NAO testam estabilidade dos modelos: testar depois somente com desenvolvimento.',
 'Depois disso, execute este mesmo R02 V3 novamente.',
 'Nenhuma calibracao e permitida antes de verificar o plano.')
 writeLines(roteiro,file.path(planejamento,'02_LEIA_PRIMEIRO.txt'),useBytes=TRUE)
 cat('\nPRIMEIRA ETAPA: diagnostico e proposta criados em:\n',planejamento,
     '\nRevisar e aprovar a particao antes de voltar a executar.\n')
 stop('Interrupcao intencional de planejamento: nenhum background novo foi gerado.',call.=FALSE)
}
part<-ler2(file.path(planejamento,'02_PARTICAO_PROPOSTA.csv'))
param<-ler2(file.path(planejamento,'02_PARAMETROS.csv'))
getp<-function(chave){v<-param$valor[param$campo==chave];
 if(length(v)!=1)stop('Parametro ausente ou duplicado: ',chave);trimws(as.character(v))}
if(!identical(sort(part$propriedade),sort(propriedades$propriedade)) ||
   anyDuplicated(part$propriedade) ||
   !all(part$conjunto %in% c('TESTE','DESENVOLVIMENTO')))
 stop('Particao invalida; use 34 propriedades com TESTE/DESENVOLVIMENTO.')
if(getp('particao_aprovada')!='SIM')
 stop('A particao ainda nao foi aprovada. Revise 02_PARTICAO_PROPOSTA.csv.')
if(getp('esforco_comparavel_aprovado')!='SIM')
 stop('Falta validar que as duas especies foram cobertas pelo mesmo esforco de inventario.')
n_final<-suppressWarnings(as.integer(getp('n_background_final')))
if(!is.finite(n_final) || n_final<length(which(upas$propriedade %in%
  part$propriedade[part$conjunto=='DESENVOLVIMENTO'])))
 stop('n_background_final deve ser maior ou igual ao numero de UPAs de desenvolvimento.')
if(getp('background_aprovado')!='SIM' || nchar(getp('justificativa_tamanho'))<45 ||
   grepl('PENDENTE',getp('justificativa_tamanho'),ignore.case=TRUE))
 stop('Preencha a justificativa e marque background_aprovado=SIM.')
semente<-suppressWarnings(as.integer(getp('semente')))
if(!is.finite(semente) || semente<1)stop('Semente invalida')
teste<-part$propriedade[part$conjunto=='TESTE']
dev<-part$propriedade[part$conjunto=='DESENVOLVIMENTO']
if(length(teste)<1 || length(dev)<2)stop('Particao sem teste/desenvolvimento suficientes')
conts<-merge(propriedades[,c('propriedade','n_roxo','n_amarelo')],part,by='propriedade')
nt<-colSums(conts[conts$conjunto=='TESTE',c('n_roxo','n_amarelo'),drop=FALSE])
nd<-colSums(conts[conts$conjunto=='DESENVOLVIMENTO',c('n_roxo','n_amarelo'),drop=FALSE])
if(any(nt<30) || any(nd<100))stop('Um conjunto tem poucas presencas por especie. Reveja teste.')
# Bloqueio conservador: NENHUMA propriedade de teste pode estar a menos
# do limite inicial de triagem da propriedade de calibracao mais proxima.
# Essa distancia geometrica nao substitui modelar a autocorrelacao espacial.
prox<-lerq(file.path(conf,'12_PROXIMIDADE_ENTRE_PROPRIEDADES.csv'))
dist_min<-suppressWarnings(as.numeric(getp('distancia_minima_teste_km')))
if(!is.finite(dist_min) || dist_min<0)stop('Distancia minima de triagem invalida')
pareamento<-prox[(prox$propriedade_a %in% teste & prox$propriedade_b %in% dev) |
                 (prox$propriedade_b %in% teste & prox$propriedade_a %in% dev),,drop=FALSE]
if(!nrow(pareamento))stop('Nao foram calculadas distancias teste/desenvolvimento')
menor<-min(pareamento$distancia_minima_m)/1000
if(menor < dist_min)stop(sprintf('Falha no bloqueio espacial: separacao minima %.3f km < triagem %.3f km. Reveja particao.',menor,dist_min))
cat(sprintf('Triagem espacial: distancia minima entre UPA(s) TESTE e desenvolvimento = %.2f km.\n',menor))
selec<-upas[upas$propriedade %in% dev,,drop=FALSE]
selec<-selec[order(selec$propriedade,selec$upa_indice),,drop=FALSE]
if(n_final>sum(selec$pixels_validos_6))stop('Mais amostras que pixels elegiveis.')
selec$cota<-quotas(selec$pixels_validos_6,n_final)
if(sum(selec$cota)!=n_final)stop('Falha no calculo de cotas')
if(dir.exists(saida))stop('Saida revisada ja existe; nao sera sobrescrita: ',saida)
paths<-function(n) c(
 altitude_m=file.path(base,'Altitude e declividade',n,'altitude_utm30m.tif'),
 declividade_graus=file.path(base,'Altitude e declividade',n,'declividade_graus_utm30m.tif'),
 dist_rio_raster_m=file.path(base,'Distancia aos rios',n,'distancia_rios_utm30m.tif'),
 bio12_mm_ano=file.path(base,'Clima e solo alinhados',n,'bio12_utm30m.tif'),
 bio17_mm_mes=file.path(base,'Clima e solo alinhados',n,'bio17_utm30m.tif'),
 textura_subgrupo=file.path(base,'Clima e solo alinhados',n,'textura_solo_utm30m.tif'))
partes<-list()
for(k in seq_len(nrow(selec))){
 linha<-selec[k,];n<-linha$propriedade;i<-as.integer(linha$upa_indice)
 pm<-file.path(base,'Mascaras UPAs inventariadas V3',n)
 mascara<-terra::rast(file.path(pm,'mascara_upas_validas_30m.tif'))
 idx<-terra::rast(file.path(pm,'mascara_upa_id_30m.tif'))
 if(!isTRUE(terra::compareGeom(mascara,idx,stopOnError=FALSE)))stop('Mascara/ID mal alinhados: ',n)
 raster_por_upa<-terra::ifel(mascara==1 & idx==i,1,NA)
 set.seed(semente+match(n,sort(dev))*100L+i)
 pontos<-terra::spatSample(raster_por_upa,size=as.integer(linha$cota),method='random',
                replace=FALSE,na.rm=TRUE,as.points=TRUE,values=FALSE,exhaustive=TRUE)
 if(nrow(pontos)!=linha$cota)stop('Amostra nao atingida: ',linha$upa_id)
 celulas<-as.integer(terra::cellFromXY(mascara,terra::crds(pontos)))
 if(anyDuplicated(celulas))stop('Celulas repetidas dentro de UPA: ',linha$upa_id)
 if(any(terra::extract(idx,pontos,ID=FALSE)[[1]]!=i))stop('Ponto na UPA errada: ',linha$upa_id)
 arqs<-paths(n)
 if(any(!file.exists(arqs)))stop('Faltam preditores: ',n)
 rr<-lapply(arqs,terra::rast)
 for(r in rr)if(!isTRUE(terra::compareGeom(mascara,r,stopOnError=FALSE)))
   stop('Preditor/mascara com grade diferente: ',n)
 stack<-terra::rast(unname(arqs));valores<-terra::extract(stack,pontos,ID=FALSE)
 if('ID' %in% names(valores) && ncol(valores)==7)valores$ID<-NULL
 if(ncol(valores)!=6)stop('Seis preditores esperados: ',n)
 names(valores)<-names(arqs)
 if(any(!is.finite(as.matrix(valores))))stop('NoData em background: ',n)
 if(any(valores$textura_subgrupo<1 | valores$textura_subgrupo>9 |
        abs(valores$textura_subgrupo-round(valores$textura_subgrupo))>1e-5))
    stop('Codigo textura invalido: ',n)
 xy<-terra::crds(pontos)
 geografico<-terra::crds(terra::project(pontos,'EPSG:4674'))
 partes[[k]]<-data.frame(propriedade=n,upa_id=linha$upa_id,upa_nome=linha$upa_nome,
     upa_indice=i,epsg_utm=linha$epsg,celula_raster=celulas,
     x_utm=xy[,1],y_utm=xy[,2],longitude=geografico[,1],latitude=geografico[,2],
     valores,check.names=FALSE,stringsAsFactors=FALSE)
 cat(sprintf('[R02 v3] %02d/%02d %s: %d pontos\n',k,nrow(selec),linha$upa_id,linha$cota))
}
bg<-do.call(rbind,partes);rownames(bg)<-NULL
bg$id_background<-sprintf('BG_%06d',seq_len(nrow(bg)))
if(nrow(bg)!=n_final || anyDuplicated(bg$id_background) ||
   anyDuplicated(paste(bg$propriedade,bg$celula_raster,sep='|')) ||
   any(bg$propriedade %in% teste) ||
   !setequal(unique(bg$upa_id),selec$upa_id))stop('Falha na auditoria interna do background')
# Registro unico COMUM as duas especies. Nao duplicar observacoes espaciais.
dir.create(saida,recursive=TRUE)
write.csv(bg,file.path(saida,'BACKGROUND_COMUM_DESENVOLVIMENTO.csv'),row.names=FALSE,fileEncoding='UTF-8')
write.csv2(selec,file.path(saida,'02_COTAS_POR_UPA.csv'),row.names=FALSE,fileEncoding='UTF-8')
write.csv2(part,file.path(saida,'02_PARTICAO_APROVADA.csv'),row.names=FALSE,fileEncoding='UTF-8')
write.csv2(param,file.path(saida,'02_PARAMETROS_APROVADOS.csv'),row.names=FALSE,fileEncoding='UTF-8')
writeLines(c('BACKGROUND COMUM DE DESENVOLVIMENTO','Background != ausencia confirmada.',
 paste('N:',n_final,'Semente:',semente),
 paste('UPAs de desenvolvimento:',nrow(selec),'Propriedades:',length(dev)),
 paste('Testes reservados:',paste(teste,collapse='; ')),
 'Dominio: SO UPAs inventariadas (ao menos 1 registro bruto), 6 rasters validos; DAP>10 aplicado apenas a presencas.',
 'UPAs sem inventario EXCLUIDAS; RIOS reais externos MANTIDOS na distancia global.',
 'Uma mesma amostra ambiental atende DUAS especies sob o protocolo compartilhado CONFIRMADO nas UPAs elegiveis.',
 'Quotas proporcionais a celulas validas, minimo 1 por UPA; nao inclui buffers de 300m.',
 sprintf('Distancia minima TESTE-DESENVOLVIMENTO: %.3f km (limiar de triagem: %.3f km)',menor,dist_min),
 'Correlacoes climaticas em 30m nao criam independencia CHELSA de 1km.',
 'Particao espacial de NOVO ajuste; independencia historicamente cega NAO demonstrada.',
 paste('Justificativa N:',getp('justificativa_tamanho')),
 paste('Versao R:',R.version.string,'terra:',as.character(packageVersion('terra')))),
 file.path(saida,'02_METODO_E_ALERTAS.txt'))
cat('\nR 02 V3 CONCLUIDO. Background comum:',nrow(bg),'em\n',saida,'\n')
