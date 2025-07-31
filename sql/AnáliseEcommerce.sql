-- Contagem inicial de registros: O dataset original contém 541.909 linhas.

SELECT COUNT(*) FROM OnlineRetail;

-- Vamos contar o número de linhas onde Quantity ou o UnitPrice são menores ou iguais a zero: são 11.805 linhas

SELECT
    COUNT(*)
FROM OnlineRetail
WHERE Quantity <= 0 OR UnitPrice <= 0;

/*
Precisamos excluir estes dados nulos porque eles representam devoluções ou cancelamentos, no caso de Quantity, e 
cortesias e promoções, no caso de UnitPrice.
*/

CREATE TABLE online_retail_clean AS
SELECT *
FROM OnlineRetail
WHERE Quantity > 0 AND UnitPrice > 0;

-- Agora vamos contar quantas linhas ficaram: 530.104 linhas.

SELECT COUNT(*) FROM online_retail_clean;

/*
Agora vamos responder as perguntas:
Quais produtos estão vendendo mais (e menos)? Excluímos alguns códigos porque não são produtos. Ex: DOT, PADS, etc.
Com maior valor é REGENCY CAKESTAND 3 TIER. Com menor valor é HEN HOUSE W CHICK IN NEST.
Mais vendido é PAPER CRAFT , LITTLE BIRDIE, menos vendido da lista Top10 é BLUE PADDED SOFT MOBILE. 
*/

SELECT
    StockCode AS CodigoDoProduto,
    Description AS NomeDoProduto,
    SUM(ROUND(Quantity * UnitPrice, 2)) AS ReceitaTotal
FROM online_retail_clean
WHERE StockCode NOT IN ('POST', 'D', 'M', 'C2', 'DOT', 'PADS')
GROUP BY CodigoDoProduto, NomeDoProduto
ORDER BY ReceitaTotal ASC
LIMIT 10;

SELECT
    StockCode AS CodigoDoProduto,
    Description AS NomeDoProduto,
    SUM(Quantity) AS QuantidadeVendida
FROM online_retail_clean
WHERE StockCode NOT IN ('POST', 'D', 'M', 'C2', 'DOT')
GROUP BY CodigoDoProduto, NomeDoProduto
ORDER BY QuantidadeVendida DESC
LIMIT 10;

/*
Quem são os "campeões de venda" em faturamento e quantidade?
PAPER CRAFT , LITTLE BIRDIE e JUMBO BAG RED RETROSPOT são os que tem maior quantidade vendida e maior valor ao mesmo tempo.

Respondendo a pergunta: Quem são nossos clientes mais valiosos?
*/

SELECT
    CustomerID AS ID_Cliente,
    Country AS Pais,
    SUM(ROUND(Quantity * UnitPrice, 2)) AS ValorTotalDeCompra
FROM online_retail_clean
GROUP BY CustomerID, Country
ORDER BY ValorTotalDeCompra DESC
LIMIT 10;

/*
Ao mandar essa query, vemos que existem clientes sem identificação na coluna CostumerID, e eles representam o total de receita
de 1716830.53 no Reino Unido. Precisamos limpar os dados novamente para excluir estes clientes. 
Para isso vamos excluir a tabela já criada.
*/

DROP TABLE online_retail_clean;

-- Vamos criar outra com CostumerID sem strings vazias (usar IS NOT NULL em WHERE não vai servir):

CREATE TABLE online_retail_clean AS
SELECT *
FROM OnlineRetail
WHERE
    Quantity > 0 AND
    UnitPrice > 0 AND
    TRIM(CustomerID) != '';

-- Agora vamos contar quantas linhas restaram: 397.884 linhas

SELECT COUNT(*) FROM online_retail_clean;

/*
Ou seja, são 132 mil transações que representam um volume enorme de receita que não pode ser atribuído a um cliente específico.
Então o e-commerce está perdendo a oportunidade de entender, reter e fazer marketing para um grupo enorme de compradores, e
o time de negócios poderia investigar por que esses clientes não são identificados. Seria um problema técnico? 
Porque estamos deixando chegar na etapa da compra de checkout sem identificação?

Vamos repetir a query para entendermos melhor quem são nossos clientes vips: 
*/

SELECT
    CustomerID AS ID_Cliente,
    Country AS Pais,
    SUM(ROUND(Quantity * UnitPrice, 2)) AS ValorTotalDeCompra
FROM online_retail_clean
GROUP BY ID_Cliente, Pais
ORDER BY ValorTotalDeCompra DESC
LIMIT 10;

/*
O cliente de ID 14646 é o principal VIP e sozinho gerou mais de 280 mil em receita.
Embora a maioria dos clientes VIPs seja do Reino Unido, o principal cliente é da Holanda
e outros da Irlanda e Australia também aparecem. Isso indica que os clientes mais valiosos não se limitam ao mercado doméstico.

Agora vamos ver quais países tem maior receita, e quais não: 
Reino Unido, Holanda, Irlanda, Alemanha, França, Australia, Espanha, Suíça, Bélgica e Suécia estão no Top 10 de maior receita.
Arábia Saudita, Bahrain, República Tcheca, África do Sul , Brasil, Comunidade Europeia, Lituânia, Líbano, Emirados Árabes Unidos e 
não especificado representam o Top 10 de menor receita. Vale o esforço investir?
*/

SELECT
    Country AS Pais,
    SUM(ROUND(Quantity * UnitPrice, 2)) AS ReceitaTotal
FROM online_retail_clean
GROUP BY Pais
ORDER BY ReceitaTotal ASC
LIMIT 10;

/*
Não especificado na lista é um ponto de atenção. Ele representa vendas de regiões que não foram registradas, 
e a receita de 2667.07 indica uma pequena, mas notável, quantidade de dados perdidos.
O que esses clientes têm em comum? Como podemos manter esse relacionamento (ou até atrair outros parecidos)?
São clientes de alto valor e embora a maioria seja do Reino Unido, a presença de clientes da Holanda, Irlanda (EIRE) 
e Austrália na lista VIP sugere que o alto valor não está restrito a um mercado doméstico. O que eles têm em comum não é o
país, mas sim a disposição para gastar.
Seria bom descobrir se eles compram com alta frequência (muitas compras pequenas) ou com alto valor por compra
(poucas compras grandes). Vamos descobrir o ticket médio desses clientes:
*/

SELECT
    CustomerID AS ID_Cliente,
    COUNT(DISTINCT InvoiceNo) AS NumeroDeCompras,
    SUM(ROUND(Quantity * UnitPrice, 2)) AS ValorTotalDeCompra,
    AVG(ROUND(Quantity * UnitPrice, 2)) AS TicketMedio
FROM online_retail_clean
WHERE CustomerID IN ('14646', '18102', '17450', '16446', '14911') -- Apenas os top 5
GROUP BY ID_Cliente
ORDER BY ValorTotalDeCompra DESC;

/*
Com essa query podemos não só ver que o cliente ID 14.646 tem a segunda maior quantidade em compra, 73, como também 
podemos ver que o cliente 14.911 tem a maior quantidade de compra, 201, mas de itens com menor valor pois é a menor receita.
Ou seja, temos dois perfis de clientes VIPs. Temos aquele que consome bastante mercadoria de alto valor, e temos aquele que
mais consome, embora suas compras sejam de itens mais baratos. Ambos são cliente fiéis  merecem camapnhas de valorização e retenção.
Então podemos focar em Programas de Fidelidade Exclusivos, Comunicação Personalizada, Atendimento ao Cliente Prioritário e 
Marketing Segmentado.

Agora vamos para outras perguntas:
Tem alguma tendência por região ou época do ano?
Tem épocas específicas em que as vendas disparam (ou caem)? Isso pode nos ajudar a planejar promoções e estoque.
*/

SELECT
    STRFTIME('%Y-%m', InvoiceDate) AS AnoMes,
    SUM(ROUND(Quantity * UnitPrice, 2)) AS ReceitaTotal
FROM online_retail_clean
GROUP BY AnoMes
ORDER BY AnoMes;

-- STRFTIME() não conseguiu reconhecer o formato dos dados na coluna InvoiceDate, então vamos usar a query para id o formato de data.

SELECT InvoiceDate FROM online_retail_clean;

SELECT typeof(InvoiceDate), InvoiceDate FROM online_retail_clean LIMIT 10;

-- Formato data e hora juntos, ex: 12/1/2010 8:26

SELECT COUNT(*) FROM online_retail_clean WHERE InvoiceDate IS NULL;

/*
Vemos que existem linhas que contém valores nulos ou são células vazias ' ', então temos que usar uma query que não mostre isso. 
Vamos usar o WITH para criar tabelas temporárias e facilitar o nosso trabalho. O WITH funciona como um mise en place em nossa 
receita principal :)
*/


WITH cleaned_dates AS (
    SELECT 
        Country,
        Quantity,
        UnitPrice,
        CASE
            WHEN InvoiceDate GLOB '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]*' THEN
                strftime('%Y-%m', 
                    SUBSTR(InvoiceDate, 7, 4) || '-' || 
                    SUBSTR(InvoiceDate, 4, 2) || '-' || 
                    SUBSTR(InvoiceDate, 1, 2))
            WHEN InvoiceDate GLOB '[0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]*' THEN
                strftime('%Y-%m', 
                    SUBSTR(InvoiceDate, 6, 4) || '-' || 
                    SUBSTR(InvoiceDate, 3, 2) || '-' || 
                    '0' || SUBSTR(InvoiceDate, 1, 1))
            WHEN InvoiceDate GLOB '[0-9][0-9]/[0-9]/[0-9][0-9][0-9][0-9]*' THEN
                strftime('%Y-%m', 
                    SUBSTR(InvoiceDate, 6, 4) || '-' || 
                    '0' || SUBSTR(InvoiceDate, 4, 1) || '-' || 
                    SUBSTR(InvoiceDate, 1, 2))
            ELSE NULL
        END AS ano_mes
    FROM online_retail_clean
    WHERE InvoiceDate IS NOT NULL
      AND InvoiceDate != ''
),

country_monthly_revenue AS (
    SELECT 
        Country,
        ano_mes,
        ROUND(SUM(Quantity * UnitPrice), 2) AS receita_total,
        ROW_NUMBER() OVER (PARTITION BY Country ORDER BY SUM(Quantity * UnitPrice) DESC) AS country_rank
    FROM cleaned_dates
    WHERE ano_mes IS NOT NULL
    GROUP BY Country, ano_mes
)

SELECT 
    Country,
    ano_mes,
    receita_total
FROM country_monthly_revenue
WHERE country_rank <= 5
ORDER BY 
    receita_total DESC, 
    Country;       

/*
Com essa query podemos ver que no Reino Unido, por exemplo, temos os meses Top 05 mais rentáveis de 
novembro, setembro, outubro, dezembro e junho, e isso já pode nos ajudar a intensificar campanhas de marketing para os outros
meses e reafirmar as campanhas nestes meses de maior receita.Quando invertemos a ordem da receita_total para ASC, vemos que os
cinco meses com menor lucro são agosto, fevereiro, janeiro, outubro e abril.
*/

WITH cleaned_dates AS (
    SELECT
        Quantity,
        UnitPrice,
        CASE
            WHEN InvoiceDate GLOB '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]*' THEN
                strftime('%Y-%m',
                    SUBSTR(InvoiceDate, 7, 4) || '-' ||
                    SUBSTR(InvoiceDate, 4, 2) || '-' ||
                    SUBSTR(InvoiceDate, 1, 2))
            WHEN InvoiceDate GLOB '[0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]*' THEN
                strftime('%Y-%m',
                    SUBSTR(InvoiceDate, 6, 4) || '-' ||
                    SUBSTR(InvoiceDate, 3, 2) || '-' ||
                    '0' || SUBSTR(InvoiceDate, 1, 1))
            WHEN InvoiceDate GLOB '[0-9][0-9]/[0-9]/[0-9][0-9][0-9][0-9]*' THEN
                strftime('%Y-%m',
                    SUBSTR(InvoiceDate, 6, 4) || '-' ||
                    '0' || SUBSTR(InvoiceDate, 4, 1) || '-' ||
                    SUBSTR(InvoiceDate, 1, 2))
            ELSE NULL
        END AS ano_mes
    FROM online_retail_clean
    WHERE InvoiceDate IS NOT NULL
      AND InvoiceDate != ''
)

SELECT
    ano_mes,
    ROUND(SUM(Quantity * UnitPrice), 2) AS receita_total
FROM
    cleaned_dates
WHERE
    ano_mes IS NOT NULL
GROUP BY
    ano_mes
ORDER BY
    receita_total DESC;

/*
Há um pico de vendas muito forte nos últimos meses de 2011. O mês mais lucrativo foi novembro de 2011 
com uma receita total de R$ 345.332,09. A tendência clara é que a receita se mantém em um nível mais baixo no 
início do ano e acelera significativamente a partir de setembro, atingindo o pico em novembro. Ou seja, precisamos fortalecer 
campanhas como incluindo Black Friday e preparativos para o Natal e intensificar campanhas para o início do ano, como Valentines Day,
Carnaval ou Dia do Trabalho.

Agora vamos testar nossa primeira hipótese: 
1.	Uma pequena porcentagem dos nossos clientes (clientes 'VIP') é responsável pela maior parte da nossa receita total, 
e identificar esses clientes é muito importante para a criação de programas de fidelidade.
*/

WITH receita_total AS (
    SELECT SUM(Quantity * UnitPrice) AS total_receita
    FROM online_retail_clean
    WHERE CustomerID IS NOT NULL
),

receita_por_cliente AS (
    SELECT 
        CustomerID,
        SUM(Quantity * UnitPrice) AS receita_cliente
    FROM online_retail_clean
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
),

clientes_ordenados AS (
    SELECT
        CustomerID,
        receita_cliente,
        ROW_NUMBER() OVER (ORDER BY receita_cliente DESC) AS rank_cliente
    FROM receita_por_cliente
)

SELECT
    CustomerID,
    receita_cliente,
    rank_cliente,
    (rank_cliente * 100.0 / (SELECT COUNT(*) FROM clientes_ordenados)) AS pct_clientes,
    (SUM(receita_cliente) OVER (ORDER BY rank_cliente) * 100.0 / (SELECT total_receita FROM receita_total)) AS pct_receita_acumulada
FROM clientes_ordenados
ORDER BY rank_cliente
LIMIT 10;

/*
Com essa query identificamos que uma pequena porcentagem de clientes é responsável por grande parte da receita, o que comprova que
existe uma tendência à REgra de Pareto (80/20). Se olharmos para a linha de rank 21, vemos que apenas 0,48% dos clientes são 
responsáveis por 24,35% da receita total.
Apenas 4,6% dos clientes geram quase metade da receita, e quando chegamos na linha de rank 200 a receita acumulada já atinge 
impressionantes 49,23%.

O que precisamos saber agora é: o que esses clientes compram? 
*/

WITH receita_por_cliente AS (
    SELECT 
        CustomerID,
        SUM(Quantity * UnitPrice) AS receita_cliente
    FROM online_retail_clean
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
),

clientes_ordenados AS (
    SELECT
        CustomerID,
        receita_cliente,
        ROW_NUMBER() OVER (ORDER BY receita_cliente DESC) AS rank_cliente
    FROM receita_por_cliente
),

clientes_vip AS (
    SELECT
        CustomerID
    FROM clientes_ordenados
    WHERE rank_cliente <= 200
)

SELECT
    t1.StockCode,
    t1.Description,
    SUM(t1.Quantity) AS quantidade_total,
    ROUND(SUM(t1.Quantity * t1.UnitPrice), 2) AS receita_total_vip
FROM
    online_retail_clean AS t1
JOIN
    clientes_vip AS t2 ON t1.CustomerID = t2.CustomerID
GROUP BY
    t1.StockCode, t1.Description
ORDER BY
    receita_total_vip DESC, quantidade_total DESC;

/*
Com essa query vemos quais produtos mais comprados e de maior valor que nossos clientes compram. Seerá necessário realizar
marketing personalizado através da criação de campanhas de e-mail ou ofertas exclusivas que combinem produtos que os clientes VIP 
já amam. Por exemplo: oferecer um desconto em um novo JUMBO BAG para quem já comprou um.

Testando nossa segunda hipótese:
2. As vendas demonstram altas e baixas a depender da época do ano, com picos significativos em meses próximos a datas comemorativas 
ex: final de ano), exigindo planejamento de estoque e marketing para esses momentos.
*/

WITH dados_tratados AS (
    SELECT 
        CASE
            WHEN InvoiceDate LIKE '__/__/____%' THEN 
                SUBSTR(InvoiceDate, 7, 4) || '-' || SUBSTR(InvoiceDate, 4, 2)
            WHEN InvoiceDate LIKE '_/__/____%' THEN 
                SUBSTR(InvoiceDate, 6, 4) || '-' || SUBSTR(InvoiceDate, 3, 2)
            WHEN InvoiceDate LIKE '__/_/____%' THEN 
                SUBSTR(InvoiceDate, 6, 4) || '-0' || SUBSTR(InvoiceDate, 4, 1)
            ELSE NULL
        END AS mes_ano,
        Quantity,
        UnitPrice
    FROM online_retail_clean
    WHERE CustomerID IS NOT NULL 
      AND Quantity > 0 
      AND UnitPrice > 0
      AND InvoiceDate IS NOT NULL
      AND InvoiceDate != ''
      AND InvoiceDate NOT LIKE '%-%'  
),

dados_mensais AS (
    SELECT
        mes_ano,
        SUBSTR(mes_ano, 1, 4) AS ano,
        SUBSTR(mes_ano, 6, 2) AS mes,
        SUM(Quantity * UnitPrice) AS receita_mensal
    FROM dados_tratados
    WHERE mes_ano IS NOT NULL
      AND LENGTH(mes_ano) = 7 
      AND SUBSTR(mes_ano, 6, 2) BETWEEN '01' AND '12'  
    GROUP BY mes_ano
)

SELECT 
    mes_ano,
    receita_mensal,
    receita_mensal / AVG(receita_mensal) OVER (PARTITION BY ano) AS proporcao_media_anual,
    CASE WHEN mes IN ('11', '12') THEN 'Alta Temporada' ELSE 'Normal' END AS temporada,
    receita_mensal - LAG(receita_mensal) OVER (ORDER BY mes_ano) AS variacao_mensal
FROM dados_mensais
ORDER BY mes_ano;

/*
Query para análise sazonal de vendas. Esta consulta identifica os picos de receita mensais, tratando formatos de data variados.
Inclui funções de janela (window functions) para calcular a proporção da receita em relação à média anual e a variação mensal, 
validando a hipótese de alta temporada no final do ano.

A nova pergunta de negócio que devemos responder é:
O que os clientes VIPs compram durante os meses de alta temporada?
*/

WITH receita_por_cliente AS (
    SELECT 
        CustomerID,
        SUM(Quantity * UnitPrice) AS receita_cliente
    FROM online_retail_clean
    WHERE CustomerID IS NOT NULL AND Quantity > 0 AND UnitPrice > 0
    GROUP BY CustomerID
),

clientes_ordenados AS (
    SELECT
        CustomerID,
        ROW_NUMBER() OVER (ORDER BY receita_cliente DESC) AS rank_cliente
    FROM receita_por_cliente
),

clientes_vip AS (
    SELECT
        CustomerID
    FROM clientes_ordenados
    WHERE rank_cliente <= 200
),

-- Novo CTE para tratar a data de forma robusta e extrair o mês
transacoes_com_mes AS (
    SELECT
        CustomerID,
        StockCode,
        Description,
        Quantity,
        UnitPrice,
        CASE
            WHEN InvoiceDate LIKE '__/__/____%' THEN SUBSTR(InvoiceDate, 4, 2)
            WHEN InvoiceDate LIKE '_/__/____%' THEN SUBSTR(InvoiceDate, 3, 2)
            WHEN InvoiceDate LIKE '__/_/____%' THEN '0' || SUBSTR(InvoiceDate, 4, 1)
            ELSE NULL
        END AS mes_numero
    FROM online_retail_clean
)

SELECT
    t1.StockCode,
    t1.Description,
    SUM(t1.Quantity) AS quantidade_vendida_alta_temporada,
    ROUND(SUM(t1.Quantity * t1.UnitPrice), 2) AS receita_alta_temporada
FROM
    transacoes_com_mes AS t1
JOIN
    clientes_vip AS t2 ON t1.CustomerID = t2.CustomerID
WHERE
    t1.mes_numero IN ('10', '11', '12')
GROUP BY
    t1.StockCode, t1.Description
ORDER BY
    receita_alta_temporada DESC;

/*
O item PICNIC BASKET WICKER 60 PIECES é o principal motor de receita entre os clientes VIP na alta temporada. 
Com uma receita de 39.619,50, ele se destaca de todos os outros produtos.
Também temos WHITE HANGING HEART T-LIGHT HOLDER, REGENCY CAKESTAND 3 TIER, e FAIRY CAKE FLANNEL ASSORTED COLOUR, que são itens
de casa, cozinha e festa.
Foco: priorizar o estoque do PICNIC BASKET WICKER 60 PIECES e dos outros itens do topo da lista para a próxima alta temporada, 
garantindo que eles nunca fiquem em falta.

Nosso último passo será descobrir quais produtos os clientes mais valiosos compram juntos durante a alta temporada.
*/

WITH receita_por_cliente AS (
    SELECT 
        CustomerID,
        SUM(Quantity * UnitPrice) AS receita_cliente
    FROM online_retail_clean
    WHERE CustomerID IS NOT NULL AND Quantity > 0 AND UnitPrice > 0
    GROUP BY CustomerID
),

clientes_ordenados AS (
    SELECT
        CustomerID,
        ROW_NUMBER() OVER (ORDER BY receita_cliente DESC) AS rank_cliente
    FROM receita_por_cliente
),

clientes_vip AS (
    SELECT
        CustomerID
    FROM clientes_ordenados
    WHERE rank_cliente <= 200
),

transacoes_com_mes AS (
    SELECT
        InvoiceNo,
        CustomerID,
        StockCode,
        Description,
        Quantity,
        UnitPrice,
        CASE
            WHEN InvoiceDate LIKE '__/__/____%' THEN SUBSTR(InvoiceDate, 4, 2)
            WHEN InvoiceDate LIKE '_/__/____%' THEN SUBSTR(InvoiceDate, 3, 2)
            WHEN InvoiceDate LIKE '__/_/____%' THEN '0' || SUBSTR(InvoiceDate, 4, 1)
            ELSE NULL
        END AS mes_numero
    FROM online_retail_clean
),

produtos_ancora AS (
    SELECT StockCode, Description FROM online_retail_clean
    WHERE Description IN (
        'PICNIC BASKET WICKER 60 PIECES',
        'WHITE HANGING HEART T-LIGHT HOLDER',
        'REGENCY CAKESTAND 3 TIER'
    )
    GROUP BY StockCode, Description
)

SELECT
    t1.Description AS produto_ancora,
    t2.Description AS produto_frequentemente_comprado_junto,
    COUNT(DISTINCT t1.InvoiceNo) AS frequencia_de_compra_conjunta
FROM
    transacoes_com_mes AS t1
JOIN
    transacoes_com_mes AS t2 ON t1.InvoiceNo = t2.InvoiceNo AND t1.StockCode != t2.StockCode
JOIN
    clientes_vip AS t3 ON t1.CustomerID = t3.CustomerID
WHERE
    t1.mes_numero IN ('10', '11', '12')
    AND t2.mes_numero IN ('10', '11', '12')
    AND t1.StockCode IN (SELECT StockCode FROM produtos_ancora)
GROUP BY
    t1.Description,
    t2.Description
ORDER BY
    frequencia_de_compra_conjunta DESC;

/*
Vemos o REGENCY CAKESTAND 3 TIER associado a REGENCY TEA PLATE ROSES e REGENCY TEAPOT ROSES. Isso indica que os clientes VIP 
buscam completar a coleção. Seria interessante oferecer um pacote promocional dos três itens juntos. 
A combinação do REGENCY CAKESTAND 3 TIER com JUMBO BAG RED RETROSPOT e PARTY BUNTING sugere que esses clientes estão organizando 
eventos, então também seria interessante oferecer kit festa como um conjunto.

Ação que podemos propor: implementar sugestões "Comprado frequentemente junto" no carrinho de compras ou na página do produto para 
itens com alta complementaridade funcional. 
A ausência do PICNIC BASKET WICKER 60 PIECES nas combinações frequentes (exceto com o "SMALL") reforça o insight de que ele é um item 
comprado isoladamente. Ele gera alto valor por si só, sem precisar de venda cruzada.
*/








