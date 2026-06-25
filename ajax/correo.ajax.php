<?php

require_once "../modelos/ventas.modelo.php";
require_once "../vendor/autoload.php";

if (isset($_POST['accion'])) {
    switch ($_POST['accion']) {
        case 'enviar_comprobante':
            $id_venta = (int)$_POST['id_venta'];
            $correo = $_POST['correo'];
            
            try {
                $response = VentasModelo::mdlEnviarComprobanteEmail($id_venta, $correo);
                echo json_encode($response, JSON_UNESCAPED_UNICODE);
            } catch (Exception $e) {
                echo json_encode([
                    "tipo_msj" => "error",
                    "msj" => "Error al enviar el correo: " . $e->getMessage()
                ], JSON_UNESCAPED_UNICODE);
            }
            break;
            
        default:
            echo json_encode([
                "tipo_msj" => "error",
                "msj" => "Acción no reconocida"
            ], JSON_UNESCAPED_UNICODE);
            break;
    }
} else {
    echo json_encode([
        "tipo_msj" => "error",
        "msj" => "Falta el parámetro accion"
    ], JSON_UNESCAPED_UNICODE);
}
