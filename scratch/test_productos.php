<?php
require_once "modelos/conexion.php";
$stmt = Conexion::conectar()->prepare("call prc_ListarProductosPorAlmacen(1)");
$stmt->execute();
$productos = $stmt->fetchAll(PDO::FETCH_ASSOC);
print_r($productos[0]);
