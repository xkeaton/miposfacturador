DROP PROCEDURE IF EXISTS prc_registrar_kardex_venta;
DELIMITER $$
CREATE PROCEDURE prc_registrar_kardex_venta(
    IN p_codigo_producto VARCHAR(20),
    IN p_fecha DATE,
    IN p_concepto VARCHAR(100),
    IN p_comprobante VARCHAR(100),
    IN p_unidades FLOAT,
    IN p_id_almacen INT
)
BEGIN
    declare v_unidades_ex float;
    declare v_costo_unitario_ex float;    
    declare v_costo_total_ex float;
    declare v_costo_total_ex_actual float;
    
    declare v_unidades_out float;
    declare v_costo_unitario_out float;    
    declare v_costo_total_out float;
    
    /*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO PARA EL ALMACEN*/
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex, v_costo_total_ex_actual
    FROM kardex k
    WHERE k.codigo_producto = p_codigo_producto AND k.id_almacen = p_id_almacen
    ORDER BY id DESC
    LIMIT 1;
    
    IF v_unidades_ex IS NULL THEN
        SET v_unidades_ex = 0;
        SET v_costo_total_ex = 0;
        SELECT costo_unitario INTO v_costo_unitario_ex FROM productos WHERE codigo_producto = p_codigo_producto;
        IF v_costo_unitario_ex IS NULL THEN
            SET v_costo_unitario_ex = 0;
        END IF;
    END IF;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE SALIDA*/
    SET v_unidades_out = p_unidades;
    SET v_costo_unitario_out = v_costo_unitario_ex;
    SET v_costo_total_out = p_unidades * v_costo_unitario_ex;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(v_unidades_ex - v_unidades_out,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex - v_costo_total_out,2);
    
    IF(v_costo_total_ex > 0) THEN
        SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
    ELSE
        SET v_costo_unitario_ex = ROUND(0,2);
    END IF;
    
    INSERT INTO kardex(codigo_producto,
                        id_almacen,
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
                        p_id_almacen,
                        p_fecha,
                        p_concepto,
                        p_comprobante,
                        v_unidades_out,
                        v_costo_unitario_out,
                        v_costo_total_out,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

    /*ACTUALIZAMOS EL STOCK EN productos_almacenes*/
    INSERT INTO productos_almacenes(id_almacen, codigo_producto, stock)
    VALUES(p_id_almacen, p_codigo_producto, v_unidades_ex)
    ON DUPLICATE KEY UPDATE stock = v_unidades_ex;

    /*ACTUALIZAMOS EL STOCK TOTAL, EL NRO DE VENTAS EN productos*/
    UPDATE productos 
    SET stock = (SELECT IFNULL(SUM(stock), 0) FROM productos_almacenes WHERE codigo_producto = p_codigo_producto), 
        ventas = ventas + v_unidades_out,
        costo_unitario = v_costo_unitario_ex,
        costo_total = (SELECT IFNULL(SUM(stock), 0) * v_costo_unitario_ex FROM productos_almacenes WHERE codigo_producto = p_codigo_producto)
    WHERE codigo_producto = p_codigo_producto;                      
END $$

DROP PROCEDURE IF EXISTS prc_registrar_kardex_bono;
CREATE PROCEDURE prc_registrar_kardex_bono(
    IN p_codigo_producto VARCHAR(20), 
    IN p_concepto VARCHAR(100), 
    IN p_nuevo_stock FLOAT,
    IN p_id_almacen INT
)
BEGIN
	/*VARIABLES PARA EXISTENCIAS ACTUALES*/
	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_in float;
	declare v_costo_unitario_in float;    
	declare v_costo_total_in float;
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO PARA ESTE ALMACEN*/    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM kardex k
    WHERE k.codigo_producto = p_codigo_producto AND k.id_almacen = p_id_almacen
    ORDER BY id DESC
    LIMIT 1;
    
    IF v_unidades_ex IS NULL THEN
        SET v_unidades_ex = 0;
        SET v_costo_total_ex = 0;
        SELECT costo_unitario INTO v_costo_unitario_ex FROM productos WHERE codigo_producto = p_codigo_producto;
        IF v_costo_unitario_ex IS NULL THEN
            SET v_costo_unitario_ex = 0;
        END IF;
    END IF;
    
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
                        id_almacen,
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
                        p_id_almacen,
						curdate(),
                        p_concepto,
                        '',
                        v_unidades_in,
                        v_costo_unitario_in,
                        v_costo_total_in,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK EN productos_almacenes*/
    INSERT INTO productos_almacenes(id_almacen, codigo_producto, stock)
    VALUES(p_id_almacen, p_codigo_producto, v_unidades_ex)
    ON DUPLICATE KEY UPDATE stock = v_unidades_ex;

	/*ACTUALIZAMOS EL STOCK TOTAL, EL NRO DE VENTAS DEL PRODUCTO EN productos*/
	UPDATE productos 
	SET stock = (SELECT IFNULL(SUM(stock), 0) FROM productos_almacenes WHERE codigo_producto = p_codigo_producto), 
         costo_unitario = v_costo_unitario_ex,
         costo_total = (SELECT IFNULL(SUM(stock), 0) * v_costo_unitario_ex FROM productos_almacenes WHERE codigo_producto = p_codigo_producto)
	WHERE codigo_producto = p_codigo_producto ;                      
END $$

DROP PROCEDURE IF EXISTS prc_registrar_kardex_vencido;
CREATE PROCEDURE prc_registrar_kardex_vencido(
    IN p_codigo_producto VARCHAR(20), 
    IN p_concepto VARCHAR(100), 
    IN p_nuevo_stock FLOAT,
    IN p_id_almacen INT
)
BEGIN
	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_out float;
	declare v_costo_unitario_out float;    
	declare v_costo_total_out float;
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO PARA ESTE ALMACEN*/    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM kardex k
    WHERE k.codigo_producto = p_codigo_producto AND k.id_almacen = p_id_almacen
    ORDER BY ID DESC
    LIMIT 1;
    
    IF v_unidades_ex IS NULL THEN
        SET v_unidades_ex = 0;
        SET v_costo_total_ex = 0;
        SELECT costo_unitario INTO v_costo_unitario_ex FROM productos WHERE codigo_producto = p_codigo_producto;
        IF v_costo_unitario_ex IS NULL THEN
            SET v_costo_unitario_ex = 0;
        END IF;
    END IF;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE SALIDA*/
    SET v_unidades_out = v_unidades_ex - p_nuevo_stock;
    SET v_costo_unitario_out = v_costo_unitario_ex;
    SET v_costo_total_out = v_unidades_out * v_costo_unitario_out;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(p_nuevo_stock,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex - v_costo_total_out,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
    ELSE
        SET v_costo_unitario_ex = ROUND(0,2);
    END IF;
    
	INSERT INTO kardex(codigo_producto,
                        id_almacen,
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
                        p_id_almacen,
						curdate(),
                        p_concepto,
                        '',
                        v_unidades_out,
                        v_costo_unitario_out,
                        v_costo_total_out,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK EN productos_almacenes*/
    INSERT INTO productos_almacenes(id_almacen, codigo_producto, stock)
    VALUES(p_id_almacen, p_codigo_producto, v_unidades_ex)
    ON DUPLICATE KEY UPDATE stock = v_unidades_ex;

	/*ACTUALIZAMOS EL STOCK TOTAL, EL NRO DE VENTAS DEL PRODUCTO EN productos*/
	UPDATE productos 
	SET stock = (SELECT IFNULL(SUM(stock), 0) FROM productos_almacenes WHERE codigo_producto = p_codigo_producto), 
         costo_unitario = v_costo_unitario_ex,
        costo_total = (SELECT IFNULL(SUM(stock), 0) * v_costo_unitario_ex FROM productos_almacenes WHERE codigo_producto = p_codigo_producto)
	WHERE codigo_producto = p_codigo_producto ;                      
END $$

DROP PROCEDURE IF EXISTS prc_registrar_kardex_existencias;
CREATE PROCEDURE prc_registrar_kardex_existencias(
    IN p_codigo_producto VARCHAR(25), 
    IN p_concepto VARCHAR(100), 
    IN p_comprobante VARCHAR(100), 
    IN p_unidades FLOAT, 
    IN p_costo_unitario FLOAT, 
    IN p_costo_total FLOAT,
    IN p_id_almacen INT
)
BEGIN
  INSERT INTO kardex (codigo_producto, id_almacen, fecha, concepto, comprobante, in_unidades, in_costo_unitario, in_costo_total, ex_unidades, ex_costo_unitario, ex_costo_total)
    VALUES (p_codigo_producto, p_id_almacen, CURDATE(), p_concepto, p_comprobante, p_unidades, p_costo_unitario, p_costo_total, p_unidades, p_costo_unitario, p_costo_total);
END $$

DELIMITER ;
