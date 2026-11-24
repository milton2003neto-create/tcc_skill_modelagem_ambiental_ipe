# =============================================================
# TCC IPES | R25 V1 | Viabilidade de blocos espaciais alternativos
# ANALISE DE PLANEJAMENTO - NAO ajusta modelos, NAO altera folds.
# Base: distancias ENTRE LIMITES DE UPAs INVENTARIADAS (R24 V1.1)
# e contagens de presencas/background de desenvolvimento (R23).
# =============================================================

versao <- 'R25_BLOCOS_ESPACIAIS_V1_20261117'
cat('\nR25 - PLANEJAMENTO DE FOLDS, SEM EXECUTAR MAXENT.\n')
cat('Selecione 24_PARES_PROPRIEDADES_GEOMETRICOS.csv do R24 V1.1.\n')
arq24 <- file.choose()
cat('Selecione 23_PROPRIEDADES_FOLDS_E_CONTAGENS.csv do R23 V1.1.\n')
arq23 <- file.choose()
qa_path <- file.path(dirname(arq24), '24_QA_64_UPAS.csv')
if (!file.exists(qa_path)) {
  cat('Agora selecione 24_QA_64_UPAS.csv do R24 V1.1.\n')
  qa_path <- file.choose()
}
ler <- function(path) {
  if (!file.exists(path)) stop('Arquivo ausente: ', path)
  read.csv(path, fileEncoding='UTF-8-BOM', stringsAsFactors=FALSE,
           check.names=FALSE)
}
pares <- ler(arq24)
contagens <- ler(arq23)
upas <- ler(qa_path)
exigir <- function(cond, msg) if (!isTRUE(cond)) stop(msg, call.=FALSE)
colunas <- function(x, nomes, origem) {
  ausentes <- setdiff(nomes, names(x))
  exigir(length(ausentes)==0L, paste('Campos ausentes em',origem,':',paste(ausentes,collapse=', ')))
}
colunas(pares, c('propriedade_a','propriedade_b','fold_a','fold_b',
                'distancia_limites_upas_km'), 'R24 pares')
colunas(contagens,c('propriedade','fold_cv','n_roxo','n_amarelo',
                   'n_background'), 'R23 contagens')
colunas(upas,c('propriedade','upa_id','fold_cv'), 'R24 QA')
exigir(nrow(pares)==351L, 'R24 deve ter exatamente 351 pares de propriedades.')
exigir(nrow(contagens)==27L && !anyDuplicated(contagens$propriedade),
      'R23 deve ter 27 propriedades unicas.')
exigir(nrow(upas)==64L && !anyDuplicated(upas$upa_id),
      'R24 deve ter 64 UPAs unicas.')
exigir(setequal(contagens$propriedade, unique(c(pares$propriedade_a,
          pares$propriedade_b))) &&
        setequal(contagens$propriedade, unique(upas$propriedade)),
        'Propriedades de R23 e R24 nao coincidem. Verifique as fontes.')
exigir(sum(contagens$n_roxo)==3248 && sum(contagens$n_amarelo)==5432 &&
        sum(contagens$n_background)==10000,
        'Contagens diferentes do desenvolvimento aprovado: pare e audite.')
exigir(all(is.finite(pares$distancia_limites_upas_km)) &&
        all(pares$distancia_limites_upas_km >= 0),
        'Distancias de R24 invalidas ou ausentes.')
exigir(all(contagens$fold_cv %in% 1:3) &&
        all(upas$fold_cv %in% 1:3), 'Fold fora de 1,2,3.')
exigir(all(contagens$n_roxo >= 0 & contagens$n_amarelo >= 0 &
            contagens$n_background >= 0), 'Contagem negativa.')
exigir(length(unique(paste(pmin(pares$propriedade_a,pares$propriedade_b),
                              pmax(pares$propriedade_a,pares$propriedade_b),sep='||')))==351L,
        'Pares de propriedades duplicados no R24.')
fold_a_esperado <- contagens$fold_cv[match(pares$propriedade_a,contagens$propriedade)]
fold_b_esperado <- contagens$fold_cv[match(pares$propriedade_b,contagens$propriedade)]
exigir(all(pares$fold_a==fold_a_esperado & pares$fold_b==fold_b_esperado),
        'Folds entre R23 e R24 divergentes: nao prosseguir.')
exigir(all(upas$fold_cv==contagens$fold_cv[
       match(upas$propriedade,contagens$propriedade)]),
       'Os folds das UPAs diferem dos folds das propriedades.')
contagens <- contagens[order(contagens$propriedade),,drop=FALSE]
rownames(contagens) <- NULL
contagens$n_upas <- as.integer(table(factor(upas$propriedade,
                                           levels=contagens$propriedade)))
exigir(sum(contagens$n_upas)==64L,'A soma de UPAs deve ser 64.')

# Saida - somente NOVA pasta, sem sobrescrever resultados.
pasta_resultados <- dirname(dirname(arq24))
if (basename(pasta_resultados)=='06 - Resultados') {
  saida <- file.path(pasta_resultados,'23 - Planejamento de blocos R25 V1')
} else {
  saida <- file.path(dirname(arq24),'23 - Planejamento de blocos R25 V1')
}
exigir(!dir.exists(saida),paste('A saida ja existe. Preserve-a.\n',saida,
                              '\nPara uma nova execucao, renomeie a pasta antiga.'))
dir.create(saida,recursive=TRUE,showWarnings=FALSE)
escrever <- function(x,nome) {
  write.csv(x,file.path(saida,nome),row.names=FALSE,fileEncoding='UTF-8')
}
escrever(data.frame(arquivo=normalizePath(c(arq24,arq23,qa_path),winslash='/'),
                     md5=as.character(tools::md5sum(c(arq24,arq23,qa_path))),
                     stringsAsFactors=FALSE),'25_MANIFESTO_FONTES.csv')

# Componentes conectadas: a distancia se refere a uniao das UPAs
# inventariadas de cada propriedade. NUNCA a divisa total do imovel.
componentes <- function(limiar) {
  nomes <- contagens$propriedade
  n <- length(nomes)
  viz <- diag(TRUE,n)
  for (i in seq_len(nrow(pares))) {
    if (pares$distancia_limites_upas_km[i] <= limiar) {
      a <- match(pares$propriedade_a[i],nomes)
      b <- match(pares$propriedade_b[i],nomes)
      viz[a,b] <- TRUE
      viz[b,a] <- TRUE
    }
  }
  grupo <- integer(n)
  g <- 0L
  while (any(grupo==0L)) {
    g <- g+1L
    fila <- which(grupo==0L)[1]
    grupo[fila] <- g
    pos <- 1L
    while (pos<=length(fila)) {
      atual <- fila[pos]
      prox <- which(viz[atual,] & grupo==0L)
      if (length(prox)) {
        grupo[prox] <- g
        fila <- c(fila,prox)
      }
      pos <- pos+1L
    }
  }
  grupo
}

# Enumeracao exata das particoes dos grupos em 3 folds nao vazios.
# Remove simetrias rotulando folds na ordem em que surgem.
particoes_tres <- function(n) {
  saidas <- list()
  v <- integer(n)
  v[1] <- 1L
  rec <- function(i,maior) {
    if (i>n) {
      if (maior==3L) saidas[[length(saidas)+1L]] <<- as.integer(v)
      return(invisible(NULL))
    }
    for (k in seq_len(min(3L,maior+1L))) {
      v[i] <<- k
      rec(i+1L,max(maior,k))
    }
    invisible(NULL)
  }
  if (n>=3L) rec(2L,1L)
  saidas
}

agrupar <- function(g) {
  ix <- which(g==g[1])
  data.frame(grupo=g[1],
             n_propriedades=length(ix),
             n_upas=sum(contagens$n_upas[ix]),
             n_roxo=sum(contagens$n_roxo[ix]),
             n_amarelo=sum(contagens$n_amarelo[ix]),
             n_background=sum(contagens$n_background[ix]),
             folds_originais=paste(sort(unique(contagens$fold_cv[ix])),collapse='; '),
             propriedades=paste(contagens$propriedade[ix],collapse='; '),
             stringsAsFactors=FALSE)
}

resumos <- list()
comp <- list()
propr_grupos <- list()
melhores <- list()
simulacoes <- list()
relato <- c('TCC IPES - R25 V1: PLANEJAMENTO, NAO NOVA VALIDACAO',
            paste('Execucao:',as.character(Sys.time())),
            'Somente 27 propriedades e 64 UPAs INVENTARIADAS de desenvolvimento.',
            'Teste externo de 7 propriedades NAO foi usado.',
            'Nao ha exclusao de propriedade/UPA, alteracao de folds originais ou novo MaxEnt.',
            'Distancias do R24 entre limites das UPAs; projecao metrico-regional R24.',
            'Componentes conectadas podem ter extremidades distantes entre si.',
            'Avaliacao de viabilidade: cada fold >= 10% das presencas de CADA especie.',
            'O minimo de 10% e um critério DIAGNOSTICO, nao regra universal de MaxEnt.',
            'A alocacao de menor indice de desequilibrio e APENAS ILUSTRATIVA.',
            'Nunca usar as alocacoes propostas como validacao independente sem novo desenho.',
            '')

totR <- sum(contagens$n_roxo)
totA <- sum(contagens$n_amarelo)
totB <- sum(contagens$n_background)
for (limiar in c(5,10,20)) {
  gr <- componentes(limiar)
  grupos <- sort(unique(gr))
  propr_grupos[[as.character(limiar)]] <- data.frame(
    limiar_km=limiar,propriedade=contagens$propriedade,
    fold_original=contagens$fold_cv, grupo=gr,
    n_upas=contagens$n_upas,n_roxo=contagens$n_roxo,
    n_amarelo=contagens$n_amarelo,n_background=contagens$n_background)
  sg <- do.call(rbind,lapply(grupos,function(g) {
    ix <- which(gr==g)
    data.frame(grupo=g, n_propriedades=length(ix),
      n_upas=sum(contagens$n_upas[ix]),
      n_roxo=sum(contagens$n_roxo[ix]),
      n_amarelo=sum(contagens$n_amarelo[ix]),
      n_background=sum(contagens$n_background[ix]),
      folds_originais=paste(sort(unique(contagens$fold_cv[ix])),collapse='; '),
      propriedades=paste(contagens$propriedade[ix],collapse='; '),
      stringsAsFactors=FALSE)
  }))
  sg$limiar_km <- limiar
  comp[[as.character(limiar)]] <- sg[,c('limiar_km','grupo','n_propriedades',
              'n_upas','n_roxo','n_amarelo','n_background',
              'folds_originais','propriedades')]
  n <- nrow(sg)
  ps <- particoes_tres(n)
  exigir(length(ps)>0,'Menos de 3 grupos: tres folds espacialmente separados impossiveis.')
  melhor_score <- Inf
  melhor <- NULL
  viable <- 0L
  for (v in ps) {
    soma <- function(col) vapply(1:3, function(f) sum(col[v==f]), numeric(1))
    nr <- soma(sg$n_roxo); na <- soma(sg$n_amarelo)
    np <- soma(sg$n_propriedades); nb <- soma(sg$n_background)
    cond <- all(nr>=0.1*totR) && all(na>=0.1*totA)
    if (cond) viable <- viable+1L
    score <- sum((nr/totR-1/3)^2) + sum((na/totA-1/3)^2) +
             0.1*sum((np/27-1/3)^2) + 0.05*sum((nb/totB-1/3)^2)
    if (score<melhor_score-1e-12) {
      melhor_score <- score
      melhor <- v
    }
  }
  soma_melhor <- function(col) vapply(1:3, function(f)
          sum(col[melhor==f]),numeric(1))
  nr <- soma_melhor(sg$n_roxo); na <- soma_melhor(sg$n_amarelo)
  nb <- soma_melhor(sg$n_background); np <- soma_melhor(sg$n_propriedades)
  nu <- soma_melhor(sg$n_upas)
  entre_orig <- sum(pares$distancia_limites_upas_km <= limiar &
                         pares$fold_a != pares$fold_b)
  sim <- data.frame(limiar_km=limiar,fold_simulado=1:3,
            n_propriedades=np,n_upas=nu,n_roxo=nr,n_amarelo=na,n_background=nb,
            pct_roxo=round(100*nr/totR,2),
            pct_amarelo=round(100*na/totA,2),
            somente_simulacao_NAO_APLICAR=TRUE)
  simulacoes[[as.character(limiar)]] <- sim
  resumos[[as.character(limiar)]] <- data.frame(
    limiar_km=limiar,n_grupos=n,
    n_grupos_multifold=sum(grepl(';',sg$folds_originais,fixed=TRUE)),
    pares_propriedades_entre_folds_atuais=entre_orig,
    n_alocacoes_tres_folds=length(ps),
    n_alocacoes_minimo_10pct_por_especie=viable,
    maior_grupo_roxo_pct=round(100*max(sg$n_roxo)/totR,2),
    maior_grupo_amarelo_pct=round(100*max(sg$n_amarelo)/totA,2),
    menor_fold_roxo_pct=round(100*min(nr)/totR,2),
    menor_fold_amarelo_pct=round(100*min(na)/totA,2),
    indice_desequilibrio=melhor_score,
    decisao=if (viable==0L) 'INVIAVEL_10PCT_NOS_3_FOLDS' else 'HA_ALOCACAO_10PCT')
  melhores[[as.character(limiar)]] <- data.frame(limiar_km=limiar,
    propriedade=contagens$propriedade,grupo=gr,
    fold_original=contagens$fold_cv,
    fold_simulado=melhor[match(gr,sg$grupo)],
    APENAS_SIMULACAO_NAO_APLICAR=TRUE)
  relato <- c(relato,sprintf('Limiar %d km: %d grupos, %d alocacoes em 3 folds, %d com >=10%% de ambas especies em cada fold.',
                            limiar,n,length(ps),viable),
     sprintf('  Maior grupo do roxo: %.2f%%; menor fold roxo na alocacao ilustrativa: %.2f%%.',
       100*max(sg$n_roxo)/totR,100*min(nr)/totR),
     sprintf('  Pares entre folds ORIGINAIS a <=%d km: %d.',limiar,entre_orig))
  cat(sprintf('R25 %d km: %d grupos, %d alocacoes, %d equilibradas (>=10%%).\n',
              limiar,n,length(ps),viable))
}
resumos <- do.call(rbind,resumos)
comp <- do.call(rbind,comp)
propr_grupos <- do.call(rbind,propr_grupos)
melhores <- do.call(rbind,melhores)
simulacoes <- do.call(rbind,simulacoes)
escrever(resumos,'25_RESUMO_VIABILIDADE.csv')
escrever(comp,'25_GRUPOS_COMPOSICAO.csv')
escrever(propr_grupos,'25_PROPRIEDADES_NOS_GRUPOS.csv')
escrever(simulacoes,'25_FOLDS_SIMULADOS_APENAS_DIAGNOSTICO.csv')
escrever(melhores,'25_ALOCACAO_ILUSTRATIVA_NAO_APLICAR.csv')

# Referencia dos folds originais para comparacao de balanceamento.
atual <- aggregate(contagens[,c('n_roxo','n_amarelo','n_background','n_upas')],
                   by=list(fold=contagens$fold_cv),FUN=sum)
ordem <- match(1:3,atual$fold)
atual <- atual[ordem,,drop=FALSE]
for (sp in c('roxo','amarelo')) {
  coluna <- paste0('n_',sp)
  m <- cbind(atual[[coluna]],
             simulacoes[[coluna]][simulacoes$limiar_km==5],
             simulacoes[[coluna]][simulacoes$limiar_km==10],
             simulacoes[[coluna]][simulacoes$limiar_km==20])
  colnames(m) <- c('Folds atuais','Grupos 5 km','Grupos 10 km','Grupos 20 km')
  rownames(m) <- paste('Fold',1:3)
  png(file.path(saida,paste0('25_BALANCO_',toupper(sp),'_FOLDS.png')),
      width=1380,height=730,res=145)
  op <- par(mar=c(6,5,4,2))
  barplot(m,beside=TRUE,col=c('gray20','gray55','gray80'),
          ylab='Numero de ocorrencias',
          main=paste('TCC IPES -',toupper(sp),'- planejamento (nao aplicar folds)'),
          legend.text=rownames(m),args.legend=list(x='topright',bty='n'),
          ylim=c(0,max(m)*1.16),las=1)
  par(op);dev.off()
}
relato <- c(relato,'',
 'CRITICO: 5/10/20 km nao permitem tres folds com >=10% dos registros de cada especie.',
 'Nao usar a menor nota de desequilibrio para escolher um modelo por AUC.',
 'As opcoes de alocacao exemplificam restricoes; NAO sao folds aprovados.',
 'R25 nao refaz modelos, nao reclassifica UPAs, nao insere propriedades sem inventario.',
 'O limite de 10% e arbitrario/exploratorio; uma boa validacao exige desenho independente.',
 'Considerar avaliacao especifica por especie, transferencia regional e representatividade.',
 'Validar pendencia cadastral da UPA 01 de Saudade antes de produto espacial definitivo.',
 paste('Pasta de saida:',saida),
 paste('Codigo:',versao),
 paste('R:',R.version.string))
writeLines(relato,file.path(saida,'25_RELATORIO_PLANEJAMENTO.txt'),useBytes=TRUE)
writeLines(capture.output(sessionInfo()),file.path(saida,'25_SESSION_INFO.txt'),useBytes=TRUE)
cat('\nR25 CONCLUIDO - SOMENTE SIMULACAO. Pasta:',saida,'\n')
cat('Nao altere os folds ou rode MaxEnt com as alocacoes ilustrativas.\n')
