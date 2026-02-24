<?php
// config/db.php
// Edite as credenciais antes de usar em produção

define('DB_HOST',    'localhost');
define('DB_PORT',    '3306');
define('DB_NAME',    'pawfectshop');
define('DB_USER',    'root');        // troque pelo seu usuário MySQL
define('DB_PASS',    '');            // troque pela sua senha MySQL
define('DB_CHARSET', 'utf8mb4');

function getDB(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = sprintf(
            'mysql:host=%s;port=%s;dbname=%s;charset=%s',
            DB_HOST, DB_PORT, DB_NAME, DB_CHARSET
        );
        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ];
        $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
    }
    return $pdo;
}