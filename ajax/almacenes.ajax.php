<?php

require_once "../modelos/almacenes.modelo.php";

if (isset($_POST['accion'])) {
    switch ($_POST['accion']) {
        case 'obtener_almacenes':
            $response = AlmacenesModelo::mdlObtenerAlmacenes();
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;

        case 'listar_almacenes':
            $response = AlmacenesModelo::mdlListarAlmacenes();
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;

        case 'registrar_almacen':
            $nombre = $_POST['nombre'];
            $direccion = $_POST['direccion'];
            $estado = $_POST['estado'];
            $response = AlmacenesModelo::mdlRegistrarAlmacen($nombre, $direccion, $estado);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;

        case 'actualizar_almacen':
            $id = $_POST['id'];
            $nombre = $_POST['nombre'];
            $direccion = $_POST['direccion'];
            $estado = $_POST['estado'];
            $response = AlmacenesModelo::mdlActualizarAlmacen($id, $nombre, $direccion, $estado);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;

        case 'eliminar_almacen':
            $id = $_POST['id'];
            $response = AlmacenesModelo::mdlEliminarAlmacen($id);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;
    }
}
