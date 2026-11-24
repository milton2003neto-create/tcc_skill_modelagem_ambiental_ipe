# TCC Ipês — Auditoria independente da segunda parte do R29

**Arquivo analisado:** `02_TESTES_RECIPROCOS.zip` (31 entradas, incluindo pastas); integridade ZIP conferida.  
**Escopo:** quatro experimentos recíprocos entre duas UPAs por ajuste, duas espécies; configuração maxnet LQH/RM4, seis preditores e background B2 da UPA correspondente.  
**Decisão:** **execução e métricas recalculadas aprovadas para comparação exploratória local, sem modelo final aprovado**.

## 1. Resultados

| Espécie | Treino → validação | Presenças de treino/validação | BG treino/validação | AUC treino | AUC validação | Boyce informado | P10 treino | Omissão validação | BG acima P10 |
|---|---|---|---|---:|---:|---:|---:|---:|---:|
| Roxo | Hermes 01 → 03 | 233 / 212 | 273 / 131 | 0,6276 | 0,5796 | 0,479 | 0,5829 | 9/212 (4,25%) | 117/131 (89,31%) |
| Roxo | Hermes 03 → 01 | 212 / 233 | 131 / 273 | 0,6740 | 0,5155 | 0,496 | 0,4923 | 58/233 (24,89%) | 186/273 (68,13%) |
| Amarelo | Limão 02 → 03 | 187 / 206 | 137 / 141 | 0,6433 | 0,6746 | 0,814 | 0,5590 | 112/206 (54,37%) | 45/141 (31,91%) |
| Amarelo | Limão 03 → 02 | 206 / 187 | 141 / 137 | 0,6845 | 0,6098 | 0,807 | 0,5699 | 8/187 (4,28%) | 110/137 (80,29%) |

AUC significa discriminação entre presenças e background (não ausências confirmadas). Boyce não foi reproduzido independentemente nesta auditoria.

## 2. Conferências realizadas

- Os quatro arquivos de previsões possuem, juntos, **3.040 registros**, sem valores de score ausentes.
- Em cada ajuste, não há sobreposição dos identificadores das presenças nem dos pontos B2 de treinamento e validação.
- **AUC de treinamento e validação, quantil 0,10 do treino, omissão P10 e fração de background acima do P10** foram recalculados a partir das previsões; discrepâncias numéricas inferiores a 1e-12.
- Os arquivos `29_METRICAS_4_RECIPROCOS.csv` e `29_METRICAS_PARCIAIS.csv` são idênticos.
- Há quatro arquivos de modelo RDS e quatro checkpoints, mas **não** foi feita reprodução dos ajustes no R/maxnet a partir dos arquivos originais. Curvas P/E e distribuições dos scores foram inspecionadas visualmente.

## 3. Interpretação principal

A direção do teste altera o desempenho. Em Hermes, a AUC diminui de 0,580 para 0,516 quando a direção é invertida, e a omissão sobe de 4,25% para 24,89%. Em Limão, a AUC é 0,675 num sentido e 0,610 no outro, mas a omissão varia muito mais: 54,37% versus 4,28%.

No sentido Limão 02 → 03, a mediana dos scores das presenças de validação (**0,5520**) fica **abaixo** do limiar P10 do treino (**0,5590**). No sentido inverso, a mediana das presenças (**0,7006**) fica acima de seu P10 (**0,5699**). Isso ajuda a explicar a diferença de omissão, sem provar uma causa ecológica.

Os valores de Boyce informados para Limão (0,814 e 0,807) são altos apesar de uma das direções ter omissão de 54,37%: os indicadores avaliam aspectos diferentes. Não aprovar o experimento pelo Boyce isolado.

## 4. Solo: classe não representada no treino

Em Limão 02 → 03, a **classe 4** de solo está ausente do treinamento (classes observadas 2 e 3), mas aparece em **7/206 presenças (3,40%)** e **5/141 pontos de background (3,55%)** na validação. Esses scores envolvem extrapolação categórica. Nenhum dado deve ser recodificado, eliminado ou imputado para ocultar a situação.

A classe nova **não explica sozinha a omissão elevada**. Mesmo no cenário extremo em que as sete presenças da classe 4 estivessem todas entre as 112 omitidas, ao menos **105 das outras 199 presenças (52,76%)** continuariam omitidas. Portanto, a dificuldade de transferência nesse sentido não se restringe à classe inédita.

## 5. Limitações científicas

1. Os ajustes foram calibrados com apenas **131–273 pontos de background**, número muito inferior ao usado nos modelos regionais; por isso, os resultados são estudos de caso locais, não seleção final de parâmetros.
2. Hermes 01/03 tem distância aproximada de 0,678 km entre limites e Limão 02/03 tem distância geométrica 0 km. Não há independência espacial regional.
3. AUC, Boyce, omissão e P10 não podem ser comparados como se as duas direções fossem avaliações sobre a mesma amostra de validação; os conjuntos mudam entre direções.
4. As curvas P/E apresentam irregularidades; o Boyce calculado com muitos intervalos pode ser sensível às opções do ecospat. A parte 1 do R29 já examinou tal sensibilidade para os seis modelos R28, mas ela não foi repetida para estes quatro ajustes.
5. Não foi feito teste externo, e não há evidência de desempenho em outras propriedades a partir deste experimento isolado.

## 6. Próxima decisão com pouco tempo

- **Guardar R29 como experimento local complementar concluído.** Não refazer esses quatro modelos nem alterar os dados para melhorar os índices.
- Se a comparação aleatória 50/50, inspirada em Gracialda, for indispensável ao escopo acordado, fazer apenas **dois modelos exploratórios** (um por espécie), marcados claramente como não independentes espacialmente, usando a mesma configuração de referência. Não usar sua AUC para selecionar a configuração final.
- Consolidar R19 (propriedades), R28 (painéis UPAs) e R29 (recíprocos), com avaliação de AUC/Boyce/omissão e limitação por escala; selecionar protocolo e parâmetros para o ajuste definitivo com critérios transparentes no desenvolvimento.
- **Manter as sete propriedades externas intocadas** até fechar o protocolo final; avaliar o teste apenas uma vez. Antes de mapas finais, resolver a pendência cadastral de Saudade.

**Arquivo complementar:** `29_AUDITORIA_INDEPENDENTE_RECALCULOS.csv` contém os valores recalculados por ajuste.
