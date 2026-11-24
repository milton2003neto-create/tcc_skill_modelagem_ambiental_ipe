# Auditoria científica — R29 Parte 3: referência aleatória 50/50

**Data:** 18 de novembro de 2026  
**Fonte:** `03_RESULTADOS_ALEATORIO_50_50_V1.zip` (22 entradas, duas avaliações MaxEnt).  
**Status:** consistência numérica aprovada; desempenho restrito ao desenho aleatório exploratório. **Não há validação espacial independente.**

## 1. Protocolo e integridade

- MaxEnt por `maxnet`, seis preditores, features LQH, RM=4, previsão cloglog, textura do solo categórica.
- Divisão congelada do R27, aleatória 50/50 dentro de cada UPA por espécie, com UPAs compartilhadas entre treino e validação.
- B2 com 10.000 pontos, divididos em 4.986 no treinamento e 5.014 na validação, em ambos os modelos.
- Ipê-roxo: 1.620 presenças em treino e 1.628 em validação. Ipê-amarelo: 2.706 em treino e 2.726 em validação.
- Os MD5 dos quatro arquivos de entrada disponíveis no ambiente coincidem com o manifesto da execução. O arquivo ZIP passou no teste de integridade. Não há IDs de presença nem IDs de background repetidos entre treino e validação em cada espécie. Os scores são finitos e pertencem a [0,1].
- Recalculei AUC de treinamento e validação com ranks médios para empates, o décimo percentil das presenças de treinamento, omissão com score < P10, proporção de background >= P10 e AUC por propriedade e UPA; todas as contas conferem com os CSVs originais, com tolerância < 1e-9.
- Métricas parciais e finais são coincidentes. Os dois objetos RDS finais foram encontrados, mas **não foram reproduzidos por reajuste ou execução independente de `maxnet`**.

## 2. Resultados

| Métrica | Ipê-roxo | Ipê-amarelo |
|---|---:|---:|
| AUC treino | 0,866650 | 0,803917 |
| AUC validação global | 0,870594 | 0,800885 |
| AUC validação dentro das propriedades, ponderada por pares | 0,586852 | 0,578560 |
| AUC validação dentro das UPAs, ponderada por pares avaliáveis | 0,572039 | 0,554503 |
| Boyce original, informado pelo R29 | 0,822 | 0,999 |
| Boyce nclass=10, informado pelo R29 | 0,400 | 1,000 |
| Limiar P10 treino (cloglog) | 0,565519 | 0,452361 |
| Omissão P10 validação | 9,8280% | 9,9413% |
| Background de validação acima ou no P10 | 23,4743% | 47,7064% |
| Coeficientes ativos | 15 | 18 |

**Ressalva sobre Boyce:** transcrevi os dois índices dos arquivos originais; não os reproduzi independentemente via `ecospat`. A diferença para o roxo entre os dois parâmetros indica sensibilidade da métrica.

## 3. Principais achados interpretativos

**AUC global elevada não representa desempenho local equivalente.** Aproximadamente 96,33% (roxo) e 95,46% (amarelo) dos pares presença–background comparados globalmente são de propriedades diferentes. Quando restringimos as comparações à própria propriedade ou UPA, as AUCs aproximam-se de 0,55–0,59. Os valores internos foram ponderados pelos pares avaliáveis, respeitando a convenção de AUC presença–background.

**Omissões de 100% persistem em algumas propriedades, apesar das médias globais próximas de 10%:**

- Ipê-roxo: Cedro (42/42), Safira (31/31), Santa Lúcia (33/33) e Topázio (29/29). Somam **135 das 160 presenças omitidas no roxo**.
- Ipê-amarelo: Águas Claras (36/36), Guajará (22/22), Mururé (8/8) e Paraíso (12/12). Somam 78 das 271 presenças omitidas no amarelo.

Esses resultados revelam heterogeneidade entre regiões e propriedades que a omissão global do sorteio 50/50 não mostra. Alguns grupos têm amostras pequenas, e suas proporções locais têm maior incerteza.

**Por que 50/50 tende a gerar números favoráveis?** O sorteio foi feito dentro de UPAs compartilhadas entre treinamento e validação; em consequência, os conjuntos são espacial e ambientalmente semelhantes. A estabilidade entre AUC de treino e validação não prova transferência para novas UPAs ou propriedades independentes. Como o background não é ausência confirmada, a AUC avalia ordenação relativa presença–background, e o percentual acima do limiar não é taxa de falsos positivos.

## 4. Comparação com os painéis locais R28

A média simples das AUCs dos três painéis LQH/RM4 R28 foi 0,468 para ipê-roxo e 0,667 para ipê-amarelo. O experimento R29 50/50 produziu 0,871 e 0,801. **Essa diferença não deve ser atribuída a uma melhora do MaxEnt**, pois o desenho de validação mudou: o R28 reserva UPAs inteiras, enquanto o R29 randomiza presenças dentro das mesmas UPAs.

## 5. Decisão e próxima etapa

1. Aprovar o **processamento** dos dois modelos 50/50 e registrar esses resultados como **referência aleatória exploratória**.
2. Não utilizar as AUCs do 50/50 como critério principal de seleção de modelo ou evidência de validação espacial independente.
3. Completar a grade local dos seis painéis por UPA: 3 classes de features (L, LQ, LQH) × 4 RM (1–4) × 6 painéis = 72 avaliações. Se os seis modelos LQH/RM4 do R28 tiverem dados e parâmetros idênticos aos exigidos pela grade, reutilizá-los depois da auditoria de identidade, realizando 66 novos ajustes.
4. Congelar os seis painéis atuais, sem revisá-los conforme desempenho visto, e informar expressamente que novos ajustes nesses painéis são análise exploratória de sensibilidade, sujeitos a viés de seleção.
5. Comparar também AUC por UPA/propriedade, Boyce com sensibilidade de classes, omissão P10, complexidade e cobertura ambiental. Não usar o teste externo de sete propriedades durante ajuste de configurações.
6. Após definir um protocolo de seleção com os dados de desenvolvimento, reajustar os modelos finais e consultar as sete propriedades externas uma única vez, sem novos ajustes motivados pelo teste.

**Conclusão:** o 50/50 confirma que o MaxEnt obtém AUC global alta ao compartilhar áreas entre treinamento e validação. Porém, a discriminação local é apenas moderada ou fraca, e várias propriedades ainda apresentam omissão total. A comparação por escala espacial deve permanecer no centro da interpretação do TCC.
