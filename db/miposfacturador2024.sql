-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 19-01-2025 a las 16:45:55
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `miposfacturador`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE  PROCEDURE `prc_ActualizarDetalleVenta` (IN `p_codigo_producto` VARCHAR(20), IN `p_cantidad` FLOAT, IN `p_id` INT)   BEGIN

 declare v_nro_boleta varchar(20);
 declare v_total_venta float;

/*
ACTUALIZAR EL STOCK DEL PRODUCTO QUE SEA MODIFICADO
......
.....
.......
*/

/*
ACTULIZAR CODIGO, CANTIDAD Y TOTAL DEL ITEM MODIFICADO
*/

 UPDATE venta_detalle 
 SET codigo_producto = p_codigo_producto, 
 cantidad = p_cantidad, 
 total_venta = (p_cantidad * (select precio_venta_producto from productos where codigo_producto = p_codigo_producto))
 WHERE id = p_id;
 
 set v_nro_boleta = (select nro_boleta from venta_detalle where id = p_id);
 set v_total_venta = (select sum(total_venta) from venta_detalle where nro_boleta = v_nro_boleta);
 
 update venta_cabecera
   set total_venta = v_total_venta
 where nro_boleta = v_nro_boleta;

END$$

CREATE  PROCEDURE `prc_ListarCategorias` ()   BEGIN
select * from categorias;
END$$

CREATE  PROCEDURE `prc_ListarProductos` ()   SELECT  '' as detalle,
		'' as acciones,
        p.id,
		codigo_producto,
		p.id_categoria,
        
		upper(c.descripcion) as nombre_categoria,
		upper(p.descripcion) as producto,
        imagen,
        p.id_tipo_afectacion_igv,
        upper(tai.descripcion) as tipo_afectacion_igv,
        p.id_unidad_medida,
        upper(cum.descripcion) as unidad_medida,
		ROUND(costo_unitario,2) as costo_unitario,
		ROUND(precio_unitario_con_igv,2) as precio_unitario_con_igv,
        ROUND(precio_unitario_sin_igv,2) as precio_unitario_sin_igv,
        ROUND(precio_unitario_mayor_con_igv,2) as precio_unitario_mayor_con_igv,
        ROUND(precio_unitario_mayor_sin_igv,2) as precio_unitario_mayor_sin_igv,
        ROUND(precio_unitario_oferta_con_igv,2) as precio_unitario_oferta_con_igv,
        ROUND(precio_unitario_oferta_sin_igv,2) as precio_unitario_oferta_sin_igv,
		stock,
		minimo_stock,
		ventas,
		ROUND(costo_total,2) as costo_total,
		p.fecha_creacion,
		p.fecha_actualizacion,
        case when p.estado = 1 then 'ACTIVO' else 'INACTIVO' end estado
	FROM productos p INNER JOIN categorias c on p.id_categoria = c.id
					 inner join tipo_afectacion_igv tai on tai.codigo = p.id_tipo_afectacion_igv
					inner join codigo_unidad_medida cum on cum.id = p.id_unidad_medida
    WHERE p.estado in (0,1)
	order by p.codigo_producto desc$$

CREATE  PROCEDURE `prc_ListarProductosMasVendidos` ()  NO SQL BEGIN

select  p.codigo_producto,
		p.descripcion,
        sum(vd.cantidad) as cantidad,
        sum(Round(vd.importe_total,2)) as total_venta
from detalle_venta vd inner join productos p on vd.codigo_producto = p.codigo_producto
group by p.codigo_producto,
		p.descripcion
order by  sum(Round(vd.importe_total,2)) DESC
limit 10;

END$$

CREATE  PROCEDURE `prc_ListarProductosPocoStock` ()  NO SQL BEGIN
select p.codigo_producto,
		p.descripcion,
        p.stock,
        p.minimo_stock
from productos p
where p.stock <= p.minimo_stock
order by p.stock asc;
END$$

CREATE  PROCEDURE `prc_movimentos_arqueo_caja_por_usuario` (`p_id_usuario` INT, `p_id_caja` INT)   BEGIN

	select 
	ac.monto_apertura as y,
	'APERTURA' as label,
	"#6c757d" as color
	from arqueo_caja ac inner join usuarios usu on ac.id_usuario = usu.id_usuario
	where ac.id_usuario = p_id_usuario
    and ac.id = p_id_caja
	and date(ac.fecha_apertura) = curdate()
	union  
	select 
	ac.ingresos as y,
	'INGRESOS' as label,
	"#28a745" as color
	from arqueo_caja ac inner join usuarios usu on ac.id_usuario = usu.id_usuario
	where ac.id_usuario = p_id_usuario
    and ac.id = p_id_caja
	and date(ac.fecha_apertura) = curdate()
	union
	select 
	ac.devoluciones as y,
	'DEVOLUCIONES' as label,
	"#ffc107" as color
	from arqueo_caja ac inner join usuarios usu on ac.id_usuario = usu.id_usuario
	where ac.id_usuario = p_id_usuario
    and ac.id = p_id_caja
	and date(ac.fecha_apertura) = curdate()
	union
	select 
	ac.gastos as y,
	'GASTOS' as label,
	"#17a2b8" as color
	from arqueo_caja ac inner join usuarios usu on ac.id_usuario = usu.id_usuario
	where ac.id_usuario = p_id_usuario
    and ac.id = p_id_caja
	and date(ac.fecha_apertura) = curdate();
END$$

CREATE  PROCEDURE `prc_ObtenerDatosDashboard` ()  NO SQL BEGIN
  DECLARE totalProductos int;
  DECLARE totalCompras float;
  DECLARE totalVentas float;
  DECLARE ganancias float;
  DECLARE productosPocoStock int;
  DECLARE ventasHoy float;

  SET totalProductos = (SELECT
      COUNT(*)
    FROM productos p);
    
  SET totalCompras = (SELECT
      SUM(p.costo_total)
    FROM productos p);  

	SET totalVentas = 0;
  SET totalVentas = (SELECT
      SUM(v.importe_total)
    FROM venta v);

  SET ganancias = 0;
  SET ganancias = (SELECT
      SUM(dv.importe_total) - SUM(dv.cantidad * dv.costo_unitario)
    FROM detalle_venta dv);
    
  SET productosPocoStock = (SELECT
      COUNT(1)
    FROM productos p
    WHERE p.stock <= p.minimo_stock);
    
    SET ventasHoy = 0;
  SET ventasHoy = (SELECT
      SUM(v.importe_total)
    FROM venta v
    WHERE DATE(v.fecha_emision) = CURDATE());

  SELECT
    IFNULL(totalProductos, 0) AS totalProductos,
    IFNULL(CONCAT('S./ ', FORMAT(totalCompras, 2)), 0) AS totalCompras,
    IFNULL(CONCAT('S./ ', FORMAT(totalVentas, 2)), 0) AS totalVentas,
    IFNULL(CONCAT('S./ ', FORMAT(ganancias, 2), ' - ','  % ', FORMAT((ganancias / totalVentas) *100,2)), 0) AS ganancias,
    IFNULL(productosPocoStock, 0) AS productosPocoStock,
    IFNULL(CONCAT('S./ ', FORMAT(ventasHoy, 2)), 0) AS ventasHoy;



END$$

CREATE  PROCEDURE `prc_obtenerNroBoleta` ()  NO SQL select serie_boleta,
		IFNULL(LPAD(max(c.nro_correlativo_venta)+1,8,'0'),'00000001') nro_venta 
from empresa c$$

CREATE  PROCEDURE `prc_ObtenerVentasMesActual` ()  NO SQL BEGIN
SELECT date(vc.fecha_emision) as fecha_venta,
		sum(round(vc.importe_total,2)) as total_venta,
        ifnull((SELECT sum(round(vc1.importe_total,2))
			FROM venta vc1
		where date(vc1.fecha_emision) >= date(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
		and date(vc1.fecha_emision) <= last_day(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
        and date(vc1.fecha_emision) = DATE_ADD(date(vc.fecha_emision), INTERVAL -1 MONTH)
		group by date(vc1.fecha_emision)),0) as total_venta_ant
FROM venta vc
where date(vc.fecha_emision) >= date(last_day(now() - INTERVAL 1 month) + INTERVAL 1 day)
and date(vc.fecha_emision) <= last_day(date(CURRENT_DATE))
group by date(vc.fecha_emision);


END$$

CREATE  PROCEDURE `prc_ObtenerVentasMesAnterior` ()  NO SQL BEGIN
SELECT date(vc.fecha_venta) as fecha_venta,
		sum(round(vc.total_venta,2)) as total_venta,
        sum(round(vc.total_venta,2)) as total_venta_ant
FROM venta_cabecera vc
where date(vc.fecha_venta) >= date(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
and date(vc.fecha_venta) <= last_day(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
group by date(vc.fecha_venta);
END$$

CREATE  PROCEDURE `prc_pagar_cuotas_compra` (IN `p_id_compra` INT, IN `p_monto_a_pagar` FLOAT, IN `p_id_usuario` INT)   BEGIN

	DECLARE v_id INT;
	DECLARE v_id_compra INT;
	DECLARE v_cuota varchar(3);
	DECLARE v_importe FLOAT;
    DECLARE v_importe_pagado FLOAT;
    DECLARE v_saldo_pendiente FLOAT;
	DECLARE v_cuota_pagada BOOLEAN;
    DECLARE v_fecha_vencimiento DATE;
    
    DECLARE p_monto_a_pagar_original decimal(18,2);
    
    DECLARE v_id_arqueo_caja INT;
    
    DECLARE var_final INTEGER DEFAULT 0;
    
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_mensaje varchar(500) DEFAULT '';
    
	DECLARE cursor1 CURSOR FOR 
    select id, 
			id_compra, 
            cuota, 
            importe, 
            importe_pagado, 
            saldo_pendiente, 
            cuota_pagada, 
            fecha_vencimiento
    from cuotas_compras c
    where c.id_compra = p_id_compra
    and c.cuota_pagada = 0
    order by c.id;
    
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET var_final = 1;
    set p_monto_a_pagar_original = p_monto_a_pagar;
    OPEN cursor1;

	  bucle: LOOP

		FETCH cursor1 
		INTO v_id,
			 v_id_compra, 
             v_cuota, 
             v_importe, 
             v_importe_pagado, 
             v_saldo_pendiente,
             v_cuota_pagada, 
             v_fecha_vencimiento;

		IF var_final = 1 THEN
		  LEAVE bucle;
		END IF;

		if(p_monto_a_pagar > 0 && (p_monto_a_pagar <= v_saldo_pendiente) ) then
			set v_mensaje = 'Monto a pagar menor al saldo pendiente de la cuota';
            update cuotas_compras c
			  set c.importe_pagado = round(ifnull(c.importe_pagado,0) + p_monto_a_pagar,2),
					c.saldo_pendiente = round(c.importe - ifnull(c.importe_pagado,0),2),
                    c.cuota_pagada = case when round(c.importe,2) = round(ifnull(c.importe_pagado,0),2) then 1 else 0 end                    
            where c.id = v_id;
            
            set p_monto_a_pagar = p_monto_a_pagar - v_saldo_pendiente;
            
            LEAVE bucle;
        end if;
        
        if(p_monto_a_pagar > 0 && (p_monto_a_pagar > v_saldo_pendiente)) then
        
			set v_mensaje = 'Monto a pagar mayor al saldo pendiente de la cuota';
        
			 update cuotas_compras c
			  set c.importe_pagado = round(c.importe,2),
					c.saldo_pendiente = 0,
                    c.cuota_pagada = case when round(c.importe,2) = round(ifnull(c.importe_pagado,0),2) then 1 else 0 end                    
            where c.id = v_id;
            
            set p_monto_a_pagar = p_monto_a_pagar - v_saldo_pendiente;
        end if;
		 
	  END LOOP bucle;
	  CLOSE cursor1; 
      
      SET v_saldo_pendiente = 0;
      
      select sum(ifnull(saldo_pendiente,0))
      into v_saldo_pendiente
      from cuotas_compras where id_compra = p_id_compra;
      
      if(v_saldo_pendiente <= 0) then
		update compras
			set pagado = 1
        where id = p_id_compra;
      end if;
    
     -- SELECT p_monto_a_pagar as vuelto;
     
     select id
     into v_id_arqueo_caja
     from arqueo_caja
	where id_usuario = p_id_usuario
    and estado = 1;
     
     insert into movimientos_arqueo_caja(id_arqueo_caja, id_tipo_movimiento, descripcion, monto, estado)
     values(v_id_arqueo_caja, 5, 'PAGO CUOTA DE COMPRA AL CREDITO', p_monto_a_pagar_original, 1);
     
     update arqueo_caja 
      set gastos = ifnull(gastos,0) + p_monto_a_pagar_original,
      	 monto_final = ifnull(monto_final,0) - p_monto_a_pagar_original
    where id_usuario = p_id_usuario
    and estado = 1;
     
     
END$$

CREATE  PROCEDURE `prc_pagar_cuotas_factura` (IN `p_id_venta` INT, IN `p_monto_a_pagar` FLOAT, IN `p_id_usuario` INT, IN `p_medio_pago` INT)   BEGIN

	DECLARE v_id INT;
	DECLARE v_id_venta INT;
	DECLARE v_cuota varchar(3);
	DECLARE v_importe FLOAT;
    DECLARE v_importe_pagado FLOAT;
    DECLARE v_saldo_pendiente FLOAT;
	DECLARE v_cuota_pagada BOOLEAN;
    DECLARE v_fecha_vencimiento DATE;
    
    DECLARE v_id_medio_pago INT;
    DECLARE v_id_tipo_movimiento_caja INT;
    DECLARE v_afecta_caja INT;
    DECLARE v_medio_pago VARCHAR(100);
    
    DECLARE p_monto_a_pagar_original decimal(18,2);
    
    DECLARE v_id_arqueo_caja INT;
    
    DECLARE var_final INTEGER DEFAULT 0;
    
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_mensaje varchar(500) DEFAULT '';
    
	DECLARE cursor1 CURSOR FOR 
    select id, 
			id_venta, 
            cuota, 
            importe, 
            importe_pagado, 
            saldo_pendiente, 
            cuota_pagada, 
            fecha_vencimiento
    from cuotas c
    where c.id_venta = p_id_venta
    and c.cuota_pagada = 0
    order by c.id;
    
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET var_final = 1;
    set p_monto_a_pagar_original = p_monto_a_pagar;
    OPEN cursor1;

	  bucle: LOOP

		FETCH cursor1 
		INTO v_id,
			 v_id_venta, 
             v_cuota, 
             v_importe, 
             v_importe_pagado, 
             v_saldo_pendiente,
             v_cuota_pagada, 
             v_fecha_vencimiento;

		IF var_final = 1 THEN
		  LEAVE bucle;
		END IF;

		if(p_monto_a_pagar > 0 && (p_monto_a_pagar <= v_saldo_pendiente) ) then
			set v_mensaje = 'Monto a pagar menor al saldo pendiente de la cuota';
            update cuotas c
			  set c.importe_pagado = round(ifnull(c.importe_pagado,0) + p_monto_a_pagar,2),
					c.saldo_pendiente = round(c.importe - ifnull(c.importe_pagado,0),2),
                    c.cuota_pagada = case when round(c.importe,2) = round(ifnull(c.importe_pagado,0),2) then 1 else 0 end,
                    c.medio_pago = p_medio_pago
            where c.id = v_id;
            
            set p_monto_a_pagar = p_monto_a_pagar - v_saldo_pendiente;
            
            LEAVE bucle;
        end if;
        
        if(p_monto_a_pagar > 0 && (p_monto_a_pagar > v_saldo_pendiente)) then
        
			set v_mensaje = 'Monto a pagar mayor al saldo pendiente de la cuota';
        
			 update cuotas c
			  set c.importe_pagado = round(c.importe,2),
					c.saldo_pendiente = 0,
                    c.cuota_pagada = case when round(c.importe,2) = round(ifnull(c.importe_pagado,0),2) then 1 else 0 end,
                    c.medio_pago = p_medio_pago
            where c.id = v_id;
            
            set p_monto_a_pagar = p_monto_a_pagar - v_saldo_pendiente;
        end if;
		 
	  END LOOP bucle;
	  CLOSE cursor1; 
      
      SET v_saldo_pendiente = 0;
      
      select sum(ifnull(saldo_pendiente,0))
      into v_saldo_pendiente
      from cuotas where id_venta = p_id_venta;
      
      if(v_saldo_pendiente = 0) then
		update venta
			set pagado = 1
        where id = p_id_venta;
      end if;
    
     -- SELECT p_monto_a_pagar as vuelto;
     
     select id
     into v_id_arqueo_caja
     from arqueo_caja
	where id_usuario = p_id_usuario
    and estado = 1;
     
     -- SETEMOS EL TIPO DE MOVIMIENTO DE CAJA 
     select mp.id as id_medio_pago, mp.id_tipo_movimiento_caja, tmc.afecta_caja, mp.descripcion as medio_pago
     INTO v_id_medio_pago, v_id_tipo_movimiento_caja, v_afecta_caja, v_medio_pago
	from medio_pago mp inner join tipo_movimiento_caja tmc on mp.id_tipo_movimiento_caja = tmc.id
	where mp.id = p_medio_pago;
    
     insert into movimientos_arqueo_caja(id_arqueo_caja, id_tipo_movimiento, descripcion, monto, estado)
     values(v_id_arqueo_caja, v_id_tipo_movimiento_caja, concat('PAGO ',v_medio_pago ,' CUOTA DE FACTURA'), p_monto_a_pagar_original, 1);
     
     if v_afecta_caja = 1 THEN
		 update arqueo_caja 
		  set ingresos = ifnull(ingresos,0) + p_monto_a_pagar_original,
			 monto_final = ifnull(monto_final,0) + p_monto_a_pagar_original
		where id_usuario = p_id_usuario
		and estado = 1;
    END IF;
     
     
END$$

CREATE  PROCEDURE `prc_registrar_kardex_anulacion` (IN `p_id_venta` INT, IN `p_codigo_producto` VARCHAR(20))   BEGIN

	/*VARIABLES PARA EXISTENCIAS ACTUALES*/
	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_in float;
	declare v_costo_unitario_in float;    
	declare v_costo_total_in float;
    
    declare v_cantidad_devolucion float;
	declare v_costo_unitario_devolucion float;   
    declare v_comprobante_devolucion varchar(20);   
    declare v_concepto_devolucion varchar(50);   
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM kardex k
    WHERE k.codigo_producto = p_codigo_producto
    ORDER BY id DESC
    LIMIT 1;
    
    select   cantidad, 
			costo_unitario,
			concat(v.serie,'-',v.correlativo) as comprobante,
			'DEVOLUCIÓN' as concepto
	  into v_cantidad_devolucion, v_costo_unitario_devolucion,
			v_comprobante_devolucion, v_concepto_devolucion 
	from detalle_venta dv inner join venta v on dv.id_venta = v.id
    where dv.id_venta = p_id_venta and dv.codigo_producto = p_codigo_producto;
    
      /*SETEAMOS LOS VALORES PARA EL REGISTRO DE INGRESO*/
    SET v_unidades_in = v_cantidad_devolucion;
    SET v_costo_unitario_in = v_costo_unitario_devolucion;
    SET v_costo_total_in = v_unidades_in * v_costo_unitario_in;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = v_unidades_ex + ROUND(v_cantidad_devolucion,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex + v_costo_total_in,2);
    SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);


	INSERT INTO kardex(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        in_unidades,
                        in_costo_unitario,
                        in_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						curdate(),
                        v_concepto_devolucion,
                        v_comprobante_devolucion,
                        v_unidades_in,
                        v_costo_unitario_in,
                        v_costo_total_in,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE productos 
	SET stock = v_unidades_ex, 
         costo_unitario = v_costo_unitario_ex,
         costo_total= v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;  

END$$

CREATE  PROCEDURE `prc_registrar_kardex_bono` (IN `p_codigo_producto` VARCHAR(20), IN `p_concepto` VARCHAR(100), IN `p_nuevo_stock` FLOAT)   BEGIN

	/*VARIABLES PARA EXISTENCIAS ACTUALES*/
	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_in float;
	declare v_costo_unitario_in float;    
	declare v_costo_total_in float;
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM kardex k
    WHERE k.codigo_producto = p_codigo_producto
    ORDER BY id DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE INGRESO*/
    SET v_unidades_in = p_nuevo_stock - v_unidades_ex;
    SET v_costo_unitario_in = v_costo_unitario_ex;
    SET v_costo_total_in = v_unidades_in * v_costo_unitario_in;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(p_nuevo_stock,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex + v_costo_total_in,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
	else
		SET v_costo_unitario_ex = ROUND(0,2);
    END IF;
    
        
	INSERT INTO kardex(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        in_unidades,
                        in_costo_unitario,
                        in_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						curdate(),
                        p_concepto,
                        '',
                        v_unidades_in,
                        v_costo_unitario_in,
                        v_costo_total_in,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE productos 
	SET stock = v_unidades_ex, 
         costo_unitario = v_costo_unitario_ex,
         costo_total= v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;                      

END$$

CREATE  PROCEDURE `prc_registrar_kardex_compra` (IN `p_id_compra` INT, IN `p_comprobante` VARCHAR(20), IN `p_codigo_producto` VARCHAR(20), IN `p_concepto` VARCHAR(100), IN `p_cantidad_compra` FLOAT, IN `p_costo_compra` FLOAT)   BEGIN

	/*VARIABLES PARA EXISTENCIAS ACTUALES*/
	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_in float;
	declare v_costo_unitario_in float;    
	declare v_costo_total_in float;
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM kardex k
    WHERE k.codigo_producto = p_codigo_producto
    ORDER BY id DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE INGRESO*/
    SET v_unidades_in = p_cantidad_compra;
    SET v_costo_unitario_in = p_costo_compra;
    SET v_costo_total_in = v_unidades_in * v_costo_unitario_in;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = v_unidades_ex + ROUND(p_cantidad_compra,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex + v_costo_total_in,2);
    SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);

	INSERT INTO kardex(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        in_unidades,
                        in_costo_unitario,
                        in_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						curdate(),
                        p_concepto,
                        p_comprobante,
                        v_unidades_in,
                        v_costo_unitario_in,
                        v_costo_total_in,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE productos 
	SET stock = v_unidades_ex, 
         costo_unitario = v_costo_unitario_ex,
         costo_total= v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;  
  

END$$

CREATE  PROCEDURE `prc_registrar_kardex_existencias` (IN `p_codigo_producto` VARCHAR(25), IN `p_concepto` VARCHAR(100), IN `p_comprobante` VARCHAR(100), IN `p_unidades` FLOAT, IN `p_costo_unitario` FLOAT, IN `p_costo_total` FLOAT)   BEGIN
  INSERT INTO kardex (codigo_producto, fecha, concepto, comprobante, in_unidades, in_costo_unitario, in_costo_total,ex_unidades, ex_costo_unitario, ex_costo_total)
    VALUES (p_codigo_producto, CURDATE(), p_concepto, p_comprobante, p_unidades, p_costo_unitario, p_costo_total, p_unidades, p_costo_unitario, p_costo_total);

END$$

CREATE  PROCEDURE `prc_registrar_kardex_vencido` (IN `p_codigo_producto` VARCHAR(20), IN `p_concepto` VARCHAR(100), IN `p_nuevo_stock` FLOAT)   BEGIN

	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_out float;
	declare v_costo_unitario_out float;    
	declare v_costo_total_out float;
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM kardex k
    WHERE k.codigo_producto = p_codigo_producto
    ORDER BY ID DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE SALIDA*/
    SET v_unidades_out = v_unidades_ex - p_nuevo_stock;
    SET v_costo_unitario_out = v_costo_unitario_ex;
    SET v_costo_total_out = v_unidades_out * v_costo_unitario_out;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(p_nuevo_stock,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex - v_costo_total_out,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
    END IF;
    
        
	INSERT INTO kardex(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        out_unidades,
                        out_costo_unitario,
                        out_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						curdate(),
                        p_concepto,
                        '',
                        v_unidades_out,
                        v_costo_unitario_out,
                        v_costo_total_out,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE productos 
	SET stock = v_unidades_ex, 
         costo_unitario = v_costo_unitario_ex,
        costo_total = v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;                      

END$$

CREATE  PROCEDURE `prc_registrar_kardex_venta` (IN `p_codigo_producto` VARCHAR(20), IN `p_fecha` DATE, IN `p_concepto` VARCHAR(100), IN `p_comprobante` VARCHAR(100), IN `p_unidades` FLOAT)   BEGIN

	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_costo_total_ex_actual float;
    
    declare v_unidades_out float;
	declare v_costo_unitario_out float;    
	declare v_costo_total_out float;
    

	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/
    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex, v_costo_total_ex_actual
    FROM kardex k
    WHERE k.codigo_producto = p_codigo_producto
    ORDER BY id DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE SALIDA*/
    SET v_unidades_out = p_unidades;
    SET v_costo_unitario_out = v_costo_unitario_ex;
    SET v_costo_total_out = p_unidades * v_costo_unitario_ex;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(v_unidades_ex - v_unidades_out,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex -  v_costo_total_out,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
    END IF;
    
        
	INSERT INTO kardex(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        out_unidades,
                        out_costo_unitario,
                        out_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						p_fecha,
                        p_concepto,
                        p_comprobante,
                        v_unidades_out,
                        v_costo_unitario_out,
                        v_costo_total_out,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE productos 
	SET stock = v_unidades_ex, 
		ventas = ventas + v_unidades_out,
        costo_unitario = v_costo_unitario_ex,
        costo_total = v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;                      

END$$

CREATE  PROCEDURE `prc_registrar_venta_detalle` (IN `p_nro_boleta` VARCHAR(8), IN `p_codigo_producto` VARCHAR(20), IN `p_cantidad` FLOAT, IN `p_total_venta` FLOAT)   BEGIN
declare v_precio_compra float;
declare v_precio_venta float;

SELECT p.precio_compra_producto,p.precio_venta_producto
into v_precio_compra, v_precio_venta
FROM productos p
WHERE p.codigo_producto  = p_codigo_producto;
    
INSERT INTO venta_detalle(nro_boleta,codigo_producto, cantidad, costo_unitario_venta,precio_unitario_venta,total_venta, fecha_venta) 
VALUES(p_nro_boleta,p_codigo_producto,p_cantidad, v_precio_compra, v_precio_venta,p_total_venta,curdate());
                                                        
END$$

CREATE  PROCEDURE `prc_ReporteVentas` (IN `p_fecha_desde` DATE, IN `p_fecha_hasta` DATE)   BEGIN

	select v.fecha_emision,
			-- '' as fecha_vencimiento,
            case when upper(v.forma_pago) = 'CONTADO' then v.fecha_emision 
				else (select cuo.fecha_vencimiento from cuotas cuo where id_venta = v.id
						order by cuota desc limit 1) end as fecha_vencimiento,
			s.id_tipo_comprobante,
			v.serie,
			lpad(v.correlativo,13,'0') as correlativo,
			cli.id_tipo_documento,
			cli.nro_documento,
			cli.nombres_apellidos_razon_social,
			'' as valor_facturado_exportacion,
			round(ifnull(v.total_operaciones_gravadas,''),2) as base_imponible_operacion_gravada,
			round(ifnull(v.total_operaciones_exoneradas,''),2) as importe_total_operacion_exonerada,
			round(ifnull(v.total_operaciones_inafectas,''),2) as importe_total_operacion_inafecta,
			'' as isc,        
			v.total_igv as igv,
			'' as otros_tributos_no_base_imponible,
			v.importe_total as importe_total_comprobante_pago,
			'' as tipo_cambio,
			/*REFERENCIA DEL COMPROBANTE DE PAGO O DOCUMENTO ORIGINAL QUE SE MODIFICA*/
			'' as fecha_referencia,
			'' as tipo_referencia,
			'' as serie_referencia,
			'' as nro_comprobante_pago_o_documento,
			case when v.id_moneda = 'PEN' then 'S' else '$' end as moneda,
			'' as equivalente_dolares_americanos,
			'' as fecha_vencimiento,
			case when upper(v.forma_pago) = 'CONTADO' then 'CON' else 'CRE' end as condicion_contado_credito,
			'' as codigo_centro_costos,
			'' as codigo_centro_costos_2,
			'70121' as cuenta_contable_base_imponible,
			'' as cuenta_contable_otros_tributos,
			'1212' as cuenta_contable_total,
			'' as regimen_especial,
			'' as porcentaje_regimen_especial,
			'' as importe_regimen_especial,
			'' as serie_documento_regimen_especial,
			'' as numero_documento_regimen_especial,
			'' as fecha_documento_regimen_especial,
			'' as codigo_presupuesto,
			'' as porcentaje_igv,
			'VENTA DE MERCADERIA' as glosa,
			'' as medio_pago,
			'' as condicion_percepción,
			'' as importe_calculo_regimen_especial,
			'' as impuesto_consumo_bolsas_plastico,
			'' as cuenta_contable_icbper
	from venta v inner join serie s on v.id_serie = s.id
				 inner join clientes cli on cli.id = v.id_cliente
	where v.fecha_emision between p_fecha_desde and p_fecha_hasta;
				 
END$$

CREATE  PROCEDURE `prc_top_ventas_categorias` ()   BEGIN

select cast(sum(vd.importe_total)  AS DECIMAL(8,2)) as y, c.descripcion as label
    from detalle_venta vd inner join productos p on vd.codigo_producto = p.codigo_producto
                        inner join categorias c on c.id = p.id_categoria
    group by c.descripcion
    LIMIT 10;
END$$

CREATE  PROCEDURE `prc_total_facturas_boletas` ()   BEGIN

select cast(sum(v.importe_total)  AS DECIMAL(8,2)) as y, tc.descripcion as label
    from venta v inner join serie s on v.id_serie = s.id
				 inner join tipo_comprobante tc on tc.codigo = s.id_tipo_comprobante
    group by s.id_tipo_comprobante
    LIMIT 10;
END$$

CREATE  PROCEDURE `prc_truncate_all_tables` ()   BEGIN

SET FOREIGN_KEY_CHECKS = 0;


truncate table arqueo_caja;

truncate table clientes;
truncate table compras;
truncate table cotizaciones;
truncate table cotizaciones_detalle;
truncate table cuotas;
truncate table cuotas_compras;
truncate table detalle_compra;
truncate table compras;
truncate table detalle_venta;
truncate table venta;
truncate table empresas;
truncate table codigo_unidad_medida;
truncate table tipo_afectacion_igv;
truncate table categorias;
truncate table kardex;
truncate table productos;

truncate table movimientos_arqueo_caja;
truncate table proveedores;
truncate table resumenes_detalle;
truncate table resumenes;
truncate table serie;

SET FOREIGN_KEY_CHECKS = 1;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `arqueo_caja`
--

CREATE TABLE `arqueo_caja` (
  `id` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `fecha_apertura` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_cierre` datetime DEFAULT NULL,
  `monto_apertura` float NOT NULL,
  `ingresos` float DEFAULT NULL,
  `devoluciones` float DEFAULT NULL,
  `gastos` float DEFAULT NULL,
  `monto_final` float DEFAULT NULL,
  `monto_real` float DEFAULT NULL,
  `sobrante` float DEFAULT NULL,
  `faltante` float DEFAULT NULL,
  `estado` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cajas`
--

CREATE TABLE `cajas` (
  `id` int(11) NOT NULL,
  `nombre_caja` varchar(100) NOT NULL,
  `estado` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `cajas`
--

INSERT INTO `cajas` (`id`, `nombre_caja`, `estado`) VALUES
(1, 'Sin Caja', 1),
(2, 'Caja Principal', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

CREATE TABLE `categorias` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(150) NOT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `fecha_actualizacion` timestamp NULL DEFAULT NULL,
  `estado` int(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `id` int(11) NOT NULL,
  `id_tipo_documento` int(11) DEFAULT NULL,
  `nro_documento` varchar(20) DEFAULT NULL,
  `nombres_apellidos_razon_social` varchar(255) DEFAULT NULL,
  `direccion` varchar(255) DEFAULT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `codigo_unidad_medida`
--

CREATE TABLE `codigo_unidad_medida` (
  `id` varchar(3) NOT NULL,
  `descripcion` varchar(150) NOT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compras`
--

CREATE TABLE `compras` (
  `id` int(11) NOT NULL,
  `id_proveedor` int(11) DEFAULT NULL,
  `fecha_compra` datetime DEFAULT NULL,
  `id_tipo_comprobante` varchar(3) DEFAULT NULL,
  `serie` varchar(10) DEFAULT NULL,
  `correlativo` varchar(20) DEFAULT NULL,
  `id_moneda` varchar(3) DEFAULT NULL,
  `forma_pago` varchar(45) DEFAULT NULL,
  `ope_exonerada` float DEFAULT NULL,
  `ope_inafecta` float DEFAULT NULL,
  `ope_gravada` float DEFAULT NULL,
  `total_igv` float DEFAULT NULL,
  `descuento` float DEFAULT NULL,
  `total_compra` float DEFAULT NULL,
  `estado` int(11) NOT NULL DEFAULT 1,
  `pagado` int(11) DEFAULT 0 COMMENT '0: Pendiente\\n1: Pagado'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `configuraciones`
--

CREATE TABLE `configuraciones` (
  `id` varchar(3) NOT NULL,
  `ordinal` int(11) NOT NULL,
  `llave` varchar(150) NOT NULL,
  `valor` varchar(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `configuraciones`
--

INSERT INTO `configuraciones` (`id`, `ordinal`, `llave`, `valor`) VALUES
('100', 0, 'CONFIGURACION SERVIDOR CORREO', '-'),
('100', 1, 'HOST', 'mail.tutorialesphperu.com'),
('100', 2, 'USERNAME', 'tutorialesphperu@tutorialesphperu.com'),
('100', 3, 'PASSWORD', 'Emilia1109$'),
('100', 4, 'SMTPSECURE', 'ssl'),
('100', 5, 'PORT', '465'),
('100', 6, 'NOMBRE EMPRESA', 'LUIS LOZANO ARICA'),
('200', 0, 'WEBSERVICE SUNAT / MODO FACTURACION', '-'),
('200', 1, 'PRODUCCION', 'https://e-factura.sunat.gob.pe/ol-ti-itcpfegem/billService?wsdl'),
('200', 2, 'DESARROLLO', 'https://e-beta.sunat.gob.pe/ol-ti-itcpfegem-beta/billService'),
('200', 3, 'MODO FACTURACION', 'DESARROLLO'),
('300', 0, 'API SUNAT / GUÍAS DE REMISIÓN', ''),
('300', 1, 'CLIENT_ID_DESARROLLO', 'test-85e5b0ae-255c-4891-a595-0b98c65c9854'),
('300', 2, 'CLIENT_SECRET_DESARROLLO', 'test-Hty/M6QshYvPgItX2P0+Kw=='),
('300', 3, 'CLIENT_ID_PRODUCCION', '-'),
('300', 4, 'CLIENT_SECRET_PRODUCCION', '-'),
('300', 5, 'API_AUTH_DESARROLLO', 'https://gre-test.nubefact.com/v1'),
('300', 6, 'API_CPE_DESARROLLO', 'https://gre-test.nubefact.com/v1'),
('300', 7, 'API_AUTH_PRODUCCION', 'https://api-seguridad.sunat.gob.pe/v1'),
('300', 8, 'API_CPE_PRODUCCION', 'https://api-cpe.sunat.gob.pe/v1'),
('300', 9, 'MODO GUIA DE REMISION', 'DESARROLLO'),
('400', 0, 'USUARIO SOL SECUNDARIO', ''),
('400', 1, 'USUARIO SOL', 'MODDATOS'),
('400', 2, 'CLAVE SOL', 'MODDATOS');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cotizaciones`
--

CREATE TABLE `cotizaciones` (
  `id` int(11) NOT NULL,
  `id_empresa_emisora` int(11) DEFAULT NULL,
  `id_serie` int(11) NOT NULL,
  `serie` varchar(4) NOT NULL,
  `correlativo` int(11) NOT NULL,
  `fecha_cotizacion` date NOT NULL,
  `fecha_expiracion` date NOT NULL,
  `id_moneda` varchar(3) NOT NULL,
  `tipo_cambio` decimal(18,3) DEFAULT NULL,
  `comprobante_a_generar` varchar(3) NOT NULL,
  `id_cliente` int(11) NOT NULL,
  `total_operaciones_gravadas` decimal(18,2) DEFAULT 0.00,
  `total_operaciones_exoneradas` decimal(18,2) DEFAULT 0.00,
  `total_operaciones_inafectas` decimal(18,2) DEFAULT 0.00,
  `total_igv` decimal(18,2) DEFAULT 0.00,
  `importe_total` decimal(18,2) DEFAULT 0.00,
  `estado` int(11) DEFAULT 0 COMMENT '0: Registrado\\n1: Confirmado\\n2: Cerrada',
  `id_usuario` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cotizaciones_detalle`
--

CREATE TABLE `cotizaciones_detalle` (
  `id` int(11) NOT NULL,
  `id_cotizacion` int(11) DEFAULT NULL,
  `item` int(11) DEFAULT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `descripcion` varchar(150) DEFAULT NULL,
  `porcentaje_igv` decimal(18,2) DEFAULT NULL,
  `cantidad` decimal(18,2) DEFAULT NULL,
  `costo_unitario` decimal(18,2) DEFAULT NULL,
  `valor_unitario` decimal(18,2) DEFAULT NULL,
  `precio_unitario` decimal(18,2) DEFAULT NULL,
  `valor_total` decimal(18,2) DEFAULT NULL,
  `igv` decimal(18,2) DEFAULT NULL,
  `importe_total` decimal(18,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cuotas`
--

CREATE TABLE `cuotas` (
  `id` int(11) NOT NULL,
  `id_venta` int(11) DEFAULT NULL,
  `cuota` varchar(3) DEFAULT NULL,
  `importe` decimal(15,6) DEFAULT NULL,
  `importe_pagado` float NOT NULL,
  `saldo_pendiente` float NOT NULL,
  `cuota_pagada` tinyint(1) NOT NULL DEFAULT 0,
  `fecha_vencimiento` date DEFAULT NULL,
  `medio_pago` varchar(45) DEFAULT NULL,
  `estado` char(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cuotas_compras`
--

CREATE TABLE `cuotas_compras` (
  `id` int(11) NOT NULL,
  `id_compra` int(11) DEFAULT NULL,
  `cuota` varchar(3) DEFAULT NULL,
  `importe` decimal(15,6) DEFAULT NULL,
  `importe_pagado` float NOT NULL,
  `saldo_pendiente` float NOT NULL,
  `cuota_pagada` tinyint(1) NOT NULL DEFAULT 0,
  `fecha_vencimiento` date DEFAULT NULL,
  `estado` char(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_compra`
--

CREATE TABLE `detalle_compra` (
  `id` int(11) NOT NULL,
  `id_compra` int(11) DEFAULT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `cantidad` float DEFAULT NULL,
  `costo_unitario` float DEFAULT NULL,
  `descuento` float DEFAULT NULL,
  `subtotal` float DEFAULT NULL,
  `impuesto` float DEFAULT NULL,
  `total` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_venta`
--

CREATE TABLE `detalle_venta` (
  `id` int(11) NOT NULL,
  `id_venta` int(11) DEFAULT NULL,
  `item` int(11) DEFAULT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `descripcion` varchar(150) DEFAULT NULL,
  `porcentaje_igv` decimal(18,4) DEFAULT NULL,
  `cantidad` decimal(18,4) DEFAULT NULL,
  `costo_unitario` decimal(18,4) DEFAULT NULL,
  `valor_unitario` decimal(18,4) DEFAULT NULL,
  `precio_unitario` decimal(18,4) DEFAULT NULL,
  `valor_total` decimal(18,4) DEFAULT NULL,
  `igv` decimal(18,4) DEFAULT NULL,
  `importe_total` decimal(18,4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empresas`
--

CREATE TABLE `empresas` (
  `id_empresa` int(11) NOT NULL,
  `genera_fact_electronica` tinyint(4) DEFAULT 1,
  `razon_social` text NOT NULL,
  `nombre_comercial` varchar(255) DEFAULT NULL,
  `id_tipo_documento` varchar(20) DEFAULT NULL,
  `ruc` bigint(20) NOT NULL,
  `direccion` text NOT NULL,
  `simbolo_moneda` varchar(5) DEFAULT NULL,
  `email` text NOT NULL,
  `telefono` varchar(100) DEFAULT NULL,
  `provincia` varchar(100) DEFAULT NULL,
  `departamento` varchar(100) DEFAULT NULL,
  `distrito` varchar(100) DEFAULT NULL,
  `ubigeo` varchar(6) DEFAULT NULL,
  `certificado_digital` varchar(255) DEFAULT NULL,
  `clave_certificado` varchar(45) DEFAULT NULL,
  `usuario_sol` varchar(45) DEFAULT NULL,
  `clave_sol` varchar(45) DEFAULT NULL,
  `es_principal` int(1) DEFAULT 0,
  `fact_bol_defecto` int(1) DEFAULT 0,
  `logo` varchar(150) DEFAULT NULL,
  `bbva_cci` varchar(45) DEFAULT NULL,
  `bcp_cci` varchar(45) DEFAULT NULL,
  `yape` varchar(45) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT 1,
  `production` int(11) DEFAULT 0,
  `client_id` varchar(150) DEFAULT NULL,
  `client_secret` datetime DEFAULT NULL,
  `certificado_digital_pem` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `forma_pago`
--

CREATE TABLE `forma_pago` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(100) NOT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `forma_pago`
--

INSERT INTO `forma_pago` (`id`, `descripcion`, `estado`) VALUES
(1, 'Contado', 1),
(2, 'Crédito', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `guia_remision`
--

CREATE TABLE `guia_remision` (
  `id` int(11) NOT NULL,
  `tipo_documento` varchar(5) NOT NULL,
  `serie` varchar(10) NOT NULL,
  `correlativo` int(11) NOT NULL,
  `fecha_emision` date NOT NULL,
  `id_empresa` int(11) NOT NULL,
  `id_cliente` int(11) NOT NULL,
  `id_tipo_documento_rel` varchar(45) DEFAULT NULL,
  `documento_rel` varchar(45) DEFAULT NULL,
  `codigo_traslado` varchar(5) NOT NULL,
  `modalidad_traslado` varchar(5) NOT NULL,
  `fecha_traslado` date NOT NULL,
  `peso_total` float NOT NULL,
  `unidad_peso_total` varchar(10) NOT NULL,
  `numero_bultos` float DEFAULT NULL,
  `ubigeo_llegada` varchar(10) NOT NULL,
  `direccion_llegada` varchar(150) NOT NULL,
  `ubigeo_partida` varchar(10) NOT NULL,
  `direccion_partida` varchar(150) NOT NULL,
  `tipo_documento_transportista` varchar(10) DEFAULT NULL,
  `numero_documento_transportista` varchar(20) DEFAULT NULL,
  `razon_social_transportista` varchar(150) DEFAULT NULL,
  `nro_mtc` varchar(45) DEFAULT NULL,
  `observaciones` text DEFAULT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  `estado` int(11) DEFAULT 1,
  `estado_sunat` int(11) DEFAULT NULL,
  `mensaje_error_sunat` text DEFAULT NULL,
  `xml_base64` text DEFAULT NULL,
  `xml_cdr_sunat_base64` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `guia_remision`
--

INSERT INTO `guia_remision` (`id`, `tipo_documento`, `serie`, `correlativo`, `fecha_emision`, `id_empresa`, `id_cliente`, `id_tipo_documento_rel`, `documento_rel`, `codigo_traslado`, `modalidad_traslado`, `fecha_traslado`, `peso_total`, `unidad_peso_total`, `numero_bultos`, `ubigeo_llegada`, `direccion_llegada`, `ubigeo_partida`, `direccion_partida`, `tipo_documento_transportista`, `numero_documento_transportista`, `razon_social_transportista`, `nro_mtc`, `observaciones`, `id_usuario`, `estado`, `estado_sunat`, `mensaje_error_sunat`, `xml_base64`, `xml_cdr_sunat_base64`) VALUES
(1, '09', 'T001', 1, '2024-03-13', 1, 1, NULL, NULL, '01', '01', '2024-03-13', 200, 'KGM', 4, '140108', 'Av Grau', '140108', 'Av Lima 214', '6', '20605100016', 'RVM MAQUINARIAS S.A.C.', '', NULL, 14, 1, 0, NULL, NULL, NULL),
(2, '09', 'T001', 1, '2024-03-13', 1, 1, NULL, NULL, '01', '01', '2024-03-13', 200, 'KGM', 4, '140108', 'Av Grau', '140108', 'Av Lima 214', '6', '20605100016', 'RVM MAQUINARIAS S.A.C.', '', NULL, 14, 1, 0, NULL, NULL, NULL),
(3, '09', 'T001', 1, '2024-03-13', 1, 1, NULL, NULL, '01', '01', '2024-03-13', 200, 'KGM', 4, '140108', 'Av Grau', '140108', 'Av Lima 214', '6', '20605100016', 'RVM MAQUINARIAS S.A.C.', '', NULL, 14, 1, 0, NULL, NULL, NULL),
(4, '09', 'T001', 1, '2024-03-13', 1, 1, NULL, NULL, '01', '01', '2024-03-13', 200, 'KGM', 4, '140108', 'Av Grau', '140108', 'Av Lima 214', '6', '20605100016', 'RVM MAQUINARIAS S.A.C.', '', NULL, 14, 1, 0, NULL, NULL, NULL),
(5, '09', 'T001', 1, '2024-03-13', 1, 1, NULL, NULL, '01', '01', '2024-03-13', 200, 'KGM', 4, '140108', 'Av Grau', '140108', 'Av Lima 214', '6', '20605100016', 'RVM MAQUINARIAS S.A.C.', '', NULL, 14, 1, 0, NULL, NULL, NULL),
(6, '09', 'T001', 2, '2024-03-13', 1, 1, NULL, NULL, '01', '01', '2024-03-13', 200, 'KGM', 4, '140108', 'Av Grau', '140108', 'Av Lima 214', '6', '20605100016', 'RVM MAQUINARIAS S.A.C.', '', NULL, 14, 1, 0, NULL, NULL, NULL),
(7, '09', 'T001', 3, '2024-03-13', 1, 1, NULL, NULL, '01', '01', '2024-03-13', 200, 'KGM', 4, '140108', 'Av Grau', '140108', 'Av Lima 214', '6', '20605100016', 'RVM MAQUINARIAS S.A.C.', '', NULL, 14, 1, 0, NULL, NULL, NULL),
(8, '09', 'T001', 4, '2024-03-13', 1, 1, NULL, NULL, '01', '01', '2024-03-13', 50, 'KGM', 5, '140108', 'Av Grau 548', '140108', 'Av Limas 123', '6', '20604915351', 'MEN GRAPH S.A.C.', '', NULL, 14, 1, 0, NULL, NULL, NULL),
(9, '09', 'T001', 5, '2024-03-13', 1, 1, NULL, NULL, '01', '01', '2024-03-13', 50, 'KGM', 5, '140108', 'Av grau 234', '140108', 'Av Lima 123', '6', '20604915351', 'MEN GRAPH S.A.C.', '', NULL, 14, 1, 0, NULL, NULL, NULL),
(10, '09', 'T001', 6, '2024-03-13', 1, 1, NULL, NULL, '01', '01', '2024-03-13', 200, 'KGM', 5, '140108', 'Av Agnamos 1234', '140108', 'Av Lima 123', '6', '20604915351', 'MEN GRAPH S.A.C.', '', NULL, 14, 1, 0, NULL, NULL, NULL),
(11, '09', 'T001', 7, '2024-03-13', 1, 1, '01', NULL, '01', '01', '2024-03-13', 200, 'KGM', 5, '140108', 'Av Grau 123', '140108', 'Av Lima 123', '6', '20604915351', 'MEN GRAPH S.A.C.', '', NULL, 14, 1, 0, NULL, NULL, NULL),
(12, '09', 'T001', 8, '2024-03-13', 1, 1, '01', 'F001-156', '01', '01', '2024-03-13', 200, 'KGM', 5, '140108', 'Av Grau 123', '140108', 'Av Lima 123', '6', '20604915351', 'MEN GRAPH S.A.C.', '', NULL, 14, 1, 0, NULL, NULL, NULL),
(13, '09', 'T001', 9, '2024-03-13', 1, 1, '03', 'B002-845', '01', '01', '2024-03-13', 200, 'KGM', 5, '140108', 'Av Grau 345', '140108', 'Av Lima 123', '6', '20604915351', 'MEN GRAPH S.A.C.', '', 'Prueba Guia Remision Remitente', 14, 1, 0, NULL, NULL, NULL),
(14, '09', 'T001', 10, '2024-03-13', 1, 1, '01', 'F005-6548', '01', '01', '2024-03-13', 200, 'KGM', 7, '140108', 'Av Lima 345', '140108', 'Av Lima 123', '6', '20603049684', ' ESTUDIO CONTABLE O & RM S.A.C.', '', 'Guia Remision Remitente 200 Kgm', 14, 1, 0, NULL, NULL, NULL),
(15, '09', 'T001', 11, '2024-03-13', 1, 1, '01', 'F001-159', '01', '01', '2024-03-13', 200, 'KGM', 5, '140108', 'Av Grau 234', '140108', 'Av Lima 123', '6', '20603049684', ' ESTUDIO CONTABLE O & RM S.A.C.', '', '', 14, 1, 0, NULL, NULL, NULL),
(16, '09', 'T001', 12, '2024-03-13', 1, 1, '01', 'F001-565', '01', '01', '2024-03-13', 250, 'KGM', 5, '140108', 'Av Grau 355', '140108', 'Av Lima 213', '6', '20525994741', ' COMERCIAL FERRETERA PRISMA S.A.C. ', '', '', 14, 1, 0, NULL, NULL, NULL),
(17, '09', 'T001', 13, '2024-03-13', 1, 1, '01', 'F001-654', '01', '01', '2024-03-13', 205, 'KGM', 4, '140108', 'Av Grau 456', '140108', 'Av Lima 123', '6', '20538995364', ' D & L TECNOLOGIA Y AUDIO S.R.L.', '', '', 14, 1, 0, NULL, NULL, NULL),
(18, '09', 'T001', 14, '2024-03-13', 1, 1, '01', 'F006-545', '01', '01', '2024-03-13', 120, 'KGM', 3, '140108', 'Av Grau 345', '140108', 'Av Lima 123', '6', '20538995364', ' D & L TECNOLOGIA Y AUDIO S.R.L.', '', '', 14, 1, 0, NULL, NULL, NULL),
(19, '09', 'T001', 15, '2024-03-14', 1, 1, '01', 'F001-154', '01', '01', '2024-03-14', 50, 'KGM', 2, '140108', 'Av Grau 234', '140108', 'Av Lima 123', '6', '20605100016', 'RVM MAQUINARIAS S.A.C.', '', 'Prueba Guia', 14, 1, 0, NULL, NULL, NULL),
(20, '09', 'T001', 16, '2024-03-14', 1, 1, '01', 'F002-234', '01', '02', '2024-03-14', 50, 'KGM', 2, '140108', 'aV gRAU 234', '140108', 'Av lIMA 123', NULL, NULL, NULL, NULL, 'PRUEBA', 14, 1, 0, NULL, NULL, NULL),
(21, '09', 'T001', 17, '2024-03-14', 1, 1, '01', 'F002-565', '01', '02', '2024-03-15', 50, 'KGM', 5, '140108', 'AV GRAU 234', '140108', 'AV LIMA 123', NULL, NULL, NULL, NULL, '', 14, 1, 0, NULL, NULL, NULL),
(22, '09', 'T001', 18, '2024-03-14', 1, 1, '01', 'F002-6546', '01', '02', '2024-03-15', 50, 'KGM', 5, '140108', 'AV GRAU 243', '140108', 'AV LIMA 123', NULL, NULL, NULL, NULL, '', 14, 1, 0, NULL, NULL, NULL),
(23, '09', 'T001', 19, '2024-03-14', 1, 1, '01', 'F001-321', '01', '02', '2024-03-15', 50, 'KGM', 5, '140108', 'AV GRAU 345', '140108', 'AV LIMA 123', NULL, NULL, NULL, NULL, '', 14, 1, 0, NULL, NULL, NULL),
(24, '09', 'T001', 20, '2024-03-14', 1, 1, '01', 'F002-214', '01', '02', '2024-03-15', 50, 'KGM', 5, '140108', 'AV GRAU 345', '140108', 'AV LIMA 123', NULL, NULL, NULL, NULL, '', 14, 1, 0, NULL, NULL, NULL),
(25, '09', 'T001', 21, '2024-03-14', 1, 1, '03', 'B002-654', '01', '02', '2024-03-15', 50, 'KGM', 4, '140108', 'AV GRAU 456', '140108', 'AV LIMA 345', NULL, NULL, NULL, NULL, '', 14, 1, 0, NULL, NULL, NULL),
(26, '09', 'T001', 22, '2024-03-14', 1, 1, '01', 'F001-654', '01', '02', '2024-03-15', 50, 'KGM', 5, '140108', 'AV GRAU 345', '140108', 'AV LIMA 123', NULL, NULL, NULL, NULL, '', 14, 1, 0, NULL, NULL, NULL),
(27, '09', 'T001', 23, '2024-03-17', 1, 6, '01', 'F001-654', '01', '01', '2024-03-17', 200, 'KGM', 5, '140108', 'Av Lima 466', '140108', 'Av Grau 123', '6', '20547825781', 'DMG DRILLING E.I.R.L.', '', 'PRUEBA GUIA REMITENTE', 14, 1, 0, NULL, NULL, NULL),
(28, '09', 'T001', 24, '2024-03-17', 1, 6, '01', 'F001-654', '01', '01', '2024-03-17', 20, 'KGM', 5, '140108', 'av lima 454', '140108', 'av grau 123', '6', '20603498799', 'ESCUELA DE DETECTIVES PRIVADOS DEL PERU E.I.R.L. - ESDEPRIP', '', '', 14, 1, 0, NULL, NULL, NULL),
(29, '09', 'T001', 25, '2024-03-17', 1, 6, '01', 'F001-654', '01', '01', '2024-03-17', 20, 'KGM', 5, '140108', 'av lima 454', '140108', 'av grau 123', '6', '20603498799', 'ESCUELA DE DETECTIVES PRIVADOS DEL PERU E.I.R.L. - ESDEPRIP', '', '', 14, 1, 0, NULL, NULL, NULL),
(30, '09', 'T001', 26, '2024-03-17', 1, 6, '01', 'F001-654', '01', '01', '2024-03-17', 20, 'KGM', 5, '140108', 'av lima 454', '140108', 'av grau 123', '6', '20603498799', 'ESCUELA DE DETECTIVES PRIVADOS DEL PERU E.I.R.L. - ESDEPRIP', '', '', 14, 1, 0, NULL, NULL, NULL),
(31, '09', 'T001', 27, '2024-03-17', 1, 6, '01', 'F001-321', '01', '01', '2024-03-17', 20, 'KGM', 2, '140108', 'av grau 214', '140108', 'av lima 123', '6', '20603498799', 'ESCUELA DE DETECTIVES PRIVADOS DEL PERU E.I.R.L. - ESDEPRIP', '', '', 14, 1, 0, NULL, NULL, NULL),
(32, '09', 'T001', 28, '2024-03-17', 1, 6, '03', 'B001-654', '01', '01', '2024-03-17', 20, 'KGM', 5, '140108', 'av grau 456', '140108', 'av lima 123', '6', '20603498799', 'ESCUELA DE DETECTIVES PRIVADOS DEL PERU E.I.R.L. - ESDEPRIP', '', '', 14, 1, 0, NULL, NULL, NULL),
(33, '09', 'T001', 29, '2024-03-17', 1, 6, '01', 'F001-654', '01', '01', '2024-03-17', 20, 'KGM', 5, '140108', 'av grau 345', '140108', 'av lima 213', '6', '20603498799', 'ESCUELA DE DETECTIVES PRIVADOS DEL PERU E.I.R.L. - ESDEPRIP', '', '', 14, 1, 0, NULL, NULL, NULL),
(34, '09', 'T001', 30, '2024-03-17', 1, 6, '01', 'F001-654', '01', '01', '2024-03-17', 20, 'KGM', 5, '140108', 'av Lima 123', '140108', 'av grau 123', '6', '20553856451', 'BI GRAND CONFECCIONES S.A.C.', '', '', 14, 1, 0, NULL, NULL, NULL),
(35, '09', 'T001', 31, '2024-03-17', 1, 6, '01', 'F001-987', '01', '02', '2024-03-17', 20, 'KGM', 5, '140108', 'Av Grau 435', '140108', 'av lima 123', NULL, NULL, NULL, NULL, '', 14, 1, 0, NULL, NULL, NULL),
(36, '09', 'T001', 32, '2024-03-17', 1, 6, '01', 'F001-564', '01', '02', '2024-03-17', 20, 'KGM', 5, '140108', 'Av Lima 234', '140108', 'av Grau 123', NULL, NULL, NULL, NULL, '', 14, 1, 0, NULL, NULL, NULL),
(37, '09', 'T001', 33, '2024-03-17', 1, 6, '01', 'F001-193', '01', '02', '2024-03-17', 20, 'KGM', 5, '140108', 'av lima 345', '140108', 'AV grau 123', NULL, NULL, NULL, NULL, '', 14, 1, 0, NULL, NULL, NULL),
(38, '09', 'T001', 34, '2024-03-17', 1, 6, '01', 'F001-193', '01', '02', '2024-03-17', 20, 'KGM', 5, '140108', 'av lima 345', '140108', 'AV grau 123', NULL, NULL, NULL, NULL, '', 14, 1, 0, NULL, NULL, NULL),
(39, '09', 'T001', 35, '2024-03-17', 1, 6, '01', 'F001-193', '01', '02', '2024-03-17', 20, 'KGM', 5, '140108', 'av lima 345', '140108', 'AV grau 123', NULL, NULL, NULL, NULL, '', 14, 1, 0, NULL, NULL, NULL),
(40, '09', 'T001', 36, '2024-03-17', 1, 6, '01', 'F001-193', '01', '02', '2024-03-17', 20, 'KGM', 5, '140108', 'av lima 345', '140108', 'AV grau 123', NULL, NULL, NULL, NULL, '', 14, 1, 0, NULL, NULL, NULL),
(41, '09', 'T001', 37, '2024-03-17', 1, 6, '01', 'F001-193', '01', '02', '2024-03-17', 20, 'KGM', 5, '140108', 'av lima 345', '140108', 'AV grau 123', NULL, NULL, NULL, NULL, '', 14, 1, 0, NULL, NULL, NULL),
(42, '09', 'T001', 38, '2024-03-17', 1, 6, '01', 'F001-4456', '01', '02', '2024-03-23', 20, 'KGM', 5, '140108', 'Av Lima 234', '140108', 'av grau 123', NULL, NULL, NULL, NULL, 'EMISION DE GUIA DE REMISION REMITENTE CON MODALIDAD TRANSPORTE PRIVADO', 14, 1, 0, NULL, NULL, NULL),
(43, '09', 'T001', 39, '2024-03-17', 1, 6, '01', 'F001-654', '01', '01', '2024-03-17', 20, 'KGM', 5, '140108', 'Av Lima 123', '140108', 'av grau 123', '6', '20525994741', 'COMERCIAL FERRETERA PRISMA', '', 'prueba GRR', 14, 1, 0, NULL, NULL, NULL),
(44, '09', 'T001', 40, '2024-03-17', 1, 4, '03', 'B001-699', '01', '02', '2024-03-17', 20, 'KGM', 5, '140108', 'av lima 123', '140108', 'av grau 123', NULL, NULL, NULL, NULL, 'prueba', 14, 1, 0, NULL, NULL, NULL),
(45, '31', 'V001', 1, '2024-03-18', 1, 6, '01', 'F001-65421', '', '', '2024-03-18', 20, 'KGM', 5, '140108', 'AV LIMA 456', '140108', 'AV GRAU 356', NULL, NULL, NULL, '', '', 14, 1, 0, NULL, NULL, NULL),
(46, '31', 'V001', 1, '2024-03-18', 1, 6, '01', 'F001-654', '', '', '2024-03-18', 34, 'KGM', 5, '140108', 'av lima 355', '140108', 'av grau 123', NULL, NULL, NULL, '', '', 14, 1, 0, NULL, NULL, NULL),
(47, '31', 'V001', 1, '2024-03-18', 1, 6, '01', 'F001-654', '', '', '2024-03-18', 20, 'KGM', 2, '140108', 'Av Grau 345', '140108', 'Av Lima 123', NULL, NULL, NULL, '', '', 14, 1, 0, NULL, NULL, NULL),
(48, '09', 'T001', 41, '2024-03-18', 1, 6, '01', 'F001-654', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'av lima 234', '140108', 'av grau 123', '6', '20494099153', 'CORPORACION ROANKA SOCIEDAD ANONIMA CERRADA', '', '', 14, 1, 0, NULL, NULL, NULL),
(49, '09', 'T001', 42, '2024-03-18', 1, 6, '01', 'F001-654', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'av lima 456', '140108', 'av grau 234', '6', '20494099153', 'OMERCIAL FERRETERA ', '', '', 14, 1, 0, NULL, NULL, NULL),
(50, '09', 'T001', 43, '2024-03-18', 1, 6, '01', 'F001-654897', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'av lima 345', '140108', 'av grau 123', '6', '20605100016', 'RVM MAQUINARIAS', '', '', 14, 1, 0, NULL, NULL, NULL),
(51, '09', 'T001', 44, '2024-03-18', 1, 6, '01', 'F001-6545', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'av lima 466', '140108', 'av grau 234', '6', '20605100016', 'RVM MAQUINARIAS S.A.C.', '', '', 14, 1, 0, NULL, NULL, NULL),
(52, '31', 'V001', 1, '2024-03-18', 1, 6, '01', 'F001-456', '', '', '2024-03-18', 20, 'KGM', 5, '140108', 'av grau 456', '140108', 'av lima 213', NULL, NULL, NULL, '', '', 14, 1, 0, NULL, NULL, NULL),
(53, '31', 'V001', 1, '2024-03-18', 1, 6, '01', 'F001-456', '', '', '2024-03-18', 20, 'KGM', 5, '140108', 'av grau 456', '140108', 'av lima 213', NULL, NULL, NULL, '', '', 14, 1, 0, NULL, NULL, NULL),
(54, '31', 'V001', 1, '2024-03-18', 1, 6, '01', 'F001-456', '', '', '2024-03-18', 20, 'KGM', 5, '140108', 'av grau 456', '140108', 'av lima 213', NULL, NULL, NULL, '', '', 14, 1, 0, NULL, NULL, NULL),
(55, '09', 'T001', 45, '2024-03-18', 1, 6, '01', 'F001-654', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'AV GRAU 456', '140108', 'AV LIMA 123', '6', '20538856674', 'TRANSPORTES PRUEBA SAC', '', '', 14, 1, 0, NULL, NULL, NULL),
(56, '09', 'T001', 46, '2024-03-18', 1, 6, '01', 'F001-231654', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'AV LIMA 355', '140108', 'AV GRAU 123', '6', '20538856674', 'TRANSPORTES SAC', '', '', 14, 1, 0, NULL, NULL, NULL),
(57, '09', 'T001', 47, '2024-03-18', 1, 6, '01', 'F001-156', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'av lima 345', '140108', 'av grau 345', '6', '20538856674', 'ARTROSCOPICTRAUMA', '', '', 14, 1, 0, NULL, NULL, NULL),
(58, '09', 'T001', 48, '2024-03-18', 1, 6, '01', 'F001-654', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'av limas 34', '140108', 'av grau 123', '6', '20538856674', 'ARTROSCOPICTRAUMA', '', '', 14, 1, 0, NULL, NULL, NULL),
(59, '09', 'T001', 49, '2024-03-18', 1, 6, '01', 'F001-156', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'AV GRAU 345', '140108', 'AV LIMA 213', '6', '20538995364', ' D & L TECNOLOGIA Y AUDIO S.R.L.', '', '', 14, 1, 0, NULL, NULL, NULL),
(60, '09', 'T001', 50, '2024-03-18', 1, 6, '01', 'F001-156', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'AV GRAU 345', '140108', 'AV LIMA 213', '6', '20538995364', ' D & L TECNOLOGIA Y AUDIO S.R.L.', '', '', 14, 1, 0, NULL, NULL, NULL),
(61, '09', 'T001', 51, '2024-03-18', 1, 6, '01', 'F001-156', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'AV GRAU 345', '140108', 'AV LIMA 213', '6', '20538995364', ' D & L TECNOLOGIA Y AUDIO S.R.L.', '', '', 14, 1, 0, NULL, NULL, NULL),
(62, '09', 'T001', 52, '2024-03-18', 1, 6, '01', 'F001-156', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'AV GRAU 345', '140108', 'AV LIMA 213', '6', '20538995364', ' D & L TECNOLOGIA Y AUDIO S.R.L.', '', '', 14, 1, 0, NULL, NULL, NULL),
(63, '09', 'T001', 53, '2024-03-18', 1, 6, '01', 'F001-156', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'AV GRAU 345', '140108', 'AV LIMA 213', '6', '20538995364', ' D & L TECNOLOGIA Y AUDIO S.R.L.', '', '', 14, 1, 0, NULL, NULL, NULL),
(64, '09', 'T001', 54, '2024-03-18', 1, 6, '01', 'F001-156', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'AV GRAU 345', '140108', 'AV LIMA 213', '6', '20538995364', ' D & L TECNOLOGIA Y AUDIO S.R.L.', '', '', 14, 1, 0, NULL, NULL, NULL),
(65, '09', 'T001', 55, '2024-03-18', 1, 6, '01', 'F001-156', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'AV GRAU 345', '140108', 'AV LIMA 213', '6', '20538995364', ' D & L TECNOLOGIA Y AUDIO S.R.L.', '', '', 14, 1, 2567, 'Vehiculo principal: 2567 (nodo: \"cac:TransportEquipment/cbc:ID\" valor: \"ASD-5458\")', 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPERlc3BhdGNoQWR2aWNlIHhtbG5zPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpEZXNwYXRjaEFkdmljZS0yIiB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyIgeG1sbnM6Y2FjPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpDb21tb25BZ2dyZWdhdGVDb21wb25lbnRzLTIiIHhtbG5zOmNiYz0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uQmFzaWNDb21wb25lbnRzLTIiIHhtbG5zOmV4dD0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uRXh0ZW5zaW9uQ29tcG9uZW50cy0yIj48ZXh0OlVCTEV4dGVuc2lvbnM+PGV4dDpVQkxFeHRlbnNpb24+PGV4dDpFeHRlbnNpb25Db250ZW50PjxkczpTaWduYXR1cmUgSWQ9IkdyZWVudGVyU2lnbiI+PGRzOlNpZ25lZEluZm8+PGRzOkNhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy9UUi8yMDAxL1JFQy14bWwtYzE0bi0yMDAxMDMxNSIvPjxkczpTaWduYXR1cmVNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjcnNhLXNoYTEiLz48ZHM6UmVmZXJlbmNlIFVSST0iIj48ZHM6VHJhbnNmb3Jtcz48ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI2VudmVsb3BlZC1zaWduYXR1cmUiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8+PGRzOkRpZ2VzdFZhbHVlPllwWTVxYXc0c3VIQ0VsVkh6WGlBMko4RDVqST08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+YmU1WU1IYUtxcWxOSTRyUGd1cXhGdjQ3ZDBNNU1rSExnSmRrTWJ0RmkrbnRqczlMa3RicTBXL2NkRWlFUSs5N2huTmcxWWlLR1U1OWJwVXRKQlNxTWQzbWFJd3Z0Y0s3S1ZVSlYxbm5kbUV0c2t4em45Qms5Q0wyY1d6VkVIaTlwS2g1bDhTcForV0I0eFY3UHN1eXB6VUR2QWhWaktiaFlzTE40VEtvK1FmQWdQMEFZYzVJV0VEWWVrdWxTeDd1TGV0SnkzcTM3eW13SHcwdGVwYlZJYWZNSFJ5Yjd2eU9QNWRiUHlDcE9FdzdMVFUrb3BiLzBJZFN5eTRESThjK2NiZVcySytLaVl4SFJwY05pN1F0cmpWZ0JCTGJadE8rM0tlY3dQd0dQRnBRTWkrUElta3hwUGlHRVFkVEE5VzRyM1ZKZk5qNDFhL3NkWjhEN3Q2ajZBPT08L2RzOlNpZ25hdHVyZVZhbHVlPjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUZDRENDQS9DZ0F3SUJBZ0lKQU9ja2tZN2hrT3l6TUEwR0NTcUdTSWIzRFFFQkN3VUFNSUlCRFRFYk1Ca0dDZ21TSm9tVDhpeGtBUmtXQzB4TVFVMUJMbEJGSUZOQk1Rc3dDUVlEVlFRR0V3SlFSVEVOTUFzR0ExVUVDQXdFVEVsTlFURU5NQXNHQTFVRUJ3d0VURWxOUVRFWU1CWUdBMVVFQ2d3UFZGVWdSVTFRVWtWVFFTQlRMa0V1TVVVd1F3WURWUVFMRER4RVRra2dPVGs1T1RrNU9TQlNWVU1nTWpBME5USTFOemc1TlRFZ0xTQkRSVkpVU1VaSlEwRkVUeUJRUVZKQklFUkZUVTlUVkZKQlEwbkRrMDR4UkRCQ0JnTlZCQU1NTzA1UFRVSlNSU0JTUlZCU1JWTkZUbFJCVGxSRklFeEZSMEZNSUMwZ1EwVlNWRWxHU1VOQlJFOGdVRUZTUVNCRVJVMVBVMVJTUVVOSnc1Tk9NUnd3R2dZSktvWklodmNOQVFrQkZnMWtaVzF2UUd4c1lXMWhMbkJsTUI0WERUSTBNREl5T1RBeE1EYzFPVm9YRFRJMk1ESXlPREF4TURjMU9Wb3dnZ0VOTVJzd0dRWUtDWkltaVpQeUxHUUJHUllMVEV4QlRVRXVVRVVnVTBFeEN6QUpCZ05WQkFZVEFsQkZNUTB3Q3dZRFZRUUlEQVJNU1UxQk1RMHdDd1lEVlFRSERBUk1TVTFCTVJnd0ZnWURWUVFLREE5VVZTQkZUVkJTUlZOQklGTXVRUzR4UlRCREJnTlZCQXNNUEVST1NTQTVPVGs1T1RrNUlGSlZReUF5TURRMU1qVTNPRGsxTVNBdElFTkZVbFJKUmtsRFFVUlBJRkJCVWtFZ1JFVk5UMU5VVWtGRFNjT1RUakZFTUVJR0ExVUVBd3c3VGs5TlFsSkZJRkpGVUZKRlUwVk9WRUZPVkVVZ1RFVkhRVXdnTFNCRFJWSlVTVVpKUTBGRVR5QlFRVkpCSUVSRlRVOVRWRkpCUTBuRGswNHhIREFhQmdrcWhraUc5dzBCQ1FFV0RXUmxiVzlBYkd4aGJXRXVjR1V3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRRFR0SGRjQmNuZUJ2bnorM0JwejhhUGFaM2RaY05ZK29aZ3hYTlFheFpvdzBaYStwb0k2Rjk0cHlZelZyOWY3alZoMW16UFFjZ3NLU3Fpd1ZlOS9IMzBwbkM1NEpyWXVEa2pKL3hQOE5yM0E3VHJDR0RXSVFaTmR4NEhIYWFwaTZiZENuUkxrZFNBam5FWkRhV1FWeWRyRFJVODRqVktOSXVNejBmaE8rRWwxZWI3SGZlelJiTHFERDFRTjI4SkwvZWlONExJbHlKUTJvOU5iRjEySEJZb1kxb01sQ2pnZFM3TWNVNlZaNWdqYzQzL0kyTDVVemZlWDVSK1pQbEFZR2tYMXBLVTBBQmFiOWZlTHFKVUdWOGRJNDVmQTdqZzJOKzdHcjlqeXlDQkZLY3hBV1IveitGTmI3WkZYL0kzK3BkcjhVeWpzUzJRczVaaXNyZWhVdnkvQWdNQkFBR2paekJsTUIwR0ExVWREZ1FXQkJUWVNhYm85Yjc5eWxOK2wzM3BZQlRIRW1XTXBEQWZCZ05WSFNNRUdEQVdnQlRZU2FibzliNzl5bE4rbDMzcFlCVEhFbVdNcERBVEJnTlZIU1VFRERBS0JnZ3JCZ0VGQlFjREFUQU9CZ05WSFE4QkFmOEVCQU1DQjRBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFGNll4NWFKSGFOSlJkczh5MHRCOUVCWERqTTErYStQV1V2cWJGNmZ4c0Q0SjBiZ1JLQzBSZnFWcU1uZm9TMklvcTBkSEhvbUFhQVBoM05McjFJUlZVVHJYWHorRGJqQnEvdkNsNENtSVgrYlhmVTFrWUZJb0VQS3RjQlJUYlFQVWEwYnpJRFl3UWpqNW1iaUpDVSs1VXpqa01xZ1o2V1F1Z1dHYVA4UThsWG4xMkhvR1JIQm9oWHlRYysyb0NwZGhaRisxMEQzZzVLK1prQ1VaSERQNXZXVERSNmhLVUh3YWc3VjZXc1BxVzRZd2xsY0F3QkxIVmpPc0R4cWQ0WHlyaVhGTy9jWVpNc2ZoZzBRZUMvQjVHK3Vkem41eHdPLzJ3ZlJFWlhIamtUOGxqb2taeWhLVzlYMkZUUFltR3dTWWloNEZVdEcvR1BxOFFRVnFrTm9ZaE09PC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpTaWduYXR1cmU+PC9leHQ6RXh0ZW5zaW9uQ29udGVudD48L2V4dDpVQkxFeHRlbnNpb24+PC9leHQ6VUJMRXh0ZW5zaW9ucz48Y2JjOlVCTFZlcnNpb25JRD4yLjE8L2NiYzpVQkxWZXJzaW9uSUQ+PGNiYzpDdXN0b21pemF0aW9uSUQ+Mi4wPC9jYmM6Q3VzdG9taXphdGlvbklEPjxjYmM6SUQ+VDAwMS01NTwvY2JjOklEPjxjYmM6SXNzdWVEYXRlPjIwMjQtMDMtMTc8L2NiYzpJc3N1ZURhdGU+PGNiYzpJc3N1ZVRpbWU+MTg6MDA6MDA8L2NiYzpJc3N1ZVRpbWU+PGNiYzpEZXNwYXRjaEFkdmljZVR5cGVDb2RlIGxpc3RBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgbGlzdE5hbWU9IlRpcG8gZGUgRG9jdW1lbnRvIiBsaXN0VVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzAxIj4wOTwvY2JjOkRlc3BhdGNoQWR2aWNlVHlwZUNvZGU+PGNhYzpTaWduYXR1cmU+PGNiYzpJRD4yMDQ1MjU3ODk1NzwvY2JjOklEPjxjYWM6U2lnbmF0b3J5UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQ+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlOYW1lPjxjYmM6TmFtZT48IVtDREFUQVtUVVRPUklBTEVTIFBIUEVSVV1dPjwvY2JjOk5hbWU+PC9jYWM6UGFydHlOYW1lPjwvY2FjOlNpZ25hdG9yeVBhcnR5PjxjYWM6RGlnaXRhbFNpZ25hdHVyZUF0dGFjaG1lbnQ+PGNhYzpFeHRlcm5hbFJlZmVyZW5jZT48Y2JjOlVSST4jR1JFRU5URVItU0lHTjwvY2JjOlVSST48L2NhYzpFeHRlcm5hbFJlZmVyZW5jZT48L2NhYzpEaWdpdGFsU2lnbmF0dXJlQXR0YWNobWVudD48L2NhYzpTaWduYXR1cmU+PGNhYzpEZXNwYXRjaFN1cHBsaWVyUGFydHk+PGNhYzpQYXJ0eT48Y2FjOlBhcnR5SWRlbnRpZmljYXRpb24+PGNiYzpJRCBzY2hlbWVJRD0iNiIgc2NoZW1lTmFtZT0iRG9jdW1lbnRvIGRlIElkZW50aWRhZCIgc2NoZW1lQWdlbmN5TmFtZT0iUEU6U1VOQVQiIHNjaGVtZVVSST0idXJuOnBlOmdvYjpzdW5hdDpjcGU6c2VlOmdlbTpjYXRhbG9nb3M6Y2F0YWxvZ28wNiI+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlMZWdhbEVudGl0eT48Y2JjOlJlZ2lzdHJhdGlvbk5hbWU+PCFbQ0RBVEFbVFVUT1JJQUxFUyBQSFBFUlVdXT48L2NiYzpSZWdpc3RyYXRpb25OYW1lPjwvY2FjOlBhcnR5TGVnYWxFbnRpdHk+PC9jYWM6UGFydHk+PC9jYWM6RGVzcGF0Y2hTdXBwbGllclBhcnR5PjxjYWM6RGVsaXZlcnlDdXN0b21lclBhcnR5PjxjYWM6UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQgc2NoZW1lSUQ9IjEiIHNjaGVtZU5hbWU9IkRvY3VtZW50byBkZSBJZGVudGlkYWQiIHNjaGVtZUFnZW5jeU5hbWU9IlBFOlNVTkFUIiBzY2hlbWVVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMDYiPjQ1MjU3ODk1PC9jYmM6SUQ+PC9jYWM6UGFydHlJZGVudGlmaWNhdGlvbj48Y2FjOlBhcnR5TGVnYWxFbnRpdHk+PGNiYzpSZWdpc3RyYXRpb25OYW1lPjwhW0NEQVRBW0xVSVMgQU5HRUwgTE9aQU5PIEFSSUNBXV0+PC9jYmM6UmVnaXN0cmF0aW9uTmFtZT48L2NhYzpQYXJ0eUxlZ2FsRW50aXR5PjwvY2FjOlBhcnR5PjwvY2FjOkRlbGl2ZXJ5Q3VzdG9tZXJQYXJ0eT48Y2FjOlNoaXBtZW50PjxjYmM6SUQ+U1VOQVRfRW52aW88L2NiYzpJRD48Y2JjOkhhbmRsaW5nQ29kZSBsaXN0QWdlbmN5TmFtZT0iUEU6U1VOQVQiIGxpc3ROYW1lPSJNb3Rpdm8gZGUgdHJhc2xhZG8iIGxpc3RVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMjAiPjAxPC9jYmM6SGFuZGxpbmdDb2RlPjxjYmM6R3Jvc3NXZWlnaHRNZWFzdXJlIHVuaXRDb2RlPSJLR00iPjIwLjAwMDwvY2JjOkdyb3NzV2VpZ2h0TWVhc3VyZT48Y2JjOlRvdGFsVHJhbnNwb3J0SGFuZGxpbmdVbml0UXVhbnRpdHk+NTwvY2JjOlRvdGFsVHJhbnNwb3J0SGFuZGxpbmdVbml0UXVhbnRpdHk+PGNhYzpTaGlwbWVudFN0YWdlPjxjYmM6VHJhbnNwb3J0TW9kZUNvZGUgbGlzdE5hbWU9Ik1vZGFsaWRhZCBkZSB0cmFzbGFkbyIgbGlzdEFnZW5jeU5hbWU9IlBFOlNVTkFUIiBsaXN0VVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzE4Ij4wMTwvY2JjOlRyYW5zcG9ydE1vZGVDb2RlPjxjYWM6VHJhbnNpdFBlcmlvZD48Y2JjOlN0YXJ0RGF0ZT4yMDI0LTAzLTE3PC9jYmM6U3RhcnREYXRlPjwvY2FjOlRyYW5zaXRQZXJpb2Q+PGNhYzpDYXJyaWVyUGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQgc2NoZW1lSUQ9IjYiPjIwNTM4OTk1MzY0PC9jYmM6SUQ+PC9jYWM6UGFydHlJZGVudGlmaWNhdGlvbj48Y2FjOlBhcnR5TGVnYWxFbnRpdHk+PGNiYzpSZWdpc3RyYXRpb25OYW1lPjwhW0NEQVRBWyBEICYgTCBURUNOT0xPR0lBIFkgQVVESU8gUy5SLkwuXV0+PC9jYmM6UmVnaXN0cmF0aW9uTmFtZT48Y2JjOkNvbXBhbnlJRC8+PC9jYWM6UGFydHlMZWdhbEVudGl0eT48L2NhYzpDYXJyaWVyUGFydHk+PC9jYWM6U2hpcG1lbnRTdGFnZT48Y2FjOkRlbGl2ZXJ5PjxjYWM6RGVsaXZlcnlBZGRyZXNzPjxjYmM6SUQgc2NoZW1lQWdlbmN5TmFtZT0iUEU6SU5FSSIgc2NoZW1lTmFtZT0iVWJpZ2VvcyI+MTQwMTA4PC9jYmM6SUQ+PGNhYzpBZGRyZXNzTGluZT48Y2JjOkxpbmU+YXYgZ3JhdSAzNDU8L2NiYzpMaW5lPjwvY2FjOkFkZHJlc3NMaW5lPjwvY2FjOkRlbGl2ZXJ5QWRkcmVzcz48Y2FjOkRlc3BhdGNoPjxjYWM6RGVzcGF0Y2hBZGRyZXNzPjxjYmM6SUQgc2NoZW1lQWdlbmN5TmFtZT0iUEU6SU5FSSIgc2NoZW1lTmFtZT0iVWJpZ2VvcyI+MTQwMTA4PC9jYmM6SUQ+PGNhYzpBZGRyZXNzTGluZT48Y2JjOkxpbmU+YXYgbGltYSAyMTM8L2NiYzpMaW5lPjwvY2FjOkFkZHJlc3NMaW5lPjwvY2FjOkRlc3BhdGNoQWRkcmVzcz48L2NhYzpEZXNwYXRjaD48L2NhYzpEZWxpdmVyeT48L2NhYzpTaGlwbWVudD48Y2FjOkRlc3BhdGNoTGluZT48Y2JjOklEPjE8L2NiYzpJRD48Y2JjOkRlbGl2ZXJlZFF1YW50aXR5IHVuaXRDb2RlPSJOSVUiPjE8L2NiYzpEZWxpdmVyZWRRdWFudGl0eT48Y2FjOk9yZGVyTGluZVJlZmVyZW5jZT48Y2JjOkxpbmVJRD4xPC9jYmM6TGluZUlEPjwvY2FjOk9yZGVyTGluZVJlZmVyZW5jZT48Y2FjOkl0ZW0+PGNiYzpEZXNjcmlwdGlvbj48IVtDREFUQVtGQU5UQSBOQVJBTkpBIDUwME1MXV0+PC9jYmM6RGVzY3JpcHRpb24+PGNhYzpTZWxsZXJzSXRlbUlkZW50aWZpY2F0aW9uPjxjYmM6SUQ+Nzc1NTEzOTAwMjg1MTwvY2JjOklEPjwvY2FjOlNlbGxlcnNJdGVtSWRlbnRpZmljYXRpb24+PC9jYWM6SXRlbT48L2NhYzpEZXNwYXRjaExpbmU+PGNhYzpEZXNwYXRjaExpbmU+PGNiYzpJRD4yPC9jYmM6SUQ+PGNiYzpEZWxpdmVyZWRRdWFudGl0eSB1bml0Q29kZT0iTklVIj4xPC9jYmM6RGVsaXZlcmVkUXVhbnRpdHk+PGNhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNiYzpMaW5lSUQ+MjwvY2JjOkxpbmVJRD48L2NhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNhYzpJdGVtPjxjYmM6RGVzY3JpcHRpb24+PCFbQ0RBVEFbREVMRUlURSAxTF1dPjwvY2JjOkRlc2NyaXB0aW9uPjxjYWM6U2VsbGVyc0l0ZW1JZGVudGlmaWNhdGlvbj48Y2JjOklEPjc3NTUxMzkwMDI5MDI8L2NiYzpJRD48L2NhYzpTZWxsZXJzSXRlbUlkZW50aWZpY2F0aW9uPjwvY2FjOkl0ZW0+PC9jYWM6RGVzcGF0Y2hMaW5lPjwvRGVzcGF0Y2hBZHZpY2U+Cg==', NULL),
(66, '09', 'T001', 56, '2024-03-18', 1, 6, '01', 'F001-156', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'AV GRAU 345', '140108', 'AV LIMA 213', '6', '20538995364', ' D & L TECNOLOGIA Y AUDIO S.R.L.', '', '', 14, 1, 2567, 'Vehiculo principal: 2567 (nodo: \"cac:TransportEquipment/cbc:ID\" valor: \"ASD-5458\")', 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPERlc3BhdGNoQWR2aWNlIHhtbG5zPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpEZXNwYXRjaEFkdmljZS0yIiB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyIgeG1sbnM6Y2FjPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpDb21tb25BZ2dyZWdhdGVDb21wb25lbnRzLTIiIHhtbG5zOmNiYz0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uQmFzaWNDb21wb25lbnRzLTIiIHhtbG5zOmV4dD0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uRXh0ZW5zaW9uQ29tcG9uZW50cy0yIj48ZXh0OlVCTEV4dGVuc2lvbnM+PGV4dDpVQkxFeHRlbnNpb24+PGV4dDpFeHRlbnNpb25Db250ZW50PjxkczpTaWduYXR1cmUgSWQ9IkdyZWVudGVyU2lnbiI+PGRzOlNpZ25lZEluZm8+PGRzOkNhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy9UUi8yMDAxL1JFQy14bWwtYzE0bi0yMDAxMDMxNSIvPjxkczpTaWduYXR1cmVNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjcnNhLXNoYTEiLz48ZHM6UmVmZXJlbmNlIFVSST0iIj48ZHM6VHJhbnNmb3Jtcz48ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI2VudmVsb3BlZC1zaWduYXR1cmUiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8+PGRzOkRpZ2VzdFZhbHVlPnJyMG5iMWhRRG9oYVlXaTVHb1ZNMDJlc1J4WT08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+VDU0WE12VldkaFNIdGkyem9lcGJ0RXRKT01zN3Y3WnRJWnNXOUpYMU1jOTMvNjY4dHlWK2FoZDRNSWUyMk5rT0tBb0hqeHEwMlkzSVdYeWYraHI1Y0RJME5XT2FaemJ6d0FBZ0lqb3pPMDdqZUN5SURrSzl4eERjWmxMb2xrN01UWGlzbHVKY3RmTVY4QTBHalZmZkdXa1A5Qk5NaktmWTVtTTJMem9ZNzR6Q3EySVV2OTljRnZpU2ZMTHlFVm55QnFPRm81M3ArSFNmaTYyS2RpdFdKTzJJNCtQQXQ4NDRPRTNIVDg3V2NYTHBCRHNLbG5oNjBQZHMrZ3dQQVVJczBIS1NOMUhPL3ZxblFOczJUOTlWMzluZ2pTcFdrQnlwSjFQYjJMR3pIbCtwTVU3bEkyUFhPNGRJK0RKVGRxbndRNC8zOUh5dXdLZ0F4SHk2a1RGemdnPT08L2RzOlNpZ25hdHVyZVZhbHVlPjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUZDRENDQS9DZ0F3SUJBZ0lKQU9ja2tZN2hrT3l6TUEwR0NTcUdTSWIzRFFFQkN3VUFNSUlCRFRFYk1Ca0dDZ21TSm9tVDhpeGtBUmtXQzB4TVFVMUJMbEJGSUZOQk1Rc3dDUVlEVlFRR0V3SlFSVEVOTUFzR0ExVUVDQXdFVEVsTlFURU5NQXNHQTFVRUJ3d0VURWxOUVRFWU1CWUdBMVVFQ2d3UFZGVWdSVTFRVWtWVFFTQlRMa0V1TVVVd1F3WURWUVFMRER4RVRra2dPVGs1T1RrNU9TQlNWVU1nTWpBME5USTFOemc1TlRFZ0xTQkRSVkpVU1VaSlEwRkVUeUJRUVZKQklFUkZUVTlUVkZKQlEwbkRrMDR4UkRCQ0JnTlZCQU1NTzA1UFRVSlNSU0JTUlZCU1JWTkZUbFJCVGxSRklFeEZSMEZNSUMwZ1EwVlNWRWxHU1VOQlJFOGdVRUZTUVNCRVJVMVBVMVJTUVVOSnc1Tk9NUnd3R2dZSktvWklodmNOQVFrQkZnMWtaVzF2UUd4c1lXMWhMbkJsTUI0WERUSTBNREl5T1RBeE1EYzFPVm9YRFRJMk1ESXlPREF4TURjMU9Wb3dnZ0VOTVJzd0dRWUtDWkltaVpQeUxHUUJHUllMVEV4QlRVRXVVRVVnVTBFeEN6QUpCZ05WQkFZVEFsQkZNUTB3Q3dZRFZRUUlEQVJNU1UxQk1RMHdDd1lEVlFRSERBUk1TVTFCTVJnd0ZnWURWUVFLREE5VVZTQkZUVkJTUlZOQklGTXVRUzR4UlRCREJnTlZCQXNNUEVST1NTQTVPVGs1T1RrNUlGSlZReUF5TURRMU1qVTNPRGsxTVNBdElFTkZVbFJKUmtsRFFVUlBJRkJCVWtFZ1JFVk5UMU5VVWtGRFNjT1RUakZFTUVJR0ExVUVBd3c3VGs5TlFsSkZJRkpGVUZKRlUwVk9WRUZPVkVVZ1RFVkhRVXdnTFNCRFJWSlVTVVpKUTBGRVR5QlFRVkpCSUVSRlRVOVRWRkpCUTBuRGswNHhIREFhQmdrcWhraUc5dzBCQ1FFV0RXUmxiVzlBYkd4aGJXRXVjR1V3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRRFR0SGRjQmNuZUJ2bnorM0JwejhhUGFaM2RaY05ZK29aZ3hYTlFheFpvdzBaYStwb0k2Rjk0cHlZelZyOWY3alZoMW16UFFjZ3NLU3Fpd1ZlOS9IMzBwbkM1NEpyWXVEa2pKL3hQOE5yM0E3VHJDR0RXSVFaTmR4NEhIYWFwaTZiZENuUkxrZFNBam5FWkRhV1FWeWRyRFJVODRqVktOSXVNejBmaE8rRWwxZWI3SGZlelJiTHFERDFRTjI4SkwvZWlONExJbHlKUTJvOU5iRjEySEJZb1kxb01sQ2pnZFM3TWNVNlZaNWdqYzQzL0kyTDVVemZlWDVSK1pQbEFZR2tYMXBLVTBBQmFiOWZlTHFKVUdWOGRJNDVmQTdqZzJOKzdHcjlqeXlDQkZLY3hBV1IveitGTmI3WkZYL0kzK3BkcjhVeWpzUzJRczVaaXNyZWhVdnkvQWdNQkFBR2paekJsTUIwR0ExVWREZ1FXQkJUWVNhYm85Yjc5eWxOK2wzM3BZQlRIRW1XTXBEQWZCZ05WSFNNRUdEQVdnQlRZU2FibzliNzl5bE4rbDMzcFlCVEhFbVdNcERBVEJnTlZIU1VFRERBS0JnZ3JCZ0VGQlFjREFUQU9CZ05WSFE4QkFmOEVCQU1DQjRBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFGNll4NWFKSGFOSlJkczh5MHRCOUVCWERqTTErYStQV1V2cWJGNmZ4c0Q0SjBiZ1JLQzBSZnFWcU1uZm9TMklvcTBkSEhvbUFhQVBoM05McjFJUlZVVHJYWHorRGJqQnEvdkNsNENtSVgrYlhmVTFrWUZJb0VQS3RjQlJUYlFQVWEwYnpJRFl3UWpqNW1iaUpDVSs1VXpqa01xZ1o2V1F1Z1dHYVA4UThsWG4xMkhvR1JIQm9oWHlRYysyb0NwZGhaRisxMEQzZzVLK1prQ1VaSERQNXZXVERSNmhLVUh3YWc3VjZXc1BxVzRZd2xsY0F3QkxIVmpPc0R4cWQ0WHlyaVhGTy9jWVpNc2ZoZzBRZUMvQjVHK3Vkem41eHdPLzJ3ZlJFWlhIamtUOGxqb2taeWhLVzlYMkZUUFltR3dTWWloNEZVdEcvR1BxOFFRVnFrTm9ZaE09PC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpTaWduYXR1cmU+PC9leHQ6RXh0ZW5zaW9uQ29udGVudD48L2V4dDpVQkxFeHRlbnNpb24+PC9leHQ6VUJMRXh0ZW5zaW9ucz48Y2JjOlVCTFZlcnNpb25JRD4yLjE8L2NiYzpVQkxWZXJzaW9uSUQ+PGNiYzpDdXN0b21pemF0aW9uSUQ+Mi4wPC9jYmM6Q3VzdG9taXphdGlvbklEPjxjYmM6SUQ+VDAwMS01NjwvY2JjOklEPjxjYmM6SXNzdWVEYXRlPjIwMjQtMDMtMTc8L2NiYzpJc3N1ZURhdGU+PGNiYzpJc3N1ZVRpbWU+MTg6MDA6MDA8L2NiYzpJc3N1ZVRpbWU+PGNiYzpEZXNwYXRjaEFkdmljZVR5cGVDb2RlIGxpc3RBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgbGlzdE5hbWU9IlRpcG8gZGUgRG9jdW1lbnRvIiBsaXN0VVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzAxIj4wOTwvY2JjOkRlc3BhdGNoQWR2aWNlVHlwZUNvZGU+PGNhYzpTaWduYXR1cmU+PGNiYzpJRD4yMDQ1MjU3ODk1NzwvY2JjOklEPjxjYWM6U2lnbmF0b3J5UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQ+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlOYW1lPjxjYmM6TmFtZT48IVtDREFUQVtUVVRPUklBTEVTIFBIUEVSVV1dPjwvY2JjOk5hbWU+PC9jYWM6UGFydHlOYW1lPjwvY2FjOlNpZ25hdG9yeVBhcnR5PjxjYWM6RGlnaXRhbFNpZ25hdHVyZUF0dGFjaG1lbnQ+PGNhYzpFeHRlcm5hbFJlZmVyZW5jZT48Y2JjOlVSST4jR1JFRU5URVItU0lHTjwvY2JjOlVSST48L2NhYzpFeHRlcm5hbFJlZmVyZW5jZT48L2NhYzpEaWdpdGFsU2lnbmF0dXJlQXR0YWNobWVudD48L2NhYzpTaWduYXR1cmU+PGNhYzpEZXNwYXRjaFN1cHBsaWVyUGFydHk+PGNhYzpQYXJ0eT48Y2FjOlBhcnR5SWRlbnRpZmljYXRpb24+PGNiYzpJRCBzY2hlbWVJRD0iNiIgc2NoZW1lTmFtZT0iRG9jdW1lbnRvIGRlIElkZW50aWRhZCIgc2NoZW1lQWdlbmN5TmFtZT0iUEU6U1VOQVQiIHNjaGVtZVVSST0idXJuOnBlOmdvYjpzdW5hdDpjcGU6c2VlOmdlbTpjYXRhbG9nb3M6Y2F0YWxvZ28wNiI+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlMZWdhbEVudGl0eT48Y2JjOlJlZ2lzdHJhdGlvbk5hbWU+PCFbQ0RBVEFbVFVUT1JJQUxFUyBQSFBFUlVdXT48L2NiYzpSZWdpc3RyYXRpb25OYW1lPjwvY2FjOlBhcnR5TGVnYWxFbnRpdHk+PC9jYWM6UGFydHk+PC9jYWM6RGVzcGF0Y2hTdXBwbGllclBhcnR5PjxjYWM6RGVsaXZlcnlDdXN0b21lclBhcnR5PjxjYWM6UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQgc2NoZW1lSUQ9IjEiIHNjaGVtZU5hbWU9IkRvY3VtZW50byBkZSBJZGVudGlkYWQiIHNjaGVtZUFnZW5jeU5hbWU9IlBFOlNVTkFUIiBzY2hlbWVVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMDYiPjQ1MjU3ODk1PC9jYmM6SUQ+PC9jYWM6UGFydHlJZGVudGlmaWNhdGlvbj48Y2FjOlBhcnR5TGVnYWxFbnRpdHk+PGNiYzpSZWdpc3RyYXRpb25OYW1lPjwhW0NEQVRBW0xVSVMgQU5HRUwgTE9aQU5PIEFSSUNBXV0+PC9jYmM6UmVnaXN0cmF0aW9uTmFtZT48L2NhYzpQYXJ0eUxlZ2FsRW50aXR5PjwvY2FjOlBhcnR5PjwvY2FjOkRlbGl2ZXJ5Q3VzdG9tZXJQYXJ0eT48Y2FjOlNoaXBtZW50PjxjYmM6SUQ+U1VOQVRfRW52aW88L2NiYzpJRD48Y2JjOkhhbmRsaW5nQ29kZSBsaXN0QWdlbmN5TmFtZT0iUEU6U1VOQVQiIGxpc3ROYW1lPSJNb3Rpdm8gZGUgdHJhc2xhZG8iIGxpc3RVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMjAiPjAxPC9jYmM6SGFuZGxpbmdDb2RlPjxjYmM6R3Jvc3NXZWlnaHRNZWFzdXJlIHVuaXRDb2RlPSJLR00iPjIwLjAwMDwvY2JjOkdyb3NzV2VpZ2h0TWVhc3VyZT48Y2JjOlRvdGFsVHJhbnNwb3J0SGFuZGxpbmdVbml0UXVhbnRpdHk+NTwvY2JjOlRvdGFsVHJhbnNwb3J0SGFuZGxpbmdVbml0UXVhbnRpdHk+PGNhYzpTaGlwbWVudFN0YWdlPjxjYmM6VHJhbnNwb3J0TW9kZUNvZGUgbGlzdE5hbWU9Ik1vZGFsaWRhZCBkZSB0cmFzbGFkbyIgbGlzdEFnZW5jeU5hbWU9IlBFOlNVTkFUIiBsaXN0VVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzE4Ij4wMTwvY2JjOlRyYW5zcG9ydE1vZGVDb2RlPjxjYWM6VHJhbnNpdFBlcmlvZD48Y2JjOlN0YXJ0RGF0ZT4yMDI0LTAzLTE3PC9jYmM6U3RhcnREYXRlPjwvY2FjOlRyYW5zaXRQZXJpb2Q+PGNhYzpDYXJyaWVyUGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQgc2NoZW1lSUQ9IjYiPjIwNTM4OTk1MzY0PC9jYmM6SUQ+PC9jYWM6UGFydHlJZGVudGlmaWNhdGlvbj48Y2FjOlBhcnR5TGVnYWxFbnRpdHk+PGNiYzpSZWdpc3RyYXRpb25OYW1lPjwhW0NEQVRBWyBEICYgTCBURUNOT0xPR0lBIFkgQVVESU8gUy5SLkwuXV0+PC9jYmM6UmVnaXN0cmF0aW9uTmFtZT48Y2JjOkNvbXBhbnlJRC8+PC9jYWM6UGFydHlMZWdhbEVudGl0eT48L2NhYzpDYXJyaWVyUGFydHk+PC9jYWM6U2hpcG1lbnRTdGFnZT48Y2FjOkRlbGl2ZXJ5PjxjYWM6RGVsaXZlcnlBZGRyZXNzPjxjYmM6SUQgc2NoZW1lQWdlbmN5TmFtZT0iUEU6SU5FSSIgc2NoZW1lTmFtZT0iVWJpZ2VvcyI+MTQwMTA4PC9jYmM6SUQ+PGNhYzpBZGRyZXNzTGluZT48Y2JjOkxpbmU+YXYgZ3JhdSAzNDU8L2NiYzpMaW5lPjwvY2FjOkFkZHJlc3NMaW5lPjwvY2FjOkRlbGl2ZXJ5QWRkcmVzcz48Y2FjOkRlc3BhdGNoPjxjYWM6RGVzcGF0Y2hBZGRyZXNzPjxjYmM6SUQgc2NoZW1lQWdlbmN5TmFtZT0iUEU6SU5FSSIgc2NoZW1lTmFtZT0iVWJpZ2VvcyI+MTQwMTA4PC9jYmM6SUQ+PGNhYzpBZGRyZXNzTGluZT48Y2JjOkxpbmU+YXYgbGltYSAyMTM8L2NiYzpMaW5lPjwvY2FjOkFkZHJlc3NMaW5lPjwvY2FjOkRlc3BhdGNoQWRkcmVzcz48L2NhYzpEZXNwYXRjaD48L2NhYzpEZWxpdmVyeT48L2NhYzpTaGlwbWVudD48Y2FjOkRlc3BhdGNoTGluZT48Y2JjOklEPjE8L2NiYzpJRD48Y2JjOkRlbGl2ZXJlZFF1YW50aXR5IHVuaXRDb2RlPSJOSVUiPjE8L2NiYzpEZWxpdmVyZWRRdWFudGl0eT48Y2FjOk9yZGVyTGluZVJlZmVyZW5jZT48Y2JjOkxpbmVJRD4xPC9jYmM6TGluZUlEPjwvY2FjOk9yZGVyTGluZVJlZmVyZW5jZT48Y2FjOkl0ZW0+PGNiYzpEZXNjcmlwdGlvbj48IVtDREFUQVtGQU5UQSBOQVJBTkpBIDUwME1MXV0+PC9jYmM6RGVzY3JpcHRpb24+PGNhYzpTZWxsZXJzSXRlbUlkZW50aWZpY2F0aW9uPjxjYmM6SUQ+Nzc1NTEzOTAwMjg1MTwvY2JjOklEPjwvY2FjOlNlbGxlcnNJdGVtSWRlbnRpZmljYXRpb24+PC9jYWM6SXRlbT48L2NhYzpEZXNwYXRjaExpbmU+PGNhYzpEZXNwYXRjaExpbmU+PGNiYzpJRD4yPC9jYmM6SUQ+PGNiYzpEZWxpdmVyZWRRdWFudGl0eSB1bml0Q29kZT0iTklVIj4xPC9jYmM6RGVsaXZlcmVkUXVhbnRpdHk+PGNhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNiYzpMaW5lSUQ+MjwvY2JjOkxpbmVJRD48L2NhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNhYzpJdGVtPjxjYmM6RGVzY3JpcHRpb24+PCFbQ0RBVEFbREVMRUlURSAxTF1dPjwvY2JjOkRlc2NyaXB0aW9uPjxjYWM6U2VsbGVyc0l0ZW1JZGVudGlmaWNhdGlvbj48Y2JjOklEPjc3NTUxMzkwMDI5MDI8L2NiYzpJRD48L2NhYzpTZWxsZXJzSXRlbUlkZW50aWZpY2F0aW9uPjwvY2FjOkl0ZW0+PC9jYWM6RGVzcGF0Y2hMaW5lPjwvRGVzcGF0Y2hBZHZpY2U+Cg==', NULL),
(67, '09', 'T001', 57, '2024-03-18', 1, 6, '01', 'F001-156', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'AV GRAU 345', '140108', 'AV LIMA 213', '6', '20538995364', ' D & L TECNOLOGIA Y AUDIO S.R.L.', '', '', 14, 1, 2567, 'Vehiculo principal: 2567 (nodo: \"cac:TransportEquipment/cbc:ID\" valor: \"ASD-5458\")', 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPERlc3BhdGNoQWR2aWNlIHhtbG5zPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpEZXNwYXRjaEFkdmljZS0yIiB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyIgeG1sbnM6Y2FjPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpDb21tb25BZ2dyZWdhdGVDb21wb25lbnRzLTIiIHhtbG5zOmNiYz0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uQmFzaWNDb21wb25lbnRzLTIiIHhtbG5zOmV4dD0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uRXh0ZW5zaW9uQ29tcG9uZW50cy0yIj48ZXh0OlVCTEV4dGVuc2lvbnM+PGV4dDpVQkxFeHRlbnNpb24+PGV4dDpFeHRlbnNpb25Db250ZW50PjxkczpTaWduYXR1cmUgSWQ9IkdyZWVudGVyU2lnbiI+PGRzOlNpZ25lZEluZm8+PGRzOkNhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy9UUi8yMDAxL1JFQy14bWwtYzE0bi0yMDAxMDMxNSIvPjxkczpTaWduYXR1cmVNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjcnNhLXNoYTEiLz48ZHM6UmVmZXJlbmNlIFVSST0iIj48ZHM6VHJhbnNmb3Jtcz48ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI2VudmVsb3BlZC1zaWduYXR1cmUiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8+PGRzOkRpZ2VzdFZhbHVlPk9BMk5IT3RzWnlVZGk5a3N4R2JwU2tFMU9FWT08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+WHNZTkc1SEJrdkt5OWNoaElrM1hYOHkrejh3MzN5SU9PV05lQlpPY1dnK1NSUDI0MU5hWVBCYmcwakI0Uk56Mm5KbnJNUkRCaEJ6TFdHbHoxN2lSMHhONU1VNm4rZ2dOdjRQUkdVN3o3YjlzTCtxTjFPRm9OMTdXbnBMc1VPR0VSSGxNUEtrck5ORHhYcm1WSDlJanY1RHQ5RlZYQnBVWnNYTWFWVWJMZDAyQmlwWGVDTkJ3K1RxT3FKOExuT3A0Z21PNUgyNFpFTUZlcE9wbXEzWnpWSkY3cXU4MHFxZXZaRUFWNEVFdEpIWjBpUUFTbGVKbVNzVGtNRXp3Wjd5QjhVajhPZTgyU0d3ZVNiZGg0dnJyQjluYU5ZVG1IcUE4NFRvckFaclFyS2JSYWNmUFBqM3pLdUd5a2pjOWs0ZHBMOWlvWmNsNFFNN041N0xVQ0dpek53PT08L2RzOlNpZ25hdHVyZVZhbHVlPjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUZDRENDQS9DZ0F3SUJBZ0lKQU9ja2tZN2hrT3l6TUEwR0NTcUdTSWIzRFFFQkN3VUFNSUlCRFRFYk1Ca0dDZ21TSm9tVDhpeGtBUmtXQzB4TVFVMUJMbEJGSUZOQk1Rc3dDUVlEVlFRR0V3SlFSVEVOTUFzR0ExVUVDQXdFVEVsTlFURU5NQXNHQTFVRUJ3d0VURWxOUVRFWU1CWUdBMVVFQ2d3UFZGVWdSVTFRVWtWVFFTQlRMa0V1TVVVd1F3WURWUVFMRER4RVRra2dPVGs1T1RrNU9TQlNWVU1nTWpBME5USTFOemc1TlRFZ0xTQkRSVkpVU1VaSlEwRkVUeUJRUVZKQklFUkZUVTlUVkZKQlEwbkRrMDR4UkRCQ0JnTlZCQU1NTzA1UFRVSlNSU0JTUlZCU1JWTkZUbFJCVGxSRklFeEZSMEZNSUMwZ1EwVlNWRWxHU1VOQlJFOGdVRUZTUVNCRVJVMVBVMVJTUVVOSnc1Tk9NUnd3R2dZSktvWklodmNOQVFrQkZnMWtaVzF2UUd4c1lXMWhMbkJsTUI0WERUSTBNREl5T1RBeE1EYzFPVm9YRFRJMk1ESXlPREF4TURjMU9Wb3dnZ0VOTVJzd0dRWUtDWkltaVpQeUxHUUJHUllMVEV4QlRVRXVVRVVnVTBFeEN6QUpCZ05WQkFZVEFsQkZNUTB3Q3dZRFZRUUlEQVJNU1UxQk1RMHdDd1lEVlFRSERBUk1TVTFCTVJnd0ZnWURWUVFLREE5VVZTQkZUVkJTUlZOQklGTXVRUzR4UlRCREJnTlZCQXNNUEVST1NTQTVPVGs1T1RrNUlGSlZReUF5TURRMU1qVTNPRGsxTVNBdElFTkZVbFJKUmtsRFFVUlBJRkJCVWtFZ1JFVk5UMU5VVWtGRFNjT1RUakZFTUVJR0ExVUVBd3c3VGs5TlFsSkZJRkpGVUZKRlUwVk9WRUZPVkVVZ1RFVkhRVXdnTFNCRFJWSlVTVVpKUTBGRVR5QlFRVkpCSUVSRlRVOVRWRkpCUTBuRGswNHhIREFhQmdrcWhraUc5dzBCQ1FFV0RXUmxiVzlBYkd4aGJXRXVjR1V3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRRFR0SGRjQmNuZUJ2bnorM0JwejhhUGFaM2RaY05ZK29aZ3hYTlFheFpvdzBaYStwb0k2Rjk0cHlZelZyOWY3alZoMW16UFFjZ3NLU3Fpd1ZlOS9IMzBwbkM1NEpyWXVEa2pKL3hQOE5yM0E3VHJDR0RXSVFaTmR4NEhIYWFwaTZiZENuUkxrZFNBam5FWkRhV1FWeWRyRFJVODRqVktOSXVNejBmaE8rRWwxZWI3SGZlelJiTHFERDFRTjI4SkwvZWlONExJbHlKUTJvOU5iRjEySEJZb1kxb01sQ2pnZFM3TWNVNlZaNWdqYzQzL0kyTDVVemZlWDVSK1pQbEFZR2tYMXBLVTBBQmFiOWZlTHFKVUdWOGRJNDVmQTdqZzJOKzdHcjlqeXlDQkZLY3hBV1IveitGTmI3WkZYL0kzK3BkcjhVeWpzUzJRczVaaXNyZWhVdnkvQWdNQkFBR2paekJsTUIwR0ExVWREZ1FXQkJUWVNhYm85Yjc5eWxOK2wzM3BZQlRIRW1XTXBEQWZCZ05WSFNNRUdEQVdnQlRZU2FibzliNzl5bE4rbDMzcFlCVEhFbVdNcERBVEJnTlZIU1VFRERBS0JnZ3JCZ0VGQlFjREFUQU9CZ05WSFE4QkFmOEVCQU1DQjRBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFGNll4NWFKSGFOSlJkczh5MHRCOUVCWERqTTErYStQV1V2cWJGNmZ4c0Q0SjBiZ1JLQzBSZnFWcU1uZm9TMklvcTBkSEhvbUFhQVBoM05McjFJUlZVVHJYWHorRGJqQnEvdkNsNENtSVgrYlhmVTFrWUZJb0VQS3RjQlJUYlFQVWEwYnpJRFl3UWpqNW1iaUpDVSs1VXpqa01xZ1o2V1F1Z1dHYVA4UThsWG4xMkhvR1JIQm9oWHlRYysyb0NwZGhaRisxMEQzZzVLK1prQ1VaSERQNXZXVERSNmhLVUh3YWc3VjZXc1BxVzRZd2xsY0F3QkxIVmpPc0R4cWQ0WHlyaVhGTy9jWVpNc2ZoZzBRZUMvQjVHK3Vkem41eHdPLzJ3ZlJFWlhIamtUOGxqb2taeWhLVzlYMkZUUFltR3dTWWloNEZVdEcvR1BxOFFRVnFrTm9ZaE09PC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpTaWduYXR1cmU+PC9leHQ6RXh0ZW5zaW9uQ29udGVudD48L2V4dDpVQkxFeHRlbnNpb24+PC9leHQ6VUJMRXh0ZW5zaW9ucz48Y2JjOlVCTFZlcnNpb25JRD4yLjE8L2NiYzpVQkxWZXJzaW9uSUQ+PGNiYzpDdXN0b21pemF0aW9uSUQ+Mi4wPC9jYmM6Q3VzdG9taXphdGlvbklEPjxjYmM6SUQ+VDAwMS01NzwvY2JjOklEPjxjYmM6SXNzdWVEYXRlPjIwMjQtMDMtMTc8L2NiYzpJc3N1ZURhdGU+PGNiYzpJc3N1ZVRpbWU+MTg6MDA6MDA8L2NiYzpJc3N1ZVRpbWU+PGNiYzpEZXNwYXRjaEFkdmljZVR5cGVDb2RlIGxpc3RBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgbGlzdE5hbWU9IlRpcG8gZGUgRG9jdW1lbnRvIiBsaXN0VVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzAxIj4wOTwvY2JjOkRlc3BhdGNoQWR2aWNlVHlwZUNvZGU+PGNhYzpTaWduYXR1cmU+PGNiYzpJRD4yMDQ1MjU3ODk1NzwvY2JjOklEPjxjYWM6U2lnbmF0b3J5UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQ+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlOYW1lPjxjYmM6TmFtZT48IVtDREFUQVtUVVRPUklBTEVTIFBIUEVSVV1dPjwvY2JjOk5hbWU+PC9jYWM6UGFydHlOYW1lPjwvY2FjOlNpZ25hdG9yeVBhcnR5PjxjYWM6RGlnaXRhbFNpZ25hdHVyZUF0dGFjaG1lbnQ+PGNhYzpFeHRlcm5hbFJlZmVyZW5jZT48Y2JjOlVSST4jR1JFRU5URVItU0lHTjwvY2JjOlVSST48L2NhYzpFeHRlcm5hbFJlZmVyZW5jZT48L2NhYzpEaWdpdGFsU2lnbmF0dXJlQXR0YWNobWVudD48L2NhYzpTaWduYXR1cmU+PGNhYzpEZXNwYXRjaFN1cHBsaWVyUGFydHk+PGNhYzpQYXJ0eT48Y2FjOlBhcnR5SWRlbnRpZmljYXRpb24+PGNiYzpJRCBzY2hlbWVJRD0iNiIgc2NoZW1lTmFtZT0iRG9jdW1lbnRvIGRlIElkZW50aWRhZCIgc2NoZW1lQWdlbmN5TmFtZT0iUEU6U1VOQVQiIHNjaGVtZVVSST0idXJuOnBlOmdvYjpzdW5hdDpjcGU6c2VlOmdlbTpjYXRhbG9nb3M6Y2F0YWxvZ28wNiI+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlMZWdhbEVudGl0eT48Y2JjOlJlZ2lzdHJhdGlvbk5hbWU+PCFbQ0RBVEFbVFVUT1JJQUxFUyBQSFBFUlVdXT48L2NiYzpSZWdpc3RyYXRpb25OYW1lPjwvY2FjOlBhcnR5TGVnYWxFbnRpdHk+PC9jYWM6UGFydHk+PC9jYWM6RGVzcGF0Y2hTdXBwbGllclBhcnR5PjxjYWM6RGVsaXZlcnlDdXN0b21lclBhcnR5PjxjYWM6UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQgc2NoZW1lSUQ9IjEiIHNjaGVtZU5hbWU9IkRvY3VtZW50byBkZSBJZGVudGlkYWQiIHNjaGVtZUFnZW5jeU5hbWU9IlBFOlNVTkFUIiBzY2hlbWVVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMDYiPjQ1MjU3ODk1PC9jYmM6SUQ+PC9jYWM6UGFydHlJZGVudGlmaWNhdGlvbj48Y2FjOlBhcnR5TGVnYWxFbnRpdHk+PGNiYzpSZWdpc3RyYXRpb25OYW1lPjwhW0NEQVRBW0xVSVMgQU5HRUwgTE9aQU5PIEFSSUNBXV0+PC9jYmM6UmVnaXN0cmF0aW9uTmFtZT48L2NhYzpQYXJ0eUxlZ2FsRW50aXR5PjwvY2FjOlBhcnR5PjwvY2FjOkRlbGl2ZXJ5Q3VzdG9tZXJQYXJ0eT48Y2FjOlNoaXBtZW50PjxjYmM6SUQ+U1VOQVRfRW52aW88L2NiYzpJRD48Y2JjOkhhbmRsaW5nQ29kZSBsaXN0QWdlbmN5TmFtZT0iUEU6U1VOQVQiIGxpc3ROYW1lPSJNb3Rpdm8gZGUgdHJhc2xhZG8iIGxpc3RVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMjAiPjAxPC9jYmM6SGFuZGxpbmdDb2RlPjxjYmM6R3Jvc3NXZWlnaHRNZWFzdXJlIHVuaXRDb2RlPSJLR00iPjIwLjAwMDwvY2JjOkdyb3NzV2VpZ2h0TWVhc3VyZT48Y2JjOlRvdGFsVHJhbnNwb3J0SGFuZGxpbmdVbml0UXVhbnRpdHk+NTwvY2JjOlRvdGFsVHJhbnNwb3J0SGFuZGxpbmdVbml0UXVhbnRpdHk+PGNhYzpTaGlwbWVudFN0YWdlPjxjYmM6VHJhbnNwb3J0TW9kZUNvZGUgbGlzdE5hbWU9Ik1vZGFsaWRhZCBkZSB0cmFzbGFkbyIgbGlzdEFnZW5jeU5hbWU9IlBFOlNVTkFUIiBsaXN0VVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzE4Ij4wMTwvY2JjOlRyYW5zcG9ydE1vZGVDb2RlPjxjYWM6VHJhbnNpdFBlcmlvZD48Y2JjOlN0YXJ0RGF0ZT4yMDI0LTAzLTE3PC9jYmM6U3RhcnREYXRlPjwvY2FjOlRyYW5zaXRQZXJpb2Q+PGNhYzpDYXJyaWVyUGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQgc2NoZW1lSUQ9IjYiPjIwNTM4OTk1MzY0PC9jYmM6SUQ+PC9jYWM6UGFydHlJZGVudGlmaWNhdGlvbj48Y2FjOlBhcnR5TGVnYWxFbnRpdHk+PGNiYzpSZWdpc3RyYXRpb25OYW1lPjwhW0NEQVRBWyBEICYgTCBURUNOT0xPR0lBIFkgQVVESU8gUy5SLkwuXV0+PC9jYmM6UmVnaXN0cmF0aW9uTmFtZT48Y2JjOkNvbXBhbnlJRC8+PC9jYWM6UGFydHlMZWdhbEVudGl0eT48L2NhYzpDYXJyaWVyUGFydHk+PC9jYWM6U2hpcG1lbnRTdGFnZT48Y2FjOkRlbGl2ZXJ5PjxjYWM6RGVsaXZlcnlBZGRyZXNzPjxjYmM6SUQgc2NoZW1lQWdlbmN5TmFtZT0iUEU6SU5FSSIgc2NoZW1lTmFtZT0iVWJpZ2VvcyI+MTQwMTA4PC9jYmM6SUQ+PGNhYzpBZGRyZXNzTGluZT48Y2JjOkxpbmU+YXYgZ3JhdSAzNDU8L2NiYzpMaW5lPjwvY2FjOkFkZHJlc3NMaW5lPjwvY2FjOkRlbGl2ZXJ5QWRkcmVzcz48Y2FjOkRlc3BhdGNoPjxjYWM6RGVzcGF0Y2hBZGRyZXNzPjxjYmM6SUQgc2NoZW1lQWdlbmN5TmFtZT0iUEU6SU5FSSIgc2NoZW1lTmFtZT0iVWJpZ2VvcyI+MTQwMTA4PC9jYmM6SUQ+PGNhYzpBZGRyZXNzTGluZT48Y2JjOkxpbmU+YXYgbGltYSAyMTM8L2NiYzpMaW5lPjwvY2FjOkFkZHJlc3NMaW5lPjwvY2FjOkRlc3BhdGNoQWRkcmVzcz48L2NhYzpEZXNwYXRjaD48L2NhYzpEZWxpdmVyeT48L2NhYzpTaGlwbWVudD48Y2FjOkRlc3BhdGNoTGluZT48Y2JjOklEPjE8L2NiYzpJRD48Y2JjOkRlbGl2ZXJlZFF1YW50aXR5IHVuaXRDb2RlPSJOSVUiPjE8L2NiYzpEZWxpdmVyZWRRdWFudGl0eT48Y2FjOk9yZGVyTGluZVJlZmVyZW5jZT48Y2JjOkxpbmVJRD4xPC9jYmM6TGluZUlEPjwvY2FjOk9yZGVyTGluZVJlZmVyZW5jZT48Y2FjOkl0ZW0+PGNiYzpEZXNjcmlwdGlvbj48IVtDREFUQVtGQU5UQSBOQVJBTkpBIDUwME1MXV0+PC9jYmM6RGVzY3JpcHRpb24+PGNhYzpTZWxsZXJzSXRlbUlkZW50aWZpY2F0aW9uPjxjYmM6SUQ+Nzc1NTEzOTAwMjg1MTwvY2JjOklEPjwvY2FjOlNlbGxlcnNJdGVtSWRlbnRpZmljYXRpb24+PC9jYWM6SXRlbT48L2NhYzpEZXNwYXRjaExpbmU+PGNhYzpEZXNwYXRjaExpbmU+PGNiYzpJRD4yPC9jYmM6SUQ+PGNiYzpEZWxpdmVyZWRRdWFudGl0eSB1bml0Q29kZT0iTklVIj4xPC9jYmM6RGVsaXZlcmVkUXVhbnRpdHk+PGNhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNiYzpMaW5lSUQ+MjwvY2JjOkxpbmVJRD48L2NhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNhYzpJdGVtPjxjYmM6RGVzY3JpcHRpb24+PCFbQ0RBVEFbREVMRUlURSAxTF1dPjwvY2JjOkRlc2NyaXB0aW9uPjxjYWM6U2VsbGVyc0l0ZW1JZGVudGlmaWNhdGlvbj48Y2JjOklEPjc3NTUxMzkwMDI5MDI8L2NiYzpJRD48L2NhYzpTZWxsZXJzSXRlbUlkZW50aWZpY2F0aW9uPjwvY2FjOkl0ZW0+PC9jYWM6RGVzcGF0Y2hMaW5lPjwvRGVzcGF0Y2hBZHZpY2U+Cg==', NULL);
INSERT INTO `guia_remision` (`id`, `tipo_documento`, `serie`, `correlativo`, `fecha_emision`, `id_empresa`, `id_cliente`, `id_tipo_documento_rel`, `documento_rel`, `codigo_traslado`, `modalidad_traslado`, `fecha_traslado`, `peso_total`, `unidad_peso_total`, `numero_bultos`, `ubigeo_llegada`, `direccion_llegada`, `ubigeo_partida`, `direccion_partida`, `tipo_documento_transportista`, `numero_documento_transportista`, `razon_social_transportista`, `nro_mtc`, `observaciones`, `id_usuario`, `estado`, `estado_sunat`, `mensaje_error_sunat`, `xml_base64`, `xml_cdr_sunat_base64`) VALUES
(68, '09', 'T001', 58, '2024-03-18', 1, 9, '01', 'F001-654', '01', '02', '2024-03-18', 20, 'KGM', 5, '140108', 'AV LIMA 456', '140108', 'AV GRAU 123', NULL, NULL, NULL, NULL, '', 14, 1, 2567, 'Vehiculo principal: 2567 (nodo: \"cac:TransportEquipment/cbc:ID\" valor: \"ASD-5458\")', 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPERlc3BhdGNoQWR2aWNlIHhtbG5zPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpEZXNwYXRjaEFkdmljZS0yIiB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyIgeG1sbnM6Y2FjPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpDb21tb25BZ2dyZWdhdGVDb21wb25lbnRzLTIiIHhtbG5zOmNiYz0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uQmFzaWNDb21wb25lbnRzLTIiIHhtbG5zOmV4dD0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uRXh0ZW5zaW9uQ29tcG9uZW50cy0yIj48ZXh0OlVCTEV4dGVuc2lvbnM+PGV4dDpVQkxFeHRlbnNpb24+PGV4dDpFeHRlbnNpb25Db250ZW50PjxkczpTaWduYXR1cmUgSWQ9IkdyZWVudGVyU2lnbiI+PGRzOlNpZ25lZEluZm8+PGRzOkNhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy9UUi8yMDAxL1JFQy14bWwtYzE0bi0yMDAxMDMxNSIvPjxkczpTaWduYXR1cmVNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjcnNhLXNoYTEiLz48ZHM6UmVmZXJlbmNlIFVSST0iIj48ZHM6VHJhbnNmb3Jtcz48ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI2VudmVsb3BlZC1zaWduYXR1cmUiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8+PGRzOkRpZ2VzdFZhbHVlPnZIaHZtbU1SUjl4NjZ4Tk5RQm9KMnRRTzJXST08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+QzNtRUJxWWNaTklGYVlZcHlsOUhIdGxLV3BJOExueW1qWU83ZjhIWjRpRW5pUHR3ZUZaNWxsTTFrSG1oN0hGM3NzZDZMSHB2RlkzQUN6SGxRSzFDNFBHbUpUdDhmUjB4enhDUERHbjZHaXhXeFR5VmNaeDFxbUdTTVNLQmNyL3NKTVNCcmlBejlNeGhpeGo4WFVjOXF0MzEzTkxjcUdGSGR0L1ZESGZwQjF4Wmp6cmN1TXRGTVZ6TVFMa2RpLzhnWGVoMHFoM2QzV3c3ODhvMWJJUlR3aFVINk5RcGxkRXNYZ2F4dlVDRWtwSGx5dDdhNzQvMFdvckN4alFnN21JZDh2U3dqVm5WamprM0RnWXhvSVc0M0F6Z0JYWVNSelB3bUluTDdzdGx2clZaUWNPNzhpOWt0RUFWRXRqL0NWU2x6QmVlSGdTVjViWWFBYVVickZmeXFRPT08L2RzOlNpZ25hdHVyZVZhbHVlPjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUZDRENDQS9DZ0F3SUJBZ0lKQU9ja2tZN2hrT3l6TUEwR0NTcUdTSWIzRFFFQkN3VUFNSUlCRFRFYk1Ca0dDZ21TSm9tVDhpeGtBUmtXQzB4TVFVMUJMbEJGSUZOQk1Rc3dDUVlEVlFRR0V3SlFSVEVOTUFzR0ExVUVDQXdFVEVsTlFURU5NQXNHQTFVRUJ3d0VURWxOUVRFWU1CWUdBMVVFQ2d3UFZGVWdSVTFRVWtWVFFTQlRMa0V1TVVVd1F3WURWUVFMRER4RVRra2dPVGs1T1RrNU9TQlNWVU1nTWpBME5USTFOemc1TlRFZ0xTQkRSVkpVU1VaSlEwRkVUeUJRUVZKQklFUkZUVTlUVkZKQlEwbkRrMDR4UkRCQ0JnTlZCQU1NTzA1UFRVSlNSU0JTUlZCU1JWTkZUbFJCVGxSRklFeEZSMEZNSUMwZ1EwVlNWRWxHU1VOQlJFOGdVRUZTUVNCRVJVMVBVMVJTUVVOSnc1Tk9NUnd3R2dZSktvWklodmNOQVFrQkZnMWtaVzF2UUd4c1lXMWhMbkJsTUI0WERUSTBNREl5T1RBeE1EYzFPVm9YRFRJMk1ESXlPREF4TURjMU9Wb3dnZ0VOTVJzd0dRWUtDWkltaVpQeUxHUUJHUllMVEV4QlRVRXVVRVVnVTBFeEN6QUpCZ05WQkFZVEFsQkZNUTB3Q3dZRFZRUUlEQVJNU1UxQk1RMHdDd1lEVlFRSERBUk1TVTFCTVJnd0ZnWURWUVFLREE5VVZTQkZUVkJTUlZOQklGTXVRUzR4UlRCREJnTlZCQXNNUEVST1NTQTVPVGs1T1RrNUlGSlZReUF5TURRMU1qVTNPRGsxTVNBdElFTkZVbFJKUmtsRFFVUlBJRkJCVWtFZ1JFVk5UMU5VVWtGRFNjT1RUakZFTUVJR0ExVUVBd3c3VGs5TlFsSkZJRkpGVUZKRlUwVk9WRUZPVkVVZ1RFVkhRVXdnTFNCRFJWSlVTVVpKUTBGRVR5QlFRVkpCSUVSRlRVOVRWRkpCUTBuRGswNHhIREFhQmdrcWhraUc5dzBCQ1FFV0RXUmxiVzlBYkd4aGJXRXVjR1V3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRRFR0SGRjQmNuZUJ2bnorM0JwejhhUGFaM2RaY05ZK29aZ3hYTlFheFpvdzBaYStwb0k2Rjk0cHlZelZyOWY3alZoMW16UFFjZ3NLU3Fpd1ZlOS9IMzBwbkM1NEpyWXVEa2pKL3hQOE5yM0E3VHJDR0RXSVFaTmR4NEhIYWFwaTZiZENuUkxrZFNBam5FWkRhV1FWeWRyRFJVODRqVktOSXVNejBmaE8rRWwxZWI3SGZlelJiTHFERDFRTjI4SkwvZWlONExJbHlKUTJvOU5iRjEySEJZb1kxb01sQ2pnZFM3TWNVNlZaNWdqYzQzL0kyTDVVemZlWDVSK1pQbEFZR2tYMXBLVTBBQmFiOWZlTHFKVUdWOGRJNDVmQTdqZzJOKzdHcjlqeXlDQkZLY3hBV1IveitGTmI3WkZYL0kzK3BkcjhVeWpzUzJRczVaaXNyZWhVdnkvQWdNQkFBR2paekJsTUIwR0ExVWREZ1FXQkJUWVNhYm85Yjc5eWxOK2wzM3BZQlRIRW1XTXBEQWZCZ05WSFNNRUdEQVdnQlRZU2FibzliNzl5bE4rbDMzcFlCVEhFbVdNcERBVEJnTlZIU1VFRERBS0JnZ3JCZ0VGQlFjREFUQU9CZ05WSFE4QkFmOEVCQU1DQjRBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFGNll4NWFKSGFOSlJkczh5MHRCOUVCWERqTTErYStQV1V2cWJGNmZ4c0Q0SjBiZ1JLQzBSZnFWcU1uZm9TMklvcTBkSEhvbUFhQVBoM05McjFJUlZVVHJYWHorRGJqQnEvdkNsNENtSVgrYlhmVTFrWUZJb0VQS3RjQlJUYlFQVWEwYnpJRFl3UWpqNW1iaUpDVSs1VXpqa01xZ1o2V1F1Z1dHYVA4UThsWG4xMkhvR1JIQm9oWHlRYysyb0NwZGhaRisxMEQzZzVLK1prQ1VaSERQNXZXVERSNmhLVUh3YWc3VjZXc1BxVzRZd2xsY0F3QkxIVmpPc0R4cWQ0WHlyaVhGTy9jWVpNc2ZoZzBRZUMvQjVHK3Vkem41eHdPLzJ3ZlJFWlhIamtUOGxqb2taeWhLVzlYMkZUUFltR3dTWWloNEZVdEcvR1BxOFFRVnFrTm9ZaE09PC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpTaWduYXR1cmU+PC9leHQ6RXh0ZW5zaW9uQ29udGVudD48L2V4dDpVQkxFeHRlbnNpb24+PC9leHQ6VUJMRXh0ZW5zaW9ucz48Y2JjOlVCTFZlcnNpb25JRD4yLjE8L2NiYzpVQkxWZXJzaW9uSUQ+PGNiYzpDdXN0b21pemF0aW9uSUQ+Mi4wPC9jYmM6Q3VzdG9taXphdGlvbklEPjxjYmM6SUQ+VDAwMS01ODwvY2JjOklEPjxjYmM6SXNzdWVEYXRlPjIwMjQtMDMtMTc8L2NiYzpJc3N1ZURhdGU+PGNiYzpJc3N1ZVRpbWU+MTg6MDA6MDA8L2NiYzpJc3N1ZVRpbWU+PGNiYzpEZXNwYXRjaEFkdmljZVR5cGVDb2RlIGxpc3RBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgbGlzdE5hbWU9IlRpcG8gZGUgRG9jdW1lbnRvIiBsaXN0VVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzAxIj4wOTwvY2JjOkRlc3BhdGNoQWR2aWNlVHlwZUNvZGU+PGNhYzpTaWduYXR1cmU+PGNiYzpJRD4yMDQ1MjU3ODk1NzwvY2JjOklEPjxjYWM6U2lnbmF0b3J5UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQ+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlOYW1lPjxjYmM6TmFtZT48IVtDREFUQVtUVVRPUklBTEVTIFBIUEVSVV1dPjwvY2JjOk5hbWU+PC9jYWM6UGFydHlOYW1lPjwvY2FjOlNpZ25hdG9yeVBhcnR5PjxjYWM6RGlnaXRhbFNpZ25hdHVyZUF0dGFjaG1lbnQ+PGNhYzpFeHRlcm5hbFJlZmVyZW5jZT48Y2JjOlVSST4jR1JFRU5URVItU0lHTjwvY2JjOlVSST48L2NhYzpFeHRlcm5hbFJlZmVyZW5jZT48L2NhYzpEaWdpdGFsU2lnbmF0dXJlQXR0YWNobWVudD48L2NhYzpTaWduYXR1cmU+PGNhYzpEZXNwYXRjaFN1cHBsaWVyUGFydHk+PGNhYzpQYXJ0eT48Y2FjOlBhcnR5SWRlbnRpZmljYXRpb24+PGNiYzpJRCBzY2hlbWVJRD0iNiIgc2NoZW1lTmFtZT0iRG9jdW1lbnRvIGRlIElkZW50aWRhZCIgc2NoZW1lQWdlbmN5TmFtZT0iUEU6U1VOQVQiIHNjaGVtZVVSST0idXJuOnBlOmdvYjpzdW5hdDpjcGU6c2VlOmdlbTpjYXRhbG9nb3M6Y2F0YWxvZ28wNiI+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlMZWdhbEVudGl0eT48Y2JjOlJlZ2lzdHJhdGlvbk5hbWU+PCFbQ0RBVEFbVFVUT1JJQUxFUyBQSFBFUlVdXT48L2NiYzpSZWdpc3RyYXRpb25OYW1lPjwvY2FjOlBhcnR5TGVnYWxFbnRpdHk+PC9jYWM6UGFydHk+PC9jYWM6RGVzcGF0Y2hTdXBwbGllclBhcnR5PjxjYWM6RGVsaXZlcnlDdXN0b21lclBhcnR5PjxjYWM6UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQgc2NoZW1lSUQ9IjYiIHNjaGVtZU5hbWU9IkRvY3VtZW50byBkZSBJZGVudGlkYWQiIHNjaGVtZUFnZW5jeU5hbWU9IlBFOlNVTkFUIiBzY2hlbWVVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMDYiPjIwNTUzODU2NDUxPC9jYmM6SUQ+PC9jYWM6UGFydHlJZGVudGlmaWNhdGlvbj48Y2FjOlBhcnR5TGVnYWxFbnRpdHk+PGNiYzpSZWdpc3RyYXRpb25OYW1lPjwhW0NEQVRBW0JJIEdSQU5EIENPTkZFQ0NJT05FUyBTLkEuQy5dXT48L2NiYzpSZWdpc3RyYXRpb25OYW1lPjwvY2FjOlBhcnR5TGVnYWxFbnRpdHk+PC9jYWM6UGFydHk+PC9jYWM6RGVsaXZlcnlDdXN0b21lclBhcnR5PjxjYWM6U2hpcG1lbnQ+PGNiYzpJRD5TVU5BVF9FbnZpbzwvY2JjOklEPjxjYmM6SGFuZGxpbmdDb2RlIGxpc3RBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgbGlzdE5hbWU9Ik1vdGl2byBkZSB0cmFzbGFkbyIgbGlzdFVSST0idXJuOnBlOmdvYjpzdW5hdDpjcGU6c2VlOmdlbTpjYXRhbG9nb3M6Y2F0YWxvZ28yMCI+MDE8L2NiYzpIYW5kbGluZ0NvZGU+PGNiYzpHcm9zc1dlaWdodE1lYXN1cmUgdW5pdENvZGU9IktHTSI+MjAuMDAwPC9jYmM6R3Jvc3NXZWlnaHRNZWFzdXJlPjxjYmM6VG90YWxUcmFuc3BvcnRIYW5kbGluZ1VuaXRRdWFudGl0eT41PC9jYmM6VG90YWxUcmFuc3BvcnRIYW5kbGluZ1VuaXRRdWFudGl0eT48Y2FjOlNoaXBtZW50U3RhZ2U+PGNiYzpUcmFuc3BvcnRNb2RlQ29kZSBsaXN0TmFtZT0iTW9kYWxpZGFkIGRlIHRyYXNsYWRvIiBsaXN0QWdlbmN5TmFtZT0iUEU6U1VOQVQiIGxpc3RVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMTgiPjAyPC9jYmM6VHJhbnNwb3J0TW9kZUNvZGU+PGNhYzpUcmFuc2l0UGVyaW9kPjxjYmM6U3RhcnREYXRlPjIwMjQtMDMtMTc8L2NiYzpTdGFydERhdGU+PC9jYWM6VHJhbnNpdFBlcmlvZD48Y2FjOkRyaXZlclBlcnNvbj48Y2JjOklEIHNjaGVtZUlEPSIxIiBzY2hlbWVOYW1lPSJEb2N1bWVudG8gZGUgSWRlbnRpZGFkIiBzY2hlbWVBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgc2NoZW1lVVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzA2Ij40NTI1Nzg5NTwvY2JjOklEPjxjYmM6Rmlyc3ROYW1lPkxVSVM8L2NiYzpGaXJzdE5hbWU+PGNiYzpGYW1pbHlOYW1lPkxPWkFOTzwvY2JjOkZhbWlseU5hbWU+PGNiYzpKb2JUaXRsZT5QcmluY2lwYWw8L2NiYzpKb2JUaXRsZT48Y2FjOklkZW50aXR5RG9jdW1lbnRSZWZlcmVuY2U+PGNiYzpJRD5BU0QtNTY1NDY1NDk4NDwvY2JjOklEPjwvY2FjOklkZW50aXR5RG9jdW1lbnRSZWZlcmVuY2U+PC9jYWM6RHJpdmVyUGVyc29uPjwvY2FjOlNoaXBtZW50U3RhZ2U+PGNhYzpEZWxpdmVyeT48Y2FjOkRlbGl2ZXJ5QWRkcmVzcz48Y2JjOklEIHNjaGVtZUFnZW5jeU5hbWU9IlBFOklORUkiIHNjaGVtZU5hbWU9IlViaWdlb3MiPjE0MDEwODwvY2JjOklEPjxjYWM6QWRkcmVzc0xpbmU+PGNiYzpMaW5lPmF2IGxpbWEgNDU2PC9jYmM6TGluZT48L2NhYzpBZGRyZXNzTGluZT48L2NhYzpEZWxpdmVyeUFkZHJlc3M+PGNhYzpEZXNwYXRjaD48Y2FjOkRlc3BhdGNoQWRkcmVzcz48Y2JjOklEIHNjaGVtZUFnZW5jeU5hbWU9IlBFOklORUkiIHNjaGVtZU5hbWU9IlViaWdlb3MiPjE0MDEwODwvY2JjOklEPjxjYWM6QWRkcmVzc0xpbmU+PGNiYzpMaW5lPmF2IGdyYXUgMTIzPC9jYmM6TGluZT48L2NhYzpBZGRyZXNzTGluZT48L2NhYzpEZXNwYXRjaEFkZHJlc3M+PC9jYWM6RGVzcGF0Y2g+PC9jYWM6RGVsaXZlcnk+PGNhYzpUcmFuc3BvcnRIYW5kbGluZ1VuaXQ+PGNhYzpUcmFuc3BvcnRFcXVpcG1lbnQ+PGNiYzpJRD5BU0QtNTQ1ODwvY2JjOklEPjwvY2FjOlRyYW5zcG9ydEVxdWlwbWVudD48L2NhYzpUcmFuc3BvcnRIYW5kbGluZ1VuaXQ+PC9jYWM6U2hpcG1lbnQ+PGNhYzpEZXNwYXRjaExpbmU+PGNiYzpJRD4xPC9jYmM6SUQ+PGNiYzpEZWxpdmVyZWRRdWFudGl0eSB1bml0Q29kZT0iTklVIj4xPC9jYmM6RGVsaXZlcmVkUXVhbnRpdHk+PGNhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNiYzpMaW5lSUQ+MTwvY2JjOkxpbmVJRD48L2NhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNhYzpJdGVtPjxjYmM6RGVzY3JpcHRpb24+PCFbQ0RBVEFbREVMRUlURSAxTF1dPjwvY2JjOkRlc2NyaXB0aW9uPjxjYWM6U2VsbGVyc0l0ZW1JZGVudGlmaWNhdGlvbj48Y2JjOklEPjc3NTUxMzkwMDI5MDI8L2NiYzpJRD48L2NhYzpTZWxsZXJzSXRlbUlkZW50aWZpY2F0aW9uPjwvY2FjOkl0ZW0+PC9jYWM6RGVzcGF0Y2hMaW5lPjxjYWM6RGVzcGF0Y2hMaW5lPjxjYmM6SUQ+MjwvY2JjOklEPjxjYmM6RGVsaXZlcmVkUXVhbnRpdHkgdW5pdENvZGU9Ik5JVSI+MTwvY2JjOkRlbGl2ZXJlZFF1YW50aXR5PjxjYWM6T3JkZXJMaW5lUmVmZXJlbmNlPjxjYmM6TGluZUlEPjI8L2NiYzpMaW5lSUQ+PC9jYWM6T3JkZXJMaW5lUmVmZXJlbmNlPjxjYWM6SXRlbT48Y2JjOkRlc2NyaXB0aW9uPjwhW0NEQVRBW1BBSVNBTkEgRVhUUkEgNUtdXT48L2NiYzpEZXNjcmlwdGlvbj48Y2FjOlNlbGxlcnNJdGVtSWRlbnRpZmljYXRpb24+PGNiYzpJRD43NzU1MTM5MDAyODA5PC9jYmM6SUQ+PC9jYWM6U2VsbGVyc0l0ZW1JZGVudGlmaWNhdGlvbj48L2NhYzpJdGVtPjwvY2FjOkRlc3BhdGNoTGluZT48L0Rlc3BhdGNoQWR2aWNlPgo=', NULL),
(69, '09', 'T001', 59, '2024-03-18', 1, 9, '01', 'F001-654', '01', '02', '2024-03-18', 20, 'KGM', 5, '140108', 'AV LIMA 456', '140108', 'AV GRAU 123', NULL, NULL, NULL, NULL, '', 14, 1, 2567, 'Vehiculo principal: 2567 (nodo: \"cac:TransportEquipment/cbc:ID\" valor: \"ASD-5458\")', 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPERlc3BhdGNoQWR2aWNlIHhtbG5zPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpEZXNwYXRjaEFkdmljZS0yIiB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyIgeG1sbnM6Y2FjPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpDb21tb25BZ2dyZWdhdGVDb21wb25lbnRzLTIiIHhtbG5zOmNiYz0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uQmFzaWNDb21wb25lbnRzLTIiIHhtbG5zOmV4dD0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uRXh0ZW5zaW9uQ29tcG9uZW50cy0yIj48ZXh0OlVCTEV4dGVuc2lvbnM+PGV4dDpVQkxFeHRlbnNpb24+PGV4dDpFeHRlbnNpb25Db250ZW50PjxkczpTaWduYXR1cmUgSWQ9IkdyZWVudGVyU2lnbiI+PGRzOlNpZ25lZEluZm8+PGRzOkNhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy9UUi8yMDAxL1JFQy14bWwtYzE0bi0yMDAxMDMxNSIvPjxkczpTaWduYXR1cmVNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjcnNhLXNoYTEiLz48ZHM6UmVmZXJlbmNlIFVSST0iIj48ZHM6VHJhbnNmb3Jtcz48ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI2VudmVsb3BlZC1zaWduYXR1cmUiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8+PGRzOkRpZ2VzdFZhbHVlPm45eVFsMlFBRzdSRWpPY3pzNm1OQlY5RTd1WT08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+TzFhdG14NXZWbHhoaG91cklIUTN4aEZYUEc2VHAwR21VQnRqV2FQSGVTV1IraUNaMHVxbmZiZ3dsWDh5V3ZWTDJGOXBzS3o3Y0FxZml0Nmg4TStYVWlrbml4bDhHMXBDSFBkQkZmUlRCM1paOTRCWkNzQ21uRDA0REZCSjJhcldIaUx4MzVkczZyM05iWlZrZmdSV01iMFNZVUR5Q3Y3ckk1ZmNIalBheHoxOFJreEhSU1NndHZNZ0YzU3lONkdhN2FGQnMwQjhXNEZIU2hLVkg2TlkzWVpzVTZlTkVJbnlvSldtN3A4T2JVWEx5L0lxNWc4N0JaUGtIc0tDckEyOE5QeXR5UmxBaHhqMkRsNVloT3ZvOHVENk9mWFBSVTlrVzJ3T1F1cmFGQ2FRQmx4OSszYWUwMExZOEVOT3NiNnhOajluQzIxdFpoN1FiSVpwNjBheGVnPT08L2RzOlNpZ25hdHVyZVZhbHVlPjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUZDRENDQS9DZ0F3SUJBZ0lKQU9ja2tZN2hrT3l6TUEwR0NTcUdTSWIzRFFFQkN3VUFNSUlCRFRFYk1Ca0dDZ21TSm9tVDhpeGtBUmtXQzB4TVFVMUJMbEJGSUZOQk1Rc3dDUVlEVlFRR0V3SlFSVEVOTUFzR0ExVUVDQXdFVEVsTlFURU5NQXNHQTFVRUJ3d0VURWxOUVRFWU1CWUdBMVVFQ2d3UFZGVWdSVTFRVWtWVFFTQlRMa0V1TVVVd1F3WURWUVFMRER4RVRra2dPVGs1T1RrNU9TQlNWVU1nTWpBME5USTFOemc1TlRFZ0xTQkRSVkpVU1VaSlEwRkVUeUJRUVZKQklFUkZUVTlUVkZKQlEwbkRrMDR4UkRCQ0JnTlZCQU1NTzA1UFRVSlNSU0JTUlZCU1JWTkZUbFJCVGxSRklFeEZSMEZNSUMwZ1EwVlNWRWxHU1VOQlJFOGdVRUZTUVNCRVJVMVBVMVJTUVVOSnc1Tk9NUnd3R2dZSktvWklodmNOQVFrQkZnMWtaVzF2UUd4c1lXMWhMbkJsTUI0WERUSTBNREl5T1RBeE1EYzFPVm9YRFRJMk1ESXlPREF4TURjMU9Wb3dnZ0VOTVJzd0dRWUtDWkltaVpQeUxHUUJHUllMVEV4QlRVRXVVRVVnVTBFeEN6QUpCZ05WQkFZVEFsQkZNUTB3Q3dZRFZRUUlEQVJNU1UxQk1RMHdDd1lEVlFRSERBUk1TVTFCTVJnd0ZnWURWUVFLREE5VVZTQkZUVkJTUlZOQklGTXVRUzR4UlRCREJnTlZCQXNNUEVST1NTQTVPVGs1T1RrNUlGSlZReUF5TURRMU1qVTNPRGsxTVNBdElFTkZVbFJKUmtsRFFVUlBJRkJCVWtFZ1JFVk5UMU5VVWtGRFNjT1RUakZFTUVJR0ExVUVBd3c3VGs5TlFsSkZJRkpGVUZKRlUwVk9WRUZPVkVVZ1RFVkhRVXdnTFNCRFJWSlVTVVpKUTBGRVR5QlFRVkpCSUVSRlRVOVRWRkpCUTBuRGswNHhIREFhQmdrcWhraUc5dzBCQ1FFV0RXUmxiVzlBYkd4aGJXRXVjR1V3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRRFR0SGRjQmNuZUJ2bnorM0JwejhhUGFaM2RaY05ZK29aZ3hYTlFheFpvdzBaYStwb0k2Rjk0cHlZelZyOWY3alZoMW16UFFjZ3NLU3Fpd1ZlOS9IMzBwbkM1NEpyWXVEa2pKL3hQOE5yM0E3VHJDR0RXSVFaTmR4NEhIYWFwaTZiZENuUkxrZFNBam5FWkRhV1FWeWRyRFJVODRqVktOSXVNejBmaE8rRWwxZWI3SGZlelJiTHFERDFRTjI4SkwvZWlONExJbHlKUTJvOU5iRjEySEJZb1kxb01sQ2pnZFM3TWNVNlZaNWdqYzQzL0kyTDVVemZlWDVSK1pQbEFZR2tYMXBLVTBBQmFiOWZlTHFKVUdWOGRJNDVmQTdqZzJOKzdHcjlqeXlDQkZLY3hBV1IveitGTmI3WkZYL0kzK3BkcjhVeWpzUzJRczVaaXNyZWhVdnkvQWdNQkFBR2paekJsTUIwR0ExVWREZ1FXQkJUWVNhYm85Yjc5eWxOK2wzM3BZQlRIRW1XTXBEQWZCZ05WSFNNRUdEQVdnQlRZU2FibzliNzl5bE4rbDMzcFlCVEhFbVdNcERBVEJnTlZIU1VFRERBS0JnZ3JCZ0VGQlFjREFUQU9CZ05WSFE4QkFmOEVCQU1DQjRBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFGNll4NWFKSGFOSlJkczh5MHRCOUVCWERqTTErYStQV1V2cWJGNmZ4c0Q0SjBiZ1JLQzBSZnFWcU1uZm9TMklvcTBkSEhvbUFhQVBoM05McjFJUlZVVHJYWHorRGJqQnEvdkNsNENtSVgrYlhmVTFrWUZJb0VQS3RjQlJUYlFQVWEwYnpJRFl3UWpqNW1iaUpDVSs1VXpqa01xZ1o2V1F1Z1dHYVA4UThsWG4xMkhvR1JIQm9oWHlRYysyb0NwZGhaRisxMEQzZzVLK1prQ1VaSERQNXZXVERSNmhLVUh3YWc3VjZXc1BxVzRZd2xsY0F3QkxIVmpPc0R4cWQ0WHlyaVhGTy9jWVpNc2ZoZzBRZUMvQjVHK3Vkem41eHdPLzJ3ZlJFWlhIamtUOGxqb2taeWhLVzlYMkZUUFltR3dTWWloNEZVdEcvR1BxOFFRVnFrTm9ZaE09PC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpTaWduYXR1cmU+PC9leHQ6RXh0ZW5zaW9uQ29udGVudD48L2V4dDpVQkxFeHRlbnNpb24+PC9leHQ6VUJMRXh0ZW5zaW9ucz48Y2JjOlVCTFZlcnNpb25JRD4yLjE8L2NiYzpVQkxWZXJzaW9uSUQ+PGNiYzpDdXN0b21pemF0aW9uSUQ+Mi4wPC9jYmM6Q3VzdG9taXphdGlvbklEPjxjYmM6SUQ+VDAwMS01OTwvY2JjOklEPjxjYmM6SXNzdWVEYXRlPjIwMjQtMDMtMTc8L2NiYzpJc3N1ZURhdGU+PGNiYzpJc3N1ZVRpbWU+MTg6MDA6MDA8L2NiYzpJc3N1ZVRpbWU+PGNiYzpEZXNwYXRjaEFkdmljZVR5cGVDb2RlIGxpc3RBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgbGlzdE5hbWU9IlRpcG8gZGUgRG9jdW1lbnRvIiBsaXN0VVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzAxIj4wOTwvY2JjOkRlc3BhdGNoQWR2aWNlVHlwZUNvZGU+PGNhYzpTaWduYXR1cmU+PGNiYzpJRD4yMDQ1MjU3ODk1NzwvY2JjOklEPjxjYWM6U2lnbmF0b3J5UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQ+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlOYW1lPjxjYmM6TmFtZT48IVtDREFUQVtUVVRPUklBTEVTIFBIUEVSVV1dPjwvY2JjOk5hbWU+PC9jYWM6UGFydHlOYW1lPjwvY2FjOlNpZ25hdG9yeVBhcnR5PjxjYWM6RGlnaXRhbFNpZ25hdHVyZUF0dGFjaG1lbnQ+PGNhYzpFeHRlcm5hbFJlZmVyZW5jZT48Y2JjOlVSST4jR1JFRU5URVItU0lHTjwvY2JjOlVSST48L2NhYzpFeHRlcm5hbFJlZmVyZW5jZT48L2NhYzpEaWdpdGFsU2lnbmF0dXJlQXR0YWNobWVudD48L2NhYzpTaWduYXR1cmU+PGNhYzpEZXNwYXRjaFN1cHBsaWVyUGFydHk+PGNhYzpQYXJ0eT48Y2FjOlBhcnR5SWRlbnRpZmljYXRpb24+PGNiYzpJRCBzY2hlbWVJRD0iNiIgc2NoZW1lTmFtZT0iRG9jdW1lbnRvIGRlIElkZW50aWRhZCIgc2NoZW1lQWdlbmN5TmFtZT0iUEU6U1VOQVQiIHNjaGVtZVVSST0idXJuOnBlOmdvYjpzdW5hdDpjcGU6c2VlOmdlbTpjYXRhbG9nb3M6Y2F0YWxvZ28wNiI+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlMZWdhbEVudGl0eT48Y2JjOlJlZ2lzdHJhdGlvbk5hbWU+PCFbQ0RBVEFbVFVUT1JJQUxFUyBQSFBFUlVdXT48L2NiYzpSZWdpc3RyYXRpb25OYW1lPjwvY2FjOlBhcnR5TGVnYWxFbnRpdHk+PC9jYWM6UGFydHk+PC9jYWM6RGVzcGF0Y2hTdXBwbGllclBhcnR5PjxjYWM6RGVsaXZlcnlDdXN0b21lclBhcnR5PjxjYWM6UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQgc2NoZW1lSUQ9IjYiIHNjaGVtZU5hbWU9IkRvY3VtZW50byBkZSBJZGVudGlkYWQiIHNjaGVtZUFnZW5jeU5hbWU9IlBFOlNVTkFUIiBzY2hlbWVVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMDYiPjIwNTUzODU2NDUxPC9jYmM6SUQ+PC9jYWM6UGFydHlJZGVudGlmaWNhdGlvbj48Y2FjOlBhcnR5TGVnYWxFbnRpdHk+PGNiYzpSZWdpc3RyYXRpb25OYW1lPjwhW0NEQVRBW0JJIEdSQU5EIENPTkZFQ0NJT05FUyBTLkEuQy5dXT48L2NiYzpSZWdpc3RyYXRpb25OYW1lPjwvY2FjOlBhcnR5TGVnYWxFbnRpdHk+PC9jYWM6UGFydHk+PC9jYWM6RGVsaXZlcnlDdXN0b21lclBhcnR5PjxjYWM6U2hpcG1lbnQ+PGNiYzpJRD5TVU5BVF9FbnZpbzwvY2JjOklEPjxjYmM6SGFuZGxpbmdDb2RlIGxpc3RBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgbGlzdE5hbWU9Ik1vdGl2byBkZSB0cmFzbGFkbyIgbGlzdFVSST0idXJuOnBlOmdvYjpzdW5hdDpjcGU6c2VlOmdlbTpjYXRhbG9nb3M6Y2F0YWxvZ28yMCI+MDE8L2NiYzpIYW5kbGluZ0NvZGU+PGNiYzpHcm9zc1dlaWdodE1lYXN1cmUgdW5pdENvZGU9IktHTSI+MjAuMDAwPC9jYmM6R3Jvc3NXZWlnaHRNZWFzdXJlPjxjYmM6VG90YWxUcmFuc3BvcnRIYW5kbGluZ1VuaXRRdWFudGl0eT41PC9jYmM6VG90YWxUcmFuc3BvcnRIYW5kbGluZ1VuaXRRdWFudGl0eT48Y2FjOlNoaXBtZW50U3RhZ2U+PGNiYzpUcmFuc3BvcnRNb2RlQ29kZSBsaXN0TmFtZT0iTW9kYWxpZGFkIGRlIHRyYXNsYWRvIiBsaXN0QWdlbmN5TmFtZT0iUEU6U1VOQVQiIGxpc3RVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMTgiPjAyPC9jYmM6VHJhbnNwb3J0TW9kZUNvZGU+PGNhYzpUcmFuc2l0UGVyaW9kPjxjYmM6U3RhcnREYXRlPjIwMjQtMDMtMTc8L2NiYzpTdGFydERhdGU+PC9jYWM6VHJhbnNpdFBlcmlvZD48Y2FjOkRyaXZlclBlcnNvbj48Y2JjOklEIHNjaGVtZUlEPSIxIiBzY2hlbWVOYW1lPSJEb2N1bWVudG8gZGUgSWRlbnRpZGFkIiBzY2hlbWVBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgc2NoZW1lVVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzA2Ij40NTI1Nzg5NTwvY2JjOklEPjxjYmM6Rmlyc3ROYW1lPkxVSVM8L2NiYzpGaXJzdE5hbWU+PGNiYzpGYW1pbHlOYW1lPkxPWkFOTzwvY2JjOkZhbWlseU5hbWU+PGNiYzpKb2JUaXRsZT5QcmluY2lwYWw8L2NiYzpKb2JUaXRsZT48Y2FjOklkZW50aXR5RG9jdW1lbnRSZWZlcmVuY2U+PGNiYzpJRD5BU0QtNTY1NDY1NDk4NDwvY2JjOklEPjwvY2FjOklkZW50aXR5RG9jdW1lbnRSZWZlcmVuY2U+PC9jYWM6RHJpdmVyUGVyc29uPjwvY2FjOlNoaXBtZW50U3RhZ2U+PGNhYzpEZWxpdmVyeT48Y2FjOkRlbGl2ZXJ5QWRkcmVzcz48Y2JjOklEIHNjaGVtZUFnZW5jeU5hbWU9IlBFOklORUkiIHNjaGVtZU5hbWU9IlViaWdlb3MiPjE0MDEwODwvY2JjOklEPjxjYWM6QWRkcmVzc0xpbmU+PGNiYzpMaW5lPmF2IGxpbWEgNDU2PC9jYmM6TGluZT48L2NhYzpBZGRyZXNzTGluZT48L2NhYzpEZWxpdmVyeUFkZHJlc3M+PGNhYzpEZXNwYXRjaD48Y2FjOkRlc3BhdGNoQWRkcmVzcz48Y2JjOklEIHNjaGVtZUFnZW5jeU5hbWU9IlBFOklORUkiIHNjaGVtZU5hbWU9IlViaWdlb3MiPjE0MDEwODwvY2JjOklEPjxjYWM6QWRkcmVzc0xpbmU+PGNiYzpMaW5lPmF2IGdyYXUgMTIzPC9jYmM6TGluZT48L2NhYzpBZGRyZXNzTGluZT48L2NhYzpEZXNwYXRjaEFkZHJlc3M+PC9jYWM6RGVzcGF0Y2g+PC9jYWM6RGVsaXZlcnk+PGNhYzpUcmFuc3BvcnRIYW5kbGluZ1VuaXQ+PGNhYzpUcmFuc3BvcnRFcXVpcG1lbnQ+PGNiYzpJRD5BU0QtNTQ1ODwvY2JjOklEPjwvY2FjOlRyYW5zcG9ydEVxdWlwbWVudD48L2NhYzpUcmFuc3BvcnRIYW5kbGluZ1VuaXQ+PC9jYWM6U2hpcG1lbnQ+PGNhYzpEZXNwYXRjaExpbmU+PGNiYzpJRD4xPC9jYmM6SUQ+PGNiYzpEZWxpdmVyZWRRdWFudGl0eSB1bml0Q29kZT0iTklVIj4xPC9jYmM6RGVsaXZlcmVkUXVhbnRpdHk+PGNhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNiYzpMaW5lSUQ+MTwvY2JjOkxpbmVJRD48L2NhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNhYzpJdGVtPjxjYmM6RGVzY3JpcHRpb24+PCFbQ0RBVEFbREVMRUlURSAxTF1dPjwvY2JjOkRlc2NyaXB0aW9uPjxjYWM6U2VsbGVyc0l0ZW1JZGVudGlmaWNhdGlvbj48Y2JjOklEPjc3NTUxMzkwMDI5MDI8L2NiYzpJRD48L2NhYzpTZWxsZXJzSXRlbUlkZW50aWZpY2F0aW9uPjwvY2FjOkl0ZW0+PC9jYWM6RGVzcGF0Y2hMaW5lPjxjYWM6RGVzcGF0Y2hMaW5lPjxjYmM6SUQ+MjwvY2JjOklEPjxjYmM6RGVsaXZlcmVkUXVhbnRpdHkgdW5pdENvZGU9Ik5JVSI+MTwvY2JjOkRlbGl2ZXJlZFF1YW50aXR5PjxjYWM6T3JkZXJMaW5lUmVmZXJlbmNlPjxjYmM6TGluZUlEPjI8L2NiYzpMaW5lSUQ+PC9jYWM6T3JkZXJMaW5lUmVmZXJlbmNlPjxjYWM6SXRlbT48Y2JjOkRlc2NyaXB0aW9uPjwhW0NEQVRBW1BBSVNBTkEgRVhUUkEgNUtdXT48L2NiYzpEZXNjcmlwdGlvbj48Y2FjOlNlbGxlcnNJdGVtSWRlbnRpZmljYXRpb24+PGNiYzpJRD43NzU1MTM5MDAyODA5PC9jYmM6SUQ+PC9jYWM6U2VsbGVyc0l0ZW1JZGVudGlmaWNhdGlvbj48L2NhYzpJdGVtPjwvY2FjOkRlc3BhdGNoTGluZT48L0Rlc3BhdGNoQWR2aWNlPgo=', NULL),
(70, '09', 'T001', 60, '2024-03-18', 1, 9, '01', 'F001-654', '01', '02', '2024-03-18', 20, 'KGM', 5, '140108', 'AV LIMA 456', '140108', 'AV GRAU 123', NULL, NULL, NULL, NULL, '', 14, 1, 2567, 'Vehiculo principal: 2567 (nodo: \"cac:TransportEquipment/cbc:ID\" valor: \"ASD-5458\")', NULL, NULL),
(71, '09', 'T001', 61, '2024-03-18', 1, 9, '01', 'F001-654', '01', '02', '2024-03-18', 20, 'KGM', 5, '140108', 'AV LIMA 456', '140108', 'AV GRAU 123', NULL, NULL, NULL, NULL, '', 14, 1, 2567, 'Vehiculo principal: 2567 (nodo: \"cac:TransportEquipment/cbc:ID\" valor: \"ASD-5458\")', NULL, NULL),
(72, '09', 'T001', 62, '2024-03-18', 1, 9, '01', 'F001-654', '01', '02', '2024-03-18', 20, 'KGM', 5, '140108', 'AV LIMA 456', '140108', 'AV GRAU 123', NULL, NULL, NULL, NULL, '', 14, 1, 2567, 'Vehiculo principal: 2567 (nodo: \"cac:TransportEquipment/cbc:ID\" valor: \"ASD-5458\")', NULL, NULL),
(73, '09', 'T001', 63, '2024-03-18', 1, 9, '01', 'F001-654', '01', '02', '2024-03-18', 20, 'KGM', 5, '140108', 'AV LIMA 456', '140108', 'AV GRAU 123', NULL, NULL, NULL, NULL, '', 14, 1, 2567, 'Vehiculo principal: 2567 (nodo: \"cac:TransportEquipment/cbc:ID\" valor: \"ASD-5458\")', 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPERlc3BhdGNoQWR2aWNlIHhtbG5zPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpEZXNwYXRjaEFkdmljZS0yIiB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyIgeG1sbnM6Y2FjPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpDb21tb25BZ2dyZWdhdGVDb21wb25lbnRzLTIiIHhtbG5zOmNiYz0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uQmFzaWNDb21wb25lbnRzLTIiIHhtbG5zOmV4dD0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uRXh0ZW5zaW9uQ29tcG9uZW50cy0yIj48ZXh0OlVCTEV4dGVuc2lvbnM+PGV4dDpVQkxFeHRlbnNpb24+PGV4dDpFeHRlbnNpb25Db250ZW50PjxkczpTaWduYXR1cmUgSWQ9IkdyZWVudGVyU2lnbiI+PGRzOlNpZ25lZEluZm8+PGRzOkNhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy9UUi8yMDAxL1JFQy14bWwtYzE0bi0yMDAxMDMxNSIvPjxkczpTaWduYXR1cmVNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjcnNhLXNoYTEiLz48ZHM6UmVmZXJlbmNlIFVSST0iIj48ZHM6VHJhbnNmb3Jtcz48ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI2VudmVsb3BlZC1zaWduYXR1cmUiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8+PGRzOkRpZ2VzdFZhbHVlPi9wb3hzUnk3ckxteEROTGM4QlVNNEpYR1dMcz08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+SFhCRWMwODFKaFJLZFJkRTdyOUIyZjhkV2tWWngvS0FwUzlyOVFzNmdqdFJERUF3YU44c2I3TkMySmdMT0pwZld3cldqdnNCbERQZ0wxVW5XMUtyUWRrMTJsR0hxSmFiOTZQOFRjUlk5ekhkNmNyaE0wQ1JXc294dnBZeFV4Z3hvWkVEY1VwakxBL2VIejBrWm9uT0FobnZoK0tqcUZ5UFVhcHgrOE5OZkZjR3ZoNHRkMUtBTE9hNjlaelFRUHJPWnR3c285WnBoOGNpVnhhVjgyNmhXY3YvRnpkRkxiek01dFpTZTQvVys4RkZGbFNCOFg1NVRJaXpEUk1ndVBFQzhodzdRZkFzWUNqR3p0MTFaeGJZMk5iL21mY3lGeCtjam5OOXRTNFM0QTRHMlJiZVNuNlJCSWhGWE1sUDB2ci9RVk1DTFM5WDlHeUFVcS9tZzFaYVRBPT08L2RzOlNpZ25hdHVyZVZhbHVlPjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUZDRENDQS9DZ0F3SUJBZ0lKQU9ja2tZN2hrT3l6TUEwR0NTcUdTSWIzRFFFQkN3VUFNSUlCRFRFYk1Ca0dDZ21TSm9tVDhpeGtBUmtXQzB4TVFVMUJMbEJGSUZOQk1Rc3dDUVlEVlFRR0V3SlFSVEVOTUFzR0ExVUVDQXdFVEVsTlFURU5NQXNHQTFVRUJ3d0VURWxOUVRFWU1CWUdBMVVFQ2d3UFZGVWdSVTFRVWtWVFFTQlRMa0V1TVVVd1F3WURWUVFMRER4RVRra2dPVGs1T1RrNU9TQlNWVU1nTWpBME5USTFOemc1TlRFZ0xTQkRSVkpVU1VaSlEwRkVUeUJRUVZKQklFUkZUVTlUVkZKQlEwbkRrMDR4UkRCQ0JnTlZCQU1NTzA1UFRVSlNSU0JTUlZCU1JWTkZUbFJCVGxSRklFeEZSMEZNSUMwZ1EwVlNWRWxHU1VOQlJFOGdVRUZTUVNCRVJVMVBVMVJTUVVOSnc1Tk9NUnd3R2dZSktvWklodmNOQVFrQkZnMWtaVzF2UUd4c1lXMWhMbkJsTUI0WERUSTBNREl5T1RBeE1EYzFPVm9YRFRJMk1ESXlPREF4TURjMU9Wb3dnZ0VOTVJzd0dRWUtDWkltaVpQeUxHUUJHUllMVEV4QlRVRXVVRVVnVTBFeEN6QUpCZ05WQkFZVEFsQkZNUTB3Q3dZRFZRUUlEQVJNU1UxQk1RMHdDd1lEVlFRSERBUk1TVTFCTVJnd0ZnWURWUVFLREE5VVZTQkZUVkJTUlZOQklGTXVRUzR4UlRCREJnTlZCQXNNUEVST1NTQTVPVGs1T1RrNUlGSlZReUF5TURRMU1qVTNPRGsxTVNBdElFTkZVbFJKUmtsRFFVUlBJRkJCVWtFZ1JFVk5UMU5VVWtGRFNjT1RUakZFTUVJR0ExVUVBd3c3VGs5TlFsSkZJRkpGVUZKRlUwVk9WRUZPVkVVZ1RFVkhRVXdnTFNCRFJWSlVTVVpKUTBGRVR5QlFRVkpCSUVSRlRVOVRWRkpCUTBuRGswNHhIREFhQmdrcWhraUc5dzBCQ1FFV0RXUmxiVzlBYkd4aGJXRXVjR1V3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRRFR0SGRjQmNuZUJ2bnorM0JwejhhUGFaM2RaY05ZK29aZ3hYTlFheFpvdzBaYStwb0k2Rjk0cHlZelZyOWY3alZoMW16UFFjZ3NLU3Fpd1ZlOS9IMzBwbkM1NEpyWXVEa2pKL3hQOE5yM0E3VHJDR0RXSVFaTmR4NEhIYWFwaTZiZENuUkxrZFNBam5FWkRhV1FWeWRyRFJVODRqVktOSXVNejBmaE8rRWwxZWI3SGZlelJiTHFERDFRTjI4SkwvZWlONExJbHlKUTJvOU5iRjEySEJZb1kxb01sQ2pnZFM3TWNVNlZaNWdqYzQzL0kyTDVVemZlWDVSK1pQbEFZR2tYMXBLVTBBQmFiOWZlTHFKVUdWOGRJNDVmQTdqZzJOKzdHcjlqeXlDQkZLY3hBV1IveitGTmI3WkZYL0kzK3BkcjhVeWpzUzJRczVaaXNyZWhVdnkvQWdNQkFBR2paekJsTUIwR0ExVWREZ1FXQkJUWVNhYm85Yjc5eWxOK2wzM3BZQlRIRW1XTXBEQWZCZ05WSFNNRUdEQVdnQlRZU2FibzliNzl5bE4rbDMzcFlCVEhFbVdNcERBVEJnTlZIU1VFRERBS0JnZ3JCZ0VGQlFjREFUQU9CZ05WSFE4QkFmOEVCQU1DQjRBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFGNll4NWFKSGFOSlJkczh5MHRCOUVCWERqTTErYStQV1V2cWJGNmZ4c0Q0SjBiZ1JLQzBSZnFWcU1uZm9TMklvcTBkSEhvbUFhQVBoM05McjFJUlZVVHJYWHorRGJqQnEvdkNsNENtSVgrYlhmVTFrWUZJb0VQS3RjQlJUYlFQVWEwYnpJRFl3UWpqNW1iaUpDVSs1VXpqa01xZ1o2V1F1Z1dHYVA4UThsWG4xMkhvR1JIQm9oWHlRYysyb0NwZGhaRisxMEQzZzVLK1prQ1VaSERQNXZXVERSNmhLVUh3YWc3VjZXc1BxVzRZd2xsY0F3QkxIVmpPc0R4cWQ0WHlyaVhGTy9jWVpNc2ZoZzBRZUMvQjVHK3Vkem41eHdPLzJ3ZlJFWlhIamtUOGxqb2taeWhLVzlYMkZUUFltR3dTWWloNEZVdEcvR1BxOFFRVnFrTm9ZaE09PC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpTaWduYXR1cmU+PC9leHQ6RXh0ZW5zaW9uQ29udGVudD48L2V4dDpVQkxFeHRlbnNpb24+PC9leHQ6VUJMRXh0ZW5zaW9ucz48Y2JjOlVCTFZlcnNpb25JRD4yLjE8L2NiYzpVQkxWZXJzaW9uSUQ+PGNiYzpDdXN0b21pemF0aW9uSUQ+Mi4wPC9jYmM6Q3VzdG9taXphdGlvbklEPjxjYmM6SUQ+VDAwMS02MzwvY2JjOklEPjxjYmM6SXNzdWVEYXRlPjIwMjQtMDMtMTc8L2NiYzpJc3N1ZURhdGU+PGNiYzpJc3N1ZVRpbWU+MTg6MDA6MDA8L2NiYzpJc3N1ZVRpbWU+PGNiYzpEZXNwYXRjaEFkdmljZVR5cGVDb2RlIGxpc3RBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgbGlzdE5hbWU9IlRpcG8gZGUgRG9jdW1lbnRvIiBsaXN0VVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzAxIj4wOTwvY2JjOkRlc3BhdGNoQWR2aWNlVHlwZUNvZGU+PGNhYzpTaWduYXR1cmU+PGNiYzpJRD4yMDQ1MjU3ODk1NzwvY2JjOklEPjxjYWM6U2lnbmF0b3J5UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQ+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlOYW1lPjxjYmM6TmFtZT48IVtDREFUQVtUVVRPUklBTEVTIFBIUEVSVV1dPjwvY2JjOk5hbWU+PC9jYWM6UGFydHlOYW1lPjwvY2FjOlNpZ25hdG9yeVBhcnR5PjxjYWM6RGlnaXRhbFNpZ25hdHVyZUF0dGFjaG1lbnQ+PGNhYzpFeHRlcm5hbFJlZmVyZW5jZT48Y2JjOlVSST4jR1JFRU5URVItU0lHTjwvY2JjOlVSST48L2NhYzpFeHRlcm5hbFJlZmVyZW5jZT48L2NhYzpEaWdpdGFsU2lnbmF0dXJlQXR0YWNobWVudD48L2NhYzpTaWduYXR1cmU+PGNhYzpEZXNwYXRjaFN1cHBsaWVyUGFydHk+PGNhYzpQYXJ0eT48Y2FjOlBhcnR5SWRlbnRpZmljYXRpb24+PGNiYzpJRCBzY2hlbWVJRD0iNiIgc2NoZW1lTmFtZT0iRG9jdW1lbnRvIGRlIElkZW50aWRhZCIgc2NoZW1lQWdlbmN5TmFtZT0iUEU6U1VOQVQiIHNjaGVtZVVSST0idXJuOnBlOmdvYjpzdW5hdDpjcGU6c2VlOmdlbTpjYXRhbG9nb3M6Y2F0YWxvZ28wNiI+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlMZWdhbEVudGl0eT48Y2JjOlJlZ2lzdHJhdGlvbk5hbWU+PCFbQ0RBVEFbVFVUT1JJQUxFUyBQSFBFUlVdXT48L2NiYzpSZWdpc3RyYXRpb25OYW1lPjwvY2FjOlBhcnR5TGVnYWxFbnRpdHk+PC9jYWM6UGFydHk+PC9jYWM6RGVzcGF0Y2hTdXBwbGllclBhcnR5PjxjYWM6RGVsaXZlcnlDdXN0b21lclBhcnR5PjxjYWM6UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQgc2NoZW1lSUQ9IjYiIHNjaGVtZU5hbWU9IkRvY3VtZW50byBkZSBJZGVudGlkYWQiIHNjaGVtZUFnZW5jeU5hbWU9IlBFOlNVTkFUIiBzY2hlbWVVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMDYiPjIwNTUzODU2NDUxPC9jYmM6SUQ+PC9jYWM6UGFydHlJZGVudGlmaWNhdGlvbj48Y2FjOlBhcnR5TGVnYWxFbnRpdHk+PGNiYzpSZWdpc3RyYXRpb25OYW1lPjwhW0NEQVRBW0JJIEdSQU5EIENPTkZFQ0NJT05FUyBTLkEuQy5dXT48L2NiYzpSZWdpc3RyYXRpb25OYW1lPjwvY2FjOlBhcnR5TGVnYWxFbnRpdHk+PC9jYWM6UGFydHk+PC9jYWM6RGVsaXZlcnlDdXN0b21lclBhcnR5PjxjYWM6U2hpcG1lbnQ+PGNiYzpJRD5TVU5BVF9FbnZpbzwvY2JjOklEPjxjYmM6SGFuZGxpbmdDb2RlIGxpc3RBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgbGlzdE5hbWU9Ik1vdGl2byBkZSB0cmFzbGFkbyIgbGlzdFVSST0idXJuOnBlOmdvYjpzdW5hdDpjcGU6c2VlOmdlbTpjYXRhbG9nb3M6Y2F0YWxvZ28yMCI+MDE8L2NiYzpIYW5kbGluZ0NvZGU+PGNiYzpHcm9zc1dlaWdodE1lYXN1cmUgdW5pdENvZGU9IktHTSI+MjAuMDAwPC9jYmM6R3Jvc3NXZWlnaHRNZWFzdXJlPjxjYmM6VG90YWxUcmFuc3BvcnRIYW5kbGluZ1VuaXRRdWFudGl0eT41PC9jYmM6VG90YWxUcmFuc3BvcnRIYW5kbGluZ1VuaXRRdWFudGl0eT48Y2FjOlNoaXBtZW50U3RhZ2U+PGNiYzpUcmFuc3BvcnRNb2RlQ29kZSBsaXN0TmFtZT0iTW9kYWxpZGFkIGRlIHRyYXNsYWRvIiBsaXN0QWdlbmN5TmFtZT0iUEU6U1VOQVQiIGxpc3RVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMTgiPjAyPC9jYmM6VHJhbnNwb3J0TW9kZUNvZGU+PGNhYzpUcmFuc2l0UGVyaW9kPjxjYmM6U3RhcnREYXRlPjIwMjQtMDMtMTc8L2NiYzpTdGFydERhdGU+PC9jYWM6VHJhbnNpdFBlcmlvZD48Y2FjOkRyaXZlclBlcnNvbj48Y2JjOklEIHNjaGVtZUlEPSIxIiBzY2hlbWVOYW1lPSJEb2N1bWVudG8gZGUgSWRlbnRpZGFkIiBzY2hlbWVBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgc2NoZW1lVVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzA2Ij40NTI1Nzg5NTwvY2JjOklEPjxjYmM6Rmlyc3ROYW1lPkxVSVM8L2NiYzpGaXJzdE5hbWU+PGNiYzpGYW1pbHlOYW1lPkxPWkFOTzwvY2JjOkZhbWlseU5hbWU+PGNiYzpKb2JUaXRsZT5QcmluY2lwYWw8L2NiYzpKb2JUaXRsZT48Y2FjOklkZW50aXR5RG9jdW1lbnRSZWZlcmVuY2U+PGNiYzpJRD5BU0QtNTY1NDY1NDk4NDwvY2JjOklEPjwvY2FjOklkZW50aXR5RG9jdW1lbnRSZWZlcmVuY2U+PC9jYWM6RHJpdmVyUGVyc29uPjwvY2FjOlNoaXBtZW50U3RhZ2U+PGNhYzpEZWxpdmVyeT48Y2FjOkRlbGl2ZXJ5QWRkcmVzcz48Y2JjOklEIHNjaGVtZUFnZW5jeU5hbWU9IlBFOklORUkiIHNjaGVtZU5hbWU9IlViaWdlb3MiPjE0MDEwODwvY2JjOklEPjxjYWM6QWRkcmVzc0xpbmU+PGNiYzpMaW5lPmF2IGxpbWEgNDU2PC9jYmM6TGluZT48L2NhYzpBZGRyZXNzTGluZT48L2NhYzpEZWxpdmVyeUFkZHJlc3M+PGNhYzpEZXNwYXRjaD48Y2FjOkRlc3BhdGNoQWRkcmVzcz48Y2JjOklEIHNjaGVtZUFnZW5jeU5hbWU9IlBFOklORUkiIHNjaGVtZU5hbWU9IlViaWdlb3MiPjE0MDEwODwvY2JjOklEPjxjYWM6QWRkcmVzc0xpbmU+PGNiYzpMaW5lPmF2IGdyYXUgMTIzPC9jYmM6TGluZT48L2NhYzpBZGRyZXNzTGluZT48L2NhYzpEZXNwYXRjaEFkZHJlc3M+PC9jYWM6RGVzcGF0Y2g+PC9jYWM6RGVsaXZlcnk+PGNhYzpUcmFuc3BvcnRIYW5kbGluZ1VuaXQ+PGNhYzpUcmFuc3BvcnRFcXVpcG1lbnQ+PGNiYzpJRD5BU0QtNTQ1ODwvY2JjOklEPjwvY2FjOlRyYW5zcG9ydEVxdWlwbWVudD48L2NhYzpUcmFuc3BvcnRIYW5kbGluZ1VuaXQ+PC9jYWM6U2hpcG1lbnQ+PGNhYzpEZXNwYXRjaExpbmU+PGNiYzpJRD4xPC9jYmM6SUQ+PGNiYzpEZWxpdmVyZWRRdWFudGl0eSB1bml0Q29kZT0iTklVIj4xPC9jYmM6RGVsaXZlcmVkUXVhbnRpdHk+PGNhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNiYzpMaW5lSUQ+MTwvY2JjOkxpbmVJRD48L2NhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNhYzpJdGVtPjxjYmM6RGVzY3JpcHRpb24+PCFbQ0RBVEFbREVMRUlURSAxTF1dPjwvY2JjOkRlc2NyaXB0aW9uPjxjYWM6U2VsbGVyc0l0ZW1JZGVudGlmaWNhdGlvbj48Y2JjOklEPjc3NTUxMzkwMDI5MDI8L2NiYzpJRD48L2NhYzpTZWxsZXJzSXRlbUlkZW50aWZpY2F0aW9uPjwvY2FjOkl0ZW0+PC9jYWM6RGVzcGF0Y2hMaW5lPjxjYWM6RGVzcGF0Y2hMaW5lPjxjYmM6SUQ+MjwvY2JjOklEPjxjYmM6RGVsaXZlcmVkUXVhbnRpdHkgdW5pdENvZGU9Ik5JVSI+MTwvY2JjOkRlbGl2ZXJlZFF1YW50aXR5PjxjYWM6T3JkZXJMaW5lUmVmZXJlbmNlPjxjYmM6TGluZUlEPjI8L2NiYzpMaW5lSUQ+PC9jYWM6T3JkZXJMaW5lUmVmZXJlbmNlPjxjYWM6SXRlbT48Y2JjOkRlc2NyaXB0aW9uPjwhW0NEQVRBW1BBSVNBTkEgRVhUUkEgNUtdXT48L2NiYzpEZXNjcmlwdGlvbj48Y2FjOlNlbGxlcnNJdGVtSWRlbnRpZmljYXRpb24+PGNiYzpJRD43NzU1MTM5MDAyODA5PC9jYmM6SUQ+PC9jYWM6U2VsbGVyc0l0ZW1JZGVudGlmaWNhdGlvbj48L2NhYzpJdGVtPjwvY2FjOkRlc3BhdGNoTGluZT48L0Rlc3BhdGNoQWR2aWNlPgo=', NULL),
(74, '09', 'T001', 64, '2024-03-18', 1, 9, '01', 'F001-654', '01', '02', '2024-03-18', 20, 'KGM', 5, '140108', 'AV LIMA 456', '140108', 'AV GRAU 123', NULL, NULL, NULL, NULL, '', 14, 1, 2567, 'Vehiculo principal: 2567 (nodo: \"cac:TransportEquipment/cbc:ID\" valor: \"ASD-5458\")', 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPERlc3BhdGNoQWR2aWNlIHhtbG5zPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpEZXNwYXRjaEFkdmljZS0yIiB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyIgeG1sbnM6Y2FjPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpDb21tb25BZ2dyZWdhdGVDb21wb25lbnRzLTIiIHhtbG5zOmNiYz0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uQmFzaWNDb21wb25lbnRzLTIiIHhtbG5zOmV4dD0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uRXh0ZW5zaW9uQ29tcG9uZW50cy0yIj48ZXh0OlVCTEV4dGVuc2lvbnM+PGV4dDpVQkxFeHRlbnNpb24+PGV4dDpFeHRlbnNpb25Db250ZW50PjxkczpTaWduYXR1cmUgSWQ9IkdyZWVudGVyU2lnbiI+PGRzOlNpZ25lZEluZm8+PGRzOkNhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy9UUi8yMDAxL1JFQy14bWwtYzE0bi0yMDAxMDMxNSIvPjxkczpTaWduYXR1cmVNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjcnNhLXNoYTEiLz48ZHM6UmVmZXJlbmNlIFVSST0iIj48ZHM6VHJhbnNmb3Jtcz48ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI2VudmVsb3BlZC1zaWduYXR1cmUiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8+PGRzOkRpZ2VzdFZhbHVlPkxnc2pjbWdaNlFQM0JpR1QrNVRxTUpDSXZrZz08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+b3dlQUVKbGM0Nml4REg0WEQ2bkRLbENMUCttSWxXMHVWdGJ1YjEzOW1seTZVZTB4RjZSV0tIMldKT1p0Qks2VVBkL3pvRVFOZFg3WW5WclRYTWs2cGkwYmJqNk5XTURUc3E0cml6WWRQMkxxRUVWMjB0cDlwNzQ4aVhoZmtnT3JNN3VBVFpWSkpvbUMrQWRrN0o4ZldTdkpUa3FybVQ1cDAzT2dFMkVoc0ltcldlNWVVa0x4UjFnQ3FTNlMzTHplK1JlbjVIcHNWYzhIc2xhajkySWhlYlZCYm5BWG9acFBMalkwTkVxR1VGd2NWd3djOU1wUjc2L3FGVjNNOHdJRXlhSGpoblFzWloyRjM1UWIvNVhBNTM5Z0lGeTRlTU1jK3VuK1lEWGwzejJ1QThDMStIcjNqQU1vd2J6Z1hJZzNsdEpEdmc3NzFUbW5VbGxkc2tEZzFnPT08L2RzOlNpZ25hdHVyZVZhbHVlPjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUZDRENDQS9DZ0F3SUJBZ0lKQU9ja2tZN2hrT3l6TUEwR0NTcUdTSWIzRFFFQkN3VUFNSUlCRFRFYk1Ca0dDZ21TSm9tVDhpeGtBUmtXQzB4TVFVMUJMbEJGSUZOQk1Rc3dDUVlEVlFRR0V3SlFSVEVOTUFzR0ExVUVDQXdFVEVsTlFURU5NQXNHQTFVRUJ3d0VURWxOUVRFWU1CWUdBMVVFQ2d3UFZGVWdSVTFRVWtWVFFTQlRMa0V1TVVVd1F3WURWUVFMRER4RVRra2dPVGs1T1RrNU9TQlNWVU1nTWpBME5USTFOemc1TlRFZ0xTQkRSVkpVU1VaSlEwRkVUeUJRUVZKQklFUkZUVTlUVkZKQlEwbkRrMDR4UkRCQ0JnTlZCQU1NTzA1UFRVSlNSU0JTUlZCU1JWTkZUbFJCVGxSRklFeEZSMEZNSUMwZ1EwVlNWRWxHU1VOQlJFOGdVRUZTUVNCRVJVMVBVMVJTUVVOSnc1Tk9NUnd3R2dZSktvWklodmNOQVFrQkZnMWtaVzF2UUd4c1lXMWhMbkJsTUI0WERUSTBNREl5T1RBeE1EYzFPVm9YRFRJMk1ESXlPREF4TURjMU9Wb3dnZ0VOTVJzd0dRWUtDWkltaVpQeUxHUUJHUllMVEV4QlRVRXVVRVVnVTBFeEN6QUpCZ05WQkFZVEFsQkZNUTB3Q3dZRFZRUUlEQVJNU1UxQk1RMHdDd1lEVlFRSERBUk1TVTFCTVJnd0ZnWURWUVFLREE5VVZTQkZUVkJTUlZOQklGTXVRUzR4UlRCREJnTlZCQXNNUEVST1NTQTVPVGs1T1RrNUlGSlZReUF5TURRMU1qVTNPRGsxTVNBdElFTkZVbFJKUmtsRFFVUlBJRkJCVWtFZ1JFVk5UMU5VVWtGRFNjT1RUakZFTUVJR0ExVUVBd3c3VGs5TlFsSkZJRkpGVUZKRlUwVk9WRUZPVkVVZ1RFVkhRVXdnTFNCRFJWSlVTVVpKUTBGRVR5QlFRVkpCSUVSRlRVOVRWRkpCUTBuRGswNHhIREFhQmdrcWhraUc5dzBCQ1FFV0RXUmxiVzlBYkd4aGJXRXVjR1V3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRRFR0SGRjQmNuZUJ2bnorM0JwejhhUGFaM2RaY05ZK29aZ3hYTlFheFpvdzBaYStwb0k2Rjk0cHlZelZyOWY3alZoMW16UFFjZ3NLU3Fpd1ZlOS9IMzBwbkM1NEpyWXVEa2pKL3hQOE5yM0E3VHJDR0RXSVFaTmR4NEhIYWFwaTZiZENuUkxrZFNBam5FWkRhV1FWeWRyRFJVODRqVktOSXVNejBmaE8rRWwxZWI3SGZlelJiTHFERDFRTjI4SkwvZWlONExJbHlKUTJvOU5iRjEySEJZb1kxb01sQ2pnZFM3TWNVNlZaNWdqYzQzL0kyTDVVemZlWDVSK1pQbEFZR2tYMXBLVTBBQmFiOWZlTHFKVUdWOGRJNDVmQTdqZzJOKzdHcjlqeXlDQkZLY3hBV1IveitGTmI3WkZYL0kzK3BkcjhVeWpzUzJRczVaaXNyZWhVdnkvQWdNQkFBR2paekJsTUIwR0ExVWREZ1FXQkJUWVNhYm85Yjc5eWxOK2wzM3BZQlRIRW1XTXBEQWZCZ05WSFNNRUdEQVdnQlRZU2FibzliNzl5bE4rbDMzcFlCVEhFbVdNcERBVEJnTlZIU1VFRERBS0JnZ3JCZ0VGQlFjREFUQU9CZ05WSFE4QkFmOEVCQU1DQjRBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFGNll4NWFKSGFOSlJkczh5MHRCOUVCWERqTTErYStQV1V2cWJGNmZ4c0Q0SjBiZ1JLQzBSZnFWcU1uZm9TMklvcTBkSEhvbUFhQVBoM05McjFJUlZVVHJYWHorRGJqQnEvdkNsNENtSVgrYlhmVTFrWUZJb0VQS3RjQlJUYlFQVWEwYnpJRFl3UWpqNW1iaUpDVSs1VXpqa01xZ1o2V1F1Z1dHYVA4UThsWG4xMkhvR1JIQm9oWHlRYysyb0NwZGhaRisxMEQzZzVLK1prQ1VaSERQNXZXVERSNmhLVUh3YWc3VjZXc1BxVzRZd2xsY0F3QkxIVmpPc0R4cWQ0WHlyaVhGTy9jWVpNc2ZoZzBRZUMvQjVHK3Vkem41eHdPLzJ3ZlJFWlhIamtUOGxqb2taeWhLVzlYMkZUUFltR3dTWWloNEZVdEcvR1BxOFFRVnFrTm9ZaE09PC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpTaWduYXR1cmU+PC9leHQ6RXh0ZW5zaW9uQ29udGVudD48L2V4dDpVQkxFeHRlbnNpb24+PC9leHQ6VUJMRXh0ZW5zaW9ucz48Y2JjOlVCTFZlcnNpb25JRD4yLjE8L2NiYzpVQkxWZXJzaW9uSUQ+PGNiYzpDdXN0b21pemF0aW9uSUQ+Mi4wPC9jYmM6Q3VzdG9taXphdGlvbklEPjxjYmM6SUQ+VDAwMS02NDwvY2JjOklEPjxjYmM6SXNzdWVEYXRlPjIwMjQtMDMtMTc8L2NiYzpJc3N1ZURhdGU+PGNiYzpJc3N1ZVRpbWU+MTg6MDA6MDA8L2NiYzpJc3N1ZVRpbWU+PGNiYzpEZXNwYXRjaEFkdmljZVR5cGVDb2RlIGxpc3RBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgbGlzdE5hbWU9IlRpcG8gZGUgRG9jdW1lbnRvIiBsaXN0VVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzAxIj4wOTwvY2JjOkRlc3BhdGNoQWR2aWNlVHlwZUNvZGU+PGNhYzpTaWduYXR1cmU+PGNiYzpJRD4yMDQ1MjU3ODk1NzwvY2JjOklEPjxjYWM6U2lnbmF0b3J5UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQ+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlOYW1lPjxjYmM6TmFtZT48IVtDREFUQVtUVVRPUklBTEVTIFBIUEVSVV1dPjwvY2JjOk5hbWU+PC9jYWM6UGFydHlOYW1lPjwvY2FjOlNpZ25hdG9yeVBhcnR5PjxjYWM6RGlnaXRhbFNpZ25hdHVyZUF0dGFjaG1lbnQ+PGNhYzpFeHRlcm5hbFJlZmVyZW5jZT48Y2JjOlVSST4jR1JFRU5URVItU0lHTjwvY2JjOlVSST48L2NhYzpFeHRlcm5hbFJlZmVyZW5jZT48L2NhYzpEaWdpdGFsU2lnbmF0dXJlQXR0YWNobWVudD48L2NhYzpTaWduYXR1cmU+PGNhYzpEZXNwYXRjaFN1cHBsaWVyUGFydHk+PGNhYzpQYXJ0eT48Y2FjOlBhcnR5SWRlbnRpZmljYXRpb24+PGNiYzpJRCBzY2hlbWVJRD0iNiIgc2NoZW1lTmFtZT0iRG9jdW1lbnRvIGRlIElkZW50aWRhZCIgc2NoZW1lQWdlbmN5TmFtZT0iUEU6U1VOQVQiIHNjaGVtZVVSST0idXJuOnBlOmdvYjpzdW5hdDpjcGU6c2VlOmdlbTpjYXRhbG9nb3M6Y2F0YWxvZ28wNiI+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlMZWdhbEVudGl0eT48Y2JjOlJlZ2lzdHJhdGlvbk5hbWU+PCFbQ0RBVEFbVFVUT1JJQUxFUyBQSFBFUlVdXT48L2NiYzpSZWdpc3RyYXRpb25OYW1lPjwvY2FjOlBhcnR5TGVnYWxFbnRpdHk+PC9jYWM6UGFydHk+PC9jYWM6RGVzcGF0Y2hTdXBwbGllclBhcnR5PjxjYWM6RGVsaXZlcnlDdXN0b21lclBhcnR5PjxjYWM6UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQgc2NoZW1lSUQ9IjYiIHNjaGVtZU5hbWU9IkRvY3VtZW50byBkZSBJZGVudGlkYWQiIHNjaGVtZUFnZW5jeU5hbWU9IlBFOlNVTkFUIiBzY2hlbWVVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMDYiPjIwNTUzODU2NDUxPC9jYmM6SUQ+PC9jYWM6UGFydHlJZGVudGlmaWNhdGlvbj48Y2FjOlBhcnR5TGVnYWxFbnRpdHk+PGNiYzpSZWdpc3RyYXRpb25OYW1lPjwhW0NEQVRBW0JJIEdSQU5EIENPTkZFQ0NJT05FUyBTLkEuQy5dXT48L2NiYzpSZWdpc3RyYXRpb25OYW1lPjwvY2FjOlBhcnR5TGVnYWxFbnRpdHk+PC9jYWM6UGFydHk+PC9jYWM6RGVsaXZlcnlDdXN0b21lclBhcnR5PjxjYWM6U2hpcG1lbnQ+PGNiYzpJRD5TVU5BVF9FbnZpbzwvY2JjOklEPjxjYmM6SGFuZGxpbmdDb2RlIGxpc3RBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgbGlzdE5hbWU9Ik1vdGl2byBkZSB0cmFzbGFkbyIgbGlzdFVSST0idXJuOnBlOmdvYjpzdW5hdDpjcGU6c2VlOmdlbTpjYXRhbG9nb3M6Y2F0YWxvZ28yMCI+MDE8L2NiYzpIYW5kbGluZ0NvZGU+PGNiYzpHcm9zc1dlaWdodE1lYXN1cmUgdW5pdENvZGU9IktHTSI+MjAuMDAwPC9jYmM6R3Jvc3NXZWlnaHRNZWFzdXJlPjxjYmM6VG90YWxUcmFuc3BvcnRIYW5kbGluZ1VuaXRRdWFudGl0eT41PC9jYmM6VG90YWxUcmFuc3BvcnRIYW5kbGluZ1VuaXRRdWFudGl0eT48Y2FjOlNoaXBtZW50U3RhZ2U+PGNiYzpUcmFuc3BvcnRNb2RlQ29kZSBsaXN0TmFtZT0iTW9kYWxpZGFkIGRlIHRyYXNsYWRvIiBsaXN0QWdlbmN5TmFtZT0iUEU6U1VOQVQiIGxpc3RVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMTgiPjAyPC9jYmM6VHJhbnNwb3J0TW9kZUNvZGU+PGNhYzpUcmFuc2l0UGVyaW9kPjxjYmM6U3RhcnREYXRlPjIwMjQtMDMtMTc8L2NiYzpTdGFydERhdGU+PC9jYWM6VHJhbnNpdFBlcmlvZD48Y2FjOkRyaXZlclBlcnNvbj48Y2JjOklEIHNjaGVtZUlEPSIxIiBzY2hlbWVOYW1lPSJEb2N1bWVudG8gZGUgSWRlbnRpZGFkIiBzY2hlbWVBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgc2NoZW1lVVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzA2Ij40NTI1Nzg5NTwvY2JjOklEPjxjYmM6Rmlyc3ROYW1lPkxVSVM8L2NiYzpGaXJzdE5hbWU+PGNiYzpGYW1pbHlOYW1lPkxPWkFOTzwvY2JjOkZhbWlseU5hbWU+PGNiYzpKb2JUaXRsZT5QcmluY2lwYWw8L2NiYzpKb2JUaXRsZT48Y2FjOklkZW50aXR5RG9jdW1lbnRSZWZlcmVuY2U+PGNiYzpJRD5BU0QtNTY1NDY1NDk4NDwvY2JjOklEPjwvY2FjOklkZW50aXR5RG9jdW1lbnRSZWZlcmVuY2U+PC9jYWM6RHJpdmVyUGVyc29uPjwvY2FjOlNoaXBtZW50U3RhZ2U+PGNhYzpEZWxpdmVyeT48Y2FjOkRlbGl2ZXJ5QWRkcmVzcz48Y2JjOklEIHNjaGVtZUFnZW5jeU5hbWU9IlBFOklORUkiIHNjaGVtZU5hbWU9IlViaWdlb3MiPjE0MDEwODwvY2JjOklEPjxjYWM6QWRkcmVzc0xpbmU+PGNiYzpMaW5lPmF2IGxpbWEgNDU2PC9jYmM6TGluZT48L2NhYzpBZGRyZXNzTGluZT48L2NhYzpEZWxpdmVyeUFkZHJlc3M+PGNhYzpEZXNwYXRjaD48Y2FjOkRlc3BhdGNoQWRkcmVzcz48Y2JjOklEIHNjaGVtZUFnZW5jeU5hbWU9IlBFOklORUkiIHNjaGVtZU5hbWU9IlViaWdlb3MiPjE0MDEwODwvY2JjOklEPjxjYWM6QWRkcmVzc0xpbmU+PGNiYzpMaW5lPmF2IGdyYXUgMTIzPC9jYmM6TGluZT48L2NhYzpBZGRyZXNzTGluZT48L2NhYzpEZXNwYXRjaEFkZHJlc3M+PC9jYWM6RGVzcGF0Y2g+PC9jYWM6RGVsaXZlcnk+PGNhYzpUcmFuc3BvcnRIYW5kbGluZ1VuaXQ+PGNhYzpUcmFuc3BvcnRFcXVpcG1lbnQ+PGNiYzpJRD5BU0QtNTQ1ODwvY2JjOklEPjwvY2FjOlRyYW5zcG9ydEVxdWlwbWVudD48L2NhYzpUcmFuc3BvcnRIYW5kbGluZ1VuaXQ+PC9jYWM6U2hpcG1lbnQ+PGNhYzpEZXNwYXRjaExpbmU+PGNiYzpJRD4xPC9jYmM6SUQ+PGNiYzpEZWxpdmVyZWRRdWFudGl0eSB1bml0Q29kZT0iTklVIj4xPC9jYmM6RGVsaXZlcmVkUXVhbnRpdHk+PGNhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNiYzpMaW5lSUQ+MTwvY2JjOkxpbmVJRD48L2NhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNhYzpJdGVtPjxjYmM6RGVzY3JpcHRpb24+PCFbQ0RBVEFbREVMRUlURSAxTF1dPjwvY2JjOkRlc2NyaXB0aW9uPjxjYWM6U2VsbGVyc0l0ZW1JZGVudGlmaWNhdGlvbj48Y2JjOklEPjc3NTUxMzkwMDI5MDI8L2NiYzpJRD48L2NhYzpTZWxsZXJzSXRlbUlkZW50aWZpY2F0aW9uPjwvY2FjOkl0ZW0+PC9jYWM6RGVzcGF0Y2hMaW5lPjxjYWM6RGVzcGF0Y2hMaW5lPjxjYmM6SUQ+MjwvY2JjOklEPjxjYmM6RGVsaXZlcmVkUXVhbnRpdHkgdW5pdENvZGU9Ik5JVSI+MTwvY2JjOkRlbGl2ZXJlZFF1YW50aXR5PjxjYWM6T3JkZXJMaW5lUmVmZXJlbmNlPjxjYmM6TGluZUlEPjI8L2NiYzpMaW5lSUQ+PC9jYWM6T3JkZXJMaW5lUmVmZXJlbmNlPjxjYWM6SXRlbT48Y2JjOkRlc2NyaXB0aW9uPjwhW0NEQVRBW1BBSVNBTkEgRVhUUkEgNUtdXT48L2NiYzpEZXNjcmlwdGlvbj48Y2FjOlNlbGxlcnNJdGVtSWRlbnRpZmljYXRpb24+PGNiYzpJRD43NzU1MTM5MDAyODA5PC9jYmM6SUQ+PC9jYWM6U2VsbGVyc0l0ZW1JZGVudGlmaWNhdGlvbj48L2NhYzpJdGVtPjwvY2FjOkRlc3BhdGNoTGluZT48L0Rlc3BhdGNoQWR2aWNlPgo=', NULL);
INSERT INTO `guia_remision` (`id`, `tipo_documento`, `serie`, `correlativo`, `fecha_emision`, `id_empresa`, `id_cliente`, `id_tipo_documento_rel`, `documento_rel`, `codigo_traslado`, `modalidad_traslado`, `fecha_traslado`, `peso_total`, `unidad_peso_total`, `numero_bultos`, `ubigeo_llegada`, `direccion_llegada`, `ubigeo_partida`, `direccion_partida`, `tipo_documento_transportista`, `numero_documento_transportista`, `razon_social_transportista`, `nro_mtc`, `observaciones`, `id_usuario`, `estado`, `estado_sunat`, `mensaje_error_sunat`, `xml_base64`, `xml_cdr_sunat_base64`) VALUES
(75, '09', 'T001', 65, '2024-03-18', 1, 6, '01', 'F001-654', '01', '01', '2024-03-18', 20, 'KGM', 5, '140108', 'AV LIMA 897', '140108', 'AV GRAU 123', '6', '20538995364', ' D & L TECNOLOGIA Y AUDIO S.R.L.', '', '', 14, 1, 0, '', 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPERlc3BhdGNoQWR2aWNlIHhtbG5zPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpEZXNwYXRjaEFkdmljZS0yIiB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyIgeG1sbnM6Y2FjPSJ1cm46b2FzaXM6bmFtZXM6c3BlY2lmaWNhdGlvbjp1Ymw6c2NoZW1hOnhzZDpDb21tb25BZ2dyZWdhdGVDb21wb25lbnRzLTIiIHhtbG5zOmNiYz0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uQmFzaWNDb21wb25lbnRzLTIiIHhtbG5zOmV4dD0idXJuOm9hc2lzOm5hbWVzOnNwZWNpZmljYXRpb246dWJsOnNjaGVtYTp4c2Q6Q29tbW9uRXh0ZW5zaW9uQ29tcG9uZW50cy0yIj48ZXh0OlVCTEV4dGVuc2lvbnM+PGV4dDpVQkxFeHRlbnNpb24+PGV4dDpFeHRlbnNpb25Db250ZW50PjxkczpTaWduYXR1cmUgSWQ9IkdyZWVudGVyU2lnbiI+PGRzOlNpZ25lZEluZm8+PGRzOkNhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy9UUi8yMDAxL1JFQy14bWwtYzE0bi0yMDAxMDMxNSIvPjxkczpTaWduYXR1cmVNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjcnNhLXNoYTEiLz48ZHM6UmVmZXJlbmNlIFVSST0iIj48ZHM6VHJhbnNmb3Jtcz48ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI2VudmVsb3BlZC1zaWduYXR1cmUiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8+PGRzOkRpZ2VzdFZhbHVlPk5ndTZQZEphNzc0SlZNaGxYcHh4K2o5aTUvND08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+Q2JKdkJvZVBSalRNRWV0bFZnc0dTSWFBckx4Vi9pbldLRHMwbC9KWlRwT3FnS3BWbUQzOVBXc3dob3k0alY4NUJJbWZyOU0rMnA3SFJZNWJxNHJQeGcxTTJ1NzZ0NVovNy9xc3llaUlScmI2RDVSemNSR1RxTCsycHdKMENjMS91U0xya05jQ29odHdiM2FRZXpkdlM3YjUwSnRGem1ZZXdVcm9tc3ZCUkc4ZUN6ZU5LMmIyNmpWR3VaNGdqWng2OGxyNTFqTGQ0Ym42cllGM2d0NGlIMlVHcEdKbkY5YmxJNkVvTERWY3NocmQ0TTRMM0YvZGV1SkxsN2dGUkVibVMzQXFBTURkWkFFOGpvSWcwWE1VUHhvVnRibjd6bXVlNVNXQjh3VmhMMTV6eElIOW5GcGx6NDFySUhLVnhMbENTWi96RUtXT3ZidnpkY1R4U1VWK0p3PT08L2RzOlNpZ25hdHVyZVZhbHVlPjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUZDRENDQS9DZ0F3SUJBZ0lKQU9ja2tZN2hrT3l6TUEwR0NTcUdTSWIzRFFFQkN3VUFNSUlCRFRFYk1Ca0dDZ21TSm9tVDhpeGtBUmtXQzB4TVFVMUJMbEJGSUZOQk1Rc3dDUVlEVlFRR0V3SlFSVEVOTUFzR0ExVUVDQXdFVEVsTlFURU5NQXNHQTFVRUJ3d0VURWxOUVRFWU1CWUdBMVVFQ2d3UFZGVWdSVTFRVWtWVFFTQlRMa0V1TVVVd1F3WURWUVFMRER4RVRra2dPVGs1T1RrNU9TQlNWVU1nTWpBME5USTFOemc1TlRFZ0xTQkRSVkpVU1VaSlEwRkVUeUJRUVZKQklFUkZUVTlUVkZKQlEwbkRrMDR4UkRCQ0JnTlZCQU1NTzA1UFRVSlNSU0JTUlZCU1JWTkZUbFJCVGxSRklFeEZSMEZNSUMwZ1EwVlNWRWxHU1VOQlJFOGdVRUZTUVNCRVJVMVBVMVJTUVVOSnc1Tk9NUnd3R2dZSktvWklodmNOQVFrQkZnMWtaVzF2UUd4c1lXMWhMbkJsTUI0WERUSTBNREl5T1RBeE1EYzFPVm9YRFRJMk1ESXlPREF4TURjMU9Wb3dnZ0VOTVJzd0dRWUtDWkltaVpQeUxHUUJHUllMVEV4QlRVRXVVRVVnVTBFeEN6QUpCZ05WQkFZVEFsQkZNUTB3Q3dZRFZRUUlEQVJNU1UxQk1RMHdDd1lEVlFRSERBUk1TVTFCTVJnd0ZnWURWUVFLREE5VVZTQkZUVkJTUlZOQklGTXVRUzR4UlRCREJnTlZCQXNNUEVST1NTQTVPVGs1T1RrNUlGSlZReUF5TURRMU1qVTNPRGsxTVNBdElFTkZVbFJKUmtsRFFVUlBJRkJCVWtFZ1JFVk5UMU5VVWtGRFNjT1RUakZFTUVJR0ExVUVBd3c3VGs5TlFsSkZJRkpGVUZKRlUwVk9WRUZPVkVVZ1RFVkhRVXdnTFNCRFJWSlVTVVpKUTBGRVR5QlFRVkpCSUVSRlRVOVRWRkpCUTBuRGswNHhIREFhQmdrcWhraUc5dzBCQ1FFV0RXUmxiVzlBYkd4aGJXRXVjR1V3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRRFR0SGRjQmNuZUJ2bnorM0JwejhhUGFaM2RaY05ZK29aZ3hYTlFheFpvdzBaYStwb0k2Rjk0cHlZelZyOWY3alZoMW16UFFjZ3NLU3Fpd1ZlOS9IMzBwbkM1NEpyWXVEa2pKL3hQOE5yM0E3VHJDR0RXSVFaTmR4NEhIYWFwaTZiZENuUkxrZFNBam5FWkRhV1FWeWRyRFJVODRqVktOSXVNejBmaE8rRWwxZWI3SGZlelJiTHFERDFRTjI4SkwvZWlONExJbHlKUTJvOU5iRjEySEJZb1kxb01sQ2pnZFM3TWNVNlZaNWdqYzQzL0kyTDVVemZlWDVSK1pQbEFZR2tYMXBLVTBBQmFiOWZlTHFKVUdWOGRJNDVmQTdqZzJOKzdHcjlqeXlDQkZLY3hBV1IveitGTmI3WkZYL0kzK3BkcjhVeWpzUzJRczVaaXNyZWhVdnkvQWdNQkFBR2paekJsTUIwR0ExVWREZ1FXQkJUWVNhYm85Yjc5eWxOK2wzM3BZQlRIRW1XTXBEQWZCZ05WSFNNRUdEQVdnQlRZU2FibzliNzl5bE4rbDMzcFlCVEhFbVdNcERBVEJnTlZIU1VFRERBS0JnZ3JCZ0VGQlFjREFUQU9CZ05WSFE4QkFmOEVCQU1DQjRBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFGNll4NWFKSGFOSlJkczh5MHRCOUVCWERqTTErYStQV1V2cWJGNmZ4c0Q0SjBiZ1JLQzBSZnFWcU1uZm9TMklvcTBkSEhvbUFhQVBoM05McjFJUlZVVHJYWHorRGJqQnEvdkNsNENtSVgrYlhmVTFrWUZJb0VQS3RjQlJUYlFQVWEwYnpJRFl3UWpqNW1iaUpDVSs1VXpqa01xZ1o2V1F1Z1dHYVA4UThsWG4xMkhvR1JIQm9oWHlRYysyb0NwZGhaRisxMEQzZzVLK1prQ1VaSERQNXZXVERSNmhLVUh3YWc3VjZXc1BxVzRZd2xsY0F3QkxIVmpPc0R4cWQ0WHlyaVhGTy9jWVpNc2ZoZzBRZUMvQjVHK3Vkem41eHdPLzJ3ZlJFWlhIamtUOGxqb2taeWhLVzlYMkZUUFltR3dTWWloNEZVdEcvR1BxOFFRVnFrTm9ZaE09PC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpTaWduYXR1cmU+PC9leHQ6RXh0ZW5zaW9uQ29udGVudD48L2V4dDpVQkxFeHRlbnNpb24+PC9leHQ6VUJMRXh0ZW5zaW9ucz48Y2JjOlVCTFZlcnNpb25JRD4yLjE8L2NiYzpVQkxWZXJzaW9uSUQ+PGNiYzpDdXN0b21pemF0aW9uSUQ+Mi4wPC9jYmM6Q3VzdG9taXphdGlvbklEPjxjYmM6SUQ+VDAwMS02NTwvY2JjOklEPjxjYmM6SXNzdWVEYXRlPjIwMjQtMDMtMTc8L2NiYzpJc3N1ZURhdGU+PGNiYzpJc3N1ZVRpbWU+MTg6MDA6MDA8L2NiYzpJc3N1ZVRpbWU+PGNiYzpEZXNwYXRjaEFkdmljZVR5cGVDb2RlIGxpc3RBZ2VuY3lOYW1lPSJQRTpTVU5BVCIgbGlzdE5hbWU9IlRpcG8gZGUgRG9jdW1lbnRvIiBsaXN0VVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzAxIj4wOTwvY2JjOkRlc3BhdGNoQWR2aWNlVHlwZUNvZGU+PGNhYzpTaWduYXR1cmU+PGNiYzpJRD4yMDQ1MjU3ODk1NzwvY2JjOklEPjxjYWM6U2lnbmF0b3J5UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQ+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlOYW1lPjxjYmM6TmFtZT48IVtDREFUQVtUVVRPUklBTEVTIFBIUEVSVV1dPjwvY2JjOk5hbWU+PC9jYWM6UGFydHlOYW1lPjwvY2FjOlNpZ25hdG9yeVBhcnR5PjxjYWM6RGlnaXRhbFNpZ25hdHVyZUF0dGFjaG1lbnQ+PGNhYzpFeHRlcm5hbFJlZmVyZW5jZT48Y2JjOlVSST4jR1JFRU5URVItU0lHTjwvY2JjOlVSST48L2NhYzpFeHRlcm5hbFJlZmVyZW5jZT48L2NhYzpEaWdpdGFsU2lnbmF0dXJlQXR0YWNobWVudD48L2NhYzpTaWduYXR1cmU+PGNhYzpEZXNwYXRjaFN1cHBsaWVyUGFydHk+PGNhYzpQYXJ0eT48Y2FjOlBhcnR5SWRlbnRpZmljYXRpb24+PGNiYzpJRCBzY2hlbWVJRD0iNiIgc2NoZW1lTmFtZT0iRG9jdW1lbnRvIGRlIElkZW50aWRhZCIgc2NoZW1lQWdlbmN5TmFtZT0iUEU6U1VOQVQiIHNjaGVtZVVSST0idXJuOnBlOmdvYjpzdW5hdDpjcGU6c2VlOmdlbTpjYXRhbG9nb3M6Y2F0YWxvZ28wNiI+MjA0NTI1Nzg5NTc8L2NiYzpJRD48L2NhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYWM6UGFydHlMZWdhbEVudGl0eT48Y2JjOlJlZ2lzdHJhdGlvbk5hbWU+PCFbQ0RBVEFbVFVUT1JJQUxFUyBQSFBFUlVdXT48L2NiYzpSZWdpc3RyYXRpb25OYW1lPjwvY2FjOlBhcnR5TGVnYWxFbnRpdHk+PC9jYWM6UGFydHk+PC9jYWM6RGVzcGF0Y2hTdXBwbGllclBhcnR5PjxjYWM6RGVsaXZlcnlDdXN0b21lclBhcnR5PjxjYWM6UGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQgc2NoZW1lSUQ9IjEiIHNjaGVtZU5hbWU9IkRvY3VtZW50byBkZSBJZGVudGlkYWQiIHNjaGVtZUFnZW5jeU5hbWU9IlBFOlNVTkFUIiBzY2hlbWVVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMDYiPjQ1MjU3ODk1PC9jYmM6SUQ+PC9jYWM6UGFydHlJZGVudGlmaWNhdGlvbj48Y2FjOlBhcnR5TGVnYWxFbnRpdHk+PGNiYzpSZWdpc3RyYXRpb25OYW1lPjwhW0NEQVRBW0xVSVMgQU5HRUwgTE9aQU5PIEFSSUNBXV0+PC9jYmM6UmVnaXN0cmF0aW9uTmFtZT48L2NhYzpQYXJ0eUxlZ2FsRW50aXR5PjwvY2FjOlBhcnR5PjwvY2FjOkRlbGl2ZXJ5Q3VzdG9tZXJQYXJ0eT48Y2FjOlNoaXBtZW50PjxjYmM6SUQ+U1VOQVRfRW52aW88L2NiYzpJRD48Y2JjOkhhbmRsaW5nQ29kZSBsaXN0QWdlbmN5TmFtZT0iUEU6U1VOQVQiIGxpc3ROYW1lPSJNb3Rpdm8gZGUgdHJhc2xhZG8iIGxpc3RVUkk9InVybjpwZTpnb2I6c3VuYXQ6Y3BlOnNlZTpnZW06Y2F0YWxvZ29zOmNhdGFsb2dvMjAiPjAxPC9jYmM6SGFuZGxpbmdDb2RlPjxjYmM6R3Jvc3NXZWlnaHRNZWFzdXJlIHVuaXRDb2RlPSJLR00iPjIwLjAwMDwvY2JjOkdyb3NzV2VpZ2h0TWVhc3VyZT48Y2JjOlRvdGFsVHJhbnNwb3J0SGFuZGxpbmdVbml0UXVhbnRpdHk+NTwvY2JjOlRvdGFsVHJhbnNwb3J0SGFuZGxpbmdVbml0UXVhbnRpdHk+PGNhYzpTaGlwbWVudFN0YWdlPjxjYmM6VHJhbnNwb3J0TW9kZUNvZGUgbGlzdE5hbWU9Ik1vZGFsaWRhZCBkZSB0cmFzbGFkbyIgbGlzdEFnZW5jeU5hbWU9IlBFOlNVTkFUIiBsaXN0VVJJPSJ1cm46cGU6Z29iOnN1bmF0OmNwZTpzZWU6Z2VtOmNhdGFsb2dvczpjYXRhbG9nbzE4Ij4wMTwvY2JjOlRyYW5zcG9ydE1vZGVDb2RlPjxjYWM6VHJhbnNpdFBlcmlvZD48Y2JjOlN0YXJ0RGF0ZT4yMDI0LTAzLTE3PC9jYmM6U3RhcnREYXRlPjwvY2FjOlRyYW5zaXRQZXJpb2Q+PGNhYzpDYXJyaWVyUGFydHk+PGNhYzpQYXJ0eUlkZW50aWZpY2F0aW9uPjxjYmM6SUQgc2NoZW1lSUQ9IjYiPjIwNTM4OTk1MzY0PC9jYmM6SUQ+PC9jYWM6UGFydHlJZGVudGlmaWNhdGlvbj48Y2FjOlBhcnR5TGVnYWxFbnRpdHk+PGNiYzpSZWdpc3RyYXRpb25OYW1lPjwhW0NEQVRBWyBEICYgTCBURUNOT0xPR0lBIFkgQVVESU8gUy5SLkwuXV0+PC9jYmM6UmVnaXN0cmF0aW9uTmFtZT48Y2JjOkNvbXBhbnlJRC8+PC9jYWM6UGFydHlMZWdhbEVudGl0eT48L2NhYzpDYXJyaWVyUGFydHk+PC9jYWM6U2hpcG1lbnRTdGFnZT48Y2FjOkRlbGl2ZXJ5PjxjYWM6RGVsaXZlcnlBZGRyZXNzPjxjYmM6SUQgc2NoZW1lQWdlbmN5TmFtZT0iUEU6SU5FSSIgc2NoZW1lTmFtZT0iVWJpZ2VvcyI+MTQwMTA4PC9jYmM6SUQ+PGNhYzpBZGRyZXNzTGluZT48Y2JjOkxpbmU+YXYgbGltYSA4OTc8L2NiYzpMaW5lPjwvY2FjOkFkZHJlc3NMaW5lPjwvY2FjOkRlbGl2ZXJ5QWRkcmVzcz48Y2FjOkRlc3BhdGNoPjxjYWM6RGVzcGF0Y2hBZGRyZXNzPjxjYmM6SUQgc2NoZW1lQWdlbmN5TmFtZT0iUEU6SU5FSSIgc2NoZW1lTmFtZT0iVWJpZ2VvcyI+MTQwMTA4PC9jYmM6SUQ+PGNhYzpBZGRyZXNzTGluZT48Y2JjOkxpbmU+YXYgZ3JhdSAxMjM8L2NiYzpMaW5lPjwvY2FjOkFkZHJlc3NMaW5lPjwvY2FjOkRlc3BhdGNoQWRkcmVzcz48L2NhYzpEZXNwYXRjaD48L2NhYzpEZWxpdmVyeT48L2NhYzpTaGlwbWVudD48Y2FjOkRlc3BhdGNoTGluZT48Y2JjOklEPjE8L2NiYzpJRD48Y2JjOkRlbGl2ZXJlZFF1YW50aXR5IHVuaXRDb2RlPSJOSVUiPjE8L2NiYzpEZWxpdmVyZWRRdWFudGl0eT48Y2FjOk9yZGVyTGluZVJlZmVyZW5jZT48Y2JjOkxpbmVJRD4xPC9jYmM6TGluZUlEPjwvY2FjOk9yZGVyTGluZVJlZmVyZW5jZT48Y2FjOkl0ZW0+PGNiYzpEZXNjcmlwdGlvbj48IVtDREFUQVtERUxFSVRFIDFMXV0+PC9jYmM6RGVzY3JpcHRpb24+PGNhYzpTZWxsZXJzSXRlbUlkZW50aWZpY2F0aW9uPjxjYmM6SUQ+Nzc1NTEzOTAwMjkwMjwvY2JjOklEPjwvY2FjOlNlbGxlcnNJdGVtSWRlbnRpZmljYXRpb24+PC9jYWM6SXRlbT48L2NhYzpEZXNwYXRjaExpbmU+PGNhYzpEZXNwYXRjaExpbmU+PGNiYzpJRD4yPC9jYmM6SUQ+PGNiYzpEZWxpdmVyZWRRdWFudGl0eSB1bml0Q29kZT0iTklVIj4xPC9jYmM6RGVsaXZlcmVkUXVhbnRpdHk+PGNhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNiYzpMaW5lSUQ+MjwvY2JjOkxpbmVJRD48L2NhYzpPcmRlckxpbmVSZWZlcmVuY2U+PGNhYzpJdGVtPjxjYmM6RGVzY3JpcHRpb24+PCFbQ0RBVEFbUEFJU0FOQSBFWFRSQSA1S11dPjwvY2JjOkRlc2NyaXB0aW9uPjxjYWM6U2VsbGVyc0l0ZW1JZGVudGlmaWNhdGlvbj48Y2JjOklEPjc3NTUxMzkwMDI4MDk8L2NiYzpJRD48L2NhYzpTZWxsZXJzSXRlbUlkZW50aWZpY2F0aW9uPjwvY2FjOkl0ZW0+PC9jYWM6RGVzcGF0Y2hMaW5lPjwvRGVzcGF0Y2hBZHZpY2U+Cg==', NULL),
(76, '31', 'V001', 1, '2024-03-20', 1, 6, '01', 'F001-1235', '', '', '2024-03-20', 20, 'KGM', 5, '140108', 'Av Lima 345', '140108', 'av grau 123', NULL, NULL, NULL, '', '', 14, 1, NULL, NULL, NULL, NULL),
(77, '31', 'V001', 1, '2024-03-20', 1, 6, '01', 'F001-1235', '', '', '2024-03-20', 20, 'KGM', 5, '140108', 'Av Lima 345', '140108', 'av grau 123', NULL, NULL, NULL, '', '', 14, 1, NULL, NULL, NULL, NULL),
(78, '31', 'V001', 1, '2024-03-20', 1, 6, '01', 'F001-1235', '', '', '2024-03-20', 20, 'KGM', 5, '140108', 'Av Lima 345', '140108', 'av grau 123', NULL, NULL, NULL, '', '', 14, 1, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `guia_remision_choferes`
--

CREATE TABLE `guia_remision_choferes` (
  `id` int(11) NOT NULL,
  `id_guia_remision` int(11) NOT NULL,
  `tipo_documento` varchar(5) NOT NULL,
  `numero_documento` varchar(20) NOT NULL,
  `licencia` varchar(30) NOT NULL,
  `nombres` varchar(100) NOT NULL,
  `apellidos` varchar(100) NOT NULL,
  `tipo_chofer` varchar(45) NOT NULL COMMENT 'PRINCIPAL\nSECUNDARIO',
  `estado` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `guia_remision_choferes`
--

INSERT INTO `guia_remision_choferes` (`id`, `id_guia_remision`, `tipo_documento`, `numero_documento`, `licencia`, `nombres`, `apellidos`, `tipo_chofer`, `estado`) VALUES
(1, 40, '1', '45257895', 'Q987654321', 'LUIS ANGEL', 'LOZANO ARICA', 'PRINCIPAL', 1),
(2, 40, '1', '42584136', 'A123456789', 'FIORELLA JESSICA', 'OSORES VALLEJO', 'SECUNDARIO', 1),
(3, 40, '1', '45124578', 'C123456789', 'SHIRLEY NALDI', 'CARI LAZARTE', 'SECUNDARIO', 1),
(4, 41, '1', '45257895', 'Q987654321', 'LUIS ANGEL', 'LOZANO ARICA', 'PRINCIPAL', 1),
(5, 41, '1', '42584136', 'A123456789', 'FIORELLA JESSICA', 'OSORES VALLEJO', 'SECUNDARIO', 1),
(6, 41, '1', '45124578', 'C123456789', 'SHIRLEY NALDI', 'CARI LAZARTE', 'SECUNDARIO', 1),
(7, 42, '1', '45257895', 'Q98765431', 'LUIS ANGEL', 'LOZANO ARICA', 'PRINCIPAL', 1),
(8, 42, '1', '42584136', 'A456789123', 'FIORELLA JESSICA', 'OSORES VALLEJO', 'SECUNDARIO', 1),
(9, 44, '1', '45257895', 'A789456123', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(10, 44, '1', '42587458', 'Z456456456', 'FIORELLA', 'OSORES', 'SECUNDARIO', 1),
(11, 45, '1', '45257895', 'A123456789', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(12, 45, '1', '42584136', 'A45612378', 'FIORELLA', 'OSORES', 'SECUNDARIO', 1),
(13, 46, '1', '45257895', 'Q12345678', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(14, 46, '1', '42784512', 'A123456789', 'FIORELLA', 'OSORES', 'SECUNDARIO', 1),
(15, 47, '1', '45257895', 'A123456789', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(16, 47, '1', '45784512', 'E789456123', 'RAFAEL', 'LOZANO', 'SECUNDARIO', 1),
(17, 52, '1', '45257895', 'A456123456', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(18, 52, '1', '42457845', 'Q789456123', 'RAFAEL', 'LOZANO', 'SECUNDARIO', 1),
(19, 53, '1', '45257895', 'A456123456', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(20, 53, '1', '42457845', 'Q789456123', 'RAFAEL', 'LOZANO', 'SECUNDARIO', 1),
(21, 54, '1', '45257895', 'A456123456', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(22, 54, '1', '42457845', 'Q789456123', 'RAFAEL', 'LOZANO', 'SECUNDARIO', 1),
(23, 68, '1', '45257895', 'ASD-5654654984', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(24, 69, '1', '45257895', 'ASD-5654654984', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(25, 70, '1', '45257895', 'ASD-5654654984', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(26, 71, '1', '45257895', 'ASD-5654654984', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(27, 72, '1', '45257895', 'ASD-5654654984', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(28, 73, '1', '45257895', 'ASD-5654654984', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(29, 74, '1', '45257895', 'ASD-5654654984', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(30, 76, '1', '45257895', 'A789456123', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(31, 77, '1', '45257895', 'A789456123', 'LUIS', 'LOZANO', 'PRINCIPAL', 1),
(32, 78, '1', '45257895', 'A789456123', 'LUIS', 'LOZANO', 'PRINCIPAL', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `guia_remision_productos`
--

CREATE TABLE `guia_remision_productos` (
  `id` int(11) NOT NULL,
  `id_guia_remision` int(11) NOT NULL,
  `codigo_producto` varchar(50) NOT NULL,
  `descripcion_producto` varchar(150) NOT NULL,
  `unidad` varchar(10) NOT NULL,
  `cantidad` float NOT NULL,
  `estado` int(11) GENERATED ALWAYS AS (1) VIRTUAL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `guia_remision_productos`
--

INSERT INTO `guia_remision_productos` (`id`, `id_guia_remision`, `codigo_producto`, `descripcion_producto`, `unidad`, `cantidad`) VALUES
(3, 8, '7755139002869', 'CANCHITA MANTEQUILLA', 'NIU', 1),
(4, 8, '7755139002874', 'PRINGLES PAPAS', 'NIU', 1),
(5, 8, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(6, 8, '7755139002830', 'BIG COLA 400ML', 'NIU', 1),
(7, 9, '7755139002874', 'PRINGLES PAPAS', 'NIU', 20),
(8, 9, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 30),
(9, 9, '7755139002830', 'BIG COLA 400ML', 'NIU', 40),
(10, 10, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(11, 10, '7755139002811', 'GLORIA EVAPORADA LIG...', 'NIU', 1),
(12, 10, '7755139002830', 'BIG COLA 400ML', 'NIU', 1),
(13, 11, '7755139002830', 'BIG COLA 400ML', 'NIU', 1),
(14, 12, '7755139002830', 'BIG COLA 400ML', 'NIU', 1),
(15, 13, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(16, 13, '7755139002811', 'GLORIA EVAPORADA LIG...', 'NIU', 1),
(17, 13, '7755139002830', 'BIG COLA 400ML', 'NIU', 1),
(18, 14, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(19, 14, '7755139002830', 'BIG COLA 400ML', 'NIU', 1),
(20, 15, '7755139002849', 'SEVEN UP 500ML', 'NIU', 1),
(21, 15, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 2),
(22, 16, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(23, 16, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(24, 17, '7755139002872', 'VALLE NORTE 750G', 'NIU', 1),
(25, 17, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(26, 18, '7755139002902', 'DELEITE 1L', 'NIU', 35),
(27, 18, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 20),
(28, 19, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 20),
(29, 19, '7755139002830', 'BIG COLA 400ML', 'NIU', 30),
(30, 20, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(31, 20, '7755139002830', 'BIG COLA 400ML', 'NIU', 1),
(32, 21, '7755139002874', 'PRINGLES PAPAS', 'NIU', 1),
(33, 21, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(34, 22, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(35, 23, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(36, 24, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(37, 25, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(38, 26, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(39, 27, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 20),
(40, 27, '7755139002811', 'GLORIA EVAPORADA LIG...', 'NIU', 30),
(41, 27, '7755139002830', 'BIG COLA 400ML', 'NIU', 40),
(42, 28, '7755139002869', 'CANCHITA MANTEQUILLA', 'NIU', 30),
(43, 28, '7755139002830', 'BIG COLA 400ML', 'NIU', 20),
(44, 29, '7755139002869', 'CANCHITA MANTEQUILLA', 'NIU', 30),
(45, 29, '7755139002830', 'BIG COLA 400ML', 'NIU', 20),
(46, 30, '7755139002869', 'CANCHITA MANTEQUILLA', 'NIU', 30),
(47, 30, '7755139002830', 'BIG COLA 400ML', 'NIU', 20),
(48, 31, '7755139002874', 'PRINGLES PAPAS', 'NIU', 20),
(49, 31, '7755139002830', 'BIG COLA 400ML', 'NIU', 10),
(50, 32, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 10),
(51, 33, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 15),
(52, 34, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 15),
(53, 35, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 10),
(54, 36, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 10),
(55, 37, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 15),
(56, 38, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 15),
(57, 39, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 15),
(58, 40, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 15),
(59, 41, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 15),
(60, 42, '7755139002839', 'PULP DURAZNO 315ML', 'NIU', 1),
(61, 42, '7755139002869', 'CANCHITA MANTEQUILLA', 'NIU', 2),
(62, 42, '7755139002811', 'GLORIA EVAPORADA LIG...', 'NIU', 1),
(63, 42, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 1),
(64, 42, '7755139002830', 'BIG COLA 400ML', 'NIU', 2),
(65, 43, '7755139002811', 'GLORIA EVAPORADA LIG...', 'NIU', 1),
(66, 43, '7755139002830', 'BIG COLA 400ML', 'NIU', 1),
(67, 43, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(68, 44, '7755139002830', 'BIG COLA 400ML', 'NIU', 5),
(69, 44, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 6),
(70, 45, '7755139002811', 'GLORIA EVAPORADA LIG...', 'NIU', 10),
(71, 45, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 20),
(72, 45, '7755139002830', 'BIG COLA 400ML', 'NIU', 30),
(73, 46, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(74, 46, '7755139002830', 'BIG COLA 400ML', 'NIU', 1),
(75, 47, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 10),
(76, 47, '7755139002830', 'BIG COLA 400ML', 'NIU', 20),
(77, 48, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 10),
(78, 48, '7755139002830', 'BIG COLA 400ML', 'NIU', 20),
(79, 49, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 1),
(80, 50, '7755139002830', 'BIG COLA 400ML', 'NIU', 10),
(81, 50, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 20),
(82, 51, '7755139002855', 'COCA COLA 600ML', 'NIU', 20),
(83, 51, '7755139002830', 'BIG COLA 400ML', 'NIU', 20),
(84, 52, '7755139002855', 'COCA COLA 600ML', 'NIU', 1),
(85, 52, '7755139002874', 'PRINGLES PAPAS', 'NIU', 1),
(86, 52, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 1),
(87, 53, '7755139002855', 'COCA COLA 600ML', 'NIU', 1),
(88, 53, '7755139002874', 'PRINGLES PAPAS', 'NIU', 1),
(89, 53, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 1),
(90, 54, '7755139002855', 'COCA COLA 600ML', 'NIU', 1),
(91, 54, '7755139002874', 'PRINGLES PAPAS', 'NIU', 1),
(92, 54, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 1),
(93, 55, '7755139002811', 'GLORIA EVAPORADA LIG...', 'NIU', 1),
(94, 55, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(95, 56, '7755139002855', 'COCA COLA 600ML', 'NIU', 20),
(96, 56, '7755139002830', 'BIG COLA 400ML', 'NIU', 30),
(97, 57, '7755139002830', 'BIG COLA 400ML', 'NIU', 1),
(98, 57, '7755139002855', 'COCA COLA 600ML', 'NIU', 1),
(99, 58, '7755139002830', 'BIG COLA 400ML', 'NIU', 1),
(100, 58, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(101, 59, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 1),
(102, 59, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(103, 60, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 1),
(104, 60, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(105, 61, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 1),
(106, 61, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(107, 62, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 1),
(108, 62, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(109, 63, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 1),
(110, 63, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(111, 64, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 1),
(112, 64, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(113, 65, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 1),
(114, 65, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(115, 66, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 1),
(116, 66, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(117, 67, '7755139002851', 'FANTA NARANJA 500ML', 'NIU', 1),
(118, 67, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(119, 68, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(120, 68, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(121, 69, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(122, 69, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(123, 70, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(124, 70, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(125, 71, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(126, 71, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(127, 72, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(128, 72, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(129, 73, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(130, 73, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(131, 74, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(132, 74, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(133, 75, '7755139002902', 'DELEITE 1L', 'NIU', 1),
(134, 75, '7755139002809', 'PAISANA EXTRA 5K', 'NIU', 1),
(135, 76, '7755139002830', 'BIG COLA 400ML', 'NIU', 1),
(136, 77, '7755139002830', 'BIG COLA 400ML', 'NIU', 1),
(137, 78, '7755139002830', 'BIG COLA 400ML', 'NIU', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `guia_remision_vehiculos`
--

CREATE TABLE `guia_remision_vehiculos` (
  `id` int(11) NOT NULL,
  `id_guia_remision` int(11) NOT NULL,
  `placa` varchar(15) NOT NULL,
  `tipo_vehiculo` varchar(45) NOT NULL COMMENT 'PRINCIPAL\nSECUNDARIO',
  `estado` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `guia_remision_vehiculos`
--

INSERT INTO `guia_remision_vehiculos` (`id`, `id_guia_remision`, `placa`, `tipo_vehiculo`, `estado`) VALUES
(1, 40, 'ASD123', 'PRINCIPAL', 1),
(2, 40, 'ABC123', 'SECUNDARIO', 1),
(3, 40, 'ERT123', 'SECUNDARIO', 1),
(4, 41, 'ASD123', 'PRINCIPAL', 1),
(5, 41, 'ABC123', 'SECUNDARIO', 1),
(6, 41, 'ERT123', 'SECUNDARIO', 1),
(7, 42, 'ASD123', 'PRINCIPAL', 1),
(8, 42, 'ABC123', 'SECUNDARIO', 1),
(9, 44, 'ASD456', 'PRINCIPAL', 1),
(10, 44, 'ABC123', 'SECUNDARIO', 1),
(11, 45, 'ABC123', 'PRINCIPAL', 1),
(12, 45, 'ABC789', 'SECUNDARIO', 1),
(13, 46, 'ABC123', 'PRINCIPAL', 1),
(14, 46, 'QWE123', 'SECUNDARIO', 1),
(15, 47, 'ABC123', 'PRINCIPAL', 1),
(16, 47, 'ADF123', 'SECUNDARIO', 1),
(17, 52, 'ASD123', 'PRINCIPAL', 1),
(18, 52, 'ABC123', 'SECUNDARIO', 1),
(19, 53, 'ASD123', 'PRINCIPAL', 1),
(20, 53, 'ABC123', 'SECUNDARIO', 1),
(21, 54, 'ASD123', 'PRINCIPAL', 1),
(22, 54, 'ABC123', 'SECUNDARIO', 1),
(23, 68, 'ASD-5458', 'PRINCIPAL', 1),
(24, 69, 'ASD-5458', 'PRINCIPAL', 1),
(25, 70, 'ASD-5458', 'PRINCIPAL', 1),
(26, 71, 'ASD-5458', 'PRINCIPAL', 1),
(27, 72, 'ASD-5458', 'PRINCIPAL', 1),
(28, 73, 'ASD-5458', 'PRINCIPAL', 1),
(29, 74, 'ASD-5458', 'PRINCIPAL', 1),
(30, 76, 'ABC123', 'PRINCIPAL', 1),
(31, 77, 'ABC123', 'PRINCIPAL', 1),
(32, 78, 'ABC123', 'PRINCIPAL', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `historico_cargas_masivas`
--

CREATE TABLE `historico_cargas_masivas` (
  `id` int(11) NOT NULL,
  `categorias_insertadas` int(11) DEFAULT NULL,
  `categorias_excel` int(11) DEFAULT NULL,
  `productos_insertados` int(11) DEFAULT NULL,
  `productos_excel` int(11) DEFAULT NULL,
  `unidades_medida_insertadas` int(11) DEFAULT NULL,
  `unidades_medida_excel` varchar(45) DEFAULT NULL,
  `fecha_carga` datetime DEFAULT current_timestamp(),
  `estado_carga` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `historico_cargas_masivas`
--

INSERT INTO `historico_cargas_masivas` (`id`, `categorias_insertadas`, `categorias_excel`, `productos_insertados`, `productos_excel`, `unidades_medida_insertadas`, `unidades_medida_excel`, `fecha_carga`, `estado_carga`) VALUES
(1, 19, 19, 96, 96, 8, '8', '2024-08-30 10:27:41', 1),
(2, 19, 19, 7, 7, 8, '8', '2024-08-31 11:44:56', 1),
(3, 19, 19, 7, 7, 8, '8', '2024-08-31 11:45:44', 1),
(4, 19, 19, 7, 7, 8, '8', '2024-08-31 11:47:15', 1),
(5, 19, 19, 7, 7, 8, '8', '2024-08-31 11:48:10', 1),
(6, 19, 19, 7, 7, 8, '8', '2024-08-31 11:56:30', 1),
(7, 5, 5, 7, 7, 8, '8', '2024-08-31 12:20:16', 1),
(8, 5, 5, 7, 7, 8, '8', '2024-08-31 12:21:47', 1),
(9, 2, 2, NULL, 437, NULL, '13', '2024-12-18 11:19:54', 0),
(10, 2, 2, 34, 437, 12, '12', '2024-12-18 11:20:13', 0),
(11, 2, 2, 34, 34, 12, '12', '2024-12-18 11:21:01', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `impuestos`
--

CREATE TABLE `impuestos` (
  `id_tipo_operacion` int(11) NOT NULL,
  `impuesto` float DEFAULT NULL,
  `estado` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `impuestos`
--

INSERT INTO `impuestos` (`id_tipo_operacion`, `impuesto`, `estado`) VALUES
(10, 18, 1),
(20, 0, 1),
(30, 0, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `kardex`
--

CREATE TABLE `kardex` (
  `id` int(11) NOT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `fecha` datetime DEFAULT NULL,
  `concepto` varchar(100) DEFAULT NULL,
  `comprobante` varchar(50) DEFAULT NULL,
  `in_unidades` float DEFAULT NULL,
  `in_costo_unitario` float DEFAULT NULL,
  `in_costo_total` float DEFAULT NULL,
  `out_unidades` float DEFAULT NULL,
  `out_costo_unitario` float DEFAULT NULL,
  `out_costo_total` float DEFAULT NULL,
  `ex_unidades` float DEFAULT NULL,
  `ex_costo_unitario` float DEFAULT NULL,
  `ex_costo_total` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `medio_pago`
--

CREATE TABLE `medio_pago` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(150) DEFAULT NULL,
  `id_tipo_movimiento_caja` int(11) DEFAULT NULL,
  `fecha_registro` datetime DEFAULT current_timestamp(),
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `medio_pago`
--

INSERT INTO `medio_pago` (`id`, `descripcion`, `id_tipo_movimiento_caja`, `fecha_registro`, `estado`) VALUES
(1, 'EFECTIVO', 3, '2024-03-18', 1),
(2, 'YAPE', 6, '2024-03-18', 1),
(3, 'PLIN', 7, '2024-03-18', 1),
(4, 'TRANSFERENCIA', 8, '2024-03-18', 1),
(5, 'CANJE', 9, '2024-03-18', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `modalidad_traslado`
--

CREATE TABLE `modalidad_traslado` (
  `id` int(11) NOT NULL,
  `codigo` varchar(10) NOT NULL,
  `descripcion` varchar(45) NOT NULL,
  `estado` int(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `modalidad_traslado`
--

INSERT INTO `modalidad_traslado` (`id`, `codigo`, `descripcion`, `estado`) VALUES
(1, '01', 'TRASNPORTE PÚBLICO', 1),
(2, '02', 'TRANSPORTE PRIVADO', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `modulos`
--

CREATE TABLE `modulos` (
  `id` int(11) NOT NULL,
  `modulo` varchar(150) DEFAULT NULL,
  `padre_id` int(11) DEFAULT NULL,
  `vista` varchar(150) DEFAULT NULL,
  `icon_menu` varchar(150) DEFAULT NULL,
  `orden` int(11) DEFAULT NULL,
  `fecha_creacion` timestamp NULL DEFAULT NULL,
  `fecha_actualizacion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `modulos`
--

INSERT INTO `modulos` (`id`, `modulo`, `padre_id`, `vista`, `icon_menu`, `orden`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(1, 'Tablero Principal', 0, 'dashboard/dashboard.php', 'fas fa-tachometer-alt', 0, NULL, NULL),
(2, 'Punto de Venta', 0, '', 'fas fa-store', 5, NULL, NULL),
(5, 'Productos', 0, NULL, 'fas fa-cart-plus', 1, NULL, NULL),
(6, 'Inventario', 5, 'inventario/productos/productos.php', 'fas fa-check-circle', 2, NULL, NULL),
(7, 'Carga Masiva', 5, 'inventario/carga_masiva_productos.php', 'fas fa-check-circle', 4, NULL, NULL),
(8, 'Categorías', 5, 'inventario/categorias.php', 'fas fa-check-circle', 3, NULL, NULL),
(9, 'Compras', 0, 'compras/compras.php', 'fas fa-dolly', 21, NULL, NULL),
(10, 'Reportes', 0, '', 'fas fa-chart-pie', 22, NULL, NULL),
(11, 'Administración', 0, NULL, 'fas fa-users-cog', 28, NULL, NULL),
(13, 'Módulos / Perfiles', 31, 'seguridad/seguridad_modulos_perfiles.php', 'fas fa-check-circle', 39, NULL, NULL),
(15, 'Caja', 0, 'caja/caja.php', 'fas fa-cash-register', 18, '2022-12-05 14:44:08', NULL),
(22, 'Tipo Afectación', 11, 'administracion/administrar_tipo_afectacion.php', 'fas fa-check-circle', 34, '2023-09-22 05:46:29', NULL),
(23, 'Tipo Comprobante', 11, 'administracion/administrar_tipo_comprobante.php', 'fas fa-check-circle', 33, '2023-09-22 05:50:12', NULL),
(24, 'Series', 11, 'administracion/administrar_series.php', 'fas fa-check-circle', 35, '2023-09-22 06:15:56', NULL),
(25, 'Clientes', 11, 'administracion/administrar_clientes.php', 'fas fa-check-circle', 30, '2023-09-22 06:19:20', NULL),
(26, 'Proveedores', 11, 'administracion/administrar_proveedores.php', 'fas fa-check-circle', 31, '2023-09-22 06:19:31', NULL),
(27, 'Empresa', 11, 'administracion/administrar_empresas.php', 'fas fa-check-circle', 29, '2023-09-22 06:20:56', NULL),
(28, 'Emitir Boleta', 2, 'ventas/venta_boleta.php', 'fas fa-check-circle', 6, '2023-09-26 15:46:51', NULL),
(29, 'Emitir Factura', 2, 'ventas/venta_factura.php', 'fas fa-check-circle', 7, '2023-09-26 15:47:09', NULL),
(30, 'Resumen de Boletas', 2, 'ventas/venta_resumen_boletas.php', 'fas fa-check-circle', 9, '2023-09-26 15:47:39', NULL),
(31, 'Seguridad', 0, '', 'fas fa-user-shield', 36, '2023-09-26 21:03:11', NULL),
(33, 'Perfiles', 31, 'seguridad/perfiles/seguridad_perfiles.php', 'fas fa-check-circle', 37, '2023-09-26 21:04:53', NULL),
(34, 'Usuarios', 31, 'seguridad/seguridad_usuarios.php', 'fas fa-check-circle', 38, '2023-09-26 21:05:08', NULL),
(37, 'Tipo Documento', 11, 'administracion/administrar_tipo_documento.php', 'fas fa-check-circle', 32, '2023-09-30 04:07:02', NULL),
(38, 'Kardex Totalizado', 10, 'reportes/reporte_kardex_totalizado.php', 'fas fa-check-circle', 24, '2023-09-30 04:07:02', NULL),
(39, 'Ventas x Categoría', 10, 'reportes/reporte_ventas.php', 'fas fa-check-circle', 26, '2023-09-30 04:07:02', NULL),
(40, 'Ventas x Producto', 10, 'reportes/reporte_ventas_producto.php', 'fas fa-check-circle', 27, '2023-09-30 04:07:02', NULL),
(41, 'Nota de Crédito', 2, 'ventas/venta_nota_credito.php', 'fas fa-check-circle', 10, NULL, NULL),
(42, 'Kardex x Producto', 10, 'reportes/reporte_kardex_por_producto.php', 'fas fa-check-circle', 25, NULL, NULL),
(43, 'Cuentas x Cobrar', 0, 'ventas/cuentas_x_cobrar.php', 'far fa-credit-card', 19, '2023-11-02 00:25:12', '2023-11-01 20:25:12'),
(44, 'Nota de Débito', 2, 'ventas/venta_nota_debito.php', 'fas fa-check-circle', 11, NULL, NULL),
(45, 'Comprob. Elect.', 0, 'ventas/listado_comprobantes_electronicos.php', 'fas fa-file-invoice-dollar', 17, NULL, NULL),
(46, 'Nota de Venta', 2, 'ventas/venta_nota_venta.php', 'fas fa-check-circle', 8, NULL, NULL),
(47, 'Configuraciones', 0, 'configuraciones/configuraciones.php', 'fas fa-tools', 40, NULL, NULL),
(48, 'Cotizaciones', 2, 'ventas/cotizaciones/venta_cotizacion.php', 'fas fa-check-circle', 12, NULL, NULL),
(49, 'Cuentas x Pagar', 0, 'compras/cuentas_x_pagar.php', 'fas fa-hand-holding-usd', 20, NULL, NULL),
(50, 'Registro de Ventas', 10, 'reportes/reporte_registro_ventas.php', 'fas fa-check-circle', 23, NULL, NULL),
(51, 'Venta POS', 0, 'ventas/venta_pos.php', 'fas fa-shopping-bag', 13, NULL, NULL),
(52, 'Guia Remisión', 0, '', 'fas fa-shuttle-van', 14, NULL, NULL),
(53, 'GR Remitente', 52, 'ventas/venta_guia_remision_remitente.php', 'fas fa-check-circle', 15, NULL, NULL),
(55, 'Ver Guias', 52, 'ventas/venta_listado_guias_remision.php', 'fas fa-check-circle', 100, NULL, NULL),
(56, 'Cuadres de Caja', 10, 'reportes/cuadre_caja.php', 'fas fa-check-circle', 0, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `moneda`
--

CREATE TABLE `moneda` (
  `id` char(3) NOT NULL,
  `descripcion` varchar(45) NOT NULL,
  `simbolo` char(5) DEFAULT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `moneda`
--

INSERT INTO `moneda` (`id`, `descripcion`, `simbolo`, `estado`) VALUES
('PEN', 'SOLES', 'S/', 1),
('USD', 'DOLARES', '$', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `motivos_notas`
--

CREATE TABLE `motivos_notas` (
  `id` int(11) NOT NULL,
  `tipo` varchar(45) DEFAULT NULL,
  `codigo` varchar(45) DEFAULT NULL,
  `descripcion` varchar(45) DEFAULT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `motivos_notas`
--

INSERT INTO `motivos_notas` (`id`, `tipo`, `codigo`, `descripcion`, `estado`) VALUES
(1, 'C', '01', 'Anulación de la operación', 1),
(2, 'C', '02', 'Anulación por error en el RUC', 1),
(3, 'C', '03', 'Corrección por error en la descripción', 0),
(4, 'C', '04', 'Descuento global', 1),
(5, 'C', '05', 'Descuento por ítem', 1),
(6, 'C', '06', 'Devolución total', 1),
(7, 'C', '07', 'Devolución por ítem', 1),
(8, 'C', '08', 'Bonificación', 0),
(9, 'C', '09', 'Disminución en el valor', 0),
(10, 'C', '10', 'Otros Conceptos', 0),
(11, 'C', '11', 'Ajustes de operaciones de exportación', 0),
(12, 'C', '12', 'Ajustes afectos al IVAP', 0),
(13, 'C', '13', 'Ajustes en las CUOTAS', 0),
(14, 'D', '01', 'Intereses por mora', 1),
(15, 'D', '02', 'Aumento en el valor', 1),
(16, 'D', '03', 'Penalidades/ otros conceptos', 1),
(17, 'D', '10', 'Ajustes de operaciones de exportación', 1),
(18, 'D', '11', 'Ajustes afectos al IVAP', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `motivo_traslado`
--

CREATE TABLE `motivo_traslado` (
  `id` int(11) NOT NULL,
  `codigo` varchar(5) NOT NULL,
  `descripcion` varchar(100) NOT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `motivo_traslado`
--

INSERT INTO `motivo_traslado` (`id`, `codigo`, `descripcion`, `estado`) VALUES
(1, '01', 'VENTA', 1),
(2, '02', 'COMPRA', 1),
(3, '04', 'TRASLADO ENTRE ESTABLECIMIENTOS DE LA MISMA EMPRESA', 1),
(4, '08', 'IMPORTACIÓN', 1),
(5, '09', 'EXPORTACIÓN', 1),
(6, '13', 'OTROS', 1),
(7, '14', 'VENTA SUJETA A CONFIRMACION DEL COMPRADOR', 1),
(8, '18', 'TRASLADO EMISOR ITINERANTE CP', 1),
(9, '19', 'TRASLADO A ZONA PRIMARIA', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `movimientos_arqueo_caja`
--

CREATE TABLE `movimientos_arqueo_caja` (
  `id` int(11) NOT NULL,
  `id_arqueo_caja` int(11) DEFAULT NULL,
  `id_tipo_movimiento` int(11) DEFAULT NULL,
  `descripcion` varchar(250) DEFAULT NULL,
  `monto` float DEFAULT NULL,
  `comprobante` varchar(45) DEFAULT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `perfiles`
--

CREATE TABLE `perfiles` (
  `id_perfil` int(11) NOT NULL,
  `descripcion` varchar(45) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL,
  `fecha_creacion` timestamp NULL DEFAULT NULL,
  `fecha_actualizacion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `perfiles`
--

INSERT INTO `perfiles` (`id_perfil`, `descripcion`, `estado`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(10, 'SUPER ADMINISTRADOR', 1, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `perfil_modulo`
--

CREATE TABLE `perfil_modulo` (
  `idperfil_modulo` int(11) NOT NULL,
  `id_perfil` int(11) DEFAULT NULL,
  `id_modulo` int(11) DEFAULT NULL,
  `vista_inicio` tinyint(4) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `perfil_modulo`
--

INSERT INTO `perfil_modulo` (`idperfil_modulo`, `id_perfil`, `id_modulo`, `vista_inicio`, `estado`) VALUES
(2160, 11, 28, 0, 1),
(2161, 11, 2, 0, 1),
(2162, 11, 29, 0, 1),
(2163, 11, 46, 0, 1),
(2164, 11, 41, 0, 1),
(2165, 11, 44, 0, 1),
(2166, 11, 48, 0, 1),
(2167, 11, 51, 1, 1),
(2168, 11, 52, 0, 1),
(2169, 11, 53, 0, 1),
(2171, 11, 55, 0, 1),
(2172, 11, 15, 0, 1),
(2173, 11, 43, 0, 1),
(2174, 11, 25, 0, 1),
(2175, 11, 11, 0, 1),
(0, 10, 1, 1, 1),
(0, 10, 56, 0, 1),
(0, 10, 10, 0, 1),
(0, 10, 6, 0, 1),
(0, 10, 5, 0, 1),
(0, 10, 8, 0, 1),
(0, 10, 7, 0, 1),
(0, 10, 28, 0, 1),
(0, 10, 2, 0, 1),
(0, 10, 29, 0, 1),
(0, 10, 46, 0, 1),
(0, 10, 30, 0, 1),
(0, 10, 41, 0, 1),
(0, 10, 44, 0, 1),
(0, 10, 48, 0, 1),
(0, 10, 51, 0, 1),
(0, 10, 53, 0, 1),
(0, 10, 52, 0, 1),
(0, 10, 45, 0, 1),
(0, 10, 15, 0, 1),
(0, 10, 43, 0, 1),
(0, 10, 49, 0, 1),
(0, 10, 9, 0, 1),
(0, 10, 50, 0, 1),
(0, 10, 38, 0, 1),
(0, 10, 42, 0, 1),
(0, 10, 39, 0, 1),
(0, 10, 40, 0, 1),
(0, 10, 27, 0, 1),
(0, 10, 11, 0, 1),
(0, 10, 25, 0, 1),
(0, 10, 26, 0, 1),
(0, 10, 37, 0, 1),
(0, 10, 23, 0, 1),
(0, 10, 22, 0, 1),
(0, 10, 24, 0, 1),
(0, 10, 33, 0, 1),
(0, 10, 31, 0, 1),
(0, 10, 34, 0, 1),
(0, 10, 13, 0, 1),
(0, 10, 47, 0, 1),
(0, 10, 55, 0, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id` int(11) NOT NULL,
  `codigo_producto` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `id_categoria` int(11) DEFAULT NULL,
  `descripcion` text CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  `id_tipo_afectacion_igv` int(11) NOT NULL,
  `id_unidad_medida` varchar(3) NOT NULL,
  `costo_unitario` float DEFAULT 0,
  `precio_unitario_con_igv` float DEFAULT 0,
  `precio_unitario_sin_igv` float DEFAULT 0,
  `precio_unitario_mayor_con_igv` float DEFAULT 0,
  `precio_unitario_mayor_sin_igv` float DEFAULT 0,
  `precio_unitario_oferta_con_igv` float DEFAULT 0,
  `precio_unitario_oferta_sin_igv` float DEFAULT NULL,
  `stock` float DEFAULT 0,
  `minimo_stock` float DEFAULT 0,
  `ventas` float DEFAULT 0,
  `costo_total` float DEFAULT 0,
  `imagen` varchar(255) DEFAULT 'no_image.jpg',
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `fecha_actualizacion` date DEFAULT NULL,
  `estado` int(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores`
--

CREATE TABLE `proveedores` (
  `id` int(11) NOT NULL,
  `id_tipo_documento` varchar(45) NOT NULL,
  `ruc` varchar(45) NOT NULL,
  `razon_social` varchar(150) NOT NULL,
  `direccion` varchar(255) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `resumenes`
--

CREATE TABLE `resumenes` (
  `id` int(11) NOT NULL,
  `fecha_envio` date DEFAULT NULL,
  `fecha_referencia` date DEFAULT NULL,
  `correlativo` int(11) DEFAULT NULL,
  `resumen` smallint(6) DEFAULT NULL,
  `baja` smallint(6) DEFAULT NULL,
  `nombrexml` varchar(50) DEFAULT NULL,
  `mensaje_sunat` varchar(200) DEFAULT NULL,
  `codigo_sunat` varchar(20) DEFAULT NULL,
  `ticket` varchar(50) DEFAULT NULL,
  `estado` char(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `resumenes_detalle`
--

CREATE TABLE `resumenes_detalle` (
  `id` int(255) NOT NULL,
  `id_envio` int(11) DEFAULT NULL,
  `id_comprobante` int(11) DEFAULT NULL,
  `condicion` smallint(6) DEFAULT NULL COMMENT '1->Creacion, 2->Actualizacion, 3->Baja'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `serie`
--

CREATE TABLE `serie` (
  `id` int(11) NOT NULL,
  `id_tipo_comprobante` varchar(3) NOT NULL,
  `serie` varchar(4) NOT NULL,
  `correlativo` int(11) DEFAULT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tb_ubigeos`
--

CREATE TABLE `tb_ubigeos` (
  `ubigeo_reniec` varchar(6) NOT NULL,
  `departamento` text DEFAULT NULL,
  `provincia` text DEFAULT NULL,
  `distrito` text DEFAULT NULL,
  `region` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `tb_ubigeos`
--

INSERT INTO `tb_ubigeos` (`ubigeo_reniec`, `departamento`, `provincia`, `distrito`, `region`) VALUES
('000000', 'LIMA', 'LIMA', 'SANTA MARIA DE HUACHIPA', 'LIMA PROVINCIA'),
('010101', 'AMAZONAS', 'CHACHAPOYAS', 'CHACHAPOYAS', 'AMAZONAS'),
('010102', 'AMAZONAS', 'CHACHAPOYAS', 'ASUNCION', 'AMAZONAS'),
('010103', 'AMAZONAS', 'CHACHAPOYAS', 'BALSAS', 'AMAZONAS'),
('010104', 'AMAZONAS', 'CHACHAPOYAS', 'CHETO', 'AMAZONAS'),
('010105', 'AMAZONAS', 'CHACHAPOYAS', 'CHILIQUIN', 'AMAZONAS'),
('010106', 'AMAZONAS', 'CHACHAPOYAS', 'CHUQUIBAMBA', 'AMAZONAS'),
('010107', 'AMAZONAS', 'CHACHAPOYAS', 'GRANADA', 'AMAZONAS'),
('010108', 'AMAZONAS', 'CHACHAPOYAS', 'HUANCAS', 'AMAZONAS'),
('010109', 'AMAZONAS', 'CHACHAPOYAS', 'LA JALCA', 'AMAZONAS'),
('010110', 'AMAZONAS', 'CHACHAPOYAS', 'LEIMEBAMBA', 'AMAZONAS'),
('010111', 'AMAZONAS', 'CHACHAPOYAS', 'LEVANTO', 'AMAZONAS'),
('010112', 'AMAZONAS', 'CHACHAPOYAS', 'MAGDALENA', 'AMAZONAS'),
('010113', 'AMAZONAS', 'CHACHAPOYAS', 'MARISCAL CASTILLA', 'AMAZONAS'),
('010114', 'AMAZONAS', 'CHACHAPOYAS', 'MOLINOPAMPA', 'AMAZONAS'),
('010115', 'AMAZONAS', 'CHACHAPOYAS', 'MONTEVIDEO', 'AMAZONAS'),
('010116', 'AMAZONAS', 'CHACHAPOYAS', 'OLLEROS', 'AMAZONAS'),
('010117', 'AMAZONAS', 'CHACHAPOYAS', 'QUINJALCA', 'AMAZONAS'),
('010118', 'AMAZONAS', 'CHACHAPOYAS', 'SAN FRANCISCO DE DAGUAS', 'AMAZONAS'),
('010119', 'AMAZONAS', 'CHACHAPOYAS', 'SAN ISIDRO DE MAINO', 'AMAZONAS'),
('010120', 'AMAZONAS', 'CHACHAPOYAS', 'SOLOCO', 'AMAZONAS'),
('010121', 'AMAZONAS', 'CHACHAPOYAS', 'SONCHE', 'AMAZONAS'),
('010201', 'AMAZONAS', 'BAGUA', 'LA PECA', 'AMAZONAS'),
('010202', 'AMAZONAS', 'BAGUA', 'ARAMANGO', 'AMAZONAS'),
('010203', 'AMAZONAS', 'BAGUA', 'COPALLIN', 'AMAZONAS'),
('010204', 'AMAZONAS', 'BAGUA', 'EL PARCO', 'AMAZONAS'),
('010205', 'AMAZONAS', 'BAGUA', 'BAGUA', 'AMAZONAS'),
('010206', 'AMAZONAS', 'BAGUA', 'IMAZA', 'AMAZONAS'),
('010301', 'AMAZONAS', 'BONGARA', 'JUMBILLA', 'AMAZONAS'),
('010302', 'AMAZONAS', 'BONGARA', 'COROSHA', 'AMAZONAS'),
('010303', 'AMAZONAS', 'BONGARA', 'CUISPES', 'AMAZONAS'),
('010304', 'AMAZONAS', 'BONGARA', 'CHISQUILLA', 'AMAZONAS'),
('010305', 'AMAZONAS', 'BONGARA', 'CHURUJA', 'AMAZONAS'),
('010306', 'AMAZONAS', 'BONGARA', 'FLORIDA', 'AMAZONAS'),
('010307', 'AMAZONAS', 'BONGARA', 'RECTA', 'AMAZONAS'),
('010308', 'AMAZONAS', 'BONGARA', 'SAN CARLOS', 'AMAZONAS'),
('010309', 'AMAZONAS', 'BONGARA', 'SHIPASBAMBA', 'AMAZONAS'),
('010310', 'AMAZONAS', 'BONGARA', 'VALERA', 'AMAZONAS'),
('010311', 'AMAZONAS', 'BONGARA', 'YAMBRASBAMBA', 'AMAZONAS'),
('010312', 'AMAZONAS', 'BONGARA', 'JAZAN', 'AMAZONAS'),
('010401', 'AMAZONAS', 'LUYA', 'LAMUD', 'AMAZONAS'),
('010402', 'AMAZONAS', 'LUYA', 'CAMPORREDONDO', 'AMAZONAS'),
('010403', 'AMAZONAS', 'LUYA', 'COCABAMBA', 'AMAZONAS'),
('010404', 'AMAZONAS', 'LUYA', 'COLCAMAR', 'AMAZONAS'),
('010405', 'AMAZONAS', 'LUYA', 'CONILA', 'AMAZONAS'),
('010406', 'AMAZONAS', 'LUYA', 'INGUILPATA', 'AMAZONAS'),
('010407', 'AMAZONAS', 'LUYA', 'LONGUITA', 'AMAZONAS'),
('010408', 'AMAZONAS', 'LUYA', 'LONYA CHICO', 'AMAZONAS'),
('010409', 'AMAZONAS', 'LUYA', 'LUYA', 'AMAZONAS'),
('010410', 'AMAZONAS', 'LUYA', 'LUYA VIEJO', 'AMAZONAS'),
('010411', 'AMAZONAS', 'LUYA', 'MARIA', 'AMAZONAS'),
('010412', 'AMAZONAS', 'LUYA', 'OCALLI', 'AMAZONAS'),
('010413', 'AMAZONAS', 'LUYA', 'OCUMAL', 'AMAZONAS'),
('010414', 'AMAZONAS', 'LUYA', 'PISUQUIA', 'AMAZONAS'),
('010415', 'AMAZONAS', 'LUYA', 'SAN CRISTOBAL', 'AMAZONAS'),
('010416', 'AMAZONAS', 'LUYA', 'SAN FRANCISCO DEL YESO', 'AMAZONAS'),
('010417', 'AMAZONAS', 'LUYA', 'SAN JERONIMO', 'AMAZONAS'),
('010418', 'AMAZONAS', 'LUYA', 'SAN JUAN DE LOPECANCHA', 'AMAZONAS'),
('010419', 'AMAZONAS', 'LUYA', 'SANTA CATALINA', 'AMAZONAS'),
('010420', 'AMAZONAS', 'LUYA', 'SANTO TOMAS', 'AMAZONAS'),
('010421', 'AMAZONAS', 'LUYA', 'TINGO', 'AMAZONAS'),
('010422', 'AMAZONAS', 'LUYA', 'TRITA', 'AMAZONAS'),
('010423', 'AMAZONAS', 'LUYA', 'PROVIDENCIA', 'AMAZONAS'),
('010501', 'AMAZONAS', 'RODRIGUEZ DE MENDOZA', 'SAN NICOLAS', 'AMAZONAS'),
('010502', 'AMAZONAS', 'RODRIGUEZ DE MENDOZA', 'COCHAMAL', 'AMAZONAS'),
('010503', 'AMAZONAS', 'RODRIGUEZ DE MENDOZA', 'CHIRIMOTO', 'AMAZONAS'),
('010504', 'AMAZONAS', 'RODRIGUEZ DE MENDOZA', 'HUAMBO', 'AMAZONAS'),
('010505', 'AMAZONAS', 'RODRIGUEZ DE MENDOZA', 'LIMABAMBA', 'AMAZONAS'),
('010506', 'AMAZONAS', 'RODRIGUEZ DE MENDOZA', 'LONGAR', 'AMAZONAS'),
('010507', 'AMAZONAS', 'RODRIGUEZ DE MENDOZA', 'MILPUC', 'AMAZONAS'),
('010508', 'AMAZONAS', 'RODRIGUEZ DE MENDOZA', 'MARISCAL BENAVIDES', 'AMAZONAS'),
('010509', 'AMAZONAS', 'RODRIGUEZ DE MENDOZA', 'OMIA', 'AMAZONAS'),
('010510', 'AMAZONAS', 'RODRIGUEZ DE MENDOZA', 'SANTA ROSA', 'AMAZONAS'),
('010511', 'AMAZONAS', 'RODRIGUEZ DE MENDOZA', 'TOTORA', 'AMAZONAS'),
('010512', 'AMAZONAS', 'RODRIGUEZ DE MENDOZA', 'VISTA ALEGRE', 'AMAZONAS'),
('010601', 'AMAZONAS', 'CONDORCANQUI', 'NIEVA', 'AMAZONAS'),
('010602', 'AMAZONAS', 'CONDORCANQUI', 'RIO SANTIAGO', 'AMAZONAS'),
('010603', 'AMAZONAS', 'CONDORCANQUI', 'EL CENEPA', 'AMAZONAS'),
('010701', 'AMAZONAS', 'UTCUBAMBA', 'BAGUA GRANDE', 'AMAZONAS'),
('010702', 'AMAZONAS', 'UTCUBAMBA', 'CAJARURO', 'AMAZONAS'),
('010703', 'AMAZONAS', 'UTCUBAMBA', 'CUMBA', 'AMAZONAS'),
('010704', 'AMAZONAS', 'UTCUBAMBA', 'EL MILAGRO', 'AMAZONAS'),
('010705', 'AMAZONAS', 'UTCUBAMBA', 'JAMALCA', 'AMAZONAS'),
('010706', 'AMAZONAS', 'UTCUBAMBA', 'LONYA GRANDE', 'AMAZONAS'),
('010707', 'AMAZONAS', 'UTCUBAMBA', 'YAMON', 'AMAZONAS'),
('020101', 'ANCASH', 'HUARAZ', 'HUARAZ', 'ANCASH'),
('020102', 'ANCASH', 'HUARAZ', 'INDEPENDENCIA', 'ANCASH'),
('020103', 'ANCASH', 'HUARAZ', 'COCHABAMBA', 'ANCASH'),
('020104', 'ANCASH', 'HUARAZ', 'COLCABAMBA', 'ANCASH'),
('020105', 'ANCASH', 'HUARAZ', 'HUANCHAY', 'ANCASH'),
('020106', 'ANCASH', 'HUARAZ', 'JANGAS', 'ANCASH'),
('020107', 'ANCASH', 'HUARAZ', 'LA LIBERTAD', 'ANCASH'),
('020108', 'ANCASH', 'HUARAZ', 'OLLEROS', 'ANCASH'),
('020109', 'ANCASH', 'HUARAZ', 'PAMPAS', 'ANCASH'),
('020110', 'ANCASH', 'HUARAZ', 'PARIACOTO', 'ANCASH'),
('020111', 'ANCASH', 'HUARAZ', 'PIRA', 'ANCASH'),
('020112', 'ANCASH', 'HUARAZ', 'TARICA', 'ANCASH'),
('020201', 'ANCASH', 'AIJA', 'AIJA', 'ANCASH'),
('020203', 'ANCASH', 'AIJA', 'CORIS', 'ANCASH'),
('020205', 'ANCASH', 'AIJA', 'HUACLLAN', 'ANCASH'),
('020206', 'ANCASH', 'AIJA', 'LA MERCED', 'ANCASH'),
('020208', 'ANCASH', 'AIJA', 'SUCCHA', 'ANCASH'),
('020301', 'ANCASH', 'BOLOGNESI', 'CHIQUIAN', 'ANCASH'),
('020302', 'ANCASH', 'BOLOGNESI', 'ABELARDO PARDO LEZAMETA', 'ANCASH'),
('020304', 'ANCASH', 'BOLOGNESI', 'AQUIA', 'ANCASH'),
('020305', 'ANCASH', 'BOLOGNESI', 'CAJACAY', 'ANCASH'),
('020310', 'ANCASH', 'BOLOGNESI', 'HUAYLLACAYAN', 'ANCASH'),
('020311', 'ANCASH', 'BOLOGNESI', 'HUASTA', 'ANCASH'),
('020313', 'ANCASH', 'BOLOGNESI', 'MANGAS', 'ANCASH'),
('020315', 'ANCASH', 'BOLOGNESI', 'PACLLON', 'ANCASH'),
('020317', 'ANCASH', 'BOLOGNESI', 'SAN MIGUEL DE CORPANQUI', 'ANCASH'),
('020320', 'ANCASH', 'BOLOGNESI', 'TICLLOS', 'ANCASH'),
('020321', 'ANCASH', 'BOLOGNESI', 'ANTONIO RAYMONDI', 'ANCASH'),
('020322', 'ANCASH', 'BOLOGNESI', 'CANIS', 'ANCASH'),
('020323', 'ANCASH', 'BOLOGNESI', 'COLQUIOC', 'ANCASH'),
('020324', 'ANCASH', 'BOLOGNESI', 'LA PRIMAVERA', 'ANCASH'),
('020325', 'ANCASH', 'BOLOGNESI', 'HUALLANCA', 'ANCASH'),
('020401', 'ANCASH', 'CARHUAZ', 'CARHUAZ', 'ANCASH'),
('020402', 'ANCASH', 'CARHUAZ', 'ACOPAMPA', 'ANCASH'),
('020403', 'ANCASH', 'CARHUAZ', 'AMASHCA', 'ANCASH'),
('020404', 'ANCASH', 'CARHUAZ', 'ANTA', 'ANCASH'),
('020405', 'ANCASH', 'CARHUAZ', 'ATAQUERO', 'ANCASH'),
('020406', 'ANCASH', 'CARHUAZ', 'MARCARA', 'ANCASH'),
('020407', 'ANCASH', 'CARHUAZ', 'PARIAHUANCA', 'ANCASH'),
('020408', 'ANCASH', 'CARHUAZ', 'SAN MIGUEL DE ACO', 'ANCASH'),
('020409', 'ANCASH', 'CARHUAZ', 'SHILLA', 'ANCASH'),
('020410', 'ANCASH', 'CARHUAZ', 'TINCO', 'ANCASH'),
('020411', 'ANCASH', 'CARHUAZ', 'YUNGAR', 'ANCASH'),
('020501', 'ANCASH', 'CASMA', 'CASMA', 'ANCASH'),
('020502', 'ANCASH', 'CASMA', 'BUENA VISTA ALTA', 'ANCASH'),
('020503', 'ANCASH', 'CASMA', 'COMANDANTE NOEL', 'ANCASH'),
('020505', 'ANCASH', 'CASMA', 'YAUTAN', 'ANCASH'),
('020601', 'ANCASH', 'CORONGO', 'CORONGO', 'ANCASH'),
('020602', 'ANCASH', 'CORONGO', 'ACO', 'ANCASH'),
('020603', 'ANCASH', 'CORONGO', 'BAMBAS', 'ANCASH'),
('020604', 'ANCASH', 'CORONGO', 'CUSCA', 'ANCASH'),
('020605', 'ANCASH', 'CORONGO', 'LA PAMPA', 'ANCASH'),
('020606', 'ANCASH', 'CORONGO', 'YANAC', 'ANCASH'),
('020607', 'ANCASH', 'CORONGO', 'YUPAN', 'ANCASH'),
('020701', 'ANCASH', 'HUAYLAS', 'CARAZ', 'ANCASH'),
('020702', 'ANCASH', 'HUAYLAS', 'HUALLANCA', 'ANCASH'),
('020703', 'ANCASH', 'HUAYLAS', 'HUATA', 'ANCASH'),
('020704', 'ANCASH', 'HUAYLAS', 'HUAYLAS', 'ANCASH'),
('020705', 'ANCASH', 'HUAYLAS', 'MATO', 'ANCASH'),
('020706', 'ANCASH', 'HUAYLAS', 'PAMPAROMAS', 'ANCASH'),
('020707', 'ANCASH', 'HUAYLAS', 'PUEBLO LIBRE', 'ANCASH'),
('020708', 'ANCASH', 'HUAYLAS', 'SANTA CRUZ', 'ANCASH'),
('020709', 'ANCASH', 'HUAYLAS', 'YURACMARCA', 'ANCASH'),
('020710', 'ANCASH', 'HUAYLAS', 'SANTO TORIBIO', 'ANCASH'),
('020801', 'ANCASH', 'HUARI', 'HUARI', 'ANCASH'),
('020802', 'ANCASH', 'HUARI', 'CAJAY', 'ANCASH'),
('020803', 'ANCASH', 'HUARI', 'CHAVIN DE HUANTAR', 'ANCASH'),
('020804', 'ANCASH', 'HUARI', 'HUACACHI', 'ANCASH'),
('020805', 'ANCASH', 'HUARI', 'HUACHIS', 'ANCASH'),
('020806', 'ANCASH', 'HUARI', 'HUACCHIS', 'ANCASH'),
('020807', 'ANCASH', 'HUARI', 'HUANTAR', 'ANCASH'),
('020808', 'ANCASH', 'HUARI', 'MASIN', 'ANCASH'),
('020809', 'ANCASH', 'HUARI', 'PAUCAS', 'ANCASH'),
('020810', 'ANCASH', 'HUARI', 'PONTO', 'ANCASH'),
('020811', 'ANCASH', 'HUARI', 'RAHUAPAMPA', 'ANCASH'),
('020812', 'ANCASH', 'HUARI', 'RAPAYAN', 'ANCASH'),
('020813', 'ANCASH', 'HUARI', 'SAN MARCOS', 'ANCASH'),
('020814', 'ANCASH', 'HUARI', 'SAN PEDRO DE CHANA', 'ANCASH'),
('020815', 'ANCASH', 'HUARI', 'UCO', 'ANCASH'),
('020816', 'ANCASH', 'HUARI', 'ANRA', 'ANCASH'),
('020901', 'ANCASH', 'MARISCAL LUZURIAGA', 'PISCOBAMBA', 'ANCASH'),
('020902', 'ANCASH', 'MARISCAL LUZURIAGA', 'CASCA', 'ANCASH'),
('020903', 'ANCASH', 'MARISCAL LUZURIAGA', 'LUCMA', 'ANCASH'),
('020904', 'ANCASH', 'MARISCAL LUZURIAGA', 'FIDEL OLIVAS ESCUDERO', 'ANCASH'),
('020905', 'ANCASH', 'MARISCAL LUZURIAGA', 'LLAMA', 'ANCASH'),
('020906', 'ANCASH', 'MARISCAL LUZURIAGA', 'LLUMPA', 'ANCASH'),
('020907', 'ANCASH', 'MARISCAL LUZURIAGA', 'MUSGA', 'ANCASH'),
('020908', 'ANCASH', 'MARISCAL LUZURIAGA', 'ELEAZAR GUZMAN BARRON', 'ANCASH'),
('021001', 'ANCASH', 'PALLASCA', 'CABANA', 'ANCASH'),
('021002', 'ANCASH', 'PALLASCA', 'BOLOGNESI', 'ANCASH'),
('021003', 'ANCASH', 'PALLASCA', 'CONCHUCOS', 'ANCASH'),
('021004', 'ANCASH', 'PALLASCA', 'HUACASCHUQUE', 'ANCASH'),
('021005', 'ANCASH', 'PALLASCA', 'HUANDOVAL', 'ANCASH'),
('021006', 'ANCASH', 'PALLASCA', 'LACABAMBA', 'ANCASH'),
('021007', 'ANCASH', 'PALLASCA', 'LLAPO', 'ANCASH'),
('021008', 'ANCASH', 'PALLASCA', 'PALLASCA', 'ANCASH'),
('021009', 'ANCASH', 'PALLASCA', 'PAMPAS', 'ANCASH'),
('021010', 'ANCASH', 'PALLASCA', 'SANTA ROSA', 'ANCASH'),
('021011', 'ANCASH', 'PALLASCA', 'TAUCA', 'ANCASH'),
('021101', 'ANCASH', 'POMABAMBA', 'POMABAMBA', 'ANCASH'),
('021102', 'ANCASH', 'POMABAMBA', 'HUAYLLAN', 'ANCASH'),
('021103', 'ANCASH', 'POMABAMBA', 'PAROBAMBA', 'ANCASH'),
('021104', 'ANCASH', 'POMABAMBA', 'QUINUABAMBA', 'ANCASH'),
('021201', 'ANCASH', 'RECUAY', 'RECUAY', 'ANCASH'),
('021202', 'ANCASH', 'RECUAY', 'COTAPARACO', 'ANCASH'),
('021203', 'ANCASH', 'RECUAY', 'HUAYLLAPAMPA', 'ANCASH'),
('021204', 'ANCASH', 'RECUAY', 'MARCA', 'ANCASH'),
('021205', 'ANCASH', 'RECUAY', 'PAMPAS CHICO', 'ANCASH'),
('021206', 'ANCASH', 'RECUAY', 'PARARIN', 'ANCASH'),
('021207', 'ANCASH', 'RECUAY', 'TAPACOCHA', 'ANCASH'),
('021208', 'ANCASH', 'RECUAY', 'TICAPAMPA', 'ANCASH'),
('021209', 'ANCASH', 'RECUAY', 'LLACLLIN', 'ANCASH'),
('021210', 'ANCASH', 'RECUAY', 'CATAC', 'ANCASH'),
('021301', 'ANCASH', 'SANTA', 'CHIMBOTE', 'ANCASH'),
('021302', 'ANCASH', 'SANTA', 'CACERES DEL PERU', 'ANCASH'),
('021303', 'ANCASH', 'SANTA', 'MACATE', 'ANCASH'),
('021304', 'ANCASH', 'SANTA', 'MORO', 'ANCASH'),
('021305', 'ANCASH', 'SANTA', 'NEPEÑA', 'ANCASH'),
('021306', 'ANCASH', 'SANTA', 'SAMANCO', 'ANCASH'),
('021307', 'ANCASH', 'SANTA', 'SANTA', 'ANCASH'),
('021308', 'ANCASH', 'SANTA', 'COISHCO', 'ANCASH'),
('021309', 'ANCASH', 'SANTA', 'NUEVO CHIMBOTE', 'ANCASH'),
('021401', 'ANCASH', 'SIHUAS', 'SIHUAS', 'ANCASH'),
('021402', 'ANCASH', 'SIHUAS', 'ALFONSO UGARTE', 'ANCASH'),
('021403', 'ANCASH', 'SIHUAS', 'CHINGALPO', 'ANCASH'),
('021404', 'ANCASH', 'SIHUAS', 'HUAYLLABAMBA', 'ANCASH'),
('021405', 'ANCASH', 'SIHUAS', 'QUICHES', 'ANCASH'),
('021406', 'ANCASH', 'SIHUAS', 'SICSIBAMBA', 'ANCASH'),
('021407', 'ANCASH', 'SIHUAS', 'ACOBAMBA', 'ANCASH'),
('021408', 'ANCASH', 'SIHUAS', 'CASHAPAMPA', 'ANCASH'),
('021409', 'ANCASH', 'SIHUAS', 'RAGASH', 'ANCASH'),
('021410', 'ANCASH', 'SIHUAS', 'SAN JUAN', 'ANCASH'),
('021501', 'ANCASH', 'YUNGAY', 'YUNGAY', 'ANCASH'),
('021502', 'ANCASH', 'YUNGAY', 'CASCAPARA', 'ANCASH'),
('021503', 'ANCASH', 'YUNGAY', 'MANCOS', 'ANCASH'),
('021504', 'ANCASH', 'YUNGAY', 'MATACOTO', 'ANCASH'),
('021505', 'ANCASH', 'YUNGAY', 'QUILLO', 'ANCASH'),
('021506', 'ANCASH', 'YUNGAY', 'RANRAHIRCA', 'ANCASH'),
('021507', 'ANCASH', 'YUNGAY', 'SHUPLUY', 'ANCASH'),
('021508', 'ANCASH', 'YUNGAY', 'YANAMA', 'ANCASH'),
('021601', 'ANCASH', 'ANTONIO RAYMONDI', 'LLAMELLIN', 'ANCASH'),
('021602', 'ANCASH', 'ANTONIO RAYMONDI', 'ACZO', 'ANCASH'),
('021603', 'ANCASH', 'ANTONIO RAYMONDI', 'CHACCHO', 'ANCASH'),
('021604', 'ANCASH', 'ANTONIO RAYMONDI', 'CHINGAS', 'ANCASH'),
('021605', 'ANCASH', 'ANTONIO RAYMONDI', 'MIRGAS', 'ANCASH'),
('021606', 'ANCASH', 'ANTONIO RAYMONDI', 'SAN JUAN DE RONTOY', 'ANCASH'),
('021701', 'ANCASH', 'CARLOS FERMIN FITZCARRALD', 'SAN LUIS', 'ANCASH'),
('021702', 'ANCASH', 'CARLOS FERMIN FITZCARRALD', 'YAUYA', 'ANCASH'),
('021703', 'ANCASH', 'CARLOS FERMIN FITZCARRALD', 'SAN NICOLAS', 'ANCASH'),
('021801', 'ANCASH', 'ASUNCION', 'CHACAS', 'ANCASH'),
('021802', 'ANCASH', 'ASUNCION', 'ACOCHACA', 'ANCASH'),
('021901', 'ANCASH', 'HUARMEY', 'HUARMEY', 'ANCASH'),
('021902', 'ANCASH', 'HUARMEY', 'COCHAPETI', 'ANCASH'),
('021903', 'ANCASH', 'HUARMEY', 'HUAYAN', 'ANCASH'),
('021904', 'ANCASH', 'HUARMEY', 'MALVAS', 'ANCASH'),
('021905', 'ANCASH', 'HUARMEY', 'CULEBRAS', 'ANCASH'),
('022001', 'ANCASH', 'OCROS', 'ACAS', 'ANCASH'),
('022002', 'ANCASH', 'OCROS', 'CAJAMARQUILLA', 'ANCASH'),
('022003', 'ANCASH', 'OCROS', 'CARHUAPAMPA', 'ANCASH'),
('022004', 'ANCASH', 'OCROS', 'COCHAS', 'ANCASH'),
('022005', 'ANCASH', 'OCROS', 'CONGAS', 'ANCASH'),
('022006', 'ANCASH', 'OCROS', 'LLIPA', 'ANCASH'),
('022007', 'ANCASH', 'OCROS', 'OCROS', 'ANCASH'),
('022008', 'ANCASH', 'OCROS', 'SAN CRISTOBAL DE RAJAN', 'ANCASH'),
('022009', 'ANCASH', 'OCROS', 'SAN PEDRO', 'ANCASH'),
('022010', 'ANCASH', 'OCROS', 'SANTIAGO DE CHILCAS', 'ANCASH'),
('030101', 'APURIMAC', 'ABANCAY', 'ABANCAY', 'APURIMAC'),
('030102', 'APURIMAC', 'ABANCAY', 'CIRCA', 'APURIMAC'),
('030103', 'APURIMAC', 'ABANCAY', 'CURAHUASI', 'APURIMAC'),
('030104', 'APURIMAC', 'ABANCAY', 'CHACOCHE', 'APURIMAC'),
('030105', 'APURIMAC', 'ABANCAY', 'HUANIPACA', 'APURIMAC'),
('030106', 'APURIMAC', 'ABANCAY', 'LAMBRAMA', 'APURIMAC'),
('030107', 'APURIMAC', 'ABANCAY', 'PICHIRHUA', 'APURIMAC'),
('030108', 'APURIMAC', 'ABANCAY', 'SAN PEDRO DE CACHORA', 'APURIMAC'),
('030109', 'APURIMAC', 'ABANCAY', 'TAMBURCO', 'APURIMAC'),
('030201', 'APURIMAC', 'AYMARAES', 'CHALHUANCA', 'APURIMAC'),
('030202', 'APURIMAC', 'AYMARAES', 'CAPAYA', 'APURIMAC'),
('030203', 'APURIMAC', 'AYMARAES', 'CARAYBAMBA', 'APURIMAC'),
('030204', 'APURIMAC', 'AYMARAES', 'COLCABAMBA', 'APURIMAC'),
('030205', 'APURIMAC', 'AYMARAES', 'COTARUSE', 'APURIMAC'),
('030206', 'APURIMAC', 'AYMARAES', 'CHAPIMARCA', 'APURIMAC'),
('030207', 'APURIMAC', 'AYMARAES', 'HUAYLLO', 'APURIMAC'),
('030208', 'APURIMAC', 'AYMARAES', 'LUCRE', 'APURIMAC'),
('030209', 'APURIMAC', 'AYMARAES', 'POCOHUANCA', 'APURIMAC'),
('030210', 'APURIMAC', 'AYMARAES', 'SAÑAYCA', 'APURIMAC'),
('030211', 'APURIMAC', 'AYMARAES', 'SORAYA', 'APURIMAC'),
('030212', 'APURIMAC', 'AYMARAES', 'TAPAIRIHUA', 'APURIMAC'),
('030213', 'APURIMAC', 'AYMARAES', 'TINTAY', 'APURIMAC'),
('030214', 'APURIMAC', 'AYMARAES', 'TORAYA', 'APURIMAC'),
('030215', 'APURIMAC', 'AYMARAES', 'YANACA', 'APURIMAC'),
('030216', 'APURIMAC', 'AYMARAES', 'SAN JUAN DE CHACÑA', 'APURIMAC'),
('030217', 'APURIMAC', 'AYMARAES', 'JUSTO APU SAHUARAURA', 'APURIMAC'),
('030301', 'APURIMAC', 'ANDAHUAYLAS', 'ANDAHUAYLAS', 'APURIMAC'),
('030302', 'APURIMAC', 'ANDAHUAYLAS', 'ANDARAPA', 'APURIMAC'),
('030303', 'APURIMAC', 'ANDAHUAYLAS', 'CHIARA', 'APURIMAC'),
('030304', 'APURIMAC', 'ANDAHUAYLAS', 'HUANCARAMA', 'APURIMAC'),
('030305', 'APURIMAC', 'ANDAHUAYLAS', 'HUANCARAY', 'APURIMAC'),
('030306', 'APURIMAC', 'ANDAHUAYLAS', 'KISHUARA', 'APURIMAC'),
('030307', 'APURIMAC', 'ANDAHUAYLAS', 'PACOBAMBA', 'APURIMAC'),
('030308', 'APURIMAC', 'ANDAHUAYLAS', 'PAMPACHIRI', 'APURIMAC'),
('030309', 'APURIMAC', 'ANDAHUAYLAS', 'SAN ANTONIO DE CACHI', 'APURIMAC'),
('030310', 'APURIMAC', 'ANDAHUAYLAS', 'SAN JERONIMO', 'APURIMAC'),
('030311', 'APURIMAC', 'ANDAHUAYLAS', 'TALAVERA', 'APURIMAC'),
('030312', 'APURIMAC', 'ANDAHUAYLAS', 'TURPO', 'APURIMAC'),
('030313', 'APURIMAC', 'ANDAHUAYLAS', 'PACUCHA', 'APURIMAC'),
('030314', 'APURIMAC', 'ANDAHUAYLAS', 'POMACOCHA', 'APURIMAC'),
('030315', 'APURIMAC', 'ANDAHUAYLAS', 'SANTA MARIA DE CHICMO', 'APURIMAC'),
('030316', 'APURIMAC', 'ANDAHUAYLAS', 'TUMAY HUARACA', 'APURIMAC'),
('030317', 'APURIMAC', 'ANDAHUAYLAS', 'HUAYANA', 'APURIMAC'),
('030318', 'APURIMAC', 'ANDAHUAYLAS', 'SAN MIGUEL DE CHACCRAMPA', 'APURIMAC'),
('030319', 'APURIMAC', 'ANDAHUAYLAS', 'KAQUIABAMBA', 'APURIMAC'),
('030320', 'APURIMAC', 'ANDAHUAYLAS', 'JOSE MARIA ARGUEDAS', 'APURIMAC'),
('030401', 'APURIMAC', 'ANTABAMBA', 'ANTABAMBA', 'APURIMAC'),
('030402', 'APURIMAC', 'ANTABAMBA', 'EL ORO', 'APURIMAC'),
('030403', 'APURIMAC', 'ANTABAMBA', 'HUAQUIRCA', 'APURIMAC'),
('030404', 'APURIMAC', 'ANTABAMBA', 'JUAN ESPINOZA MEDRANO', 'APURIMAC'),
('030405', 'APURIMAC', 'ANTABAMBA', 'OROPESA', 'APURIMAC'),
('030406', 'APURIMAC', 'ANTABAMBA', 'PACHACONAS', 'APURIMAC'),
('030407', 'APURIMAC', 'ANTABAMBA', 'SABAINO', 'APURIMAC'),
('030501', 'APURIMAC', 'COTABAMBAS', 'TAMBOBAMBA', 'APURIMAC'),
('030502', 'APURIMAC', 'COTABAMBAS', 'COYLLURQUI', 'APURIMAC'),
('030503', 'APURIMAC', 'COTABAMBAS', 'COTABAMBAS', 'APURIMAC'),
('030504', 'APURIMAC', 'COTABAMBAS', 'HAQUIRA', 'APURIMAC'),
('030505', 'APURIMAC', 'COTABAMBAS', 'MARA', 'APURIMAC'),
('030506', 'APURIMAC', 'COTABAMBAS', 'CHALLHUAHUACHO', 'APURIMAC'),
('030601', 'APURIMAC', 'GRAU', 'CHUQUIBAMBILLA', 'APURIMAC'),
('030602', 'APURIMAC', 'GRAU', 'CURPAHUASI', 'APURIMAC'),
('030603', 'APURIMAC', 'GRAU', 'HUAYLLATI', 'APURIMAC'),
('030604', 'APURIMAC', 'GRAU', 'MAMARA', 'APURIMAC'),
('030605', 'APURIMAC', 'GRAU', 'GAMARRA', 'APURIMAC'),
('030606', 'APURIMAC', 'GRAU', 'MICAELA BASTIDAS', 'APURIMAC'),
('030607', 'APURIMAC', 'GRAU', 'PROGRESO', 'APURIMAC'),
('030608', 'APURIMAC', 'GRAU', 'PATAYPAMPA', 'APURIMAC'),
('030609', 'APURIMAC', 'GRAU', 'SAN ANTONIO', 'APURIMAC'),
('030610', 'APURIMAC', 'GRAU', 'TURPAY', 'APURIMAC'),
('030611', 'APURIMAC', 'GRAU', 'VILCABAMBA', 'APURIMAC'),
('030612', 'APURIMAC', 'GRAU', 'VIRUNDO', 'APURIMAC'),
('030613', 'APURIMAC', 'GRAU', 'SANTA ROSA', 'APURIMAC'),
('030614', 'APURIMAC', 'GRAU', 'CURASCO', 'APURIMAC'),
('030701', 'APURIMAC', 'CHINCHEROS', 'CHINCHEROS', 'APURIMAC'),
('030702', 'APURIMAC', 'CHINCHEROS', 'ONGOY', 'APURIMAC'),
('030703', 'APURIMAC', 'CHINCHEROS', 'OCOBAMBA', 'APURIMAC'),
('030704', 'APURIMAC', 'CHINCHEROS', 'COCHARCAS', 'APURIMAC'),
('030705', 'APURIMAC', 'CHINCHEROS', 'ANCO-HUALLO', 'APURIMAC'),
('030706', 'APURIMAC', 'CHINCHEROS', 'HUACCANA', 'APURIMAC'),
('030707', 'APURIMAC', 'CHINCHEROS', 'URANMARCA', 'APURIMAC'),
('030708', 'APURIMAC', 'CHINCHEROS', 'RANRACANCHA', 'APURIMAC'),
('030709', 'APURIMAC', 'CHINCHEROS', 'ROCCHACC', 'APURIMAC'),
('030710', 'APURIMAC', 'CHINCHEROS', 'EL PORVENIR', 'APURIMAC'),
('030711', 'APURIMAC', 'CHINCHEROS', 'LOS CHANKAS', 'APURIMAC'),
('030712', 'APURIMAC', 'CHINCHEROS', 'AHUAYRO', 'APURIMAC'),
('040101', 'AREQUIPA', 'AREQUIPA', 'AREQUIPA', 'AREQUIPA'),
('040102', 'AREQUIPA', 'AREQUIPA', 'CAYMA', 'AREQUIPA'),
('040103', 'AREQUIPA', 'AREQUIPA', 'CERRO COLORADO', 'AREQUIPA'),
('040104', 'AREQUIPA', 'AREQUIPA', 'CHARACATO', 'AREQUIPA'),
('040105', 'AREQUIPA', 'AREQUIPA', 'CHIGUATA', 'AREQUIPA'),
('040106', 'AREQUIPA', 'AREQUIPA', 'LA JOYA', 'AREQUIPA'),
('040107', 'AREQUIPA', 'AREQUIPA', 'MIRAFLORES', 'AREQUIPA'),
('040108', 'AREQUIPA', 'AREQUIPA', 'MOLLEBAYA', 'AREQUIPA'),
('040109', 'AREQUIPA', 'AREQUIPA', 'PAUCARPATA', 'AREQUIPA'),
('040110', 'AREQUIPA', 'AREQUIPA', 'POCSI', 'AREQUIPA'),
('040111', 'AREQUIPA', 'AREQUIPA', 'POLOBAYA', 'AREQUIPA'),
('040112', 'AREQUIPA', 'AREQUIPA', 'QUEQUEÑA', 'AREQUIPA'),
('040113', 'AREQUIPA', 'AREQUIPA', 'SABANDIA', 'AREQUIPA'),
('040114', 'AREQUIPA', 'AREQUIPA', 'SACHACA', 'AREQUIPA'),
('040115', 'AREQUIPA', 'AREQUIPA', 'SAN JUAN DE SIGUAS', 'AREQUIPA'),
('040116', 'AREQUIPA', 'AREQUIPA', 'SAN JUAN DE TARUCANI', 'AREQUIPA'),
('040117', 'AREQUIPA', 'AREQUIPA', 'SANTA ISABEL DE SIGUAS', 'AREQUIPA'),
('040118', 'AREQUIPA', 'AREQUIPA', 'SANTA RITA DE SIGUAS', 'AREQUIPA'),
('040119', 'AREQUIPA', 'AREQUIPA', 'SOCABAYA', 'AREQUIPA'),
('040120', 'AREQUIPA', 'AREQUIPA', 'TIABAYA', 'AREQUIPA'),
('040121', 'AREQUIPA', 'AREQUIPA', 'UCHUMAYO', 'AREQUIPA'),
('040122', 'AREQUIPA', 'AREQUIPA', 'VITOR', 'AREQUIPA'),
('040123', 'AREQUIPA', 'AREQUIPA', 'YANAHUARA', 'AREQUIPA'),
('040124', 'AREQUIPA', 'AREQUIPA', 'YARABAMBA', 'AREQUIPA'),
('040125', 'AREQUIPA', 'AREQUIPA', 'YURA', 'AREQUIPA'),
('040126', 'AREQUIPA', 'AREQUIPA', 'MARIANO MELGAR', 'AREQUIPA'),
('040127', 'AREQUIPA', 'AREQUIPA', 'JACOBO HUNTER', 'AREQUIPA'),
('040128', 'AREQUIPA', 'AREQUIPA', 'ALTO SELVA ALEGRE', 'AREQUIPA'),
('040129', 'AREQUIPA', 'AREQUIPA', 'JOSE LUIS BUSTAMANTE Y RIVERO', 'AREQUIPA'),
('040201', 'AREQUIPA', 'CAYLLOMA', 'CHIVAY', 'AREQUIPA'),
('040202', 'AREQUIPA', 'CAYLLOMA', 'ACHOMA', 'AREQUIPA'),
('040203', 'AREQUIPA', 'CAYLLOMA', 'CABANACONDE', 'AREQUIPA'),
('040204', 'AREQUIPA', 'CAYLLOMA', 'CAYLLOMA', 'AREQUIPA'),
('040205', 'AREQUIPA', 'CAYLLOMA', 'CALLALLI', 'AREQUIPA'),
('040206', 'AREQUIPA', 'CAYLLOMA', 'COPORAQUE', 'AREQUIPA'),
('040207', 'AREQUIPA', 'CAYLLOMA', 'HUAMBO', 'AREQUIPA'),
('040208', 'AREQUIPA', 'CAYLLOMA', 'HUANCA', 'AREQUIPA'),
('040209', 'AREQUIPA', 'CAYLLOMA', 'ICHUPAMPA', 'AREQUIPA'),
('040210', 'AREQUIPA', 'CAYLLOMA', 'LARI', 'AREQUIPA'),
('040211', 'AREQUIPA', 'CAYLLOMA', 'LLUTA', 'AREQUIPA'),
('040212', 'AREQUIPA', 'CAYLLOMA', 'MACA', 'AREQUIPA'),
('040213', 'AREQUIPA', 'CAYLLOMA', 'MADRIGAL', 'AREQUIPA'),
('040214', 'AREQUIPA', 'CAYLLOMA', 'SAN ANTONIO DE CHUCA', 'AREQUIPA'),
('040215', 'AREQUIPA', 'CAYLLOMA', 'SIBAYO', 'AREQUIPA'),
('040216', 'AREQUIPA', 'CAYLLOMA', 'TAPAY', 'AREQUIPA'),
('040217', 'AREQUIPA', 'CAYLLOMA', 'TISCO', 'AREQUIPA'),
('040218', 'AREQUIPA', 'CAYLLOMA', 'TUTI', 'AREQUIPA'),
('040219', 'AREQUIPA', 'CAYLLOMA', 'YANQUE', 'AREQUIPA'),
('040220', 'AREQUIPA', 'CAYLLOMA', 'MAJES', 'AREQUIPA'),
('040301', 'AREQUIPA', 'CAMANA', 'CAMANA', 'AREQUIPA'),
('040302', 'AREQUIPA', 'CAMANA', 'JOSE MARIA QUIMPER', 'AREQUIPA'),
('040303', 'AREQUIPA', 'CAMANA', 'MARIANO NICOLAS VALCARCEL', 'AREQUIPA'),
('040304', 'AREQUIPA', 'CAMANA', 'MARISCAL CACERES', 'AREQUIPA'),
('040305', 'AREQUIPA', 'CAMANA', 'NICOLAS DE PIEROLA', 'AREQUIPA'),
('040306', 'AREQUIPA', 'CAMANA', 'OCOÑA', 'AREQUIPA'),
('040307', 'AREQUIPA', 'CAMANA', 'QUILCA', 'AREQUIPA'),
('040308', 'AREQUIPA', 'CAMANA', 'SAMUEL PASTOR', 'AREQUIPA'),
('040401', 'AREQUIPA', 'CARAVELI', 'CARAVELI', 'AREQUIPA'),
('040402', 'AREQUIPA', 'CARAVELI', 'ACARI', 'AREQUIPA'),
('040403', 'AREQUIPA', 'CARAVELI', 'ATICO', 'AREQUIPA'),
('040404', 'AREQUIPA', 'CARAVELI', 'ATIQUIPA', 'AREQUIPA'),
('040405', 'AREQUIPA', 'CARAVELI', 'BELLA UNION', 'AREQUIPA'),
('040406', 'AREQUIPA', 'CARAVELI', 'CAHUACHO', 'AREQUIPA'),
('040407', 'AREQUIPA', 'CARAVELI', 'CHALA', 'AREQUIPA'),
('040408', 'AREQUIPA', 'CARAVELI', 'CHAPARRA', 'AREQUIPA'),
('040409', 'AREQUIPA', 'CARAVELI', 'HUANUHUANU', 'AREQUIPA'),
('040410', 'AREQUIPA', 'CARAVELI', 'JAQUI', 'AREQUIPA'),
('040411', 'AREQUIPA', 'CARAVELI', 'LOMAS', 'AREQUIPA'),
('040412', 'AREQUIPA', 'CARAVELI', 'QUICACHA', 'AREQUIPA'),
('040413', 'AREQUIPA', 'CARAVELI', 'YAUCA', 'AREQUIPA'),
('040501', 'AREQUIPA', 'CASTILLA', 'APLAO', 'AREQUIPA'),
('040502', 'AREQUIPA', 'CASTILLA', 'ANDAGUA', 'AREQUIPA'),
('040503', 'AREQUIPA', 'CASTILLA', 'AYO', 'AREQUIPA'),
('040504', 'AREQUIPA', 'CASTILLA', 'CHACHAS', 'AREQUIPA'),
('040505', 'AREQUIPA', 'CASTILLA', 'CHILCAYMARCA', 'AREQUIPA'),
('040506', 'AREQUIPA', 'CASTILLA', 'CHOCO', 'AREQUIPA'),
('040507', 'AREQUIPA', 'CASTILLA', 'HUANCARQUI', 'AREQUIPA'),
('040508', 'AREQUIPA', 'CASTILLA', 'MACHAGUAY', 'AREQUIPA'),
('040509', 'AREQUIPA', 'CASTILLA', 'ORCOPAMPA', 'AREQUIPA'),
('040510', 'AREQUIPA', 'CASTILLA', 'PAMPACOLCA', 'AREQUIPA'),
('040511', 'AREQUIPA', 'CASTILLA', 'TIPAN', 'AREQUIPA'),
('040512', 'AREQUIPA', 'CASTILLA', 'URACA', 'AREQUIPA'),
('040513', 'AREQUIPA', 'CASTILLA', 'UÑON', 'AREQUIPA'),
('040514', 'AREQUIPA', 'CASTILLA', 'VIRACO', 'AREQUIPA'),
('040601', 'AREQUIPA', 'CONDESUYOS', 'CHUQUIBAMBA', 'AREQUIPA'),
('040602', 'AREQUIPA', 'CONDESUYOS', 'ANDARAY', 'AREQUIPA'),
('040603', 'AREQUIPA', 'CONDESUYOS', 'CAYARANI', 'AREQUIPA'),
('040604', 'AREQUIPA', 'CONDESUYOS', 'CHICHAS', 'AREQUIPA'),
('040605', 'AREQUIPA', 'CONDESUYOS', 'IRAY', 'AREQUIPA'),
('040606', 'AREQUIPA', 'CONDESUYOS', 'SALAMANCA', 'AREQUIPA'),
('040607', 'AREQUIPA', 'CONDESUYOS', 'YANAQUIHUA', 'AREQUIPA'),
('040608', 'AREQUIPA', 'CONDESUYOS', 'RIO GRANDE', 'AREQUIPA'),
('040701', 'AREQUIPA', 'ISLAY', 'MOLLENDO', 'AREQUIPA'),
('040702', 'AREQUIPA', 'ISLAY', 'COCACHACRA', 'AREQUIPA'),
('040703', 'AREQUIPA', 'ISLAY', 'DEAN VALDIVIA', 'AREQUIPA'),
('040704', 'AREQUIPA', 'ISLAY', 'ISLAY', 'AREQUIPA'),
('040705', 'AREQUIPA', 'ISLAY', 'MEJIA', 'AREQUIPA'),
('040706', 'AREQUIPA', 'ISLAY', 'PUNTA DE BOMBON', 'AREQUIPA'),
('040801', 'AREQUIPA', 'LA UNION', 'COTAHUASI', 'AREQUIPA'),
('040802', 'AREQUIPA', 'LA UNION', 'ALCA', 'AREQUIPA'),
('040803', 'AREQUIPA', 'LA UNION', 'CHARCANA', 'AREQUIPA'),
('040804', 'AREQUIPA', 'LA UNION', 'HUAYNACOTAS', 'AREQUIPA'),
('040805', 'AREQUIPA', 'LA UNION', 'PAMPAMARCA', 'AREQUIPA'),
('040806', 'AREQUIPA', 'LA UNION', 'PUYCA', 'AREQUIPA'),
('040807', 'AREQUIPA', 'LA UNION', 'QUECHUALLA', 'AREQUIPA'),
('040808', 'AREQUIPA', 'LA UNION', 'SAYLA', 'AREQUIPA'),
('040809', 'AREQUIPA', 'LA UNION', 'TAURIA', 'AREQUIPA'),
('040810', 'AREQUIPA', 'LA UNION', 'TOMEPAMPA', 'AREQUIPA'),
('040811', 'AREQUIPA', 'LA UNION', 'TORO', 'AREQUIPA'),
('050101', 'AYACUCHO', 'HUAMANGA', 'AYACUCHO', 'AYACUCHO'),
('050102', 'AYACUCHO', 'HUAMANGA', 'ACOS VINCHOS', 'AYACUCHO'),
('050103', 'AYACUCHO', 'HUAMANGA', 'CARMEN ALTO', 'AYACUCHO'),
('050104', 'AYACUCHO', 'HUAMANGA', 'CHIARA', 'AYACUCHO'),
('050105', 'AYACUCHO', 'HUAMANGA', 'QUINUA', 'AYACUCHO'),
('050106', 'AYACUCHO', 'HUAMANGA', 'SAN JOSE DE TICLLAS', 'AYACUCHO'),
('050107', 'AYACUCHO', 'HUAMANGA', 'SAN JUAN BAUTISTA', 'AYACUCHO'),
('050108', 'AYACUCHO', 'HUAMANGA', 'SANTIAGO DE PISCHA', 'AYACUCHO'),
('050109', 'AYACUCHO', 'HUAMANGA', 'VINCHOS', 'AYACUCHO'),
('050110', 'AYACUCHO', 'HUAMANGA', 'TAMBILLO', 'AYACUCHO'),
('050111', 'AYACUCHO', 'HUAMANGA', 'ACOCRO', 'AYACUCHO'),
('050112', 'AYACUCHO', 'HUAMANGA', 'SOCOS', 'AYACUCHO'),
('050113', 'AYACUCHO', 'HUAMANGA', 'OCROS', 'AYACUCHO'),
('050114', 'AYACUCHO', 'HUAMANGA', 'PACAYCASA', 'AYACUCHO'),
('050115', 'AYACUCHO', 'HUAMANGA', 'JESUS NAZARENO', 'AYACUCHO'),
('050116', 'AYACUCHO', 'HUAMANGA', 'ANDRES AVELINO CACERES DORREGARAY', 'AYACUCHO'),
('050201', 'AYACUCHO', 'CANGALLO', 'CANGALLO', 'AYACUCHO'),
('050204', 'AYACUCHO', 'CANGALLO', 'CHUSCHI', 'AYACUCHO'),
('050206', 'AYACUCHO', 'CANGALLO', 'LOS MOROCHUCOS', 'AYACUCHO'),
('050207', 'AYACUCHO', 'CANGALLO', 'PARAS', 'AYACUCHO'),
('050208', 'AYACUCHO', 'CANGALLO', 'TOTOS', 'AYACUCHO'),
('050211', 'AYACUCHO', 'CANGALLO', 'MARIA PARADO DE BELLIDO', 'AYACUCHO'),
('050301', 'AYACUCHO', 'HUANTA', 'HUANTA', 'AYACUCHO'),
('050302', 'AYACUCHO', 'HUANTA', 'AYAHUANCO', 'AYACUCHO'),
('050303', 'AYACUCHO', 'HUANTA', 'HUAMANGUILLA', 'AYACUCHO'),
('050304', 'AYACUCHO', 'HUANTA', 'IGUAIN', 'AYACUCHO'),
('050305', 'AYACUCHO', 'HUANTA', 'LURICOCHA', 'AYACUCHO'),
('050307', 'AYACUCHO', 'HUANTA', 'SANTILLANA', 'AYACUCHO'),
('050308', 'AYACUCHO', 'HUANTA', 'SIVIA', 'AYACUCHO'),
('050309', 'AYACUCHO', 'HUANTA', 'LLOCHEGUA', 'AYACUCHO'),
('050310', 'AYACUCHO', 'HUANTA', 'CANAYRE', 'AYACUCHO'),
('050311', 'AYACUCHO', 'HUANTA', 'UCHURACCAY', 'AYACUCHO'),
('050312', 'AYACUCHO', 'HUANTA', 'PUCACOLPA', 'AYACUCHO'),
('050313', 'AYACUCHO', 'HUANTA', 'CHACA', 'AYACUCHO'),
('050314', 'AYACUCHO', 'HUANTA', 'PUTIS', 'AYACUCHO'),
('050401', 'AYACUCHO', 'LA MAR', 'SAN MIGUEL', 'AYACUCHO'),
('050402', 'AYACUCHO', 'LA MAR', 'ANCO', 'AYACUCHO'),
('050403', 'AYACUCHO', 'LA MAR', 'AYNA', 'AYACUCHO'),
('050404', 'AYACUCHO', 'LA MAR', 'CHILCAS', 'AYACUCHO'),
('050405', 'AYACUCHO', 'LA MAR', 'CHUNGUI', 'AYACUCHO'),
('050406', 'AYACUCHO', 'LA MAR', 'TAMBO', 'AYACUCHO'),
('050407', 'AYACUCHO', 'LA MAR', 'LUIS CARRANZA', 'AYACUCHO'),
('050408', 'AYACUCHO', 'LA MAR', 'SANTA ROSA', 'AYACUCHO'),
('050409', 'AYACUCHO', 'LA MAR', 'SAMUGARI', 'AYACUCHO'),
('050410', 'AYACUCHO', 'LA MAR', 'ANCHIHUAY', 'AYACUCHO'),
('050411', 'AYACUCHO', 'LA MAR', 'ORONCCOY', 'AYACUCHO'),
('050412', 'AYACUCHO', 'LA MAR', 'UNION PROGRESO', 'AYACUCHO'),
('050413', 'AYACUCHO', 'LA MAR', 'PATIBAMBA', 'AYACUCHO'),
('050414', 'AYACUCHO', 'LA MAR', 'NINABAMBA', 'AYACUCHO'),
('050415', 'AYACUCHO', 'LA MAR', 'RIO MAGDALENA', 'AYACUCHO'),
('050501', 'AYACUCHO', 'LUCANAS', 'PUQUIO', 'AYACUCHO'),
('050502', 'AYACUCHO', 'LUCANAS', 'AUCARA', 'AYACUCHO'),
('050503', 'AYACUCHO', 'LUCANAS', 'CABANA', 'AYACUCHO'),
('050504', 'AYACUCHO', 'LUCANAS', 'CARMEN SALCEDO', 'AYACUCHO'),
('050506', 'AYACUCHO', 'LUCANAS', 'CHAVIÑA', 'AYACUCHO'),
('050508', 'AYACUCHO', 'LUCANAS', 'CHIPAO', 'AYACUCHO'),
('050510', 'AYACUCHO', 'LUCANAS', 'HUAC-HUAS', 'AYACUCHO'),
('050511', 'AYACUCHO', 'LUCANAS', 'LARAMATE', 'AYACUCHO'),
('050512', 'AYACUCHO', 'LUCANAS', 'LEONCIO PRADO', 'AYACUCHO'),
('050513', 'AYACUCHO', 'LUCANAS', 'LUCANAS', 'AYACUCHO'),
('050514', 'AYACUCHO', 'LUCANAS', 'LLAUTA', 'AYACUCHO'),
('050516', 'AYACUCHO', 'LUCANAS', 'OCAÑA', 'AYACUCHO'),
('050517', 'AYACUCHO', 'LUCANAS', 'OTOCA', 'AYACUCHO'),
('050520', 'AYACUCHO', 'LUCANAS', 'SANCOS', 'AYACUCHO'),
('050521', 'AYACUCHO', 'LUCANAS', 'SAN JUAN', 'AYACUCHO'),
('050522', 'AYACUCHO', 'LUCANAS', 'SAN PEDRO', 'AYACUCHO'),
('050524', 'AYACUCHO', 'LUCANAS', 'SANTA ANA DE HUAYCAHUACHO', 'AYACUCHO'),
('050525', 'AYACUCHO', 'LUCANAS', 'SANTA LUCIA', 'AYACUCHO'),
('050529', 'AYACUCHO', 'LUCANAS', 'SAISA', 'AYACUCHO'),
('050531', 'AYACUCHO', 'LUCANAS', 'SAN PEDRO DE PALCO', 'AYACUCHO'),
('050532', 'AYACUCHO', 'LUCANAS', 'SAN CRISTOBAL', 'AYACUCHO'),
('050601', 'AYACUCHO', 'PARINACOCHAS', 'CORACORA', 'AYACUCHO'),
('050604', 'AYACUCHO', 'PARINACOCHAS', 'CORONEL CASTAÑEDA', 'AYACUCHO'),
('050605', 'AYACUCHO', 'PARINACOCHAS', 'CHUMPI', 'AYACUCHO'),
('050608', 'AYACUCHO', 'PARINACOCHAS', 'PACAPAUSA', 'AYACUCHO'),
('050611', 'AYACUCHO', 'PARINACOCHAS', 'PULLO', 'AYACUCHO'),
('050612', 'AYACUCHO', 'PARINACOCHAS', 'PUYUSCA', 'AYACUCHO'),
('050615', 'AYACUCHO', 'PARINACOCHAS', 'SAN FRANCISCO DE RAVACAYCO', 'AYACUCHO'),
('050616', 'AYACUCHO', 'PARINACOCHAS', 'UPAHUACHO', 'AYACUCHO'),
('050701', 'AYACUCHO', 'VICTOR FAJARDO', 'HUANCAPI', 'AYACUCHO'),
('050702', 'AYACUCHO', 'VICTOR FAJARDO', 'ALCAMENCA', 'AYACUCHO'),
('050703', 'AYACUCHO', 'VICTOR FAJARDO', 'APONGO', 'AYACUCHO'),
('050704', 'AYACUCHO', 'VICTOR FAJARDO', 'CANARIA', 'AYACUCHO'),
('050706', 'AYACUCHO', 'VICTOR FAJARDO', 'CAYARA', 'AYACUCHO'),
('050707', 'AYACUCHO', 'VICTOR FAJARDO', 'COLCA', 'AYACUCHO'),
('050708', 'AYACUCHO', 'VICTOR FAJARDO', 'HUAYA', 'AYACUCHO'),
('050709', 'AYACUCHO', 'VICTOR FAJARDO', 'HUAMANQUIQUIA', 'AYACUCHO'),
('050710', 'AYACUCHO', 'VICTOR FAJARDO', 'HUANCARAYLLA', 'AYACUCHO'),
('050713', 'AYACUCHO', 'VICTOR FAJARDO', 'SARHUA', 'AYACUCHO'),
('050714', 'AYACUCHO', 'VICTOR FAJARDO', 'VILCANCHOS', 'AYACUCHO'),
('050715', 'AYACUCHO', 'VICTOR FAJARDO', 'ASQUIPATA', 'AYACUCHO'),
('050801', 'AYACUCHO', 'HUANCA SANCOS', 'SANCOS', 'AYACUCHO'),
('050802', 'AYACUCHO', 'HUANCA SANCOS', 'SACSAMARCA', 'AYACUCHO'),
('050803', 'AYACUCHO', 'HUANCA SANCOS', 'SANTIAGO DE LUCANAMARCA', 'AYACUCHO'),
('050804', 'AYACUCHO', 'HUANCA SANCOS', 'CARAPO', 'AYACUCHO'),
('050901', 'AYACUCHO', 'VILCAS HUAMAN', 'VILCAS HUAMAN', 'AYACUCHO'),
('050902', 'AYACUCHO', 'VILCAS HUAMAN', 'VISCHONGO', 'AYACUCHO'),
('050903', 'AYACUCHO', 'VILCAS HUAMAN', 'ACCOMARCA', 'AYACUCHO'),
('050904', 'AYACUCHO', 'VILCAS HUAMAN', 'CARHUANCA', 'AYACUCHO'),
('050905', 'AYACUCHO', 'VILCAS HUAMAN', 'CONCEPCION', 'AYACUCHO'),
('050906', 'AYACUCHO', 'VILCAS HUAMAN', 'HUAMBALPA', 'AYACUCHO'),
('050907', 'AYACUCHO', 'VILCAS HUAMAN', 'SAURAMA', 'AYACUCHO'),
('050908', 'AYACUCHO', 'VILCAS HUAMAN', 'INDEPENDENCIA', 'AYACUCHO'),
('051001', 'AYACUCHO', 'PAUCAR DEL SARA SARA', 'PAUSA', 'AYACUCHO'),
('051002', 'AYACUCHO', 'PAUCAR DEL SARA SARA', 'COLTA', 'AYACUCHO'),
('051003', 'AYACUCHO', 'PAUCAR DEL SARA SARA', 'CORCULLA', 'AYACUCHO'),
('051004', 'AYACUCHO', 'PAUCAR DEL SARA SARA', 'LAMPA', 'AYACUCHO'),
('051005', 'AYACUCHO', 'PAUCAR DEL SARA SARA', 'MARCABAMBA', 'AYACUCHO'),
('051006', 'AYACUCHO', 'PAUCAR DEL SARA SARA', 'OYOLO', 'AYACUCHO'),
('051007', 'AYACUCHO', 'PAUCAR DEL SARA SARA', 'PARARCA', 'AYACUCHO'),
('051008', 'AYACUCHO', 'PAUCAR DEL SARA SARA', 'SAN JAVIER DE ALPABAMBA', 'AYACUCHO'),
('051009', 'AYACUCHO', 'PAUCAR DEL SARA SARA', 'SAN JOSE DE USHUA', 'AYACUCHO'),
('051010', 'AYACUCHO', 'PAUCAR DEL SARA SARA', 'SARA SARA', 'AYACUCHO'),
('051101', 'AYACUCHO', 'SUCRE', 'QUEROBAMBA', 'AYACUCHO'),
('051102', 'AYACUCHO', 'SUCRE', 'BELEN', 'AYACUCHO'),
('051103', 'AYACUCHO', 'SUCRE', 'CHALCOS', 'AYACUCHO'),
('051104', 'AYACUCHO', 'SUCRE', 'SAN SALVADOR DE QUIJE', 'AYACUCHO'),
('051105', 'AYACUCHO', 'SUCRE', 'PAICO', 'AYACUCHO'),
('051106', 'AYACUCHO', 'SUCRE', 'SANTIAGO DE PAUCARAY', 'AYACUCHO'),
('051107', 'AYACUCHO', 'SUCRE', 'SAN PEDRO DE LARCAY', 'AYACUCHO'),
('051108', 'AYACUCHO', 'SUCRE', 'SORAS', 'AYACUCHO'),
('051109', 'AYACUCHO', 'SUCRE', 'HUACAÑA', 'AYACUCHO'),
('051110', 'AYACUCHO', 'SUCRE', 'CHILCAYOC', 'AYACUCHO'),
('051111', 'AYACUCHO', 'SUCRE', 'MORCOLLA', 'AYACUCHO'),
('060101', 'CAJAMARCA', 'CAJAMARCA', 'CAJAMARCA', 'CAJAMARCA'),
('060102', 'CAJAMARCA', 'CAJAMARCA', 'ASUNCION', 'CAJAMARCA'),
('060103', 'CAJAMARCA', 'CAJAMARCA', 'COSPAN', 'CAJAMARCA'),
('060104', 'CAJAMARCA', 'CAJAMARCA', 'CHETILLA', 'CAJAMARCA'),
('060105', 'CAJAMARCA', 'CAJAMARCA', 'ENCAÑADA', 'CAJAMARCA'),
('060106', 'CAJAMARCA', 'CAJAMARCA', 'JESUS', 'CAJAMARCA'),
('060107', 'CAJAMARCA', 'CAJAMARCA', 'LOS BAÑOS DEL INCA', 'CAJAMARCA'),
('060108', 'CAJAMARCA', 'CAJAMARCA', 'LLACANORA', 'CAJAMARCA'),
('060109', 'CAJAMARCA', 'CAJAMARCA', 'MAGDALENA', 'CAJAMARCA'),
('060110', 'CAJAMARCA', 'CAJAMARCA', 'MATARA', 'CAJAMARCA'),
('060111', 'CAJAMARCA', 'CAJAMARCA', 'NAMORA', 'CAJAMARCA'),
('060112', 'CAJAMARCA', 'CAJAMARCA', 'SAN JUAN', 'CAJAMARCA'),
('060201', 'CAJAMARCA', 'CAJABAMBA', 'CAJABAMBA', 'CAJAMARCA'),
('060202', 'CAJAMARCA', 'CAJABAMBA', 'CACHACHI', 'CAJAMARCA'),
('060203', 'CAJAMARCA', 'CAJABAMBA', 'CONDEBAMBA', 'CAJAMARCA'),
('060205', 'CAJAMARCA', 'CAJABAMBA', 'SITACOCHA', 'CAJAMARCA'),
('060301', 'CAJAMARCA', 'CELENDIN', 'CELENDIN', 'CAJAMARCA'),
('060302', 'CAJAMARCA', 'CELENDIN', 'CORTEGANA', 'CAJAMARCA'),
('060303', 'CAJAMARCA', 'CELENDIN', 'CHUMUCH', 'CAJAMARCA'),
('060304', 'CAJAMARCA', 'CELENDIN', 'HUASMIN', 'CAJAMARCA'),
('060305', 'CAJAMARCA', 'CELENDIN', 'JORGE CHAVEZ', 'CAJAMARCA'),
('060306', 'CAJAMARCA', 'CELENDIN', 'JOSE GALVEZ', 'CAJAMARCA'),
('060307', 'CAJAMARCA', 'CELENDIN', 'MIGUEL IGLESIAS', 'CAJAMARCA'),
('060308', 'CAJAMARCA', 'CELENDIN', 'OXAMARCA', 'CAJAMARCA'),
('060309', 'CAJAMARCA', 'CELENDIN', 'SOROCHUCO', 'CAJAMARCA'),
('060310', 'CAJAMARCA', 'CELENDIN', 'SUCRE', 'CAJAMARCA'),
('060311', 'CAJAMARCA', 'CELENDIN', 'UTCO', 'CAJAMARCA'),
('060312', 'CAJAMARCA', 'CELENDIN', 'LA LIBERTAD DE PALLAN', 'CAJAMARCA'),
('060401', 'CAJAMARCA', 'CONTUMAZA', 'CONTUMAZA', 'CAJAMARCA'),
('060403', 'CAJAMARCA', 'CONTUMAZA', 'CHILETE', 'CAJAMARCA'),
('060404', 'CAJAMARCA', 'CONTUMAZA', 'GUZMANGO', 'CAJAMARCA'),
('060405', 'CAJAMARCA', 'CONTUMAZA', 'SAN BENITO', 'CAJAMARCA'),
('060406', 'CAJAMARCA', 'CONTUMAZA', 'CUPISNIQUE', 'CAJAMARCA'),
('060407', 'CAJAMARCA', 'CONTUMAZA', 'TANTARICA', 'CAJAMARCA'),
('060408', 'CAJAMARCA', 'CONTUMAZA', 'YONAN', 'CAJAMARCA'),
('060409', 'CAJAMARCA', 'CONTUMAZA', 'SANTA CRUZ DE TOLEDO', 'CAJAMARCA'),
('060501', 'CAJAMARCA', 'CUTERVO', 'CUTERVO', 'CAJAMARCA'),
('060502', 'CAJAMARCA', 'CUTERVO', 'CALLAYUC', 'CAJAMARCA'),
('060503', 'CAJAMARCA', 'CUTERVO', 'CUJILLO', 'CAJAMARCA'),
('060504', 'CAJAMARCA', 'CUTERVO', 'CHOROS', 'CAJAMARCA'),
('060505', 'CAJAMARCA', 'CUTERVO', 'LA RAMADA', 'CAJAMARCA'),
('060506', 'CAJAMARCA', 'CUTERVO', 'PIMPINGOS', 'CAJAMARCA'),
('060507', 'CAJAMARCA', 'CUTERVO', 'QUEROCOTILLO', 'CAJAMARCA'),
('060508', 'CAJAMARCA', 'CUTERVO', 'SAN ANDRES DE CUTERVO', 'CAJAMARCA'),
('060509', 'CAJAMARCA', 'CUTERVO', 'SAN JUAN DE CUTERVO', 'CAJAMARCA'),
('060510', 'CAJAMARCA', 'CUTERVO', 'SAN LUIS DE LUCMA', 'CAJAMARCA'),
('060511', 'CAJAMARCA', 'CUTERVO', 'SANTA CRUZ', 'CAJAMARCA'),
('060512', 'CAJAMARCA', 'CUTERVO', 'SANTO DOMINGO DE LA CAPILLA', 'CAJAMARCA'),
('060513', 'CAJAMARCA', 'CUTERVO', 'SANTO TOMAS', 'CAJAMARCA'),
('060514', 'CAJAMARCA', 'CUTERVO', 'SOCOTA', 'CAJAMARCA'),
('060515', 'CAJAMARCA', 'CUTERVO', 'TORIBIO CASANOVA', 'CAJAMARCA'),
('060601', 'CAJAMARCA', 'CHOTA', 'CHOTA', 'CAJAMARCA'),
('060602', 'CAJAMARCA', 'CHOTA', 'ANGUIA', 'CAJAMARCA'),
('060603', 'CAJAMARCA', 'CHOTA', 'COCHABAMBA', 'CAJAMARCA'),
('060604', 'CAJAMARCA', 'CHOTA', 'CONCHAN', 'CAJAMARCA'),
('060605', 'CAJAMARCA', 'CHOTA', 'CHADIN', 'CAJAMARCA'),
('060606', 'CAJAMARCA', 'CHOTA', 'CHIGUIRIP', 'CAJAMARCA'),
('060607', 'CAJAMARCA', 'CHOTA', 'CHIMBAN', 'CAJAMARCA'),
('060608', 'CAJAMARCA', 'CHOTA', 'HUAMBOS', 'CAJAMARCA'),
('060609', 'CAJAMARCA', 'CHOTA', 'LAJAS', 'CAJAMARCA'),
('060610', 'CAJAMARCA', 'CHOTA', 'LLAMA', 'CAJAMARCA'),
('060611', 'CAJAMARCA', 'CHOTA', 'MIRACOSTA', 'CAJAMARCA'),
('060612', 'CAJAMARCA', 'CHOTA', 'PACCHA', 'CAJAMARCA'),
('060613', 'CAJAMARCA', 'CHOTA', 'PION', 'CAJAMARCA'),
('060614', 'CAJAMARCA', 'CHOTA', 'QUEROCOTO', 'CAJAMARCA'),
('060615', 'CAJAMARCA', 'CHOTA', 'TACABAMBA', 'CAJAMARCA'),
('060616', 'CAJAMARCA', 'CHOTA', 'TOCMOCHE', 'CAJAMARCA'),
('060617', 'CAJAMARCA', 'CHOTA', 'SAN JUAN DE LICUPIS', 'CAJAMARCA'),
('060618', 'CAJAMARCA', 'CHOTA', 'CHOROPAMPA', 'CAJAMARCA'),
('060619', 'CAJAMARCA', 'CHOTA', 'CHALAMARCA', 'CAJAMARCA'),
('060701', 'CAJAMARCA', 'HUALGAYOC', 'BAMBAMARCA', 'CAJAMARCA'),
('060702', 'CAJAMARCA', 'HUALGAYOC', 'CHUGUR', 'CAJAMARCA'),
('060703', 'CAJAMARCA', 'HUALGAYOC', 'HUALGAYOC', 'CAJAMARCA'),
('060801', 'CAJAMARCA', 'JAEN', 'JAEN', 'CAJAMARCA'),
('060802', 'CAJAMARCA', 'JAEN', 'BELLAVISTA', 'CAJAMARCA'),
('060803', 'CAJAMARCA', 'JAEN', 'COLASAY', 'CAJAMARCA'),
('060804', 'CAJAMARCA', 'JAEN', 'CHONTALI', 'CAJAMARCA'),
('060805', 'CAJAMARCA', 'JAEN', 'POMAHUACA', 'CAJAMARCA'),
('060806', 'CAJAMARCA', 'JAEN', 'PUCARA', 'CAJAMARCA'),
('060807', 'CAJAMARCA', 'JAEN', 'SALLIQUE', 'CAJAMARCA'),
('060808', 'CAJAMARCA', 'JAEN', 'SAN FELIPE', 'CAJAMARCA'),
('060809', 'CAJAMARCA', 'JAEN', 'SAN JOSE DEL ALTO', 'CAJAMARCA'),
('060810', 'CAJAMARCA', 'JAEN', 'SANTA ROSA', 'CAJAMARCA'),
('060811', 'CAJAMARCA', 'JAEN', 'LAS PIRIAS', 'CAJAMARCA'),
('060812', 'CAJAMARCA', 'JAEN', 'HUABAL', 'CAJAMARCA'),
('060901', 'CAJAMARCA', 'SANTA CRUZ', 'SANTA CRUZ', 'CAJAMARCA'),
('060902', 'CAJAMARCA', 'SANTA CRUZ', 'CATACHE', 'CAJAMARCA'),
('060903', 'CAJAMARCA', 'SANTA CRUZ', 'CHANCAYBAÑOS', 'CAJAMARCA'),
('060904', 'CAJAMARCA', 'SANTA CRUZ', 'LA ESPERANZA', 'CAJAMARCA'),
('060905', 'CAJAMARCA', 'SANTA CRUZ', 'NINABAMBA', 'CAJAMARCA'),
('060906', 'CAJAMARCA', 'SANTA CRUZ', 'PULAN', 'CAJAMARCA'),
('060907', 'CAJAMARCA', 'SANTA CRUZ', 'SEXI', 'CAJAMARCA'),
('060908', 'CAJAMARCA', 'SANTA CRUZ', 'UTICYACU', 'CAJAMARCA'),
('060909', 'CAJAMARCA', 'SANTA CRUZ', 'YAUYUCAN', 'CAJAMARCA'),
('060910', 'CAJAMARCA', 'SANTA CRUZ', 'ANDABAMBA', 'CAJAMARCA'),
('060911', 'CAJAMARCA', 'SANTA CRUZ', 'SAUCEPAMPA', 'CAJAMARCA'),
('061001', 'CAJAMARCA', 'SAN MIGUEL', 'SAN MIGUEL', 'CAJAMARCA'),
('061002', 'CAJAMARCA', 'SAN MIGUEL', 'CALQUIS', 'CAJAMARCA'),
('061003', 'CAJAMARCA', 'SAN MIGUEL', 'LA FLORIDA', 'CAJAMARCA'),
('061004', 'CAJAMARCA', 'SAN MIGUEL', 'LLAPA', 'CAJAMARCA'),
('061005', 'CAJAMARCA', 'SAN MIGUEL', 'NANCHOC', 'CAJAMARCA'),
('061006', 'CAJAMARCA', 'SAN MIGUEL', 'NIEPOS', 'CAJAMARCA'),
('061007', 'CAJAMARCA', 'SAN MIGUEL', 'SAN GREGORIO', 'CAJAMARCA'),
('061008', 'CAJAMARCA', 'SAN MIGUEL', 'SAN SILVESTRE DE COCHAN', 'CAJAMARCA'),
('061009', 'CAJAMARCA', 'SAN MIGUEL', 'EL PRADO', 'CAJAMARCA'),
('061010', 'CAJAMARCA', 'SAN MIGUEL', 'UNION AGUA BLANCA', 'CAJAMARCA'),
('061011', 'CAJAMARCA', 'SAN MIGUEL', 'TONGOD', 'CAJAMARCA'),
('061012', 'CAJAMARCA', 'SAN MIGUEL', 'CATILLUC', 'CAJAMARCA'),
('061013', 'CAJAMARCA', 'SAN MIGUEL', 'BOLIVAR', 'CAJAMARCA'),
('061101', 'CAJAMARCA', 'SAN IGNACIO', 'SAN IGNACIO', 'CAJAMARCA'),
('061102', 'CAJAMARCA', 'SAN IGNACIO', 'CHIRINOS', 'CAJAMARCA'),
('061103', 'CAJAMARCA', 'SAN IGNACIO', 'HUARANGO', 'CAJAMARCA'),
('061104', 'CAJAMARCA', 'SAN IGNACIO', 'NAMBALLE', 'CAJAMARCA'),
('061105', 'CAJAMARCA', 'SAN IGNACIO', 'LA COIPA', 'CAJAMARCA'),
('061106', 'CAJAMARCA', 'SAN IGNACIO', 'SAN JOSE DE LOURDES', 'CAJAMARCA'),
('061107', 'CAJAMARCA', 'SAN IGNACIO', 'TABACONAS', 'CAJAMARCA'),
('061201', 'CAJAMARCA', 'SAN MARCOS', 'PEDRO GALVEZ', 'CAJAMARCA'),
('061202', 'CAJAMARCA', 'SAN MARCOS', 'ICHOCAN', 'CAJAMARCA'),
('061203', 'CAJAMARCA', 'SAN MARCOS', 'GREGORIO PITA', 'CAJAMARCA'),
('061204', 'CAJAMARCA', 'SAN MARCOS', 'JOSE MANUEL QUIROZ', 'CAJAMARCA'),
('061205', 'CAJAMARCA', 'SAN MARCOS', 'EDUARDO VILLANUEVA', 'CAJAMARCA'),
('061206', 'CAJAMARCA', 'SAN MARCOS', 'JOSE SABOGAL', 'CAJAMARCA'),
('061207', 'CAJAMARCA', 'SAN MARCOS', 'CHANCAY', 'CAJAMARCA'),
('061301', 'CAJAMARCA', 'SAN PABLO', 'SAN PABLO', 'CAJAMARCA'),
('061302', 'CAJAMARCA', 'SAN PABLO', 'SAN BERNARDINO', 'CAJAMARCA'),
('061303', 'CAJAMARCA', 'SAN PABLO', 'SAN LUIS', 'CAJAMARCA'),
('061304', 'CAJAMARCA', 'SAN PABLO', 'TUMBADEN', 'CAJAMARCA'),
('070101', 'CUSCO', 'CUSCO', 'CUSCO', 'CUSCO'),
('070102', 'CUSCO', 'CUSCO', 'CCORCA', 'CUSCO'),
('070103', 'CUSCO', 'CUSCO', 'POROY', 'CUSCO'),
('070104', 'CUSCO', 'CUSCO', 'SAN JERONIMO', 'CUSCO'),
('070105', 'CUSCO', 'CUSCO', 'SAN SEBASTIAN', 'CUSCO'),
('070106', 'CUSCO', 'CUSCO', 'SANTIAGO', 'CUSCO'),
('070107', 'CUSCO', 'CUSCO', 'SAYLLA', 'CUSCO'),
('070108', 'CUSCO', 'CUSCO', 'WANCHAQ', 'CUSCO'),
('070201', 'CUSCO', 'ACOMAYO', 'ACOMAYO', 'CUSCO'),
('070202', 'CUSCO', 'ACOMAYO', 'ACOPIA', 'CUSCO'),
('070203', 'CUSCO', 'ACOMAYO', 'ACOS', 'CUSCO'),
('070204', 'CUSCO', 'ACOMAYO', 'POMACANCHI', 'CUSCO'),
('070205', 'CUSCO', 'ACOMAYO', 'RONDOCAN', 'CUSCO'),
('070206', 'CUSCO', 'ACOMAYO', 'SANGARARA', 'CUSCO'),
('070207', 'CUSCO', 'ACOMAYO', 'MOSOC LLACTA', 'CUSCO'),
('070301', 'CUSCO', 'ANTA', 'ANTA', 'CUSCO'),
('070302', 'CUSCO', 'ANTA', 'CHINCHAYPUJIO', 'CUSCO'),
('070303', 'CUSCO', 'ANTA', 'HUAROCONDO', 'CUSCO'),
('070304', 'CUSCO', 'ANTA', 'LIMATAMBO', 'CUSCO'),
('070305', 'CUSCO', 'ANTA', 'MOLLEPATA', 'CUSCO'),
('070306', 'CUSCO', 'ANTA', 'PUCYURA', 'CUSCO'),
('070307', 'CUSCO', 'ANTA', 'ZURITE', 'CUSCO'),
('070308', 'CUSCO', 'ANTA', 'CACHIMAYO', 'CUSCO'),
('070309', 'CUSCO', 'ANTA', 'ANCAHUASI', 'CUSCO'),
('070401', 'CUSCO', 'CALCA', 'CALCA', 'CUSCO'),
('070402', 'CUSCO', 'CALCA', 'COYA', 'CUSCO'),
('070403', 'CUSCO', 'CALCA', 'LAMAY', 'CUSCO'),
('070404', 'CUSCO', 'CALCA', 'LARES', 'CUSCO'),
('070405', 'CUSCO', 'CALCA', 'PISAC', 'CUSCO'),
('070406', 'CUSCO', 'CALCA', 'SAN SALVADOR', 'CUSCO'),
('070407', 'CUSCO', 'CALCA', 'TARAY', 'CUSCO'),
('070408', 'CUSCO', 'CALCA', 'YANATILE', 'CUSCO'),
('070501', 'CUSCO', 'CANAS', 'YANAOCA', 'CUSCO'),
('070502', 'CUSCO', 'CANAS', 'CHECCA', 'CUSCO'),
('070503', 'CUSCO', 'CANAS', 'KUNTURKANKI', 'CUSCO'),
('070504', 'CUSCO', 'CANAS', 'LANGUI', 'CUSCO'),
('070505', 'CUSCO', 'CANAS', 'LAYO', 'CUSCO'),
('070506', 'CUSCO', 'CANAS', 'PAMPAMARCA', 'CUSCO'),
('070507', 'CUSCO', 'CANAS', 'QUEHUE', 'CUSCO'),
('070508', 'CUSCO', 'CANAS', 'TUPAC AMARU', 'CUSCO'),
('070601', 'CUSCO', 'CANCHIS', 'SICUANI', 'CUSCO'),
('070602', 'CUSCO', 'CANCHIS', 'COMBAPATA', 'CUSCO'),
('070603', 'CUSCO', 'CANCHIS', 'CHECACUPE', 'CUSCO'),
('070604', 'CUSCO', 'CANCHIS', 'MARANGANI', 'CUSCO'),
('070605', 'CUSCO', 'CANCHIS', 'PITUMARCA', 'CUSCO'),
('070606', 'CUSCO', 'CANCHIS', 'SAN PABLO', 'CUSCO'),
('070607', 'CUSCO', 'CANCHIS', 'SAN PEDRO', 'CUSCO'),
('070608', 'CUSCO', 'CANCHIS', 'TINTA', 'CUSCO'),
('070701', 'CUSCO', 'CHUMBIVILCAS', 'SANTO TOMAS', 'CUSCO'),
('070702', 'CUSCO', 'CHUMBIVILCAS', 'CAPACMARCA', 'CUSCO'),
('070703', 'CUSCO', 'CHUMBIVILCAS', 'COLQUEMARCA', 'CUSCO'),
('070704', 'CUSCO', 'CHUMBIVILCAS', 'CHAMACA', 'CUSCO'),
('070705', 'CUSCO', 'CHUMBIVILCAS', 'LIVITACA', 'CUSCO'),
('070706', 'CUSCO', 'CHUMBIVILCAS', 'LLUSCO', 'CUSCO'),
('070707', 'CUSCO', 'CHUMBIVILCAS', 'QUIÑOTA', 'CUSCO'),
('070708', 'CUSCO', 'CHUMBIVILCAS', 'VELILLE', 'CUSCO'),
('070801', 'CUSCO', 'ESPINAR', 'ESPINAR', 'CUSCO'),
('070802', 'CUSCO', 'ESPINAR', 'CONDOROMA', 'CUSCO'),
('070803', 'CUSCO', 'ESPINAR', 'COPORAQUE', 'CUSCO'),
('070804', 'CUSCO', 'ESPINAR', 'OCORURO', 'CUSCO'),
('070805', 'CUSCO', 'ESPINAR', 'PALLPATA', 'CUSCO'),
('070806', 'CUSCO', 'ESPINAR', 'PICHIGUA', 'CUSCO'),
('070807', 'CUSCO', 'ESPINAR', 'SUYCKUTAMBO', 'CUSCO'),
('070808', 'CUSCO', 'ESPINAR', 'ALTO PICHIGUA', 'CUSCO'),
('070901', 'CUSCO', 'LA CONVENCION', 'SANTA ANA', 'CUSCO'),
('070902', 'CUSCO', 'LA CONVENCION', 'ECHARATE', 'CUSCO'),
('070903', 'CUSCO', 'LA CONVENCION', 'HUAYOPATA', 'CUSCO'),
('070904', 'CUSCO', 'LA CONVENCION', 'MARANURA', 'CUSCO'),
('070905', 'CUSCO', 'LA CONVENCION', 'OCOBAMBA', 'CUSCO'),
('070906', 'CUSCO', 'LA CONVENCION', 'SANTA TERESA', 'CUSCO'),
('070907', 'CUSCO', 'LA CONVENCION', 'VILCABAMBA', 'CUSCO'),
('070908', 'CUSCO', 'LA CONVENCION', 'QUELLOUNO', 'CUSCO'),
('070909', 'CUSCO', 'LA CONVENCION', 'QUIMBIRI', 'CUSCO'),
('070910', 'CUSCO', 'LA CONVENCION', 'PICHARI', 'CUSCO'),
('070911', 'CUSCO', 'LA CONVENCION', 'INKAWASI', 'CUSCO'),
('070912', 'CUSCO', 'LA CONVENCION', 'VILLA VIRGEN', 'CUSCO'),
('070913', 'CUSCO', 'LA CONVENCION', 'VILLA KINTIARINA', 'CUSCO'),
('070915', 'CUSCO', 'LA CONVENCION', 'MEGANTONI', 'CUSCO'),
('070916', 'CUSCO', 'LA CONVENCION', 'KUMPIRUSHIATO', 'CUSCO'),
('070917', 'CUSCO', 'LA CONVENCION', 'CIELO PUNCO', 'CUSCO'),
('070918', 'CUSCO', 'LA CONVENCION', 'MANITEA', 'CUSCO'),
('070919', 'CUSCO', 'LA CONVENCION', 'UNION ASHÁNINKA', 'CUSCO'),
('071001', 'CUSCO', 'PARURO', 'PARURO', 'CUSCO'),
('071002', 'CUSCO', 'PARURO', 'ACCHA', 'CUSCO'),
('071003', 'CUSCO', 'PARURO', 'CCAPI', 'CUSCO'),
('071004', 'CUSCO', 'PARURO', 'COLCHA', 'CUSCO'),
('071005', 'CUSCO', 'PARURO', 'HUANOQUITE', 'CUSCO'),
('071006', 'CUSCO', 'PARURO', 'OMACHA', 'CUSCO'),
('071007', 'CUSCO', 'PARURO', 'YAURISQUE', 'CUSCO'),
('071008', 'CUSCO', 'PARURO', 'PACCARITAMBO', 'CUSCO'),
('071009', 'CUSCO', 'PARURO', 'PILLPINTO', 'CUSCO'),
('071101', 'CUSCO', 'PAUCARTAMBO', 'PAUCARTAMBO', 'CUSCO'),
('071102', 'CUSCO', 'PAUCARTAMBO', 'CAICAY', 'CUSCO'),
('071103', 'CUSCO', 'PAUCARTAMBO', 'COLQUEPATA', 'CUSCO'),
('071104', 'CUSCO', 'PAUCARTAMBO', 'CHALLABAMBA', 'CUSCO'),
('071105', 'CUSCO', 'PAUCARTAMBO', 'KOSÑIPATA', 'CUSCO'),
('071106', 'CUSCO', 'PAUCARTAMBO', 'HUANCARANI', 'CUSCO'),
('071201', 'CUSCO', 'QUISPICANCHI', 'URCOS', 'CUSCO'),
('071202', 'CUSCO', 'QUISPICANCHI', 'ANDAHUAYLILLAS', 'CUSCO'),
('071203', 'CUSCO', 'QUISPICANCHI', 'CAMANTI', 'CUSCO'),
('071204', 'CUSCO', 'QUISPICANCHI', 'CCARHUAYO', 'CUSCO'),
('071205', 'CUSCO', 'QUISPICANCHI', 'CCATCA', 'CUSCO'),
('071206', 'CUSCO', 'QUISPICANCHI', 'CUSIPATA', 'CUSCO'),
('071207', 'CUSCO', 'QUISPICANCHI', 'HUARO', 'CUSCO'),
('071208', 'CUSCO', 'QUISPICANCHI', 'LUCRE', 'CUSCO'),
('071209', 'CUSCO', 'QUISPICANCHI', 'MARCAPATA', 'CUSCO'),
('071210', 'CUSCO', 'QUISPICANCHI', 'OCONGATE', 'CUSCO'),
('071211', 'CUSCO', 'QUISPICANCHI', 'OROPESA', 'CUSCO'),
('071212', 'CUSCO', 'QUISPICANCHI', 'QUIQUIJANA', 'CUSCO'),
('071301', 'CUSCO', 'URUBAMBA', 'URUBAMBA', 'CUSCO'),
('071302', 'CUSCO', 'URUBAMBA', 'CHINCHERO', 'CUSCO'),
('071303', 'CUSCO', 'URUBAMBA', 'HUAYLLABAMBA', 'CUSCO'),
('071304', 'CUSCO', 'URUBAMBA', 'MACHUPICCHU', 'CUSCO'),
('071305', 'CUSCO', 'URUBAMBA', 'MARAS', 'CUSCO'),
('071306', 'CUSCO', 'URUBAMBA', 'OLLANTAYTAMBO', 'CUSCO'),
('071307', 'CUSCO', 'URUBAMBA', 'YUCAY', 'CUSCO'),
('080101', 'HUANCAVELICA', 'HUANCAVELICA', 'HUANCAVELICA', 'HUANCAVELICA'),
('080102', 'HUANCAVELICA', 'HUANCAVELICA', 'ACOBAMBILLA', 'HUANCAVELICA'),
('080103', 'HUANCAVELICA', 'HUANCAVELICA', 'ACORIA', 'HUANCAVELICA'),
('080104', 'HUANCAVELICA', 'HUANCAVELICA', 'CONAYCA', 'HUANCAVELICA'),
('080105', 'HUANCAVELICA', 'HUANCAVELICA', 'CUENCA', 'HUANCAVELICA'),
('080106', 'HUANCAVELICA', 'HUANCAVELICA', 'HUACHOCOLPA', 'HUANCAVELICA'),
('080108', 'HUANCAVELICA', 'HUANCAVELICA', 'HUAYLLAHUARA', 'HUANCAVELICA'),
('080109', 'HUANCAVELICA', 'HUANCAVELICA', 'IZCUCHACA', 'HUANCAVELICA'),
('080110', 'HUANCAVELICA', 'HUANCAVELICA', 'LARIA', 'HUANCAVELICA'),
('080111', 'HUANCAVELICA', 'HUANCAVELICA', 'MANTA', 'HUANCAVELICA'),
('080112', 'HUANCAVELICA', 'HUANCAVELICA', 'MARISCAL CACERES', 'HUANCAVELICA'),
('080113', 'HUANCAVELICA', 'HUANCAVELICA', 'MOYA', 'HUANCAVELICA'),
('080114', 'HUANCAVELICA', 'HUANCAVELICA', 'NUEVO OCCORO', 'HUANCAVELICA'),
('080115', 'HUANCAVELICA', 'HUANCAVELICA', 'PALCA', 'HUANCAVELICA'),
('080116', 'HUANCAVELICA', 'HUANCAVELICA', 'PILCHACA', 'HUANCAVELICA'),
('080117', 'HUANCAVELICA', 'HUANCAVELICA', 'VILCA', 'HUANCAVELICA'),
('080118', 'HUANCAVELICA', 'HUANCAVELICA', 'YAULI', 'HUANCAVELICA'),
('080119', 'HUANCAVELICA', 'HUANCAVELICA', 'ASCENSION', 'HUANCAVELICA'),
('080120', 'HUANCAVELICA', 'HUANCAVELICA', 'HUANDO', 'HUANCAVELICA'),
('080201', 'HUANCAVELICA', 'ACOBAMBA', 'ACOBAMBA', 'HUANCAVELICA'),
('080202', 'HUANCAVELICA', 'ACOBAMBA', 'ANTA', 'HUANCAVELICA'),
('080203', 'HUANCAVELICA', 'ACOBAMBA', 'ANDABAMBA', 'HUANCAVELICA'),
('080204', 'HUANCAVELICA', 'ACOBAMBA', 'CAJA', 'HUANCAVELICA'),
('080205', 'HUANCAVELICA', 'ACOBAMBA', 'MARCAS', 'HUANCAVELICA'),
('080206', 'HUANCAVELICA', 'ACOBAMBA', 'PAUCARA', 'HUANCAVELICA'),
('080207', 'HUANCAVELICA', 'ACOBAMBA', 'POMACOCHA', 'HUANCAVELICA'),
('080208', 'HUANCAVELICA', 'ACOBAMBA', 'ROSARIO', 'HUANCAVELICA'),
('080301', 'HUANCAVELICA', 'ANGARAES', 'LIRCAY', 'HUANCAVELICA'),
('080302', 'HUANCAVELICA', 'ANGARAES', 'ANCHONGA', 'HUANCAVELICA'),
('080303', 'HUANCAVELICA', 'ANGARAES', 'CALLANMARCA', 'HUANCAVELICA'),
('080304', 'HUANCAVELICA', 'ANGARAES', 'CONGALLA', 'HUANCAVELICA'),
('080305', 'HUANCAVELICA', 'ANGARAES', 'CHINCHO', 'HUANCAVELICA'),
('080306', 'HUANCAVELICA', 'ANGARAES', 'HUAYLLAY GRANDE', 'HUANCAVELICA'),
('080307', 'HUANCAVELICA', 'ANGARAES', 'HUANCA-HUANCA', 'HUANCAVELICA'),
('080308', 'HUANCAVELICA', 'ANGARAES', 'JULCAMARCA', 'HUANCAVELICA'),
('080309', 'HUANCAVELICA', 'ANGARAES', 'SAN ANTONIO DE ANTAPARCO', 'HUANCAVELICA'),
('080310', 'HUANCAVELICA', 'ANGARAES', 'SANTO TOMAS DE PATA', 'HUANCAVELICA'),
('080311', 'HUANCAVELICA', 'ANGARAES', 'SECCLLA', 'HUANCAVELICA'),
('080312', 'HUANCAVELICA', 'ANGARAES', 'CCOCHACCASA', 'HUANCAVELICA'),
('080401', 'HUANCAVELICA', 'CASTROVIRREYNA', 'CASTROVIRREYNA', 'HUANCAVELICA');
INSERT INTO `tb_ubigeos` (`ubigeo_reniec`, `departamento`, `provincia`, `distrito`, `region`) VALUES
('080402', 'HUANCAVELICA', 'CASTROVIRREYNA', 'ARMA', 'HUANCAVELICA'),
('080403', 'HUANCAVELICA', 'CASTROVIRREYNA', 'AURAHUA', 'HUANCAVELICA'),
('080405', 'HUANCAVELICA', 'CASTROVIRREYNA', 'CAPILLAS', 'HUANCAVELICA'),
('080406', 'HUANCAVELICA', 'CASTROVIRREYNA', 'COCAS', 'HUANCAVELICA'),
('080408', 'HUANCAVELICA', 'CASTROVIRREYNA', 'CHUPAMARCA', 'HUANCAVELICA'),
('080409', 'HUANCAVELICA', 'CASTROVIRREYNA', 'HUACHOS', 'HUANCAVELICA'),
('080410', 'HUANCAVELICA', 'CASTROVIRREYNA', 'HUAMATAMBO', 'HUANCAVELICA'),
('080414', 'HUANCAVELICA', 'CASTROVIRREYNA', 'MOLLEPAMPA', 'HUANCAVELICA'),
('080422', 'HUANCAVELICA', 'CASTROVIRREYNA', 'SAN JUAN', 'HUANCAVELICA'),
('080427', 'HUANCAVELICA', 'CASTROVIRREYNA', 'TANTARA', 'HUANCAVELICA'),
('080428', 'HUANCAVELICA', 'CASTROVIRREYNA', 'TICRAPO', 'HUANCAVELICA'),
('080429', 'HUANCAVELICA', 'CASTROVIRREYNA', 'SANTA ANA', 'HUANCAVELICA'),
('080501', 'HUANCAVELICA', 'TAYACAJA', 'PAMPAS', 'HUANCAVELICA'),
('080502', 'HUANCAVELICA', 'TAYACAJA', 'ACOSTAMBO', 'HUANCAVELICA'),
('080503', 'HUANCAVELICA', 'TAYACAJA', 'ACRAQUIA', 'HUANCAVELICA'),
('080504', 'HUANCAVELICA', 'TAYACAJA', 'AHUAYCHA', 'HUANCAVELICA'),
('080506', 'HUANCAVELICA', 'TAYACAJA', 'COLCABAMBA', 'HUANCAVELICA'),
('080509', 'HUANCAVELICA', 'TAYACAJA', 'DANIEL HERNANDEZ', 'HUANCAVELICA'),
('080511', 'HUANCAVELICA', 'TAYACAJA', 'HUACHOCOLPA', 'HUANCAVELICA'),
('080512', 'HUANCAVELICA', 'TAYACAJA', 'HUARIBAMBA', 'HUANCAVELICA'),
('080515', 'HUANCAVELICA', 'TAYACAJA', 'ÑAHUIMPUQUIO', 'HUANCAVELICA'),
('080517', 'HUANCAVELICA', 'TAYACAJA', 'PAZOS', 'HUANCAVELICA'),
('080518', 'HUANCAVELICA', 'TAYACAJA', 'QUISHUAR', 'HUANCAVELICA'),
('080519', 'HUANCAVELICA', 'TAYACAJA', 'SALCABAMBA', 'HUANCAVELICA'),
('080520', 'HUANCAVELICA', 'TAYACAJA', 'SAN MARCOS DE ROCCHAC', 'HUANCAVELICA'),
('080523', 'HUANCAVELICA', 'TAYACAJA', 'SURCUBAMBA', 'HUANCAVELICA'),
('080525', 'HUANCAVELICA', 'TAYACAJA', 'TINTAY PUNCU', 'HUANCAVELICA'),
('080526', 'HUANCAVELICA', 'TAYACAJA', 'SALCAHUASI', 'HUANCAVELICA'),
('080528', 'HUANCAVELICA', 'TAYACAJA', 'QUICHUAS', 'HUANCAVELICA'),
('080529', 'HUANCAVELICA', 'TAYACAJA', 'ANDAYMARCA', 'HUANCAVELICA'),
('080530', 'HUANCAVELICA', 'TAYACAJA', 'ROBLE', 'HUANCAVELICA'),
('080531', 'HUANCAVELICA', 'TAYACAJA', 'PICHOS', 'HUANCAVELICA'),
('080532', 'HUANCAVELICA', 'TAYACAJA', 'SANTIAGO DE TUCUMA', 'HUANCAVELICA'),
('080533', 'HUANCAVELICA', 'TAYACAJA', 'LAMBRAS', 'HUANCAVELICA'),
('080534', 'HUANCAVELICA', 'TAYACAJA', 'COCHABAMBA', 'HUANCAVELICA'),
('080601', 'HUANCAVELICA', 'HUAYTARA', 'AYAVI', 'HUANCAVELICA'),
('080602', 'HUANCAVELICA', 'HUAYTARA', 'CORDOVA', 'HUANCAVELICA'),
('080603', 'HUANCAVELICA', 'HUAYTARA', 'HUAYACUNDO ARMA', 'HUANCAVELICA'),
('080604', 'HUANCAVELICA', 'HUAYTARA', 'HUAYTARA', 'HUANCAVELICA'),
('080605', 'HUANCAVELICA', 'HUAYTARA', 'LARAMARCA', 'HUANCAVELICA'),
('080606', 'HUANCAVELICA', 'HUAYTARA', 'OCOYO', 'HUANCAVELICA'),
('080607', 'HUANCAVELICA', 'HUAYTARA', 'PILPICHACA', 'HUANCAVELICA'),
('080608', 'HUANCAVELICA', 'HUAYTARA', 'QUERCO', 'HUANCAVELICA'),
('080609', 'HUANCAVELICA', 'HUAYTARA', 'QUITO-ARMA', 'HUANCAVELICA'),
('080610', 'HUANCAVELICA', 'HUAYTARA', 'SAN ANTONIO DE CUSICANCHA', 'HUANCAVELICA'),
('080611', 'HUANCAVELICA', 'HUAYTARA', 'SAN FRANCISCO DE SANGAYAICO', 'HUANCAVELICA'),
('080612', 'HUANCAVELICA', 'HUAYTARA', 'SAN ISIDRO', 'HUANCAVELICA'),
('080613', 'HUANCAVELICA', 'HUAYTARA', 'SANTIAGO DE CHOCORVOS', 'HUANCAVELICA'),
('080614', 'HUANCAVELICA', 'HUAYTARA', 'SANTIAGO DE QUIRAHUARA', 'HUANCAVELICA'),
('080615', 'HUANCAVELICA', 'HUAYTARA', 'SANTO DOMINGO DE CAPILLAS', 'HUANCAVELICA'),
('080616', 'HUANCAVELICA', 'HUAYTARA', 'TAMBO', 'HUANCAVELICA'),
('080701', 'HUANCAVELICA', 'CHURCAMPA', 'CHURCAMPA', 'HUANCAVELICA'),
('080702', 'HUANCAVELICA', 'CHURCAMPA', 'ANCO', 'HUANCAVELICA'),
('080703', 'HUANCAVELICA', 'CHURCAMPA', 'CHINCHIHUASI', 'HUANCAVELICA'),
('080704', 'HUANCAVELICA', 'CHURCAMPA', 'EL CARMEN', 'HUANCAVELICA'),
('080705', 'HUANCAVELICA', 'CHURCAMPA', 'LA MERCED', 'HUANCAVELICA'),
('080706', 'HUANCAVELICA', 'CHURCAMPA', 'LOCROJA', 'HUANCAVELICA'),
('080707', 'HUANCAVELICA', 'CHURCAMPA', 'PAUCARBAMBA', 'HUANCAVELICA'),
('080708', 'HUANCAVELICA', 'CHURCAMPA', 'SAN MIGUEL DE MAYOCC', 'HUANCAVELICA'),
('080709', 'HUANCAVELICA', 'CHURCAMPA', 'SAN PEDRO DE CORIS', 'HUANCAVELICA'),
('080710', 'HUANCAVELICA', 'CHURCAMPA', 'PACHAMARCA', 'HUANCAVELICA'),
('080711', 'HUANCAVELICA', 'CHURCAMPA', 'COSME', 'HUANCAVELICA'),
('090101', 'HUANUCO', 'HUANUCO', 'HUANUCO', 'HUANUCO'),
('090102', 'HUANUCO', 'HUANUCO', 'CHINCHAO', 'HUANUCO'),
('090103', 'HUANUCO', 'HUANUCO', 'CHURUBAMBA', 'HUANUCO'),
('090104', 'HUANUCO', 'HUANUCO', 'MARGOS', 'HUANUCO'),
('090105', 'HUANUCO', 'HUANUCO', 'QUISQUI', 'HUANUCO'),
('090106', 'HUANUCO', 'HUANUCO', 'SAN FRANCISCO DE CAYRAN', 'HUANUCO'),
('090107', 'HUANUCO', 'HUANUCO', 'SAN PEDRO DE CHAULAN', 'HUANUCO'),
('090108', 'HUANUCO', 'HUANUCO', 'SANTA MARIA DEL VALLE', 'HUANUCO'),
('090109', 'HUANUCO', 'HUANUCO', 'YARUMAYO', 'HUANUCO'),
('090110', 'HUANUCO', 'HUANUCO', 'AMARILIS', 'HUANUCO'),
('090111', 'HUANUCO', 'HUANUCO', 'PILLCO MARCA', 'HUANUCO'),
('090112', 'HUANUCO', 'HUANUCO', 'YACUS', 'HUANUCO'),
('090113', 'HUANUCO', 'HUANUCO', 'SAN PABLO DE PILLAO', 'HUANUCO'),
('090201', 'HUANUCO', 'AMBO', 'AMBO', 'HUANUCO'),
('090202', 'HUANUCO', 'AMBO', 'CAYNA', 'HUANUCO'),
('090203', 'HUANUCO', 'AMBO', 'COLPAS', 'HUANUCO'),
('090204', 'HUANUCO', 'AMBO', 'CONCHAMARCA', 'HUANUCO'),
('090205', 'HUANUCO', 'AMBO', 'HUACAR', 'HUANUCO'),
('090206', 'HUANUCO', 'AMBO', 'SAN FRANCISCO', 'HUANUCO'),
('090207', 'HUANUCO', 'AMBO', 'SAN RAFAEL', 'HUANUCO'),
('090208', 'HUANUCO', 'AMBO', 'TOMAY KICHWA', 'HUANUCO'),
('090301', 'HUANUCO', 'DOS DE MAYO', 'LA UNION', 'HUANUCO'),
('090307', 'HUANUCO', 'DOS DE MAYO', 'CHUQUIS', 'HUANUCO'),
('090312', 'HUANUCO', 'DOS DE MAYO', 'MARIAS', 'HUANUCO'),
('090314', 'HUANUCO', 'DOS DE MAYO', 'PACHAS', 'HUANUCO'),
('090316', 'HUANUCO', 'DOS DE MAYO', 'QUIVILLA', 'HUANUCO'),
('090317', 'HUANUCO', 'DOS DE MAYO', 'RIPAN', 'HUANUCO'),
('090321', 'HUANUCO', 'DOS DE MAYO', 'SHUNQUI', 'HUANUCO'),
('090322', 'HUANUCO', 'DOS DE MAYO', 'SILLAPATA', 'HUANUCO'),
('090323', 'HUANUCO', 'DOS DE MAYO', 'YANAS', 'HUANUCO'),
('090401', 'HUANUCO', 'HUAMALIES', 'LLATA', 'HUANUCO'),
('090402', 'HUANUCO', 'HUAMALIES', 'ARANCAY', 'HUANUCO'),
('090403', 'HUANUCO', 'HUAMALIES', 'CHAVIN DE PARIARCA', 'HUANUCO'),
('090404', 'HUANUCO', 'HUAMALIES', 'JACAS GRANDE', 'HUANUCO'),
('090405', 'HUANUCO', 'HUAMALIES', 'JIRCAN', 'HUANUCO'),
('090406', 'HUANUCO', 'HUAMALIES', 'MIRAFLORES', 'HUANUCO'),
('090407', 'HUANUCO', 'HUAMALIES', 'MONZON', 'HUANUCO'),
('090408', 'HUANUCO', 'HUAMALIES', 'PUNCHAO', 'HUANUCO'),
('090409', 'HUANUCO', 'HUAMALIES', 'PUÑOS', 'HUANUCO'),
('090410', 'HUANUCO', 'HUAMALIES', 'SINGA', 'HUANUCO'),
('090411', 'HUANUCO', 'HUAMALIES', 'TANTAMAYO', 'HUANUCO'),
('090501', 'HUANUCO', 'MARAÑON', 'HUACRACHUCO', 'HUANUCO'),
('090502', 'HUANUCO', 'MARAÑON', 'CHOLON', 'HUANUCO'),
('090505', 'HUANUCO', 'MARAÑON', 'SAN BUENAVENTURA', 'HUANUCO'),
('090506', 'HUANUCO', 'MARAÑON', 'LA MORADA', 'HUANUCO'),
('090507', 'HUANUCO', 'MARAÑON', 'SANTA ROSA DE ALTO YANAJANCA', 'HUANUCO'),
('090601', 'HUANUCO', 'LEONCIO PRADO', 'RUPA-RUPA', 'HUANUCO'),
('090602', 'HUANUCO', 'LEONCIO PRADO', 'DANIEL ALOMIAS ROBLES', 'HUANUCO'),
('090603', 'HUANUCO', 'LEONCIO PRADO', 'HERMILIO VALDIZAN', 'HUANUCO'),
('090604', 'HUANUCO', 'LEONCIO PRADO', 'LUYANDO', 'HUANUCO'),
('090605', 'HUANUCO', 'LEONCIO PRADO', 'MARIANO DAMASO BERAUN', 'HUANUCO'),
('090606', 'HUANUCO', 'LEONCIO PRADO', 'JOSE CRESPO Y CASTILLO', 'HUANUCO'),
('090607', 'HUANUCO', 'LEONCIO PRADO', 'PUCAYACU', 'HUANUCO'),
('090608', 'HUANUCO', 'LEONCIO PRADO', 'CASTILLO GRANDE', 'HUANUCO'),
('090609', 'HUANUCO', 'LEONCIO PRADO', 'PUEBLO NUEVO', 'HUANUCO'),
('090610', 'HUANUCO', 'LEONCIO PRADO', 'SANTO DOMINGO DE ANDA', 'HUANUCO'),
('090701', 'HUANUCO', 'PACHITEA', 'PANAO', 'HUANUCO'),
('090702', 'HUANUCO', 'PACHITEA', 'CHAGLLA', 'HUANUCO'),
('090704', 'HUANUCO', 'PACHITEA', 'MOLINO', 'HUANUCO'),
('090706', 'HUANUCO', 'PACHITEA', 'UMARI', 'HUANUCO'),
('090801', 'HUANUCO', 'PUERTO INCA', 'HONORIA', 'HUANUCO'),
('090802', 'HUANUCO', 'PUERTO INCA', 'PUERTO INCA', 'HUANUCO'),
('090803', 'HUANUCO', 'PUERTO INCA', 'CODO DEL POZUZO', 'HUANUCO'),
('090804', 'HUANUCO', 'PUERTO INCA', 'TOURNAVISTA', 'HUANUCO'),
('090805', 'HUANUCO', 'PUERTO INCA', 'YUYAPICHIS', 'HUANUCO'),
('090901', 'HUANUCO', 'HUACAYBAMBA', 'HUACAYBAMBA', 'HUANUCO'),
('090902', 'HUANUCO', 'HUACAYBAMBA', 'PINRA', 'HUANUCO'),
('090903', 'HUANUCO', 'HUACAYBAMBA', 'CANCHABAMBA', 'HUANUCO'),
('090904', 'HUANUCO', 'HUACAYBAMBA', 'COCHABAMBA', 'HUANUCO'),
('091001', 'HUANUCO', 'LAURICOCHA', 'JESUS', 'HUANUCO'),
('091002', 'HUANUCO', 'LAURICOCHA', 'BAÑOS', 'HUANUCO'),
('091003', 'HUANUCO', 'LAURICOCHA', 'SAN FRANCISCO DE ASIS', 'HUANUCO'),
('091004', 'HUANUCO', 'LAURICOCHA', 'QUEROPALCA', 'HUANUCO'),
('091005', 'HUANUCO', 'LAURICOCHA', 'SAN MIGUEL DE CAURI', 'HUANUCO'),
('091006', 'HUANUCO', 'LAURICOCHA', 'RONDOS', 'HUANUCO'),
('091007', 'HUANUCO', 'LAURICOCHA', 'JIVIA', 'HUANUCO'),
('091101', 'HUANUCO', 'YAROWILCA', 'CHAVINILLO', 'HUANUCO'),
('091102', 'HUANUCO', 'YAROWILCA', 'APARICIO POMARES', 'HUANUCO'),
('091103', 'HUANUCO', 'YAROWILCA', 'CAHUAC', 'HUANUCO'),
('091104', 'HUANUCO', 'YAROWILCA', 'CHACABAMBA', 'HUANUCO'),
('091105', 'HUANUCO', 'YAROWILCA', 'JACAS CHICO', 'HUANUCO'),
('091106', 'HUANUCO', 'YAROWILCA', 'OBAS', 'HUANUCO'),
('091107', 'HUANUCO', 'YAROWILCA', 'PAMPAMARCA', 'HUANUCO'),
('091108', 'HUANUCO', 'YAROWILCA', 'CHORAS', 'HUANUCO'),
('100101', 'ICA', 'ICA', 'ICA', 'ICA'),
('100102', 'ICA', 'ICA', 'LA TINGUIÑA', 'ICA'),
('100103', 'ICA', 'ICA', 'LOS AQUIJES', 'ICA'),
('100104', 'ICA', 'ICA', 'PARCONA', 'ICA'),
('100105', 'ICA', 'ICA', 'PUEBLO NUEVO', 'ICA'),
('100106', 'ICA', 'ICA', 'SALAS', 'ICA'),
('100107', 'ICA', 'ICA', 'SAN JOSE DE LOS MOLINOS', 'ICA'),
('100108', 'ICA', 'ICA', 'SAN JUAN BAUTISTA', 'ICA'),
('100109', 'ICA', 'ICA', 'SANTIAGO', 'ICA'),
('100110', 'ICA', 'ICA', 'SUBTANJALLA', 'ICA'),
('100111', 'ICA', 'ICA', 'YAUCA DEL ROSARIO', 'ICA'),
('100112', 'ICA', 'ICA', 'TATE', 'ICA'),
('100113', 'ICA', 'ICA', 'PACHACUTEC', 'ICA'),
('100114', 'ICA', 'ICA', 'OCUCAJE', 'ICA'),
('100201', 'ICA', 'CHINCHA', 'CHINCHA ALTA', 'ICA'),
('100202', 'ICA', 'CHINCHA', 'CHAVIN', 'ICA'),
('100203', 'ICA', 'CHINCHA', 'CHINCHA BAJA', 'ICA'),
('100204', 'ICA', 'CHINCHA', 'EL CARMEN', 'ICA'),
('100205', 'ICA', 'CHINCHA', 'GROCIO PRADO', 'ICA'),
('100206', 'ICA', 'CHINCHA', 'SAN PEDRO DE HUACARPANA', 'ICA'),
('100207', 'ICA', 'CHINCHA', 'SUNAMPE', 'ICA'),
('100208', 'ICA', 'CHINCHA', 'TAMBO DE MORA', 'ICA'),
('100209', 'ICA', 'CHINCHA', 'ALTO LARAN', 'ICA'),
('100210', 'ICA', 'CHINCHA', 'PUEBLO NUEVO', 'ICA'),
('100211', 'ICA', 'CHINCHA', 'SAN JUAN DE YANAC', 'ICA'),
('100301', 'ICA', 'NAZCA', 'NAZCA', 'ICA'),
('100302', 'ICA', 'NAZCA', 'CHANGUILLO', 'ICA'),
('100303', 'ICA', 'NAZCA', 'EL INGENIO', 'ICA'),
('100304', 'ICA', 'NAZCA', 'MARCONA', 'ICA'),
('100305', 'ICA', 'NAZCA', 'VISTA ALEGRE', 'ICA'),
('100401', 'ICA', 'PISCO', 'PISCO', 'ICA'),
('100402', 'ICA', 'PISCO', 'HUANCANO', 'ICA'),
('100403', 'ICA', 'PISCO', 'HUMAY', 'ICA'),
('100404', 'ICA', 'PISCO', 'INDEPENDENCIA', 'ICA'),
('100405', 'ICA', 'PISCO', 'PARACAS', 'ICA'),
('100406', 'ICA', 'PISCO', 'SAN ANDRES', 'ICA'),
('100407', 'ICA', 'PISCO', 'SAN CLEMENTE', 'ICA'),
('100408', 'ICA', 'PISCO', 'TUPAC AMARU INCA', 'ICA'),
('100501', 'ICA', 'PALPA', 'PALPA', 'ICA'),
('100502', 'ICA', 'PALPA', 'LLIPATA', 'ICA'),
('100503', 'ICA', 'PALPA', 'RIO GRANDE', 'ICA'),
('100504', 'ICA', 'PALPA', 'SANTA CRUZ', 'ICA'),
('100505', 'ICA', 'PALPA', 'TIBILLO', 'ICA'),
('110101', 'JUNIN', 'HUANCAYO', 'HUANCAYO', 'JUNIN'),
('110103', 'JUNIN', 'HUANCAYO', 'CARHUACALLANGA', 'JUNIN'),
('110104', 'JUNIN', 'HUANCAYO', 'COLCA', 'JUNIN'),
('110105', 'JUNIN', 'HUANCAYO', 'CULLHUAS', 'JUNIN'),
('110106', 'JUNIN', 'HUANCAYO', 'CHACAPAMPA', 'JUNIN'),
('110107', 'JUNIN', 'HUANCAYO', 'CHICCHE', 'JUNIN'),
('110108', 'JUNIN', 'HUANCAYO', 'CHILCA', 'JUNIN'),
('110109', 'JUNIN', 'HUANCAYO', 'CHONGOS ALTO', 'JUNIN'),
('110112', 'JUNIN', 'HUANCAYO', 'CHUPURO', 'JUNIN'),
('110113', 'JUNIN', 'HUANCAYO', 'EL TAMBO', 'JUNIN'),
('110114', 'JUNIN', 'HUANCAYO', 'HUACRAPUQUIO', 'JUNIN'),
('110116', 'JUNIN', 'HUANCAYO', 'HUALHUAS', 'JUNIN'),
('110118', 'JUNIN', 'HUANCAYO', 'HUANCAN', 'JUNIN'),
('110119', 'JUNIN', 'HUANCAYO', 'HUASICANCHA', 'JUNIN'),
('110120', 'JUNIN', 'HUANCAYO', 'HUAYUCACHI', 'JUNIN'),
('110121', 'JUNIN', 'HUANCAYO', 'INGENIO', 'JUNIN'),
('110122', 'JUNIN', 'HUANCAYO', 'PARIAHUANCA', 'JUNIN'),
('110123', 'JUNIN', 'HUANCAYO', 'PILCOMAYO', 'JUNIN'),
('110124', 'JUNIN', 'HUANCAYO', 'PUCARA', 'JUNIN'),
('110125', 'JUNIN', 'HUANCAYO', 'QUICHUAY', 'JUNIN'),
('110126', 'JUNIN', 'HUANCAYO', 'QUILCAS', 'JUNIN'),
('110127', 'JUNIN', 'HUANCAYO', 'SAN AGUSTIN', 'JUNIN'),
('110128', 'JUNIN', 'HUANCAYO', 'SAN JERONIMO DE TUNAN', 'JUNIN'),
('110131', 'JUNIN', 'HUANCAYO', 'SANTO DOMINGO DE ACOBAMBA', 'JUNIN'),
('110132', 'JUNIN', 'HUANCAYO', 'SAÑO', 'JUNIN'),
('110133', 'JUNIN', 'HUANCAYO', 'SAPALLANGA', 'JUNIN'),
('110134', 'JUNIN', 'HUANCAYO', 'SICAYA', 'JUNIN'),
('110136', 'JUNIN', 'HUANCAYO', 'VIQUES', 'JUNIN'),
('110201', 'JUNIN', 'CONCEPCION', 'CONCEPCION', 'JUNIN'),
('110202', 'JUNIN', 'CONCEPCION', 'ACO', 'JUNIN'),
('110203', 'JUNIN', 'CONCEPCION', 'ANDAMARCA', 'JUNIN'),
('110204', 'JUNIN', 'CONCEPCION', 'COMAS', 'JUNIN'),
('110205', 'JUNIN', 'CONCEPCION', 'COCHAS', 'JUNIN'),
('110206', 'JUNIN', 'CONCEPCION', 'CHAMBARA', 'JUNIN'),
('110207', 'JUNIN', 'CONCEPCION', 'HEROINAS TOLEDO', 'JUNIN'),
('110208', 'JUNIN', 'CONCEPCION', 'MANZANARES', 'JUNIN'),
('110209', 'JUNIN', 'CONCEPCION', 'MARISCAL CASTILLA', 'JUNIN'),
('110210', 'JUNIN', 'CONCEPCION', 'MATAHUASI', 'JUNIN'),
('110211', 'JUNIN', 'CONCEPCION', 'MITO', 'JUNIN'),
('110212', 'JUNIN', 'CONCEPCION', 'NUEVE DE JULIO', 'JUNIN'),
('110213', 'JUNIN', 'CONCEPCION', 'ORCOTUNA', 'JUNIN'),
('110214', 'JUNIN', 'CONCEPCION', 'SANTA ROSA DE OCOPA', 'JUNIN'),
('110215', 'JUNIN', 'CONCEPCION', 'SAN JOSE DE QUERO', 'JUNIN'),
('110301', 'JUNIN', 'JAUJA', 'JAUJA', 'JUNIN'),
('110302', 'JUNIN', 'JAUJA', 'ACOLLA', 'JUNIN'),
('110303', 'JUNIN', 'JAUJA', 'APATA', 'JUNIN'),
('110304', 'JUNIN', 'JAUJA', 'ATAURA', 'JUNIN'),
('110305', 'JUNIN', 'JAUJA', 'CANCHAYLLO', 'JUNIN'),
('110306', 'JUNIN', 'JAUJA', 'EL MANTARO', 'JUNIN'),
('110307', 'JUNIN', 'JAUJA', 'HUAMALI', 'JUNIN'),
('110308', 'JUNIN', 'JAUJA', 'HUARIPAMPA', 'JUNIN'),
('110309', 'JUNIN', 'JAUJA', 'HUERTAS', 'JUNIN'),
('110310', 'JUNIN', 'JAUJA', 'JANJAILLO', 'JUNIN'),
('110311', 'JUNIN', 'JAUJA', 'JULCAN', 'JUNIN'),
('110312', 'JUNIN', 'JAUJA', 'LEONOR ORDOÑEZ', 'JUNIN'),
('110313', 'JUNIN', 'JAUJA', 'LLOCLLAPAMPA', 'JUNIN'),
('110314', 'JUNIN', 'JAUJA', 'MARCO', 'JUNIN'),
('110315', 'JUNIN', 'JAUJA', 'MASMA', 'JUNIN'),
('110316', 'JUNIN', 'JAUJA', 'MOLINOS', 'JUNIN'),
('110317', 'JUNIN', 'JAUJA', 'MONOBAMBA', 'JUNIN'),
('110318', 'JUNIN', 'JAUJA', 'MUQUI', 'JUNIN'),
('110319', 'JUNIN', 'JAUJA', 'MUQUIYAUYO', 'JUNIN'),
('110320', 'JUNIN', 'JAUJA', 'PACA', 'JUNIN'),
('110321', 'JUNIN', 'JAUJA', 'PACCHA', 'JUNIN'),
('110322', 'JUNIN', 'JAUJA', 'PANCAN', 'JUNIN'),
('110323', 'JUNIN', 'JAUJA', 'PARCO', 'JUNIN'),
('110324', 'JUNIN', 'JAUJA', 'POMACANCHA', 'JUNIN'),
('110325', 'JUNIN', 'JAUJA', 'RICRAN', 'JUNIN'),
('110326', 'JUNIN', 'JAUJA', 'SAN LORENZO', 'JUNIN'),
('110327', 'JUNIN', 'JAUJA', 'SAN PEDRO DE CHUNAN', 'JUNIN'),
('110328', 'JUNIN', 'JAUJA', 'SINCOS', 'JUNIN'),
('110329', 'JUNIN', 'JAUJA', 'TUNAN MARCA', 'JUNIN'),
('110330', 'JUNIN', 'JAUJA', 'YAULI', 'JUNIN'),
('110331', 'JUNIN', 'JAUJA', 'CURICACA', 'JUNIN'),
('110332', 'JUNIN', 'JAUJA', 'MASMA CHICCHE', 'JUNIN'),
('110333', 'JUNIN', 'JAUJA', 'SAUSA', 'JUNIN'),
('110334', 'JUNIN', 'JAUJA', 'YAUYOS', 'JUNIN'),
('110401', 'JUNIN', 'JUNIN', 'JUNIN', 'JUNIN'),
('110402', 'JUNIN', 'JUNIN', 'CARHUAMAYO', 'JUNIN'),
('110403', 'JUNIN', 'JUNIN', 'ONDORES', 'JUNIN'),
('110404', 'JUNIN', 'JUNIN', 'ULCUMAYO', 'JUNIN'),
('110501', 'JUNIN', 'TARMA', 'TARMA', 'JUNIN'),
('110502', 'JUNIN', 'TARMA', 'ACOBAMBA', 'JUNIN'),
('110503', 'JUNIN', 'TARMA', 'HUARICOLCA', 'JUNIN'),
('110504', 'JUNIN', 'TARMA', 'HUASAHUASI', 'JUNIN'),
('110505', 'JUNIN', 'TARMA', 'LA UNION', 'JUNIN'),
('110506', 'JUNIN', 'TARMA', 'PALCA', 'JUNIN'),
('110507', 'JUNIN', 'TARMA', 'PALCAMAYO', 'JUNIN'),
('110508', 'JUNIN', 'TARMA', 'SAN PEDRO DE CAJAS', 'JUNIN'),
('110509', 'JUNIN', 'TARMA', 'TAPO', 'JUNIN'),
('110601', 'JUNIN', 'YAULI', 'LA OROYA', 'JUNIN'),
('110602', 'JUNIN', 'YAULI', 'CHACAPALPA', 'JUNIN'),
('110603', 'JUNIN', 'YAULI', 'HUAY-HUAY', 'JUNIN'),
('110604', 'JUNIN', 'YAULI', 'MARCAPOMACOCHA', 'JUNIN'),
('110605', 'JUNIN', 'YAULI', 'MOROCOCHA', 'JUNIN'),
('110606', 'JUNIN', 'YAULI', 'PACCHA', 'JUNIN'),
('110607', 'JUNIN', 'YAULI', 'SANTA BARBARA DE CARHUACAYAN', 'JUNIN'),
('110608', 'JUNIN', 'YAULI', 'SUITUCANCHA', 'JUNIN'),
('110609', 'JUNIN', 'YAULI', 'YAULI', 'JUNIN'),
('110610', 'JUNIN', 'YAULI', 'SANTA ROSA DE SACCO', 'JUNIN'),
('110701', 'JUNIN', 'SATIPO', 'SATIPO', 'JUNIN'),
('110702', 'JUNIN', 'SATIPO', 'COVIRIALI', 'JUNIN'),
('110703', 'JUNIN', 'SATIPO', 'LLAYLLA', 'JUNIN'),
('110704', 'JUNIN', 'SATIPO', 'MAZAMARI', 'JUNIN'),
('110705', 'JUNIN', 'SATIPO', 'PAMPA HERMOSA', 'JUNIN'),
('110706', 'JUNIN', 'SATIPO', 'PANGOA', 'JUNIN'),
('110707', 'JUNIN', 'SATIPO', 'RIO NEGRO', 'JUNIN'),
('110708', 'JUNIN', 'SATIPO', 'RIO TAMBO', 'JUNIN'),
('110709', 'JUNIN', 'SATIPO', 'VIZCATAN DEL ENE', 'JUNIN'),
('110801', 'JUNIN', 'CHANCHAMAYO', 'CHANCHAMAYO', 'JUNIN'),
('110802', 'JUNIN', 'CHANCHAMAYO', 'SAN RAMON', 'JUNIN'),
('110803', 'JUNIN', 'CHANCHAMAYO', 'VITOC', 'JUNIN'),
('110804', 'JUNIN', 'CHANCHAMAYO', 'SAN LUIS DE SHUARO', 'JUNIN'),
('110805', 'JUNIN', 'CHANCHAMAYO', 'PICHANAQUI', 'JUNIN'),
('110806', 'JUNIN', 'CHANCHAMAYO', 'PERENE', 'JUNIN'),
('110901', 'JUNIN', 'CHUPACA', 'CHUPACA', 'JUNIN'),
('110902', 'JUNIN', 'CHUPACA', 'AHUAC', 'JUNIN'),
('110903', 'JUNIN', 'CHUPACA', 'CHONGOS BAJO', 'JUNIN'),
('110904', 'JUNIN', 'CHUPACA', 'HUACHAC', 'JUNIN'),
('110905', 'JUNIN', 'CHUPACA', 'HUAMANCACA CHICO', 'JUNIN'),
('110906', 'JUNIN', 'CHUPACA', 'SAN JUAN DE YSCOS', 'JUNIN'),
('110907', 'JUNIN', 'CHUPACA', 'SAN JUAN DE JARPA', 'JUNIN'),
('110908', 'JUNIN', 'CHUPACA', 'TRES DE DICIEMBRE', 'JUNIN'),
('110909', 'JUNIN', 'CHUPACA', 'YANACANCHA', 'JUNIN'),
('120101', 'LA LIBERTAD', 'TRUJILLO', 'TRUJILLO', 'LA LIBERTAD'),
('120102', 'LA LIBERTAD', 'TRUJILLO', 'HUANCHACO', 'LA LIBERTAD'),
('120103', 'LA LIBERTAD', 'TRUJILLO', 'LAREDO', 'LA LIBERTAD'),
('120104', 'LA LIBERTAD', 'TRUJILLO', 'MOCHE', 'LA LIBERTAD'),
('120105', 'LA LIBERTAD', 'TRUJILLO', 'SALAVERRY', 'LA LIBERTAD'),
('120106', 'LA LIBERTAD', 'TRUJILLO', 'SIMBAL', 'LA LIBERTAD'),
('120107', 'LA LIBERTAD', 'TRUJILLO', 'VICTOR LARCO HERRERA', 'LA LIBERTAD'),
('120109', 'LA LIBERTAD', 'TRUJILLO', 'POROTO', 'LA LIBERTAD'),
('120110', 'LA LIBERTAD', 'TRUJILLO', 'EL PORVENIR', 'LA LIBERTAD'),
('120111', 'LA LIBERTAD', 'TRUJILLO', 'LA ESPERANZA', 'LA LIBERTAD'),
('120112', 'LA LIBERTAD', 'TRUJILLO', 'FLORENCIA DE MORA', 'LA LIBERTAD'),
('120201', 'LA LIBERTAD', 'BOLIVAR', 'BOLIVAR', 'LA LIBERTAD'),
('120202', 'LA LIBERTAD', 'BOLIVAR', 'BAMBAMARCA', 'LA LIBERTAD'),
('120203', 'LA LIBERTAD', 'BOLIVAR', 'CONDORMARCA', 'LA LIBERTAD'),
('120204', 'LA LIBERTAD', 'BOLIVAR', 'LONGOTEA', 'LA LIBERTAD'),
('120205', 'LA LIBERTAD', 'BOLIVAR', 'UCUNCHA', 'LA LIBERTAD'),
('120206', 'LA LIBERTAD', 'BOLIVAR', 'UCHUMARCA', 'LA LIBERTAD'),
('120301', 'LA LIBERTAD', 'SANCHEZ CARRION', 'HUAMACHUCO', 'LA LIBERTAD'),
('120302', 'LA LIBERTAD', 'SANCHEZ CARRION', 'COCHORCO', 'LA LIBERTAD'),
('120303', 'LA LIBERTAD', 'SANCHEZ CARRION', 'CURGOS', 'LA LIBERTAD'),
('120304', 'LA LIBERTAD', 'SANCHEZ CARRION', 'CHUGAY', 'LA LIBERTAD'),
('120305', 'LA LIBERTAD', 'SANCHEZ CARRION', 'MARCABAL', 'LA LIBERTAD'),
('120306', 'LA LIBERTAD', 'SANCHEZ CARRION', 'SANAGORAN', 'LA LIBERTAD'),
('120307', 'LA LIBERTAD', 'SANCHEZ CARRION', 'SARIN', 'LA LIBERTAD'),
('120308', 'LA LIBERTAD', 'SANCHEZ CARRION', 'SARTIMBAMBA', 'LA LIBERTAD'),
('120401', 'LA LIBERTAD', 'OTUZCO', 'OTUZCO', 'LA LIBERTAD'),
('120402', 'LA LIBERTAD', 'OTUZCO', 'AGALLPAMPA', 'LA LIBERTAD'),
('120403', 'LA LIBERTAD', 'OTUZCO', 'CHARAT', 'LA LIBERTAD'),
('120404', 'LA LIBERTAD', 'OTUZCO', 'HUARANCHAL', 'LA LIBERTAD'),
('120405', 'LA LIBERTAD', 'OTUZCO', 'LA CUESTA', 'LA LIBERTAD'),
('120408', 'LA LIBERTAD', 'OTUZCO', 'PARANDAY', 'LA LIBERTAD'),
('120409', 'LA LIBERTAD', 'OTUZCO', 'SALPO', 'LA LIBERTAD'),
('120410', 'LA LIBERTAD', 'OTUZCO', 'SINSICAP', 'LA LIBERTAD'),
('120411', 'LA LIBERTAD', 'OTUZCO', 'USQUIL', 'LA LIBERTAD'),
('120413', 'LA LIBERTAD', 'OTUZCO', 'MACHE', 'LA LIBERTAD'),
('120501', 'LA LIBERTAD', 'PACASMAYO', 'SAN PEDRO DE LLOC', 'LA LIBERTAD'),
('120503', 'LA LIBERTAD', 'PACASMAYO', 'GUADALUPE', 'LA LIBERTAD'),
('120504', 'LA LIBERTAD', 'PACASMAYO', 'JEQUETEPEQUE', 'LA LIBERTAD'),
('120506', 'LA LIBERTAD', 'PACASMAYO', 'PACASMAYO', 'LA LIBERTAD'),
('120508', 'LA LIBERTAD', 'PACASMAYO', 'SAN JOSE', 'LA LIBERTAD'),
('120601', 'LA LIBERTAD', 'PATAZ', 'TAYABAMBA', 'LA LIBERTAD'),
('120602', 'LA LIBERTAD', 'PATAZ', 'BULDIBUYO', 'LA LIBERTAD'),
('120603', 'LA LIBERTAD', 'PATAZ', 'CHILLIA', 'LA LIBERTAD'),
('120604', 'LA LIBERTAD', 'PATAZ', 'HUAYLILLAS', 'LA LIBERTAD'),
('120605', 'LA LIBERTAD', 'PATAZ', 'HUANCASPATA', 'LA LIBERTAD'),
('120606', 'LA LIBERTAD', 'PATAZ', 'HUAYO', 'LA LIBERTAD'),
('120607', 'LA LIBERTAD', 'PATAZ', 'ONGON', 'LA LIBERTAD'),
('120608', 'LA LIBERTAD', 'PATAZ', 'PARCOY', 'LA LIBERTAD'),
('120609', 'LA LIBERTAD', 'PATAZ', 'PATAZ', 'LA LIBERTAD'),
('120610', 'LA LIBERTAD', 'PATAZ', 'PIAS', 'LA LIBERTAD'),
('120611', 'LA LIBERTAD', 'PATAZ', 'TAURIJA', 'LA LIBERTAD'),
('120612', 'LA LIBERTAD', 'PATAZ', 'URPAY', 'LA LIBERTAD'),
('120613', 'LA LIBERTAD', 'PATAZ', 'SANTIAGO DE CHALLAS', 'LA LIBERTAD'),
('120701', 'LA LIBERTAD', 'SANTIAGO DE CHUCO', 'SANTIAGO DE CHUCO', 'LA LIBERTAD'),
('120702', 'LA LIBERTAD', 'SANTIAGO DE CHUCO', 'CACHICADAN', 'LA LIBERTAD'),
('120703', 'LA LIBERTAD', 'SANTIAGO DE CHUCO', 'MOLLEBAMBA', 'LA LIBERTAD'),
('120704', 'LA LIBERTAD', 'SANTIAGO DE CHUCO', 'MOLLEPATA', 'LA LIBERTAD'),
('120705', 'LA LIBERTAD', 'SANTIAGO DE CHUCO', 'QUIRUVILCA', 'LA LIBERTAD'),
('120706', 'LA LIBERTAD', 'SANTIAGO DE CHUCO', 'SANTA CRUZ DE CHUCA', 'LA LIBERTAD'),
('120707', 'LA LIBERTAD', 'SANTIAGO DE CHUCO', 'SITABAMBA', 'LA LIBERTAD'),
('120708', 'LA LIBERTAD', 'SANTIAGO DE CHUCO', 'ANGASMARCA', 'LA LIBERTAD'),
('120801', 'LA LIBERTAD', 'ASCOPE', 'ASCOPE', 'LA LIBERTAD'),
('120802', 'LA LIBERTAD', 'ASCOPE', 'CHICAMA', 'LA LIBERTAD'),
('120803', 'LA LIBERTAD', 'ASCOPE', 'CHOCOPE', 'LA LIBERTAD'),
('120804', 'LA LIBERTAD', 'ASCOPE', 'SANTIAGO DE CAO', 'LA LIBERTAD'),
('120805', 'LA LIBERTAD', 'ASCOPE', 'MAGDALENA DE CAO', 'LA LIBERTAD'),
('120806', 'LA LIBERTAD', 'ASCOPE', 'PAIJAN', 'LA LIBERTAD'),
('120807', 'LA LIBERTAD', 'ASCOPE', 'RAZURI', 'LA LIBERTAD'),
('120808', 'LA LIBERTAD', 'ASCOPE', 'CASA GRANDE', 'LA LIBERTAD'),
('120901', 'LA LIBERTAD', 'CHEPEN', 'CHEPEN', 'LA LIBERTAD'),
('120902', 'LA LIBERTAD', 'CHEPEN', 'PACANGA', 'LA LIBERTAD'),
('120903', 'LA LIBERTAD', 'CHEPEN', 'PUEBLO NUEVO', 'LA LIBERTAD'),
('121001', 'LA LIBERTAD', 'JULCAN', 'JULCAN', 'LA LIBERTAD'),
('121002', 'LA LIBERTAD', 'JULCAN', 'CARABAMBA', 'LA LIBERTAD'),
('121003', 'LA LIBERTAD', 'JULCAN', 'CALAMARCA', 'LA LIBERTAD'),
('121004', 'LA LIBERTAD', 'JULCAN', 'HUASO', 'LA LIBERTAD'),
('121101', 'LA LIBERTAD', 'GRAN CHIMU', 'CASCAS', 'LA LIBERTAD'),
('121102', 'LA LIBERTAD', 'GRAN CHIMU', 'LUCMA', 'LA LIBERTAD'),
('121103', 'LA LIBERTAD', 'GRAN CHIMU', 'MARMOT', 'LA LIBERTAD'),
('121104', 'LA LIBERTAD', 'GRAN CHIMU', 'SAYAPULLO', 'LA LIBERTAD'),
('121201', 'LA LIBERTAD', 'VIRU', 'VIRU', 'LA LIBERTAD'),
('121202', 'LA LIBERTAD', 'VIRU', 'CHAO', 'LA LIBERTAD'),
('121203', 'LA LIBERTAD', 'VIRU', 'GUADALUPITO', 'LA LIBERTAD'),
('130101', 'LAMBAYEQUE', 'CHICLAYO', 'CHICLAYO', 'LAMBAYEQUE'),
('130102', 'LAMBAYEQUE', 'CHICLAYO', 'CHONGOYAPE', 'LAMBAYEQUE'),
('130103', 'LAMBAYEQUE', 'CHICLAYO', 'ETEN', 'LAMBAYEQUE'),
('130104', 'LAMBAYEQUE', 'CHICLAYO', 'ETEN PUERTO', 'LAMBAYEQUE'),
('130105', 'LAMBAYEQUE', 'CHICLAYO', 'LAGUNAS', 'LAMBAYEQUE'),
('130106', 'LAMBAYEQUE', 'CHICLAYO', 'MONSEFU', 'LAMBAYEQUE'),
('130107', 'LAMBAYEQUE', 'CHICLAYO', 'NUEVA ARICA', 'LAMBAYEQUE'),
('130108', 'LAMBAYEQUE', 'CHICLAYO', 'OYOTUN', 'LAMBAYEQUE'),
('130109', 'LAMBAYEQUE', 'CHICLAYO', 'PICSI', 'LAMBAYEQUE'),
('130110', 'LAMBAYEQUE', 'CHICLAYO', 'PIMENTEL', 'LAMBAYEQUE'),
('130111', 'LAMBAYEQUE', 'CHICLAYO', 'REQUE', 'LAMBAYEQUE'),
('130112', 'LAMBAYEQUE', 'CHICLAYO', 'JOSE LEONARDO ORTIZ', 'LAMBAYEQUE'),
('130113', 'LAMBAYEQUE', 'CHICLAYO', 'SANTA ROSA', 'LAMBAYEQUE'),
('130114', 'LAMBAYEQUE', 'CHICLAYO', 'SAÑA', 'LAMBAYEQUE'),
('130115', 'LAMBAYEQUE', 'CHICLAYO', 'LA VICTORIA', 'LAMBAYEQUE'),
('130116', 'LAMBAYEQUE', 'CHICLAYO', 'CAYALTI', 'LAMBAYEQUE'),
('130117', 'LAMBAYEQUE', 'CHICLAYO', 'PATAPO', 'LAMBAYEQUE'),
('130118', 'LAMBAYEQUE', 'CHICLAYO', 'POMALCA', 'LAMBAYEQUE'),
('130119', 'LAMBAYEQUE', 'CHICLAYO', 'PUCALA', 'LAMBAYEQUE'),
('130120', 'LAMBAYEQUE', 'CHICLAYO', 'TUMAN', 'LAMBAYEQUE'),
('130201', 'LAMBAYEQUE', 'FERREÑAFE', 'FERREÑAFE', 'LAMBAYEQUE'),
('130202', 'LAMBAYEQUE', 'FERREÑAFE', 'INCAHUASI', 'LAMBAYEQUE'),
('130203', 'LAMBAYEQUE', 'FERREÑAFE', 'CAÑARIS', 'LAMBAYEQUE'),
('130204', 'LAMBAYEQUE', 'FERREÑAFE', 'PITIPO', 'LAMBAYEQUE'),
('130205', 'LAMBAYEQUE', 'FERREÑAFE', 'PUEBLO NUEVO', 'LAMBAYEQUE'),
('130206', 'LAMBAYEQUE', 'FERREÑAFE', 'MANUEL ANTONIO MESONES MURO', 'LAMBAYEQUE'),
('130301', 'LAMBAYEQUE', 'LAMBAYEQUE', 'LAMBAYEQUE', 'LAMBAYEQUE'),
('130302', 'LAMBAYEQUE', 'LAMBAYEQUE', 'CHOCHOPE', 'LAMBAYEQUE'),
('130303', 'LAMBAYEQUE', 'LAMBAYEQUE', 'ILLIMO', 'LAMBAYEQUE'),
('130304', 'LAMBAYEQUE', 'LAMBAYEQUE', 'JAYANCA', 'LAMBAYEQUE'),
('130305', 'LAMBAYEQUE', 'LAMBAYEQUE', 'MOCHUMI', 'LAMBAYEQUE'),
('130306', 'LAMBAYEQUE', 'LAMBAYEQUE', 'MORROPE', 'LAMBAYEQUE'),
('130307', 'LAMBAYEQUE', 'LAMBAYEQUE', 'MOTUPE', 'LAMBAYEQUE'),
('130308', 'LAMBAYEQUE', 'LAMBAYEQUE', 'OLMOS', 'LAMBAYEQUE'),
('130309', 'LAMBAYEQUE', 'LAMBAYEQUE', 'PACORA', 'LAMBAYEQUE'),
('130310', 'LAMBAYEQUE', 'LAMBAYEQUE', 'SALAS', 'LAMBAYEQUE'),
('130311', 'LAMBAYEQUE', 'LAMBAYEQUE', 'SAN JOSE', 'LAMBAYEQUE'),
('130312', 'LAMBAYEQUE', 'LAMBAYEQUE', 'TUCUME', 'LAMBAYEQUE'),
('140101', 'LIMA', 'LIMA', 'LIMA', 'LIMA PROVINCIA'),
('140102', 'LIMA', 'LIMA', 'ANCON', 'LIMA PROVINCIA'),
('140103', 'LIMA', 'LIMA', 'ATE', 'LIMA PROVINCIA'),
('140104', 'LIMA', 'LIMA', 'BREÑA', 'LIMA PROVINCIA'),
('140105', 'LIMA', 'LIMA', 'CARABAYLLO', 'LIMA PROVINCIA'),
('140106', 'LIMA', 'LIMA', 'COMAS', 'LIMA PROVINCIA'),
('140107', 'LIMA', 'LIMA', 'CHACLACAYO', 'LIMA PROVINCIA'),
('140108', 'LIMA', 'LIMA', 'CHORRILLOS', 'LIMA PROVINCIA'),
('140109', 'LIMA', 'LIMA', 'LA VICTORIA', 'LIMA PROVINCIA'),
('140110', 'LIMA', 'LIMA', 'LA MOLINA', 'LIMA PROVINCIA'),
('140111', 'LIMA', 'LIMA', 'LINCE', 'LIMA PROVINCIA'),
('140112', 'LIMA', 'LIMA', 'LURIGANCHO', 'LIMA PROVINCIA'),
('140113', 'LIMA', 'LIMA', 'LURIN', 'LIMA PROVINCIA'),
('140114', 'LIMA', 'LIMA', 'MAGDALENA DEL MAR', 'LIMA PROVINCIA'),
('140115', 'LIMA', 'LIMA', 'MIRAFLORES', 'LIMA PROVINCIA'),
('140116', 'LIMA', 'LIMA', 'PACHACAMAC', 'LIMA PROVINCIA'),
('140117', 'LIMA', 'LIMA', 'PUEBLO LIBRE', 'LIMA PROVINCIA'),
('140118', 'LIMA', 'LIMA', 'PUCUSANA', 'LIMA PROVINCIA'),
('140119', 'LIMA', 'LIMA', 'PUENTE PIEDRA', 'LIMA PROVINCIA'),
('140120', 'LIMA', 'LIMA', 'PUNTA HERMOSA', 'LIMA PROVINCIA'),
('140121', 'LIMA', 'LIMA', 'PUNTA NEGRA', 'LIMA PROVINCIA'),
('140122', 'LIMA', 'LIMA', 'RIMAC', 'LIMA PROVINCIA'),
('140123', 'LIMA', 'LIMA', 'SAN BARTOLO', 'LIMA PROVINCIA'),
('140124', 'LIMA', 'LIMA', 'SAN ISIDRO', 'LIMA PROVINCIA'),
('140125', 'LIMA', 'LIMA', 'BARRANCO', 'LIMA PROVINCIA'),
('140126', 'LIMA', 'LIMA', 'SAN MARTIN DE PORRES', 'LIMA PROVINCIA'),
('140127', 'LIMA', 'LIMA', 'SAN MIGUEL', 'LIMA PROVINCIA'),
('140128', 'LIMA', 'LIMA', 'SANTA MARIA DEL MAR', 'LIMA PROVINCIA'),
('140129', 'LIMA', 'LIMA', 'SANTA ROSA', 'LIMA PROVINCIA'),
('140130', 'LIMA', 'LIMA', 'SANTIAGO DE SURCO', 'LIMA PROVINCIA'),
('140131', 'LIMA', 'LIMA', 'SURQUILLO', 'LIMA PROVINCIA'),
('140132', 'LIMA', 'LIMA', 'VILLA MARIA DEL TRIUNFO', 'LIMA PROVINCIA'),
('140133', 'LIMA', 'LIMA', 'JESUS MARIA', 'LIMA PROVINCIA'),
('140134', 'LIMA', 'LIMA', 'INDEPENDENCIA', 'LIMA PROVINCIA'),
('140135', 'LIMA', 'LIMA', 'EL AGUSTINO', 'LIMA PROVINCIA'),
('140136', 'LIMA', 'LIMA', 'SAN JUAN DE MIRAFLORES', 'LIMA PROVINCIA'),
('140137', 'LIMA', 'LIMA', 'SAN JUAN DE LURIGANCHO', 'LIMA PROVINCIA'),
('140138', 'LIMA', 'LIMA', 'SAN LUIS', 'LIMA PROVINCIA'),
('140139', 'LIMA', 'LIMA', 'CIENEGUILLA', 'LIMA PROVINCIA'),
('140140', 'LIMA', 'LIMA', 'SAN BORJA', 'LIMA PROVINCIA'),
('140141', 'LIMA', 'LIMA', 'VILLA EL SALVADOR', 'LIMA PROVINCIA'),
('140142', 'LIMA', 'LIMA', 'LOS OLIVOS', 'LIMA PROVINCIA'),
('140143', 'LIMA', 'LIMA', 'SANTA ANITA', 'LIMA PROVINCIA'),
('140201', 'LIMA', 'CAJATAMBO', 'CAJATAMBO', 'LIMA REGION'),
('140205', 'LIMA', 'CAJATAMBO', 'COPA', 'LIMA REGION'),
('140206', 'LIMA', 'CAJATAMBO', 'GORGOR', 'LIMA REGION'),
('140207', 'LIMA', 'CAJATAMBO', 'HUANCAPON', 'LIMA REGION'),
('140208', 'LIMA', 'CAJATAMBO', 'MANAS', 'LIMA REGION'),
('140301', 'LIMA', 'CANTA', 'CANTA', 'LIMA REGION'),
('140302', 'LIMA', 'CANTA', 'ARAHUAY', 'LIMA REGION'),
('140303', 'LIMA', 'CANTA', 'HUAMANTANGA', 'LIMA REGION'),
('140304', 'LIMA', 'CANTA', 'HUAROS', 'LIMA REGION'),
('140305', 'LIMA', 'CANTA', 'LACHAQUI', 'LIMA REGION'),
('140306', 'LIMA', 'CANTA', 'SAN BUENAVENTURA', 'LIMA REGION'),
('140307', 'LIMA', 'CANTA', 'SANTA ROSA DE QUIVES', 'LIMA REGION'),
('140401', 'LIMA', 'CAÑETE', 'SAN VICENTE DE CAÑETE', 'LIMA REGION'),
('140402', 'LIMA', 'CAÑETE', 'CALANGO', 'LIMA REGION'),
('140403', 'LIMA', 'CAÑETE', 'CERRO AZUL', 'LIMA REGION'),
('140404', 'LIMA', 'CAÑETE', 'COAYLLO', 'LIMA REGION'),
('140405', 'LIMA', 'CAÑETE', 'CHILCA', 'LIMA REGION'),
('140406', 'LIMA', 'CAÑETE', 'IMPERIAL', 'LIMA REGION'),
('140407', 'LIMA', 'CAÑETE', 'LUNAHUANA', 'LIMA REGION'),
('140408', 'LIMA', 'CAÑETE', 'MALA', 'LIMA REGION'),
('140409', 'LIMA', 'CAÑETE', 'NUEVO IMPERIAL', 'LIMA REGION'),
('140410', 'LIMA', 'CAÑETE', 'PACARAN', 'LIMA REGION'),
('140411', 'LIMA', 'CAÑETE', 'QUILMANA', 'LIMA REGION'),
('140412', 'LIMA', 'CAÑETE', 'SAN ANTONIO', 'LIMA REGION'),
('140413', 'LIMA', 'CAÑETE', 'SAN LUIS', 'LIMA REGION'),
('140414', 'LIMA', 'CAÑETE', 'SANTA CRUZ DE FLORES', 'LIMA REGION'),
('140415', 'LIMA', 'CAÑETE', 'ZUÑIGA', 'LIMA REGION'),
('140416', 'LIMA', 'CAÑETE', 'ASIA', 'LIMA REGION'),
('140501', 'LIMA', 'HUAURA', 'HUACHO', 'LIMA REGION'),
('140502', 'LIMA', 'HUAURA', 'AMBAR', 'LIMA REGION'),
('140504', 'LIMA', 'HUAURA', 'CALETA DE CARQUIN', 'LIMA REGION'),
('140505', 'LIMA', 'HUAURA', 'CHECRAS', 'LIMA REGION'),
('140506', 'LIMA', 'HUAURA', 'HUALMAY', 'LIMA REGION'),
('140507', 'LIMA', 'HUAURA', 'HUAURA', 'LIMA REGION'),
('140508', 'LIMA', 'HUAURA', 'LEONCIO PRADO', 'LIMA REGION'),
('140509', 'LIMA', 'HUAURA', 'PACCHO', 'LIMA REGION'),
('140511', 'LIMA', 'HUAURA', 'SANTA LEONOR', 'LIMA REGION'),
('140512', 'LIMA', 'HUAURA', 'SANTA MARIA', 'LIMA REGION'),
('140513', 'LIMA', 'HUAURA', 'SAYAN', 'LIMA REGION'),
('140516', 'LIMA', 'HUAURA', 'VEGUETA', 'LIMA REGION'),
('140601', 'LIMA', 'HUAROCHIRI', 'MATUCANA', 'LIMA REGION'),
('140602', 'LIMA', 'HUAROCHIRI', 'ANTIOQUIA', 'LIMA REGION'),
('140603', 'LIMA', 'HUAROCHIRI', 'CALLAHUANCA', 'LIMA REGION'),
('140604', 'LIMA', 'HUAROCHIRI', 'CARAMPOMA', 'LIMA REGION'),
('140605', 'LIMA', 'HUAROCHIRI', 'SAN PEDRO DE CASTA', 'LIMA REGION'),
('140606', 'LIMA', 'HUAROCHIRI', 'CUENCA', 'LIMA REGION'),
('140607', 'LIMA', 'HUAROCHIRI', 'CHICLA', 'LIMA REGION'),
('140608', 'LIMA', 'HUAROCHIRI', 'HUANZA', 'LIMA REGION'),
('140609', 'LIMA', 'HUAROCHIRI', 'HUAROCHIRI', 'LIMA REGION'),
('140610', 'LIMA', 'HUAROCHIRI', 'LAHUAYTAMBO', 'LIMA REGION'),
('140611', 'LIMA', 'HUAROCHIRI', 'LANGA', 'LIMA REGION'),
('140612', 'LIMA', 'HUAROCHIRI', 'MARIATANA', 'LIMA REGION'),
('140613', 'LIMA', 'HUAROCHIRI', 'RICARDO PALMA', 'LIMA REGION'),
('140614', 'LIMA', 'HUAROCHIRI', 'SAN ANDRES DE TUPICOCHA', 'LIMA REGION'),
('140615', 'LIMA', 'HUAROCHIRI', 'SAN ANTONIO', 'LIMA REGION'),
('140616', 'LIMA', 'HUAROCHIRI', 'SAN BARTOLOME', 'LIMA REGION'),
('140617', 'LIMA', 'HUAROCHIRI', 'SAN DAMIAN', 'LIMA REGION'),
('140618', 'LIMA', 'HUAROCHIRI', 'SANGALLAYA', 'LIMA REGION'),
('140619', 'LIMA', 'HUAROCHIRI', 'SAN JUAN DE TANTARANCHE', 'LIMA REGION'),
('140620', 'LIMA', 'HUAROCHIRI', 'SAN LORENZO DE QUINTI', 'LIMA REGION'),
('140621', 'LIMA', 'HUAROCHIRI', 'SAN MATEO', 'LIMA REGION'),
('140622', 'LIMA', 'HUAROCHIRI', 'SAN MATEO DE OTAO', 'LIMA REGION'),
('140623', 'LIMA', 'HUAROCHIRI', 'SAN PEDRO DE HUANCAYRE', 'LIMA REGION'),
('140624', 'LIMA', 'HUAROCHIRI', 'SANTA CRUZ DE COCACHACRA', 'LIMA REGION'),
('140625', 'LIMA', 'HUAROCHIRI', 'SANTA EULALIA', 'LIMA REGION'),
('140626', 'LIMA', 'HUAROCHIRI', 'SANTIAGO DE ANCHUCAYA', 'LIMA REGION'),
('140627', 'LIMA', 'HUAROCHIRI', 'SANTIAGO DE TUNA', 'LIMA REGION'),
('140628', 'LIMA', 'HUAROCHIRI', 'SANTO DOMINGO DE LOS OLLEROS', 'LIMA REGION'),
('140629', 'LIMA', 'HUAROCHIRI', 'SURCO', 'LIMA REGION'),
('140630', 'LIMA', 'HUAROCHIRI', 'HUACHUPAMPA', 'LIMA REGION'),
('140631', 'LIMA', 'HUAROCHIRI', 'LARAOS', 'LIMA REGION'),
('140632', 'LIMA', 'HUAROCHIRI', 'SAN JUAN DE IRIS', 'LIMA REGION'),
('140701', 'LIMA', 'YAUYOS', 'YAUYOS', 'LIMA REGION'),
('140702', 'LIMA', 'YAUYOS', 'ALIS', 'LIMA REGION'),
('140703', 'LIMA', 'YAUYOS', 'AYAUCA', 'LIMA REGION'),
('140704', 'LIMA', 'YAUYOS', 'AYAVIRI', 'LIMA REGION'),
('140705', 'LIMA', 'YAUYOS', 'AZANGARO', 'LIMA REGION'),
('140706', 'LIMA', 'YAUYOS', 'CACRA', 'LIMA REGION'),
('140707', 'LIMA', 'YAUYOS', 'CARANIA', 'LIMA REGION'),
('140708', 'LIMA', 'YAUYOS', 'COCHAS', 'LIMA REGION'),
('140709', 'LIMA', 'YAUYOS', 'COLONIA', 'LIMA REGION'),
('140710', 'LIMA', 'YAUYOS', 'CHOCOS', 'LIMA REGION'),
('140711', 'LIMA', 'YAUYOS', 'HUAMPARA', 'LIMA REGION'),
('140712', 'LIMA', 'YAUYOS', 'HUANCAYA', 'LIMA REGION'),
('140713', 'LIMA', 'YAUYOS', 'HUANGASCAR', 'LIMA REGION'),
('140714', 'LIMA', 'YAUYOS', 'HUANTAN', 'LIMA REGION'),
('140715', 'LIMA', 'YAUYOS', 'HUAÑEC', 'LIMA REGION'),
('140716', 'LIMA', 'YAUYOS', 'LARAOS', 'LIMA REGION'),
('140717', 'LIMA', 'YAUYOS', 'LINCHA', 'LIMA REGION'),
('140718', 'LIMA', 'YAUYOS', 'MIRAFLORES', 'LIMA REGION'),
('140719', 'LIMA', 'YAUYOS', 'OMAS', 'LIMA REGION'),
('140720', 'LIMA', 'YAUYOS', 'QUINCHES', 'LIMA REGION'),
('140721', 'LIMA', 'YAUYOS', 'QUINOCAY', 'LIMA REGION'),
('140722', 'LIMA', 'YAUYOS', 'SAN JOAQUIN', 'LIMA REGION'),
('140723', 'LIMA', 'YAUYOS', 'SAN PEDRO DE PILAS', 'LIMA REGION'),
('140724', 'LIMA', 'YAUYOS', 'TANTA', 'LIMA REGION'),
('140725', 'LIMA', 'YAUYOS', 'TAURIPAMPA', 'LIMA REGION'),
('140726', 'LIMA', 'YAUYOS', 'TUPE', 'LIMA REGION'),
('140727', 'LIMA', 'YAUYOS', 'TOMAS', 'LIMA REGION'),
('140728', 'LIMA', 'YAUYOS', 'VIÑAC', 'LIMA REGION'),
('140729', 'LIMA', 'YAUYOS', 'VITIS', 'LIMA REGION'),
('140730', 'LIMA', 'YAUYOS', 'HONGOS', 'LIMA REGION'),
('140731', 'LIMA', 'YAUYOS', 'MADEAN', 'LIMA REGION'),
('140732', 'LIMA', 'YAUYOS', 'PUTINZA', 'LIMA REGION'),
('140733', 'LIMA', 'YAUYOS', 'CATAHUASI', 'LIMA REGION'),
('140801', 'LIMA', 'HUARAL', 'HUARAL', 'LIMA REGION'),
('140802', 'LIMA', 'HUARAL', 'ATAVILLOS ALTO', 'LIMA REGION'),
('140803', 'LIMA', 'HUARAL', 'ATAVILLOS BAJO', 'LIMA REGION'),
('140804', 'LIMA', 'HUARAL', 'AUCALLAMA', 'LIMA REGION'),
('140805', 'LIMA', 'HUARAL', 'CHANCAY', 'LIMA REGION'),
('140806', 'LIMA', 'HUARAL', 'IHUARI', 'LIMA REGION'),
('140807', 'LIMA', 'HUARAL', 'LAMPIAN', 'LIMA REGION'),
('140808', 'LIMA', 'HUARAL', 'PACARAOS', 'LIMA REGION'),
('140809', 'LIMA', 'HUARAL', 'SAN MIGUEL DE ACOS', 'LIMA REGION'),
('140810', 'LIMA', 'HUARAL', 'VEINTISIETE DE NOVIEMBRE', 'LIMA REGION'),
('140811', 'LIMA', 'HUARAL', 'SANTA CRUZ DE ANDAMARCA', 'LIMA REGION'),
('140812', 'LIMA', 'HUARAL', 'SUMBILCA', 'LIMA REGION'),
('140901', 'LIMA', 'BARRANCA', 'BARRANCA', 'LIMA REGION'),
('140902', 'LIMA', 'BARRANCA', 'PARAMONGA', 'LIMA REGION'),
('140903', 'LIMA', 'BARRANCA', 'PATIVILCA', 'LIMA REGION'),
('140904', 'LIMA', 'BARRANCA', 'SUPE', 'LIMA REGION'),
('140905', 'LIMA', 'BARRANCA', 'SUPE PUERTO', 'LIMA REGION'),
('141001', 'LIMA', 'OYON', 'OYON', 'LIMA REGION'),
('141002', 'LIMA', 'OYON', 'NAVAN', 'LIMA REGION'),
('141003', 'LIMA', 'OYON', 'CAUJUL', 'LIMA REGION'),
('141004', 'LIMA', 'OYON', 'ANDAJES', 'LIMA REGION'),
('141005', 'LIMA', 'OYON', 'PACHANGARA', 'LIMA REGION'),
('141006', 'LIMA', 'OYON', 'COCHAMARCA', 'LIMA REGION'),
('150101', 'LORETO', 'MAYNAS', 'IQUITOS', 'LORETO'),
('150102', 'LORETO', 'MAYNAS', 'ALTO NANAY', 'LORETO'),
('150103', 'LORETO', 'MAYNAS', 'FERNANDO LORES', 'LORETO'),
('150104', 'LORETO', 'MAYNAS', 'LAS AMAZONAS', 'LORETO'),
('150105', 'LORETO', 'MAYNAS', 'MAZAN', 'LORETO'),
('150106', 'LORETO', 'MAYNAS', 'NAPO', 'LORETO'),
('150107', 'LORETO', 'MAYNAS', 'PUTUMAYO', 'LORETO'),
('150108', 'LORETO', 'MAYNAS', 'TORRES CAUSANA', 'LORETO'),
('150110', 'LORETO', 'MAYNAS', 'INDIANA', 'LORETO'),
('150111', 'LORETO', 'MAYNAS', 'PUNCHANA', 'LORETO'),
('150112', 'LORETO', 'MAYNAS', 'BELEN', 'LORETO'),
('150113', 'LORETO', 'MAYNAS', 'SAN JUAN BAUTISTA', 'LORETO'),
('150114', 'LORETO', 'MAYNAS', 'TENIENTE MANUEL CLAVERO', 'LORETO'),
('150201', 'LORETO', 'ALTO AMAZONAS', 'YURIMAGUAS', 'LORETO'),
('150202', 'LORETO', 'ALTO AMAZONAS', 'BALSAPUERTO', 'LORETO'),
('150205', 'LORETO', 'ALTO AMAZONAS', 'JEBEROS', 'LORETO'),
('150206', 'LORETO', 'ALTO AMAZONAS', 'LAGUNAS', 'LORETO'),
('150210', 'LORETO', 'ALTO AMAZONAS', 'SANTA CRUZ', 'LORETO'),
('150211', 'LORETO', 'ALTO AMAZONAS', 'TENIENTE CESAR LOPEZ ROJAS', 'LORETO'),
('150301', 'LORETO', 'LORETO', 'NAUTA', 'LORETO'),
('150302', 'LORETO', 'LORETO', 'PARINARI', 'LORETO'),
('150303', 'LORETO', 'LORETO', 'TIGRE', 'LORETO'),
('150304', 'LORETO', 'LORETO', 'URARINAS', 'LORETO'),
('150305', 'LORETO', 'LORETO', 'TROMPETEROS', 'LORETO'),
('150401', 'LORETO', 'REQUENA', 'REQUENA', 'LORETO'),
('150402', 'LORETO', 'REQUENA', 'ALTO TAPICHE', 'LORETO'),
('150403', 'LORETO', 'REQUENA', 'CAPELO', 'LORETO'),
('150404', 'LORETO', 'REQUENA', 'EMILIO SAN MARTIN', 'LORETO'),
('150405', 'LORETO', 'REQUENA', 'MAQUIA', 'LORETO'),
('150406', 'LORETO', 'REQUENA', 'PUINAHUA', 'LORETO'),
('150407', 'LORETO', 'REQUENA', 'SAQUENA', 'LORETO'),
('150408', 'LORETO', 'REQUENA', 'SOPLIN', 'LORETO'),
('150409', 'LORETO', 'REQUENA', 'TAPICHE', 'LORETO'),
('150410', 'LORETO', 'REQUENA', 'JENARO HERRERA', 'LORETO'),
('150411', 'LORETO', 'REQUENA', 'YAQUERANA', 'LORETO'),
('150501', 'LORETO', 'UCAYALI', 'CONTAMANA', 'LORETO'),
('150502', 'LORETO', 'UCAYALI', 'VARGAS GUERRA', 'LORETO'),
('150503', 'LORETO', 'UCAYALI', 'PADRE MARQUEZ', 'LORETO'),
('150504', 'LORETO', 'UCAYALI', 'PAMPA HERMOSA', 'LORETO'),
('150505', 'LORETO', 'UCAYALI', 'SARAYACU', 'LORETO'),
('150506', 'LORETO', 'UCAYALI', 'INAHUAYA', 'LORETO'),
('150601', 'LORETO', 'MARISCAL RAMON CASTILLA', 'RAMON CASTILLA', 'LORETO'),
('150602', 'LORETO', 'MARISCAL RAMON CASTILLA', 'PEBAS', 'LORETO'),
('150603', 'LORETO', 'MARISCAL RAMON CASTILLA', 'YAVARI', 'LORETO'),
('150604', 'LORETO', 'MARISCAL RAMON CASTILLA', 'SAN PABLO', 'LORETO'),
('150701', 'LORETO', 'DATEM DEL MARAÑON', 'BARRANCA', 'LORETO'),
('150702', 'LORETO', 'DATEM DEL MARAÑON', 'ANDOAS', 'LORETO'),
('150703', 'LORETO', 'DATEM DEL MARAÑON', 'CAHUAPANAS', 'LORETO'),
('150704', 'LORETO', 'DATEM DEL MARAÑON', 'MANSERICHE', 'LORETO'),
('150705', 'LORETO', 'DATEM DEL MARAÑON', 'MORONA', 'LORETO'),
('150706', 'LORETO', 'DATEM DEL MARAÑON', 'PASTAZA', 'LORETO'),
('150901', 'LORETO', 'PUTUMAYO', 'PUTUMAYO', 'LORETO'),
('150902', 'LORETO', 'PUTUMAYO', 'ROSA PANDURO', 'LORETO'),
('150903', 'LORETO', 'PUTUMAYO', 'TENIENTE MANUEL CLAVERO', 'LORETO'),
('150904', 'LORETO', 'PUTUMAYO', 'YAGUAS', 'LORETO'),
('160101', 'MADRE DE DIOS', 'TAMBOPATA', 'TAMBOPATA', 'MADRE DE DIOS'),
('160102', 'MADRE DE DIOS', 'TAMBOPATA', 'INAMBARI', 'MADRE DE DIOS'),
('160103', 'MADRE DE DIOS', 'TAMBOPATA', 'LAS PIEDRAS', 'MADRE DE DIOS'),
('160104', 'MADRE DE DIOS', 'TAMBOPATA', 'LABERINTO', 'MADRE DE DIOS'),
('160201', 'MADRE DE DIOS', 'MANU', 'MANU', 'MADRE DE DIOS'),
('160202', 'MADRE DE DIOS', 'MANU', 'FITZCARRALD', 'MADRE DE DIOS'),
('160203', 'MADRE DE DIOS', 'MANU', 'MADRE DE DIOS', 'MADRE DE DIOS'),
('160204', 'MADRE DE DIOS', 'MANU', 'HUEPETUHE', 'MADRE DE DIOS'),
('160301', 'MADRE DE DIOS', 'TAHUAMANU', 'IÑAPARI', 'MADRE DE DIOS'),
('160302', 'MADRE DE DIOS', 'TAHUAMANU', 'IBERIA', 'MADRE DE DIOS'),
('160303', 'MADRE DE DIOS', 'TAHUAMANU', 'TAHUAMANU', 'MADRE DE DIOS'),
('170101', 'MOQUEGUA', 'MARISCAL NIETO', 'MOQUEGUA', 'MOQUEGUA'),
('170102', 'MOQUEGUA', 'MARISCAL NIETO', 'CARUMAS', 'MOQUEGUA'),
('170103', 'MOQUEGUA', 'MARISCAL NIETO', 'CUCHUMBAYA', 'MOQUEGUA'),
('170104', 'MOQUEGUA', 'MARISCAL NIETO', 'SAN CRISTOBAL', 'MOQUEGUA'),
('170105', 'MOQUEGUA', 'MARISCAL NIETO', 'TORATA', 'MOQUEGUA'),
('170106', 'MOQUEGUA', 'MARISCAL NIETO', 'SAMEGUA', 'MOQUEGUA'),
('170107', 'MOQUEGUA', 'MARISCAL NIETO', 'SAN ANTONIO', 'MOQUEGUA'),
('170201', 'MOQUEGUA', 'GENERAL SANCHEZ CERRO', 'OMATE', 'MOQUEGUA'),
('170202', 'MOQUEGUA', 'GENERAL SANCHEZ CERRO', 'COALAQUE', 'MOQUEGUA'),
('170203', 'MOQUEGUA', 'GENERAL SANCHEZ CERRO', 'CHOJATA', 'MOQUEGUA'),
('170204', 'MOQUEGUA', 'GENERAL SANCHEZ CERRO', 'ICHUÑA', 'MOQUEGUA'),
('170205', 'MOQUEGUA', 'GENERAL SANCHEZ CERRO', 'LA CAPILLA', 'MOQUEGUA'),
('170206', 'MOQUEGUA', 'GENERAL SANCHEZ CERRO', 'LLOQUE', 'MOQUEGUA'),
('170207', 'MOQUEGUA', 'GENERAL SANCHEZ CERRO', 'MATALAQUE', 'MOQUEGUA'),
('170208', 'MOQUEGUA', 'GENERAL SANCHEZ CERRO', 'PUQUINA', 'MOQUEGUA'),
('170209', 'MOQUEGUA', 'GENERAL SANCHEZ CERRO', 'QUINISTAQUILLAS', 'MOQUEGUA'),
('170210', 'MOQUEGUA', 'GENERAL SANCHEZ CERRO', 'UBINAS', 'MOQUEGUA'),
('170211', 'MOQUEGUA', 'GENERAL SANCHEZ CERRO', 'YUNGA', 'MOQUEGUA'),
('170301', 'MOQUEGUA', 'ILO', 'ILO', 'MOQUEGUA'),
('170302', 'MOQUEGUA', 'ILO', 'EL ALGARROBAL', 'MOQUEGUA'),
('170303', 'MOQUEGUA', 'ILO', 'PACOCHA', 'MOQUEGUA'),
('180101', 'PASCO', 'PASCO', 'CHAUPIMARCA', 'PASCO'),
('180103', 'PASCO', 'PASCO', 'HUACHON', 'PASCO'),
('180104', 'PASCO', 'PASCO', 'HUARIACA', 'PASCO'),
('180105', 'PASCO', 'PASCO', 'HUAYLLAY', 'PASCO'),
('180106', 'PASCO', 'PASCO', 'NINACACA', 'PASCO'),
('180107', 'PASCO', 'PASCO', 'PALLANCHACRA', 'PASCO'),
('180108', 'PASCO', 'PASCO', 'PAUCARTAMBO', 'PASCO'),
('180109', 'PASCO', 'PASCO', 'SAN FRANCISCO DE ASIS DE YARUSYACAN', 'PASCO'),
('180110', 'PASCO', 'PASCO', 'SIMON BOLIVAR', 'PASCO'),
('180111', 'PASCO', 'PASCO', 'TICLACAYAN', 'PASCO'),
('180112', 'PASCO', 'PASCO', 'TINYAHUARCO', 'PASCO'),
('180113', 'PASCO', 'PASCO', 'VICCO', 'PASCO'),
('180114', 'PASCO', 'PASCO', 'YANACANCHA', 'PASCO'),
('180201', 'PASCO', 'DANIEL ALCIDES CARRION', 'YANAHUANCA', 'PASCO'),
('180202', 'PASCO', 'DANIEL ALCIDES CARRION', 'CHACAYAN', 'PASCO'),
('180203', 'PASCO', 'DANIEL ALCIDES CARRION', 'GOYLLARISQUIZGA', 'PASCO'),
('180204', 'PASCO', 'DANIEL ALCIDES CARRION', 'PAUCAR', 'PASCO'),
('180205', 'PASCO', 'DANIEL ALCIDES CARRION', 'SAN PEDRO DE PILLAO', 'PASCO'),
('180206', 'PASCO', 'DANIEL ALCIDES CARRION', 'SANTA ANA DE TUSI', 'PASCO'),
('180207', 'PASCO', 'DANIEL ALCIDES CARRION', 'TAPUC', 'PASCO'),
('180208', 'PASCO', 'DANIEL ALCIDES CARRION', 'VILCABAMBA', 'PASCO'),
('180301', 'PASCO', 'OXAPAMPA', 'OXAPAMPA', 'PASCO'),
('180302', 'PASCO', 'OXAPAMPA', 'CHONTABAMBA', 'PASCO'),
('180303', 'PASCO', 'OXAPAMPA', 'HUANCABAMBA', 'PASCO'),
('180304', 'PASCO', 'OXAPAMPA', 'PUERTO BERMUDEZ', 'PASCO'),
('180305', 'PASCO', 'OXAPAMPA', 'VILLA RICA', 'PASCO'),
('180306', 'PASCO', 'OXAPAMPA', 'POZUZO', 'PASCO'),
('180307', 'PASCO', 'OXAPAMPA', 'PALCAZU', 'PASCO'),
('180308', 'PASCO', 'OXAPAMPA', 'CONSTITUCION', 'PASCO'),
('190101', 'PIURA', 'PIURA', 'PIURA', 'PIURA'),
('190103', 'PIURA', 'PIURA', 'CASTILLA', 'PIURA'),
('190104', 'PIURA', 'PIURA', 'CATACAOS', 'PIURA'),
('190105', 'PIURA', 'PIURA', 'LA ARENA', 'PIURA'),
('190106', 'PIURA', 'PIURA', 'LA UNION', 'PIURA'),
('190107', 'PIURA', 'PIURA', 'LAS LOMAS', 'PIURA'),
('190109', 'PIURA', 'PIURA', 'TAMBO GRANDE', 'PIURA'),
('190113', 'PIURA', 'PIURA', 'CURA MORI', 'PIURA'),
('190114', 'PIURA', 'PIURA', 'EL TALLAN', 'PIURA'),
('190115', 'PIURA', 'PIURA', 'VEINTISEIS DE OCTUBRE', 'PIURA'),
('190201', 'PIURA', 'AYABACA', 'AYABACA', 'PIURA'),
('190202', 'PIURA', 'AYABACA', 'FRIAS', 'PIURA'),
('190203', 'PIURA', 'AYABACA', 'LAGUNAS', 'PIURA'),
('190204', 'PIURA', 'AYABACA', 'MONTERO', 'PIURA'),
('190205', 'PIURA', 'AYABACA', 'PACAIPAMPA', 'PIURA'),
('190206', 'PIURA', 'AYABACA', 'SAPILLICA', 'PIURA'),
('190207', 'PIURA', 'AYABACA', 'SICCHEZ', 'PIURA'),
('190208', 'PIURA', 'AYABACA', 'SUYO', 'PIURA'),
('190209', 'PIURA', 'AYABACA', 'JILILI', 'PIURA'),
('190210', 'PIURA', 'AYABACA', 'PAIMAS', 'PIURA'),
('190301', 'PIURA', 'HUANCABAMBA', 'HUANCABAMBA', 'PIURA'),
('190302', 'PIURA', 'HUANCABAMBA', 'CANCHAQUE', 'PIURA'),
('190303', 'PIURA', 'HUANCABAMBA', 'HUARMACA', 'PIURA'),
('190304', 'PIURA', 'HUANCABAMBA', 'SONDOR', 'PIURA'),
('190305', 'PIURA', 'HUANCABAMBA', 'SONDORILLO', 'PIURA'),
('190306', 'PIURA', 'HUANCABAMBA', 'EL CARMEN DE LA FRONTERA', 'PIURA'),
('190307', 'PIURA', 'HUANCABAMBA', 'SAN MIGUEL DE EL FAIQUE', 'PIURA'),
('190308', 'PIURA', 'HUANCABAMBA', 'LALAQUIZ', 'PIURA'),
('190401', 'PIURA', 'MORROPON', 'CHULUCANAS', 'PIURA'),
('190402', 'PIURA', 'MORROPON', 'BUENOS AIRES', 'PIURA'),
('190403', 'PIURA', 'MORROPON', 'CHALACO', 'PIURA'),
('190404', 'PIURA', 'MORROPON', 'MORROPON', 'PIURA'),
('190405', 'PIURA', 'MORROPON', 'SALITRAL', 'PIURA'),
('190406', 'PIURA', 'MORROPON', 'SANTA CATALINA DE MOSSA', 'PIURA'),
('190407', 'PIURA', 'MORROPON', 'SANTO DOMINGO', 'PIURA'),
('190408', 'PIURA', 'MORROPON', 'LA MATANZA', 'PIURA'),
('190409', 'PIURA', 'MORROPON', 'YAMANGO', 'PIURA'),
('190410', 'PIURA', 'MORROPON', 'SAN JUAN DE BIGOTE', 'PIURA'),
('190501', 'PIURA', 'PAITA', 'PAITA', 'PIURA'),
('190502', 'PIURA', 'PAITA', 'AMOTAPE', 'PIURA'),
('190503', 'PIURA', 'PAITA', 'ARENAL', 'PIURA'),
('190504', 'PIURA', 'PAITA', 'LA HUACA', 'PIURA'),
('190505', 'PIURA', 'PAITA', 'COLAN', 'PIURA'),
('190506', 'PIURA', 'PAITA', 'TAMARINDO', 'PIURA'),
('190507', 'PIURA', 'PAITA', 'VICHAYAL', 'PIURA'),
('190601', 'PIURA', 'SULLANA', 'SULLANA', 'PIURA'),
('190602', 'PIURA', 'SULLANA', 'BELLAVISTA', 'PIURA'),
('190603', 'PIURA', 'SULLANA', 'LANCONES', 'PIURA'),
('190604', 'PIURA', 'SULLANA', 'MARCAVELICA', 'PIURA'),
('190605', 'PIURA', 'SULLANA', 'MIGUEL CHECA', 'PIURA'),
('190606', 'PIURA', 'SULLANA', 'QUERECOTILLO', 'PIURA'),
('190607', 'PIURA', 'SULLANA', 'SALITRAL', 'PIURA'),
('190608', 'PIURA', 'SULLANA', 'IGNACIO ESCUDERO', 'PIURA'),
('190701', 'PIURA', 'TALARA', 'PARIÑAS', 'PIURA'),
('190702', 'PIURA', 'TALARA', 'EL ALTO', 'PIURA'),
('190703', 'PIURA', 'TALARA', 'LA BREA', 'PIURA'),
('190704', 'PIURA', 'TALARA', 'LOBITOS', 'PIURA'),
('190705', 'PIURA', 'TALARA', 'MANCORA', 'PIURA'),
('190706', 'PIURA', 'TALARA', 'LOS ORGANOS', 'PIURA'),
('190801', 'PIURA', 'SECHURA', 'SECHURA', 'PIURA'),
('190802', 'PIURA', 'SECHURA', 'VICE', 'PIURA'),
('190803', 'PIURA', 'SECHURA', 'BERNAL', 'PIURA'),
('190804', 'PIURA', 'SECHURA', 'BELLAVISTA DE LA UNION', 'PIURA'),
('190805', 'PIURA', 'SECHURA', 'CRISTO NOS VALGA', 'PIURA'),
('190806', 'PIURA', 'SECHURA', 'RINCONADA LLICUAR', 'PIURA'),
('200101', 'PUNO', 'PUNO', 'PUNO', 'PUNO'),
('200102', 'PUNO', 'PUNO', 'ACORA', 'PUNO'),
('200103', 'PUNO', 'PUNO', 'ATUNCOLLA', 'PUNO'),
('200104', 'PUNO', 'PUNO', 'CAPACHICA', 'PUNO'),
('200105', 'PUNO', 'PUNO', 'COATA', 'PUNO'),
('200106', 'PUNO', 'PUNO', 'CHUCUITO', 'PUNO'),
('200107', 'PUNO', 'PUNO', 'HUATA', 'PUNO'),
('200108', 'PUNO', 'PUNO', 'MAÑAZO', 'PUNO'),
('200109', 'PUNO', 'PUNO', 'PAUCARCOLLA', 'PUNO'),
('200110', 'PUNO', 'PUNO', 'PICHACANI', 'PUNO'),
('200111', 'PUNO', 'PUNO', 'SAN ANTONIO', 'PUNO'),
('200112', 'PUNO', 'PUNO', 'TIQUILLACA', 'PUNO'),
('200113', 'PUNO', 'PUNO', 'VILQUE', 'PUNO'),
('200114', 'PUNO', 'PUNO', 'PLATERIA', 'PUNO'),
('200115', 'PUNO', 'PUNO', 'AMANTANI', 'PUNO'),
('200201', 'PUNO', 'AZANGARO', 'AZANGARO', 'PUNO'),
('200202', 'PUNO', 'AZANGARO', 'ACHAYA', 'PUNO'),
('200203', 'PUNO', 'AZANGARO', 'ARAPA', 'PUNO'),
('200204', 'PUNO', 'AZANGARO', 'ASILLO', 'PUNO'),
('200205', 'PUNO', 'AZANGARO', 'CAMINACA', 'PUNO'),
('200206', 'PUNO', 'AZANGARO', 'CHUPA', 'PUNO'),
('200207', 'PUNO', 'AZANGARO', 'JOSE DOMINGO CHOQUEHUANCA', 'PUNO'),
('200208', 'PUNO', 'AZANGARO', 'MUÑANI', 'PUNO'),
('200210', 'PUNO', 'AZANGARO', 'POTONI', 'PUNO'),
('200212', 'PUNO', 'AZANGARO', 'SAMAN', 'PUNO'),
('200213', 'PUNO', 'AZANGARO', 'SAN ANTON', 'PUNO'),
('200214', 'PUNO', 'AZANGARO', 'SAN JOSE', 'PUNO'),
('200215', 'PUNO', 'AZANGARO', 'SAN JUAN DE SALINAS', 'PUNO'),
('200216', 'PUNO', 'AZANGARO', 'SANTIAGO DE PUPUJA', 'PUNO'),
('200217', 'PUNO', 'AZANGARO', 'TIRAPATA', 'PUNO'),
('200301', 'PUNO', 'CARABAYA', 'MACUSANI', 'PUNO'),
('200302', 'PUNO', 'CARABAYA', 'AJOYANI', 'PUNO'),
('200303', 'PUNO', 'CARABAYA', 'AYAPATA', 'PUNO'),
('200304', 'PUNO', 'CARABAYA', 'COASA', 'PUNO'),
('200305', 'PUNO', 'CARABAYA', 'CORANI', 'PUNO'),
('200306', 'PUNO', 'CARABAYA', 'CRUCERO', 'PUNO'),
('200307', 'PUNO', 'CARABAYA', 'ITUATA', 'PUNO'),
('200308', 'PUNO', 'CARABAYA', 'OLLACHEA', 'PUNO'),
('200309', 'PUNO', 'CARABAYA', 'SAN GABAN', 'PUNO'),
('200310', 'PUNO', 'CARABAYA', 'USICAYOS', 'PUNO'),
('200401', 'PUNO', 'CHUCUITO', 'JULI', 'PUNO'),
('200402', 'PUNO', 'CHUCUITO', 'DESAGUADERO', 'PUNO'),
('200403', 'PUNO', 'CHUCUITO', 'HUACULLANI', 'PUNO'),
('200406', 'PUNO', 'CHUCUITO', 'PISACOMA', 'PUNO'),
('200407', 'PUNO', 'CHUCUITO', 'POMATA', 'PUNO'),
('200410', 'PUNO', 'CHUCUITO', 'ZEPITA', 'PUNO'),
('200412', 'PUNO', 'CHUCUITO', 'KELLUYO', 'PUNO'),
('200501', 'PUNO', 'HUANCANE', 'HUANCANE', 'PUNO'),
('200502', 'PUNO', 'HUANCANE', 'COJATA', 'PUNO'),
('200504', 'PUNO', 'HUANCANE', 'INCHUPALLA', 'PUNO'),
('200506', 'PUNO', 'HUANCANE', 'PUSI', 'PUNO'),
('200507', 'PUNO', 'HUANCANE', 'ROSASPATA', 'PUNO'),
('200508', 'PUNO', 'HUANCANE', 'TARACO', 'PUNO'),
('200509', 'PUNO', 'HUANCANE', 'VILQUE CHICO', 'PUNO'),
('200511', 'PUNO', 'HUANCANE', 'HUATASANI', 'PUNO'),
('200601', 'PUNO', 'LAMPA', 'LAMPA', 'PUNO'),
('200602', 'PUNO', 'LAMPA', 'CABANILLA', 'PUNO'),
('200603', 'PUNO', 'LAMPA', 'CALAPUJA', 'PUNO'),
('200604', 'PUNO', 'LAMPA', 'NICASIO', 'PUNO'),
('200605', 'PUNO', 'LAMPA', 'OCUVIRI', 'PUNO'),
('200606', 'PUNO', 'LAMPA', 'PALCA', 'PUNO'),
('200607', 'PUNO', 'LAMPA', 'PARATIA', 'PUNO'),
('200608', 'PUNO', 'LAMPA', 'PUCARA', 'PUNO'),
('200609', 'PUNO', 'LAMPA', 'SANTA LUCIA', 'PUNO'),
('200610', 'PUNO', 'LAMPA', 'VILAVILA', 'PUNO'),
('200701', 'PUNO', 'MELGAR', 'AYAVIRI', 'PUNO'),
('200702', 'PUNO', 'MELGAR', 'ANTAUTA', 'PUNO'),
('200703', 'PUNO', 'MELGAR', 'CUPI', 'PUNO'),
('200704', 'PUNO', 'MELGAR', 'LLALLI', 'PUNO'),
('200705', 'PUNO', 'MELGAR', 'MACARI', 'PUNO'),
('200706', 'PUNO', 'MELGAR', 'NUÑOA', 'PUNO'),
('200707', 'PUNO', 'MELGAR', 'ORURILLO', 'PUNO'),
('200708', 'PUNO', 'MELGAR', 'SANTA ROSA', 'PUNO'),
('200709', 'PUNO', 'MELGAR', 'UMACHIRI', 'PUNO'),
('200801', 'PUNO', 'SANDIA', 'SANDIA', 'PUNO'),
('200803', 'PUNO', 'SANDIA', 'CUYOCUYO', 'PUNO'),
('200804', 'PUNO', 'SANDIA', 'LIMBANI', 'PUNO'),
('200805', 'PUNO', 'SANDIA', 'PHARA', 'PUNO'),
('200806', 'PUNO', 'SANDIA', 'PATAMBUCO', 'PUNO'),
('200807', 'PUNO', 'SANDIA', 'QUIACA', 'PUNO'),
('200808', 'PUNO', 'SANDIA', 'SAN JUAN DEL ORO', 'PUNO'),
('200810', 'PUNO', 'SANDIA', 'YANAHUAYA', 'PUNO');
INSERT INTO `tb_ubigeos` (`ubigeo_reniec`, `departamento`, `provincia`, `distrito`, `region`) VALUES
('200811', 'PUNO', 'SANDIA', 'ALTO INAMBARI', 'PUNO'),
('200812', 'PUNO', 'SANDIA', 'SAN PEDRO DE PUTINA PUNCO', 'PUNO'),
('200901', 'PUNO', 'SAN ROMAN', 'JULIACA', 'PUNO'),
('200902', 'PUNO', 'SAN ROMAN', 'CABANA', 'PUNO'),
('200903', 'PUNO', 'SAN ROMAN', 'CABANILLAS', 'PUNO'),
('200904', 'PUNO', 'SAN ROMAN', 'CARACOTO', 'PUNO'),
('200905', 'PUNO', 'SAN ROMAN', 'SAN MIGUEL', 'PUNO'),
('201001', 'PUNO', 'YUNGUYO', 'YUNGUYO', 'PUNO'),
('201002', 'PUNO', 'YUNGUYO', 'UNICACHI', 'PUNO'),
('201003', 'PUNO', 'YUNGUYO', 'ANAPIA', 'PUNO'),
('201004', 'PUNO', 'YUNGUYO', 'COPANI', 'PUNO'),
('201005', 'PUNO', 'YUNGUYO', 'CUTURAPI', 'PUNO'),
('201006', 'PUNO', 'YUNGUYO', 'OLLARAYA', 'PUNO'),
('201007', 'PUNO', 'YUNGUYO', 'TINICACHI', 'PUNO'),
('201101', 'PUNO', 'SAN ANTONIO DE PUTINA', 'PUTINA', 'PUNO'),
('201102', 'PUNO', 'SAN ANTONIO DE PUTINA', 'PEDRO VILCA APAZA', 'PUNO'),
('201103', 'PUNO', 'SAN ANTONIO DE PUTINA', 'QUILCAPUNCU', 'PUNO'),
('201104', 'PUNO', 'SAN ANTONIO DE PUTINA', 'ANANEA', 'PUNO'),
('201105', 'PUNO', 'SAN ANTONIO DE PUTINA', 'SINA', 'PUNO'),
('201201', 'PUNO', 'EL COLLAO', 'ILAVE', 'PUNO'),
('201202', 'PUNO', 'EL COLLAO', 'PILCUYO', 'PUNO'),
('201203', 'PUNO', 'EL COLLAO', 'SANTA ROSA', 'PUNO'),
('201204', 'PUNO', 'EL COLLAO', 'CAPAZO', 'PUNO'),
('201205', 'PUNO', 'EL COLLAO', 'CONDURIRI', 'PUNO'),
('201301', 'PUNO', 'MOHO', 'MOHO', 'PUNO'),
('201302', 'PUNO', 'MOHO', 'CONIMA', 'PUNO'),
('201303', 'PUNO', 'MOHO', 'TILALI', 'PUNO'),
('201304', 'PUNO', 'MOHO', 'HUAYRAPATA', 'PUNO'),
('210101', 'SAN MARTIN', 'MOYOBAMBA', 'MOYOBAMBA', 'SAN MARTIN'),
('210102', 'SAN MARTIN', 'MOYOBAMBA', 'CALZADA', 'SAN MARTIN'),
('210103', 'SAN MARTIN', 'MOYOBAMBA', 'HABANA', 'SAN MARTIN'),
('210104', 'SAN MARTIN', 'MOYOBAMBA', 'JEPELACIO', 'SAN MARTIN'),
('210105', 'SAN MARTIN', 'MOYOBAMBA', 'SORITOR', 'SAN MARTIN'),
('210106', 'SAN MARTIN', 'MOYOBAMBA', 'YANTALO', 'SAN MARTIN'),
('210201', 'SAN MARTIN', 'HUALLAGA', 'SAPOSOA', 'SAN MARTIN'),
('210202', 'SAN MARTIN', 'HUALLAGA', 'PISCOYACU', 'SAN MARTIN'),
('210203', 'SAN MARTIN', 'HUALLAGA', 'SACANCHE', 'SAN MARTIN'),
('210204', 'SAN MARTIN', 'HUALLAGA', 'TINGO DE SAPOSOA', 'SAN MARTIN'),
('210205', 'SAN MARTIN', 'HUALLAGA', 'ALTO SAPOSOA', 'SAN MARTIN'),
('210206', 'SAN MARTIN', 'HUALLAGA', 'EL ESLABON', 'SAN MARTIN'),
('210301', 'SAN MARTIN', 'LAMAS', 'LAMAS', 'SAN MARTIN'),
('210303', 'SAN MARTIN', 'LAMAS', 'BARRANQUITA', 'SAN MARTIN'),
('210304', 'SAN MARTIN', 'LAMAS', 'CAYNARACHI', 'SAN MARTIN'),
('210305', 'SAN MARTIN', 'LAMAS', 'CUÑUMBUQUI', 'SAN MARTIN'),
('210306', 'SAN MARTIN', 'LAMAS', 'PINTO RECODO', 'SAN MARTIN'),
('210307', 'SAN MARTIN', 'LAMAS', 'RUMISAPA', 'SAN MARTIN'),
('210311', 'SAN MARTIN', 'LAMAS', 'SHANAO', 'SAN MARTIN'),
('210313', 'SAN MARTIN', 'LAMAS', 'TABALOSOS', 'SAN MARTIN'),
('210314', 'SAN MARTIN', 'LAMAS', 'ZAPATERO', 'SAN MARTIN'),
('210315', 'SAN MARTIN', 'LAMAS', 'ALONSO DE ALVARADO', 'SAN MARTIN'),
('210316', 'SAN MARTIN', 'LAMAS', 'SAN ROQUE DE CUMBAZA', 'SAN MARTIN'),
('210401', 'SAN MARTIN', 'MARISCAL CACERES', 'JUANJUI', 'SAN MARTIN'),
('210402', 'SAN MARTIN', 'MARISCAL CACERES', 'CAMPANILLA', 'SAN MARTIN'),
('210403', 'SAN MARTIN', 'MARISCAL CACERES', 'HUICUNGO', 'SAN MARTIN'),
('210404', 'SAN MARTIN', 'MARISCAL CACERES', 'PACHIZA', 'SAN MARTIN'),
('210405', 'SAN MARTIN', 'MARISCAL CACERES', 'PAJARILLO', 'SAN MARTIN'),
('210501', 'SAN MARTIN', 'RIOJA', 'RIOJA', 'SAN MARTIN'),
('210502', 'SAN MARTIN', 'RIOJA', 'POSIC', 'SAN MARTIN'),
('210503', 'SAN MARTIN', 'RIOJA', 'YORONGOS', 'SAN MARTIN'),
('210504', 'SAN MARTIN', 'RIOJA', 'YURACYACU', 'SAN MARTIN'),
('210505', 'SAN MARTIN', 'RIOJA', 'NUEVA CAJAMARCA', 'SAN MARTIN'),
('210506', 'SAN MARTIN', 'RIOJA', 'ELIAS SOPLIN VARGAS', 'SAN MARTIN'),
('210507', 'SAN MARTIN', 'RIOJA', 'SAN FERNANDO', 'SAN MARTIN'),
('210508', 'SAN MARTIN', 'RIOJA', 'PARDO MIGUEL', 'SAN MARTIN'),
('210509', 'SAN MARTIN', 'RIOJA', 'AWAJUN', 'SAN MARTIN'),
('210601', 'SAN MARTIN', 'SAN MARTIN', 'TARAPOTO', 'SAN MARTIN'),
('210602', 'SAN MARTIN', 'SAN MARTIN', 'ALBERTO LEVEAU', 'SAN MARTIN'),
('210604', 'SAN MARTIN', 'SAN MARTIN', 'CACATACHI', 'SAN MARTIN'),
('210606', 'SAN MARTIN', 'SAN MARTIN', 'CHAZUTA', 'SAN MARTIN'),
('210607', 'SAN MARTIN', 'SAN MARTIN', 'CHIPURANA', 'SAN MARTIN'),
('210608', 'SAN MARTIN', 'SAN MARTIN', 'EL PORVENIR', 'SAN MARTIN'),
('210609', 'SAN MARTIN', 'SAN MARTIN', 'HUIMBAYOC', 'SAN MARTIN'),
('210610', 'SAN MARTIN', 'SAN MARTIN', 'JUAN GUERRA', 'SAN MARTIN'),
('210611', 'SAN MARTIN', 'SAN MARTIN', 'MORALES', 'SAN MARTIN'),
('210612', 'SAN MARTIN', 'SAN MARTIN', 'PAPAPLAYA', 'SAN MARTIN'),
('210616', 'SAN MARTIN', 'SAN MARTIN', 'SAN ANTONIO', 'SAN MARTIN'),
('210619', 'SAN MARTIN', 'SAN MARTIN', 'SAUCE', 'SAN MARTIN'),
('210620', 'SAN MARTIN', 'SAN MARTIN', 'SHAPAJA', 'SAN MARTIN'),
('210621', 'SAN MARTIN', 'SAN MARTIN', 'LA BANDA DE SHILCAYO', 'SAN MARTIN'),
('210701', 'SAN MARTIN', 'BELLAVISTA', 'BELLAVISTA', 'SAN MARTIN'),
('210702', 'SAN MARTIN', 'BELLAVISTA', 'SAN RAFAEL', 'SAN MARTIN'),
('210703', 'SAN MARTIN', 'BELLAVISTA', 'SAN PABLO', 'SAN MARTIN'),
('210704', 'SAN MARTIN', 'BELLAVISTA', 'ALTO BIAVO', 'SAN MARTIN'),
('210705', 'SAN MARTIN', 'BELLAVISTA', 'HUALLAGA', 'SAN MARTIN'),
('210706', 'SAN MARTIN', 'BELLAVISTA', 'BAJO BIAVO', 'SAN MARTIN'),
('210801', 'SAN MARTIN', 'TOCACHE', 'TOCACHE', 'SAN MARTIN'),
('210802', 'SAN MARTIN', 'TOCACHE', 'NUEVO PROGRESO', 'SAN MARTIN'),
('210803', 'SAN MARTIN', 'TOCACHE', 'POLVORA', 'SAN MARTIN'),
('210804', 'SAN MARTIN', 'TOCACHE', 'SHUNTE', 'SAN MARTIN'),
('210805', 'SAN MARTIN', 'TOCACHE', 'UCHIZA', 'SAN MARTIN'),
('210806', 'SAN MARTIN', 'TOCACHE', 'SANTA LUCIA', 'SAN MARTIN'),
('210901', 'SAN MARTIN', 'PICOTA', 'PICOTA', 'SAN MARTIN'),
('210902', 'SAN MARTIN', 'PICOTA', 'BUENOS AIRES', 'SAN MARTIN'),
('210903', 'SAN MARTIN', 'PICOTA', 'CASPISAPA', 'SAN MARTIN'),
('210904', 'SAN MARTIN', 'PICOTA', 'PILLUANA', 'SAN MARTIN'),
('210905', 'SAN MARTIN', 'PICOTA', 'PUCACACA', 'SAN MARTIN'),
('210906', 'SAN MARTIN', 'PICOTA', 'SAN CRISTOBAL', 'SAN MARTIN'),
('210907', 'SAN MARTIN', 'PICOTA', 'SAN HILARION', 'SAN MARTIN'),
('210908', 'SAN MARTIN', 'PICOTA', 'TINGO DE PONASA', 'SAN MARTIN'),
('210909', 'SAN MARTIN', 'PICOTA', 'TRES UNIDOS', 'SAN MARTIN'),
('210910', 'SAN MARTIN', 'PICOTA', 'SHAMBOYACU', 'SAN MARTIN'),
('211001', 'SAN MARTIN', 'EL DORADO', 'SAN JOSE DE SISA', 'SAN MARTIN'),
('211002', 'SAN MARTIN', 'EL DORADO', 'AGUA BLANCA', 'SAN MARTIN'),
('211003', 'SAN MARTIN', 'EL DORADO', 'SHATOJA', 'SAN MARTIN'),
('211004', 'SAN MARTIN', 'EL DORADO', 'SAN MARTIN', 'SAN MARTIN'),
('211005', 'SAN MARTIN', 'EL DORADO', 'SANTA ROSA', 'SAN MARTIN'),
('220101', 'TACNA', 'TACNA', 'TACNA', 'TACNA'),
('220102', 'TACNA', 'TACNA', 'CALANA', 'TACNA'),
('220104', 'TACNA', 'TACNA', 'INCLAN', 'TACNA'),
('220107', 'TACNA', 'TACNA', 'PACHIA', 'TACNA'),
('220108', 'TACNA', 'TACNA', 'PALCA', 'TACNA'),
('220109', 'TACNA', 'TACNA', 'POCOLLAY', 'TACNA'),
('220110', 'TACNA', 'TACNA', 'SAMA', 'TACNA'),
('220111', 'TACNA', 'TACNA', 'ALTO DE LA ALIANZA', 'TACNA'),
('220112', 'TACNA', 'TACNA', 'CIUDAD NUEVA', 'TACNA'),
('220113', 'TACNA', 'TACNA', 'CORONEL GREGORIO ALBARRACIN LANCHIP', 'TACNA'),
('220114', 'TACNA', 'TACNA', 'LA YARADA LOS PALOS', 'TACNA'),
('220201', 'TACNA', 'TARATA', 'TARATA', 'TACNA'),
('220205', 'TACNA', 'TARATA', 'CHUCATAMANI', 'TACNA'),
('220206', 'TACNA', 'TARATA', 'ESTIQUE', 'TACNA'),
('220207', 'TACNA', 'TARATA', 'ESTIQUE-PAMPA', 'TACNA'),
('220210', 'TACNA', 'TARATA', 'SITAJARA', 'TACNA'),
('220211', 'TACNA', 'TARATA', 'SUSAPAYA', 'TACNA'),
('220212', 'TACNA', 'TARATA', 'TARUCACHI', 'TACNA'),
('220213', 'TACNA', 'TARATA', 'TICACO', 'TACNA'),
('220301', 'TACNA', 'JORGE BASADRE', 'LOCUMBA', 'TACNA'),
('220302', 'TACNA', 'JORGE BASADRE', 'ITE', 'TACNA'),
('220303', 'TACNA', 'JORGE BASADRE', 'ILABAYA', 'TACNA'),
('220401', 'TACNA', 'CANDARAVE', 'CANDARAVE', 'TACNA'),
('220402', 'TACNA', 'CANDARAVE', 'CAIRANI', 'TACNA'),
('220403', 'TACNA', 'CANDARAVE', 'CURIBAYA', 'TACNA'),
('220404', 'TACNA', 'CANDARAVE', 'HUANUARA', 'TACNA'),
('220405', 'TACNA', 'CANDARAVE', 'QUILAHUANI', 'TACNA'),
('220406', 'TACNA', 'CANDARAVE', 'CAMILACA', 'TACNA'),
('230101', 'TUMBES', 'TUMBES', 'TUMBES', 'TUMBES'),
('230102', 'TUMBES', 'TUMBES', 'CORRALES', 'TUMBES'),
('230103', 'TUMBES', 'TUMBES', 'LA CRUZ', 'TUMBES'),
('230104', 'TUMBES', 'TUMBES', 'PAMPAS DE HOSPITAL', 'TUMBES'),
('230105', 'TUMBES', 'TUMBES', 'SAN JACINTO', 'TUMBES'),
('230106', 'TUMBES', 'TUMBES', 'SAN JUAN DE LA VIRGEN', 'TUMBES'),
('230201', 'TUMBES', 'CONTRALMIRANTE VILLAR', 'ZORRITOS', 'TUMBES'),
('230202', 'TUMBES', 'CONTRALMIRANTE VILLAR', 'CASITAS', 'TUMBES'),
('230203', 'TUMBES', 'CONTRALMIRANTE VILLAR', 'CANOAS DE PUNTA SAL', 'TUMBES'),
('230301', 'TUMBES', 'ZARUMILLA', 'ZARUMILLA', 'TUMBES'),
('230302', 'TUMBES', 'ZARUMILLA', 'MATAPALO', 'TUMBES'),
('230303', 'TUMBES', 'ZARUMILLA', 'PAPAYAL', 'TUMBES'),
('230304', 'TUMBES', 'ZARUMILLA', 'AGUAS VERDES', 'TUMBES'),
('240101', 'CALLAO', 'CALLAO', 'CALLAO', 'CALLAO'),
('240102', 'CALLAO', 'CALLAO', 'BELLAVISTA', 'CALLAO'),
('240103', 'CALLAO', 'CALLAO', 'LA PUNTA', 'CALLAO'),
('240104', 'CALLAO', 'CALLAO', 'CARMEN DE LA LEGUA REYNOSO', 'CALLAO'),
('240105', 'CALLAO', 'CALLAO', 'LA PERLA', 'CALLAO'),
('240106', 'CALLAO', 'CALLAO', 'VENTANILLA', 'CALLAO'),
('240107', 'CALLAO', 'CALLAO', 'MI PERU', 'CALLAO'),
('250101', 'UCAYALI', 'CORONEL PORTILLO', 'CALLERIA', 'UCAYALI'),
('250102', 'UCAYALI', 'CORONEL PORTILLO', 'YARINACOCHA', 'UCAYALI'),
('250103', 'UCAYALI', 'CORONEL PORTILLO', 'MASISEA', 'UCAYALI'),
('250104', 'UCAYALI', 'CORONEL PORTILLO', 'CAMPOVERDE', 'UCAYALI'),
('250105', 'UCAYALI', 'CORONEL PORTILLO', 'IPARIA', 'UCAYALI'),
('250106', 'UCAYALI', 'CORONEL PORTILLO', 'NUEVA REQUENA', 'UCAYALI'),
('250107', 'UCAYALI', 'CORONEL PORTILLO', 'MANANTAY', 'UCAYALI'),
('250201', 'UCAYALI', 'PADRE ABAD', 'PADRE ABAD', 'UCAYALI'),
('250202', 'UCAYALI', 'PADRE ABAD', 'IRAZOLA', 'UCAYALI'),
('250203', 'UCAYALI', 'PADRE ABAD', 'CURIMANA', 'UCAYALI'),
('250204', 'UCAYALI', 'PADRE ABAD', 'NESHUYA', 'UCAYALI'),
('250205', 'UCAYALI', 'PADRE ABAD', 'ALEXANDER VON HUMBOLDT', 'UCAYALI'),
('250206', 'UCAYALI', 'PADRE ABAD', 'BOQUERON', 'UCAYALI'),
('250207', 'UCAYALI', 'PADRE ABAD', 'HUIPOCA', 'UCAYALI'),
('250301', 'UCAYALI', 'ATALAYA', 'RAYMONDI', 'UCAYALI'),
('250302', 'UCAYALI', 'ATALAYA', 'TAHUANIA', 'UCAYALI'),
('250303', 'UCAYALI', 'ATALAYA', 'YURUA', 'UCAYALI'),
('250304', 'UCAYALI', 'ATALAYA', 'SEPAHUA', 'UCAYALI'),
('250401', 'UCAYALI', 'PURUS', 'PURUS', 'UCAYALI');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_afectacion_igv`
--

CREATE TABLE `tipo_afectacion_igv` (
  `id` int(11) NOT NULL,
  `codigo` char(3) NOT NULL,
  `descripcion` varchar(150) DEFAULT NULL,
  `letra_tributo` varchar(45) DEFAULT NULL,
  `codigo_tributo` varchar(45) DEFAULT NULL,
  `nombre_tributo` varchar(45) DEFAULT NULL,
  `tipo_tributo` varchar(45) DEFAULT NULL,
  `porcentaje_impuesto` decimal(10,0) DEFAULT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_comprobante`
--

CREATE TABLE `tipo_comprobante` (
  `id` int(11) NOT NULL,
  `codigo` varchar(3) NOT NULL,
  `descripcion` varchar(50) NOT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `tipo_comprobante`
--

INSERT INTO `tipo_comprobante` (`id`, `codigo`, `descripcion`, `estado`) VALUES
(1, '01', 'FACTURA', 1),
(2, '03', 'BOLETA', 1),
(3, '07', 'NOTA DE CRÉDITO', 1),
(4, '08', 'NOTA DE DÉBITO', 1),
(5, '09', 'GUIA DE REMISIÓN REMITENTE', 1),
(6, 'RA', 'RESUMEN ANULACIONES', 1),
(7, 'RC', 'RESUMEN COMPROBANTES', 1),
(10, 'NV', 'NOTA DE VENTA', 1),
(11, 'CTZ', 'COTIZACIÓN', 1),
(12, 'NC', 'NOTA DE COMPRA', 1),
(13, '31', 'GUIA DE REMISION TRANSPORTISTA', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_documento`
--

CREATE TABLE `tipo_documento` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(45) NOT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_documento`
--

INSERT INTO `tipo_documento` (`id`, `descripcion`, `estado`) VALUES
(0, 'SIN DOCUMENTO', 1),
(1, 'DPI', 1),
(4, 'CARNET DE EXTRANJERIA', 1),
(6, 'RUC', 1),
(7, 'PASAPORTE', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_movimiento_caja`
--

CREATE TABLE `tipo_movimiento_caja` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(150) DEFAULT NULL,
  `afecta_caja` int(11) DEFAULT NULL,
  `estado` int(11) DEFAULT 1,
  `fecha_registro` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_movimiento_caja`
--

INSERT INTO `tipo_movimiento_caja` (`id`, `descripcion`, `afecta_caja`, `estado`, `fecha_registro`) VALUES
(1, 'DEVOLUCIÓN', 1, 1, '2024-03-18'),
(2, 'GASTO', 1, 1, '2024-03-18'),
(3, 'INGRESO VENTA EFECTIVO', 1, 1, '2024-03-18'),
(4, 'APERTURA', 1, 1, '2024-03-18'),
(5, 'PAGO COMPRA AL CREDITO', 0, 1, '2024-03-18'),
(6, 'INGRESO YAPE', 0, 1, '2024-03-18'),
(7, 'INGRESO PLIN', 0, 1, '2024-03-18'),
(8, 'INGRESO TRANSFERENCIA', 0, 1, '2024-03-18'),
(9, 'INGRESO CANJE', 0, 1, '2024-03-18'),
(10, 'INGRESO VENTA AL CREDITO', 0, 1, '2024-03-18');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_operacion`
--

CREATE TABLE `tipo_operacion` (
  `codigo` varchar(4) NOT NULL,
  `descripcion` varchar(255) NOT NULL,
  `estado` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_operacion`
--

INSERT INTO `tipo_operacion` (`codigo`, `descripcion`, `estado`) VALUES
('0101', 'Venta interna', 1),
('0102', 'Venta Interna – Anticipos', 1),
('0103', 'Venta interna - Itinerante', 1),
('0110', 'Venta Interna - Sustenta Traslado de Mercadería - Remitente', 1),
('0111', 'Venta Interna - Sustenta Traslado de Mercadería - Transportista', 1),
('0112', 'Venta Interna - Sustenta Gastos Deducibles Persona Natural', 1),
('0120', 'Venta Interna - Sujeta al IVAP', 1),
('0200', 'Exportación de Bienes ', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_precio_venta_unitario`
--

CREATE TABLE `tipo_precio_venta_unitario` (
  `codigo` varchar(2) NOT NULL,
  `descripcion` varchar(255) NOT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_precio_venta_unitario`
--

INSERT INTO `tipo_precio_venta_unitario` (`codigo`, `descripcion`, `estado`) VALUES
('01', 'Precio unitario (incluye el IGV)', 1),
('02', 'Valor referencial unitario en operaciones no onerosas', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL,
  `nombre_usuario` varchar(100) DEFAULT NULL,
  `apellido_usuario` varchar(100) DEFAULT NULL,
  `usuario` varchar(100) DEFAULT NULL,
  `clave` text DEFAULT NULL,
  `id_perfil_usuario` int(11) DEFAULT NULL,
  `id_caja` int(11) DEFAULT 1,
  `email` varchar(150) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id_usuario`, `nombre_usuario`, `apellido_usuario`, `usuario`, `clave`, `id_perfil_usuario`, `id_caja`, `email`, `estado`) VALUES
(14, 'ADMINISTRADOR', 'ADMINISTRADOR', 'admin', '$2a$07$azybxcags23425sdg23sdeanQZqjaf6Birm2NvcYTNtJw24CsO5uq', 10, 2, NULL, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta`
--

CREATE TABLE `venta` (
  `id` int(11) NOT NULL,
  `id_empresa_emisora` int(11) NOT NULL,
  `id_cliente` int(11) NOT NULL,
  `id_serie` int(11) NOT NULL,
  `serie` varchar(4) NOT NULL,
  `correlativo` int(11) NOT NULL,
  `tipo_comprobante_modificado` varchar(10) DEFAULT NULL,
  `id_serie_modificado` int(11) DEFAULT NULL,
  `correlativo_modificado` varchar(10) DEFAULT NULL,
  `motivo_nota_credito_debito` varchar(10) DEFAULT NULL,
  `descripcion_motivo_nota` text DEFAULT NULL,
  `fecha_emision` date NOT NULL,
  `hora_emision` varchar(10) NOT NULL,
  `fecha_vencimiento` date NOT NULL,
  `id_moneda` varchar(3) NOT NULL,
  `forma_pago` varchar(45) NOT NULL,
  `medio_pago` varchar(45) NOT NULL,
  `tipo_operacion` varchar(10) NOT NULL,
  `total_operaciones_gravadas` decimal(18,2) DEFAULT 0.00,
  `total_operaciones_exoneradas` decimal(18,2) DEFAULT 0.00,
  `total_operaciones_inafectas` decimal(18,2) DEFAULT 0.00,
  `total_igv` decimal(18,2) DEFAULT 0.00,
  `importe_total` decimal(18,2) DEFAULT 0.00,
  `efectivo_recibido` decimal(18,2) DEFAULT 0.00,
  `vuelto` decimal(18,2) DEFAULT 0.00,
  `nombre_xml` varchar(255) DEFAULT NULL,
  `xml_base64` text DEFAULT NULL,
  `xml_cdr_sunat_base64` text DEFAULT NULL,
  `codigo_error_sunat` text DEFAULT NULL,
  `mensaje_respuesta_sunat` text DEFAULT NULL,
  `hash_signature` varchar(150) DEFAULT NULL,
  `estado_respuesta_sunat` int(11) DEFAULT 0 COMMENT '1: Comprobante enviado correctamente - 2: Rechazado, enviado con errores - 0: Pendiente de envío - 3: Anulado Sunat',
  `estado_comprobante` int(11) DEFAULT 0 COMMENT '0: Pendiente de envío\n1: Registrado en Sunat\n2: Anulado Sunat',
  `id_usuario` int(11) DEFAULT NULL,
  `pagado` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta_detalle`
--

CREATE TABLE `venta_detalle` (
  `id` int(11) NOT NULL,
  `id_venta` int(11) DEFAULT NULL,
  `item` int(11) DEFAULT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `descripcion` varchar(150) DEFAULT NULL,
  `porcentaje_igv` decimal(18,4) DEFAULT NULL,
  `cantidad` decimal(18,4) DEFAULT NULL,
  `costo_unitario` decimal(18,4) DEFAULT NULL,
  `valor_unitario` decimal(18,4) DEFAULT NULL,
  `precio_unitario` decimal(18,4) DEFAULT NULL,
  `valor_total` decimal(18,4) DEFAULT NULL,
  `igv` decimal(18,4) DEFAULT NULL,
  `importe_total` decimal(18,4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `arqueo_caja`
--
ALTER TABLE `arqueo_caja`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `cajas`
--
ALTER TABLE `cajas`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `codigo_unidad_medida`
--
ALTER TABLE `codigo_unidad_medida`
  ADD UNIQUE KEY `id_UNIQUE` (`id`);

--
-- Indices de la tabla `compras`
--
ALTER TABLE `compras`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `configuraciones`
--
ALTER TABLE `configuraciones`
  ADD PRIMARY KEY (`id`,`ordinal`);

--
-- Indices de la tabla `cotizaciones`
--
ALTER TABLE `cotizaciones`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `cotizaciones_detalle`
--
ALTER TABLE `cotizaciones_detalle`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `cuotas`
--
ALTER TABLE `cuotas`
  ADD PRIMARY KEY (`id`) USING BTREE;

--
-- Indices de la tabla `cuotas_compras`
--
ALTER TABLE `cuotas_compras`
  ADD PRIMARY KEY (`id`) USING BTREE;

--
-- Indices de la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_cod_producto_idx` (`codigo_producto`),
  ADD KEY `fk_id_compra_idx` (`id_compra`);

--
-- Indices de la tabla `detalle_venta`
--
ALTER TABLE `detalle_venta`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `empresas`
--
ALTER TABLE `empresas`
  ADD PRIMARY KEY (`id_empresa`);

--
-- Indices de la tabla `forma_pago`
--
ALTER TABLE `forma_pago`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `guia_remision`
--
ALTER TABLE `guia_remision`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `guia_remision_choferes`
--
ALTER TABLE `guia_remision_choferes`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `guia_remision_productos`
--
ALTER TABLE `guia_remision_productos`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `guia_remision_vehiculos`
--
ALTER TABLE `guia_remision_vehiculos`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `historico_cargas_masivas`
--
ALTER TABLE `historico_cargas_masivas`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `impuestos`
--
ALTER TABLE `impuestos`
  ADD PRIMARY KEY (`id_tipo_operacion`);

--
-- Indices de la tabla `kardex`
--
ALTER TABLE `kardex`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_id_producto_idx` (`codigo_producto`);

--
-- Indices de la tabla `medio_pago`
--
ALTER TABLE `medio_pago`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `modalidad_traslado`
--
ALTER TABLE `modalidad_traslado`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `modulos`
--
ALTER TABLE `modulos`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `moneda`
--
ALTER TABLE `moneda`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `motivos_notas`
--
ALTER TABLE `motivos_notas`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `motivo_traslado`
--
ALTER TABLE `motivo_traslado`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `movimientos_arqueo_caja`
--
ALTER TABLE `movimientos_arqueo_caja`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `perfiles`
--
ALTER TABLE `perfiles`
  ADD PRIMARY KEY (`id_perfil`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codigo_producto_UNIQUE` (`codigo_producto`),
  ADD KEY `fk_id_categoria_idx` (`id_categoria`);

--
-- Indices de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `resumenes`
--
ALTER TABLE `resumenes`
  ADD PRIMARY KEY (`id`) USING BTREE;

--
-- Indices de la tabla `resumenes_detalle`
--
ALTER TABLE `resumenes_detalle`
  ADD PRIMARY KEY (`id`) USING BTREE,
  ADD KEY `fk_id_envio` (`id_envio`) USING BTREE,
  ADD KEY `fk_idventa` (`id_comprobante`) USING BTREE;

--
-- Indices de la tabla `serie`
--
ALTER TABLE `serie`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `tb_ubigeos`
--
ALTER TABLE `tb_ubigeos`
  ADD PRIMARY KEY (`ubigeo_reniec`);

--
-- Indices de la tabla `tipo_afectacion_igv`
--
ALTER TABLE `tipo_afectacion_igv`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `tipo_comprobante`
--
ALTER TABLE `tipo_comprobante`
  ADD PRIMARY KEY (`id`,`codigo`);

--
-- Indices de la tabla `tipo_documento`
--
ALTER TABLE `tipo_documento`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `tipo_movimiento_caja`
--
ALTER TABLE `tipo_movimiento_caja`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `tipo_operacion`
--
ALTER TABLE `tipo_operacion`
  ADD PRIMARY KEY (`codigo`);

--
-- Indices de la tabla `tipo_precio_venta_unitario`
--
ALTER TABLE `tipo_precio_venta_unitario`
  ADD PRIMARY KEY (`codigo`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id_usuario`),
  ADD KEY `id_perfil_usuario` (`id_perfil_usuario`),
  ADD KEY `fk_id_caja_idx` (`id_caja`);

--
-- Indices de la tabla `venta`
--
ALTER TABLE `venta`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `venta_detalle`
--
ALTER TABLE `venta_detalle`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `arqueo_caja`
--
ALTER TABLE `arqueo_caja`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `cajas`
--
ALTER TABLE `cajas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `categorias`
--
ALTER TABLE `categorias`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `clientes`
--
ALTER TABLE `clientes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `compras`
--
ALTER TABLE `compras`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `cotizaciones`
--
ALTER TABLE `cotizaciones`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `cotizaciones_detalle`
--
ALTER TABLE `cotizaciones_detalle`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `cuotas`
--
ALTER TABLE `cuotas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `cuotas_compras`
--
ALTER TABLE `cuotas_compras`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `detalle_venta`
--
ALTER TABLE `detalle_venta`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `empresas`
--
ALTER TABLE `empresas`
  MODIFY `id_empresa` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `forma_pago`
--
ALTER TABLE `forma_pago`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `guia_remision`
--
ALTER TABLE `guia_remision`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=79;

--
-- AUTO_INCREMENT de la tabla `guia_remision_choferes`
--
ALTER TABLE `guia_remision_choferes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT de la tabla `guia_remision_productos`
--
ALTER TABLE `guia_remision_productos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=138;

--
-- AUTO_INCREMENT de la tabla `guia_remision_vehiculos`
--
ALTER TABLE `guia_remision_vehiculos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT de la tabla `historico_cargas_masivas`
--
ALTER TABLE `historico_cargas_masivas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla `kardex`
--
ALTER TABLE `kardex`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `medio_pago`
--
ALTER TABLE `medio_pago`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `modalidad_traslado`
--
ALTER TABLE `modalidad_traslado`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `modulos`
--
ALTER TABLE `modulos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=57;

--
-- AUTO_INCREMENT de la tabla `motivos_notas`
--
ALTER TABLE `motivos_notas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT de la tabla `motivo_traslado`
--
ALTER TABLE `motivo_traslado`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `movimientos_arqueo_caja`
--
ALTER TABLE `movimientos_arqueo_caja`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `perfiles`
--
ALTER TABLE `perfiles`
  MODIFY `id_perfil` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `resumenes`
--
ALTER TABLE `resumenes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `resumenes_detalle`
--
ALTER TABLE `resumenes_detalle`
  MODIFY `id` int(255) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `serie`
--
ALTER TABLE `serie`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `tipo_afectacion_igv`
--
ALTER TABLE `tipo_afectacion_igv`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `tipo_comprobante`
--
ALTER TABLE `tipo_comprobante`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT de la tabla `tipo_movimiento_caja`
--
ALTER TABLE `tipo_movimiento_caja`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT de la tabla `venta`
--
ALTER TABLE `venta`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `venta_detalle`
--
ALTER TABLE `venta_detalle`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD CONSTRAINT `fk_cod_producto` FOREIGN KEY (`codigo_producto`) REFERENCES `productos` (`codigo_producto`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_id_compra` FOREIGN KEY (`id_compra`) REFERENCES `compras` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `kardex`
--
ALTER TABLE `kardex`
  ADD CONSTRAINT `fk_cod_producto_kardex` FOREIGN KEY (`codigo_producto`) REFERENCES `productos` (`codigo_producto`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `productos`
--
ALTER TABLE `productos`
  ADD CONSTRAINT `fk_id_categoria` FOREIGN KEY (`id_categoria`) REFERENCES `categorias` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `resumenes_detalle`
--
ALTER TABLE `resumenes_detalle`
  ADD CONSTRAINT `fk_id_envio` FOREIGN KEY (`id_envio`) REFERENCES `resumenes` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `fk_id_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `usuarios_ibfk_1` FOREIGN KEY (`id_perfil_usuario`) REFERENCES `perfiles` (`id_perfil`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
