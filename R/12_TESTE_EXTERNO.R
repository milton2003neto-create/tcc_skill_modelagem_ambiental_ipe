# =============================================================================
# 12_TESTE_EXTERNO.R
# -----------------------------------------------------------------------------
# O QUE FAZ: avaliacao CONFIRMATORIA final. Treina o modelo escolhido na busca
#            (R/11) com as 27 propriedades de desenvolvimento e o avalia UMA
#            VEZ nas 7 propriedades reservadas (teste externo independente).
#            Cada abertura fica registrada em
#            resultados/_geral/REGISTRO_TESTE_EXTERNO.csv (com impressao MD5).
# PROTOCOLO FINAL (definido ANTES de abrir o teste, pela busca LOPO):
#   roxo   : Altitude + BIO17; feature L; RM 1 (parcimonia: empatado com o
#            1o colocado, com menos variaveis)
#   amarelo: Distancia a hidrografia + BIO12 + Solo; features LQH; RM 2
#   ambos  : background B2, clamping, cloglog, 3 folds internos por propriedade
# SAIDAS : as mesmas das etapas 2-6 + resultados/_geral/teste_externo/<data_hora>/
#          RESULTADO_TESTE_EXTERNO.csv
# =============================================================================

if (!exists("validar_modelo")) source(file.path("R", "09_VALIDACAO.R"), encoding = "UTF-8")

PROTOCOLO_FINAL <- list(
  roxo    = list(variaveis = c("altitude_m", "bio17_mm_mes"), features = "l", rm = 1),
  amarelo = list(variaveis = c("dist_rio_raster_m", "bio12_mm_ano", "textura_subgrupo"), features = "lqh", rm = 2))

teste_externo <- function(especie, prot = PROTOCOLO_FINAL[[especie]]) {
  base <- carregar_base_completa(especie)
  plano <- recomendar_plano(base, modo = "propriedade", usar_reservadas = TRUE, k_folds = 3)
  u <- plano$unidades
  stopifnot(all(u$reservada[u$papel == "validacao"]), all(!u$reservada[u$papel == "treino"]),
            setequal(u$propriedade[u$papel == "validacao"], PROPRIEDADES_RESERVADAS))
  pasta_plano <- salvar_plano(plano, base)
  av <- analisar_variaveis(plano, base); pasta_var <- salvar_variaveis(av, prot$variaveis, pasta_plano)
  bg <- preparar_background(plano, base, "b2"); grade <- grade_parametros(prot$features, prot$rm)
  pasta_cfg <- salvar_config(especie, plano, base, bg, prot$variaveis, grade, TRUE, NULL, pasta_plano, pasta_var)
  cfg <- readRDS(file.path(pasta_cfg, "CONFIG_MODELAGEM.rds"))
  tr <- rodar_grade(cfg, base); m <- grade$modelo
  jk <- rodar_jackknife(tr, m, base); roc <- roc_modelo(tr, m, base)
  pasta_tr <- salvar_treino(tr, m, jk, roc, pasta_cfg)
  me <- readRDS(file.path(pasta_tr, "MODELO_ESCOLHIDO.rds"))
  va <- validar_modelo(me, base, pasta_tr, confirmar_externo = TRUE)
  pasta_va <- salvar_validacao(va, base, "todas")
  list(va = va, tr = tr, jk = jk, pasta_treino = pasta_tr, pasta_validacao = pasta_va)
}

rodar_teste_externo <- function(especies = names(PROTOCOLO_FINAL)) {
  pasta <- file.path(PASTA_RESULTADOS, "_geral", "teste_externo", format(Sys.time(), "%Y-%m-%d_%H%M%S"))
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE); out <- list()
  for (e in especies) {
    r <- teste_externo(e); c <- r$va$comparacao; pu <- r$va$por_unidade
    out[[e]] <- data.frame(especie = ESPECIES[[e]], modelo = r$tr$recomendado,
      variaveis = paste(VARIAVEIS[PROTOCOLO_FINAL[[e]]$variaveis], collapse = "; "),
      auc_treino = round(c$auc[1], 3), auc_cv = round(c$auc[2], 3), omissao_p10_cv = round(c$omissao_p10[2], 3),
      auc_externo = round(c$auc[3], 3), omissao_p10_externo = round(c$omissao_p10[3], 3), omissao_mtp_externo = round(c$omissao_mtp[3], 3),
      boyce_externo = round(c$boyce[3], 3), pres_externo = c$n_presencas[3], bg_externo = c$n_background[3],
      por_propriedade = paste(sprintf("%s: n=%d, AUC dentro=%s, omissao=%.0f%%", pu$unidade, pu$n_presencas,
                                      ifelse(is.na(pu$auc_dentro), "-", sprintf("%.2f", pu$auc_dentro)), 100 * pu$omissao_p10), collapse = " | "),
      pasta_validacao = r$pasta_validacao)
    salvar_csv(do.call(rbind, out), pasta, "RESULTADO_TESTE_EXTERNO.csv")
  }
  invisible(do.call(rbind, out))
}
