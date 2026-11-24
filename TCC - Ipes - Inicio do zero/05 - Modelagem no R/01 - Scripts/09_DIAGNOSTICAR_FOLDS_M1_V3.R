# ===============================================================
# TCC IPES | R09 V3.1 - DIAGNOSTICO DOS FOLDS DO MAXENT M1
# ===============================================================
# Continua o protocolo V3 depois do R08 (72 ajustes).
# NAO ajusta modelos, NAO altera M0/M1, NAO usa teste externo.
# Examina: AUC, omissao, distribuicao dos scores, limiar de treino,
# discriminacao dentro de propriedades e novidade univariada.
# Folds de interesse: ROXO F3 e AMARELO F2.
# Requer somente R base (nenhuma instalacao de pacote).
# Selecione 08_METRICAS_72_MODELOS.csv na pasta oficial R08.
# ===============================================================

versao_r09 <- 'R09_V3_1_20261115'
cat('\nR09 | Selecione 08_METRICAS_72_MODELOS.csv do R08.\n')
arquivo <- normalizePath(file.choose(), winslash = '/', mustWork = TRUE)
if (basename(arquivo) != '08_METRICAS_72_MODELOS.csv') {
  stop('Arquivo incorreto. Selecione 08_METRICAS_72_MODELOS.csv.')
}

pasta_m1 <- dirname(arquivo)
# Estrutura: RAIZ/06 - Resultados/06 - MaxEnt M1 - Grade 72 V3/
raiz <- dirname(dirname(pasta_m1))
if (basename(pasta_m1) != '06 - MaxEnt M1 - Grade 72 V3' ||
    basename(dirname(pasta_m1)) != '06 - Resultados' ||
    !dir.exists(file.path(raiz, '03 - Trabalho no QGIS'))) {
  stop('A pasta escolhida nao pertence a estrutura V3 oficial do TCC.')
}

pasta05 <- file.path(raiz, '04 - Dados para o MaxEnt',
                     '04 - Presencas e folds V3')
entrada_pres <- file.path(pasta05, '05_PRESENCAS_UM_POR_PIXEL_30M.csv')
entrada_bg <- file.path(pasta05, '05_BACKGROUND_COM_FOLDS.csv')
entrada_todas <- file.path(pasta05, '05_PRESENCAS_TODAS_DESENVOLVIMENTO.csv')
entrada_resumo <- file.path(pasta05, '05_RESUMO_FOLDS.csv')
entradas <- c(entrada_pres, entrada_bg, entrada_todas, entrada_resumo)
pasta_previsoes <- file.path(pasta_m1, '08_PREVISOES_VALIDACAO')
arquivo_manifesto <- file.path(pasta_m1, '08_MANIFESTO_ENTRADAS.csv')
if (!all(file.exists(c(entradas, arquivo_manifesto))) ||
    !dir.exists(pasta_previsoes)) {
  stop('Faltam entradas do R05 ou previsoes/manifesto do R08 na estrutura oficial.')
}

ler <- function(caminho) {
  utils::read.csv(caminho, fileEncoding = 'UTF-8-BOM',
                  stringsAsFactors = FALSE, check.names = FALSE)
}
conferir_colunas <- function(x, colunas, nome) {
  faltam <- setdiff(colunas, names(x))
  if (length(faltam)) stop(nome, ': colunas ausentes: ', paste(faltam, collapse = ', '))
}

m <- ler(arquivo)
pres <- ler(entrada_pres)
bg <- ler(entrada_bg)
manifesto <- ler(arquivo_manifesto)
conferir_colunas(m, c('id','especie','fold_cv','features','RM',
                      'n_presenca_validacao','n_background_validacao',
                      'auc_validacao','omissao10_validacao',
                      'limiar10_treino_cloglog','boyce_validacao'), 'R08 metricas')
conferir_colunas(pres, c('especie','propriedade','fold_cv',
                         'altitude_m','declividade_graus','dist_rio_raster_m',
                         'bio12_mm_ano','bio17_mm_mes'), 'R05 presencas')
conferir_colunas(bg, c('propriedade','fold_cv','upa_id',
                       'altitude_m','declividade_graus','dist_rio_raster_m',
                       'bio12_mm_ano','bio17_mm_mes'), 'R05 background')
conferir_colunas(manifesto, c('arquivo','md5'), 'R08 manifesto')

if (nrow(m) != 72L || anyDuplicated(m$id) ||
    nrow(pres) != 8680L || nrow(bg) != 5000L ||
    sum(pres$especie == 'Ipe-roxo') != 3248L ||
    sum(pres$especie == 'Ipe-amarelo') != 5432L ||
    length(unique(bg$propriedade)) != 27L ||
    length(unique(bg$upa_id)) != 64L ||
    !setequal(unique(pres$fold_cv), 1:3) ||
    !setequal(unique(bg$fold_cv), 1:3)) {
  stop('Contagens, duplicidades ou particao diferem das entradas V3 auditadas.')
}

# A integridade do R08 exige entradas com hashes identicos aos de seu ajuste.
md5_atuais <- unname(tools::md5sum(entradas))
for (i in seq_along(entradas)) {
  registro <- manifesto[manifesto$arquivo == basename(entradas[i]), , drop = FALSE]
  if (nrow(registro) != 1L ||
      !identical(tolower(as.character(registro$md5)), tolower(as.character(md5_atuais[i])))) {
    stop('O arquivo mudou depois do R08: ', basename(entradas[i]),
         '. Nao misture execucoes com bases diferentes.')
  }
}

# As sete propriedades externas devem continuar inteiramente reservadas.
externas <- c('BARRO BRANCO','CURUÇA','GUARIÚBA','JATOBÁ',
              'LOTE 01','MARILIA','PALMEIRA')
if (any(c(pres$propriedade, bg$propriedade) %in% externas)) {
  stop('VAZAMENTO DO TESTE EXTERNO: o R09 foi interrompido.')
}
propriedades_folds <- unique(rbind(
  pres[, c('propriedade','fold_cv')], bg[, c('propriedade','fold_cv')]))
if (any(vapply(split(propriedades_folds$fold_cv,
                     propriedades_folds$propriedade),
               function(x) length(unique(x)) != 1L, logical(1)))) {
  stop('A mesma propriedade aparece em folds diferentes.')
}

# Tres configuracoes diagnosticas por especie, SEM escolher vencedor.
candidatas <- data.frame(
  especie  = c('Ipe-roxo','Ipe-roxo','Ipe-roxo',
               'Ipe-amarelo','Ipe-amarelo','Ipe-amarelo'),
  features = c('lq','l','lqh','lq','lqh','lqh'),
  RM       = c(2L,4L,4L,2L,3L,4L),
  stringsAsFactors = FALSE)

# AUC de presencas x background, com ranks medios para empates.
auc <- function(p, b) {
  p <- as.numeric(p); b <- as.numeric(b)
  if (!length(p) || !length(b) || any(!is.finite(c(p,b)))) return(NA_real_)
  n <- length(p); k <- length(b)
  r <- rank(c(p,b), ties.method = 'average')
  (sum(r[seq_len(n)]) - n*(n+1)/2)/(n*k)
}

resultados <- list()
propriedades <- list()
previsoes_problema <- list()
nr <- 0L; np <- 0L; ng <- 0L

for (i in seq_len(nrow(candidatas))) {
  cfg <- candidatas[i, ]
  sp <- cfg$especie
  apelido <- if (sp == 'Ipe-roxo') 'ROXO' else 'AMARELO'
  for (f in 1:3) {
    id <- paste0('M1_', apelido, '_F', f, '_',
                 toupper(cfg$features), '_RM', cfg$RM)
    z <- m[m$id == id, , drop = FALSE]
    if (nrow(z) != 1L) stop('Modelo ausente ou duplicado: ', id)
    caminho <- file.path(pasta_previsoes, paste0(id, '.csv'))
    if (!file.exists(caminho)) stop('Previsoes ausentes: ', caminho)
    pp <- ler(caminho)
    conferir_colunas(pp, c('id','especie','fold_cv','features','RM',
                           'tipo','propriedade','score_cloglog'), id)
    if (anyNA(pp) || any(pp$id != id) || any(pp$especie != sp) ||
        any(pp$fold_cv != f) || any(pp$features != cfg$features) ||
        any(pp$RM != cfg$RM) ||
        !setequal(unique(pp$tipo), c('PRESENCA_VALIDACAO',
                                    'BACKGROUND_VALIDACAO')) ||
        any(!is.finite(pp$score_cloglog)) ||
        any(pp$score_cloglog < 0 | pp$score_cloglog > 1) ||
        any(pp$propriedade %in% externas) ||
        !all(pp$propriedade %in% propriedades_folds$propriedade[
          propriedades_folds$fold_cv == f])) {
      stop('CSV de previsoes invalido ou fora do fold: ', id)
    }
    a <- pp$score_cloglog[pp$tipo == 'PRESENCA_VALIDACAO']
    b <- pp$score_cloglog[pp$tipo == 'BACKGROUND_VALIDACAO']
    if (length(a) != z$n_presenca_validacao ||
        length(b) != z$n_background_validacao ||
        length(a) != sum(pres$especie == sp & pres$fold_cv == f) ||
        length(b) != sum(bg$fold_cv == f)) {
      stop('Contagens da validacao divergentes: ', id)
    }
    limiar <- as.numeric(z$limiar10_treino_cloglog)
    auc_recalculada <- auc(a, b)
    omissao <- mean(a < limiar)
    if (length(limiar) != 1L || !is.finite(limiar) ||
        abs(auc_recalculada - as.numeric(z$auc_validacao)) > 1e-8 ||
        abs(omissao - as.numeric(z$omissao10_validacao)) > 1e-8) {
      stop('AUC, limiar ou omissao nao conferem com o R08: ', id)
    }
    nr <- nr + 1L
    resultados[[nr]] <- data.frame(
      id=id, especie=sp, fold_cv=f, features=cfg$features, RM=cfg$RM,
      n_presencas=length(a), n_background=length(b),
      auc_validacao=auc_recalculada, boyce_validacao=z$boyce_validacao,
      omissao10_validacao=omissao, limiar10_treino=limiar,
      score_min_presencas=min(a), score_max_presencas=max(a),
      score_mediana_presencas=median(a), score_mediana_background=median(b),
      p10_presencas=unname(stats::quantile(a,.10)),
      p90_presencas=unname(stats::quantile(a,.90)),
      fracao_presencas_acima_ou_igual_limiar=mean(a >= limiar),
      diferenca_mediana_presenca_background=median(a)-median(b))

    # AUC dentro da mesma propriedade (nao confundir com AUC global).
    for (pr in unique(pp$propriedade)) {
      subset <- pp[pp$propriedade == pr,,drop = FALSE]
      ap <- subset$score_cloglog[subset$tipo == 'PRESENCA_VALIDACAO']
      bp <- subset$score_cloglog[subset$tipo == 'BACKGROUND_VALIDACAO']
      if (!length(ap) || !length(bp)) next
      np <- np + 1L
      propriedades[[np]] <- data.frame(
        id=id, especie=sp, fold_cv=f, propriedade=pr,
        n_presencas=length(ap), n_background=length(bp),
        auc_propriedade=if (min(length(ap),length(bp))>=10L) auc(ap,bp) else NA_real_,
        omissao10_propriedade=mean(ap < limiar),
        status_auc=if (min(length(ap),length(bp))>=10L) 'OK' else 'AMOSTRA_PEQUENA')
    }
    # Guardar apenas os dois folds problematicos para graficos.
    if ((sp == 'Ipe-roxo' && f == 3L) ||
        (sp == 'Ipe-amarelo' && f == 2L)) {
      ng <- ng+1L
      previsoes_problema[[ng]] <- list(id=id, especie=sp, fold=f,
         p=a, b=b, limiar=limiar)
    }
    cat(sprintf('Conferido %s: AUC %.3f | omissao %.1f%%\n',
                id,auc_recalculada,100*omissao))
  }
}

# Novidade ambiental univariada: intervalos dos preditores do background
# de TREINAMENTO. Nao e MESS, MOP ou teste de autocorrelacao espacial.
vars <- c('altitude_m','declividade_graus','dist_rio_raster_m',
          'bio12_mm_ano','bio17_mm_mes')
novidade <- list()
novidade_resumo <- list()
nn <- 0L; ns <- 0L
for (sp in c('Ipe-roxo','Ipe-amarelo')) {
  for (f in 1:3) {
    vp <- pres[pres$especie == sp & pres$fold_cv == f,,drop = FALSE]
    vb <- bg[bg$fold_cv == f,,drop = FALSE]
    treino_bg <- bg[bg$fold_cv != f,,drop = FALSE]
    matriz_fora_p <- matrix(FALSE,nrow(vp),length(vars),dimnames=list(NULL,vars))
    matriz_fora_b <- matrix(FALSE,nrow(vb),length(vars),dimnames=list(NULL,vars))
    for (v in vars) {
      minimo <- min(treino_bg[[v]]); maximo <- max(treino_bg[[v]])
      fora_p <- vp[[v]] < minimo | vp[[v]] > maximo
      fora_b <- vb[[v]] < minimo | vb[[v]] > maximo
      matriz_fora_p[,v] <- fora_p
      matriz_fora_b[,v] <- fora_b
      nn <- nn+1L
      novidade[[nn]] <- data.frame(
        especie=sp, fold_cv=f, variavel=v,
        minimo_bg_treino=minimo, maximo_bg_treino=maximo,
        n_presencas_validacao=nrow(vp), n_presencas_fora=sum(fora_p),
        prop_presencas_fora=mean(fora_p),
        n_background_validacao=nrow(vb), n_background_fora=sum(fora_b),
        prop_background_fora=mean(fora_b))
    }
    ns <- ns + 1L
    novidade_resumo[[ns]] <- data.frame(
      especie=sp, fold_cv=f,
      n_presencas=nrow(vp), n_background=nrow(vb),
      proporcao_presencas_fora_qualquer_variavel=mean(rowSums(matriz_fora_p)>0),
      proporcao_presencas_fora_bio12_ou_bio17=mean(
        rowSums(matriz_fora_p[,c('bio12_mm_ano','bio17_mm_mes'),drop=FALSE])>0),
      proporcao_presencas_fora_bio12_e_bio17=mean(
        rowSums(matriz_fora_p[,c('bio12_mm_ano','bio17_mm_mes'),drop=FALSE])==2),
      proporcao_background_fora_qualquer_variavel=mean(rowSums(matriz_fora_b)>0))
  }
}

# Escrever em NOVA pasta, sem alterar os resultados existentes M0/M1.
saida <- file.path(raiz,'06 - Resultados','07 - Diagnostico dos folds M1 V3')
if (dir.exists(saida)) {
  stop('A pasta do R09 ja existe. Guarde a anterior antes de executar novamente: ',saida)
}
dir.create(saida,recursive=TRUE,showWarnings=FALSE)
graficos <- file.path(saida,'09_GRAFICOS')
dir.create(graficos,showWarnings=FALSE)
escrever <- function(x,nome) {
  utils::write.csv(x,file.path(saida,nome),row.names=FALSE,fileEncoding='UTF-8')
}
escrever(do.call(rbind,resultados),'09_DIAGNOSTICO_PREVISOES.csv')
escrever(do.call(rbind,propriedades),'09_DIAGNOSTICO_PROPRIEDADES.csv')
escrever(do.call(rbind,novidade),'09_NOVIDADE_AMBIENTAL.csv')
escrever(do.call(rbind,novidade_resumo),'09_RESUMO_NOVIDADE_POR_FOLD.csv')

# Histogramas comparando presencas e background, com limiar treinado.
for (x in previsoes_problema) {
  caminho <- file.path(graficos,paste0('09_DISTRIBUICAO_',x$id,'.png'))
  grDevices::png(caminho,width=1200,height=770,res=140)
  br <- seq(0,1,by=.02)
  hp <- graphics::hist(x$p,breaks=br,plot=FALSE)
  hb <- graphics::hist(x$b,breaks=br,plot=FALSE)
  ym <- max(c(hp$density,hb$density),na.rm=TRUE)*1.13
  graphics::plot(hb,frequency=FALSE,xlim=c(0,1),ylim=c(0,ym),
      col=grDevices::adjustcolor('gray70',alpha.f=.65),border=NA,
      main=paste('MaxEnt M1 -',x$id),xlab='Adequabilidade prevista (cloglog)',
      ylab='Densidade')
  graphics::plot(hp,frequency=FALSE,add=TRUE,
      col=grDevices::adjustcolor('steelblue4',alpha.f=.5),border=NA)
  graphics::abline(v=x$limiar,col='firebrick3',lwd=2,lty=2)
  graphics::legend('topright',c('Background de validacao','Presencas de validacao',
                   'Limiar 10% do treino'),
      fill=c('gray70','steelblue4',NA),border=NA,
      lty=c(NA,NA,2),col=c(NA,NA,'firebrick3'),bty='n',cex=.85)
  grDevices::dev.off()
}

texto <- c(
  paste('TCC IPES - R09 DIAGNOSTICO DOS FOLDS |',versao_r09),
  paste('Executado em:',as.character(Sys.time())),
  '18 conjuntos de previsoes conferidos (6 configuracoes x 3 folds).',
  'Nao foram ajustados novos modelos.',
  'AUC e omissao foram recalculadas das previsoes R08 e conferidas com as metricas.',
  'Os Boyce foram apenas importados das metricas R08 (nao recalculados).',
  'AUC local exige >=10 presencas e >=10 backgrounds por propriedade.',
  'Novidade ambiental: fora do intervalo minimo-maximo de cada preditor no',
  'background dos dois folds de treinamento. NAO e MESS/MOP nem autocorrelacao.',
  'O uso de intervalos do background nao prova extrapolacao multivariada.',
  'Limiar e omissao de validacao seguem o limiar de 10% definido no treino.',
  'Folds espaciais nao garantem independencia ecologica.',
  'Nenhuma das sete propriedades de TESTE externo foi utilizada.',
  '',
  'Arquivos: 09_DIAGNOSTICO_PREVISOES.csv (18 linhas);',
  '09_DIAGNOSTICO_PROPRIEDADES.csv; 09_NOVIDADE_AMBIENTAL.csv (30 linhas);',
  '09_RESUMO_NOVIDADE_POR_FOLD.csv (6 linhas); 09_GRAFICOS (6 figuras).',
  '',
  'Proximo passo: interpretar os folds problematicos e decidir o desenho M2',
  'sem alterar particao, preditores ou background nesta etapa.')
writeLines(texto,file.path(saida,'09_LEIA_RESULTADOS.txt'),useBytes=TRUE)
writeLines(capture.output(utils::sessionInfo()),
           file.path(saida,'09_SESSION_INFO.txt'),useBytes=TRUE)
cat('\nR09 FINALIZADO com verificacoes aprovadas.\nPasta de resultados:\n',saida,'\n',sep='')
