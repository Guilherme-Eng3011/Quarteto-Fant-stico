

USE integracao_dados_entrega;


SELECT
    CONCAT(pc.produto_id, ' - ', COALESCE(pc.descricao_produto, '')) AS produto,
    pc.qtde_pedida AS quantidade_requisitada,
    DATE_FORMAT(pc.data_pedido, '%d/%m/%Y') AS data_solicitacao
FROM pedido_compra pc
ORDER BY pc.data_pedido, pc.produto_id;

SELECT
    CONCAT(pc.produto_id, ' - ', COALESCE(MAX(pc.descricao_produto), '')) AS produto,
    SUM(pc.qtde_pedida) AS qtde_requisitada,
    DATE_FORMAT(MIN(pc.data_pedido), '%d/%m/%Y') AS primeira_data_solicitacao
FROM pedido_compra pc
WHERE pc.data_pedido >= '2025-02-01'
  AND pc.data_pedido <  '2025-03-01'
GROUP BY pc.produto_id
HAVING SUM(pc.qtde_pedida) > 10
ORDER BY qtde_requisitada DESC;


