

import os
from pathlib import Path
import pandas as pd
import mysql.connector

ARQUIVO = Path(os.getenv("ARQUIVO_XLSX", "dados/base_teste.xlsx"))
DB = {
    "host": os.getenv("MYSQL_HOST", "localhost"),
    "port": int(os.getenv("MYSQL_PORT", "3306")),
    "database": os.getenv("MYSQL_DATABASE", "integracao_dados_entrega"),
    "user": os.getenv("MYSQL_USER", "root"),
    "password": os.getenv("MYSQL_PASSWORD", ""),
}


def valor(v):
    """Converte NaN/NaT para None e tipos numpy para tipos Python."""
    if pd.isna(v):
        return None
    if hasattr(v, "to_pydatetime"):
        return v.to_pydatetime().date()
    if hasattr(v, "item"):
        return v.item()
    return v


def texto(v):
    v = valor(v)
    return None if v is None else str(v).strip()


def data(v):
    v = valor(v)
    return None if v is None else pd.Timestamp(v).date()


def num(v, default=None):
    v = valor(v)
    return default if v is None else float(v)


def inteiro(v, default=None):
    v = valor(v)
    return default if v is None else int(v)


def importar(cursor, tabela, sql, linhas):
    total = 0
    for n, dados in enumerate(linhas, start=1):
        try:
            cursor.execute(sql, dados)
            total += cursor.rowcount if cursor.rowcount > 0 else 0
        except Exception as exc:
            raise RuntimeError(f"Erro na tabela {tabela}, registro {n}: {exc}") from exc
    print(f"{tabela}: {total} inserções novas (linhas processadas: {n if 'n' in locals() else 0})")


def main():
    if not ARQUIVO.exists():
        raise FileNotFoundError(f"Planilha não encontrada: {ARQUIVO.resolve()}")
    xls = pd.ExcelFile(ARQUIVO)
    esperadas = {"venda", "pedido_compra", "entradas_mercadoria", "produtos_filial", "fornecedor"}
    if not esperadas.issubset(set(xls.sheet_names)):
        raise ValueError(f"Abas ausentes: {esperadas - set(xls.sheet_names)}")

    conn = mysql.connector.connect(**DB)
    try:
        cur = conn.cursor()
   
        df = pd.read_excel(ARQUIVO, sheet_name="fornecedor")
        df.columns = df.columns.astype(str).str.strip()
        importar(cur, "fornecedor",
            "INSERT IGNORE INTO fornecedor (idfornecedor, razao_social) VALUES (%s,%s)",
            [(texto(r.idfornecedor), texto(r.razao_social)) for r in df.itertuples(index=False)])
        conn.commit()

       
        df = pd.read_excel(ARQUIVO, sheet_name="produtos_filial")
        df.columns = df.columns.astype(str).str.strip()
        importar(cur, "produtos_filial",
            "INSERT IGNORE INTO produtos_filial "
            "(filial_id,produto_id,descricao,estoque,preco_unitario,preco_compra,preco_venda,idfornecedor) "
            "VALUES (%s,%s,%s,%s,%s,%s,%s,%s)",
            [(inteiro(r.filial_id), texto(r.idproduto), texto(r.descricao), num(r.estoque,0),
              num(r.preco_unitario,0), num(r.preco_compra,0), num(r.preco_venda,0), texto(r.idfornecedor))
             for r in df.itertuples(index=False)])
        conn.commit()

        df_full = pd.read_excel(ARQUIVO, sheet_name="pedido_compra")
        extras = [c for c in df_full.columns if str(c).startswith("Unnamed:")]
        if extras and df_full[extras].notna().any().any():
            print("AVISO: pedido_compra contém bloco adicional sem cabeçalhos:", extras)
            print("       Essas células foram preservadas na planilha original e não importadas como campos válidos.")
        df = df_full.iloc[:, :12].copy()
        df.columns = [str(c).strip() for c in df.columns]
        linhas = []
        for r in df.itertuples(index=False):
            pendente = None if valor(r.qtde_pedida) is None else num(r.qtde_pedida,0) - num(r.qtde_entregue,0)
            fornecedor = texto(r.fornecedor_id)
            # IDs numéricos da planilha são associados aos códigos F1...F20.
            fornecedor = f"F{int(float(fornecedor))}" if fornecedor not in (None, "") else None
            linhas.append((inteiro(r.pedido_id), data(r.data_pedido), inteiro(r.item,0),
                texto(r.produto_id), texto(r.descricao_produto), inteiro(r.ordem_compra,0),
                num(r.qtde_pedida), inteiro(r.filial_id), data(r.data_entrega),
                num(r.qtde_entregue,0), pendente, num(r.preco_compra,0), fornecedor))
        importar(cur, "pedido_compra",
            "INSERT IGNORE INTO pedido_compra "
            "(pedido_id,data_pedido,item,produto_id,descricao_produto,ordem_compra,qtde_pedida,filial_id,"
            "data_entrega,qtde_entregue,qtde_pendente,preco_compra,fornecedor_id) "
            "VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)", linhas)
        conn.commit()

        df = pd.read_excel(ARQUIVO, sheet_name="entradas_mercadoria")
        df.columns = df.columns.astype(str).str.strip()
        importar(cur, "entradas_mercadoria",
            "INSERT IGNORE INTO entradas_mercadoria "
            "(ordem_compra,data_entrada,nro_nfe,item,produto_id,descricao_produto,qtde_recebida,filial_id,custo_unitario) "
            "VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)",
            [(inteiro(r.ordem_compra), data(r.data_entrada), texto(r.nro_nfe), inteiro(r.item,0),
              texto(r.produto_id), texto(r.descricao_produto), num(r.qtde_recebida),
              inteiro(r.filial_id), num(r.custo_unitario,0)) for r in df.itertuples(index=False)])
        conn.commit()

  
        df = pd.read_excel(ARQUIVO, sheet_name="venda")
        df.columns = df.columns.astype(str).str.strip()
        importar(cur, "venda",
            "INSERT IGNORE INTO venda "
            "(venda_id,data_emissao,horariomov,produto_id,qtde_vendida,valor_unitario,filial_id,item,unidade_medida) "
            "VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)",
            [(inteiro(r.venda_id), data(r.data_emissao), texto(r.horariomov) or "00:00:00",
              texto(r.produto_id), num(r.qtde_vendida), num(r.valor_unitario,0),
              inteiro(r.filial_id,1), inteiro(r.item,0), texto(r.unidade_medida))
             for r in df.itertuples(index=False)])
        conn.commit()

        print("\nContagem final no MySQL:")
        for tabela in ["fornecedor", "produtos_filial", "pedido_compra", "entradas_mercadoria", "venda"]:
            cur.execute(f"SELECT COUNT(*) FROM {tabela}")
            print(f"  {tabela}: {cur.fetchone()[0]}")
        cur.close()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()
