
USE integracao_dados_entrega;


SELECT
    produto_id,
    SUM(qtde_vendida) AS quantidade_vendida,
    ROUND(SUM(qtde_vendida * valor_unitario), 2) AS valor_total_vendido
FROM venda
WHERE data_emissao >= '2025-02-01'
  AND data_emissao <  '2025-03-01'
GROUP BY produto_id
ORDER BY produto_id;

SELECT
    pc.pedido_id,
    pc.ordem_compra,
    pc.produto_id,
    pc.descricao_produto,
    pc.qtde_pedida,
    COALESCE(SUM(em.qtde_recebida), 0) AS total_recebido,
    GREATEST(pc.qtde_pedida - COALESCE(SUM(em.qtde_recebida), 0), 0) AS saldo_nao_recebido
FROM pedido_compra pc
LEFT JOIN entradas_mercadoria em
       ON em.ordem_compra = pc.ordem_compra
      AND em.produto_id = pc.produto_id
WHERE pc.ordem_compra <> 0
GROUP BY pc.pedido_id, pc.ordem_compra, pc.produto_id,
         pc.descricao_produto, pc.qtde_pedida
HAVING COALESCE(SUM(em.qtde_recebida), 0) < pc.qtde_pedida
ORDER BY pc.pedido_id;
