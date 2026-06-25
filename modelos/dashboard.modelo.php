<?php

require_once "conexion.php";

class DashboardModelo{

    static public function mdlGetDatosDashboard(){

        $stmt = Conexion::conectar()->prepare('call prc_ObtenerDatosDashboard()');

        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_OBJ);

       
    }

    static public function mdlGetVentasMesActual(){

        $stmt = Conexion::conectar()->prepare('call prc_ObtenerVentasMesActual()');

        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_OBJ);
    }

    static public function mdlProductosMasVendidos(){
    
        $stmt = Conexion::conectar()->prepare('call prc_ListarProductosMasVendidos()');
    
        $stmt->execute();
    
        return $stmt->fetchAll(PDO::FETCH_OBJ);
    }

    static public function mdlProductosPocoStock(){
    
        $stmt = Conexion::conectar()->prepare('call prc_ListarProductosPocoStock');
    
        $stmt->execute();
    
        return $stmt->fetchAll(PDO::FETCH_OBJ);
    }

    static public function mdlVentasPorCategoria(){
    
        $stmt = Conexion::conectar()->prepare('call prc_top_ventas_categorias');
    
        $stmt->execute();
    
        return $stmt->fetchAll(PDO::FETCH_OBJ);
    }

    static public function mdlVentasPorTipoComprobante(){
    
        $stmt = Conexion::conectar()->prepare('call prc_total_facturas_boletas');
    
        $stmt->execute();
    
        return $stmt->fetchAll(PDO::FETCH_OBJ);
    }

    static public function mdlGetDatosResumenYusu($id_almacen = 1) {
        $dbh = Conexion::conectar();
        try {
            // Ventas de hoy
            $stmtHoy = $dbh->prepare("SELECT IFNULL(SUM(importe_total), 0) as total, COUNT(*) as cantidad FROM venta WHERE DATE(fecha_emision) = CURDATE() AND id_almacen = ?");
            $stmtHoy->execute([$id_almacen]);
            $hoy = $stmtHoy->fetch(PDO::FETCH_ASSOC);
            
            // Ventas de ayer
            $stmtAyer = $dbh->prepare("SELECT IFNULL(SUM(importe_total), 0) as total FROM venta WHERE DATE(fecha_emision) = DATE_SUB(CURDATE(), INTERVAL 1 DAY) AND id_almacen = ?");
            $stmtAyer->execute([$id_almacen]);
            $ayer = $stmtAyer->fetch(PDO::FETCH_ASSOC);
            
            // Ventas del mes
            $stmtMes = $dbh->prepare("SELECT IFNULL(SUM(importe_total), 0) as total FROM venta WHERE MONTH(fecha_emision) = MONTH(CURDATE()) AND YEAR(fecha_emision) = YEAR(CURDATE()) AND id_almacen = ?");
            $stmtMes->execute([$id_almacen]);
            $mes = $stmtMes->fetch(PDO::FETCH_ASSOC);
            
            // Stock general
            $stmtStock = $dbh->prepare("
                SELECT 
                    COUNT(DISTINCT p.codigo_producto) as total_productos,
                    IFNULL(SUM(pa.stock * p.precio_unitario_con_igv), 0) as valor_stock,
                    SUM(CASE WHEN pa.stock > p.minimo_stock THEN 1 ELSE 0 END) as disponibles,
                    SUM(CASE WHEN pa.stock > 0 AND pa.stock <= p.minimo_stock THEN 1 ELSE 0 END) as minimo,
                    SUM(CASE WHEN pa.stock = 0 THEN 1 ELSE 0 END) as agotados
                FROM productos p
                LEFT JOIN productos_almacenes pa ON p.codigo_producto = pa.codigo_producto AND pa.id_almacen = ?
                WHERE p.estado = 1
            ");
            $stmtStock->execute([$id_almacen]);
            $stockInfo = $stmtStock->fetch(PDO::FETCH_ASSOC);
            
            return [
                "hoy_total" => (float)$hoy['total'],
                "hoy_cantidad" => (int)$hoy['cantidad'],
                "ayer_total" => (float)$ayer['total'],
                "mes_total" => (float)$mes['total'],
                "total_productos" => (int)$stockInfo['total_productos'],
                "valor_stock" => (float)$stockInfo['valor_stock'],
                "disponibles" => (int)$stockInfo['disponibles'],
                "minimo" => (int)$stockInfo['minimo'],
                "agotados" => (int)$stockInfo['agotados']
            ];
        } catch (Exception $e) {
            return [
                "hoy_total" => 0,
                "hoy_cantidad" => 0,
                "ayer_total" => 0,
                "mes_total" => 0,
                "total_productos" => 0,
                "valor_stock" => 0,
                "disponibles" => 0,
                "minimo" => 0,
                "agotados" => 0,
                "error" => $e->getMessage()
            ];
        }
    }

}