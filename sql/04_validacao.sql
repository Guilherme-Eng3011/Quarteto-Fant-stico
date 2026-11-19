

USE integracao_dados_entrega;


SELECT COUNT(*) AS linhas_venda,
       SUM(qtde_vendida) AS quantidade_total,
       ROUND(SUM(qtde_vendida * valor_unitario), 2) AS valor_total
FROM venda
WHERE data_emissao >= '2025-02-01' AND data_emissao < '2025-03-01';


SELECT produto_id, SUM(qtde_vendida) AS quantidade,
       ROUND(SUM(qtde_vendida * valor_unitario), 2) AS valor_total
FROM venda
WHERE data_emissao >= '2025-02-01' AND data_emissao < '2025-03-01'
GROUP BY produto_id ORDER BY produto_id;


SELECT v.* FROM venda v
LEFT JOIN produtos_filial p ON p.produto_id = v.produto_id AND p.filial_id = v.filial_id
WHERE v.data_emissao >= '2025-02-01' AND v.data_emissao < '2025-03-01'
  AND p.produto_id IS NULL;


SELECT pedido_id, produto_id, data_pedido, ordem_compra, qtde_pedida, qtde_entregue
FROM pedido_compra WHERE ordem_compra IS NULL OR ordem_compra = 0;


SELECT em.* FROM entradas_mercadoria em
LEFT JOIN pedido_compra pc
  ON pc.ordem_compra = em.ordem_compra AND pc.produto_id = em.produto_id
WHERE pc.pedido_id IS NULL;


SELECT pedido_id, produto_id, data_pedido, data_entrega
FROM pedido_compra
WHERE data_pedido IS NOT NULL AND data_entrega IS NOT NULL
  AND data_entrega < data_pedido;


SELECT pc.pedido_id, pc.ordem_compra, pc.produto_id,
       pc.qtde_entregue AS qtde_entregue_pedido,
       COALESCE(SUM(em.qtde_recebida), 0) AS qtde_somada_nas_entradas
FROM pedido_compra pc
LEFT JOIN entradas_mercadoria em
  ON em.ordem_compra = pc.ordem_compra AND em.produto_id = pc.produto_id
WHERE pc.ordem_compra <> 0
GROUP BY pc.pedido_id, pc.ordem_compra, pc.produto_id, pc.qtde_entregue
HAVING pc.qtde_entregue <> COALESCE(SUM(em.qtde_recebida), 0);


SELECT pedido_id, produto_id, ordem_compra, qtde_pedida, qtde_entregue
FROM pedido_compra WHERE ordem_compra = 0;


SELECT p.* FROM produtos_filial p
LEFT JOIN fornecedor f ON f.idfornecedor = p.idfornecedor
WHERE p.idfornecedor IS NOT NULL AND f.idfornecedor IS NULL;


SELECT 'fornecedor' tabela, COUNT(*) total FROM fornecedor
UNION ALL SELECT 'produtos_filial', COUNT(*) FROM produtos_filial
UNION ALL SELECT 'pedido_compra', COUNT(*) FROM pedido_compra
UNION ALL SELECT 'entradas_mercadoria', COUNT(*) FROM entradas_mercadoria
UNION ALL SELECT 'venda', COUNT(*) FROM venda;
