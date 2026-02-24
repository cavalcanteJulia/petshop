<?php
// api/produtos.php
// Endpoints REST simples para o PawfectShop

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

require_once __DIR__ . '/../config/db.php';

$method = $_SERVER['REQUEST_METHOD'];
$path   = trim($_GET['action'] ?? '', '/');

// ── Roteamento simples ──────────────────────────────────────
try {
    match (true) {
        // GET /api/produtos.php?action=produtos
        $method === 'GET'  && $path === 'produtos'   => listaProdutos(),

        // GET /api/produtos.php?action=produtos&categoria=alimentacao
        $method === 'GET'  && $path === 'produtos' && !empty($_GET['categoria']) => listaProdutos($_GET['categoria']),

        // GET /api/produtos.php?action=produto&id=1
        $method === 'GET'  && $path === 'produto'    => getProduto((int)($_GET['id'] ?? 0)),

        // POST /api/produtos.php?action=newsletter
        $method === 'POST' && $path === 'newsletter' => cadastrarNewsletter(),

        // POST /api/produtos.php?action=pedido
        $method === 'POST' && $path === 'pedido'     => criarPedido(),

        default => resposta(404, ['erro' => 'Endpoint não encontrado'])
    };
} catch (Throwable $e) {
    resposta(500, ['erro' => 'Erro interno', 'detalhe' => $e->getMessage()]);
}


// ── Funções ─────────────────────────────────────────────────

function listaProdutos(string $categoria = ''): void {
    $db  = getDB();
    $sql = 'SELECT * FROM vw_produtos';
    $params = [];

    if ($categoria !== '') {
        $sql    .= ' WHERE categoria_slug = ?';
        $params[] = $categoria;
    }

    $sql .= ' ORDER BY id';
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $produtos = $stmt->fetchAll();

    // Formata preço para exibição
    foreach ($produtos as &$p) {
        $p['preco_formatado'] = 'R$ ' . number_format($p['preco'], 2, ',', '.');
    }

    resposta(200, ['produtos' => $produtos, 'total' => count($produtos)]);
}

function getProduto(int $id): void {
    if ($id <= 0) { resposta(400, ['erro' => 'ID inválido']); return; }

    $db   = getDB();
    $stmt = $db->prepare('SELECT * FROM vw_produtos WHERE id = ?');
    $stmt->execute([$id]);
    $produto = $stmt->fetch();

    if (!$produto) { resposta(404, ['erro' => 'Produto não encontrado']); return; }

    $produto['preco_formatado'] = 'R$ ' . number_format($produto['preco'], 2, ',', '.');
    resposta(200, ['produto' => $produto]);
}

function cadastrarNewsletter(): void {
    $body  = json_decode(file_get_contents('php://input'), true);
    $email = trim($body['email'] ?? '');

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        resposta(400, ['erro' => 'E-mail inválido']);
        return;
    }

    $db = getDB();
    try {
        $db->prepare('INSERT INTO newsletter (email) VALUES (?)')
           ->execute([$email]);
        resposta(201, ['mensagem' => 'Cadastro realizado! Seu desconto de 10% foi enviado.']);
    } catch (PDOException $e) {
        // Email já cadastrado (unique constraint)
        if ($e->getCode() === '23000') {
            resposta(409, ['erro' => 'E-mail já cadastrado']);
        } else {
            throw $e;
        }
    }
}

function criarPedido(): void {
    $body = json_decode(file_get_contents('php://input'), true);

    $clienteId = (int)($body['cliente_id'] ?? 0);
    $itens     = $body['itens'] ?? [];

    if ($clienteId <= 0 || empty($itens)) {
        resposta(400, ['erro' => 'Dados incompletos']);
        return;
    }

    $db = getDB();
    $db->beginTransaction();

    try {
        $total = 0;

        // Valida cada item e calcula total
        $detalhes = [];
        foreach ($itens as $item) {
            $prodId = (int)($item['produto_id'] ?? 0);
            $qtd    = (int)($item['quantidade'] ?? 0);

            if ($prodId <= 0 || $qtd <= 0) continue;

            $stmt = $db->prepare('SELECT id, nome, preco, estoque FROM produtos WHERE id = ? AND ativo = 1');
            $stmt->execute([$prodId]);
            $produto = $stmt->fetch();

            if (!$produto) {
                $db->rollBack();
                resposta(400, ['erro' => "Produto ID $prodId não encontrado"]);
                return;
            }

            if ($produto['estoque'] < $qtd) {
                $db->rollBack();
                resposta(400, ['erro' => "Estoque insuficiente para {$produto['nome']}"]);
                return;
            }

            $total += $produto['preco'] * $qtd;
            $detalhes[] = ['produto' => $produto, 'quantidade' => $qtd];
        }

        // Cria pedido
        $db->prepare('INSERT INTO pedidos (cliente_id, total) VALUES (?, ?)')
           ->execute([$clienteId, $total]);
        $pedidoId = (int)$db->lastInsertId();

        // Insere itens e baixa estoque
        foreach ($detalhes as $d) {
            $db->prepare('INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario) VALUES (?, ?, ?, ?)')
               ->execute([$pedidoId, $d['produto']['id'], $d['quantidade'], $d['produto']['preco']]);

            $db->prepare('UPDATE produtos SET estoque = estoque - ? WHERE id = ?')
               ->execute([$d['quantidade'], $d['produto']['id']]);
        }

        $db->commit();
        resposta(201, [
            'mensagem'  => 'Pedido criado com sucesso!',
            'pedido_id' => $pedidoId,
            'total'     => 'R$ ' . number_format($total, 2, ',', '.')
        ]);

    } catch (Throwable $e) {
        $db->rollBack();
        throw $e;
    }
}

// ── Helper ──────────────────────────────────────────────────
function resposta(int $status, array $dados): void {
    http_response_code($status);
    echo json_encode($dados, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}