<?php

class Rutas{

    static public function RutaProyecto(){
        $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off' || (isset($_SERVER['SERVER_PORT']) && $_SERVER['SERVER_PORT'] == 443)) ? "https://" : "http://";
        $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
        if ($host === 'localhost' || $host === '127.0.0.1' || strpos($host, '192.168.') === 0 || strpos($host, '10.0.') === 0) {
            return $protocol . $host . "/miposfacturador/";
        } else {
            return $protocol . $host . "/";
        }
    }

}

?>
