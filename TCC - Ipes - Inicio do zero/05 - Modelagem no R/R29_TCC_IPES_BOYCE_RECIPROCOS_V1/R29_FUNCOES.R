# TCC IPES | R29 - utilitarios compartilhados (somente base R)
locate_r29 <- function() {
  of <- unlist(lapply(sys.frames(), function(f) if(is.null(f$ofile)) character(0) else as.character(f$ofile)), use.names=FALSE)
  for(f in rev(of)) {
    if(file.exists(f)) {
      d <- dirname(normalizePath(f,winslash='/',mustWork=TRUE))
      if(file.exists(file.path(d,'29_MANIFESTO_ENTRADAS.csv'))) return(d)
    }
  }
  if(file.exists('29_MANIFESTO_ENTRADAS.csv')) return(normalizePath('.',winslash='/',mustWork=TRUE))
  stop('R29: extraia o ZIP completo e execute o script a partir da pasta extraida.',call.=FALSE)
}
read_r29 <- function(path) {
  if(!file.exists(path)) stop('Arquivo nao encontrado: ',path,call.=FALSE)
  utils::read.csv(path,fileEncoding='UTF-8-BOM',check.names=FALSE,stringsAsFactors=FALSE)
}
assert_r29 <- function(ok,msg) {
  if(!isTRUE(ok)) stop('R29: ',msg,call.=FALSE)
}
need_r29 <- function(d,cols,contexto) {
  falta <- setdiff(cols,names(d))
  assert_r29(length(falta)==0L,paste0(contexto,': colunas ausentes: ',paste(falta,collapse=', ')))
}
md5_r29 <- function(path) unname(tools::md5sum(path))
preflight_r29 <- function(pasta) {
  m <- read_r29(file.path(pasta,'29_MANIFESTO_ENTRADAS.csv'))
  need_r29(m,c('caminho_relativo','md5','bytes'),'Manifesto')
  assert_r29(nrow(m)==10L && !anyDuplicated(m$caminho_relativo),'Manifesto nao contem 10 entradas unicas.')
  for(i in seq_len(nrow(m))) {
    f <- file.path(pasta,m$caminho_relativo[i])
    assert_r29(file.exists(f),paste('Arquivo de entrada ausente:',m$caminho_relativo[i]))
    assert_r29(tolower(as.character(md5_r29(f)))==tolower(as.character(m$md5[i])),
               paste('MD5 diferente. Reextraia o ZIP:',m$caminho_relativo[i]))
    assert_r29(as.numeric(file.info(f)$size)==as.numeric(m$bytes[i]),
               paste('Tamanho inesperado:',m$caminho_relativo[i]))
  }
  m
}
write_r29 <- function(d,path) {
  dir.create(dirname(path),showWarnings=FALSE,recursive=TRUE)
  tmp <- paste0(path,'.tmp')
  utils::write.csv(d,tmp,row.names=FALSE,fileEncoding='UTF-8')
  ok <- file.copy(tmp,path,overwrite=TRUE)
  unlink(tmp)
  assert_r29(ok,paste('Falha ao salvar:',path))
}
save_r29 <- function(obj,path) {
  dir.create(dirname(path),showWarnings=FALSE,recursive=TRUE)
  tmp <- paste0(path,'.tmp')
  saveRDS(obj,tmp,compress=TRUE)
  ok <- file.copy(tmp,path,overwrite=TRUE)
  unlink(tmp)
  assert_r29(ok,paste('Falha ao salvar checkpoint:',path))
}
auc_r29 <- function(p,b) {
  p <- as.numeric(p); b <- as.numeric(b)
  if(length(p)<1L || length(b)<1L || any(!is.finite(c(p,b)))) return(NA_real_)
  (sum(rank(c(p,b),ties.method='average')[seq_along(p)]) -
     length(p)*(length(p)+1)/2)/(length(p)*length(b))
}
boyce_r29 <- function(p,b,nclass=0,rm_dup=TRUE) {
  avisos <- character()
  if(length(p)<2L || length(b)<2L || any(!is.finite(c(p,b))))
    return(list(valor=NA_real_,status='AMOSTRA_INVALIDA',HS=numeric(),PE=numeric()))
  z <- tryCatch(withCallingHandlers(ecospat::ecospat.boyce(
           fit=as.numeric(b),obs=as.numeric(p),nclass=nclass,
           PEplot=FALSE,method='spearman',rm.duplicate=rm_dup),
           warning=function(w) { avisos <<- c(avisos,conditionMessage(w));invokeRestart('muffleWarning') }),
         error=function(e) { avisos <<- c(avisos,conditionMessage(e));NULL })
  if(is.null(z)) return(list(valor=NA_real_,status=paste('ERRO',paste(unique(avisos),collapse=' | ')),HS=numeric(),PE=numeric()))
  valor <- if(!is.null(z$cor)) z$cor else if(!is.null(z$Spearman.cor)) z$Spearman.cor else NA_real_
  valor <- as.numeric(valor)
  if(length(valor)!=1L || !is.finite(valor) || abs(valor)>1.00001) valor <- NA_real_
  hs <- if(!is.null(z$HS)) as.numeric(z$HS) else numeric()
  pe <- if(!is.null(z$F.ratio)) as.numeric(z$F.ratio) else numeric()
  list(valor=valor,status=if(length(avisos)) paste('AVISO',paste(unique(avisos),collapse=' | ')) else if(is.finite(valor)) 'OK' else 'INDEFINIDO',
       HS=hs,PE=pe)
}
plot_pe_r29 <- function(p,b,boyce_obj,path,titulo) {
  png(path,width=1150,height=770,res=130)
  on.exit(dev.off(),add=TRUE)
  par(mar=c(5.5,5.2,4.8,1.5))
  hs <- boyce_obj$HS; pe <- boyce_obj$PE
  ok <- length(hs)==length(pe) & length(hs)>=2L
  if(!ok) {
    plot.new();text(.5,.5,'Curva P/E indisponivel para este conjunto');title(main=titulo)
  } else {
    v <- which(is.finite(hs) & is.finite(pe) & pe>=0)
    if(length(v)<2L) {
      plot.new();text(.5,.5,'P/E com poucos intervalos finitos');title(main=titulo)
    } else {
      ymax <- max(1,stats::quantile(pe[v],probs=.99,na.rm=TRUE,names=FALSE)*1.1)
      plot(hs[v],pmin(pe[v],ymax),xlab='Adequabilidade prevista (cloglog)',
           ylab='Razao presencas / disponibilidade (P/E)',main=titulo,
           pch=16,cex=.5,col='#396F86',ylim=c(0,ymax))
      abline(h=1,lty=2,col='gray50');grid(col='gray90')
      mtext(paste('Boyce:',if(is.finite(boyce_obj$valor))
           sprintf('%.3f',boyce_obj$valor) else 'indefinido',
           '| intervalos:',length(pe)),side=3,line=.2,cex=.8)
    }
  }
}
plot_scores_r29 <- function(p,b,limiar,path,titulo) {
  png(path,width=1150,height=770,res=130)
  on.exit(dev.off(),add=TRUE)
  par(mar=c(5.5,5.2,4.5,1.4))
  hist(b,breaks=30,probability=TRUE,col=grDevices::adjustcolor('#9ca3af',alpha.f=.7),
       border=NA,xlim=c(0,1),main=titulo,xlab='Score cloglog',ylab='Densidade')
  hist(p,breaks=30,probability=TRUE,col=grDevices::adjustcolor('#2b7fad',alpha.f=.55),
       border=NA,add=TRUE)
  abline(v=limiar,lty=2,lwd=2,col='red3')
  legend('topright',legend=c('Background','Presencas','P10 treino'),
         fill=c('#9ca3af','#2b7fad',NA),border=NA,bty='n')
}
