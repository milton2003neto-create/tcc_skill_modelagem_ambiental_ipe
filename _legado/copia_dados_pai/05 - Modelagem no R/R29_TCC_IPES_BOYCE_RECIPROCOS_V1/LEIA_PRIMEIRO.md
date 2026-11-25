# R29 — Auditoria Boyce/P10 e quatro modelos recíprocos

**TCC Ipês • 18/11/2026 • versão 1**

Este pacote dá sequência ao R28 V1.1, usando exclusivamente as **27 propriedades e 64 UPAs inventariadas do desenvolvimento**. As sete propriedades externas de teste não estão presentes nas entradas. Nenhum arquivo anterior é alterado.

## Execução no RStudio

1. Extraia **a pasta inteira** `R29_TCC_IPES_BOYCE_RECIPROCOS_V1` dentro de `05 - Modelagem no R` (não mova os scripts isoladamente).
2. Abra `R29_01_AUDITAR_BOYCE_R28.R` e clique em **Source**. Essa etapa lê as seis previsões do R28 e as métricas originais, recalcula **AUC, limiar P10, omissão e Boyce** no R com `ecospat`; produz curvas P/E e histogramas. **Não ajusta modelos.**
3. Confira no arquivo `03_RESULTADOS_R29_V1/01_AUDITORIA_BOYCE/29_CONFERENCIA_BOYCE_R28.csv` a coluna `status`. Se houver `REVER_BOYCE_DIVERGENTE`, registre o alerta e envie a tabela para avaliação; o R29 não altera a série original.
4. Abra `R29_02_AJUSTAR_4_RECIPROCOS.R` e clique em **Source**. Essa etapa ajusta **quatro novos modelos `maxnet`** em sentidos recíprocos. Os resultados vão para `03_RESULTADOS_R29_V1/02_TESTES_RECIPROCOS`.
5. Ao concluir, compacte a pasta `03_RESULTADOS_R29_V1` e envie para auditoria.

Não há seleção manual de arquivos. O ZIP já contém **cópias** das bases necessárias. O manifesto `29_MANIFESTO_ENTRADAS.csv` registra MD5 e tamanho de 10 arquivos-fonte; os scripts checam integridade antes de processar. `R29_FUNCOES.R` deve ficar na mesma pasta que os dois scripts.

## O que está sendo testado

| Espécie | Treinamento | Validação | Presenças treino/validação | BG treino/validação |
|---|---|---|---:|---:|
| Ipê-roxo | Hermes UPA 01 | Hermes UPA 03 | 233 / 212 | 273 / 131 |
| Ipê-roxo | Hermes UPA 03 | Hermes UPA 01 | 212 / 233 | 131 / 273 |
| Ipê-amarelo | Limão UPA 02 | Limão UPA 03 | 187 / 206 | 137 / 141 |
| Ipê-amarelo | Limão UPA 03 | Limão UPA 02 | 206 / 187 | 141 / 137 |

Configuração de referência: features **LQH**, **RM=4**, seis preditores (altitude, declividade, distância raster aos rios, BIO12, BIO17 e textura como fator), `addsamplestobackground=TRUE`, previsão `cloglog` com `clamp=TRUE`. O limiar de omissão P10 é calculado **apenas nas presenças de treinamento**. A AUC e o Boyce usam presenças e background da UPA reservada. Os resultados são **exploratórios e locais**, não representam transferência entre regiões independentes.

### Ressalva importante sobre solo

No teste **RECIP_AMARELO_1**, a classe textural **4** está presente na validação (7 árvores e 5 pontos BG) mas ausente da UPA de treinamento. Os scripts **não excluem, não recodificam nem imputam** esses registros; mantêm os níveis originais do fator e sinalizam a extrapolação categórica. Não interpretar o modelo como tendo aprendido uma resposta para essa classe de solo. Um estudo de sensibilidade sem solo, em **ambos** os sentidos do recíproco, pode ser discutido depois, se necessário.

### Ressalvas metodológicas

- Treinamento com **131 a 273 pontos de background**, pouco para generalização robusta. Não confundir com os modelos locais R28 que usam milhares de pontos B2 de treinamento. Comparações devem ser descritivas, não equivalência estatística.
- UPAs contíguas ou próximas podem apresentar dependência espacial; AUC alta **não** garante independência.
- Background é disponibilidade e **não ausência**.
- Os testes 50/50 aleatórios do R27 não estão sendo executados aqui; continuam previstos como comparador exploratório posterior.
- Não escolher o modelo final pelo maior Boyce/AUC e não utilizar as sete propriedades externas nesta etapa.
- O R29 não reexecuta o R19 nem o R28 e não modifica os folds anteriores.

## Conferências já feitas com Python, antes da entrega

`29_PRECHECK_AUC_P10_SEM_R.csv` confirma AUC/P10/omissão dos seis modelos do R28 a partir das previsões. `29_PRECHECK_4_RECIPROCOS_SEM_R.csv` confere quantidade de presenças, background e classes novas para os quatro recíprocos. **O Boyce com a mesma versão de R/ecospat ainda precisa ser reproduzido no RStudio.**

## Saídas previstas

**Etapa 1:** tabela de verificação Boyce R28, CSV das curvas P/E, PNGs por modelo com P/E e scores, relatório e `sessionInfo()`.

**Etapa 2:** tabela de QA de solo, quatro RDS oficiais, checkpoints de retomada, previsões CSV, quatro tabelas de métricas (parcial e final), gráficos de scores e P/E, relatório e `sessionInfo()`.

**Requisitos conferidos no R28:** `maxnet 0.1.4`, `ecospat 4.1.4`. O script verifica as versões, sem instalar pacotes nem modificar o ambiente.

## Documentação técnica

- Boyce no ecospat: https://cran.rstudio.com/web/packages/ecospat/refman/ecospat.html
- Maxnet: https://cran.csail.mit.edu/web/packages/maxnet/refman/maxnet.html
