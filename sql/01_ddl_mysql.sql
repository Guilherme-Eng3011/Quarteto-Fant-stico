
CREATE DATABASE IF NOT EXISTS integracao_dados_entrega
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE integracao_dados_entrega;

CREATE TABLE fornecedor (
  idfornecedor VARCHAR(25) NOT NULL,
  razao_social VARCHAR(255) NOT NULL,
  PRIMARY KEY (idfornecedor)
) ENGINE=InnoDB;

CREATE TABLE produtos_filial (
  filial_id INT NOT NULL,
  produto_id VARCHAR(25) NOT NULL,
  descricao VARCHAR(255) NOT NULL,
  estoque DOUBLE NOT NULL DEFAULT 0,
  preco_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,
  preco_compra DECIMAL(12,4) NOT NULL DEFAULT 0,
  preco_venda DECIMAL(12,4) NOT NULL DEFAULT 0,
  idfornecedor VARCHAR(25) NULL,
  PRIMARY KEY (filial_id, produto_id),
  CONSTRAINT fk_produtos_fornecedor FOREIGN KEY (idfornecedor)
    REFERENCES fornecedor(idfornecedor)
) ENGINE=InnoDB;

CREATE TABLE pedido_compra (
  pedido_id BIGINT NOT NULL,
  data_pedido DATE NULL,
  item INT NOT NULL DEFAULT 0,
  produto_id VARCHAR(25) NOT NULL,
  descricao_produto VARCHAR(255) NULL,
  ordem_compra BIGINT NOT NULL,
  qtde_pedida DOUBLE NULL,
  filial_id INT NULL,
  data_entrega DATE NULL,
  qtde_entregue DOUBLE NOT NULL DEFAULT 0,
  qtde_pendente DOUBLE NOT NULL DEFAULT 0,
  preco_compra DECIMAL(12,4) NULL DEFAULT 0,
  fornecedor_id VARCHAR(25) NULL,
  PRIMARY KEY (pedido_id, produto_id, item),
  KEY ix_pedido_ordem (ordem_compra),
  KEY ix_pedido_produto_data (produto_id, data_pedido)
) ENGINE=InnoDB;

CREATE TABLE entradas_mercadoria (
  ordem_compra BIGINT NOT NULL,
  data_entrada DATE NULL,
  nro_nfe VARCHAR(255) NOT NULL,
  item INT NOT NULL DEFAULT 0,
  produto_id VARCHAR(25) NOT NULL,
  descricao_produto VARCHAR(255) NULL,
  qtde_recebida DOUBLE NULL,
  filial_id INT NULL,
  custo_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,
  PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe),
  KEY ix_entrada_data (data_entrada)
) ENGINE=InnoDB;

CREATE TABLE venda (
  venda_id BIGINT NOT NULL,
  data_emissao DATE NOT NULL,
  horariomov VARCHAR(8) NOT NULL DEFAULT '00:00:00',
  produto_id VARCHAR(25) NOT NULL DEFAULT '',
  qtde_vendida DOUBLE NULL,
  valor_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,
  filial_id BIGINT NOT NULL DEFAULT 1,
  item INT NOT NULL DEFAULT 0,
  unidade_medida VARCHAR(3) NULL,
  PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov),
  KEY ix_venda_data_produto (data_emissao, produto_id)
) ENGINE=InnoDB;


DELIMITER $$
CREATE TRIGGER trg_produtos_gera_fornecedor
BEFORE INSERT ON produtos_filial
FOR EACH ROW
BEGIN
  DECLARE novo_id BIGINT;
  IF NEW.idfornecedor IS NULL OR TRIM(NEW.idfornecedor) = '' THEN
    SELECT COALESCE(MAX(CAST(idfornecedor AS UNSIGNED)), 0) + 1
      INTO novo_id
      FROM fornecedor
      WHERE idfornecedor REGEXP '^[0-9]+$';
    INSERT INTO fornecedor (idfornecedor, razao_social)
      VALUES (CAST(novo_id AS CHAR), CONCAT('Fornecedor gerado automaticamente ', novo_id));
    SET NEW.idfornecedor = CAST(novo_id AS CHAR);
  END IF;
END$$
DELIMITER ;
