<?php

require_once "conexion.php";

class AlmacenesModelo
{

    static public function mdlObtenerAlmacenes()
    {
        $stmt = Conexion::conectar()->prepare("SELECT id, nombre, direccion, estado FROM almacenes WHERE estado = 1");
        $stmt->execute();
        return $stmt->fetchAll();
    }

    static public function mdlListarAlmacenes()
    {
        $stmt = Conexion::conectar()->prepare("SELECT id, nombre, direccion, CASE WHEN estado = 1 THEN 'ACTIVO' ELSE 'INACTIVO' END as estado FROM almacenes ORDER BY id DESC");
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    static public function mdlRegistrarAlmacen($nombre, $direccion, $estado)
    {
        $dbh = Conexion::conectar();
        try {
            $dbh->beginTransaction();
            $stmt = $dbh->prepare("INSERT INTO almacenes (nombre, direccion, estado) VALUES (?, ?, ?)");
            $stmt->execute([$nombre, $direccion, $estado]);
            $id_almacen = $dbh->lastInsertId();

            // Asociar todos los productos existentes con stock 0 a este almacén
            $stmtProd = $dbh->prepare("INSERT IGNORE INTO productos_almacenes (id_almacen, codigo_producto, stock) 
                                       SELECT ?, codigo_producto, 0 FROM productos");
            $stmtProd->execute([$id_almacen]);

            $dbh->commit();
            return ["tipo_msj" => "success", "msj" => "Almacén registrado correctamente"];
        } catch (Exception $e) {
            $dbh->rollBack();
            return ["tipo_msj" => "error", "msj" => "Error al registrar almacén: " . $e->getMessage()];
        }
    }

    static public function mdlActualizarAlmacen($id, $nombre, $direccion, $estado)
    {
        $dbh = Conexion::conectar();
        try {
            $dbh->beginTransaction();
            $stmt = $dbh->prepare("UPDATE almacenes SET nombre = ?, direccion = ?, estado = ? WHERE id = ?");
            $stmt->execute([$nombre, $direccion, $estado, $id]);
            $dbh->commit();
            return ["tipo_msj" => "success", "msj" => "Almacén actualizado correctamente"];
        } catch (Exception $e) {
            $dbh->rollBack();
            return ["tipo_msj" => "error", "msj" => "Error al actualizar almacén: " . $e->getMessage()];
        }
    }

    static public function mdlEliminarAlmacen($id)
    {
        $dbh = Conexion::conectar();
        try {
            $dbh->beginTransaction();
            // Desactivar en lugar de eliminar físicamente para no romper históricos
            $stmt = $dbh->prepare("UPDATE almacenes SET estado = 0 WHERE id = ?");
            $stmt->execute([$id]);
            $dbh->commit();
            return ["tipo_msj" => "success", "msj" => "Almacén desactivado correctamente"];
        } catch (Exception $e) {
            $dbh->rollBack();
            return ["tipo_msj" => "error", "msj" => "Error al desactivar almacén: " . $e->getMessage()];
        }
    }
}
