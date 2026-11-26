## Ajuda: o que é cada coisa (explicado sem jargão)

### O que esta ferramenta faz
Ela tenta descobrir **em que tipo de ambiente** os ipês foram encontrados nos inventários e
**se esse padrão se repete em outras áreas**. Para isso usa o **MaxEnt** (pacote `maxnet` do R).

### Passo a passo (faça na ordem; escolha a espécie na barra lateral)

| Aba | O que fazer | O que olhar |
|---|---|---|
| **1. Diagnóstico** | Clique em *Rodar diagnóstico*. | Se as presenças estão concentradas em poucas propriedades, se algum fold é pequeno e se há novidade ambiental. Isso explica resultados ruins **antes** de modelar. |
| **2. Treino / Validação** | Escolha *propriedade × propriedade* ou *UPA × UPA* → *Gerar recomendação* → ajuste as listas se quiser → *Aplicar* → *Salvar plano*. | Avisos vermelhos (críticos) e amarelos. A tabela **Composição dos folds** é a que vai no TCC. |
| **3. Variáveis** | *Analisar variáveis* → marque as que entram → *Salvar escolha*. | Pares muito correlacionados (\|r\| > 0,7) e VIF alto. Se manter duas parecidas, justifique. |
| **4. Background e parâmetros** | *Preparar background* → escolha features e RM → *Estimar tempo e memória* → *Salvar configuração*. | Tempo estimado e memória livre. Feche outros programas se avisar. |
| **5. Treinamento** | Escolha a configuração → *Rodar todos os modelos* → (opcional) clique em outro modelo → *Jackknife + ROC* → *Salvar treinamento*. | Omissão P10 perto de 10%, AUC de teste alta e diferença treino–teste pequena. |
| **6. Validação** | Escolha o treinamento → *Validar* → *Salvar + exportar*. | Queda da AUC do treino para a validação, AUC dentro de cada propriedade e presenças omitidas no mapa. Os `.tif` e `.gpkg` abrem no QGIS. |

Tudo é salvo em `resultados/<espécie>/<etapa>/<data_hora>/`, com um arquivo **LOG** contendo todas as escolhas.
Para retomar outro dia, as abas 5 e 6 carregam o que já foi salvo.

### Palavras importantes

| Termo | Em palavras simples |
|---|---|
| **Presença** | Um ponto onde uma árvore de ipê (DAP > 10 cm) foi inventariada. Guardamos só 1 por quadradinho de 30 m × 30 m (pixel), para não contar duas vezes o mesmo lugar. |
| **Background** | Pontos sorteados dentro das UPAs inventariadas que representam **o ambiente disponível**. **Não** são lugares onde o ipê "não existe" — são uma amostra do que havia para ele escolher. |
| **Propriedade / UPA** | Propriedade = o imóvel/empreendimento. UPA = Unidade de Produção Anual, a área inventariada dentro dele. |
| **Variáveis** | As características do ambiente: altitude, declividade, distância ao rio, chuva anual (BIO12), chuva no trimestre mais seco (BIO17) e textura do solo. |
| **Treino** | Os dados que o modelo "estuda" para aprender o padrão. |
| **Validação** | Dados que o modelo **nunca viu**, usados para conferir se ele acerta. |
| **Fold** | Um "grupo" de propriedades. Treinamos com alguns grupos e testamos no que ficou de fora, revezando. |
| **AUC** | De 0 a 1. Mede se o modelo dá nota maior para presenças do que para o background. **0,5 = chute**; acima de 0,7 é razoável; acima de 0,75 foi o corte usado por Ferreira (2009). Com background (e não ausências reais), a AUC costuma ser mais baixa. |
| **Curva ROC** | O gráfico que gera a AUC: mostra acertos (presenças captadas) × "alarmes" (background marcado como bom) em todos os limiares. |
| **Omissão (P10)** | % das presenças de validação que o modelo considerou "ruins" (nota abaixo da nota de 90% das presenças de treino). **Ideal ≈ 10%**. 100% = o modelo errou todas. |
| **Boyce** | De −1 a 1. Mostra se áreas com nota alta realmente têm mais presenças. Perto de 1 = bom; perto de 0 ou negativo = ruim. |
| **Features (L, Q, H)** | Formas que a resposta pode ter: L = reta, Q = curva (sobe e desce), H = "degraus" flexíveis. LQH é mais flexível, mas pode decorar os dados. |
| **RM (regularização)** | Freio contra "decorar". RM maior = modelo mais simples e suave. |
| **Jackknife** | Testa cada variável **sozinha** e o modelo **sem ela**, para ver quais informam mais e quais são exclusivas. |
| **Correlação / VIF** | Mostram variáveis que "dizem a mesma coisa" (redundantes). Ex.: BIO12 e BIO17 podem andar juntas. |
| **Novidade ambiental** | Quando a área de validação tem condições (ex.: chuva) que **não existiam** no treino. O modelo tem que "adivinhar" fora do que conhece → costuma errar. |
| **Gini / Curva de Lorenz** | Medem concentração: Gini 0 = presenças espalhadas igualmente entre propriedades; perto de 1 = quase tudo em poucas propriedades. |
| **Limiar P10** | A nota acima da qual estão 90% das presenças de treino. Usado para dizer "adequado" ou "não adequado" no mapa binário. |
| **MTP** | Limiar mais permissivo: a **menor** nota entre as presenças de treino. |
| **Ganho (gain)** | Quanto o modelo é melhor do que "chutar uniforme". Usado no Jackknife, como no MaxEnt Java. Ganho de teste negativo = a variável atrapalha em áreas novas. |
| **AICc** | Critério que penaliza modelos com muitos coeficientes. Menor = melhor equilíbrio entre ajuste e simplicidade. |
| **Clamping** | Fora da faixa de valores do treino, o modelo "congela" a resposta no último valor conhecido, em vez de extrapolar. |
| **Cloglog** | Escala da nota do modelo (0 a 1), interpretável como adequabilidade relativa. |
| **Validação cruzada em blocos** | Cada fold (grupo de propriedades) é deixado de fora uma vez e serve de teste; assim o teste é sempre numa área que o modelo não viu. |
| **Modo confirmatório** | Quando a validação usa as propriedades reservadas. O app pede confirmação e registra cada abertura, porque o teste externo só vale uma vez. |
| **N efetivo** | "Quantas propriedades iguais" os dados realmente valem. 12 propriedades com Gini alto podem valer só ~7. |

### Por que a AUC pode ficar baixa e a omissão alta?
1. **Poucas propriedades concentram as presenças** → o modelo aprende o ambiente delas e não generaliza.
2. **Folds desequilibrados** → um grupo pequeno dá métricas instáveis.
3. **Novidade ambiental** → a validação tem condições que o treino não viu.
4. **Background parecido com as presenças** → não há contraste para o modelo aprender.
5. **Presenças agrupadas** → pontos vizinhos repetem informação.

### Regra de ouro do teste final
O conjunto de **validação final** só pode ser usado **uma vez**, depois que tudo estiver escolhido.
Se você olhar o resultado e mudar o modelo, ele deixa de ser um teste independente.
A ferramenta registra e avisa.

### Como ler os resultados mais importantes

- **AUC de treino alta, mas de validação baixa** → o modelo aprendeu as propriedades do treino e não generaliza (transferência fraca).
- **AUC dentro da propriedade ≈ 0,5** → o modelo distingue **regiões**, mas não onde o ipê fica **dentro** da propriedade.
- **Jackknife: uma variável sozinha quase igual ao modelo completo** → o modelo depende praticamente dela. Se for uma variável de escala grossa (ex.: clima CHELSA), ela pode estar só "identificando a região".
- **Omissão P10 muito acima de 10% em uma propriedade** → confira a aba *Novidade ambiental*: provavelmente ela tem condições que o treino não tinha.
