-- ============================================================
--  PawfectShop — Banco de Dados MySQL
--  Versão: 1.0
-- ============================================================

CREATE DATABASE IF NOT EXISTS pawfectshop
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE pawfectshop;

-- ------------------------------------------------------------
-- CATEGORIAS
-- ------------------------------------------------------------
CREATE TABLE categorias (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  slug        VARCHAR(50)  NOT NULL UNIQUE,          -- 'alimentacao', 'brinquedos', 'higiene'
  nome        VARCHAR(100) NOT NULL,
  icone       VARCHAR(100),                          -- nome do SVG / emoji
  criado_em   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO categorias (slug, nome, icone) VALUES
  ('alimentacao', 'Alimentação',    'fork-knife'),
  ('brinquedos',  'Brinquedos',     'smiley'),
  ('higiene',     'Higiene & Beleza','sparkle');


-- ------------------------------------------------------------
-- PRODUTOS
-- ------------------------------------------------------------
CREATE TABLE produtos (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  categoria_id  INT UNSIGNED NOT NULL,
  nome          VARCHAR(150) NOT NULL,
  descricao     TEXT,
  preco         DECIMAL(10,2) NOT NULL,
  estoque       INT UNSIGNED NOT NULL DEFAULT 0,
  imagem_url    VARCHAR(500),
  ativo         TINYINT(1) NOT NULL DEFAULT 1,
  criado_em     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (categoria_id) REFERENCES categorias(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  INDEX idx_categoria (categoria_id),
  INDEX idx_ativo     (ativo)
) ENGINE=InnoDB;

INSERT INTO produtos (categoria_id, nome, descricao, preco, estoque, imagem_url) VALUES
  -- ALIMENTAÇÃO (id=1)
  (1, 'Ração Premium para Cães',   'Nutrição de alta qualidade para seu melhor amigo',   45.99, 100, 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=500&q=80'),
  (1, 'Ração Orgânica para Gatos', 'Nutrição saudável e natural para gatos',             38.99,  80, 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=500&q=80'),
  (1, 'Petiscos de Treinamento',   'Recompensas perfeitas para treinos',                 15.99, 200, 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=500&q=80'),

  -- BRINQUEDOS (id=2)
  (2, 'Arranhador para Gatos',     'Proteja seus móveis com este arranhador durável',    32.99,  50, 'https://images.unsplash.com/photo-1518155317743-a8ff43ea6a5f?w=500&q=80'),
  (2, 'Brinquedo Interativo Cães', 'Horas de diversão para cães ativos',                 24.99,  60, 'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=500&q=80'),
  (2, 'Varinha com Penas Gatos',   'Diversão interativa para seu felino',                12.99,  90, 'https://images.unsplash.com/photo-1518155317743-a8ff43ea6a5f?w=500&q=80'),
  (2, 'Coleira Premium + Guia',    'Design ergonômico e resistente',                     49.90,  40, 'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=500&q=80'),

  -- HIGIENE (id=3)
  (3, 'Kit de Higiene Completo',   'Solução completa de higiene para todos os pets',     59.99,  35, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=500&q=80'),
  (3, 'Shampoo Natural Premium',   'Limpeza suave e eficaz para todos os pets',          28.99,  70, 'https://images.unsplash.com/photo-1559715541-5daf8a0296d0?w=500&q=80');


-- ------------------------------------------------------------
-- CLIENTES
-- ------------------------------------------------------------
CREATE TABLE clientes (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome          VARCHAR(150) NOT NULL,
  email         VARCHAR(200) NOT NULL UNIQUE,
  senha_hash    VARCHAR(255) NOT NULL,
  telefone      VARCHAR(20),
  criado_em     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_email (email)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- ENDEREÇOS
-- ------------------------------------------------------------
CREATE TABLE enderecos (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cliente_id    INT UNSIGNED NOT NULL,
  logradouro    VARCHAR(200) NOT NULL,
  numero        VARCHAR(20)  NOT NULL,
  complemento   VARCHAR(100),
  bairro        VARCHAR(100) NOT NULL,
  cidade        VARCHAR(100) NOT NULL,
  estado        CHAR(2)      NOT NULL,
  cep           CHAR(9)      NOT NULL,
  principal     TINYINT(1)   NOT NULL DEFAULT 0,

  FOREIGN KEY (cliente_id) REFERENCES clientes(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- PEDIDOS
-- ------------------------------------------------------------
CREATE TABLE pedidos (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cliente_id    INT UNSIGNED NOT NULL,
  endereco_id   INT UNSIGNED,
  status        ENUM('pendente','pago','enviado','entregue','cancelado') NOT NULL DEFAULT 'pendente',
  total         DECIMAL(10,2) NOT NULL,
  frete         DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  desconto      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  criado_em     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (cliente_id)  REFERENCES clientes(id)  ON DELETE RESTRICT,
  FOREIGN KEY (endereco_id) REFERENCES enderecos(id) ON DELETE SET NULL,

  INDEX idx_cliente (cliente_id),
  INDEX idx_status  (status)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- ITENS DO PEDIDO
-- ------------------------------------------------------------
CREATE TABLE itens_pedido (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id     INT UNSIGNED NOT NULL,
  produto_id    INT UNSIGNED NOT NULL,
  quantidade    INT UNSIGNED NOT NULL,
  preco_unitario DECIMAL(10,2) NOT NULL,   -- preço no momento da compra

  FOREIGN KEY (pedido_id)  REFERENCES pedidos(id)  ON DELETE CASCADE,
  FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE RESTRICT,

  INDEX idx_pedido  (pedido_id),
  INDEX idx_produto (produto_id)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- NEWSLETTER
-- ------------------------------------------------------------
CREATE TABLE newsletter (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email      VARCHAR(200) NOT NULL UNIQUE,
  ativo      TINYINT(1)   NOT NULL DEFAULT 1,
  criado_em  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_email (email)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- VIEWS ÚTEIS
-- ------------------------------------------------------------

-- Produtos com nome da categoria
CREATE OR REPLACE VIEW vw_produtos AS
SELECT
  p.id,
  p.nome,
  p.descricao,
  p.preco,
  p.estoque,
  p.imagem_url,
  p.ativo,
  c.slug  AS categoria_slug,
  c.nome  AS categoria_nome
FROM produtos p
JOIN categorias c ON c.id = p.categoria_id
WHERE p.ativo = 1;

-- Resumo de pedidos por cliente
CREATE OR REPLACE VIEW vw_resumo_pedidos AS
SELECT
  p.id          AS pedido_id,
  p.status,
  p.total,
  p.criado_em,
  cl.nome       AS cliente_nome,
  cl.email      AS cliente_email,
  COUNT(ip.id)  AS qtd_itens
FROM pedidos p
JOIN clientes cl ON cl.id = p.cliente_id
JOIN itens_pedido ip ON ip.pedido_id = p.id
GROUP BY p.id, p.status, p.total, p.criado_em, cl.nome, cl.email;