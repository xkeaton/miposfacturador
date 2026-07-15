<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

echo "<h2>Diagnostic Test for POS System</h2>";

echo "<h3>1. Testing Session:</h3>";
session_start();
if (!isset($_SESSION["usuario"])) {
    echo "<span style='color:orange;'>Warning:</span> Session 'usuario' is not set. Creating dummy user ID = 1 for testing...<br>";
    $user = new stdClass();
    $user->id_usuario = 1;
    $_SESSION["usuario"] = $user;
} else {
    echo "Session user ID: " . $_SESSION["usuario"]->id_usuario . "<br>";
}

echo "<h3>2. Testing vendor autoload:</h3>";
if (file_exists("vendor/autoload.php")) {
    echo "<span style='color:green;'>SUCCESS:</span> vendor/autoload.php exists!<br>";
    require_once "vendor/autoload.php";
    echo "vendor/autoload.php loaded successfully!<br>";
} else {
    echo "<span style='color:red;'>ERROR:</span> vendor/autoload.php does not exist!<br>";
}

echo "<h3>3. Testing modelos/arqueo_caja.modelo.php:</h3>";
if (file_exists("modelos/arqueo_caja.modelo.php")) {
    echo "<span style='color:green;'>SUCCESS:</span> modelos/arqueo_caja.modelo.php exists!<br>";
    require_once "modelos/arqueo_caja.modelo.php";
    echo "modelos/arqueo_caja.modelo.php loaded successfully!<br>";
} else {
    echo "<span style='color:red;'>ERROR:</span> modelos/arqueo_caja.modelo.php does not exist!<br>";
}

echo "<h3>4. Testing database connection:</h3>";
if (file_exists("modelos/conexion.php")) {
    require_once "modelos/conexion.php";
    try {
        $db = Conexion::conectar();
        if ($db) {
            echo "<span style='color:green;'>SUCCESS:</span> Connected to database successfully!<br>";
        } else {
            echo "<span style='color:red;'>ERROR:</span> Connection returned null/false.<br>";
        }
    } catch (Exception $e) {
        echo "<span style='color:red;'>ERROR:</span> DB Connection failed: " . $e->getMessage() . "<br>";
    }
} else {
    echo "<span style='color:red;'>ERROR:</span> modelos/conexion.php does not exist!<br>";
}

echo "<h3>5. Executing ArqueoCajaModelo::mdlObtenerArqueoPorDia():</h3>";
try {
    $res = ArqueoCajaModelo::mdlObtenerArqueoPorDia();
    echo "<span style='color:green;'>SUCCESS:</span> Method executed correctly! Result:<br><pre>";
    print_r($res);
    echo "</pre>";
} catch (Throwable $e) {
    echo "<span style='color:red;'>ERROR:</span> Execution failed: " . $e->getMessage() . " in " . $e->getFile() . " on line " . $e->getLine() . "<br>";
}
