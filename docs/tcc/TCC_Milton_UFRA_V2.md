---
lang: pt-BR
---

**MINISTÉRIO DA EDUCAÇÃO**

**UNIVERSIDADE FEDERAL RURAL DA AMAZÔNIA**

**INSTITUTO DE CIÊNCIAS AGRÁRIAS**

**CURSO DE ENGENHARIA FLORESTAL**

**MILTON DA SILVA TAVARES NETO**

**MODELAGEM AMBIENTAL PREDITIVA DA OCORRÊNCIA DE *Handroanthus impetiginosus* E *Handroanthus serratifolius* EM FLORESTAS NATIVAS SOB MANEJO FLORESTAL SUSTENTÁVEL NO ESTADO DO PARÁ**

Trabalho de Conclusão de Curso apresentado ao Curso de Engenharia Florestal da Universidade Federal Rural da Amazônia como requisito parcial para obtenção do grau de Bacharel em Engenharia Florestal.

Orientadora: Prof.ª Dra. Gracialda Costa Ferreira.

Coorientadora: Prof.ª Dra. Julia Isabella de Matos Rodrigues.

BELÉM – PA, 2026

**AGRADECIMENTOS**

Aos meus pais, Tatiana Loureiro e João Luiz, à minha madrasta, Suely Pojo, e ao meu padrasto, Andre Luiz, pelo amor, pelo apoio e pelo exemplo em todas as etapas da minha vida. Aos meus irmãos, João Victor, Bruna Jolly, José Heitor, Tony Junior e Andre Neto, às minhas tias, tios, primas e primos e aos meus amados avós.

Às minhas orientadoras, Prof.ª Dra. Gracialda Costa Ferreira e Prof.ª Dra. Julia Isabella de Matos Rodrigues, pela confiança, pela paciência e pelos ensinamentos que tornaram este trabalho possível. À Prof.ª Marcela Gomes, ex-tutora do PET Florestal, que, além de orientar, sempre me mostrou o caminho para melhorar, e à Prof.ª Thâmara Lima, que sempre foi cuidadosa e uma pessoa incrível comigo e com meus colegas. A todo o corpo docente e técnico da Universidade Federal Rural da Amazônia que fez parte da minha formação: é graças a essas pessoas que cheguei até aqui.

Aos professores do ensino fundamental do Colégio Manoel Leite e do ensino médio do Colégio Ensino Ideal, que me deram a base para chegar até aqui.

Aos meus amigos de turma, que caminharam comigo nessa trajetória e que, além da amizade, me ensinaram muito sobre a vida, em especial Anna Marcelly, Leonardo Ramos, Juan Vitor, Layza Gois, Igor Miranda, Caroline Baia, Iris Marques, Layla Silva, Werlon Santos, Gabrielly Barata, João Pedro e Samilly Lisboa.

Ao grupo PET Florestal e aos membros com quem convivi durante minha passagem pelo grupo, em especial Andrei Mendes, Yuri Cardoso, Juliana Rodrigues, Daniela Borges, Luana Anjos, Anna Teotônio, Antonia Andreyna, Eliã Bittencourt, Sofia Alves, Ruan Barbosa, Jhan Martins, Kamily Pereira, Maria Lamego, Karla Gomes, Luisa Marilac, Renzo Paiva, Emily Eva e Emilly Gabriely.

À CIFLOR Jr. e a todos os seus membros, em especial Kaio Pereira, Carlos Amador, Emanuely Braga, Andre Alisson, Daniel Feliph, Geiza Gomes e Wilianne Laurentino, e aos tutores Prof. Marcos Piedade e Prof. Rodrigo Vale. Ao Centro Acadêmico de Engenharia Florestal (CAEF), em especial João Marigliani, Santy Luz, Axel Queiroz, Calyson Vasconcelos e Khiara Santos, e aos demais membros. Ao Laboratório de Dendrologia (LabDendro), em especial Thayane Ferreira, Susana Braga, Cléo Cravo, Kauany Lobo e Leandro Vasconcelos, e aos demais membros.

À empresa Green Forest, pelo apoio com os dados utilizados neste trabalho e pela oportunidade de estágio por mais de um ano, durante o qual conheci diversos profissionais: Milena Peper, Romário Borges, Mauro Caldas, Lélio Mota, Danilo Silva, Eduardo Amaral, Andressa Rodrigues, Samara Pinheiro, Marcos Chaves, Ana Beatriz, David Silva e Dayse Monteiro. Em especial, a Letícia Negrão, a quem devo muito pelo apoio durante este trabalho e nos momentos difíceis. E aos demais membros da empresa.

Aos meus amigos de infância e adolescência, Antonio Carlos, Brenda Melissa, Shimeny Sagica, Felipe Ferreira, Leandro de Paula, Maria Clara, Maria Fernanda, Rubens Bittencourt, Rita Bittencourt, Emanuelle Praia, Marcelo Luz, Gabriel Barbosa, Carolina Mesquita, Hamilson Junior, Fabio, João Guilherme, Thayssa Santiago, Jeane Cézar e Gildson Gregorio, e aos amigos que fiz ao longo da caminhada, Aluisio Neto, Danylo Martins, Tainá Silva, Ewerton Corrêa, Adriely Sousa, Luiza Henriques, Nathally Souza, Gabriely Ribeiro, Caio Andrian, Wesley Pablo, Gabriel Alves, Aristeu Rodrigues, Ana Luisa, Mayara Luz, Denner Santos, Raphael Rodrigues, Ana Clara e Ricardo Oliveira.

A todos que passaram pela minha vida e contribuíram, direta ou indiretamente, para esta conquista, meus sinceros agradecimentos.

**RESUMO**

*Handroanthus impetiginosus* (ipê-roxo) e *Handroanthus serratifolius* (ipê-amarelo) estão entre as madeiras de maior valor comercial da Amazônia, e o conhecimento das condições ambientais associadas à sua ocorrência pode subsidiar o planejamento do manejo florestal. O objetivo deste trabalho foi avaliar os padrões ambientais associados à ocorrência das duas espécies em florestas nativas sob manejo florestal sustentável no Estado do Pará, por meio de modelagem ambiental preditiva. Foram utilizados inventários florestais a 100% de 34 propriedades, das quais 27 foram empregadas no desenvolvimento dos modelos e sete foram reservadas para um teste externo, realizado uma única vez. Foram consideradas seis variáveis ambientais: altitude, declividade, distância à hidrografia, precipitação anual (BIO12), precipitação do trimestre mais seco (BIO17) e textura do solo. A relação entre a densidade das espécies e o ambiente foi analisada por classes das variáveis, e os modelos foram ajustados com o algoritmo MaxEnt, selecionados por validação em que cada propriedade foi deixada de fora uma vez e confirmados por uma grade de 945 modelos por espécie. As duas espécies ocorreram em propriedades quase distintas. A densidade de ambas foi menor nas áreas próximas à drenagem, e as espécies responderam de forma oposta à textura do solo: o ipê-roxo foi mais denso em solos de textura média, e o ipê-amarelo, em solos muito argilosos. O modelo escolhido para o ipê-roxo (altitude e BIO17) apresentou AUC de 0,825 em propriedades novas e de 0,879 no teste externo, porém com omissão de 100% no limiar de 10% de omissão do treino. O modelo do ipê-amarelo (distância à hidrografia, BIO12 e textura do solo) apresentou AUC de 0,714 e 0,691, respectivamente, com omissão de 0,3%. Em todas as etapas, a AUC calculada dentro das propriedades ficou próxima de 0,5. Conclui-se que os modelos distinguem as regiões e as propriedades mais favoráveis a cada espécie e transferem essa ordenação para propriedades novas, mas não identificam os locais ocupados dentro de cada propriedade, e que as variáveis climáticas refletem principalmente a localização geográfica das propriedades.

**Palavras-chave:** ipê; MaxEnt; inventário florestal; heterogeneidade ambiental; Amazônia.

**ABSTRACT**

*Handroanthus impetiginosus* (purple ipê) and *Handroanthus serratifolius* (yellow ipê) are among the most valuable timbers of the Amazon, and knowledge of the environmental conditions associated with their occurrence can support forest management planning. This study aimed to evaluate the environmental patterns associated with the occurrence of both species in native forests under sustainable forest management in the state of Pará, Brazil, through predictive environmental modelling. Full (100%) forest inventories of 34 properties were used: 27 properties were used to develop the models and seven were set aside for an external test, carried out only once. Six environmental variables were considered: elevation, slope, distance to drainage, annual precipitation (BIO12), precipitation of the driest quarter (BIO17) and soil texture. The relationship between species density and environment was analysed by variable classes, and the models were fitted with the MaxEnt algorithm, selected by leave-one-property-out validation and confirmed by a grid of 945 models per species. The two species occurred in almost distinct properties. The density of both species was lower near drainage, and they responded in opposite ways to soil texture: purple ipê was denser on medium-textured soils, and yellow ipê on very clayey soils. The model selected for purple ipê (elevation and BIO17) reached an AUC of 0.825 in new properties and 0.879 in the external test, but with 100% omission at the 10th percentile training presence threshold. The yellow ipê model (distance to drainage, BIO12 and soil texture) reached AUCs of 0.714 and 0.691, respectively, with 0.3% omission. In all stages, the AUC calculated within properties was close to 0.5. The models distinguish the regions and properties most suitable for each species and transfer this ranking to new properties, but do not identify the occupied sites within each property, and the climatic variables mainly reflect the geographical location of the properties.

**Keywords:** ipê; MaxEnt; forest inventory; environmental heterogeneity; Amazon.

# 1 INTRODUÇÃO

A distribuição espacial das espécies arbóreas em florestas tropicais resulta da interação entre processos ecológicos e condições ambientais, que podem influenciar a composição, a abundância e a organização das comunidades vegetais. Nesse contexto, a heterogeneidade ambiental, expressa pelas variações nas características físicas e biológicas da paisagem, constitui um fator relevante para compreender os padrões de ocorrência das espécies, uma vez que diferenças nas condições dos habitats e na disponibilidade de recursos podem estar associadas à sua distribuição espacial (Harms *et al.*, 2001; John *et al.*, 2007). Em uma floresta tropical da Costa Rica, foram identificadas associações significativas entre determinadas espécies arbóreas, as condições edáficas e a posição topográfica (Clark; Palmer; Clark, 1999), enquanto, na Amazônia ocidental, a variação florística entre localidades foi atribuída tanto à heterogeneidade ambiental quanto à limitação da dispersão (Tuomisto; Ruokolainen; Yli-Halla, 2003). Embora realizados em contextos e escalas distintos, esses estudos demonstram a importância de considerar tanto as condições ambientais quanto os processos que influenciam a ocupação dos espaços pelas espécies. Assim, compreender as associações entre a ocorrência de árvores e as características dos ambientes onde estão registradas constitui uma abordagem relevante para investigar a heterogeneidade das florestas amazônicas.

No contexto do manejo florestal sustentável na Amazônia, os inventários florestais constituem importantes instrumentos para o conhecimento da composição, da estrutura e do potencial produtivo das florestas naturais. Ademais, quando aliados ao georreferenciamento dos indivíduos arbóreos, tornam possível prever padrões de distribuição e, consequentemente, adotar estratégias que otimizem a logística do manejo florestal.

Entre as espécies arbóreas de interesse para o manejo florestal na Amazônia, destacam-se *Handroanthus impetiginosus* (Mart. ex DC.) Mattos e *Handroanthus serratifolius* (Vahl) S.O.Grose, pertencentes à família Bignoniaceae e conhecidas como ipê-roxo e ipê-amarelo, respectivamente. Essas espécies apresentam relevância econômica em razão das propriedades tecnológicas de suas madeiras, especialmente a elevada densidade, a resistência mecânica e a durabilidade natural, características que favorecem sua utilização em produtos madeireiros de maior valor agregado. A classificação taxonômica desses táxons também passou por modificações, com a reorganização do gênero *Tabebuia* em sentido amplo (Grose; Olmstead, 2007), aspecto relevante para a interpretação de registros provenientes de inventários realizados em diferentes períodos. Além da importância comercial, a exploração dessas espécies suscita questões relacionadas à conservação das populações naturais, uma vez que a recuperação dos estoques comerciais em cenários de colheitas sucessivas é limitada (Schulze *et al.*, 2008). Nesse contexto, compreender a distribuição espacial de *H. impetiginosus* e *H. serratifolius* e suas associações com as condições ambientais pode ampliar o conhecimento ecológico dessas espécies e fornecer informações complementares ao planejamento e ao monitoramento do manejo florestal sustentável.

A madeira de *H. serratifolius* dispõe de propriedades que contribuem para o seu aproveitamento em diferentes aplicações, como a madeira moderadamente densa a densa (massa específica aparente de 0,78 a 1,09 g cm⁻³), dura ao corte e muito resistente às intempéries, em razão da presença de lapachol (Carvalho, 2014). A expressividade econômica dos ipês também é evidenciada por indicadores do mercado internacional: em maio de 2026, os preços indicativos da madeira serrada de ipê destinada à exportação alcançaram aproximadamente US$ 3.000 por metro cúbico, enquanto as tábuas para *decks* atingiram cerca de US$ 4.900 por metro cúbico (International Tropical Timber Organization, 2026). Todavia, essas cotações correspondem ao grupo comercial denominado ipê, sem identificação individual das espécies comercializadas, e refletem produtos em diferentes estágios de processamento. Assim, a valorização dessas madeiras pode favorecer a exploração em regiões amazônicas remotas, ao mesmo tempo que suscita preocupações relacionadas à recuperação dos estoques comerciais após colheitas sucessivas (Schulze *et al.*, 2008). Nesse contexto, a importância econômica dessas espécies reforça a necessidade de ampliar o conhecimento sobre a distribuição de suas populações naturais e suas relações com as condições ambientais, contribuindo para a produção de informações que possam subsidiar o planejamento e o monitoramento do manejo florestal sustentável.

A investigação das relações entre *H. impetiginosus*, *H. serratifolius* e as condições ambientais encontra respaldo em estudos que evidenciam diferentes aspectos da ecologia dessas espécies. Populações de *H. impetiginosus* distribuídas pelo Brasil apresentam evidências genômicas compatíveis com processos de adaptação local associados à heterogeneidade ambiental (Collevatti *et al.*, 2019). Em escala continental, a distribuição potencial de *H. serratifolius* foi associada principalmente a condições edáficas e climáticas (Elera-Gonzales *et al.*, 2026), e, em escala nacional, a modelagem das duas espécies com variáveis de clima, solo e topografia indicou vulnerabilidade climática distinta entre elas (Borba *et al.*, 2026). Complementarmente, as duas espécies apresentaram respostas de expressão gênica distintas quando submetidas ao déficit hídrico, demonstrando que espécies taxonomicamente próximas podem responder de forma diferente às condições de estresse (Sobreiro *et al.*, 2021). Embora desenvolvidas com diferentes abordagens e escalas, essas pesquisas reforçam a importância de considerar as particularidades ecológicas de cada espécie. Entretanto, seus resultados não permitem estabelecer diretamente quais condições ambientais estão associadas à ocorrência dos indivíduos nas áreas de manejo florestal do Pará, evidenciando a necessidade de investigações específicas que considerem a heterogeneidade ambiental e a distribuição espacial dos registros disponíveis.

A modelagem de distribuição de espécies constitui uma abordagem utilizada para investigar relações entre registros de ocorrência de organismos e características ambientais, permitindo identificar padrões espaciais e estimar condições potencialmente favoráveis à sua ocorrência. Entre os métodos empregados, destaca-se o algoritmo de máxima entropia (MaxEnt), que possibilita a construção de modelos a partir de registros de presença associados a informações ambientais, sem exigir dados de ausência confirmada (Phillips; Anderson; Schapire, 2006). Essa característica torna o método particularmente pertinente à utilização de inventários florestais georreferenciados, nos quais são conhecidas as localizações dos indivíduos registrados segundo os critérios de inclusão dos levantamentos. Entretanto, a confiabilidade das predições depende não apenas da quantidade de ocorrências disponíveis, mas também da representatividade ambiental das áreas amostradas e das decisões adotadas durante a modelagem (Ferreira, 2009). O viés de amostragem e a definição das condições ambientais disponíveis para comparação podem influenciar os resultados (Phillips *et al.*, 2009), e a dependência espacial dos registros precisa ser considerada na avaliação do desempenho preditivo (Roberts *et al.*, 2017). No entanto, a aplicação de modelos de distribuição de espécies em novas áreas exige atenção às diferenças entre as condições ambientais utilizadas na calibração e aquelas presentes nos locais de predição (Elith; Leathwick, 2009; Ferreira, 2009), assim como à delimitação geográfica que define as condições ambientais disponíveis às espécies (Barve *et al.*, 2011).

Embora pesquisas anteriores tenham demonstrado a importância da heterogeneidade ambiental para a distribuição de espécies arbóreas e o potencial dos inventários florestais como fonte de informações ecológicas, ainda é necessário compreender como essas relações se manifestam para *H. impetiginosus* e *H. serratifolius* nas áreas de manejo florestal em diferentes regiões do Estado do Pará. As contribuições de Ferreira (2009) evidenciaram a viabilidade da modelagem ambiental a partir de registros de inventário e os desafios associados à transferência das predições entre unidades de manejo. Entretanto, as particularidades ecológicas das espécies, a distribuição espacial de suas ocorrências e a diversidade de condições ambientais representadas nos levantamentos tornam necessária uma investigação específica. Nesse contexto, a disponibilidade de registros georreferenciados provenientes de diferentes Unidades de Produção Anual (UPAs) constitui uma oportunidade para examinar as associações entre ocorrência e ambiente em florestas manejadas no Estado do Pará.

Diante dessa lacuna científica, a presente pesquisa buscou responder às seguintes questões: a) quais condições ambientais estão associadas à ocorrência de *H. impetiginosus* e *H. serratifolius* nas áreas de manejo florestal estudadas? e b) em que medida essas associações permitem realizar predições consistentes em propriedades independentes daquelas utilizadas na calibração dos modelos?

Partiu-se da hipótese de que a ocorrência dos indivíduos inventariados de *H. impetiginosus* e *H. serratifolius* apresenta associações com a heterogeneidade ambiental das florestas manejadas, de modo que as condições ambientais registradas nos locais de presença possam ser diferenciadas daquelas disponíveis nas áreas efetivamente amostradas. Além disso, hipotetizou-se que essas associações poderiam variar entre as espécies, em razão de suas particularidades ecológicas e das diferenças entre os ambientes representados nos inventários, embora a identificação de padrões distintos não constitua, isoladamente, comprovação de preferências ecológicas específicas. Diante disso, o objetivo do trabalho foi avaliar os padrões ambientais associados à ocorrência de *H. impetiginosus* e *H. serratifolius* em florestas nativas sob manejo florestal sustentável no Estado do Pará por meio de modelagem ambiental preditiva.

# 2 OBJETIVOS

## 2.1 Objetivo geral

Avaliar os padrões ambientais associados à ocorrência de *Handroanthus impetiginosus* e *Handroanthus serratifolius* em florestas nativas sob manejo florestal sustentável no Estado do Pará por meio de modelagem ambiental preditiva.

## 2.2 Objetivos específicos

a) Identificar as variáveis ambientais associadas à ocorrência de *H. impetiginosus* e *H. serratifolius* nas áreas de manejo florestal analisadas, comparando as respostas das duas espécies.

b) Validar os modelos de ocorrência das duas espécies em propriedades independentes, não utilizadas no ajuste, avaliando seu desempenho preditivo.

# 3 REVISÃO DE LITERATURA

## 3.1 Manejo florestal sustentável e utilização científica de inventários florestais

O manejo florestal sustentável de florestas naturais fundamenta-se no conhecimento da composição florística, da estrutura dos povoamentos e da disponibilidade de recursos madeireiros, de modo a compatibilizar a produção florestal com a manutenção dos processos ecológicos. Nesse contexto, o inventário florestal constitui uma importante ferramenta para a caracterização da vegetação e o planejamento das atividades de exploração, cujos procedimentos devem ser definidos em função dos objetivos e das características da floresta (Queiroz, 1998). Entre esses levantamentos, destaca-se o inventário florestal a 100%, também denominado censo florestal, que permite identificar, mensurar e localizar as árvores e organizar as operações de manejo na Amazônia (Amaral *et al.*, 1998).

Nas áreas submetidas a Planos de Manejo Florestal Sustentável (PMFS), o inventário a 100% registra, para cada árvore que atende aos critérios de inclusão, o nome da espécie, o diâmetro à altura do peito (DAP), a altura comercial, a qualidade do fuste e a localização espacial. Esses dados subsidiam a estimativa de volume, a seleção de árvores para exploração, a definição de áreas de conservação e o acompanhamento dos estoques. Entretanto, a abrangência do inventário é condicionada por seus critérios operacionais, de maneira que os registros não representam necessariamente todos os estágios de desenvolvimento das espécies existentes na floresta.

Embora originalmente destinados ao planejamento da produção madeireira, os inventários florestais também constituem fontes relevantes de informações para pesquisas ecológicas. A identificação e a localização das árvores possibilitam investigar padrões de distribuição espacial, variações de densidade populacional e associações entre a ocorrência das espécies e as características ambientais da paisagem, o que amplia o potencial científico dos levantamentos, especialmente em regiões amazônicas nas quais estudos florísticos detalhados ainda apresentam distribuição geográfica desigual.

Ferreira (2009), ao investigar a modelagem ambiental de espécies arbóreas no Vale do Jari, no Pará, demonstrou a possibilidade de utilizar dados de inventários florestais comerciais na análise da distribuição de árvores amazônicas. A pesquisa empregou informações provenientes de quatro UPAs, considerando registros de dez espécies e utilizando os algoritmos MaxEnt e GARP. A autora descreveu a abundância das espécies em classes de altitude, declividade e distância ao rio, ajustando modelos polinomiais, e avaliou os modelos com o teste Jackknife e a curva ROC (*Receiver Operating Characteristic*). Entre os aspectos discutidos estão a confiabilidade da identificação das espécies, a qualidade da localização dos indivíduos e a influência das diferenças ambientais entre as áreas sobre o desempenho das predições. O estudo constitui um importante antecedente para pesquisas que procuram compreender a ocorrência de espécies arbóreas a partir de levantamentos originalmente destinados ao manejo florestal.

A importância científica desses registros também pode ser observada em estudos de distribuição espacial realizados em áreas manejadas. Em Silves, no Amazonas, seis espécies arbóreas comerciais apresentaram padrões predominantemente agregados e relações diferenciadas com características topográficas (Miron *et al.*, 2021), e, na Reserva Extrativista Tapajós-Arapiuns, no Pará, predominaram agrupamentos espaciais entre dez espécies comerciais (Santos; Stepka; Hess, 2026). Esses resultados evidenciam que as populações arbóreas não apresentam necessariamente distribuição homogênea dentro das áreas florestais, o que possui implicações tanto para o conhecimento ecológico quanto para o planejamento do manejo.

A distribuição espacial das árvores também se relaciona à conservação dos indivíduos remanescentes após a exploração. Simulações realizadas em quatro áreas amazônicas, incluindo *H. serratifolius*, indicaram que critérios de seleção de árvores que consideram o distanciamento entre indivíduos da mesma espécie podem manter configurações espaciais mais favoráveis à polinização (Sontag *et al.*, 2025). Assim, o planejamento da exploração não depende exclusivamente do volume e do diâmetro dos indivíduos, mas também da organização espacial das populações.

Dessa forma, os inventários florestais apresentam potencial para gerar conhecimentos que ultrapassam sua finalidade operacional. Contudo, sua interpretação exige reconhecer que as árvores registradas correspondem à parcela da população contemplada pelos critérios de inclusão do levantamento.

## 3.2 Aspectos botânicos, ecológicos e econômicos de *Handroanthus impetiginosus* e *Handroanthus serratifolius*

As espécies *H. impetiginosus* e *H. serratifolius* pertencem à família Bignoniaceae e apresentam elevada importância ecológica e econômica em diferentes regiões do Brasil. Conhecidas popularmente como ipê-roxo e ipê-amarelo, destacam-se pela utilização de suas madeiras, pelas características ornamentais e pela participação na composição de diferentes formações vegetacionais. Apesar de compartilharem características taxonômicas e reprodutivas, apresentam particularidades morfológicas, ecológicas e biogeográficas que justificam seu estudo individualizado.

### 3.2.1 Classificação taxonômica, nomenclatura e distribuição geográfica

A família Bignoniaceae compreende espécies arbóreas, arbustivas e lianescentes amplamente distribuídas nas regiões tropicais e subtropicais. Entre seus representantes encontram-se as árvores conhecidas como ipês, historicamente agrupadas no gênero *Tabebuia*. Estudos filogenéticos demonstraram que esse agrupamento, em sua circunscrição tradicional, reunia linhagens evolutivas distintas, o que levou ao reconhecimento de *Handroanthus* como gênero distinto, com base em características morfológicas e relações filogenéticas (Grose; Olmstead, 2007).

Em decorrência dessa reorganização, as espécies anteriormente identificadas como *Tabebuia impetiginosa* (Mart. ex DC.) Standl. e *Tabebuia serratifolia* (Vahl) G.Nicholson passaram a ser reconhecidas, respectivamente, pelos nomes aceitos *H. impetiginosus* e *H. serratifolius*, nomenclatura adotada pela base Plants of the World Online (Royal Botanic Gardens, Kew, [s. d.]a, [s. d.]b) e compatível com as descrições botânicas disponíveis (Camillo; Salomão, 2018; Carvalho, 2014). A atualização nomenclatural possui particular importância em pesquisas baseadas em inventários florestais históricos, pois registros de diferentes períodos podem apresentar denominações científicas anteriores ou identificações realizadas exclusivamente por nomes populares. Além disso, nomes populares como ipê e pau-d'arco são aplicados tanto a *H. impetiginosus* quanto a *H. serratifolius* (Camillo; Salomão, 2018; Carvalho, 2014), o que reforça a necessidade de padronizar a identificação antes da análise.

Quanto à distribuição geográfica, *H. impetiginosus* ocorre do México à Argentina, do nível do mar a cerca de 1.400 m de altitude, preferencialmente em florestas estacionais semideciduais e deciduais (CNCFlora, 2012), mas também em florestas pluviais e no cerradão, com registros no Pará e no Tocantins (Camillo; Salomão, 2018), o que indica tolerância a diferentes contextos climáticos e vegetacionais. *Handroanthus serratifolius* também apresenta extensa distribuição na América tropical e, no Brasil, ocorre em diversas regiões fitogeográficas, incluindo a Amazônia, onde integra a vegetação de florestas de terra firme (Carvalho, 2014). Na Amazônia, a densidade média de ipês não ultrapassa uma árvore a cada dez hectares, e a distribuição de *H. serratifolius* coincide em grande parte com a região de maiores taxas de desmatamento (CNCFlora, 2019).

A ocorrência das duas espécies em diferentes formações vegetacionais indica capacidade de estabelecimento em condições ambientais variadas. Entretanto, a amplitude de distribuição geográfica não significa que as espécies apresentem a mesma frequência de ocorrência ou respondam igualmente às condições existentes em cada região.

### 3.2.2 Características botânicas e ecológicas de *Handroanthus impetiginosus*

*Handroanthus impetiginosus* é uma espécie arbórea decídua, caracterizada pela perda sazonal das folhas e pela floração vistosa, geralmente associada ao período de menor cobertura foliar. Seus indivíduos possuem aproximadamente 8 a 30 m de altura, tronco geralmente retilíneo, casca externa escura e fissurada, copa de formato irregular e folhas compostas, opostas e digitadas, comumente com cinco folíolos; as flores apresentam coloração rósea a violácea (Camillo; Salomão, 2018).

Os frutos são cápsulas alongadas e deiscentes, cujas sementes aladas são dispersas pelo vento. A maturação é rápida, em torno de dois meses após a queda das flores, e, no Cerrado, a liberação das sementes coincide com o início das chuvas; como as sementes perdem a viabilidade em pouco tempo quando mantidas em temperatura ambiente, a germinação depende das condições encontradas logo após a dispersão (Camillo; Salomão, 2018). Em espécies de Bignoniaceae dispersas pelo vento, as condições atmosféricas da estação seca aumentam a frequência com que as sementes são elevadas acima do dossel e, consequentemente, a distância de dispersão (Wright *et al.*, 2008), o que vincula a sazonalidade climática ao ciclo reprodutivo dessas espécies.

Embora descrito como heliófilo, o ipê-roxo ocorre tanto no interior da floresta primária quanto em formações abertas e secundárias, e as plantas jovens toleram sombreamento moderado (Camillo; Salomão, 2018). A abertura de clareiras, a competição com a vegetação circundante e a disponibilidade de recursos influenciam o crescimento inicial e a sobrevivência das plântulas, de modo que a presença de adultos em florestas densas pode resultar de recrutamentos ocorridos sob condições diferentes das atuais.

Do ponto de vista sucessional, o ipê-roxo é considerado secundário, mas pode atuar como pioneiro em áreas alteradas pelo homem. Quanto ao solo, a literatura associa seu melhor desenvolvimento a solos bem drenados e úmidos, inclusive de textura arenosa, e aponta a baixa fertilidade como fator limitante ao crescimento (Camillo; Salomão, 2018). Além disso, a análise de 128 indivíduos de 13 populações brasileiras identificou associações entre variações genéticas e condições ambientais, sugerindo que a história evolutiva e a heterogeneidade dos ambientes contribuíram para a diferenciação das populações (Collevatti *et al.*, 2019).

### 3.2.3 Características botânicas e ecológicas de *Handroanthus serratifolius*

*Handroanthus serratifolius*, conhecido como ipê-amarelo ou pau-d'arco-amarelo, é uma árvore decídua de grande porte, com tronco reto ou levemente tortuoso, copa ampla, casca pardo-acinzentada e fissurada e folhas compostas com folíolos de margens serrilhadas, característica que origina o epíteto específico. As flores, de corola amarelo-dourada, são polinizadas por abelhas, e a espécie, hermafrodita, é predominantemente alógama, o que torna importante a transferência de pólen entre indivíduos (Carvalho, 2014).

A frutificação ocorre por meio de cápsulas alongadas e deiscentes, com sementes leves e aladas dispersas pelo vento. A fenologia reprodutiva varia entre regiões: no Pará, a floração foi registrada de junho a novembro, com frutos maduros em julho e frutificação em intervalos de três a quatro anos. Quanto ao solo, a espécie é classificada como indiferente em relação a solos mesotróficos, foi registrada em solos com pH de 3,9 a 5,6 e, no sudeste do Pará, ocorre sobre Terra Roxa Estruturada (Carvalho, 2014).

A disponibilidade de luz é um dos fatores associados ao desenvolvimento inicial da espécie, com diferenças de sobrevivência e crescimento de plântulas entre o sub-bosque e as clareiras (Carvalho, 2014). A qualidade das sementes também varia entre árvores matrizes, como observado em vinte matrizes na Amazônia Ocidental (Silva Junior *et al.*, 2024). Em escala continental, a distribuição potencial da espécie foi associada principalmente ao pH do solo em profundidade e à temperatura mínima do mês mais frio, indicando que o clima, isoladamente, não explica sua distribuição (Elera-Gonzales *et al.*, 2026).

### 3.2.4 Importância econômica, exploração madeireira e conservação das espécies

As espécies de ipê apresentam expressiva importância econômica no setor florestal brasileiro em razão das propriedades tecnológicas de suas madeiras, empregadas em pisos, *decks*, assoalhos, estruturas externas e componentes da construção civil (Schulze *et al.*, 2008). A elevada valorização dessas madeiras pode tornar sua exploração financeiramente atrativa mesmo em localidades distantes dos centros consumidores: nas condições econômicas avaliadas em 2008, estimou-se que a exploração de ipês seria lucrativa em aproximadamente 63% da Amazônia brasileira (Schulze *et al.*, 2008).

No Pará, a importância econômica do ipê também se expressa em sua inclusão na categoria de madeiras nobres do Boletim de Preços Mínimos de Mercado da Secretaria de Estado da Fazenda, com valores mínimos de referência entre R$ 990,43 e R$ 7.476,43 por metro cúbico, conforme o tipo de produto e de operação (Pará, 2025). Esses valores possuem finalidade tributária e não devem ser interpretados como preços específicos das duas espécies.

O interesse econômico pode aumentar a pressão de exploração sobre populações naturais, sobretudo quando os indivíduos comerciais apresentam distribuição descontínua e densidades reduzidas. Simulações baseadas em oito anos de monitoramento no leste da Amazônia indicaram declínio acentuado das populações das duas espécies ao longo de colheitas sucessivas, mesmo sob exploração de impacto reduzido (Schulze *et al.*, 2008). Critérios de seleção de árvores adaptados a cada espécie podem favorecer a manutenção de configurações espaciais adequadas à polinização (Sontag *et al.*, 2025), o que indica que a sustentabilidade da exploração depende também da organização espacial dos indivíduos remanescentes.

A relevância da conservação dos ipês também se reflete nas regulamentações do comércio internacional. A inclusão de espécies dos gêneros *Handroanthus* e *Tabebuia* no Apêndice II da Convenção sobre o Comércio Internacional das Espécies da Flora e Fauna Selvagens em Perigo de Extinção (CITES) ampliou as exigências de controle sobre o comércio de seus produtos. No Brasil, a Instrução Normativa Ibama nº 28/2024, alterada pelas Instruções Normativas nº 5/2025 e nº 5/2026, estabelece procedimentos aplicáveis ao manejo florestal e à comercialização internacional dessas espécies (Brasil, 2024; 2025; 2026). Entre esses procedimentos, qualquer espécie desses gêneros com densidade inferior a cinco árvores a cada 100 ha, com DAP mínimo de 20 cm, passou a ser considerada rara na UPA, e sua exploração foi vedada (Brasil, 2025), o que torna o conhecimento da densidade e da distribuição dos ipês dentro das áreas de manejo diretamente relevante para o planejamento da exploração. O enquadramento no Apêndice II não proíbe a exploração, mas exige que o comércio ocorra sob critérios de legalidade e de não prejuízo à sobrevivência das espécies, o que torna o conhecimento sobre distribuição, estrutura populacional e relações ambientais importante para subsidiar decisões de uso sustentável.

### 3.2.5 Particularidades ecológicas e importância do estudo individualizado das espécies

Embora *H. impetiginosus* e *H. serratifolius* compartilhem características como deciduidade, dispersão anemocórica e interesse madeireiro, a proximidade taxonômica não implica respostas ecológicas idênticas. As duas espécies apresentam diferenças na expressão gênica em condições experimentais de restrição hídrica, indicando mecanismos fisiológicos distintos de resposta ao ambiente (Sobreiro *et al.*, 2021). No Vale do Jari, *T. serratifolia* esteve entre as espécies presentes em todos os sítios analisados, enquanto *T. impetiginosa* foi registrada nas áreas planas, independentemente da distância do rio (Ferreira, 2009). Portanto, a análise individualizada da ocorrência de cada espécie constitui uma abordagem pertinente para investigar possíveis diferenças em suas associações ambientais.

## 3.3 Heterogeneidade ambiental e ocorrência de espécies arbóreas

A distribuição das espécies arbóreas nas florestas tropicais está relacionada à heterogeneidade ambiental e à atuação de processos ecológicos em diferentes escalas espaciais. A variação das condições físicas da paisagem forma ambientes com diferentes disponibilidades de água, nutrientes, luz e espaço, que influenciam a germinação, o estabelecimento, o crescimento e a sobrevivência das árvores. Associações entre a distribuição de indivíduos e características de solos e topografia foram identificadas em florestas da Costa Rica (Clark; Palmer; Clark, 1999), e, na Amazônia Ocidental, diferenças ambientais combinadas com processos de dispersão contribuem para a organização da composição florística (Tuomisto; Ruokolainen; Yli-Halla, 2003).

A heterogeneidade ambiental manifesta-se por meio de diferentes componentes, como relevo, hidrografia, propriedades edáficas, condições climáticas e estrutura da vegetação. Esses fatores são frequentemente interdependentes, uma vez que características topográficas influenciam a drenagem e a formação dos solos, enquanto a disponibilidade hídrica e a cobertura vegetal modificam as condições microambientais.

### 3.3.1 Relevo e organização topográfica da paisagem

O relevo influencia a distribuição de água, sedimentos e nutrientes ao longo da paisagem. A altitude pode representar, em escalas regionais, gradientes de temperatura e umidade; em paisagens de relevo suave, como grande parte da Amazônia, pequenas variações de altitude relacionam-se mais diretamente à organização da drenagem e à posição dos indivíduos em relação aos interflúvios e vales. A declividade, por sua vez, associa-se ao escoamento superficial, aos processos erosivos e à redistribuição de materiais ao longo das vertentes, diferenciando encostas, platôs e baixios quanto à saturação do solo.

Na Reserva Ducke, no Amazonas, a organização topográfica e edáfica da paisagem foi associada à composição de plantas do sub-bosque (Costa; Magnusson; Luizão, 2005). Para espécies arbóreas comerciais em floresta manejada, foram observadas respostas distintas entre espécies quanto à elevação, à declividade e à distância dos cursos d'água (Miron *et al.*, 2021). No Vale do Jari, a abundância de espécies arbóreas comerciais variou entre classes de altitude, declividade e distância ao rio, distinguindo espécies de baixio e de platô (Ferreira, 2009). Esses resultados demonstram que a influência do relevo não ocorre de maneira uniforme sobre todas as espécies.

### 3.3.2 Hidrografia, drenagem e disponibilidade hídrica

A disponibilidade de água influencia processos fisiológicos, crescimento vegetal e dinâmica populacional. Na Amazônia, cursos d'água, áreas temporariamente saturadas e diferentes condições de drenagem formam ambientes com características ecológicas particulares. Essas diferenças dependem da topografia local, da permeabilidade dos solos e da dinâmica da drenagem, não sendo determinadas exclusivamente pela proximidade horizontal da rede hidrográfica (Beven; Kirkby, 1979).

Em escala de bacia, as condições hidrológicas locais, definidas pela topografia e pelo solo, filtram espécies e afetam a diversidade e a composição das florestas de terra firme (Marca-Zevallos *et al.*, 2022), e a distância vertical até a drenagem mais próxima foi identificada como importante condicionante da composição florística em floresta da Amazônia Central (Schietti *et al.*, 2014). Em florestas manejadas, determinadas espécies apresentaram maior concentração em posições mais elevadas e afastadas dos cursos d'água, enquanto outras ocuparam a paisagem de forma distinta (Miron *et al.*, 2021). Assim, a influência da hidrografia sobre a distribuição das árvores resulta das relações entre disponibilidade de água, propriedades do solo e características topográficas.

### 3.3.3 Propriedades físicas e químicas dos solos

As propriedades físicas e químicas do solo influenciam a disponibilidade de nutrientes, a retenção de água, a aeração e o crescimento das raízes. Em florestas neotropicais da Colômbia, do Equador e do Panamá, a distribuição de espécies arbóreas foi associada à variação espacial de nutrientes do solo (John *et al.*, 2007). Entre as propriedades físicas, a textura determina a infiltração e a retenção de água: solos muito argilosos retêm mais água, enquanto texturas médias drenam mais rapidamente. Como as características edáficas variam junto com a posição topográfica (Costa; Magnusson; Luizão, 2005), a influência de uma propriedade do solo pode estar relacionada a outros componentes ambientais.

Para *H. serratifolius*, atributos edáficos tiveram contribuição relevante na distribuição potencial em escala continental (Elera-Gonzales *et al.*, 2026). A caracterização edáfica tem sido ampliada por bases digitais, como o SoilGrids (Hengl *et al.*, 2017; Poggio *et al.*, 2021) e, no Brasil, o mapeamento da textura do solo do MapBiomas Solo, disponível a 30 m (MapBiomas, 2026).

### 3.3.4 Condições climáticas e sazonalidade ambiental

O clima influencia a distribuição geográfica das espécies vegetais por meio da temperatura, da precipitação e da sazonalidade. Em regiões tropicais, a distribuição sazonal da precipitação afeta a disponibilidade de água no solo e processos fenológicos como floração, frutificação e dispersão de sementes. As duas espécies estudadas florescem associadas à perda de folhas, com variações regionais nos períodos reprodutivos (Camillo; Salomão, 2018; Carvalho, 2014), e a dispersão anemocórica é favorecida pelas condições da estação seca (Wright *et al.*, 2008).

A representação espacial do clima é feita por bases globais como o WorldClim (Fick; Hijmans, 2017) e o CHELSA, este último obtido por reescalonamento de reanálises atmosféricas com resolução aproximada de 1 km (Karger *et al.*, 2017). Entretanto, a influência climática manifesta-se de forma diferente conforme a escala: gradientes regionais diferenciam grandes formações vegetacionais, enquanto, dentro de uma mesma floresta, fatores locais como solos, relevo e luz tendem a ser mais evidentes. Variáveis climáticas de resolução quilométrica, quando usadas em áreas pequenas, tendem a diferenciar regiões e não locais dentro delas.

### 3.3.5 Estrutura da vegetação, luminosidade e histórico de perturbações

A densidade do dossel, a distribuição vertical das copas e a ocorrência de clareiras modificam a radiação, a temperatura e a umidade no interior da floresta (Chazdon; Fetcher, 1984), e as clareiras são importantes para a regeneração e a manutenção da diversidade arbórea (Denslow, 1987). Para os ipês, a luz é relevante no desenvolvimento inicial (Camillo; Salomão, 2018; Carvalho, 2014). A exploração seletiva de madeira altera a cobertura vegetal por meio de clareiras, estradas e trilhas de arraste (Asner *et al.*, 2005), de modo que o histórico de perturbações constitui elemento importante para compreender a heterogeneidade dos ambientes e a dinâmica das populações arbóreas.

### 3.3.6 Escala espacial e integração dos fatores ambientais

A influência dos fatores ambientais sobre a distribuição das espécies depende da escala espacial considerada (Guisan; Thuiller, 2005). Em escala regional, clima e grandes unidades geomorfológicas representam diferenças ambientais expressivas; em escalas locais, solos, relevo, drenagem e estrutura da vegetação assumem maior importância. A distribuição das espécies resulta de processos ambientais, ecológicos e históricos que atuam conjuntamente (Elith; Leathwick, 2009), o que envolve reconhecer tanto as condições físicas atuais quanto os efeitos acumulados da dispersão, do estabelecimento, da competição e das transformações ambientais.

## 3.4 Fundamentos da modelagem ambiental de espécies

A modelagem de distribuição de espécies investiga relações entre registros de ocorrência e características ambientais, produzindo representações espaciais da favorabilidade ambiental (Guisan; Zimmermann, 2000; Elith; Leathwick, 2009). Fundamenta-se no princípio de que a distribuição observada dos organismos apresenta relações com condições ambientais, embora também seja influenciada por processos históricos, bióticos e de dispersão.

### 3.4.1 Modelagem com dados de presença e algoritmo MaxEnt

Entre as abordagens utilizadas quando não existem ausências confirmadas, destaca-se o MaxEnt (Phillips; Anderson; Schapire, 2006). O algoritmo compara as condições ambientais das presenças com aquelas disponíveis no domínio considerado, representadas por pontos de referência denominados *background* (Elith *et al.*, 2011). O MaxEnt equivale a uma regressão de Poisson inomogênea e pode ser ajustado como regressão logística penalizada, o que permitiu sua implementação aberta no pacote `maxnet` do R (Phillips *et al.*, 2017). A complexidade do modelo é controlada pelas classes de *features* (transformações das variáveis, como linear, quadrática e *hinge*) e pelo multiplicador de regularização, que penaliza a complexidade (Merow; Smith; Silander Jr., 2013). As superfícies produzidas não representam a probabilidade absoluta de ocorrência, pois essa interpretação depende de pressupostos adicionais sobre a prevalência da espécie (Guillera-Arroita *et al.*, 2015).

Em ampla comparação entre métodos de modelagem com dados somente de presença, o MaxEnt esteve entre os de melhor desempenho preditivo (Elith *et al.*, 2006). O método foi utilizado para investigar a distribuição ambiental de espécies arbóreas no Vale do Jari a partir de inventários comerciais (Ferreira, 2009), para modelar seis espécies arbóreas, entre elas *H. impetiginosus*, no Parque Nacional de Sete Cidades, no Piauí (Gaia *et al.*, 2020), e para estimar a distribuição potencial de *H. serratifolius* em escala continental (Elera-Gonzales *et al.*, 2026).

### 3.4.2 Disponibilidade ambiental, área de referência e viés amostral

Nos modelos de presença-*background*, os pontos de referência representam ambientes disponíveis, e não locais onde a espécie esteja ausente. Diferenças entre o esforço amostral e a disponibilidade ambiental representada pelo *background* podem influenciar as relações estimadas (Phillips *et al.*, 2009), e a extensão geográfica considerada deve corresponder à região acessível às espécies (Barve *et al.*, 2011). Em inventários florestais comerciais, a disponibilidade dos registros está associada à localização das áreas de manejo e aos critérios dos levantamentos, que possuem limites geográficos definidos, mas não abrangem toda a variação ambiental acessível às espécies. No Vale do Jari, as diferenças ambientais entre as áreas influenciaram o desempenho dos modelos, evidenciando a relação entre representatividade ambiental e capacidade preditiva (Ferreira, 2009).

### 3.4.3 Variáveis ambientais, complexidade e interpretação das relações ecológicas

A seleção de variáveis deve considerar sua relação com os processos ecológicos envolvidos (Elith; Leathwick, 2009), lembrando que uma variável pode atuar diretamente sobre a espécie ou refletir indiretamente outros componentes do ambiente. A correlação entre preditores dificulta a identificação da contribuição individual de cada componente ambiental (Dormann *et al.*, 2013), situação comum em paisagens florestais, nas quais relevo, solos e drenagem variam de forma associada. Modelos excessivamente complexos tendem a reproduzir particularidades dos dados e a generalizar pior (Warren; Seifert, 2011), e diferentes configurações do MaxEnt produzem comportamentos preditivos distintos (Radosavljevic; Anderson, 2014). Por isso, a escolha da configuração deve equilibrar ajuste e capacidade de generalização, e a interpretação ecológica não deve depender exclusivamente da importância estatística atribuída a cada variável.

### 3.4.4 Avaliação do desempenho e capacidade de generalização

A área sob a curva ROC (AUC) é a métrica mais utilizada na avaliação de modelos de distribuição, mas seus valores dependem da extensão do domínio e das características dos dados de avaliação (Lobo; Jiménez-Valverde; Real, 2008). Em modelos de presença-*background*, a AUC expressa a capacidade de discriminar presenças em relação aos pontos de referência, e não a ausências confirmadas. O *True Skill Statistic* (TSS) foi desenvolvido para dados de presença e ausência (Allouche; Tsoar; Kadmon, 2006), e sua aplicação com *background* exige cautela. Por isso, em dados somente de presença, recomendam-se também o índice de Boyce contínuo, que verifica se a frequência de presenças aumenta com a adequabilidade prevista (Hirzel *et al.*, 2006), e as taxas de omissão em limiares definidos no treino (Radosavljevic; Anderson, 2014).

A estrutura espacial dos dados também influencia as avaliações: divisões aleatórias de registros espacialmente próximos produzem estimativas otimistas da capacidade preditiva (Roberts *et al.*, 2017). Em resposta, recomendam-se partições em blocos espaciais (Valavi *et al.*, 2019), como a validação que retira uma unidade geográfica inteira por vez. A avaliação em áreas geograficamente independentes é especialmente relevante para estudos baseados em inventários florestais, pois testa a capacidade de prever locais distintos daqueles usados na calibração.

### 3.4.5 Transferência espacial e limitações das predições ambientais

A transferência espacial corresponde à aplicação de um modelo em área diferente daquela utilizada para estabelecer suas relações ambientais. Quando a nova área apresenta condições semelhantes às da calibração, a predição ocorre dentro do domínio ambiental conhecido; condições distintas exigem extrapolação e aumentam a incerteza (Owens *et al.*, 2013). No contexto amazônico, foram identificadas dificuldades de transferência de modelos entre áreas com diferenças ambientais (Ferreira, 2009). A modelagem de *H. impetiginosus* e *H. serratifolius* insere-se nesse contexto, considerando a ampla distribuição geográfica das espécies e a heterogeneidade dos ambientes onde ocorrem.

# 4 MATERIAL E MÉTODOS

## 4.1 Área de estudo e procedência dos dados

As áreas de estudo correspondem a 34 propriedades com Planos de Manejo Florestal Sustentável (PMFS) e suas Unidades de Produção Anual (UPAs), localizadas nos municípios de Portel (11 propriedades), Aveiro (8), Juruti (7), Prainha (5) e Santarém (3), no Estado do Pará, totalizando 78 UPAs inventariadas e cerca de 67.000 ha. As propriedades formam três agrupamentos geográficos, distantes entre si cerca de 300 km no sentido oeste–leste: o grupo oeste, entre Juruti, Santarém e Aveiro, que reúne todas as propriedades com *H. impetiginosus*; o grupo central, em Prainha; e o grupo leste, em Portel (Figura 1). Os registros de árvores dos inventários a 100%, os limites vetoriais das UPAs inventariadas e a hidrografia mapeada das propriedades foram fornecidos pela empresa Green Forest Projetos e Serviços Ambientais Ltda., sediada em Belém (PA), no âmbito do Acordo de Cooperação Técnica (ACT) firmado entre a Universidade Federal Rural da Amazônia e a referida empresa, sob a coordenação da Prof.ª Dra. Gracialda Costa Ferreira. Considerando aspectos éticos e de confidencialidade, a identificação dos imóveis e empreendimentos foi codificada (P01 a P34), e os dados geográficos foram utilizados de acordo com as condições de autorização de uso, preservando-se uma tabela de correspondência interna para rastreabilidade.

![**Figura 1 –** Localização das 34 propriedades sob manejo florestal sustentável no Estado do Pará, Brasil: (a) Estado do Pará no Brasil; (b) região de estudo, com os limites municipais e os três agrupamentos de propriedades; (c–e) propriedades dos grupos oeste, central e leste, segundo a ocorrência das espécies e o conjunto de dados (desenvolvimento ou teste externo). Fonte: elaborada pelo autor (2026), com limites territoriais do Instituto Brasileiro de Geografia e Estatística (2024) e imagem de satélite Esri World Imagery (ESRI, 2026).](github/tcc_skill_modelagem_ambiental_ipe/resultados/_geral/10_mapa/FIGURA1_LOCALIZACAO.png){width=16cm}

O inventário original continha 11.326 indivíduos das duas espécies (5.381 de *H. impetiginosus* e 5.945 de *H. serratifolius*). A Tabela 1 apresenta a distribuição das presenças utilizadas por propriedade, após a preparação descrita na seção 4.3.

**Tabela 1 –** Número de UPAs, área inventariada e número de presenças (uma por espécie por pixel de 30 m) de *Handroanthus impetiginosus* e *H. serratifolius* por propriedade sob manejo florestal sustentável no Estado do Pará, Brasil.

| Propriedade | Conjunto | UPAs | Área (ha) | *H. impetiginosus* | *H. serratifolius* |
|---|---|---:|---:|---:|---:|
| P01 | Desenvolvimento | 3 | 2.410 | 0 | 1.200 |
| P02 | Desenvolvimento | 3 | 3.805 | 0 | 1.045 |
| P03 | Desenvolvimento | 2 | 2.007 | 735 | 0 |
| P04 | Desenvolvimento | 3 | 2.778 | 574 | 0 |
| P05 | Desenvolvimento | 3 | 1.710 | 0 | 520 |
| P06 | Desenvolvimento | 2 | 1.845 | 486 | 0 |
| P07 | Desenvolvimento | 3 | 2.486 | 66 | 369 |
| P08 | Desenvolvimento | 3 | 1.798 | 83 | 350 |
| P09 | Desenvolvimento | 3 | 1.774 | 0 | 303 |
| P10 | Desenvolvimento | 2 | 1.431 | 0 | 302 |
| P11 | Desenvolvimento | 2 | 1.486 | 0 | 286 |
| P12 | Desenvolvimento | 2 | 1.168 | 280 | 0 |
| P13 | Desenvolvimento | 2 | 1.212 | 278 | 0 |
| P14 | Desenvolvimento | 2 | 2.355 | 275 | 0 |
| P15 | Desenvolvimento | 2 | 1.325 | 57 | 200 |
| P16 | Desenvolvimento | 3 | 2.035 | 62 | 136 |
| P17 | Desenvolvimento | 2 | 972 | 188 | 0 |
| P18 | Desenvolvimento | 2 | 817 | 164 | 0 |
| P19 | Desenvolvimento | 2 | 1.604 | 0 | 159 |
| P20 | Desenvolvimento | 1 | 483 | 0 | 124 |
| P21 | Desenvolvimento | 3 | 2.967 | 0 | 98 |
| P22 | Desenvolvimento | 2 | 2.325 | 0 | 95 |
| P23 | Desenvolvimento | 3 | 2.251 | 0 | 93 |
| P24 | Desenvolvimento | 3 | 2.495 | 0 | 71 |
| P25 | Desenvolvimento | 3 | 2.995 | 0 | 42 |
| P26 | Desenvolvimento | 2 | 1.993 | 0 | 23 |
| P27 | Desenvolvimento | 1 | 792 | 0 | 16 |
| **Subtotal** | | **64** | **51.319** | **3.248** | **5.432** |
| P28 | Teste externo | 2 | 1.495 | 707 | 0 |
| P29 | Teste externo | 1 | 1.284 | 678 | 0 |
| P30 | Teste externo | 2 | 1.402 | 505 | 0 |
| P31 | Teste externo | 3 | 4.238 | 0 | 151 |
| P32 | Teste externo | 3 | 4.043 | 0 | 130 |
| P33 | Teste externo | 2 | 1.973 | 0 | 31 |
| P34 | Teste externo | 1 | 1.221 | 0 | 22 |
| **Subtotal** | | **14** | **15.656** | **1.890** | **334** |
| **Total** | | **78** | **66.975** | **5.138** | **5.766** |

Fonte: elaborada pelo autor (2026).

## 4.2 Tipo de pesquisa e delineamento

A pesquisa foi do tipo observacional, pois utilizou dados já existentes, obtidos em inventários florestais a 100%, sem manipulação de tratamentos ou controle das condições ambientais pelo pesquisador; as relações entre ocorrência e ambiente foram, portanto, investigadas por associação, e não por experimentação. A abordagem foi quantitativa e espacial, e a unidade de organização dos dados foi a propriedade, subdividida em UPAs. As ocorrências de *H. impetiginosus* e *H. serratifolius* foram analisadas separadamente, em modelos de presença e *background*.

Os PMFS foram incluídos quando apresentavam simultaneamente: (i) inventário a 100% com coordenadas das árvores; (ii) identificação da UPA de cada registro; (iii) polígono da área efetivamente inventariada; e (iv) critério de inclusão compatível com o DAP mínimo analítico adotado (seção 4.3). Das 34 propriedades que atenderam a esses critérios, sete foram separadas antes da modelagem e reservadas exclusivamente para o teste externo (seção 4.10): três com registros de *H. impetiginosus* e quatro com registros de *H. serratifolius*. A reserva foi feita por propriedades inteiras, e a partição só foi aceita se o conjunto de teste tivesse pelo menos 30 presenças de cada espécie, se o de desenvolvimento tivesse pelo menos 100 e se nenhuma UPA de teste estivesse a menos de 5 km de uma UPA de desenvolvimento; a menor distância observada entre os dois conjuntos foi de 21 km. As 27 propriedades restantes (64 UPAs) constituíram o conjunto de desenvolvimento, usado na análise descritiva, na seleção das variáveis e na escolha da configuração dos modelos.

O fluxo de trabalho compreendeu: (i) organização e controle de qualidade dos inventários; (ii) preparação das camadas ambientais; (iii) análise descritiva da relação entre a densidade das espécies e as variáveis ambientais; (iv) busca sistemática da configuração dos modelos, testando todas as combinações de variáveis e de parâmetros com validação por propriedade; (v) escolha do modelo final por critérios definidos previamente; e (vi) avaliação do modelo escolhido nas propriedades reservadas. As operações de geoprocessamento foram realizadas no QGIS (QGIS Development Team, 2026) e as análises estatísticas e a modelagem no R, versão 4.6.2 (R Core Team, 2026), com os pacotes listados no Quadro 1. As etapas do trabalho estão resumidas na Figura 2.

![**Figura 2 –** Fluxograma das etapas metodológicas, da preparação dos dados ao teste externo. Fonte: elaborada pelo autor (2026).](github/tcc_skill_modelagem_ambiental_ipe/resultados/_geral/11_figuras_tcc/F_FLUXOGRAMA.png){width=14cm}

**Quadro 1 –** Programas e pacotes utilizados, versões e finalidade.

| Programa/pacote | Versão | Finalidade | Referência |
|---|---|---|---|
| QGIS | 4.0.3 | Geoprocessamento, extração de variáveis e mapas | QGIS Development Team (2026) |
| GDAL | 3.13.0 | Reprojeção, declividade, rasterização e distâncias | GDAL/OGR Contributors (2026) |
| Google Earth Engine | – | Obtenção da textura do solo (MapBiomas) | Gorelick *et al.* (2017) |
| R | 4.6.2 | Análises estatísticas e modelagem | R Core Team (2026) |
| maxnet | 0.1.4 | Ajuste do MaxEnt | Phillips *et al.* (2017) |
| glmnet | 5.2 | Regressão penalizada usada pelo maxnet | Friedman, Hastie e Tibshirani (2010) |
| ecospat | 4.1.4 | Índice de Boyce contínuo | Di Cola *et al.* (2017) |
| terra | 1.9-60 | Leitura e escrita de rasters | Hijmans (2026) |
| sf | 1.1-3 | Dados vetoriais e projeções | Pebesma (2018) |
| usdm | 2.1-7 | Fator de inflação da variância | Naimi *et al.* (2014) |
| ggplot2 | 4.0.4 | Gráficos | Wickham (2016) |
| ggspatial | 1.1.11 | Escala e seta de norte nos mapas | Dunnington (2026) |
| patchwork | 1.3.2 | Composição de figuras | Pedersen (2026) |
| maptiles | 0.13.0 | Imagem de satélite de fundo do mapa | Giraud (2026) |

Fonte: elaborado pelo autor (2026).

## 4.3 Dados brutos e preparação dos registros de ocorrência

Os dados foram recebidos, para cada propriedade, na forma de: (i) planilhas do inventário a 100% (arquivos CSV), com nome vulgar, nome científico, DAP, UPA, unidade de trabalho (UT), número da árvore e coordenadas; (ii) polígonos das UPAs inventariadas; e (iii) a rede hidrográfica mapeada da propriedade. Os arquivos originais foram preservados, e todo o processamento foi realizado em cópias. No QGIS, os dados de cada propriedade foram reunidos em um GeoPackage, contendo as camadas de árvores, de UPAs e de hidrografia, e o sistema de referência e as geometrias de cada camada foram conferidos.

As coordenadas, coletadas no sistema SIRGAS 2000 (Sistema de Referência Geocêntrico para as Américas), em projeção UTM, e disponibilizadas também em latitude e longitude (EPSG:4674), foram mantidas em projeção métrica para as operações de distância e área: SIRGAS 2000/UTM zona 21S (EPSG:31981) ou zona 22S (EPSG:31982), conforme a localização de cada propriedade. Cada árvore foi associada à UPA em que estava localizada.

Foram padronizados os campos de empreendimento, UPA, UT, identificador da árvore, nome vulgar, nome científico, coordenadas e DAP, e um identificador composto por empreendimento, UPA, UT e número da árvore permitiu rastrear cada registro. A identificação das duas espécies foi padronizada segundo os nomes científicos aceitos, com conversão dos sinônimos *Tabebuia impetiginosa* e *T. serratifolia*.

O inventário original continha 11.326 indivíduos das duas espécies. Embora o censo incluísse árvores a partir de 5 cm de DAP, adotou-se como critério analítico DAP superior a 10 cm, resultando em 9.004 indivíduos nas propriedades de desenvolvimento (3.395 de *H. impetiginosus* e 5.609 de *H. serratifolius*). Para reduzir a pseudorreplicação, manteve-se uma presença por espécie por pixel de 30 m, de modo que árvores vizinhas na mesma célula ambiental não fossem contadas como informações independentes; com isso, 324 registros (147 e 177, respectivamente) não foram contabilizados como presenças distintas, resultando em 3.248 e 5.432 presenças (Tabela 1). Todos os indivíduos foram preservados na base original.

## 4.4 Obtenção e preparação das variáveis ambientais

Foram avaliadas seis variáveis ambientais, escolhidas por hipóteses ecológicas sobre relevo, drenagem, solo e clima (Tabela 2). Todas foram processadas por propriedade, em uma área formada pelas UPAs acrescidas de uma margem de 300 m, e convertidas para uma grade comum de 30 m em projeção UTM, de modo que os pixels de todas as variáveis coincidissem exatamente. As operações foram executadas por meio de rotinas em Python no console do QGIS, com as ferramentas da biblioteca GDAL (GDAL/OGR Contributors, 2026).

**Tabela 2 –** Variáveis ambientais avaliadas na modelagem da ocorrência de *Handroanthus impetiginosus* e *H. serratifolius*, com fonte, resolução espacial nativa e hipótese ecológica associada.

| Variável | Fonte | Resolução nativa | Hipótese ecológica |
|---|---|---|---|
| Altitude (m) | ANADEM v1.0 (Laipelt *et al.*, 2024) | 30 m | Posição na paisagem (baixio, encosta, platô) |
| Declividade (graus) | Derivada do ANADEM | 30 m | Forma do terreno e escoamento superficial |
| Distância à hidrografia (m) | Hidrografia mapeada das propriedades | 30 m (rasterizada) | Encharcamento e proximidade de baixios |
| BIO12 – precipitação anual (mm) | CHELSA v2.1 mensal, 1980–2021 (Karger *et al.*, 2017) | ~1 km | Disponibilidade hídrica regional |
| BIO17 – precipitação do trimestre mais seco (mm mês⁻¹) | CHELSA v2.1 mensal, 1980–2021 (Karger *et al.*, 2017) | ~1 km | Intensidade da estação seca (fenologia e dispersão) |
| Textura do solo, 0–30 cm (categórica) | MapBiomas Solo, Coleção 3 (MapBiomas, 2026) | 30 m | Drenagem interna e retenção de água |

Fonte: elaborada pelo autor (2026).

**Altitude e declividade.** Foram obtidas do Modelo Digital de Terreno (MDT) ANADEM v1.0, que corrige o efeito da vegetação sobre a elevação do modelo Copernicus (Laipelt *et al.*, 2024). Os seis blocos do ANADEM que cobrem as áreas, em SIRGAS 2000 geográfico, foram unidos em um mosaico virtual por propriedade e reprojetados para UTM com pixel de 30 m por interpolação bilinear. A declividade foi calculada em graus pelo método de Horn (1981), com uma faixa adicional de 90 m ao redor da área para evitar distorções nas bordas, e os dois rasters foram então recortados pela área das UPAs com margem de 300 m.

**Distância à hidrografia.** Os polígonos de rios e igarapés mapeados nas 34 propriedades, fornecidos junto com os inventários (seção 4.1), foram reunidos em duas redes regionais, uma para cada zona UTM, de modo que a distância de cada pixel considerasse também cursos d'água situados em propriedades vizinhas ou em UPAs não inventariadas. Os polígonos foram rasterizados na mesma grade de 30 m da altitude, considerando todos os pixels tocados pelas feições, e a distância euclidiana de cada pixel até o pixel de água mais próximo foi calculada em metros, com a ferramenta de proximidade do GDAL. Árvores situadas sobre a hidrografia receberam distância zero e não foram excluídas.

**Clima.** Como a climatologia bioclimática oficial do CHELSA v2.1 refere-se ao período de 1981 a 2010, as variáveis climáticas foram calculadas para o período de 1980 a 2021. Para isso, foram obtidas as 504 imagens mensais de precipitação do CHELSA v2.1 (Karger *et al.*, 2017) recortadas para as áreas de estudo; calculou-se a média de cada mês ao longo dos 42 anos, obtendo-se 12 médias mensais. A BIO12 correspondeu à soma das 12 médias (mm ano⁻¹), e a BIO17, à menor média entre os 12 trimestres consecutivos possíveis (de janeiro-fevereiro-março a dezembro-janeiro-fevereiro), expressa em mm mês⁻¹. Os rasters resultantes, de cerca de 1 km, foram alinhados à grade de 30 m pelo vizinho mais próximo, o que não altera sua resolução informativa original.

**Textura do solo.** O subgrupo textural da camada de 0 a 30 cm foi obtido da Coleção 3 do MapBiomas Solo (MapBiomas, 2026), na plataforma Google Earth Engine (Gorelick *et al.*, 2017), e exportado para cada propriedade em UTM com pixel de 30 m, por reamostragem pelo vizinho mais próximo, que preserva as classes. As classes presentes nas áreas foram: muito argilosa (teor de argila maior que 60%), argilosa (35 a 60%), média-argilosa (20 a 35%), média-siltosa (argila até 35% e areia de 15 a 55%) e média-arenosa (areia de 55 a 70% e argila de 15 a 20%) (MapBiomas, 2026). A textura foi tratada como variável categórica, sem ordenação entre as classes.

**Extração dos valores.** Os valores das seis variáveis foram extraídos para cada árvore e para cada ponto de *background* (seção 4.5) a partir dos rasters alinhados. Para a distância à hidrografia, utilizou-se o valor do raster de 30 m, o mesmo usado nas predições dos modelos.

**Escala e colinearidade.** Como as variáveis climáticas possuem resolução nativa de cerca de 1 km, sua reamostragem para 30 m não cria variação local. Por isso, quantificou-se a proporção da variação de cada variável que ocorre entre propriedades, por análise de variância dos pontos de *background* com a propriedade como fator, para distinguir variáveis de efeito regional das de efeito local. A colinearidade entre as variáveis contínuas foi avaliada pelos coeficientes de correlação de Pearson e de Spearman, adotando-se |r| > 0,7 como indicativo de redundância (Dormann *et al.*, 2013), e pelo fator de inflação da variância (VIF), com limite de 5 (Naimi *et al.*, 2014); a textura foi incluída pelo código de suas classes, ordenadas da mais para a menos argilosa. Essas avaliações usaram apenas o *background* das propriedades de desenvolvimento.

## 4.5 Ocorrência das espécies nas propriedades e definição do ambiente disponível (*background*)

As duas espécies apresentaram distribuição quase segregada entre as propriedades: das 27 propriedades de desenvolvimento, quatro apresentaram registros das duas espécies, oito apenas de *H. impetiginosus* e quinze apenas de *H. serratifolius* (Tabela 1). Como, nas UPAs inventariadas, todas as árvores que atendiam ao critério de inclusão foram registradas, ambas as espécies foram procuradas com o mesmo esforço em todas as propriedades. Assim, a ausência de registros de uma espécie em uma propriedade inventariada indica que a espécie não foi encontrada naquela área, embora não constitua ausência comprovada no sentido estatístico.

Com base nisso, o ambiente disponível de cada espécie foi definido como o conjunto das 64 UPAs de desenvolvimento, incluindo as propriedades onde a espécie não foi registrada, já que essas áreas foram efetivamente percorridas e representam ambientes em que a espécie poderia ter sido encontrada. O *background* foi composto por 10.000 pontos sorteados aleatoriamente nos pixels válidos dessas UPAs, com número de pontos por UPA proporcional à sua área (Phillips; Dudík, 2008; Barbet-Massin *et al.*, 2012), e foi o mesmo para as duas espécies. Não foram sorteados pontos fora das áreas inventariadas, pois nelas não se conhece a ocorrência das espécies (Phillips *et al.*, 2009). O *background* não foi interpretado como ausência comprovada. A sensibilidade dos resultados ao *background* foi verificada com novos sorteios de 5.000 e 20.000 pontos, e, nas propriedades reservadas, o *background* foi sorteado com a mesma densidade de pontos por área.

## 4.6 Análise descritiva da relação entre densidade e ambiente

Antes da modelagem, e de forma independente dela, a relação entre as espécies e o ambiente foi descrita seguindo a abordagem de Ferreira (2009). Cada variável contínua foi dividida em oito classes intervalares de igual frequência no *background*. Em cada classe, calculou-se a densidade de cada espécie (árvores ha⁻¹), dividindo o número de presenças pela área da classe, estimada pelos pontos de *background* ponderados pela área de suas UPAs (cada pixel corresponde a 0,09 ha). A densidade foi calculada por propriedade e resumida pela média e pelo erro padrão entre as propriedades em que a espécie ocorre, desconsiderando classes com menos de 5 ha na propriedade, e a tendência foi descrita por modelos polinomiais ajustados aos valores médios das classes, adotando-se o modelo quadrático quando este elevou o R² em mais de 0,10 em relação ao linear. Também foram calculadas as densidades em classes combinadas de altitude e declividade e de altitude e distância à hidrografia, e por classe de textura do solo.

Nessa análise, diferentemente do *background* dos modelos, utilizaram-se apenas as propriedades em que cada espécie ocorre, para descrever onde a espécie se concentra dentro das áreas que ocupa, sem que a segregação entre propriedades dominasse o resultado. As condições ambientais das presenças foram comparadas às do ambiente disponível nessas propriedades pelo teste de Mann-Whitney, e, nas quatro propriedades com registros das duas espécies, compararam-se os ambientes ocupados por cada uma, o que permite contrastar as espécies sob as mesmas condições regionais.

## 4.7 Partição dos dados para treinamento e validação

Os dados foram organizados em três níveis de partição, todos por propriedades ou UPAs inteiras, para que as avaliações não fossem infladas pela proximidade entre árvores de treino e de validação (Roberts *et al.*, 2017):

a) **teste externo**: as sete propriedades reservadas (seção 4.2), usadas uma única vez, apenas para avaliar o modelo final (seção 4.10);

b) **validação cruzada por propriedade (LOPO, do inglês *leave-one-property-out*)**: usada na escolha das variáveis e dos parâmetros. Cada propriedade de desenvolvimento com presenças da espécie formou uma partição, e as propriedades sem a espécie formaram uma partição adicional, contendo apenas *background*. Em cada rodada, uma partição foi retirada, o modelo foi treinado com as presenças e o *background* das demais e avaliado nas presenças e no *background* da partição retirada. Assim, *H. impetiginosus* teve 13 partições (12 propriedades com a espécie e uma partição com as 15 propriedades sem a espécie) e *H. serratifolius*, 20 (19 + uma com as 8 propriedades sem a espécie). Esse desenho avalia diretamente a capacidade de prever uma propriedade nova (Valavi *et al.*, 2019);

c) **desenhos alternativos**, usados apenas para mostrar a influência do desenho de validação sobre as métricas: três e cinco blocos de propriedades, três blocos de UPAs e divisão aleatória das árvores em duas metades. Nos desenhos em blocos, as propriedades (ou UPAs) foram distribuídas entre os blocos de modo a equilibrar o número de presenças, atribuindo-se sucessivamente a maior unidade ainda não alocada ao bloco com menos presenças; as unidades sem a espécie foram distribuídas de modo a equilibrar o *background*.

## 4.8 Configuração dos modelos MaxEnt e métricas de avaliação

Os modelos foram ajustados com o pacote `maxnet` (Phillips *et al.*, 2017), com saída *cloglog* e *clamping* ativado, de modo que as predições foram interpretadas como adequabilidade ambiental relativa. A grade de parâmetros seguiu as recomendações de Radosavljevic e Anderson (2014) e Muscarella *et al.* (2014): classes de *features* linear (L), linear e quadrática (LQ) e linear, quadrática e *hinge* (LQH), que vão da resposta mais simples à mais flexível, e multiplicadores de regularização (RM) de 0,5; 1; 2; 3 e 4, que vão da menor à maior penalização da complexidade. As classes produto e *threshold* não foram incluídas, por produzirem respostas de difícil interpretação ecológica (Merow; Smith; Silander Jr., 2013).

Em cada rodada da validação LOPO, as predições da partição retirada foram reunidas às das demais rodadas para o cálculo das métricas:

a) AUC presença-*background*, calculada pela estatística de Mann-Whitney e interpretada com as cautelas apontadas por Lobo, Jiménez-Valverde e Real (2008), adotando-se 0,75 como referência de desempenho útil (Ferreira, 2009);

b) índice de Boyce contínuo, que varia de -1 a 1 e indica se a frequência de presenças aumenta com a adequabilidade prevista (Hirzel *et al.*, 2006);

c) omissão no limiar P10: proporção das presenças da propriedade retirada com adequabilidade abaixo do 10º percentil das presenças de treino, cujo valor esperado é 10% (Radosavljevic; Anderson, 2014);

d) AUC dentro da propriedade: AUC calculada apenas com as presenças e o *background* da própria propriedade retirada, que indica se o modelo distingue os locais ocupados dentro de uma mesma área.

Para comparar os modelos, as quatro métricas foram convertidas em postos e a pontuação de cada modelo correspondeu à média dos postos.

## 4.9 Seleção do modelo final

A seleção foi realizada em etapas, apenas com as propriedades de desenvolvimento e a validação LOPO:

a) **combinações de variáveis**: as 57 combinações com duas a seis variáveis foram avaliadas com uma configuração fixa (LQ, RM 2), e as três combinações de maior pontuação seguiram para a etapa seguinte. Modelos com uma única variável não foram considerados candidatos, pois um único fator ambiental não descreve as condições associadas à ocorrência de uma espécie, que resultam da ação conjunta de diferentes componentes da paisagem (Elith; Leathwick, 2009);

b) **parâmetros**: as três combinações foram avaliadas nas 15 configurações de parâmetros. Foram considerados equivalentes ao melhor os modelos com AUC LOPO até 0,01 abaixo da maior AUC e omissão P10 de até 12%, próxima do valor esperado de 10%. Entre os equivalentes, preferiu-se o de menor número de variáveis e, depois, o de *features* mais simples (L, LQ e LQH, nessa ordem), pois modelos mais simples tendem a transferir melhor para áreas novas (Warren; Seifert, 2011; Radosavljevic; Anderson, 2014). Quando as configurações restantes diferiram em menos de 0,005 de AUC, adotou-se o RM 1, valor padrão do MaxEnt (Phillips; Dudík, 2008);

c) **coerência ecológica**: as curvas de resposta do modelo escolhido deveriam ser compatíveis com a análise descritiva (seção 4.6) e com a literatura sobre a ecologia das espécies.

Após a escolha, para verificar se alguma outra combinação superava claramente o modelo escolhido e para quantificar a contribuição de cada variável, foram avaliadas, com a mesma validação LOPO, todas as 63 combinações possíveis das seis variáveis – incluindo os modelos com uma única variável e o modelo com as seis variáveis juntas – em todas as 15 configurações de parâmetros, totalizando 945 modelos por espécie (Apêndice A). A contribuição de cada variável foi resumida pela diferença entre o desempenho médio dos modelos que a contêm e o dos modelos que não a contêm. Também foi avaliada a sensibilidade do modelo escolhido ao desenho de validação e ao *background*.

Para o modelo escolhido e para o modelo com as seis variáveis, realizou-se o teste Jackknife (Phillips; Anderson; Schapire, 2006; Ferreira, 2009), ajustando-se o modelo com somente cada variável e sem cada variável, e foram construídas as curvas de resposta e a curva ROC.

## 4.10 Teste externo nas propriedades reservadas

Após o congelamento da escolha das variáveis, dos parâmetros e dos limiares, o modelo final de cada espécie foi ajustado com todas as propriedades de desenvolvimento e avaliado uma única vez nas propriedades reservadas, que não participaram de nenhuma etapa anterior. Foram calculados a AUC, o índice de Boyce, a omissão nos limiares P10 e MTP (mínima presença de treino), ambos definidos com os dados de treino, e a AUC dentro de cada propriedade reservada. O protocolo de cada teste foi registrado antes de sua execução, e o resultado não foi utilizado para reajustar os modelos.

## 4.11 Produtos

Os produtos incluíram as tabelas de presenças por propriedade, o desempenho dos 945 modelos de cada espécie, resumido no Apêndice A pela melhor configuração de cada combinação de variáveis, os gráficos de densidade por classe ambiental, o teste Jackknife, as curvas de resposta e ROC e os mapas de adequabilidade ambiental relativa por propriedade, exportados em formato GeoTIFF e finalizados no QGIS. A interpretação ficou restrita às áreas inventariadas e às condições ambientais representadas na calibração.

# 5 RESULTADOS

## 5.1 Caracterização das ocorrências e das variáveis ambientais

As duas espécies apresentaram distribuição quase segregada entre as propriedades (Tabela 1). Das 27 propriedades de desenvolvimento, *H. impetiginosus* ocorreu em 12 e *H. serratifolius* em 19, e apenas quatro (P07, P08, P15 e P16) continham registros de ambas. As ocorrências concentraram-se em poucas propriedades: as três propriedades com mais registros reuniram 55% das presenças de *H. impetiginosus* e as duas primeiras, 41% das de *H. serratifolius*.

Nenhum par de variáveis ultrapassou o limite de |r| = 0,7 (Figura 3). As maiores correlações ocorreram entre altitude e BIO12 (Pearson = −0,69; Spearman = −0,60) e entre BIO12 e BIO17 (Pearson = 0,53), e o maior VIF foi o de BIO12 (4,13), abaixo do limite de 5; os demais VIFs variaram de 1,09 (declividade) a 3,07 (altitude). Assim, as seis variáveis foram mantidas como candidatas à modelagem.

![**Figura 3 –** Coeficientes de correlação de Pearson (acima da diagonal) e de Spearman (abaixo da diagonal) entre as variáveis ambientais, calculados nos 10.000 pontos de *background* das propriedades de desenvolvimento. Fonte: elaborada pelo autor (2026).](github/tcc_skill_modelagem_ambiental_ipe/resultados/_geral/11_figuras_tcc/F_CORREL.png){width=12cm}

## 5.2 Relação entre densidade e variáveis ambientais

Nas duas espécies, as menores densidades ocorreram nos primeiros 60 m a partir da drenagem: 0,08 árvore ha⁻¹ para *H. impetiginosus* e 0,07 árvore ha⁻¹ para *H. serratifolius* (Figuras 4c e 5c). Para *H. impetiginosus*, a densidade aumentou linearmente com a distância à hidrografia (R² = 0,59; p = 0,026), atingindo 0,26 árvore ha⁻¹ a mais de 680 m; para *H. serratifolius*, a densidade passou a 0,12–0,16 árvore ha⁻¹ a partir de 60 m, sem tendência significativa nas classes seguintes (R² quadrático = 0,45; p = 0,23). Considerando a densidade total das propriedades em conjunto, o aumento com a distância à hidrografia foi significativo nas duas espécies (R² linear = 0,53, p = 0,04, e 0,88, p < 0,001, respectivamente).

Em relação à altitude, a densidade de *H. impetiginosus* aumentou linearmente (R² = 0,96; p < 0,001), de 0,02 árvore ha⁻¹ abaixo de 39 m para 0,33 árvore ha⁻¹ acima de 133 m, embora essa última classe tenha apresentado grande variação entre propriedades (Figura 4a). *Handroanthus serratifolius* apresentou resposta unimodal (R² quadrático = 0,65; p = 0,07), com maior densidade entre 86 e 107 m (0,32 árvore ha⁻¹) (Figura 5a). A declividade teve pouca influência: a densidade de *H. impetiginosus* manteve-se entre 0,15 e 0,17 árvore ha⁻¹ até 6,3° e foi de 0,14 árvore ha⁻¹ acima desse valor (R² quadrático = 0,70; p = 0,047) (Figura 4b), e a de *H. serratifolius* aumentou de 0,13 para 0,18 árvore ha⁻¹ até 6,3°, diminuindo nas declividades maiores (R² quadrático = 0,80; p = 0,017) (Figura 5b).

Nas variáveis climáticas, a densidade de *H. impetiginosus* foi praticamente nula nas classes de BIO17 entre 50 e 54 mm mês⁻¹ e máxima entre 70 e 72 mm mês⁻¹ (0,25 árvore ha⁻¹), com tendência quadrática marginalmente significativa (R² = 0,82; p = 0,08), e não apresentou tendência com BIO12 (R² = 0,36; p = 0,33) (Figuras 4d e 4e). Para *H. serratifolius*, não houve tendência com BIO12 (R² = 0,00; p = 0,94) nem com BIO17 (R² = 0,33; p = 0,18), embora a maior densidade tenha ocorrido entre 64 e 68 mm mês⁻¹ (0,38 árvore ha⁻¹) (Figuras 5d e 5e). Como essas variáveis variam quase só entre propriedades (Tabela 3), cada classe climática corresponde a poucas propriedades, o que explica os erros padrão elevados.

![**Figura 4 –** Valores médios e erro padrão da densidade (árvores ha⁻¹) de *Handroanthus impetiginosus* nas classes de (a) altitude, (b) declividade, (c) distância à hidrografia, (d) BIO12 e (e) BIO17 e (f) por classe de textura do solo, nas propriedades de desenvolvimento em que a espécie ocorre, com a tendência ajustada, seu intervalo de confiança de 95%, a equação e o coeficiente de determinação. Fonte: elaborada pelo autor (2026).](github/tcc_skill_modelagem_ambiental_ipe/resultados/_geral/11_figuras_tcc/F_DENS_roxo.png){width=16cm}

![**Figura 5 –** Valores médios e erro padrão da densidade (árvores ha⁻¹) de *Handroanthus serratifolius* nas classes de (a) altitude, (b) declividade, (c) distância à hidrografia, (d) BIO12 e (e) BIO17 e (f) por classe de textura do solo, nas propriedades de desenvolvimento em que a espécie ocorre, com a tendência ajustada, seu intervalo de confiança de 95%, a equação e o coeficiente de determinação. Fonte: elaborada pelo autor (2026).](github/tcc_skill_modelagem_ambiental_ipe/resultados/_geral/11_figuras_tcc/F_DENS_amarelo.png){width=16cm}

As presenças das duas espécies diferiram do ambiente disponível em todas as variáveis contínuas (Mann-Whitney, p < 0,05) (Tabela 3). As maiores diferenças ocorreram na altitude e na distância à hidrografia, com presenças em locais mais elevados e afastados da drenagem do que o disponível.

**Tabela 3 –** Medianas das variáveis ambientais nas presenças de *Handroanthus impetiginosus* e *H. serratifolius* e no ambiente disponível (*background*) das propriedades onde cada espécie ocorre, e proporção da variação de cada variável que ocorre entre propriedades.

| Variável | *H. impetiginosus* presença | Disponível | *H. serratifolius* presença | Disponível | Variação entre propriedades (%) |
|---|---:|---:|---:|---:|---:|
| Altitude (m) | 104 | 96 | 69 | 56 | 82,2 |
| Declividade (°) | 3,4 | 3,2 | 2,7 | 2,8 | 4,9 |
| Distância à hidrografia (m) | 324 | 256 | 346 | 247 | 22,3 |
| BIO12 (mm) | 2.226 | 2.233 | 2.349 | 2.310 | 97,3 |
| BIO17 (mm mês⁻¹) | 71,5 | 70,4 | 66,2 | 56,6 | 99,4 |

Fonte: elaborada pelo autor (2026). Todas as diferenças entre presença e disponível foram significativas (Mann-Whitney, p < 0,05).

As variáveis climáticas variaram quase exclusivamente entre propriedades (97,3% e 99,4% da variação), assim como a maior parte da variação da altitude (82,2%), enquanto a declividade (4,9%) e a distância à hidrografia (22,3%) variaram principalmente dentro das propriedades (Tabela 3).

## 5.3 Textura do solo e propriedades com as duas espécies

As duas espécies apresentaram respostas opostas à textura do solo (Figuras 4f e 5f). A densidade média de *H. impetiginosus* aumentou dos solos muito argilosos (0,15 árvore ha⁻¹) para os argilosos (0,16), os de textura média-argilosa (0,19) e os de textura média-siltosa (0,34 árvore ha⁻¹, porém em apenas 72 ha e com grande variação entre propriedades). A de *H. serratifolius*, ao contrário, foi maior nos solos muito argilosos (0,14 árvore ha⁻¹) e argilosos (0,13) e menor nas texturas média-argilosa (0,09) e média-siltosa (0,06 árvore ha⁻¹).

Nas quatro propriedades com as duas espécies, *H. impetiginosus* ocupou locais mais distantes da drenagem (mediana de 274 m contra 234 m; p = 0,014) e de menor declividade (2,6° contra 2,9°; p = 0,033), sem diferença de altitude (p = 0,86).

## 5.4 Seleção dos modelos

Para *H. impetiginosus*, a combinação altitude e BIO17 apresentou a maior pontuação entre as 57 combinações de duas ou mais variáveis (AUC LOPO = 0,822; Boyce = 0,78; omissão P10 = 9,8%). Na etapa de parâmetros, as cinco configurações lineares dessa combinação foram praticamente idênticas (AUC de 0,823 a 0,825; Boyce de 0,81 a 0,82; omissão de 9,8%) e equivalentes à de maior pontuação, que tinha quatro variáveis (altitude, declividade, BIO17 e textura; LQ; RM 0,5; AUC = 0,822). Pelos critérios de parcimônia, foi escolhido o modelo altitude + BIO17 com *features* lineares e RM 1 (AUC = 0,825; Boyce = 0,82; omissão = 9,8%; AUC dentro da propriedade = 0,53).

A grade completa de 945 modelos confirmou a escolha: nenhum modelo superou a AUC do modelo escolhido, e a maior AUC obtida (0,825) correspondeu à mesma combinação, com RM 0,5 (Tabela 4). O melhor modelo com as seis variáveis juntas teve AUC de 0,811, e o desempenho máximo diminuiu à medida que variáveis foram acrescentadas além de duas (Figura 6a). Modelos com apenas BIO17 (AUC = 0,819) ou apenas altitude (AUC = 0,820) alcançaram desempenho próximo ao do modelo escolhido, indicando que essas duas variáveis concentram quase toda a informação preditiva; contudo, o modelo apenas com BIO17 teve AUC dentro das propriedades de 0,46, inferior ao acaso, ou seja, identifica as regiões favoráveis, mas não os locais ocupados dentro delas.

**Tabela 4 –** Desempenho em propriedade nova (validação LOPO) de modelos selecionados entre os 945 avaliados para *Handroanthus impetiginosus*.

| Modelo | *Features* | RM | AUC | Boyce | Omissão P10 (%) | AUC dentro |
|---|---|---:|---:|---:|---:|---:|
| **Altitude + BIO17 (escolhido)** | **L** | **1** | **0,825** | **0,82** | **9,8** | **0,53** |
| Altitude + BIO17 | L | 0,5 | 0,825 | 0,82 | 9,8 | 0,53 |
| Altitude + declividade + BIO17 + textura | LQ | 0,5 | 0,822 | 0,86 | 9,5 | 0,51 |
| Somente altitude | LQ | 0,5 | 0,820 | 0,83 | 9,7 | 0,56 |
| Somente BIO17 | L | 4 | 0,819 | 0,90 | 10,4 | 0,46 |
| Seis variáveis (melhor configuração) | LQH | 0,5 | 0,811 | 0,81 | 9,5 | 0,50 |
| Seis variáveis (LQ, RM 2) | LQ | 2 | 0,803 | 0,78 | 10,6 | 0,48 |

Fonte: elaborada pelo autor (2026).

![**Figura 6 –** AUC em propriedade nova (validação LOPO) dos 945 modelos de (a) *Handroanthus impetiginosus* e (b) *H. serratifolius* em função do número de variáveis; a linha une o maior valor obtido com cada número de variáveis, o losango indica o modelo escolhido e a linha tracejada, o desempenho ao acaso (AUC = 0,5). Fonte: elaborada pelo autor (2026).](github/tcc_skill_modelagem_ambiental_ipe/resultados/_geral/11_figuras_tcc/F_GRADE_NVARS.png){width=16cm}

Considerando todos os 945 modelos, a inclusão de BIO17 elevou a AUC média em 0,10 e a de altitude em 0,07, enquanto BIO12 acrescentou 0,03 e a textura do solo, a declividade e a distância à hidrografia praticamente não alteraram a AUC média (de −0,006 a 0,002) (Figura 7).

![**Figura 7 –** Diferença entre a AUC média (validação LOPO) dos modelos que contêm e a dos modelos que não contêm cada variável, entre os 945 modelos avaliados para *Handroanthus impetiginosus* e *H. serratifolius*. Fonte: elaborada pelo autor (2026).](github/tcc_skill_modelagem_ambiental_ipe/resultados/_geral/11_figuras_tcc/F_GRADE_VARS.png){width=15cm}

No teste Jackknife do modelo escolhido, BIO17 isolada produziu ganho de treino de 0,79, contra 0,21 da altitude, e o modelo com as duas variáveis atingiu 0,87; sem BIO17, o ganho caiu para 0,21 (Figura 8a). No modelo com as seis variáveis (ganho de 0,95), os maiores ganhos isolados foram os de BIO17 (0,79) e altitude (0,73), seguidos de BIO12 (0,32) e textura (0,18), enquanto declividade e distância à hidrografia quase não produziram ganho (0,004 e 0,03). A retirada de BIO17 foi a que mais reduziu o ganho do modelo completo (de 0,95 para 0,79), seguida da de BIO12 (0,91); a retirada das demais variáveis praticamente não o alterou (Figura 8b).

![**Figura 8 –** Teste Jackknife do ganho de treino regularizado para *Handroanthus impetiginosus*: (a) modelo escolhido (altitude e BIO17; L; RM 1) e (b) modelo com as seis variáveis (LQ; RM 2). Fonte: elaborada pelo autor (2026).](github/tcc_skill_modelagem_ambiental_ipe/resultados/_geral/11_figuras_tcc/F_JK_roxo.png){width=16cm}

A adequabilidade estimada aumentou com a altitude e com BIO17, de forma mais acentuada acima de 65 mm mês⁻¹ (Figura 9). A maior parte das presenças ocorreu acima de 67 mm mês⁻¹ de BIO17 e entre 90 e 120 m de altitude, faixas menos frequentes no ambiente disponível (Figura 9).

![**Figura 9 –** Curvas de resposta do modelo escolhido para *Handroanthus impetiginosus*: adequabilidade (saída cloglog) em função de (a) altitude e (b) BIO17, com a outra variável fixada em seu valor médio; abaixo do eixo, a distribuição dos valores no ambiente disponível (cinza) e nas presenças (violeta). Fonte: elaborada pelo autor (2026).](github/tcc_skill_modelagem_ambiental_ipe/resultados/_geral/11_figuras_tcc/F_RESP_roxo.png){width=12cm}

Para *H. serratifolius*, o desempenho foi inferior. Entre as 57 combinações avaliadas com LQ e RM 2, as de maior pontuação foram declividade + distância à hidrografia (AUC LOPO = 0,567), distância à hidrografia + BIO12 + textura (0,567) e declividade + distância à hidrografia + textura (0,607). Na etapa de parâmetros, a combinação distância à hidrografia, BIO12 e textura com *features* LQH alcançou AUC de 0,709 a 0,714 entre RM 0,5 e 3, bem acima das configurações das outras duas combinações (máximo de 0,613). Como essas quatro configurações diferiram em menos de 0,005 de AUC, adotou-se o RM 1, e o modelo escolhido foi distância à hidrografia + BIO12 + textura, LQH, RM 1 (AUC = 0,714; Boyce = 0,68; omissão P10 = 11,0%; AUC dentro da propriedade = 0,53).

A grade completa também confirmou a escolha para *H. serratifolius* (Tabela 5). A maior AUC (0,719; declividade, distância à hidrografia, BIO12 e textura; LQH; RM 1) superou a do modelo escolhido em apenas 0,005, com uma variável a mais, diferença inferior ao critério de equivalência. Os 37 modelos com AUC de pelo menos 0,70 tinham *features* LQH e incluíam BIO12, e nenhum incluía BIO17. O modelo apenas com BIO12 alcançou AUC de 0,710, mas com AUC dentro das propriedades de 0,49, comportamento semelhante ao do modelo apenas com BIO17 de *H. impetiginosus*. O desempenho máximo foi praticamente constante de uma a quatro variáveis e caiu com cinco (0,657) e seis variáveis (0,610), e o modelo com as seis variáveis na configuração LQ e RM 2 teve AUC de 0,447, inferior ao acaso (Figura 6b). Considerando os 945 modelos, a inclusão da textura do solo elevou a AUC média em 0,039, a de BIO12 em 0,031 e as de declividade e distância à hidrografia em 0,013 e 0,011, enquanto a altitude (−0,017) e, principalmente, BIO17 (−0,096) reduziram o desempenho médio (Figura 7). Assim, as variáveis que mais contribuíram para cada espécie foram distintas: BIO17 e altitude para *H. impetiginosus*, e textura do solo e BIO12 para *H. serratifolius*.

**Tabela 5 –** Desempenho em propriedade nova (validação LOPO) de modelos selecionados entre os 945 avaliados para *Handroanthus serratifolius*.

| Modelo | *Features* | RM | AUC | Boyce | Omissão P10 (%) | AUC dentro |
|---|---|---:|---:|---:|---:|---:|
| **Distância + BIO12 + textura (escolhido)** | **LQH** | **1** | **0,714** | **0,68** | **11,0** | **0,53** |
| Distância + BIO12 + textura | LQH | 2 | 0,714 | 0,64 | 10,2 | 0,53 |
| Declividade + distância + BIO12 + textura | LQH | 1 | 0,719 | 0,71 | 10,6 | 0,54 |
| Declividade + distância + BIO12 | LQH | 1 | 0,718 | 0,70 | 10,5 | 0,54 |
| Somente BIO12 | LQH | 2 | 0,710 | 0,81 | 10,7 | 0,49 |
| Seis variáveis (melhor configuração) | LQH | 4 | 0,610 | 0,95 | 13,3 | 0,55 |
| Seis variáveis (LQ, RM 2) | LQ | 2 | 0,447 | 0,21 | 12,2 | 0,54 |

Fonte: elaborada pelo autor (2026).

No teste Jackknife do modelo escolhido para *H. serratifolius*, BIO12 isolada produziu ganho de treino de 0,49, semelhante ao do modelo com as três variáveis (0,48), enquanto a textura do solo (0,11) e a distância à hidrografia (0,06) produziram ganhos pequenos; sem BIO12, o ganho caiu para 0,14, e a retirada das outras duas variáveis praticamente não o alterou (Figura 10a). No modelo com as seis variáveis, o ganho total foi de apenas 0,25; os maiores ganhos isolados foram os da textura (0,11) e de BIO12 (0,09), e as retiradas de BIO12 (0,15) e da altitude (0,17) foram as que mais reduziram o ganho (Figura 10b).

![**Figura 10 –** Teste Jackknife do ganho de treino regularizado para *Handroanthus serratifolius*: (a) modelo escolhido (distância à hidrografia, BIO12 e textura do solo; LQH; RM 1) e (b) modelo com as seis variáveis (LQ; RM 2). Fonte: elaborada pelo autor (2026).](github/tcc_skill_modelagem_ambiental_ipe/resultados/_geral/11_figuras_tcc/F_JK_amarelo.png){width=16cm}

A adequabilidade estimada para *H. serratifolius* aumentou de forma acentuada nos primeiros 80 m de distância da hidrografia e, depois, lentamente (Figura 11a), padrão coerente com a menor densidade observada na classe de 0 a 60 m (Figura 5c). Para BIO12, a resposta foi bimodal, com máximos próximos de 1.970 e de 2.400 mm ano⁻¹ e mínimo entre 2.150 e 2.250 mm ano⁻¹ (Figura 11b). Esses intervalos correspondem a grupos de propriedades: o primeiro máximo, às propriedades do grupo central (P05, P09, P11, P16 e P19; mediana de 1.942 a 1.970 mm ano⁻¹); o mínimo, às propriedades do sul do grupo oeste (P03, P04, P06, P12 a P14, P17 e P18; 2.208 a 2.243 mm ano⁻¹), onde a espécie não foi registrada; e o segundo máximo, às propriedades do norte do grupo oeste (P01, P02, P07, P08, P10 e P15; 2.326 a 2.462 mm ano⁻¹), que reúnem as maiores abundâncias. Entre as texturas, a adequabilidade foi menor nos solos de textura média-argilosa e semelhante nas demais (Figura 11c).

![**Figura 11 –** Curvas de resposta do modelo escolhido para *Handroanthus serratifolius*: adequabilidade (saída cloglog) em função de (a) distância à hidrografia, (b) BIO12 e (c) textura do solo, com as demais variáveis fixadas em seu valor médio (ou na classe mais frequente); abaixo do eixo, a distribuição dos valores no ambiente disponível (cinza) e nas presenças (dourado). Fonte: elaborada pelo autor (2026).](github/tcc_skill_modelagem_ambiental_ipe/resultados/_geral/11_figuras_tcc/F_RESP_amarelo.png){width=16cm}

Para as duas espécies, a AUC dentro das propriedades ficou próxima de 0,5 (0,51 a 0,54), indicando que os modelos distinguem propriedades e regiões favoráveis, mas pouco os locais ocupados dentro de cada propriedade. A AUC também variou com o desenho de validação: para o modelo de *H. impetiginosus*, foi de 0,822 na validação LOPO e de 0,851 na divisão aleatória 50/50, com Boyce de 0,86 e 0,98, respectivamente. A troca do *background* por sorteios de 5.000 ou 20.000 pontos não alterou a AUC (0,822 a 0,823).

## 5.5 Teste externo

No teste externo de *H. impetiginosus*, realizado com o modelo altitude + BIO17 (L, RM 1) nas três propriedades reservadas (1.890 presenças), a AUC foi de 0,879, superior às obtidas no treino e na validação cruzada, e o índice de Boyce foi de 0,63 (Tabela 6; Figura 12). Entretanto, todas as presenças externas ficaram abaixo do limiar P10 definido no treino (omissão de 100%), embora acima do limiar MTP (omissão de 0%). Dentro de cada propriedade reservada, a AUC foi de 0,61 (P30), 0,57 (P29) e 0,53 (P28), e a adequabilidade média das presenças foi apenas ligeiramente superior à do *background* da mesma propriedade.

**Tabela 6 –** Desempenho do modelo escolhido para *Handroanthus impetiginosus* (altitude e BIO17; L; RM 1) no treino, na validação cruzada e no teste externo.

| Conjunto | Presenças | *Background* | AUC | Boyce | Omissão P10 (%) | Omissão MTP (%) |
|---|---:|---:|---:|---:|---:|---:|
| Treino (27 propriedades) | 3.248 | 10.000 | 0,849 | 0,90 | 10,0 | 0,0 |
| Validação cruzada (média de 3 *folds*) | – | – | 0,849 | 0,77 | 12,7 | 1,9 |
| Teste externo (P28, P29 e P30) | 1.890 | 3.050 | 0,879 | 0,63 | 100,0 | 0,0 |

Fonte: elaborada pelo autor (2026).

![**Figura 12 –** Curvas ROC do modelo escolhido para *Handroanthus impetiginosus* no treino, na validação cruzada e no teste externo; a diagonal representa o desempenho ao acaso. Fonte: elaborada pelo autor (2026).](github/tcc_skill_modelagem_ambiental_ipe/resultados/_geral/11_figuras_tcc/F_ROC_roxo.png){width=9cm}

No mapa de adequabilidade (Figura 13), os maiores valores concentraram-se nas propriedades do sul do grupo oeste (P03, P04, P06, P12, P13, P14, P17 e P18), que reúnem a maior parte das presenças de treino. As propriedades do norte desse grupo, onde a espécie ocorre em menor densidade, e as propriedades reservadas (P28 a P30) receberam valores baixos a intermediários, e as dos grupos central e leste, onde a espécie não foi registrada, os menores valores.

![**Figura 13 –** Adequabilidade estimada (saída cloglog) para *Handroanthus impetiginosus* nas UPAs das propriedades dos grupos (a) oeste, (b) central e (c) leste. Fonte: elaborada pelo autor (2026).](github/tcc_skill_modelagem_ambiental_ipe/resultados/_geral/11_figuras_tcc/F_MAPA_roxo.png){width=16cm}

No teste externo de *H. serratifolius*, realizado com o modelo distância à hidrografia + BIO12 + textura (LQH, RM 1) nas quatro propriedades reservadas com a espécie (334 presenças), a AUC foi de 0,691, inferior às do treino (0,778) e da validação cruzada (0,752), e o índice de Boyce foi de 0,79 (Tabela 7; Figura 14). Ao contrário do observado para *H. impetiginosus*, apenas uma presença externa ficou abaixo do limiar P10 (omissão de 0,3%), e nenhuma abaixo do limiar MTP. Dentro de cada propriedade reservada, a AUC foi de 0,77 (P34), 0,58 (P32), 0,57 (P31) e 0,56 (P33), e a adequabilidade média das presenças (0,67 a 0,72) foi pouco superior à do *background* da mesma propriedade (0,64 a 0,69).

**Tabela 7 –** Desempenho do modelo escolhido para *Handroanthus serratifolius* (distância à hidrografia, BIO12 e textura do solo; LQH; RM 1) no treino, na validação cruzada e no teste externo.

| Conjunto | Presenças | *Background* | AUC | Boyce | Omissão P10 (%) | Omissão MTP (%) |
|---|---:|---:|---:|---:|---:|---:|
| Treino (27 propriedades) | 5.432 | 10.000 | 0,778 | 0,98 | 10,0 | 0,0 |
| Validação cruzada (média de 3 *folds*) | – | – | 0,752 | 0,89 | 11,5 | 0,0 |
| Teste externo (P31 a P34) | 334 | 3.050 | 0,691 | 0,79 | 0,3 | 0,0 |

Fonte: elaborada pelo autor (2026).

![**Figura 14 –** Curvas ROC do modelo escolhido para *Handroanthus serratifolius* no treino, na validação cruzada e no teste externo; a diagonal representa o desempenho ao acaso. Fonte: elaborada pelo autor (2026).](github/tcc_skill_modelagem_ambiental_ipe/resultados/_geral/11_figuras_tcc/F_ROC_amarelo.png){width=9cm}

No mapa de adequabilidade de *H. serratifolius* (Figura 15), os maiores valores ocorreram nas propriedades do norte do grupo oeste (P01, P02, P07, P08, P10 e P15), do grupo central e nas propriedades reservadas do grupo leste (P31 a P34), e os menores, nas propriedades do sul do grupo oeste e nas reservadas P28 a P30, onde a espécie não foi registrada. As demais propriedades do grupo leste, com menores densidades da espécie, receberam valores intermediários. Assim, a distribuição da adequabilidade das duas espécies foi praticamente complementar (Figuras 13 e 15).

![**Figura 15 –** Adequabilidade estimada (saída cloglog) para *Handroanthus serratifolius* nas UPAs das propriedades dos grupos (a) oeste, (b) central e (c) leste. Fonte: elaborada pelo autor (2026).](github/tcc_skill_modelagem_ambiental_ipe/resultados/_geral/11_figuras_tcc/F_MAPA_amarelo.png){width=16cm}

# 6 DISCUSSÃO

## 6.1 Drenagem, relevo e solo: a escala local

O padrão mais consistente nas duas espécies foi o aumento da densidade com a distância à hidrografia, indicando que os ipês evitam baixios e áreas próximas à drenagem e se concentram em terra firme bem drenada. Esse resultado é coerente com a indicação de *H. impetiginosus* para solos com boa drenagem (Camillo; Salomão, 2018) e com estudos que identificaram a hidrologia local como filtro da composição de florestas de terra firme na Amazônia (Schietti *et al.*, 2014; Marca-Zevallos *et al.*, 2022). Em floresta manejada no Amazonas, espécies comerciais também apresentaram maior concentração em posições mais elevadas e afastadas dos cursos d'água (Miron *et al.*, 2021), e, no Vale do Jari, a abundância das espécies arbóreas variou com as classes de distância ao rio e de altitude (Ferreira, 2009). Como a distância à hidrografia e a declividade variaram principalmente dentro das propriedades, essas são as variáveis que efetivamente descrevem a escala local da paisagem.

As respostas opostas à textura do solo constituem o principal indício de diferenciação ecológica entre as espécies: *H. impetiginosus* associou-se a texturas médias, de drenagem interna mais rápida, o que concorda com sua adaptação a solos de textura arenosa e bem drenados (Camillo; Salomão, 2018), e *H. serratifolius* a solos muito argilosos, típicos de latossolos de platô. Como *H. serratifolius* é classificado como indiferente em relação a solos mesotróficos e ocorre em solos de pH variado (Carvalho, 2014), sua associação com solos muito argilosos deve refletir as condições das áreas inventariadas, e não uma exigência da espécie. Essa diferença, somada à quase segregação das espécies entre propriedades e às diferenças de drenagem e declividade nas propriedades onde coexistem, é compatível com as respostas fisiológicas distintas das duas espécies ao déficit hídrico (Sobreiro *et al.*, 2021) e com a ocorrência diferenciada observada por Ferreira (2009), em que *T. serratifolia* esteve presente em todos os sítios e *T. impetiginosa* restrita às áreas planas. Em escala continental, atributos do solo também foram determinantes para *H. serratifolius* (Elera-Gonzales *et al.*, 2026), embora com variável e escala diferentes das deste estudo.

## 6.2 Clima: a escala regional e a hipótese da dispersão

As variáveis climáticas diferenciaram principalmente propriedades, e não locais dentro delas, o que explica por que BIO17 contribuiu para prever propriedades novas no modelo de *H. impetiginosus*, enquanto a AUC dentro das propriedades permaneceu próxima de 0,5. A seleção da BIO17 é ecologicamente plausível, pois floração, frutificação e dispersão anemocórica dos ipês ocorrem na estação seca, cujas condições atmosféricas favorecem a elevação e o transporte das sementes aladas (Wright *et al.*, 2008), e a germinação depende do retorno das chuvas. Contudo, na escala deste estudo, a variável distingue sobretudo regiões, de modo que não é possível isolar esse mecanismo do efeito da localização geográfica das propriedades com a espécie. Além disso, a amplitude de BIO17 nas áreas (44 a 75 mm mês⁻¹) corresponde a estações secas pouco severas, e *H. impetiginosus* foi mais denso nas áreas de estação seca menos intensa, o que não permite afirmar que a seca favoreça a espécie. Em escalas continental e nacional, clima e solo também atuaram conjuntamente na distribuição dos ipês (Borba *et al.*, 2026; Elera-Gonzales *et al.*, 2026).

O mesmo raciocínio se aplica a BIO12 no modelo de *H. serratifolius*. A resposta bimodal não indica duas faixas ótimas de precipitação anual, mas sim que a variável separa os grupos de propriedades com a espécie das propriedades do sul do grupo oeste, onde ela não foi registrada e onde ocorre *H. impetiginosus*. Por isso, BIO12 isolada alcançou AUC semelhante à do modelo escolhido, mas não distinguiu locais dentro das propriedades (AUC dentro = 0,49), e a contribuição das variáveis climáticas para as duas espécies deve ser interpretada como efeito da região, e não como exigência climática comprovada.

## 6.3 Desempenho e transferência dos modelos

A diferença de desempenho entre as espécies – AUC próxima de 0,82 para *H. impetiginosus* e de 0,71 para *H. serratifolius* – supera o limiar de 0,75 apenas para o ipê-roxo (Ferreira, 2009). O desempenho inferior do ipê-amarelo pode estar relacionado à sua ocorrência em maior número de propriedades e de ambientes, coerente com seu caráter mais generalista (Ferreira, 2009). O fato de o modelo com as seis variáveis ter sido inferior a modelos com duas a quatro variáveis, de forma acentuada para *H. serratifolius* (AUC máxima de 0,610 contra 0,719), reforça que modelos mais complexos generalizam pior (Warren; Seifert, 2011; Radosavljevic; Anderson, 2014).

A maior AUC obtida na divisão aleatória em relação à validação por propriedade confirma que partições aleatórias de registros espacialmente próximos superestimam o desempenho (Roberts *et al.*, 2017), e justifica o uso da validação LOPO como critério de escolha. No teste externo de *H. impetiginosus*, a AUC elevada indica que o modelo ordenou corretamente presenças e *background* das propriedades reservadas; a omissão de 100% no limiar P10, porém, mostra que essas propriedades receberam notas de adequabilidade inferiores às das áreas de treino. Isso indica que a ordenação relativa foi transferida, mas não o nível absoluto de adequabilidade, o que reforça a recomendação de interpretar as predições como valores relativos, condicionados ao domínio ambiental analisado (Owens *et al.*, 2013; Elith; Leathwick, 2009), resultado semelhante às dificuldades de transferência relatadas por Ferreira (2009).

Para *H. serratifolius*, o comportamento foi o oposto: a AUC externa (0,691) foi menor que a do treino, mas praticamente todas as presenças externas ficaram acima do limiar P10, e o índice de Boyce (0,79) indicou que a frequência de presenças cresceu com a adequabilidade. As propriedades reservadas dessa espécie, situadas no grupo leste, receberam notas elevadas em toda a sua área, de modo que o modelo identificou corretamente a região favorável, mas pouco distinguiu os locais ocupados dentro dela. Em conjunto, os dois testes externos mostram que os modelos transferiram para propriedades novas a informação regional, isto é, quais áreas são favoráveis a cada espécie, mas não a variação local dentro das propriedades, o que é coerente com a AUC dentro das propriedades próxima de 0,5 em todas as etapas.

## 6.4 Limitações

A investigação foi restrita ao conjunto de propriedades efetivamente inventariadas, sem pressupor que representem toda a diversidade ambiental do Pará ou a distribuição geográfica completa das espécies; a favorabilidade estimada não equivale à confirmação da presença de indivíduos (Peterson; Soberón, 2012). A capacidade preditiva em propriedades independentes depende da representatividade ambiental entre as áreas de calibração e de validação, e a quase segregação das espécies entre propriedades impede separar totalmente o efeito ambiental do efeito da região de cada inventário. Não foram incluídas variáveis de luz, histórico de exploração ou altura acima da drenagem, e as variáveis climáticas, de resolução quilométrica, não descrevem variações locais.

# 7 CONSIDERAÇÕES FINAIS

Quanto à primeira questão da pesquisa, a ocorrência de *H. impetiginosus* e de *H. serratifolius* esteve associada à heterogeneidade ambiental das áreas manejadas, e as associações diferiram entre as espécies. Na escala local, as duas espécies foram menos densas nas áreas próximas à drenagem, o que indica preferência por terra firme bem drenada, e responderam de forma oposta à textura do solo, com o ipê-roxo associado a texturas médias e o ipê-amarelo a solos muito argilosos. Na escala regional, a precipitação do trimestre mais seco e a altitude foram as variáveis mais informativas para o ipê-roxo, e a precipitação anual e a textura do solo, para o ipê-amarelo. Como as variáveis climáticas variaram quase somente entre propriedades e as espécies ocorreram em propriedades quase distintas, esses resultados indicam principalmente as regiões em que cada espécie ocorre, e não exigências climáticas comprovadas.

Quanto à segunda questão, as associações permitiram predições apenas parcialmente consistentes em propriedades independentes. Os modelos ordenaram as propriedades e regiões segundo sua adequabilidade e mantiveram desempenho próximo ao da calibração no teste externo (AUC de 0,879 para o ipê-roxo e de 0,691 para o ipê-amarelo), mas não distinguiram os locais ocupados dentro de cada propriedade, e, no caso do ipê-roxo, o nível absoluto de adequabilidade não se manteve nas propriedades novas. A hipótese de que as condições dos locais de presença diferem das disponíveis foi confirmada sobretudo entre propriedades, e a de que as associações variam entre as espécies foi confirmada.

Para o manejo florestal, os mapas de adequabilidade podem ser usados como indicação relativa das áreas mais favoráveis a cada espécie, a ser confirmada pelo inventário, e não como estimativa da presença de indivíduos em locais específicos. Recomenda-se, em estudos futuros, ampliar o número de propriedades e de regiões, de modo a separar o efeito do clima do efeito da localização, e incluir variáveis de escala local, como a altura acima da drenagem, a abertura do dossel e o histórico de exploração, que podem explicar a distribuição dos indivíduos dentro das propriedades.

# REFERÊNCIAS

ALLOUCHE, O.; TSOAR, A.; KADMON, R. Assessing the accuracy of species distribution models: prevalence, kappa and the true skill statistic (TSS). **Journal of Applied Ecology**, v. 43, n. 6, p. 1223-1232, 2006. Disponível em: https://doi.org/10.1111/j.1365-2664.2006.01214.x. Acesso em: 19 out. 2026.

AMARAL, P.; VERÍSSIMO, A.; BARRETO, P.; VIDAL, E. **Floresta para sempre**: um manual para a produção de madeira na Amazônia. Belém: Imazon, 1998.

ASNER, G. P. et al. Selective logging in the Brazilian Amazon. **Science**, v. 310, n. 5747, p. 480-482, 2005. Disponível em: https://doi.org/10.1126/science.1118051. Acesso em: 19 out. 2026.

BARBET-MASSIN, M. et al. Selecting pseudo-absences for species distribution models: how, where and how many? **Methods in Ecology and Evolution**, v. 3, n. 2, p. 327-338, 2012. Disponível em: https://doi.org/10.1111/j.2041-210X.2011.00172.x. Acesso em: 26 nov. 2026.

BARVE, N. et al. The crucial role of the accessible area in ecological niche modeling and species distribution modeling. **Ecological Modelling**, v. 222, n. 11, p. 1810-1819, 2011. Disponível em: https://doi.org/10.1016/j.ecolmodel.2011.02.011. Acesso em: 19 out. 2026.

BEVEN, K. J.; KIRKBY, M. J. A physically based, variable contributing area model of basin hydrology. **Hydrological Sciences Bulletin**, v. 24, n. 1, p. 43-69, 1979. Disponível em: https://doi.org/10.1080/02626667909491834. Acesso em: 19 out. 2026.

BORBA, F. de C. et al. A modeling framework to assess climate vulnerability and future distributions of tropical tree species: a case study on Brazilian ipês. **Bosque**, v. 47, e4709, 2026. Disponível em: https://doi.org/10.4206/Bosque.e4709. Acesso em: 19 nov. 2026.

BRASIL. Instituto Brasileiro do Meio Ambiente e dos Recursos Naturais Renováveis. **Instrução Normativa Ibama nº 28, de 11 de dezembro de 2024**. Estabelece procedimentos relativos ao manejo florestal de espécies dos gêneros *Handroanthus*, *Tabebuia*, *Dipteryx* e *Cedrela* listadas na CITES. Brasília, DF: Ibama, 2024. Disponível em: https://www.ibama.gov.br/component/legislacao/?legislacao=139446&view=legislacao. Acesso em: 19 out. 2026.

BRASIL. Instituto Brasileiro do Meio Ambiente e dos Recursos Naturais Renováveis. **Instrução Normativa Ibama nº 5, de 4 de abril de 2025**. Altera a Instrução Normativa nº 28, de 11 de dezembro de 2024. Brasília, DF: Ibama, 2025. Disponível em: https://www.ibama.gov.br/component/legislacao/?legislacao=139484&view=legislacao. Acesso em: 19 out. 2026.

BRASIL. Instituto Brasileiro do Meio Ambiente e dos Recursos Naturais Renováveis. **Instrução Normativa Ibama nº 5, de 3 de fevereiro de 2026**. Altera a Instrução Normativa nº 28, de 11 de dezembro de 2024. Brasília, DF: Ibama, 2026. Disponível em: https://www.ibama.gov.br/component/legislacao/?legislacao=139559&view=legislacao. Acesso em: 19 out. 2026.

CAMILLO, J.; SALOMÃO, A. N. *Handroanthus impetiginosus*: ipê-roxo. In: VIEIRA, R. F.; CAMILLO, J.; CORADIN, L. (ed.). **Espécies nativas da flora brasileira de valor econômico atual ou potencial**: plantas para o futuro: Região Centro-Oeste. Brasília, DF: Ministério do Meio Ambiente, 2018. p. 984-991. Disponível em: https://www.alice.cnptia.embrapa.br/alice/handle/doc/1073569. Acesso em: 19 out. 2026.

CARVALHO, P. E. R. Pau-d'arco-amarelo: *Handroanthus serratifolius*. In: CARVALHO, P. E. R. **Espécies arbóreas brasileiras**. Brasília, DF: Embrapa Informação Tecnológica; Colombo: Embrapa Florestas, 2014. v. 5, p. 419-429. Disponível em: https://www.alice.cnptia.embrapa.br/alice/handle/doc/1140571. Acesso em: 19 out. 2026.

CHAZDON, R. L.; FETCHER, N. Photosynthetic light environments in a lowland tropical rain forest in Costa Rica. **Journal of Ecology**, v. 72, n. 2, p. 553-564, 1984. Disponível em: https://doi.org/10.2307/2260066. Acesso em: 19 out. 2026.

CLARK, D. B.; PALMER, M. W.; CLARK, D. A. Edaphic factors and the landscape-scale distributions of tropical rain forest trees. **Ecology**, v. 80, n. 8, p. 2662-2675, 1999.

CNCFLORA. *Handroanthus impetiginosus*. In: **Lista Vermelha da flora brasileira**. Rio de Janeiro: Centro Nacional de Conservação da Flora, 2012. Disponível em: https://proflora.jbrj.gov.br/html/Handroanthus%20impetiginosus_2012.html. Acesso em: 26 nov. 2026.

CNCFLORA. *Handroanthus serratifolius*. In: **Lista Vermelha da flora brasileira**. Rio de Janeiro: Centro Nacional de Conservação da Flora, 2019. Disponível em: https://proflora.jbrj.gov.br/html/Handroanthus%20serratifolius_2019.html. Acesso em: 26 nov. 2026.

COLLEVATTI, R. G. et al. A genome-wide scan shows evidence for local adaptation in a widespread keystone Neotropical forest tree. **Heredity**, v. 123, p. 117-137, 2019. Disponível em: https://doi.org/10.1038/s41437-019-0188-0. Acesso em: 19 out. 2026.

COSTA, F. R. C.; MAGNUSSON, W. E.; LUIZÃO, R. C. Mesoscale distribution patterns of Amazonian understorey herbs in relation to topography, soil and watersheds. **Journal of Ecology**, v. 93, n. 5, p. 863-878, 2005.

DENSLOW, J. S. Tropical rainforest gaps and tree species diversity. **Annual Review of Ecology and Systematics**, v. 18, p. 431-451, 1987.

DI COLA, V. et al. ecospat: an R package to support spatial analyses and modeling of species niches and distributions. **Ecography**, v. 40, n. 6, p. 774-787, 2017. Disponível em: https://doi.org/10.1111/ecog.02671. Acesso em: 26 nov. 2026.

DORMANN, C. F. et al. Collinearity: a review of methods to deal with it and a simulation study evaluating their performance. **Ecography**, v. 36, n. 1, p. 27-46, 2013. Disponível em: https://doi.org/10.1111/j.1600-0587.2012.07348.x. Acesso em: 19 out. 2026.

DUNNINGTON, D. **ggspatial**: spatial data framework for ggplot2. Versão 1.1.11. [S. l.]: CRAN, 2026. Disponível em: https://CRAN.R-project.org/package=ggspatial. Acesso em: 26 nov. 2026.

ELERA-GONZALES, D. G. et al. Potential geographic distribution of *Handroanthus serratifolius* in tropical America. **Flora**, v. 336, art. 152926, 2026. Disponível em: https://doi.org/10.1016/j.flora.2026.152926. Acesso em: 19 out. 2026.

ELITH, J. et al. Novel methods improve prediction of species' distributions from occurrence data. **Ecography**, v. 29, n. 2, p. 129-151, 2006. Disponível em: https://doi.org/10.1111/j.2006.0906-7590.04596.x. Acesso em: 26 nov. 2026.

ELITH, J. et al. A statistical explanation of MaxEnt for ecologists. **Diversity and Distributions**, v. 17, n. 1, p. 43-57, 2011. Disponível em: https://doi.org/10.1111/j.1472-4642.2010.00725.x. Acesso em: 19 out. 2026.

ELITH, J.; LEATHWICK, J. R. Species distribution models: ecological explanation and prediction across space and time. **Annual Review of Ecology, Evolution, and Systematics**, v. 40, p. 677-697, 2009.

ESRI. **World Imagery**. Redlands: Esri, 2026. Disponível em: https://www.arcgis.com/home/item.html?id=10df2279f9684e4a9f6a7f08febac2a9. Acesso em: 26 nov. 2026.

FERREIRA, G. C. **Modelagem ambiental de espécies de árvores no Vale do Jari, Monte Dourado, Pará usando dados de inventário florestal**. 2009. 181 f. Tese (Doutorado em Botânica) – Escola Nacional de Botânica Tropical, Instituto de Pesquisas Jardim Botânico do Rio de Janeiro, Rio de Janeiro, 2009.

FICK, S. E.; HIJMANS, R. J. WorldClim 2: new 1-km spatial resolution climate surfaces for global land areas. **International Journal of Climatology**, v. 37, n. 12, p. 4302-4315, 2017. Disponível em: https://doi.org/10.1002/joc.5086. Acesso em: 19 out. 2026.

FRIEDMAN, J.; HASTIE, T.; TIBSHIRANI, R. Regularization paths for generalized linear models via coordinate descent. **Journal of Statistical Software**, v. 33, n. 1, p. 1-22, 2010. Disponível em: https://doi.org/10.18637/jss.v033.i01. Acesso em: 26 nov. 2026.

GAIA, J. A. S. et al. Modelagem e distribuição potencial de espécies arbóreas relevantes para a dinâmica sociocultural e ecológica do Parque Nacional de Sete Cidades, Piauí, Brasil. **Sociedade & Natureza**, v. 32, 2020. Disponível em: https://doi.org/10.14393/SN-v32-2020-51103. Acesso em: 19 nov. 2026.

GDAL/OGR CONTRIBUTORS. **GDAL/OGR geospatial data abstraction software library**. Versão 3.13.0. Open Source Geospatial Foundation, 2026. Disponível em: https://gdal.org. Acesso em: 26 nov. 2026.

GIRAUD, T. **maptiles**: download and display map tiles. Versão 0.13.0. [S. l.]: CRAN, 2026. Disponível em: https://CRAN.R-project.org/package=maptiles. Acesso em: 26 nov. 2026.

GORELICK, N. et al. Google Earth Engine: planetary-scale geospatial analysis for everyone. **Remote Sensing of Environment**, v. 202, p. 18-27, 2017. Disponível em: https://doi.org/10.1016/j.rse.2017.06.031. Acesso em: 26 nov. 2026.

GROSE, S. O.; OLMSTEAD, R. G. Taxonomic revisions in the polyphyletic genus *Tabebuia* s. l. (Bignoniaceae). **Systematic Botany**, v. 32, n. 3, p. 660-670, 2007. Disponível em: https://doi.org/10.1600/036364407782250652. Acesso em: 19 out. 2026.

GUILLERA-ARROITA, G. et al. Is my species distribution model fit for purpose? Matching data and models to applications. **Global Ecology and Biogeography**, v. 24, n. 3, p. 276-292, 2015. Disponível em: https://doi.org/10.1111/geb.12268. Acesso em: 19 out. 2026.

GUISAN, A.; THUILLER, W. Predicting species distribution: offering more than simple habitat models. **Ecology Letters**, v. 8, n. 9, p. 993-1009, 2005.

GUISAN, A.; ZIMMERMANN, N. E. Predictive habitat distribution models in ecology. **Ecological Modelling**, v. 135, n. 2-3, p. 147-186, 2000.

HARMS, K. E.; CONDIT, R.; HUBBELL, S. P.; FOSTER, R. B. Habitat associations of trees and shrubs in a 50-ha neotropical forest plot. **Journal of Ecology**, v. 89, n. 6, p. 947-959, 2001.

HENGL, T. et al. SoilGrids250m: global gridded soil information based on machine learning. **PLOS ONE**, v. 12, n. 2, e0169748, 2017. Disponível em: https://doi.org/10.1371/journal.pone.0169748. Acesso em: 19 out. 2026.

HIJMANS, R. J. **terra**: spatial data analysis. R package version 1.9-60. 2026. Disponível em: https://CRAN.R-project.org/package=terra. Acesso em: 26 nov. 2026.

HIRZEL, A. H. et al. Evaluating the ability of habitat suitability models to predict species presences. **Ecological Modelling**, v. 199, n. 2, p. 142-152, 2006. Disponível em: https://doi.org/10.1016/j.ecolmodel.2006.05.017. Acesso em: 19 nov. 2026.

HORN, B. K. P. Hill shading and the reflectance map. **Proceedings of the IEEE**, v. 69, n. 1, p. 14-47, 1981. Disponível em: https://doi.org/10.1109/PROC.1981.11918. Acesso em: 26 nov. 2026.

INSTITUTO BRASILEIRO DE GEOGRAFIA E ESTATÍSTICA (IBGE). **API de malhas territoriais**: versão 3. Rio de Janeiro: IBGE, 2024. Disponível em: https://servicodados.ibge.gov.br/api/docs/malhas?versao=3. Acesso em: 26 nov. 2026.

INTERNATIONAL TROPICAL TIMBER ORGANIZATION (ITTO). **Tropical Timber Market Report**. Yokohama: ITTO, 2026. Disponível em: https://www.itto.int/market_information_service/. Acesso em: 19 out. 2026.

JOHN, R. et al. Soil nutrients influence spatial distributions of tropical tree species. **Proceedings of the National Academy of Sciences**, v. 104, n. 3, p. 864-869, 2007. Disponível em: https://doi.org/10.1073/pnas.0604666104. Acesso em: 19 out. 2026.

KARGER, D. N. et al. Climatologies at high resolution for the earth's land surface areas. **Scientific Data**, v. 4, art. 170122, 2017. Disponível em: https://doi.org/10.1038/sdata.2017.122. Acesso em: 26 nov. 2026.

LAIPELT, L. et al. ANADEM: a digital terrain model for South America. **Remote Sensing**, v. 16, n. 13, art. 2321, 2024. Disponível em: https://doi.org/10.3390/rs16132321. Acesso em: 26 nov. 2026.

LOBO, J. M.; JIMÉNEZ-VALVERDE, A.; REAL, R. AUC: a misleading measure of the performance of predictive distribution models. **Global Ecology and Biogeography**, v. 17, n. 2, p. 145-151, 2008. Disponível em: https://doi.org/10.1111/j.1466-8238.2007.00358.x. Acesso em: 19 out. 2026.

MAPBIOMAS. **MapBiomas Solo Coleção 3**: códigos da legenda. Brasil: MapBiomas, 2026. Disponível em: https://brasil.mapbiomas.org/wp-content/uploads/sites/3/2026/08/legenda_mapbiomas_solo_colecao3_PT-BR_EN.pdf. Acesso em: 26 nov. 2026.

MARCA-ZEVALLOS, M. J. et al. Local hydrological conditions influence tree diversity and composition across the Amazon basin. **Ecography**, v. 2022, n. 11, e06125, 2022. Disponível em: https://doi.org/10.1111/ecog.06125. Acesso em: 26 nov. 2026.

MEROW, C.; SMITH, M. J.; SILANDER JR., J. A. A practical guide to MaxEnt for modeling species' distributions: what it does, and why inputs and settings matter. **Ecography**, v. 36, n. 10, p. 1058-1069, 2013.

MIRON, A. C. et al. Spatial distribution of six managed tree species is influenced by topography conditions in the Central Amazon. **Journal of Environmental Management**, v. 281, art. 111835, 2021. Disponível em: https://doi.org/10.1016/j.jenvman.2020.111835. Acesso em: 19 out. 2026.

MUSCARELLA, R. et al. ENMeval: an R package for conducting spatially independent evaluations and estimating optimal model complexity for Maxent ecological niche models. **Methods in Ecology and Evolution**, v. 5, n. 11, p. 1198-1205, 2014.

NAIMI, B. et al. Where is positional uncertainty a problem for species distribution modelling? **Ecography**, v. 37, n. 2, p. 191-203, 2014. Disponível em: https://doi.org/10.1111/j.1600-0587.2013.00205.x. Acesso em: 26 nov. 2026.

OWENS, H. L. et al. Constraints on interpretation of ecological niche models by limited environmental ranges on calibration areas. **Ecological Modelling**, v. 263, p. 10-18, 2013.

PARÁ. Secretaria de Estado da Fazenda. **Portaria SEFA nº 669, de 22 de dezembro de 2025**. Altera a Portaria SEFA nº 354/2005, que estabelece o Boletim de Preços Mínimos de Mercado. Diário Oficial do Estado do Pará, Belém, 23 dez. 2025.

PEBESMA, E. Simple features for R: standardized support for spatial vector data. **The R Journal**, v. 10, n. 1, p. 439-446, 2018. Disponível em: https://doi.org/10.32614/RJ-2018-009. Acesso em: 26 nov. 2026.

PEDERSEN, T. L. **patchwork**: the composer of plots. Versão 1.3.2. [S. l.]: CRAN, 2026. Disponível em: https://CRAN.R-project.org/package=patchwork. Acesso em: 26 nov. 2026.

PETERSON, A. T.; SOBERÓN, J. Species distribution modeling and ecological niche modeling: getting the concepts right. **Natureza & Conservação**, v. 10, n. 2, p. 102-107, 2012.

PHILLIPS, S. J.; ANDERSON, R. P.; SCHAPIRE, R. E. Maximum entropy modeling of species geographic distributions. **Ecological Modelling**, v. 190, n. 3-4, p. 231-259, 2006. Disponível em: https://doi.org/10.1016/j.ecolmodel.2005.03.026. Acesso em: 19 out. 2026.

PHILLIPS, S. J.; DUDÍK, M. Modeling of species distributions with Maxent: new extensions and a comprehensive evaluation. **Ecography**, v. 31, n. 2, p. 161-175, 2008. Disponível em: https://doi.org/10.1111/j.0906-7590.2008.5203.x. Acesso em: 26 nov. 2026.

PHILLIPS, S. J. et al. Sample selection bias and presence-only distribution models: implications for background and pseudo-absence data. **Ecological Applications**, v. 19, n. 1, p. 181-197, 2009. Disponível em: https://doi.org/10.1890/07-2153.1. Acesso em: 19 out. 2026.

PHILLIPS, S. J. et al. Opening the black box: an open-source release of Maxent. **Ecography**, v. 40, n. 7, p. 887-893, 2017. Disponível em: https://doi.org/10.1111/ecog.03049. Acesso em: 26 nov. 2026.

POGGIO, L. et al. SoilGrids 2.0: producing soil information for the globe with quantified spatial uncertainty. **SOIL**, v. 7, p. 217-240, 2021. Disponível em: https://doi.org/10.5194/soil-7-217-2021. Acesso em: 19 out. 2026.

QGIS DEVELOPMENT TEAM. **QGIS Geographic Information System**. Versão 4.0.3. Open Source Geospatial Foundation, 2026. Disponível em: https://qgis.org. Acesso em: 26 nov. 2026.

QUEIROZ, W. T. de. **Técnicas de amostragem em inventário florestal nos trópicos**. Belém: Faculdade de Ciências Agrárias do Pará, 1998. 147 p.

R CORE TEAM. **R**: a language and environment for statistical computing. Versão 4.6.2. Vienna: R Foundation for Statistical Computing, 2026. Disponível em: https://www.R-project.org/. Acesso em: 26 nov. 2026.

RADOSAVLJEVIC, A.; ANDERSON, R. P. Making better Maxent models of species distributions: complexity, overfitting and evaluation. **Journal of Biogeography**, v. 41, n. 4, p. 629-643, 2014. Disponível em: https://doi.org/10.1111/jbi.12227. Acesso em: 19 out. 2026.

ROBERTS, D. R. et al. Cross-validation strategies for data with temporal, spatial, hierarchical, or phylogenetic structure. **Ecography**, v. 40, n. 8, p. 913-929, 2017. Disponível em: https://doi.org/10.1111/ecog.02881. Acesso em: 19 out. 2026.

ROYAL BOTANIC GARDENS, KEW. *Handroanthus impetiginosus* (Mart. ex DC.) Mattos. **Plants of the World Online**. Kew: Royal Botanic Gardens, [s. d.]a. Disponível em: https://powo.science.kew.org/taxon/117330-2. Acesso em: 19 out. 2026.

ROYAL BOTANIC GARDENS, KEW. *Handroanthus serratifolius* (Vahl) S.O.Grose. **Plants of the World Online**. Kew: Royal Botanic Gardens, [s. d.]b. Disponível em: https://powo.science.kew.org/taxon/urn:lsid:ipni.org:names:77085096-1. Acesso em: 19 out. 2026.

SANTOS, D. W. S.; STEPKA, T. F.; HESS, A. F. Spatial distribution patterns and horizontal structure of commercial tree species in the Tapajós-Arapiuns Extractive Reserve, Brazilian Amazon. **Small-scale Forestry**, v. 25, n. 1, 2026.

SCHIETTI, J. et al. Vertical distance from drainage drives floristic composition changes in an Amazonian rainforest. **Plant Ecology & Diversity**, v. 7, n. 1-2, p. 241-253, 2014. Disponível em: https://doi.org/10.1080/17550874.2013.783642. Acesso em: 26 nov. 2026.

SCHULZE, M.; GROGAN, J.; UHL, C.; LENTINI, M.; VIDAL, E. Evaluating ipê (*Tabebuia*, Bignoniaceae) logging in Amazonia: sustainable management or catalyst for forest degradation? **Biological Conservation**, v. 141, n. 8, p. 2071-2085, 2008. Disponível em: https://doi.org/10.1016/j.biocon.2008.06.003. Acesso em: 19 out. 2026.

SILVA JUNIOR, I. et al. Seed quality parameters for selection of *Handroanthus serratifolius* (Vahl) S. Grose mother trees in western Amazonia. **Ciência Florestal**, v. 34, n. 4, e84834, 2024. Disponível em: https://doi.org/10.5902/1980509884834. Acesso em: 19 out. 2026.

SOBREIRO, M. B. et al. RNA-Seq reveals different responses to drought in Neotropical trees from savannas and seasonally dry forests. **BMC Plant Biology**, v. 21, art. 463, 2021. Disponível em: https://doi.org/10.1186/s12870-021-03244-7. Acesso em: 19 out. 2026.

SONTAG, V. E. et al. Maintaining genetic diversity in the Amazon: species-specific strategies are more effective for managed forests than generalist criteria in Brazilian legislation. **Forest Ecology and Management**, v. 584, art. 122568, 2025.

TUOMISTO, H.; RUOKOLAINEN, K.; YLI-HALLA, M. Dispersal, environment, and floristic variation of western Amazonian forests. **Science**, v. 299, n. 5604, p. 241-244, 2003. Disponível em: https://doi.org/10.1126/science.1078037. Acesso em: 19 out. 2026.

VALAVI, R.; ELITH, J.; LAHOZ-MONFORT, J. J.; GUILLERA-ARROITA, G. blockCV: an R package for generating spatially or environmentally separated folds for k-fold cross-validation of species distribution models. **Methods in Ecology and Evolution**, v. 10, n. 2, p. 225-232, 2019.

WARREN, D. L.; SEIFERT, S. N. Ecological niche modeling in Maxent: the importance of model complexity and the performance of model selection criteria. **Ecological Applications**, v. 21, n. 2, p. 335-342, 2011. Disponível em: https://doi.org/10.1890/10-1171.1. Acesso em: 19 out. 2026.

WICKHAM, H. **ggplot2**: elegant graphics for data analysis. 2. ed. New York: Springer, 2016.

WRIGHT, S. J. et al. Understanding strategies for seed dispersal by wind under contrasting atmospheric conditions. **Proceedings of the National Academy of Sciences**, v. 105, n. 49, p. 19084-19089, 2008. Disponível em: https://doi.org/10.1073/pnas.0802697105. Acesso em: 26 nov. 2026.

# APÊNDICE A – DESEMPENHO DAS COMBINAÇÕES DE VARIÁVEIS AVALIADAS PARA CADA ESPÉCIE

Alt: altitude; Decl: declividade; Dist: distância à hidrografia; BIO12: precipitação anual; BIO17: precipitação do trimestre mais seco; Text: textura do solo.

**Tabela A1 –** Melhor configuração de cada uma das 63 combinações de variáveis para *Handroanthus impetiginosus*, em ordem decrescente de AUC em propriedade nova (validação LOPO), entre os 945 modelos avaliados.

| Posição | Variáveis | *Features* | RM | AUC | Boyce | Omissão P10 (%) | AUC dentro |
|---:|---|---|---:|---:|---:|---:|---:|
| 1 | Alt + BIO17 | L | 0,5 | 0,825 | 0,82 | 9,8 | 0,53 |
| 2 | Alt + Decl + BIO17 | L | 0,5 | 0,824 | 0,80 | 9,9 | 0,52 |
| 3 | Alt + BIO17 + Text | L | 0,5 | 0,823 | 0,82 | 9,7 | 0,50 |
| 4 | Alt + Decl + BIO17 + Text | L | 0,5 | 0,822 | 0,80 | 9,7 | 0,50 |
| 5 | Alt + Decl + BIO12 | LQ | 0,5 | 0,821 | 0,80 | 10,5 | 0,55 |
| 6 | BIO17 + Text | L | 0,5 | 0,821 | 0,92 | 9,9 | 0,46 |
| 7 | Alt + BIO12 | LQ | 0,5 | 0,821 | 0,74 | 10,3 | 0,55 |
| 8 | Alt + Decl | LQ | 0,5 | 0,820 | 0,84 | 9,8 | 0,56 |
| 9 | Alt | LQ | 0,5 | 0,820 | 0,83 | 9,7 | 0,56 |
| 10 | Alt + Dist + BIO17 | L | 4 | 0,820 | 0,80 | 9,8 | 0,52 |
| 11 | Alt + Decl + Dist + BIO17 | L | 4 | 0,820 | 0,79 | 9,9 | 0,52 |
| 12 | BIO17 | L | 0,5 | 0,820 | 0,89 | 10,4 | 0,46 |
| 13 | BIO12 + BIO17 | L | 0,5 | 0,819 | 0,63 | 13,0 | 0,53 |
| 14 | Alt + Decl + Text | LQ | 0,5 | 0,819 | 0,84 | 9,3 | 0,55 |
| 15 | Alt + Decl + BIO12 + Text | LQ | 0,5 | 0,818 | 0,84 | 9,7 | 0,54 |
| 16 | Alt + Text | LQ | 0,5 | 0,818 | 0,84 | 9,5 | 0,55 |
| 17 | Alt + Dist + BIO17 + Text | L | 4 | 0,818 | 0,78 | 9,7 | 0,50 |
| 18 | Alt + BIO12 + Text | LQ | 0,5 | 0,818 | 0,84 | 9,5 | 0,54 |
| 19 | Alt + Decl + Dist + BIO17 + Text | L | 4 | 0,818 | 0,78 | 9,6 | 0,50 |
| 20 | Decl + BIO17 + Text | L | 0,5 | 0,817 | 0,90 | 9,9 | 0,46 |
| 21 | Dist + BIO17 | LQH | 2 | 0,817 | 0,95 | 9,9 | 0,52 |
| 22 | Decl + Dist + BIO17 | LQH | 2 | 0,817 | 0,95 | 10,3 | 0,52 |
| 23 | Decl + Dist + BIO17 + Text | LQH | 2 | 0,817 | 0,96 | 10,6 | 0,52 |
| 24 | Decl + BIO17 | L | 1 | 0,816 | 0,93 | 9,8 | 0,46 |
| 25 | Dist + BIO17 + Text | LQH | 2 | 0,816 | 0,95 | 10,3 | 0,52 |
| 26 | Decl + Dist + BIO12 + BIO17 | LQH | 1 | 0,815 | 0,87 | 9,5 | 0,53 |
| 27 | BIO12 + BIO17 + Text | L | 1 | 0,815 | 0,72 | 11,2 | 0,50 |
| 28 | Alt + Decl + Dist + BIO12 | LQ | 0,5 | 0,814 | 0,80 | 10,5 | 0,54 |
| 29 | Decl + Dist + BIO12 + BIO17 + Text | LQH | 1 | 0,814 | 0,87 | 9,5 | 0,53 |
| 30 | Dist + BIO12 + BIO17 | LQH | 1 | 0,814 | 0,82 | 9,8 | 0,52 |
| 31 | Dist + BIO12 + BIO17 + Text | LQH | 1 | 0,814 | 0,83 | 9,9 | 0,52 |
| 32 | Alt + Dist + BIO12 | LQ | 0,5 | 0,814 | 0,75 | 10,3 | 0,54 |
| 33 | Alt + Decl + Dist | LQ | 0,5 | 0,814 | 0,85 | 9,8 | 0,55 |
| 34 | Alt + Decl + Dist + Text | LQ | 0,5 | 0,813 | 0,85 | 9,7 | 0,54 |
| 35 | Alt + Dist | LQ | 0,5 | 0,813 | 0,83 | 9,7 | 0,56 |
| 36 | Alt + Decl + Dist + BIO12 + Text | LQ | 0,5 | 0,812 | 0,84 | 9,8 | 0,54 |
| 37 | Alt + Dist + Text | LQ | 0,5 | 0,812 | 0,85 | 9,9 | 0,55 |
| 38 | Alt + Dist + BIO12 + Text | LQ | 0,5 | 0,812 | 0,84 | 9,7 | 0,54 |
| 39 | Alt + Decl + BIO12 + BIO17 | LQH | 0,5 | 0,812 | 0,78 | 9,7 | 0,49 |
| 40 | Alt + Decl + BIO12 + BIO17 + Text | LQH | 0,5 | 0,812 | 0,77 | 9,7 | 0,48 |
| 41 | Alt + Decl + Dist + BIO12 + BIO17 | LQH | 0,5 | 0,812 | 0,81 | 9,5 | 0,50 |
| 42 | Alt + Decl + Dist + BIO12 + BIO17 + Text | LQH | 0,5 | 0,811 | 0,81 | 9,5 | 0,50 |
| 43 | Alt + BIO12 + BIO17 | LQH | 0,5 | 0,811 | 0,77 | 9,7 | 0,48 |
| 44 | Alt + Dist + BIO12 + BIO17 | LQH | 0,5 | 0,811 | 0,81 | 9,4 | 0,50 |
| 45 | Alt + BIO12 + BIO17 + Text | LQH | 0,5 | 0,810 | 0,76 | 9,7 | 0,48 |
| 46 | Alt + Dist + BIO12 + BIO17 + Text | LQH | 0,5 | 0,810 | 0,80 | 9,4 | 0,50 |
| 47 | Decl + BIO12 + BIO17 | LQH | 1 | 0,809 | 0,80 | 10,1 | 0,49 |
| 48 | Decl + BIO12 + BIO17 + Text | LQH | 1 | 0,808 | 0,80 | 10,1 | 0,48 |
| 49 | Decl + Dist + BIO12 | LQH | 0,5 | 0,805 | 0,67 | 9,2 | 0,55 |
| 50 | Decl + Dist + BIO12 + Text | LQH | 0,5 | 0,804 | 0,68 | 9,3 | 0,55 |
| 51 | Decl + BIO12 | LQH | 0,5 | 0,804 | 0,59 | 9,6 | 0,53 |
| 52 | Dist + BIO12 | LQH | 0,5 | 0,804 | 0,67 | 9,1 | 0,54 |
| 53 | Dist + BIO12 + Text | LQH | 1 | 0,804 | 0,69 | 9,2 | 0,56 |
| 54 | Decl + BIO12 + Text | LQH | 1 | 0,802 | 0,67 | 9,5 | 0,54 |
| 55 | BIO12 | LQ | 0,5 | 0,801 | 0,56 | 9,4 | 0,51 |
| 56 | BIO12 + Text | LQH | 1 | 0,799 | 0,53 | 9,5 | 0,54 |
| 57 | Decl + Dist + Text | LQH | 0,5 | 0,641 | 0,76 | 10,4 | 0,53 |
| 58 | Decl + Text | LQH | 0,5 | 0,607 | 0,54 | 9,9 | 0,49 |
| 59 | Dist + Text | LQ | 0,5 | 0,601 | 0,62 | 10,1 | 0,52 |
| 60 | Decl + Dist | LQ | 0,5 | 0,567 | 0,38 | 10,8 | 0,53 |
| 61 | Dist | L | 0,5 | 0,552 | -0,50 | 9,4 | 0,56 |
| 62 | Decl | LQ | 0,5 | 0,547 | 0,19 | 10,2 | 0,48 |
| 63 | Text | L | 2 | 0,493 | 0,07 | 5,0 | 0,50 |

Fonte: elaborada pelo autor (2026).

**Tabela A2 –** Melhor configuração de cada uma das 63 combinações de variáveis para *Handroanthus serratifolius*, em ordem decrescente de AUC em propriedade nova (validação LOPO), entre os 945 modelos avaliados.

| Posição | Variáveis | *Features* | RM | AUC | Boyce | Omissão P10 (%) | AUC dentro |
|---:|---|---|---:|---:|---:|---:|---:|
| 1 | Decl + Dist + BIO12 + Text | LQH | 1 | 0,719 | 0,71 | 10,6 | 0,54 |
| 2 | Decl + Dist + BIO12 | LQH | 1 | 0,718 | 0,70 | 10,5 | 0,54 |
| 3 | Decl + BIO12 + Text | LQH | 1 | 0,716 | 0,70 | 11,0 | 0,50 |
| 4 | Decl + BIO12 | LQH | 1 | 0,714 | 0,67 | 11,1 | 0,50 |
| 5 | Dist + BIO12 + Text | LQH | 2 | 0,714 | 0,64 | 10,2 | 0,53 |
| 6 | BIO12 + Text | LQH | 2 | 0,713 | 0,80 | 11,1 | 0,49 |
| 7 | Dist + BIO12 | LQH | 2 | 0,712 | 0,64 | 10,6 | 0,53 |
| 8 | BIO12 | LQH | 2 | 0,710 | 0,81 | 10,7 | 0,49 |
| 9 | BIO17 + Text | LQH | 4 | 0,699 | 0,74 | 11,1 | 0,49 |
| 10 | BIO17 | LQH | 4 | 0,699 | 0,61 | 11,7 | 0,49 |
| 11 | Decl + BIO17 | LQH | 3 | 0,695 | 0,34 | 11,5 | 0,50 |
| 12 | Decl + BIO17 + Text | LQH | 3 | 0,694 | 0,61 | 11,3 | 0,50 |
| 13 | Decl + Dist + BIO17 + Text | LQH | 3 | 0,694 | 0,53 | 11,6 | 0,52 |
| 14 | Decl + Dist + BIO17 | LQH | 3 | 0,694 | 0,36 | 10,8 | 0,53 |
| 15 | Dist + BIO17 + Text | LQH | 3 | 0,693 | 0,49 | 11,7 | 0,52 |
| 16 | Dist + BIO17 | LQH | 4 | 0,692 | 0,22 | 11,4 | 0,53 |
| 17 | Decl + BIO12 + BIO17 | LQH | 4 | 0,674 | 0,74 | 13,2 | 0,51 |
| 18 | Decl + BIO12 + BIO17 + Text | LQH | 4 | 0,673 | 0,76 | 13,3 | 0,50 |
| 19 | BIO12 + BIO17 + Text | LQH | 4 | 0,671 | 0,72 | 12,8 | 0,49 |
| 20 | Alt + BIO12 + Text | LQH | 0,5 | 0,665 | 0,91 | 11,4 | 0,55 |
| 21 | Alt + BIO12 | LQH | 0,5 | 0,662 | 0,91 | 11,4 | 0,55 |
| 22 | Alt + Decl + BIO12 + Text | LQH | 0,5 | 0,662 | 0,91 | 11,5 | 0,55 |
| 23 | Alt + Dist + BIO12 + Text | LQH | 0,5 | 0,661 | 0,93 | 11,6 | 0,56 |
| 24 | Dist + BIO12 + BIO17 + Text | LQH | 4 | 0,660 | 0,83 | 14,0 | 0,52 |
| 25 | Alt + Dist + BIO12 | LQH | 0,5 | 0,660 | 0,93 | 11,5 | 0,56 |
| 26 | Alt + Decl + BIO12 | LQH | 0,5 | 0,659 | 0,91 | 11,4 | 0,56 |
| 27 | Decl + Dist + BIO12 + BIO17 + Text | LQH | 4 | 0,657 | 0,86 | 14,0 | 0,52 |
| 28 | Alt + Decl + Dist + BIO12 + Text | LQH | 0,5 | 0,657 | 0,93 | 11,8 | 0,56 |
| 29 | Alt + Decl + Dist + BIO12 | LQH | 0,5 | 0,657 | 0,93 | 11,7 | 0,56 |
| 30 | Decl + Dist + BIO12 + BIO17 | LQH | 4 | 0,656 | 0,86 | 14,1 | 0,53 |
| 31 | Dist + BIO12 + BIO17 | LQH | 4 | 0,655 | 0,80 | 14,0 | 0,53 |
| 32 | BIO12 + BIO17 | LQH | 4 | 0,644 | 0,68 | 13,2 | 0,51 |
| 33 | Alt + BIO17 + Text | LQH | 2 | 0,631 | 0,85 | 10,9 | 0,55 |
| 34 | Alt + BIO17 | LQH | 2 | 0,630 | 0,80 | 10,7 | 0,56 |
| 35 | Alt + Dist + BIO17 + Text | LQH | 3 | 0,630 | 0,90 | 11,3 | 0,55 |
| 36 | Alt + Dist + BIO17 | LQH | 3 | 0,630 | 0,85 | 11,3 | 0,56 |
| 37 | Alt + Decl + Dist + BIO17 + Text | LQH | 3 | 0,628 | 0,90 | 11,3 | 0,55 |
| 38 | Alt + Decl + BIO17 | LQH | 2 | 0,628 | 0,81 | 10,7 | 0,56 |
| 39 | Alt + Decl + Dist + BIO17 | LQH | 3 | 0,628 | 0,85 | 11,3 | 0,56 |
| 40 | Alt + Decl + BIO17 + Text | LQH | 2 | 0,628 | 0,85 | 10,9 | 0,54 |
| 41 | Decl + Dist + Text | L | 0,5 | 0,613 | 0,82 | 10,5 | 0,51 |
| 42 | Alt + Dist + BIO12 + BIO17 + Text | LQH | 4 | 0,611 | 0,95 | 13,3 | 0,55 |
| 43 | Alt + Decl + Dist + BIO12 + BIO17 + Text | LQH | 4 | 0,610 | 0,95 | 13,3 | 0,55 |
| 44 | Alt + Dist + BIO12 + BIO17 | LQH | 3 | 0,609 | 0,93 | 13,1 | 0,56 |
| 45 | Alt + Decl + Dist + BIO12 + BIO17 | LQH | 4 | 0,607 | 0,93 | 13,3 | 0,55 |
| 46 | Alt + BIO12 + BIO17 + Text | LQH | 3 | 0,605 | 0,91 | 12,6 | 0,54 |
| 47 | Alt + Decl + BIO12 + BIO17 + Text | LQH | 3 | 0,604 | 0,91 | 12,6 | 0,54 |
| 48 | Alt + BIO12 + BIO17 | LQH | 3 | 0,603 | 0,90 | 12,6 | 0,55 |
| 49 | Alt + Decl + BIO12 + BIO17 | LQH | 3 | 0,602 | 0,90 | 12,6 | 0,55 |
| 50 | Decl + Text | L | 0,5 | 0,591 | 0,65 | 9,9 | 0,50 |
| 51 | Decl | LQH | 1 | 0,580 | 0,33 | 9,8 | 0,50 |
| 52 | Decl + Dist | L | 0,5 | 0,571 | 0,92 | 10,5 | 0,53 |
| 53 | Dist + Text | L | 0,5 | 0,571 | 0,46 | 9,5 | 0,52 |
| 54 | Dist | L | 0,5 | 0,563 | 0,84 | 9,1 | 0,54 |
| 55 | Alt + Dist + Text | LQH | 0,5 | 0,562 | 0,88 | 13,6 | 0,55 |
| 56 | Alt + Decl + Dist + Text | LQH | 0,5 | 0,561 | 0,88 | 13,5 | 0,55 |
| 57 | Alt + Decl + Text | LQH | 0,5 | 0,559 | 0,85 | 12,5 | 0,54 |
| 58 | Alt + Text | LQH | 0,5 | 0,558 | 0,85 | 12,7 | 0,54 |
| 59 | Alt | LQH | 3 | 0,539 | 0,77 | 12,8 | 0,56 |
| 60 | Alt + Dist | LQH | 2 | 0,537 | 0,73 | 13,6 | 0,56 |
| 61 | Alt + Decl | LQH | 3 | 0,537 | 0,76 | 12,6 | 0,56 |
| 62 | Alt + Decl + Dist | LQH | 0,5 | 0,536 | 0,78 | 14,9 | 0,56 |
| 63 | Text | L | 0,5 | 0,517 | 0,50 | 2,0 | 0,49 |

Fonte: elaborada pelo autor (2026).

# APÊNDICE B – FLUXO DE PROCESSAMENTO DOS DADOS

| Etapa | Programa | Entrada | Procedimento | Saída |
|---|---|---|---|---|
| 1 | QGIS | Inventários (CSV) e polígonos das UPAs | Conferência de coordenadas e projeção; associação de cada árvore à UPA | Camada de pontos por propriedade |
| 2 | QGIS | ANADEM, rede de drenagem, CHELSA, MapBiomas Solo | Recorte, reprojeção, alinhamento a 30 m; declividade; distância à drenagem | Seis rasters alinhados |
| 3 | QGIS/R | Pontos e rasters | Extração dos valores; filtro DAP > 10 cm; uma presença por pixel | Tabela de presenças |
| 4 | R | Pixels válidos das UPAs | Sorteio do *background* (10.000 pontos, proporcional à área) | Tabela de *background* |
| 5 | R | Presenças e *background* | Densidade por classe; Mann-Whitney; variação entre propriedades | Tabelas e Figuras 4 e 5 |
| 6 | R (maxnet) | Presenças e *background* | 945 modelos por espécie com validação LOPO | Apêndice A |
| 7 | R (maxnet) | Modelo escolhido | Jackknife, curvas de resposta e ROC; teste externo | Tabelas e figuras de resultados |
| 8 | R/QGIS | Modelo final | Predição nas UPAs e elaboração dos mapas | Mapas de adequabilidade |

Fonte: elaborado pelo autor (2026).
