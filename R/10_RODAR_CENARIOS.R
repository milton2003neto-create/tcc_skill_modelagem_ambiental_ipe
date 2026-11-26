# =============================================================================
# 10_RODAR_CENARIOS.R
# -----------------------------------------------------------------------------
# O QUE FAZ: roda o fluxo completo (etapas 2 a 6) SEM o app, para varios
#            cenarios e as duas especies, usando sempre as RECOMENDACOES da
#            ferramenta, e monta uma tabela comparativa. Cada cenario grava as
#            mesmas saidas do app (plano, variaveis, configuracao, treino,
#            validacao), com log.
#            NAO abre o teste externo: as reservadas ficam protegidas.
# CENARIOS:
#   S1_base      propriedade x propriedade; variaveis recomendadas; B2
#   S2_sem_clima igual ao S1, sem BIO12 e BIO17 (testa se o modelo so
#                "reconhece a regiao" pelo clima de escala grossa)
#   S3_upa       UPA x UPA (transferencia local; cf. Ferreira, 2009)
# SAIDA   : resultados/_geral/cenarios/<data_hora>/COMPARACAO_CENARIOS.csv
# USO     : source("R/10_RODAR_CENARIOS.R"); rodar_cenarios()
# =============================================================================

if (!exists("validar_modelo")) source(file.path("R", "09_VALIDACAO.R"), encoding = "UTF-8")

CENARIOS <- list(
  S1_base      = list(modo = "propriedade", remover = character()),
  S2_sem_clima = list(modo = "propriedade", remover = c("bio12_mm_ano", "bio17_mm_mes")),
  S3_upa       = list(modo = "upa",         remover = character()))

rodar_um_cenario <- function(especie, nome, cen, base) {
  t0 <- Sys.time(); message(sprintf("[%s] %s %s: plano...", format(Sys.time(), "%H:%M"), especie, nome))
  plano <- recomendar_plano(base, modo = cen$modo); pasta_plano <- salvar_plano(plano, base)
  av <- analisar_variaveis(plano, base)
  vars <- setdiff(if (length(cen$remover)) names(VARIAVEIS) else av$recomendadas, cen$remover)
  pasta_var <- salvar_variaveis(av, vars, pasta_plano)
  bg <- preparar_background(plano, base, "b2"); rg <- recomendar_grade()
  grade <- grade_parametros(rg$features, rg$rm)
  pasta_cfg <- salvar_config(especie, plano, base, bg, vars, grade, TRUE, NULL, pasta_plano, pasta_var)
  cfg <- readRDS(file.path(pasta_cfg, "CONFIG_MODELAGEM.rds"))
  message("   grade...")
  tr <- rodar_grade(cfg, base); esc <- tr$recomendado
  message("   jackknife + ROC (", esc, ")...")
  jk <- rodar_jackknife(tr, esc, base); roc <- roc_modelo(tr, esc, base)
  pasta_tr <- salvar_treino(tr, esc, jk, roc, pasta_cfg)
  me <- readRDS(file.path(pasta_tr, "MODELO_ESCOLHIDO.rds"))
  message("   validacao...")
  va <- validar_modelo(me, base, pasta_tr); pasta_va <- salvar_validacao(va, base, "validacao")
  r <- tr$resumo[tr$resumo$modelo == esc, ]; cmp <- va$comparacao
  so <- jk[jk$tipo == "Somente a variavel", ]; top <- so$variavel[which.max(so$auc_teste)]
  data.frame(especie = especie, cenario = nome, desenho = cen$modo, variaveis = paste(vars, collapse = "+"),
    n_unid_validacao = sum(plano$unidades$papel == "validacao"),
    validacao = paste(plano$unidades$unidade[plano$unidades$papel == "validacao"], collapse = "; "),
    pres_treino = cmp$n_presencas[1], pres_validacao = cmp$n_presencas[3], modelo = esc,
    auc_treino = round(cmp$auc[1], 3), auc_cv = r$auc_teste, auc_cv_dp = r$auc_teste_dp, omissao_p10_cv = r$omissao_p10,
    auc_validacao = round(cmp$auc[3], 3), omissao_p10_validacao = round(cmp$omissao_p10[3], 3), boyce_validacao = round(cmp$boyce[3], 3),
    auc_dentro_unidade_media = round(mean(va$por_unidade$auc_dentro, na.rm = TRUE), 3),
    var_mais_importante_jk = VARIAVEIS[[top]], auc_jk_so_ela = round(max(so$auc_teste, na.rm = TRUE), 3),
    avisos_validacao = paste(va$avisos[-1], collapse = " | "),
    pasta_treino = pasta_tr, pasta_validacao = pasta_va, minutos = round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1))
}

rodar_cenarios <- function(especies = names(ESPECIES), cenarios = names(CENARIOS)) {
  pasta <- file.path(PASTA_RESULTADOS, "_geral", "cenarios", format(Sys.time(), "%Y-%m-%d_%H%M%S"))
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE); out <- list()
  for (e in especies) {
    base <- carregar_base_completa(e)
    for (c in cenarios) {
      r <- tryCatch(rodar_um_cenario(e, c, CENARIOS[[c]], base), error = function(err) {
        message("   ERRO: ", conditionMessage(err)); data.frame(especie = e, cenario = c, erro = conditionMessage(err)) })
      out[[paste(e, c)]] <- r
      tab <- do.call(rbind, lapply(out, function(x) { for (n in setdiff(names(out[[1]]), names(x))) x[[n]] <- NA; x[, names(out[[1]])] }))
      salvar_csv(tab, pasta, "COMPARACAO_CENARIOS.csv")   # salva a cada cenario (nada se perde se parar no meio)
    }
  }
  registrar_log(pasta, "cenarios", escolhas = list(especies = especies, cenarios = cenarios, criterio = "recomendacoes da ferramenta"),
                mensagens = "Teste externo (reservadas) NAO aberto.")
  message("Comparacao salva em: ", pasta)
  invisible(tab)
}
