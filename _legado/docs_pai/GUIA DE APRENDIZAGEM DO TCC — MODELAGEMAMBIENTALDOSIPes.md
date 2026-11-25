GUIA DE APRENDIZAGEM DO TCC — MODELAGEM AMBIENTAL DOS IPÊS

Manual para compreender o trabalho, interpretar os resultados e acompanhar o processamento com Claude

Destinado a quem vai ajudar no desenvolvimento do TCC, mas ainda não conhece modelagem ambiental, MaxEnt, QGIS ou R.

---

PARTE 1 — PRIMEIRO, ENTENDER O QUE É O TCC

1. Qual é o assunto da pesquisa?

O trabalho estuda duas espécies de árvores:

- Ipê-roxo: Handroanthus impetiginosus.
- Ipê-amarelo: Handroanthus serratifolius.

O objetivo é investigar quais condições ambientais estão associadas à ocorrência dessas árvores em florestas nativas sob manejo florestal no Pará.

Além disso, queremos descobrir se um modelo matemático, construído com registros de árvores encontrados em determinadas áreas, consegue prever adequadamente a ocorrência em outras áreas que não foram utilizadas para construir o modelo.

Em linguagem simples:

Imagine que temos milhares de registros de ipês encontrados em diferentes propriedades e UPAs. Para cada árvore, conseguimos conhecer algumas características do ambiente onde ela está localizada.

Por exemplo:

- A árvore está a 120 metros de altitude.
- Está em um terreno com declividade de 5 graus.
- Está a 80 metros de um rio.
- Está em uma região com determinada precipitação anual.
- Está em determinado tipo de solo.

A pergunta científica é:

Será que existe uma combinação de características ambientais que ajuda a explicar onde encontramos essas espécies?

E uma segunda pergunta:

Se aprendermos essas relações usando algumas propriedades, o modelo conseguirá identificar condições favoráveis em propriedades que não participaram do treinamento?

É isso que o TCC procura responder.

2. O que significa modelagem ambiental preditiva?

Modelagem ambiental preditiva é o uso de dados ambientais e métodos matemáticos para identificar padrões associados à ocorrência de uma espécie e estimar onde existem condições ambientais semelhantes.

Imagine que ensinamos um programa a reconhecer os ambientes onde encontramos ipês-roxos.

O programa recebe informações de milhares de registros e aprende relações entre as ocorrências e as variáveis ambientais.

Depois, ele analisa uma área dividida em milhares de pequenos pixels e atribui a cada pixel um valor de adequabilidade ambiental.

Exemplo ilustrativo:

Local| Adequabilidade estimada
Área A| 0,90
Área B| 0,75
Área C| 0,42
Área D| 0,12

Isso significa que, segundo o modelo, a Área A apresenta condições ambientais mais semelhantes às associadas às ocorrências utilizadas no treinamento.

Atenção: 0,90 não significa que existe 90% de chance de encontrar um ipê naquela área. É um valor relativo de adequabilidade produzido pelo modelo, sob determinadas configurações e pressupostos.

O mapa não é um inventário de árvores. Ele é uma estimativa baseada nas relações ambientais aprendidas.

3. O que é MaxEnt?

MaxEnt é o método de modelagem utilizado no trabalho.

O nome vem de Maximum Entropy, ou Máxima Entropia.

Não é necessário dominar a matemática interna para compreender sua finalidade.

Imagine que temos:

- 3.000 locais onde encontramos uma determinada espécie.
- 10.000 pontos que representam ambientes disponíveis nas áreas estudadas.
- Informações ambientais de todos esses pontos.

O MaxEnt compara as condições dos locais com registros de ocorrência com as condições ambientais disponíveis no domínio de estudo.

A partir disso, constrói uma função que estima a adequabilidade ambiental.

Uma comparação simples

Imagine que queremos entender em quais tipos de terreno encontramos mais frequentemente uma espécie.

Temos os registros das árvores e uma amostra dos ambientes disponíveis.

O modelo procura aprender quais combinações ambientais ajudam a diferenciar os locais de ocorrência dos ambientes disponíveis.

O MaxEnt não precisa de uma lista de ausências verdadeiras para funcionar. Ele trabalha com presença e background.

Essa distinção é fundamental para o nosso TCC.

4. O que é background?

Background significa ambiente disponível usado na comparação com os pontos de ocorrência.

Não é sinônimo de ausência.

Imagine uma UPA onde foram procuradas as duas espécies:

- Foram encontrados 20 ipês-roxos.
- Foram encontrados 35 ipês-amarelos.
- Existem também vários outros locais dentro da área onde as condições ambientais podem ser avaliadas.

Os pontos de background representam uma amostra desses ambientes disponíveis.

Eles ajudam o modelo a entender o contexto ambiental onde as espécies poderiam ocorrer.

No nosso trabalho, existe uma regra fundamental:

As UPAs sem inventário direcionado para as espécies não podem ser tratadas como locais sem ipês.

Elas não podem entrar no background como se tivessem sido pesquisadas e não tivessem apresentado ocorrências.

Nas UPAs efetivamente inventariadas, ambas as espécies foram procuradas sob o mesmo critério. Ainda assim, background não significa ausência comprovada.

---

PARTE 2 — CONHECER OS DADOS DO TCC

5. De onde vieram os dados?

O projeto utiliza inventários florestais de 34 propriedades no Pará.

O conjunto geral possui 85 polígonos de UPAs.

Mas é necessário distinguir três coisas:

1. Propriedade: empreendimento ou imóvel onde ocorre o manejo.
2. UPA: Unidade de Produção Anual, que delimita uma área operacional do manejo.
3. Área efetivamente inventariada: local onde houve levantamento direcionado das espécies.

A unidade operacional de análise é a combinação empreendimento–UPA.

Para a etapa de desenvolvimento dos modelos, foram organizadas:

- 27 propriedades.
- 64 UPAs efetivamente inventariadas.

Outras sete propriedades foram reservadas para avaliação externa:

- Barro Branco.
- Curuça.
- Guariúba.
- Jatobá.
- Lote 01.
- Marilia.
- Palmeira.

Essas sete propriedades não devem ser utilizadas para escolher variáveis, regularização ou configuração dos modelos. Elas representam a prova externa que deverá ser realizada depois que o protocolo estiver definido.

6. Quantas árvores existem na base?

Os dados originais apresentam:

Espécie| Árvores registradas
Ipê-roxo| 5.381
Ipê-amarelo| 5.945
Total| 11.326

Entretanto, nem todas as árvores entram na modelagem.

6.1 O que é DAP?

DAP significa Diâmetro à Altura do Peito.

É a medida do diâmetro do tronco da árvore, normalmente realizada a 1,30 metro do solo.

O inventário original tinha critério de inclusão a partir de 5 cm de DAP.

Mas, para a análise do TCC, foi estabelecido o critério:

DAP maior que 10 cm.

Os registros menores não são apagados. Permanecem nos dados brutos, mas não entram nessa análise.

No conjunto de desenvolvimento, após o filtro de DAP, foram obtidos:

Espécie| Árvores elegíveis
Ipê-roxo| 3.395
Ipê-amarelo| 5.609
Total| 9.004

6.2 Por que não usamos todas as árvores diretamente?

Porque vários indivíduos podem estar dentro do mesmo pixel ambiental.

O raster utilizado tem resolução de 30 metros.

Isso significa que cada célula representa uma área aproximada de 30 × 30 metros.

Se existirem cinco ipês-roxos dentro da mesma célula, o modelo não precisa receber cinco registros ambientais idênticos.

Foi aplicada uma regra de uma ocorrência por espécie por célula de 30 metros.

Resultado:

Espécie| Presenças utilizadas
Ipê-roxo| 3.248
Ipê-amarelo| 5.432
Total| 8.680

Isso não significa que as outras árvores não existam. Significa que não foram contadas como novas células de ocorrência para o ajuste.

Essa regra diminui a repetição de registros no mesmo pixel, mas não elimina toda a dependência espacial entre árvores próximas.

---

PARTE 3 — AS SEIS VARIÁVEIS AMBIENTAIS

7. O que são variáveis ambientais?

São características do ambiente que podem estar relacionadas à distribuição das espécies.

O nosso modelo trabalha com seis variáveis.

7.1 Altitude

- Fonte: ANADEM.
- Unidade: metros.

Representa a elevação do terreno em relação ao nível de referência.

Exemplo:

Local| Altitude
A| 30 m
B| 120 m
C| 250 m

O modelo pode identificar se as ocorrências estão mais associadas a determinadas faixas de altitude.

Isso não significa que a altitude, sozinha, determina onde a árvore cresce.

7.2 Declividade

- Fonte: ANADEM.
- Unidade: graus.

Representa a inclinação do terreno.

Exemplo:

- 0°: terreno praticamente plano.
- 5°: pequena inclinação.
- 20°: terreno mais inclinado.

Pode ajudar a identificar diferenças entre terrenos planos e inclinados.

Não confundir graus com porcentagem de inclinação.

7.3 Distância à hidrografia

- Fonte: rios e igarapés verificados.
- Unidade: metros.

Representa a distância de cada pixel até o rio ou igarapé mais próximo.

Exemplo:

Local| Distância ao rio
A| 20 m
B| 150 m
C| 600 m

Essa variável pode ajudar a identificar associações entre a ocorrência das árvores e a posição em relação à drenagem.

Mas distância ao rio não é uma medição direta de umidade do solo.

7.4 BIO12 — precipitação anual

- Fonte: CHELSA.
- Unidade: milímetros por ano.

Representa a precipitação anual acumulada.

Exemplo:

- Área A: 1.800 mm/ano.
- Área B: 2.200 mm/ano.
- Área C: 2.600 mm/ano.

O modelo avalia se as ocorrências estão associadas a determinadas condições de precipitação anual.

7.5 BIO17 — precipitação do trimestre mais seco

- Fonte: CHELSA.
- Unidade usada no projeto: média mensal em mm/mês.

Representa a precipitação média mensal durante o trimestre mais seco.

Exemplo:

- Área A: 40 mm/mês.
- Área B: 60 mm/mês.
- Área C: 80 mm/mês.

É uma informação diferente da precipitação anual.

Uma região pode apresentar precipitação anual elevada e, mesmo assim, passar por uma estação seca mais intensa.

Por isso, BIO12 e BIO17 podem representar aspectos climáticos diferentes.

A fórmula e as unidades precisam permanecer documentadas e conferidas com os arquivos CHELSA utilizados.

7.6 Textura do solo

- Fonte: MapBiomas Solo.
- Camada: subgrupo textural de 0–30 cm.
- Tipo: variável categórica.

Representa classes de textura do solo.

Exemplos de classes texturais incluem solos com diferentes proporções de areia, silte e argila.

No modelo, essa variável não é tratada como se os códigos fossem uma escala numérica contínua.

Por exemplo, o código 7 não significa necessariamente que o solo é melhor que o código 2.

Os códigos representam categorias.

Pendência importante: conferir a legenda oficial da Coleção 3 do MapBiomas Solo antes de descrever ecologicamente cada código utilizado. Não atribuir nomes de classes apenas pelo número.

8. O que o modelo pode nos ensinar sobre essas variáveis?

Imagine que o modelo indique uma resposta crescente para determinada variável.

Isso pode significar que, dentro do domínio ambiental estudado, os valores mais elevados dessa variável estão associados a maiores escores de adequabilidade.

Mas não podemos concluir automaticamente que a variável causa a ocorrência da espécie.

O modelo identifica associações, não experimentos de causalidade.

Também precisamos verificar se duas variáveis estão representando informações muito parecidas.

Por exemplo, BIO12 e BIO17 podem apresentar correlação em determinadas regiões.

Se duas variáveis forem muito correlacionadas, pode ser difícil separar a contribuição individual de cada uma.

---

PARTE 4 — COMO OS PROGRAMAS TRABALHAM JUNTOS

9. QGIS: a parte espacial

O QGIS é utilizado para trabalhar com mapas e informações geográficas.

É nele que organizamos:

- Pontos das árvores.
- Limites de propriedades.
- UPAs.
- Rios e igarapés.
- Modelos digitais de elevação.
- Mapas de altitude e declividade.
- Rasters ambientais.

O que é raster?

É uma imagem formada por células, chamadas pixels.

Imagine uma grande grade sobre o mapa.

Cada célula possui um valor.

Exemplo de raster de altitude:

100| 105| 110
95| 100| 115
90| 98| 120

Cada número representa a altitude de uma célula.

O mesmo princípio é utilizado para precipitação, declividade e distância aos rios.

O que é vetor?

É uma representação geográfica composta por:

- Pontos.
- Linhas.
- Polígonos.

Exemplos:

- Árvore: ponto.
- Rio: linha.
- UPA: polígono.
- Propriedade: polígono.

O QGIS permite conferir se esses elementos estão corretamente posicionados.

10. R e RStudio: a parte estatística

O R executa os cálculos.

O RStudio é o ambiente visual onde escrevemos e executamos os scripts.

No R fazemos:

- Filtragem das árvores.
- Organização das ocorrências.
- Preparação do background.
- Estatísticas ambientais.
- Correlações.
- Ajustes MaxEnt.
- Avaliação dos modelos.
- Geração de tabelas e gráficos.

O que é um script?

É um arquivo que contém instruções para o computador executar.

Exemplo:

# Ler os dados
dados <- read.csv("ocorrencias.csv")

# Manter DAP maior que 10 cm
dados <- subset(dados, DAP > 10)

# Contar os registros
nrow(dados)

O código acima manda o R ler uma tabela, manter as árvores com DAP acima de 10 cm e contar quantas sobraram.

O Claude pode ajudar a criar e revisar scripts, mas é necessário verificar se o código está correto e se os resultados fazem sentido cientificamente.

---

PARTE 5 — ENTENDER AS CONFIGURAÇÕES DO MAXENT

11. O que são configurações de um modelo?

Um modelo pode ser ajustado de diferentes maneiras.

Imagine que temos uma mesma base de dados, mas queremos testar se o resultado muda quando alteramos a complexidade matemática do modelo.

Podemos ajustar o MaxEnt com diferentes configurações e comparar os resultados.

No nosso histórico, uma das principais grades foi composta por 72 ajustes.

Não eram 72 espécies, nem 72 áreas.

Eram 72 combinações de parâmetros.

A estrutura foi:

2 espécies × 3 folds × 3 classes de feições × 4 níveis de regularização = 72 modelos.

12. O que são folds?

Fold é uma divisão dos dados para treinamento e validação.

Imagine que temos três grupos de propriedades.

- Fold 1.
- Fold 2.
- Fold 3.

Em cada ajuste, o modelo utiliza dois grupos para treinamento e reserva um grupo para validação.

Exemplo:

Etapa| Treinamento| Validação
Fold 1| Grupos 2 e 3| Grupo 1
Fold 2| Grupos 1 e 3| Grupo 2
Fold 3| Grupos 1 e 2| Grupo 3

No nosso projeto, a divisão regional por fold foi organizada por propriedades inteiras.

A intenção é verificar se o modelo treinado em determinadas propriedades consegue prever ocorrências em outras propriedades.

Distribuição das ocorrências nos folds

Fold| Propriedades| UPAs| Ipê-roxo| Ipê-amarelo
1| 9| 21| 1.618| 1.455
2| 11| 25| 1.424| 1.491
3| 7| 18| 206| 2.486

Observe um problema:

O Fold 3 possui apenas 206 ocorrências de ipê-roxo, enquanto o Fold 2 possui 2.486 ocorrências de ipê-amarelo.

Isso cria uma diferença importante entre os grupos.

O modelo pode ter dificuldade de prever áreas ambientalmente diferentes daquelas utilizadas no treinamento.

13. O que são features?

Features são classes de funções matemáticas que o MaxEnt pode utilizar para representar as relações entre as variáveis ambientais e a ocorrência da espécie.

No nosso experimento foram testadas três opções:

L — Linear

O modelo trabalha com relações lineares.

Exemplo:

À medida que a altitude aumenta, o escore pode aumentar ou diminuir seguindo uma relação aproximadamente linear.

É uma configuração mais simples.

LQ — Linear e quadrática

Além das relações lineares, permite relações curvas.

Exemplo:

Uma espécie pode apresentar maior adequabilidade em altitudes intermediárias e menor adequabilidade em altitudes muito baixas ou muito elevadas.

É uma relação em formato de curva.

LQH — Linear, quadrática e hinge

Adiciona funções do tipo hinge, que permitem representar relações mais flexíveis, com mudanças de comportamento em diferentes intervalos ambientais.

Exemplo:

A adequabilidade pode aumentar até determinado intervalo de precipitação e depois estabilizar ou diminuir.

É uma configuração mais flexível e pode gerar modelos mais complexos.

Em geral:

- L: mais simples.
- LQ: intermediária.
- LQH: mais flexível.

Mas maior flexibilidade não significa automaticamente modelo melhor.

14. O que é RM — Regularization Multiplier?

RM significa multiplicador de regularização.

É um parâmetro que controla o quanto o modelo será penalizado por apresentar complexidade excessiva.

Imagine que um modelo tenta aprender todos os pequenos detalhes dos dados de treinamento.

Ele pode ficar muito ajustado aos dados que recebeu, mas ter dificuldade para funcionar em outras áreas.

Isso é chamado de sobreajuste, ou overfitting.

A regularização ajuda a controlar esse problema.

No nosso projeto foram testados:

- RM 1.
- RM 2.
- RM 3.
- RM 4.

Em termos gerais:

RM| Interpretação
1| Menor penalização da complexidade
2| Penalização intermediária
3| Penalização maior
4| Penalização ainda maior

Um RM maior tende a produzir modelos mais simples, mas não existe garantia de que seja sempre melhor.

A escolha depende do desempenho e da estabilidade da previsão.

15. Quais eram exatamente as 12 configurações por espécie e fold?

A grade completa era:

Nº| Feature| RM
1| L| 1
2| L| 2
3| L| 3
4| L| 4
5| LQ| 1
6| LQ| 2
7| LQ| 3
8| LQ| 4
9| LQH| 1
10| LQH| 2
11| LQH| 3
12| LQH| 4

Essa grade foi repetida para:

- Ipê-roxo, Fold 1.
- Ipê-roxo, Fold 2.
- Ipê-roxo, Fold 3.
- Ipê-amarelo, Fold 1.
- Ipê-amarelo, Fold 2.
- Ipê-amarelo, Fold 3.

Portanto:

- 12 modelos por combinação espécie–fold.
- 36 modelos por espécie.
- 72 modelos no total.

Exemplo de identificação de um modelo

Ipê-roxo + Fold 1 + LQH + RM 4.

Isso significa:

- Espécie: ipê-roxo.
- Treinamento: propriedades dos outros dois folds.
- Validação: propriedades do Fold 1.
- Feature: LQH.
- Regularização: 4.

O modelo é ajustado e depois suas previsões são comparadas com as ocorrências e o background reservados para validação.

16. Outras configurações fixadas nos experimentos

Além de features e RM, os scripts registraram outras opções:

- Método: MaxEnt via pacote "maxnet".
- Textura do solo: variável categórica.
- Saída: cloglog.
- Clamping: ativado.
- Omissão: limiar calculado com os dados de treinamento.
- Background: conforme o experimento B0, B1 ou B2.

O que é clamping?

É um mecanismo utilizado quando o modelo encontra valores ambientais fora da faixa observada durante o treinamento.

Ele limita determinadas respostas para reduzir comportamentos extremos na extrapolação.

Não resolve automaticamente a novidade ambiental.

O que é cloglog?

É uma transformação utilizada para produzir os valores de saída do modelo.

É uma escala de adequabilidade prevista.

Não devemos apresentar esses números automaticamente como probabilidades absolutas de encontrar uma árvore em campo.

---

PARTE 6 — ENTENDER O BACKGROUND B0, B1 E B2

17. Por que foram utilizados três backgrounds?

Background é uma amostra do ambiente disponível.

A quantidade e a forma de selecionar esses pontos podem influenciar as métricas.

Por isso, foram comparadas três versões.

Background| Quantidade| Como foi produzido
B0| 5.000| Amostra original
B1| 10.000| B0 preservado + 5.000 pontos adicionais
B2| 10.000| Novo sorteio completo no mesmo domínio, com cotas por UPA

Qual a diferença?

Imagine que você quer representar a variedade ambiental de uma região.

Na primeira tentativa, seleciona 5.000 pontos.

Na segunda, mantém os 5.000 e acrescenta outros 5.000.

Na terceira, sorteia novamente 10.000 pontos, mantendo as regras de distribuição por UPA.

Isso permite verificar se os resultados dependem muito do sorteio do background.

B2 não representa uma nova região geográfica. É uma nova amostragem do mesmo domínio.

Também não é um teste externo independente.

---

PARTE 7 — ENTENDER AS MÉTRICAS E OS VALORES

Essa é uma das partes mais importantes para quem vai ajudar a interpretar os resultados.

18. AUC — Área sob a curva ROC

A AUC é uma métrica utilizada para avaliar a capacidade de discriminação do modelo.

No nosso caso, ela compara os escores atribuídos às presenças com os escores atribuídos aos pontos de background.

Uma interpretação simplificada:

AUC| Interpretação geral
0,50| Discriminação semelhante ao acaso
0,60| Discriminação fraca
0,70| Discriminação limitada a moderada
0,80| Discriminação relativamente boa
0,90| Discriminação muito elevada
1,00