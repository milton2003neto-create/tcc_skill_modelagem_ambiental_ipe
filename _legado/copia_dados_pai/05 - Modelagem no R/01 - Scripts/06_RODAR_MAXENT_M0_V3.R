# TCC - IPES | R06 V3 M0 - Primeiro experimento de MaxEnt (maxnet)
# Versao 3.2: corrigido Boyce (ecospat retorna $cor nas versoes recentes).
# Reaproveita previsoes existentes para atualizar Boyce SEM recalibrar os seis modelos,
# ou executa normalmente M0 completo quando a pasta de resultados ainda nao existe.
# 11/11/2026. Referencia: relatorio-sintese V3 e auditoria R05 V3.1.
# Ajusta APENAS 6 modelos de validacao (2 especies x 3 folds).
# NAO acessa as 7 propriedades externas de TESTE; NAO escolhe parametros pelo TESTE.
# Preditores: altitude, declividade, distancia raster a rios, BIO12, BIO17,
# e textura de solo (CATEGORICA). Features LQ, multiplicador de regularizacao 2.
# Avaliacao por fold: AUC contra background do proprio fold, omissao 10% baseada
# no treino, n. de coeficientes ativos, e indice de Boyce (ecospat obrigatorio).
# Os modelos salvos nesta fase sao EXPLORATORIOS, nao modelos finais do TCC.

if (!requireNamespace('maxnet', quietly=TRUE)) {
  stop("Pacote 'maxnet' ausente. No Console execute install.packages('maxnet') e rode novamente.")
}
if (!requireNamespace('ecospat', quietly=TRUE)) {
  stop("Pacote 'ecospat' ausente. No Console execute install.packages('ecospat') e rode novamente. Boyce e obrigatorio nesta versao.")
}
cat('\nR06 V3 M0 - selecione 05_PRESENCAS_UM_POR_PIXEL_30M.csv (saida do R05).\n')
arq <- normalizePath(file.choose(), winslash='/', mustWork=TRUE)
if (basename(arq)!='05_PRESENCAS_UM_POR_PIXEL_30M.csv') {
  stop('Arquivo incorreto. Selecione 05_PRESENCAS_UM_POR_PIXEL_30M.csv.')
}
entrada <- dirname(arq)
if (basename(entrada)!='04 - Presencas e folds V3') {
  stop('O CSV deve estar na pasta oficial 04 - Presencas e folds V3.')
}
raiz <- dirname(dirname(entrada))
if (basename(dirname(entrada))!='04 - Dados para o MaxEnt' ||
    !dir.exists(file.path(raiz,'03 - Trabalho no QGIS'))) {
  stop('Estrutura oficial do TCC nao encontrada. Verifique o local do arquivo selecionado.')
}
saida <- file.path(raiz,'06 - Resultados','04 - MaxEnt M0 - Validacao espacial V3')

arq_bg <- file.path(entrada,'05_BACKGROUND_COM_FOLDS.csv')
arq_todas <- file.path(entrada,'05_PRESENCAS_TODAS_DESENVOLVIMENTO.csv')
arq_resumo <- file.path(entrada,'05_RESUMO_FOLDS.csv')
for (caminho in c(arq_bg,arq_todas,arq_resumo)) {
  if (!file.exists(caminho)) stop('Entrada obrigatoria ausente: ',caminho)
}
ler <- function(f) read.csv(f,fileEncoding='UTF-8-BOM',stringsAsFactors=FALSE,check.names=FALSE)
pres <- ler(arq)
bg <- ler(arq_bg)
todas <- ler(arq_todas)
resumo_05 <- ler(arq_resumo)
vars_cont <- c('altitude_m','declividade_graus','dist_rio_raster_m',
               'bio12_mm_ano','bio17_mm_mes')
vars <- c(vars_cont,'textura_subgrupo')
requer_pres <- c('especie','propriedade','upa_id','fold_cv','celula_raster',vars)
requer_bg <- c('propriedade','upa_id','fold_cv','celula_raster','id_background',vars)
if (!all(requer_pres %in% names(pres)) || !all(requer_bg %in% names(bg))) {
  stop('Campos de entrada incompletos. Confirme que os arquivos vieram do R05 V3.1.')
}
if (nrow(pres)!=8680 || nrow(bg)!=5000 || nrow(todas)!=9004 ||
    sum(pres$especie=='Ipe-roxo')!=3248 ||
    sum(pres$especie=='Ipe-amarelo')!=5432 ||
    !setequal(unique(pres$especie),c('Ipe-roxo','Ipe-amarelo'))) {
  stop('Contagens da preparacao R05 diferentes das aprovadas na auditoria.')
}
if (anyNA(pres[,requer_pres,drop=FALSE]) || anyNA(bg[,requer_bg,drop=FALSE]) ||
    any(!is.finite(as.matrix(pres[,vars,drop=FALSE]))) ||
    any(!is.finite(as.matrix(bg[,vars,drop=FALSE])))) {
  stop('Valores ausentes, nao finitos ou invalidos nos preditores/identificadores.')
}
if (!setequal(unique(pres$propriedade),unique(bg$propriedade)) ||
    length(unique(bg$propriedade))!=27 || length(unique(bg$upa_id))!=64 ||
    any(!pres$fold_cv %in% 1:3) || any(!bg$fold_cv %in% 1:3) ||
    anyDuplicated(paste(pres$propriedade,pres$especie,pres$celula_raster,sep='|')) ||
    anyDuplicated(paste(bg$propriedade,bg$celula_raster,sep='|')) ||
    anyDuplicated(bg$id_background)) {
  stop('Erro de particao, folds ou duplicidade nos arquivos do R05.')
}
externas <- c('BARRO BRANCO','CURUÇA','GUARIÚBA','JATOBÁ',
              'LOTE 01','MARILIA','PALMEIRA')
if (any(pres$propriedade %in% externas) || any(bg$propriedade %in% externas)) {
  stop('Vazamento de propriedades de TESTE externo: modelagem interrompida.')
}
folds_props <- rbind(unique(pres[,c('propriedade','fold_cv')]),
                     unique(bg[,c('propriedade','fold_cv')]))
if (any(tapply(folds_props$fold_cv,folds_props$propriedade,
               function(x) length(unique(x))) != 1L)) {
  stop('A mesma propriedade aparece em folds diferentes.')
}
if (nrow(resumo_05)!=6 ||
    !all(c('especie','fold_cv','n_presencas_pixel_30m','n_background') %in% names(resumo_05))) {
  stop('Resumo do R05 ausente/incompleto.')
}
for (sp in c('Ipe-roxo','Ipe-amarelo')) for (f in 1:3) {
  linha <- resumo_05[resumo_05$especie==sp & resumo_05$fold_cv==f,,drop=FALSE]
  if (nrow(linha)!=1 ||
      linha$n_presencas_pixel_30m!=sum(pres$especie==sp & pres$fold_cv==f) ||
      linha$n_background!=sum(bg$fold_cv==f)) {
    stop('Contagens por fold divergem da auditoria R05: ',sp,' fold ',f)
  }
}
# Background compartilhado pelos dois modelos. Solo sempre tratado como FATOR.
classes_solo <- sort(unique(c(pres$textura_subgrupo,bg$textura_subgrupo)))
if (!identical(as.integer(classes_solo),c(2L,3L,4L,6L,7L))) {
  stop('Classes de solo inesperadas para o protocolo V3.')
}
preparar_x <- function(df) {
  x <- df[,vars,drop=FALSE]
  for (nm in vars_cont) x[[nm]] <- as.numeric(x[[nm]])
  x$textura_subgrupo <- factor(as.character(x$textura_subgrupo),
                               levels=as.character(classes_solo))
  if (anyNA(x)) stop('Categoria ausente ao montar a matriz preditora.')
  x
}
# AUC presenca versus background, Mann-Whitney com tratamento de empates.
auc_pb <- function(s_pres,s_bg) {
  a <- as.numeric(s_pres); b <- as.numeric(s_bg)
  if (!length(a) || !length(b) || any(!is.finite(c(a,b)))) return(NA_real_)
  pos <- seq_along(a)
  rk <- rank(c(a,b),ties.method='average')
  (sum(rk[pos])-length(a)*(length(a)+1)/2)/(length(a)*length(b))
}
# Boyce continuo na validacao: presencas vs background DO MESMO FOLD.
# Versoes do ecospat podem expor o coeficiente como $cor ou $Spearman.cor.
# Se o indice for matematicamente indefinido, registrar a razao; nunca NA silencioso.
indice_boyce <- function(s_pres,s_bg,especie,fold_cv) {
  a <- as.numeric(s_pres); b <- as.numeric(s_bg)
  id <- paste(especie,'fold',fold_cv)
  if (length(a)<2L || length(b)<2L || any(!is.finite(c(a,b)))) {
    msg <- 'INDEFINIDO: scores ausentes, nao finitos ou insuficientes'
    warning('[R06 BOYCE] ',id,' - ',msg)
    return(list(valor=NA_real_,status=msg))
  }
  avisos <- character()
  z <- tryCatch(withCallingHandlers(
    ecospat::ecospat.boyce(fit=b,obs=a,nclass=0,PEplot=FALSE,
                           method='spearman',rm.duplicate=TRUE),
    warning=function(w) {
      avisos <<- c(avisos,conditionMessage(w))
      invokeRestart('muffleWarning')
    }),error=function(e) {
      avisos <<- c(avisos,paste('ERRO:',conditionMessage(e)))
      NULL
    })
  v <- NA_real_
  campo <- 'nao_encontrado'
  if (is.list(z)) {
    if (!is.null(z$cor)) {
      campo <- 'cor'; v <- suppressWarnings(as.numeric(z$cor))
    } else if (!is.null(z$Spearman.cor)) {
      campo <- 'Spearman.cor'
      v <- suppressWarnings(as.numeric(z$Spearman.cor))
    }
  } else if (is.numeric(z) && length(z)==1L) {
    campo <- 'valor_numerico'; v <- as.numeric(z)
  }
  if (length(v)!=1L || !is.finite(v) || v < -1.000001 || v > 1.000001) {
    motivo <- if (length(avisos)) paste(unique(avisos),collapse=' | ') else
      'coeficiente indefinido, ausente ou fora de [-1,1]'
    msg <- paste('INDEFINIDO:',motivo,'(campo:',campo,')')
    warning('[R06 BOYCE] ',id,' - ',msg)
    return(list(valor=NA_real_,status=msg))
  }
  status <- if (length(avisos)) {
    paste('CALCULADO COM AVISO:',paste(unique(avisos),collapse=' | '))
  } else 'OK'
  cat(sprintf('[R06 BOYCE] %s: %.3f (%s)\n',id,v,campo))
  list(valor=v,status=status)
}
# Media aritmetica entre folds, sem ponderar pelo numero de arvores.
resumir_metricas <- function(metricas) {
  do.call(rbind,lapply(split(metricas,metricas$especie),function(x) {
    vb <- x$indice_boyce_validacao[is.finite(x$indice_boyce_validacao)]
    data.frame(especie=x$especie[1],
      auc_validacao_media=mean(x$auc_validacao_vs_bg_validacao),
      auc_validacao_desvio_padrao=sd(x$auc_validacao_vs_bg_validacao),
      omissao10_validacao_media=mean(x$omissao10_validacao),
      omissao10_validacao_desvio_padrao=sd(x$omissao10_validacao),
      boyce_validacao_media=if(length(vb)) mean(vb) else NA_real_,
      boyce_validacao_desvio_padrao=if(length(vb)>1L) sd(vb) else NA_real_,
      n_folds_boyce_validos=length(vb),n_folds=nrow(x))
  }))
}
# Diagnostico exploratorio: valores fora do min-max do BACKGROUND de treino.
# Nao confundir com MESS, MOP ou teste formal de autocorrelacao.
novidade_fold <- function(sp,f,pval,bval,btrain) {
  do.call(rbind,lapply(vars_cont,function(nm) {
    lo <- min(btrain[[nm]]); hi <- max(btrain[[nm]])
    data.frame(especie=sp,fold_cv=f,variavel=nm,
      minimo_bg_treino=lo,maximo_bg_treino=hi,
      n_presenca_validacao=nrow(pval),
      n_presenca_fora_minmax=sum(pval[[nm]]<lo | pval[[nm]]>hi),
      prop_presenca_fora_minmax=mean(pval[[nm]]<lo | pval[[nm]]>hi),
      n_background_validacao=nrow(bval),
      n_background_fora_minmax=sum(bval[[nm]]<lo | bval[[nm]]>hi),
      prop_background_fora_minmax=mean(bval[[nm]]<lo | bval[[nm]]>hi))
  }))
}

# Se o R06 ja foi executado, reaproveitar previsoes para CORRIGIR o Boyce
# nos CSVs existentes. Os seis arquivos .rds NAO sao recalibrados nem alterados.
# Backup permanente dos CSVs de metricas/resumo antes de qualquer atualizacao.
if (dir.exists(saida)) {
  cat('\n[R06 V3.2] Resultado M0 ja existe. Corrigindo Boyce nas previsoes existentes, sem refazer modelos.\n')
  caminho_m <- file.path(saida,'06_METRICAS_FOLDS_M0.csv')
  caminho_p <- file.path(saida,'06_PREDICOES_VALIDACAO_M0.csv')
  caminho_r <- file.path(saida,'06_RESUMO_ESPECIES_M0.csv')
  modelos <- list.files(saida,pattern='^06_MODELO_(ROXO|AMARELO)_M0_LQ_RM2_F[123]\\.rds$',full.names=TRUE)
  if (!all(file.exists(c(caminho_m,caminho_p,caminho_r))) || length(modelos)!=6L) {
    stop('Saida existente esta incompleta. Preserve-a e confira os seis modelos, metricas e previsoes antes de prosseguir.')
  }
  met <- ler(caminho_m); pred <- ler(caminho_p)
  cols_m <- c('especie','fold_cv','n_presenca_validacao','n_background_validacao',
              'auc_validacao_vs_bg_validacao','omissao10_validacao',
              'limiar10_treino_cloglog','indice_boyce_validacao')
  cols_p <- c('especie','fold_cv','tipo','propriedade','score_cloglog')
  if (!all(cols_m %in% names(met)) || !all(cols_p %in% names(pred)) ||
      nrow(met)!=6L || nrow(pred)!=18680L ||
      anyNA(pred[,cols_p,drop=FALSE]) ||
      any(!is.finite(pred$score_cloglog)) ||
      any(pred$score_cloglog<0 | pred$score_cloglog>1) ||
      anyDuplicated(paste(met$especie,met$fold_cv,sep='|')) ||
      !setequal(unique(met$especie),c('Ipe-roxo','Ipe-amarelo')) ||
      !setequal(unique(met$fold_cv),1:3) ||
      !setequal(unique(pred$tipo),c('PRESENCA_VALIDACAO','BACKGROUND_VALIDACAO')) ||
      any(pred$propriedade %in% externas)) {
    stop('CSV existente nao corresponde ao M0 auditado: nao atualizei nada.')
  }
  met$status_boyce_validacao <- rep(NA_character_,nrow(met))
  for (ix in seq_len(nrow(met))) {
    x <- met[ix,,drop=FALSE]
    ped <- pred[pred$especie==x$especie & pred$fold_cv==x$fold_cv,,drop=FALSE]
    pa <- ped$score_cloglog[ped$tipo=='PRESENCA_VALIDACAO']
    pb <- ped$score_cloglog[ped$tipo=='BACKGROUND_VALIDACAO']
    if (length(pa)!=x$n_presenca_validacao || length(pb)!=x$n_background_validacao ||
        abs(auc_pb(pa,pb)-x$auc_validacao_vs_bg_validacao)>1e-8 ||
        abs(mean(pa < x$limiar10_treino_cloglog)-x$omissao10_validacao)>1e-8) {
      stop('AUC, omissao ou tamanho do fold nao conferem: ',x$especie,' fold ',x$fold_cv,
           '. Nenhum CSV foi atualizado.')
    }
    boyce <- indice_boyce(pa,pb,x$especie,x$fold_cv)
    met$indice_boyce_validacao[ix] <- boyce$valor
    met$status_boyce_validacao[ix] <- boyce$status
  }
  resumo_novo <- resumir_metricas(met)
  bk_m <- file.path(saida,'06_METRICAS_FOLDS_M0_BACKUP_ANTES_BOYCE_V3_2.csv')
  bk_r <- file.path(saida,'06_RESUMO_ESPECIES_M0_BACKUP_ANTES_BOYCE_V3_2.csv')
  if (!file.exists(bk_m) && !file.copy(caminho_m,bk_m,overwrite=FALSE)) {
    stop('Nao foi possivel preservar backup das metricas: ',bk_m)
  }
  if (!file.exists(bk_r) && !file.copy(caminho_r,bk_r,overwrite=FALSE)) {
    stop('Nao foi possivel preservar backup do resumo: ',bk_r)
  }
  write.csv(met,caminho_m,row.names=FALSE,fileEncoding='UTF-8')
  write.csv(resumo_novo,caminho_r,row.names=FALSE,fileEncoding='UTF-8')
  writeLines(c('TCC IPES R06 V3.2 - CORRECAO INCORPORADA DO INDICE DE BOYCE',
    'Previsoes existentes reutilizadas: nenhum maxnet recalibrado.',
    'Boyce calculado com ecospat.boyce e background do fold de validacao.',
    'Campos aceitos: $cor ou $Spearman.cor, conforme versao instalada.',
    'Metricas AUC e omissao anteriores foram revalidadas sem alteracao.',
    'CSV de metricas e resumo preservados em backup antes da primeira atualizacao.',
    'Resultados externos de teste nao utilizados.',
    paste('ecospat:',as.character(utils::packageVersion('ecospat'))),
    paste('Data da atualizacao:',as.character(Sys.time()))),
    file.path(saida,'06_BOYCE_CORRIGIDO_INTEGRADO_AO_R06_V3_2.txt'),useBytes=TRUE)
  cat('\n[R06 V3.2] FINALIZADO: Boyce incorporado a 06_METRICAS_FOLDS_M0.csv\n')
  print(met[,c('especie','fold_cv','indice_boyce_validacao','status_boyce_validacao')])
} else {
# TODAS as verificacoes essenciais precedem a escrita das saidas.
dir.create(saida,recursive=TRUE,showWarnings=FALSE)
if (!dir.exists(saida)) stop('Nao consegui criar a pasta de resultados.')
set.seed(20261111)
metricas <- list(); novidades <- list(); predicoes <- list()
i <- 0L; j <- 0L; k <- 0L
for (sp in c('Ipe-roxo','Ipe-amarelo')) {
  for (f in 1:3) {
    treino_pres <- pres[pres$especie==sp & pres$fold_cv!=f,,drop=FALSE]
    valid_pres <- pres[pres$especie==sp & pres$fold_cv==f,,drop=FALSE]
    treino_bg <- bg[bg$fold_cv!=f,,drop=FALSE]
    valid_bg <- bg[bg$fold_cv==f,,drop=FALSE]
    if (min(nrow(treino_pres),nrow(valid_pres),nrow(treino_bg),nrow(valid_bg))<100L) {
      stop('Fold com amostra insuficiente: ',sp,' / ',f)
    }
    treino <- preparar_x(rbind(treino_pres[,vars,drop=FALSE],
                              treino_bg[,vars,drop=FALSE]))
    y <- c(rep(1L,nrow(treino_pres)),rep(0L,nrow(treino_bg)))
    xvp <- preparar_x(valid_pres)
    xvb <- preparar_x(valid_bg)
    # Validacao: categorias do fold devem estar representadas no treino.
    treino_cats <- unique(c(as.character(treino_pres$textura_subgrupo),
                             as.character(treino_bg$textura_subgrupo)))
    val_cats <- unique(c(as.character(valid_pres$textura_subgrupo),
                          as.character(valid_bg$textura_subgrupo)))
    if (!all(val_cats %in% treino_cats)) {
      stop('Categoria de solo inedita no fold ',f,' para ',sp,'. Interrompendo.')
    }
    cat(sprintf('\n[R06] Ajustando %s - fold de validacao %d: treino %d presencas + %d BG | validacao %d presencas + %d BG\n',
                sp,f,nrow(treino_pres),nrow(treino_bg),nrow(valid_pres),nrow(valid_bg)))
    formula_lq <- maxnet::maxnet.formula(y,treino,classes='lq')
    modelo <- maxnet::maxnet(y,treino,f=formula_lq,regmult=2,
                             addsamplestobackground=TRUE)
    sc_tp <- as.numeric(predict(modelo,preparar_x(treino_pres),
                                type='cloglog',clamp=TRUE))
    sc_tb <- as.numeric(predict(modelo,preparar_x(treino_bg),
                                type='cloglog',clamp=TRUE))
    sc_vp <- as.numeric(predict(modelo,xvp,type='cloglog',clamp=TRUE))
    sc_vb <- as.numeric(predict(modelo,xvb,type='cloglog',clamp=TRUE))
    if (any(!is.finite(c(sc_tp,sc_tb,sc_vp,sc_vb)))) {
      stop('Maxnet gerou previsoes nao finitas para ',sp,' fold ',f)
    }
    limite10 <- as.numeric(quantile(sc_tp,probs=0.10,na.rm=FALSE,type=7))
    boyce <- indice_boyce(sc_vp,sc_vb,sp,f)
    i <- i + 1L
    metricas[[i]] <- data.frame(especie=sp,fold_cv=f,configuracao='M0_LQ_RM2_SEIS',
      n_presenca_treino=nrow(treino_pres),n_background_treino=nrow(treino_bg),
      n_presenca_validacao=nrow(valid_pres),n_background_validacao=nrow(valid_bg),
      auc_treino_vs_bg_treino=auc_pb(sc_tp,sc_tb),
      auc_validacao_vs_bg_validacao=auc_pb(sc_vp,sc_vb),
      omissao10_treino=mean(sc_tp<limite10),
      omissao10_validacao=mean(sc_vp<limite10),
      limiar10_treino_cloglog=limite10,
      indice_boyce_validacao=boyce$valor,
      status_boyce_validacao=boyce$status,
      n_features_ativas=length(modelo$betas),
      tipo_predicao='cloglog',clamping=TRUE,features='lq',RM=2,
      background_validacao='fold_proprio')
    j <- j + 1L
    novidades[[j]] <- novidade_fold(sp,f,valid_pres,valid_bg,treino_bg)
    k <- k + 1L
    predicoes[[k]] <- rbind(
      data.frame(especie=sp,fold_cv=f,tipo='PRESENCA_VALIDACAO',
                 propriedade=valid_pres$propriedade,score_cloglog=sc_vp),
      data.frame(especie=sp,fold_cv=f,tipo='BACKGROUND_VALIDACAO',
                 propriedade=valid_bg$propriedade,score_cloglog=sc_vb))
    nome <- paste0('06_MODELO_',ifelse(sp=='Ipe-roxo','ROXO','AMARELO'),
                   '_M0_LQ_RM2_F',f,'.rds')
    saveRDS(modelo,file.path(saida,nome))
  }
}
metricas <- do.call(rbind,metricas)
novidades <- do.call(rbind,novidades)
predicoes <- do.call(rbind,predicoes)
write.csv(metricas,file.path(saida,'06_METRICAS_FOLDS_M0.csv'),
          row.names=FALSE,fileEncoding='UTF-8')
write.csv(novidades,file.path(saida,'06_NOVIDADE_UNIVARIADA_FOLDS_M0.csv'),
          row.names=FALSE,fileEncoding='UTF-8')
write.csv(predicoes,file.path(saida,'06_PREDICOES_VALIDACAO_M0.csv'),
          row.names=FALSE,fileEncoding='UTF-8')
# Media SIMPLES dos tres folds por especie (nao pondera pelo numero de arvores).
resumo_final <- resumir_metricas(metricas)
write.csv(resumo_final,file.path(saida,'06_RESUMO_ESPECIES_M0.csv'),
          row.names=FALSE,fileEncoding='UTF-8')
# Figura ilustrativa; olhar SEMPRE as 6 linhas das metricas, nao so a media.
png(file.path(saida,'06_AUC_VALIDACAO_POR_FOLD_M0.png'),width=1250,height=650,res=120)
op <- par(mar=c(5,5,4,2))
cores <- c('gray35','gray70')
dados <- rbind(metricas$auc_validacao_vs_bg_validacao[metricas$especie=='Ipe-roxo'],
               metricas$auc_validacao_vs_bg_validacao[metricas$especie=='Ipe-amarelo'])
b <- barplot(dados,beside=TRUE,col=cores,ylim=c(0,1),
        names.arg=paste('Fold',1:3),ylab='AUC de validacao (background do fold)',
        main='MaxEnt M0 - validacao espacial por fold')
abline(h=0.5,lty=2,col='gray50')
legend('topright',legend=c('Ipe-roxo','Ipe-amarelo'),fill=cores,bty='n')
par(op); dev.off()

hash_entradas <- tools::md5sum(c(arq,arq_bg,arq_todas,arq_resumo))
writeLines(c('TCC IPES - R06 M0 - PROTOCOLO DA PRIMEIRA MODELAGEM',
  'Modelos EXPLORATORIOS (2 especies x 3 folds): SEM TESTE EXTERNO.',
  'Previsao cloglog com clamping; solo tratado como categoria.',
  'Cinco preditores continuos + textura_subgrupo; features LQ; RM=2.',
  'Background: 5000 pontos no desenvolvimento; BG validacao = apenas seu fold.',
  'AUC = discriminacao presenca versus background, nao acuracia de ausencia.',
  'Omissao 10% = limiar definido no TREINO; validacao aplica o mesmo limiar.',
  'Boyce = ecospat::ecospat.boyce (Spearman) calculado com background do fold.',
  'Quando indefinido, o motivo e informado em status_boyce_validacao.',
  'Fold 3 roxo possui 206 presencas; folds espaciais nao sao equivalentes.',
  'Folds com novidade climatica avaliam transferencia ambiental.',
  'Nao e avaliada independencia via variogramas, MESS ou MOP neste script.',
  'Teste externo (7 propriedades) permanece reservado para depois da escolha final.',
  paste('R:',R.version.string),
  paste('maxnet:',as.character(utils::packageVersion('maxnet'))),
  paste('ecospat:',if(requireNamespace('ecospat',quietly=TRUE))
                       as.character(utils::packageVersion('ecospat')) else 'nao instalado'),
  'Arquivos de entrada e MD5:',
  paste(names(hash_entradas),hash_entradas,collapse='\n')),
  file.path(saida,'06_LEIA_RESULTADOS_E_RASTREABILIDADE.txt'),useBytes=TRUE)
writeLines(capture.output(sessionInfo()),
           file.path(saida,'06_SESSION_INFO.txt'),useBytes=TRUE)
cat('\nR06 M0 FINALIZADO: 6 modelos exploratorios, metricas e diagnosticos.\n',
    'Resultados em: ',saida,'\n',sep='')
cat('Envie toda a pasta de resultados ZIP antes de iniciar novos ajustes.\n')

cat('\n[R06 V3.2] FINALIZADO: seis modelos M0 e indices Boyce gerados.\n')
print(metricas[,c('especie','fold_cv','auc_validacao_vs_bg_validacao',
                  'omissao10_validacao','indice_boyce_validacao','status_boyce_validacao')])
} # fim do modo: ajustar modelos novos
