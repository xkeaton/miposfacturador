<?php
 
class Conexion{
 
    static public function conectar(){
        try {
            // Detectar si el host es local (localhost, 127.0.0.1, o IP local de red)
            $isLocalhost = false;
            if (isset($_SERVER['HTTP_HOST'])) {
                $host = $_SERVER['HTTP_HOST'];
                if ($host === 'localhost' || $host === '127.0.0.1' || substr($host, 0, 8) === '192.168.') {
                    $isLocalhost = true;
                }
            } else {
                // Si se ejecuta por consola (CLI) y no es el hostname del VPS
                $isLocalhost = (php_sapi_name() === 'cli' && gethostname() !== 'srv1762234');
            }
 
            if ($isLocalhost) {
                // Configuración para Localhost
                $conn = new PDO("mysql:host=localhost;dbname=miposfacturador", "root", "", array(PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8"));
            } else {
                // Configuración para el VPS (Producción)
                
                //$conn = new PDO("mysql:host=localhost;dbname=tutoria3_mitiendaposfacturador", "tutoria3_tutorialesphperu", "Rafael0701$", array(PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8"));
                $conn = new PDO("mysql:host=localhost;dbname=miposfacturador", "if0_42199398", "N63hgtzqvmy", array(PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8"));
            }
            return $conn;
        }
        catch (PDOException $e) {
            error_log('Falló la conexión de base de datos: ' . $e->getMessage());
            return null;
        }
    }
}
