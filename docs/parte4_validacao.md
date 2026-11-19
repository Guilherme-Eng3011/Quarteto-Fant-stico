
# Parte 4 — Roteiro de validação com o cliente

## Objetivo e escopo

Validar os dados de vendas de **01/02/2025 a 28/02/2025**, além das relações entre vendas, produtos, pedidos de compra, entradas de mercadoria e fornecedores. A reunião deve separar divergências efetivamente observadas de hipóteses que dependem de confirmação do cliente.

## Roteiro da reunião

1. **Confirmar o escopo:** filial(is), período, moeda, política de devoluções/cancelamentos e se o valor de venda é `qtde_vendida × valor_unitario`.
2. **Validar vendas:** comparar quantidade de documentos/linhas, unidades vendidas e faturamento total por produto e filial com o relatório operacional/PDV do cliente.
3. **Validar cadastro:** confirmar os produtos vendidos que não aparecem no cadastro `produtos_filial`, especialmente P22 a P27 nas vendas de fevereiro.
4. **Validar compras e recebimentos:** confirmar que `ordem_compra` identifica unicamente o vínculo entre pedido e entrada; revisar pedidos com ordem zero, notas sem pedido correspondente e divergências de quantidade recebida.
5. **Validar cronologia:** confirmar datas de pedido e entrega anteriores à solicitação, pois podem indicar erro de digitação, carga ou regra de negócio.
6. **Validar fornecedores:** confirmar a equivalência entre `fornecedor_id` numérico da aba de pedidos e os códigos textuais `F1`...`F20` da aba fornecedor.
7. **Aprovar exceções:** registrar responsável, evidência, decisão do cliente e prazo para cada divergência. Não corrigir valores ambíguos sem autorização.

## Técnicas de exatidão e precisão

- Reconciliação de totais: somar quantidade e valor no banco e comparar com o relatório fonte do PDV para o mesmo período e filial.
- Contagem de linhas por aba antes/depois da importação e verificação das chaves primárias.
- Conferência de domínio: datas válidas, quantidades não negativas, preços numéricos, códigos de produto/fornecedor existentes.
- Integridade referencial lógica: `entradas_mercadoria.ordem_compra` contra `pedido_compra.ordem_compra`; produto/filial contra cadastro; fornecedor contra cadastro.
- Amostragem rastreável: selecionar transações e conferir documento, data, produto, quantidade e preço contra NF/PDV.
- Testes de duplicidade, nulos, valores extremos e datas fora de sequência.
- Registro de divergências e aprovação formal do cliente antes de qualquer correção dos dados de origem.

## Erros e inconsistências observados na planilha

1. **Bloco de colunas extras em `pedido_compra`:** existem 11 colunas sem cabeçalho (`Unnamed: 12`...`Unnamed: 22`), com valores nas últimas 9 linhas. Não há definição confiável para importar esse bloco como colunas; solicitar esclarecimento ao cliente.
2. **`ordem_compra = 0` em 11 pedidos** (pedido_id 19 a 29). Zero não identifica uma ordem válida e impede conciliação; os registros com pedido_id 19 e 20 também deixam as entradas 19 e 20 sem correspondência pelo número da ordem.
3. **Datas de entrega anteriores às datas de pedido:** 20 linhas da aba `pedido_compra` apresentam `data_entrega < data_pedido`. Confirmar se datas foram invertidas ou se representam outra data operacional.
4. **Divergência entre `qtde_entregue` no pedido e a soma das entradas:** para as ordens 1 a 18, os valores não coincidem. É necessário confirmar qual fonte é a referência oficial e se `qtde_entregue` é saldo acumulado ou quantidade de uma remessa.
5. **Entradas sem pedido correspondente:** as entradas associadas às ordens 19 e 20 não encontram pedido correspondente, pois os pedidos correspondentes estão com `ordem_compra = 0`.
6. **Produtos vendidos sem cadastro em `produtos_filial`:** na filial 1, as vendas de fevereiro incluem P22, P23, P24, P25, P26 e P27, ausentes do cadastro de produtos fornecido.
7. **Inconsistência de nomenclatura/estrutura no DDL (não é erro de valor da planilha):** `ordem_compra` ausente na definição de entradas apesar de usada na PK; `idproduto`/`produto_id`, `decricao`/`descricao`, `idfonecedor`/`idfornecedor` e `idforncedor`/`idfornecedor` divergentes; PK de fornecedor referenciava coluna inexistente `idproduto`.
8. **Incompatibilidade do importador original com MySQL (não é erro da planilha):** usa driver e sintaxe PostgreSQL, e não protege credenciais por variável de ambiente.

As inconsistências acima não devem ser corrigidas por suposição. O cliente precisa confirmar os valores corretos, em especial para ordem de compra zero, datas invertidas, quantidades e bloco extra.

## Consultas de apoio

As consultas prontas para a reunião estão em `sql/04_validacao.sql`. Elas cobrem resumo e detalhe de vendas de fevereiro, produtos sem cadastro, ordens zero, entradas órfãs, datas invertidas, divergência de quantidades, fornecedor sem correspondência e contagens por tabela.

## Resultado conhecido a partir do arquivo Excel (referência para conferência)

A planilha contém 33 vendas no total, das quais 14 são de fevereiro/2025. Nesse mês, a soma das quantidades vendidas é **173,22** e o valor bruto calculado por quantidade × preço unitário é **R$ 14.093,17**. Esse total deve ser comparado com o resultado do MySQL; diferenças devem ser investigadas, não ajustadas automaticamente.
