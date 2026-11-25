# TCC - R 04 V3 | Presencas de duas especies versus MESMO ambiente de desenvolvimento.
# Usa apenas os GeoPackages das arvores com variaveis e o BG COMUM V3.
# Os testes reservados ficam EXCLUIDOS de todas as tabelas e graficos.
# Diferencas descritivas NAO implicam preferencia ecológica nem causalidade.
for(p in c('terra','ggplot2')) if(!requireNamespace(p,quietly=TRUE))
 stop('Instale ',p,': install.packages(c("terra","ggplot2"))')
cat('Selecione BACKGROUND_COMUM_DESENVOLVIMENTO.csv (R02 V3).\n')
arq<-normalizePath(file.choose(),winslash='/',mustWork=TRUE)
achar<-function(p){d<-dirname(p);repeat{
 if(dir.exists(file.path(d,'03 - Trabalho no QGIS')) && dir.exists(file.path(d,'06 - Resultados')))return(d)
 pai<-dirname(d);if(d==pai)stop('Pasta principal nao localizada');d<-pai}}
raiz<-achar(arq)
bg_dir<-file.path(raiz,'04 - Dados para o MaxEnt','03 - Background V3')
if(dirname(arq)!=normalizePath(bg_dir,winslash='/',mustWork=TRUE) ||
   basename(arq)!='BACKGROUND_COMUM_DESENVOLVIMENTO.csv')stop('Selecione o background V3')
saida<-file.path(raiz,'06 - Resultados','03 - Comparacao ambiental - V3')
if(dir.exists(saida))stop('Saida ja existente. Nunca sobrescrever: ',saida)
part<-read.csv2(file.path(bg_dir,'02_PARTICAO_APROVADA.csv'),fileEncoding='UTF-8',stringsAsFactors=FALSE)
teste<-part$propriedade[part$conjunto=='TESTE']
dev<-part$propriedade[part$conjunto=='DESENVOLVIMENTO']
if(length(teste)==0 || length(dev)==0)stop('Particao inexistente')
bg<-read.csv(arq,fileEncoding='UTF-8',stringsAsFactors=FALSE,check.names=FALSE)
if(any(bg$propriedade %in% teste) || !all(bg$propriedade%in%dev))
 stop('Vazamento de TESTE no background.')
vars<-c('altitude_m','declividade_graus','dist_rio_raster_m','bio12_mm_ano','bio17_mm_mes')
campos<-c('propriedade','upa_id','textura_subgrupo',vars)
if(!all(campos%in%names(bg)))stop('Campos ausentes no BG')
para_num<-function(x){for(v in c(vars,'textura_subgrupo')){
 x[[v]]<-suppressWarnings(as.numeric(x[[v]]))
 if(any(!is.finite(x[[v]])))stop('Valor nulo na coluna ',v)
};x}
bg<-para_num(bg)
p_gp<-file.path(raiz,'03 - Trabalho no QGIS','02 - Arquivos gerados','Pontos com variaveis')
files<-sort(list.files(p_gp,pattern='\\.gpkg$',full.names=TRUE,ignore.case=TRUE))
if(length(files)!=34)stop('Esperados 34 GPKGs de pontos. Encontrados ',length(files))
# Bloqueio de TESTE: arquivos de TESTE sequer sao lidos nesta analise.
files<-files[tools::file_path_sans_ext(basename(files)) %in% dev]
if(length(files)!=length(dev))stop('Nem todas as propriedades de desenvolvimento foram encontradas.')
identificar<-function(x){
 nm<-if('nome_cientifico'%in%names(x))tolower(as.character(x$nome_cientifico)) else rep('',nrow(x))
 vul<-if('nome_vulgar'%in%names(x))tolower(as.character(x$nome_vulgar)) else rep('',nrow(x))
 nm[is.na(nm)]<-'';vul[is.na(vul)]<-''
 r<-grepl('impetiginosus',nm)|grepl('roxo',vul)
 a<-grepl('serratifolius',nm)|grepl('amarelo',vul)
 if(any(r==a))stop('Especies ambiguas no arquivo de presencas')
 ifelse(r,'Ipe-roxo','Ipe-amarelo')
}
ler_arv<-function(file){
 v<-terra::vect(file,layer='arvores_com_variaveis')
 x<-as.data.frame(v);n<-tools::file_path_sans_ext(basename(file))
 if(!all(c('linha_csv','textura_subgrupo','dap_cm_num','elegivel_dap_gt10',vars)%in%names(x)))
  stop('Campos V3 faltantes: ',n)
 x$propriedade<-n;x$especie<-identificar(x)
 x<-para_num(x)
 x$dap_cm_num<-suppressWarnings(as.numeric(x$dap_cm_num))
 x$elegivel_dap_gt10<-suppressWarnings(as.integer(x$elegivel_dap_gt10))
 if(any(!is.finite(x$dap_cm_num)) ||
    any(x$elegivel_dap_gt10!=as.integer(x$dap_cm_num>10)))
   stop('Falha no filtro DAP V3: ',n)
 x<-x[x$dap_cm_num>10,,drop=FALSE]
 x[,c('propriedade','linha_csv','especie','textura_subgrupo',vars),drop=FALSE]
}
todas<-do.call(rbind,lapply(files,ler_arv))
if(nrow(todas)<1)stop('Sem arvores analiticas nas propriedades de desenvolvimento')
pre<-todas
if(anyDuplicated(paste(pre$propriedade,pre$linha_csv,sep='|')))
  stop('Arvore analitica duplicada (propriedade e linha_csv)')
if(any(pre$propriedade%in%teste) || !all(pre$especie %in% c('Ipe-roxo','Ipe-amarelo')))
 stop('Amostra de desenvolvimento invalida')
if(!any(pre$especie=='Ipe-roxo') || !any(pre$especie=='Ipe-amarelo'))
 stop('Faltam registros em desenvolvimento')
# Contraste global e contrastes por propriedade: IMPORTANTES PARA evitar
# interpretar diferencas regionais como preferencias intrinsecas.
rows<-list();rows_prop<-list();k<-0L;j<-0L
for(e in c('Ipe-roxo','Ipe-amarelo')){
 x<-pre[pre$especie==e,,drop=FALSE]
 for(v in vars){
  k<-k+1L;ma<-mean(x[[v]]);mb<-mean(bg[[v]])
  rows[[k]]<-data.frame(especie=e,variavel=v,n_presencas=nrow(x),n_bg=nrow(bg),
    media_pres=ma,media_bg=mb,mediana_pres=median(x[[v]]),
    mediana_bg=median(bg[[v]]),diferenca=ma-mb,
    desvio_padrao_bg=sd(bg[[v]]),
    diferenca_padronizada=if(sd(bg[[v]])>0)(ma-mb)/sd(bg[[v]]) else NA_real_)
  for(n in sort(unique(x$propriedade))){
   xa<-x[x$propriedade==n,v];xb<-bg[bg$propriedade==n,v]
   if(length(xb)==0)stop('Propriedade com arvores mas sem BG: ',n)
   j<-j+1L
   rows_prop[[j]]<-data.frame(especie=e,propriedade=n,variavel=v,
     n_arvores=length(xa),n_background=length(xb),media_arvores=mean(xa),
     media_background=mean(xb),diferenca_dentro_propriedade=mean(xa)-mean(xb))
  }
 }
}
global<-do.call(rbind,rows);por_prop<-do.call(rbind,rows_prop)
# Quantos dos contrastes de cada especie sao positivos em diferentes fazendas?
sintese<-do.call(rbind,lapply(split(por_prop,paste(por_prop$especie,por_prop$variavel)),function(x)
 data.frame(especie=x$especie[1],variavel=x$variavel[1],
  n_propriedades=nrow(x),contraste_medio_peso_igual=mean(x$diferenca_dentro_propriedade),
  mediana_das_diferencas=median(x$diferenca_dentro_propriedade),
  pct_propriedades_diferenca_positiva=100*mean(x$diferenca_dentro_propriedade>0))))
# Analise de propriedades COMPARTILHADAS com registros das duas especies:
# controla parte do efeito regional, mas NAO e desenho experimental causal.
ct<-xtabs(~propriedade+especie,pre)
compartilhadas<-rownames(ct)[rowSums(ct>0)==2]
comp<-por_prop[por_prop$propriedade%in%compartilhadas,,drop=FALSE]
# Categorizacao do solo: comparar percentuais, nunca media do codigo.
leg_file<-file.path(raiz,'02 - Fontes ambientais','MapBiomas Solo',
 'LEGENDA_MapBiomas_Solo_C3_Subgrupo_0_30cm.csv')
leg<-read.csv2(leg_file,fileEncoding='UTF-8-BOM',stringsAsFactors=FALSE)
leg$codigo<-as.integer(leg$codigo)
if(!setequal(leg$codigo,1:9))stop('Legenda de solo inconsistente')
solo_rows<-list();k<-0L
for(e in c('Ipe-roxo','Ipe-amarelo')){
 x<-pre[pre$especie==e,,drop=FALSE]
 for(i in seq_len(nrow(leg))){
  cd<-leg$codigo[i];na<-sum(x$textura_subgrupo==cd);nb<-sum(bg$textura_subgrupo==cd)
  k<-k+1L;solo_rows[[k]]<-data.frame(especie=e,codigo=cd,classe=leg$classe[i],
    presencas=na,bg=nb,percentual_presencas=100*na/nrow(x),
    percentual_bg=100*nb/nrow(bg),classe_sem_bg=nb==0)
 }
}
solo<-do.call(rbind,solo_rows)
# Salvar resultados SOMENTE apos concluir checagens de dominios.
dir.create(saida,recursive=TRUE)
salvar<-function(x,p)write.csv(x,file.path(saida,p),row.names=FALSE,fileEncoding='UTF-8')
salvar(global,'04_CONTRASTE_GLOBAL.csv');salvar(por_prop,'04_CONTRASTE_POR_PROPRIEDADE.csv')
salvar(sintese,'04_SINTESE_POR_PROPRIEDADE.csv')
salvar(comp,'04_APENAS_PROPRIEDADES_COM_AMBAS_ESPECIES.csv')
salvar(solo,'04_SOLO_COMPARACAO.csv')
salvar(data.frame(especie=c('Ipe-roxo','Ipe-amarelo'),
 n_arvores=c(sum(pre$especie=='Ipe-roxo'),sum(pre$especie=='Ipe-amarelo')),
 n_background_comum=c(nrow(bg),nrow(bg))), '04_AMOSTRAS.csv')
if(requireNamespace('writexl',quietly=TRUE))
 writexl::write_xlsx(list(Global=global,Por_propriedade=por_prop,
   Sintese=sintese,Propriedades_compartilhadas=comp,Solo=solo),
   file.path(saida,'04_COMPARACAO_REVISADA.xlsx'))
rotulos<-c(altitude_m='Altitude (m)',declividade_graus='Declividade (graus)',
 dist_rio_raster_m='Distância aos rios (m)',bio12_mm_ano='BIO12 (mm/ano)',
 bio17_mm_mes='BIO17 (mm/mês)')
cores<-c('Background comum'='#4A7996','Árvores registradas'='#B7734E')
estilo<-function()ggplot2::theme_minimal(base_size=12)+
 ggplot2::theme(plot.title=ggplot2::element_text(face='bold'),
 panel.grid.minor=ggplot2::element_blank(),legend.position='bottom')
for(v in vars){
 plotdata<-do.call(rbind,lapply(c('Ipe-roxo','Ipe-amarelo'),function(e){
  x<-pre[pre$especie==e,v];b<-bg[[v]]
  rbind(data.frame(especie=e,grupo='Árvores registradas',valor=x),
        data.frame(especie=e,grupo='Background comum',valor=b))
 }))
 p<-ggplot2::ggplot(plotdata,ggplot2::aes(x=valor,color=grupo,fill=grupo))+
  ggplot2::geom_density(alpha=.15,linewidth=.8,adjust=1.1)+
  ggplot2::facet_wrap(~especie,nrow=1,scales='free_y')+
  ggplot2::scale_color_manual(values=cores)+ggplot2::scale_fill_manual(values=cores)+
  ggplot2::labs(title=paste('Presenças e disponibilidade ambiental:',rotulos[v]),
   subtitle='Somente propriedades de desenvolvimento; comparação exploratória',
   x=rotulos[v],y='Densidade relativa',color='Amostra',fill='Amostra',
   caption='Influência geográfica possível; background não é ausência, nem pixels climáticos independentes.')+estilo()
 nome<-file.path(saida,paste0('04_',v))
 ggplot2::ggsave(paste0(nome,'.png'),p,width=11,height=5,dpi=300,bg='white')
 ggplot2::ggsave(paste0(nome,'.pdf'),p,width=11,height=5,bg='white')
}
sl<-rbind(data.frame(especie=solo$especie,classe=solo$classe,
  grupo='Árvores registradas',pct=solo$percentual_presencas),
  data.frame(especie=solo$especie,classe=solo$classe,
  grupo='Background comum',pct=solo$percentual_bg))
sl$classe<-factor(sl$classe,levels=leg$classe[order(leg$codigo)])
sl$grupo<-factor(sl$grupo,levels=names(cores))
ps<-ggplot2::ggplot(sl,ggplot2::aes(x=classe,y=pct,fill=grupo))+
 ggplot2::geom_col(position=ggplot2::position_dodge(width=.8),width=.72)+
 ggplot2::coord_flip()+ggplot2::facet_wrap(~especie,nrow=1)+
 ggplot2::scale_fill_manual(values=cores)+
 ggplot2::labs(title='Textura do solo: presenças e disponibilidade',
  subtitle='Comparação no domínio de desenvolvimento compartilhado',
  x=NULL,y='Percentual (%)',fill='Amostra')+estilo()
ggplot2::ggsave(file.path(saida,'04_SOLO.png'),ps,width=12,height=6,dpi=300,bg='white')
ggplot2::ggsave(file.path(saida,'04_SOLO.pdf'),ps,width=12,height=6,bg='white')
writeLines(c('R 04 V3 - COMPARACOES DESCRITIVAS','Reservas de TESTE excluidas para AMBAS especies.',
 paste('Teste:',paste(teste,collapse='; ')),
 paste('Propriedades de desenvolvimento com as duas especies:',
       if(length(compartilhadas))paste(compartilhadas,collapse='; ') else 'nenhuma'),
 'Background comum, apenas UPAs INVENTARIADAS: esforço compartilhado confirmado pelo usuario.',
 'Arvores com DAP estritamente >10 cm; menores preservadas nas fontes.',
 'Contrastes brutos diferem de contrastes estratificados por propriedade.',
 'Nao inferir preferencia intrinseca por clima/solo nem independencia de pixels CHELSA.',
 'Sem teste estatistico ingenuo por pseudorreplicacao espacial.',
 paste('Versao R:',R.version.string)),
 file.path(saida,'04_NOTAS_METODOLOGICAS.txt'))
cat('R04 V3 CONCLUIDO:',saida,'\n')
