
CREATE SCHEMA IF NOT EXISTS public;

CREATE TABLE IF NOT EXISTS public.fornecedor (
  idfornecedor VARCHAR(25) PRIMARY KEY,
  razao_social VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.produtos_filial (
  filial_id INTEGER NOT NULL,
  produto_id VARCHAR(25) NOT NULL,
  descricao VARCHAR(255) NOT NULL,
  estoque DOUBLE PRECISION NOT NULL DEFAULT 0,
  preco_unitario NUMERIC(12,4) NOT NULL DEFAULT 0,
  preco_compra NUMERIC(12,4) NOT NULL DEFAULT 0,
  preco_venda NUMERIC(12,4) NOT NULL DEFAULT 0,
  idfornecedor VARCHAR(25),
  PRIMARY KEY (filial_id, produto_id),
  CONSTRAINT fk_produtos_fornecedor FOREIGN KEY (idfornecedor)
    REFERENCES public.fornecedor(idfornecedor)
);

CREATE TABLE IF NOT EXISTS public.pedido_compra (
  pedido_id BIGINT NOT NULL,
  data_pedido DATE,
  item INTEGER NOT NULL DEFAULT 0,
  produto_id VARCHAR(25) NOT NULL,
  descricao_produto VARCHAR(255),
  ordem_compra BIGINT NOT NULL,
  qtde_pedida DOUBLE PRECISION,
  filial_id INTEGER,
  data_entrega DATE,
  qtde_entregue DOUBLE PRECISION NOT NULL DEFAULT 0,
  qtde_pendente DOUBLE PRECISION NOT NULL DEFAULT 0,
  preco_compra NUMERIC(12,4) DEFAULT 0,
  fornecedor_id VARCHAR(25),
  PRIMARY KEY (pedido_id, produto_id, item)
);
CREATE INDEX IF NOT EXISTS ix_pedido_ordem ON public.pedido_compra(ordem_compra);
CREATE INDEX IF NOT EXISTS ix_pedido_produto_data ON public.pedido_compra(produto_id, data_pedido);

CREATE TABLE IF NOT EXISTS public.entradas_mercadoria (
  ordem_compra BIGINT NOT NULL,
  data_entrada DATE,
  nro_nfe VARCHAR(255) NOT NULL,
  item INTEGER NOT NULL DEFAULT 0,
  produto_id VARCHAR(25) NOT NULL,
  descricao_produto VARCHAR(255),
  qtde_recebida DOUBLE PRECISION,
  filial_id INTEGER,
  custo_unitario NUMERIC(12,4) NOT NULL DEFAULT 0,
  PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe)
);

CREATE TABLE IF NOT EXISTS public.venda (
  venda_id BIGINT NOT NULL,
  data_emissao DATE NOT NULL,
  horariomov VARCHAR(8) NOT NULL DEFAULT '00:00:00',
  produto_id VARCHAR(25) NOT NULL DEFAULT '',
  qtde_vendida DOUBLE PRECISION,
  valor_unitario NUMERIC(12,4) NOT NULL DEFAULT 0,
  filial_id BIGINT NOT NULL DEFAULT 1,
  item INTEGER NOT NULL DEFAULT 0,
  unidade_medida VARCHAR(3),
  PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
);
CREATE INDEX IF NOT EXISTS ix_venda_data_produto ON public.venda(data_emissao, produto_id);

CREATE OR REPLACE FUNCTION public.fn_produtos_gera_fornecedor()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE novo_id BIGINT;
BEGIN
  IF NEW.idfornecedor IS NULL OR BTRIM(NEW.idfornecedor) = '' THEN
    SELECT COALESCE(MAX(idfornecedor::BIGINT), 0) + 1
      INTO novo_id FROM public.fornecedor
      WHERE idfornecedor ~ '^[0-9]+$';
    INSERT INTO public.fornecedor(idfornecedor, razao_social)
      VALUES (novo_id::TEXT, 'Fornecedor gerado automaticamente ' || novo_id);
    NEW.idfornecedor := novo_id::TEXT;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_produtos_gera_fornecedor ON public.produtos_filial;
CREATE TRIGGER trg_produtos_gera_fornecedor
BEFORE INSERT ON public.produtos_filial
FOR EACH ROW EXECUTE FUNCTION public.fn_produtos_gera_fornecedor();
