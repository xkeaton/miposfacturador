<?php

require_once "../modelos/usuario.modelo.php";
session_start();

if (isset($_POST["accion"])) {

    switch ($_POST["accion"]) {

        case 'login':

            if (isset($_POST["usuario"])) {

                $usuario = $_POST["usuario"];
                $password = crypt($_POST["password"], '$2a$07$azybxcags23425sdg23sdfhsd$');

                $response = UsuarioModelo::mdlIniciarSesion($usuario, $password);

                echo json_encode($response);
            }

            break;

        case 'validar_sesion':

            if (!isset($_SESSION["usuario"])) {

                session_destroy();

                $response = [
                    "message" => "no_session"
                ];

                echo json_encode($response, JSON_UNESCAPED_UNICODE);

                exit();
            } else {
                $response = [
                    "message" => "session_ok"
                ];

                echo json_encode($response, JSON_UNESCAPED_UNICODE);
            }

            break;

        default:
            # code...
            break;
    }
}
