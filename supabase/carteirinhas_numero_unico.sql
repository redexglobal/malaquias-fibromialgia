-- ============================================================
-- CARTEIRINHAS — Número ÚNICO e sequencial garantido pelo banco
-- Rodar 1x (idempotente). Cada carteirinha gerada (por QUALQUER admin ou
-- colaborador) recebe um número único sequencial: FIB-00001, DC-00002, ...
-- O "id" (uuid) já era único — este é o número legível p/ busca futura.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS carteirinhas_num_seq;

CREATE OR REPLACE FUNCTION carteirinhas_set_numero()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  -- número sequencial único, com prefixo do tipo (atribuído pelo banco, à prova de erro)
  NEW.numero := CASE WHEN NEW.tipo = 'cronicas' THEN 'DC-' ELSE 'FIB-' END
                || lpad(nextval('carteirinhas_num_seq')::text, 5, '0');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_carteirinhas_numero ON carteirinhas;
CREATE TRIGGER trg_carteirinhas_numero
  BEFORE INSERT ON carteirinhas
  FOR EACH ROW EXECUTE FUNCTION carteirinhas_set_numero();

-- Garante que nunca haja dois números iguais
CREATE UNIQUE INDEX IF NOT EXISTS idx_carteirinhas_numero_uniq ON carteirinhas (numero);
