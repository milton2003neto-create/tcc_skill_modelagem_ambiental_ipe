# =============================================================================
# TCC IPES | R21 V1 - CONTRASTES AMBIENTAIS ENTRE TREINO E VALIDACAO
# =============================================================================
# Continuacao do R20 V1.3. Analise exploratoria, SEM novos ajustes MaxEnt.
# Unidades: empreendimento/propriedade x UPA, com folds intactos.
# Entradas: R19 (manifesto MD5), R05 (presencas), R18 (background B2) e R20.
# NUNCA le conjuntos TESTE_CEGO ou as sete propriedades externas reservadas.
#
# Execute o script inteiro no RStudio (Source). Escolha o arquivo ORIGINAL:
#   19_METRICAS_72_MODELOS_B2.csv, dentro da pasta de resultados do R19.
# Saidas: NOVA pasta "19 - Contrastes ambientais R21 V1" em 06 - Resultados.
# =============================================================================

versao_r21 <- 'R21_V1_20261117'
cat('\nR21: selecione 19_METRICAS_72_MODELOS_B2.csv na pasta ORIGINAL do R19.\n')
arq_metricas <- normalizePath(file.choose(),winslash='/',mustWork=TRUE)
if (basename(arq_metricas)!='19_METRICAS_72_MODELOS_B2.csv')
  stop('Selecione exatamente 19_METRICAS_72_MODELOS_B2.csv.')
pasta19 <- dirname(arq_metricas)
pasta_res <- pasta19
while (basename(pasta_res)!='06 - Resultados' && dirname(pasta_res)!=pasta_res)
  pasta_res <- dirname(pasta_res)
if (basename(pasta_res)!='06 - Resultados')
  stop('O CSV selecionado deve estar dentro da arvore 06 - Resultados.')
raiz <- dirname(pasta_res)
pasta20 <- file.path(pasta_res,'18 - Diagnostico espacial ambiental R20 V1_3')
if (!dir.exists(pasta20))
  stop('Nao encontrei os resultados do R20 V1.3 em: ',pasta20,
       '\nMantenha a pasta R20 no local em que o script anterior a criou.')

ler <- function(f) utils::read.csv(f,stringsAsFactors=FALSE,
             check.names=FALSE,fileEncoding='UTF-8-BOM')
exigir <- function(d,nms,rotulo) {
  falta <- setdiff(nms,names(d))
  if (length(falta)) stop('Colunas faltantes em ',rotulo,': ',paste(falta,collapse=', '))
}
md5 <- function(f) unname(tools::md5sum(f))
manifesto_arq <- file.path(pasta19,'19_MANIFESTO_ENTRADAS.csv')
if (!file.exists(manifesto_arq)) stop('Manifesto do R19 nao localizado.')
manifesto19 <- ler(manifesto_arq)
exigir(manifesto19,c('arquivo','caminho','md5'),'manifesto R19')
localizar <- function(nome) {
  z <- manifesto19[manifesto19$arquivo==nome,,drop=FALSE]
  if (nrow(z)!=1L) stop('Arquivo sem registro unico no manifesto R19: ',nome)
  original <- gsub('\\\\','/',as.character(z$caminho[1]))
  possibilidades <- original
  for (ancora in c('04 - Dados para o MaxEnt/','06 - Resultados/')) {
    i <- regexpr(ancora,original,fixed=TRUE)[1]
    if (i>0L) possibilidades <- c(possibilidades,
                                 file.path(raiz,substring(original,i)))
  }
  possibilidades <- unique(possibilidades)
  disponiveis <- possibilidades[file.exists(possibilidades)]
  if (!length(disponiveis)) stop('Arquivo fonte nao localizado: ',nome,
                  '\nConserve a arvore de pastas da execucao do R19.')
  verificados <- disponiveis[tolower(vapply(disponiveis,md5,character(1)))==
                                  tolower(as.character(z$md5[1]))]
  if (!length(verificados)) stop('MD5 nao confere para ',nome,
                         '\nNao substitua silenciosamente os dados.')
  verificados[1]
}

pres_arq <- localizar('05_PRESENCAS_UM_POR_PIXEL_30M.csv')
b2_arq <- localizar('18_BACKGROUND_B2_10000_COM_FOLDS.csv')
pres <- ler(pres_arq)
bg <- ler(b2_arq)
metricas <- ler(arq_metricas)
r20_uni_arq <- file.path(pasta20,'20_NOVIDADE_UNIVARIADA.csv')
r20_upa_arq <- file.path(pasta20,'20_ESFORCO_POR_UPA.csv')
r20_nn_arq <- file.path(pasta20,'20_NN_POR_PROPRIEDADE.csv')
if (!all(file.exists(c(r20_uni_arq,r20_upa_arq,r20_nn_arq))))
  stop('Faltam resultados do R20 V1.3 (novidade, UPAs ou vizinho mais proximo).')
r20_uni <- ler(r20_uni_arq)
r20_upa <- ler(r20_upa_arq)
r20_nn <- ler(r20_nn_arq)

continuas <- c('altitude_m','declividade_graus','dist_rio_raster_m',
               'bio12_mm_ano','bio17_mm_mes')
variaveis <- c(continuas,'textura_subgrupo')
especies <- c('Ipe-roxo','Ipe-amarelo')
exigir(pres,c('especie','propriedade','upa_id','fold_cv',variaveis),'R05 presencas')
exigir(bg,c('propriedade','upa_id','fold_cv',variaveis),'R18 background B2')
exigir(metricas,c('id','especie','fold_cv','features','RM'),'R19 metricas')
exigir(r20_uni,c('especie','fold_cv','variavel','n_presencas_fora',
                 'n_background_fora'),'R20 novidade univariada')
exigir(r20_upa,c('propriedade','upa_id','fold_cv','n_background_b2',
                 'n_roxo','n_amarelo'),'R20 UPAs')
if (nrow(pres)!=8680L || nrow(bg)!=10000L || nrow(metricas)!=72L ||
    length(unique(bg$propriedade))!=27L ||
    nrow(unique(bg[,c('propriedade','upa_id')]))!=64L ||
    !setequal(unique(pres$especie),especies) ||
    anyDuplicated(metricas$id))
  stop('Contagens de R05/R18/R19 diferentes do protocolo R20 auditado.')
if (anyNA(pres[,c('especie','propriedade','upa_id','fold_cv',variaveis),drop=FALSE]) ||
    anyNA(bg[,c('propriedade','upa_id','fold_cv',variaveis),drop=FALSE]))
  stop('Existem NA em colunas ambientais ou de identificacao.')
for (nm in continuas) {
  if (!is.numeric(pres[[nm]]) || !is.numeric(bg[[nm]]) ||
      any(!is.finite(pres[[nm]])) || any(!is.finite(bg[[nm]])))
    stop('Variavel numerica invalida em ',nm)
}
# Protecao contra troca de UPA/fold e entrada acidental de testes externos.
fo <- unique(rbind(pres[,c('propriedade','fold_cv')],
                   bg[,c('propriedade','fold_cv')]))
if (any(vapply(split(fo$fold_cv,fo$propriedade),
          function(z) length(unique(z))!=1L, logical(1))))
  stop('Uma propriedade pertence a mais de um fold.')
par <- unique(bg[,c('propriedade','upa_id','fold_cv')])
if (anyDuplicated(par[,c('propriedade','upa_id')]))
  stop('UPA aparece em mais de um fold.')
if (!setequal(unique(pres$propriedade),unique(bg$propriedade)))
  stop('Propriedades de presencas e B2 nao correspondem.')
testar <- toupper(iconv(c(pres$propriedade,bg$propriedade),
                         from='',to='ASCII//TRANSLIT'))
testar <- gsub('_',' ',testar,fixed=TRUE)
reservadas <- c('BARRO BRANCO','CURUCA','GUARIUBA','JATOBA',
                'LOTE 01','MARILIA','PALMEIRA')
if (anyNA(testar) || any(testar %in% reservadas))
  stop('Identificacao de propriedade externa ou encoding invalido: pare.')
if (any(!paste(pres$propriedade,pres$upa_id,sep='||') %in%
         paste(bg$propriedade,bg$upa_id,sep='||')))
  stop('Presenca localizada em UPA fora do dominio B2 inventariado.')

# Estatisticas sempre referenciadas ao background dos DOIS folds de treino.
# Os dados do fold retido nao sao usados para definir seus proprios limites.
quant <- function(x,p) if (length(x)) as.numeric(stats::quantile(x,p)) else NA_real_
prop <- function(x) if (!length(x)) NA_real_ else mean(x)
med <- function(x) if (!length(x)) NA_real_ else stats::median(x)
media <- function(x) if (!length(x)) NA_real_ else mean(x)
num <- function(x) if (!length(x)) 0L else sum(x)

# Calcula cada contraste entre presencas e background *local*, e, separadamente,
# novidade de ambos em relacao ao background global do treino daquele fold.
calcular <- function(x, b_local, b_treino, variavel) {
  base <- b_treino[[variavel]]
  op <- x[[variavel]]
  ob <- b_local[[variavel]]
  baixo <- min(base); alto <- max(base)
  dp <- stats::sd(base)
  data.frame(variavel=variavel, n_presencas=length(op),
    n_background_local=length(ob), n_background_treino=length(base),
    treino_min=baixo, treino_p05=quant(base,.05),treino_p50=med(base),
    treino_p95=quant(base,.95),treino_max=alto,
    pres_min=if(length(op))min(op) else NA_real_,
    pres_mediana=med(op),pres_max=if(length(op))max(op) else NA_real_,
    background_local_mediana=med(ob),
    delta_mediana_pres_menos_bg_local=med(op)-med(ob),
    delta_pres_menos_bg_local_em_DP_treino=
      if(is.finite(dp) && dp>0) (med(op)-med(ob))/dp else NA_real_,
    prop_pres_abaixo_min_treino=prop(op<baixo),
    prop_pres_acima_max_treino=prop(op>alto),
    prop_pres_fora_treino=prop(op<baixo | op>alto),
    prop_bg_local_abaixo_min_treino=prop(ob<baixo),
    prop_bg_local_acima_max_treino=prop(ob>alto),
    prop_bg_local_fora_treino=prop(ob<baixo | ob>alto),
    n_pres_fora_treino=num(op<baixo | op>alto),
    n_bg_local_fora_treino=num(ob<baixo | ob>alto),
    local_pres_suficiente=length(op)>=10L,
    local_bg_suficiente=length(ob)>=10L,
    stringsAsFactors=FALSE)
}

# 1. Tres escalas: fold, propriedade e UPA (sempre com ambas as especies).
linhas_fold <- list(); linhas_prop <- list(); linhas_upa <- list()
kp <- 0L; kf <- 0L; ku <- 0L
for (f in 1:3) {
  treino <- bg[bg$fold_cv!=f,,drop=FALSE]
  val_bg <- bg[bg$fold_cv==f,,drop=FALSE]
  if (nrow(treino)<3000L || nrow(val_bg)<500L)
    stop('Background de treino/validacao insuficiente no fold ',f)
  cat('R21: fold ',f,' | ',nrow(treino),' backgrounds de treino\n',sep='')
  for (sp in especies) {
    val_pres <- pres[pres$fold_cv==f & pres$especie==sp,,drop=FALSE]
    for (v in continuas) {
      kf <- kf+1L
      linhas_fold[[kf]] <- cbind(data.frame(especie=sp,fold_cv=f),
                                   calcular(val_pres,val_bg,treino,v))
    }
    props <- unique(as.character(val_bg$propriedade))
    for (propr in props) {
      p_pro <- val_pres[val_pres$propriedade==propr,,drop=FALSE]
      b_pro <- val_bg[val_bg$propriedade==propr,,drop=FALSE]
      for (v in continuas) {
        kp <- kp+1L
        linhas_prop[[kp]] <- cbind(data.frame(especie=sp,fold_cv=f,
                  propriedade=propr),calcular(p_pro,b_pro,treino,v))
      }
      upas <- unique(as.character(b_pro$upa_id))
      for (upa in upas) {
        p_u <- p_pro[p_pro$upa_id==upa,,drop=FALSE]
        b_u <- b_pro[b_pro$upa_id==upa,,drop=FALSE]
        for (v in continuas) {
          ku <- ku+1L
          linhas_upa[[ku]] <- cbind(data.frame(especie=sp,fold_cv=f,
             propriedade=propr,upa_id=upa),calcular(p_u,b_u,treino,v))
        }
      }
    }
  }
}
tabela_fold <- do.call(rbind,linhas_fold)
tabela_prop <- do.call(rbind,linhas_prop)
tabela_upa <- do.call(rbind,linhas_upa)
rownames(tabela_fold) <- rownames(tabela_prop) <- rownames(tabela_upa) <- NULL
if (nrow(tabela_fold)!=30L || nrow(tabela_prop)!=270L ||
    nrow(tabela_upa)!=640L)
  stop('Erro na quantidade de combinacoes: 30 folds, 270 propriedades, 640 UPAs.')

# 2. Confronto com os resultados do R20 (recuperacao independente de novidade).
chave <- function(d) paste(d$especie,d$fold_cv,d$variavel,sep='||')
if (nrow(r20_uni)!=30L || anyDuplicated(chave(r20_uni)) ||
    !setequal(chave(r20_uni),chave(tabela_fold)))
  stop('R20 e R21 usam conjuntos diferentes de especie/fold/variavel.')
i <- match(chave(tabela_fold),chave(r20_uni))
if (any(tabela_fold$n_pres_fora_treino!=r20_uni$n_presencas_fora[i]) ||
    any(tabela_fold$n_bg_local_fora_treino!=r20_uni$n_background_fora[i]))
  stop('Recontagem de novidade univariada R21 NAO reproduz R20. Nao gravar resultados.')
# Mesmo conjunto de UPAs e mesma distribuicao de BG.
a <- paste(par$propriedade,par$upa_id,par$fold_cv,sep='||')
b <- paste(r20_upa$propriedade,r20_upa$upa_id,r20_upa$fold_cv,sep='||')
if (anyDuplicated(b) || !setequal(a,b))
  stop('UPAs B2 nao correspondem a lista original do R20.')
q_i <- match(a,b)
bg_upa <- vapply(seq_len(nrow(par)),function(j)
  sum(bg$propriedade==par$propriedade[j] & bg$upa_id==par$upa_id[j]),integer(1))
if (any(bg_upa!=r20_upa$n_background_b2[q_i]))
  stop('Cotas de background por UPA divergem do R20.')
# A contagem de presencas de cada especie deve continuar identica ao R20.
np_roxo <- vapply(seq_len(nrow(par)),function(j)
  sum(pres$propriedade==par$propriedade[j] &
      pres$upa_id==par$upa_id[j] & pres$especie=='Ipe-roxo'),integer(1))
np_amarelo <- vapply(seq_len(nrow(par)),function(j)
  sum(pres$propriedade==par$propriedade[j] &
      pres$upa_id==par$upa_id[j] & pres$especie=='Ipe-amarelo'),integer(1))
if (any(np_roxo!=r20_upa$n_roxo[q_i]) ||
    any(np_amarelo!=r20_upa$n_amarelo[q_i]))
  stop('Contagem das especies por UPA diverge do R20.')

# 3. Separacao BIO12/BIO17: novidade individual e conjunta (baixo ou alto).
novo_clima <- list(); kc <- 0L
for (f in 1:3) {
  treino <- bg[bg$fold_cv!=f,,drop=FALSE]
  lim <- list(bio12=range(treino$bio12_mm_ano),
              bio17=range(treino$bio17_mm_mes))
  for (sp in especies) for (propr in unique(bg$propriedade[bg$fold_cv==f])) {
    p0 <- pres[pres$fold_cv==f & pres$especie==sp &
                pres$propriedade==propr,,drop=FALSE]
    b0 <- bg[bg$fold_cv==f & bg$propriedade==propr,,drop=FALSE]
    for (gran in c('PROPRIEDADE','UPA')) {
      upas <- if(gran=='PROPRIEDADE') NA_character_ else unique(b0$upa_id)
      for (upa in upas) {
        p <- if(gran=='PROPRIEDADE') p0 else p0[p0$upa_id==upa,,drop=FALSE]
        b <- if(gran=='PROPRIEDADE') b0 else b0[b0$upa_id==upa,,drop=FALSE]
        flags <- function(d) {
          lo12 <- d$bio12_mm_ano<lim$bio12[1]
          hi12 <- d$bio12_mm_ano>lim$bio12[2]
          lo17 <- d$bio17_mm_mes<lim$bio17[1]
          hi17 <- d$bio17_mm_mes>lim$bio17[2]
          list(ambos=(lo12|hi12)&(lo17|hi17),
               qualquer=lo12|hi12|lo17|hi17,
               ambos_abaixo=lo12&lo17,ambos_acima=hi12&hi17,
               ambos_sentidos_opostos=(lo12&hi17)|(hi12&lo17))
        }
        z <- flags(p); zb <- flags(b)
        kc <- kc+1L
        novo_clima[[kc]] <- data.frame(especie=sp,fold_cv=f,
          escala=gran,propriedade=propr,upa_id=upa,
          n_presencas=nrow(p),n_background=nrow(b),
          n_pres_fora_bio12_e_bio17=sum(z$ambos),
          prop_pres_fora_bio12_e_bio17=prop(z$ambos),
          prop_pres_fora_bio12_ou_bio17=prop(z$qualquer),
          prop_pres_ambos_abaixo=prop(z$ambos_abaixo),
          prop_pres_ambos_acima=prop(z$ambos_acima),
          prop_pres_ambos_sentidos_opostos=prop(z$ambos_sentidos_opostos),
          prop_bg_fora_bio12_e_bio17=prop(zb$ambos),
          prop_bg_fora_bio12_ou_bio17=prop(zb$qualquer),
          stringsAsFactors=FALSE)
      }
    }
  }
}
tabela_clima <- do.call(rbind,novo_clima)
rownames(tabela_clima) <- NULL

# 4. Correlacao climatica de contexto, NAO usada para excluir preditores.
correlacoes <- list(); kn <- 0L
cor_segura <- function(a,b,metodo) {
  if(length(a)<3L || sd(a)==0 || sd(b)==0) return(NA_real_)
  stats::cor(a,b,method=metodo)
}
for (f in 1:3) {
  datasets <- list(bg_treino=bg[bg$fold_cv!=f,,drop=FALSE],
                   bg_validacao=bg[bg$fold_cv==f,,drop=FALSE],
                   pres_roxo=pres[pres$fold_cv==f & pres$especie=='Ipe-roxo',,drop=FALSE],
                   pres_amarelo=pres[pres$fold_cv==f & pres$especie=='Ipe-amarelo',,drop=FALSE])
  for (nm in names(datasets)) {
    z <- datasets[[nm]]
    kn <- kn+1L
    correlacoes[[kn]] <- data.frame(fold_cv=f,conjunto=nm,n=nrow(z),
      pearson_bio12_bio17=cor_segura(z$bio12_mm_ano,z$bio17_mm_mes,'pearson'),
      spearman_bio12_bio17=cor_segura(z$bio12_mm_ano,z$bio17_mm_mes,'spearman'))
  }
}
tabela_cor <- do.call(rbind,correlacoes)

# 5. Frequencias de textura em treino e validacao, sem chamar background ausencia.
solos <- list(); ks <- 0L
niveis <- sort(unique(as.character(c(pres$textura_subgrupo,bg$textura_subgrupo))))
for (f in 1:3) for (sp in especies) {
  conjuntos <- list(background_treino=bg[bg$fold_cv!=f,,drop=FALSE],
      background_validacao=bg[bg$fold_cv==f,,drop=FALSE],
      presencas_validacao=pres[pres$fold_cv==f & pres$especie==sp,,drop=FALSE])
  for (nm in names(conjuntos)) {
    z <- conjuntos[[nm]]
    for (n in niveis) {
      ks <- ks+1L
      solos[[ks]] <- data.frame(especie=sp,fold_cv=f,conjunto=nm,
        classe_textura=n,n=sum(as.character(z$textura_subgrupo)==n),
        percentual=100*mean(as.character(z$textura_subgrupo)==n))
    }
  }
}
tabela_solo <- do.call(rbind,solos)

# 6. Gravar arquivos apenas depois de verificar todas as fontes e contagens.
saida <- file.path(pasta_res,'19 - Contrastes ambientais R21 V1')
if (dir.exists(saida))
  stop('A pasta R21 ja existe; para nao sobrescrever, preserve o resultado e ',
       'renomeie/mova a pasta anterior se for uma nova execucao: ',saida)
dir.create(saida,recursive=TRUE,showWarnings=FALSE)
gdir <- file.path(saida,'21_GRAFICOS')
dir.create(gdir,showWarnings=FALSE)
gravar <- function(d,nome) utils::write.csv(d,file.path(saida,nome),
                                  row.names=FALSE,fileEncoding='UTF-8')
gravar(tabela_fold,'21_CONTRASTES_POR_FOLD.csv')
gravar(tabela_prop,'21_CONTRASTES_POR_PROPRIEDADE.csv')
gravar(tabela_upa,'21_CONTRASTES_POR_UPA.csv')
gravar(tabela_clima,'21_NOVIDADE_CONJUNTA_BIO12_BIO17.csv')
gravar(tabela_cor,'21_CORRELACOES_BIO12_BIO17.csv')
gravar(tabela_solo,'21_DISTRIBUICAO_SOLO.csv')
fontes <- data.frame(nome=c('19_METRICAS_72_MODELOS_B2.csv',
  '19_MANIFESTO_ENTRADAS.csv','05_PRESENCAS_UM_POR_PIXEL_30M.csv',
  '18_BACKGROUND_B2_10000_COM_FOLDS.csv','20_NOVIDADE_UNIVARIADA.csv',
  '20_ESFORCO_POR_UPA.csv','20_NN_POR_PROPRIEDADE.csv'),
  md5=vapply(c(arq_metricas,manifesto_arq,pres_arq,b2_arq,r20_uni_arq,
               r20_upa_arq,r20_nn_arq),md5,character(1)),
  stringsAsFactors=FALSE)
gravar(fontes,'21_MANIFESTO_FONTES.csv')

# 7. Graficos: SUBAMOSTRAGEM SOMENTE NA VISUALIZACAO; nenhuma metrica usa amostra.
desenhar_clima <- function(sp,f,sigla) {
  bt <- bg[bg$fold_cv!=f,,drop=FALSE]
  bv <- bg[bg$fold_cv==f,,drop=FALSE]
  p <- pres[pres$fold_cv==f & pres$especie==sp,,drop=FALSE]
  set.seed(20261121+f)
  if(nrow(bt)>1800L) bt <- bt[sample.int(nrow(bt),1800L),,drop=FALSE]
  if(nrow(bv)>1500L) bv <- bv[sample.int(nrow(bv),1500L),,drop=FALSE]
  grDevices::png(file.path(gdir,paste0('21_',sigla,'_F',f,'_PLANO_CLIMATICO.png')),
                 width=1350,height=940,res=130)
  graphics::par(mar=c(5,5,4,2))
  faixa_x <- range(c(bt$bio12_mm_ano,bv$bio12_mm_ano,p$bio12_mm_ano))
  faixa_y <- range(c(bt$bio17_mm_mes,bv$bio17_mm_mes,p$bio17_mm_mes))
  graphics::plot(bt$bio12_mm_ano,bt$bio17_mm_mes,pch=16,cex=.6,
    col=grDevices::adjustcolor('gray55',alpha.f=.26),xlim=faixa_x,ylim=faixa_y,
    xlab='BIO12 (bio12_mm_ano)',ylab='BIO17 (bio17_mm_mes)',
    main=paste('R21 -',sp,'Fold',f,'| ambiente e presencas'))
  graphics::points(bv$bio12_mm_ano,bv$bio17_mm_mes,pch=16,cex=.6,
    col=grDevices::adjustcolor('#d18a22',alpha.f=.38))
  graphics::points(p$bio12_mm_ano,p$bio17_mm_mes,pch=16,cex=.7,
    col=grDevices::adjustcolor('#2d669e',alpha.f=.47))
  graphics::legend('topright',legend=c('Background treino (amostra grafica)',
    'Background validacao (amostra grafica)','Presencas validacao'),
    pch=16,col=c('gray55','#d18a22','#2d669e'),bty='n',cex=.85)
  grDevices::dev.off()
}
desenhar_propriedades <- function(sp,f,sigla,variavel) {
  z <- tabela_prop[tabela_prop$especie==sp & tabela_prop$fold_cv==f &
                    tabela_prop$variavel==variavel,,drop=FALSE]
  z <- z[order(z$propriedade),,drop=FALSE]
  n <- nrow(z)
  grDevices::png(file.path(gdir,paste0('21_',sigla,'_F',f,'_',
          toupper(variavel),'_PROPRIEDADES.png')),
          width=1400,height=max(600L,230L+100L*n),res=130)
  graphics::par(mar=c(5,15,4,2))
  v <- c(z$background_local_mediana,z$pres_mediana,z$treino_min,z$treino_max)
  v <- v[is.finite(v)]
  graphics::plot(NA,xlim=range(v),ylim=c(.5,n+.5),yaxt='n',
    xlab=variavel,ylab='',main=paste('R21 -',sp,'Fold',f,'|',variavel))
  graphics::axis(2,at=seq_len(n),labels=z$propriedade,las=2,cex.axis=.80)
  graphics::abline(v=c(z$treino_min[1],z$treino_max[1]),lty=2,col='gray50')
  graphics::points(z$background_local_mediana,seq_len(n),pch=15,
                   col='gray45',cex=1.2)
  graphics::points(z$pres_mediana,seq_len(n),pch=16,
                   col='#2d669e',cex=1.35)
  graphics::legend('topleft',legend=c('Mediana background local',
                   'Mediana presencas','Min/max background treino'),
                   pch=c(15,16,NA),lty=c(NA,NA,2),
                   col=c('gray45','#2d669e','gray50'),bty='n',cex=.85)
  grDevices::dev.off()
}
for (e in list(list(sp='Ipe-amarelo',f=2,sigla='AMARELO'),
               list(sp='Ipe-roxo',f=3,sigla='ROXO'))) {
  desenhar_clima(e$sp,e$f,e$sigla)
  for (v in c('bio12_mm_ano','bio17_mm_mes'))
    desenhar_propriedades(e$sp,e$f,e$sigla,v)
}

# 8. Relatorio sucinto e plano experimental (nao seleciona vencedor).
rel <- c(paste('TCC IPES -',versao_r21),
  paste('Executado:',as.character(Sys.time())),
  'R21 DIAGNOSTICO AMBIENTAL. NAO ajusta novos modelos.',
  paste('Presencas de desenvolvimento:',nrow(pres)),
  paste('Background B2:',nrow(bg)),
  paste('Propriedades:',length(unique(bg$propriedade))),
  paste('UPAs inventariadas:',nrow(par)),
  paste('Confronto com R20: 30 contagens de novidade univariada conferidas.'),
  'IMPORTANTE: referencias ambientais de cada fold sao somente B2 de TREINO.',
  'AUC global/local e scores pertencem ao R20: nao foram recalculados no R21.',
  'BIO17 e apresentado com o nome da coluna de origem (bio17_mm_mes).',
  'Faixa minimo-maximo: diagnostico univariado, nao MESS/MOP.',
  'Por propriedade/UPA ha contrastes de presenca vs background local:',
  'isso NAO equivale a ausencia verdadeira ou demonstracao causal.',
  'Percentuais NA ocorrem quando nao existem presencas daquela especie na UPA.',
  'Medianas para grupos com <10 registros devem ser interpretadas com cautela.',
  'Os graficos usam amostras para legibilidade; tabelas usam TODOS os pontos.',
  'As sete propriedades de teste externo permanecem reservadas.',
  '', 'PROXIMA DECISAO (APOS AUDITORIA DO R21):',
  'Confrontar BIO12/BIO17 por propriedade e UPA e decidir ablacoes controladas.',
  'Candidatos para experimentacao futura: 6 variaveis; sem BIO12;',
  'sem BIO17; sem BIO12 e BIO17; sem altitude; sem textura.',
  'Manter folds e background B2 iguais em todas as comparacoes.',
  'Nenhum conjunto de preditores e aprovado automaticamente.',
  paste('Saida:',saida))
# Registro dos resultados-chave obtidos nesta execucao, sem inferir causalidade.
for (caso in list(list(especie='Ipe-amarelo',f=2),
                  list(especie='Ipe-roxo',f=3))) {
  rel <- c(rel,'',paste('CASO:',caso$especie,'fold',caso$f))
  for (nm in c('bio12_mm_ano','bio17_mm_mes')) {
    z <- tabela_fold[tabela_fold$especie==caso$especie &
      tabela_fold$fold_cv==caso$f & tabela_fold$variavel==nm,,drop=FALSE]
    rel <- c(rel,sprintf('%s: %.2f%% das presencas abaixo do minimo; %.2f%% acima do maximo do background de treino.',
      nm,100*z$prop_pres_abaixo_min_treino,100*z$prop_pres_acima_max_treino))
  }
  z <- tabela_clima[tabela_clima$especie==caso$especie &
        tabela_clima$fold_cv==caso$f &
        tabela_clima$escala=='PROPRIEDADE',,drop=FALSE]
  z <- z[order(-z$n_presencas),,drop=FALSE]
  for(j in seq_len(nrow(z))) if(z$n_presencas[j]>0L) {
    rel <- c(rel,sprintf('%s: %d presencas, %.2f%% fora de BIO12 e BIO17 simultaneamente.',
      z$propriedade[j],z$n_presencas[j],100*z$prop_pres_fora_bio12_e_bio17[j]))
  }
}
writeLines(rel,file.path(saida,'21_RELATORIO_DE_LEITURA.txt'),useBytes=TRUE)
writeLines(capture.output(utils::sessionInfo()),
           file.path(saida,'21_SESSION_INFO.txt'),useBytes=TRUE)
cat('\nR21 CONCLUIDO. Arquivos em:\n',saida,'\n',sep='')
