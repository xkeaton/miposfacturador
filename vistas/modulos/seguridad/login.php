<?php
$ruta = Rutas::RutaProyecto();

// Obtener datos de la empresa dinámicamente
try {
    $stmtEmpresa = Conexion::conectar()->prepare("SELECT razon_social, nombre_comercial, logo FROM empresas LIMIT 1");
    $stmtEmpresa->execute();
    $empresa = $stmtEmpresa->fetch(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    $empresa = null;
}

$nombreNegocio = ($empresa && !empty($empresa['nombre_comercial'])) ? $empresa['nombre_comercial'] : (($empresa && !empty($empresa['razon_social'])) ? $empresa['razon_social'] : "Mi POS Facturador");
$logoFile = ($empresa && !empty($empresa['logo'])) ? $empresa['logo'] : "mi_logo_tutorialesphperu.png";
$logoPath = "vistas/assets/dist/img/logos_empresas/" . $logoFile;
?>

<!-- Importar Tailwind CSS e Inter Font -->
<script src="https://cdn.tailwindcss.com"></script>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<style>
    body {
        font-family: 'Inter', sans-serif !important;
        background-color: #f8fafc !important;
    }
</style>
<script>
    tailwind.config = {
        theme: {
            extend: {
                colors: {
                    brand: {
                        50: '#ecfdf5',
                        100: '#d1fae5',
                        400: '#34d399',
                        500: '#00c292', /* Usamos el color verde Yusu como primario */
                        600: '#00a87d',
                        700: '#008f6a'
                    }
                }
            }
        }
    }
</script>

<div class="min-h-screen flex w-full">
    <div class="hidden lg:flex lg:w-1/2 relative overflow-hidden bg-gradient-to-br from-emerald-600 via-emerald-700 to-teal-800 text-white">
        <div class="absolute -top-24 -left-24 w-96 h-96 rounded-full bg-white/10 blur-2xl"></div>
        <div class="absolute bottom-0 right-0 w-96 h-96 rounded-full bg-teal-400/20 blur-3xl"></div>

        <div class="relative z-10 flex flex-col justify-center px-14 xl:px-20 w-full">
            <div class="flex flex-col items-start">
                <img class="w-20 h-20 rounded-3xl bg-white/15 p-1 backdrop-blur shadow-xl mb-5 object-cover" src="<?php echo $logoPath; ?>" onerror="this.src='vistas/assets/dist/img/logos_empresas/mi_logo_tutorialesphperu.png';" alt="Logo">
                <h1 class="text-4xl font-extrabold tracking-tight"><?php echo htmlspecialchars($nombreNegocio); ?></h1>
                <p class="mt-1 text-sm font-semibold tracking-[0.2em] text-emerald-200 uppercase">Sistema de Facturación Electrónica</p>
            </div>

            <div class="mt-12 space-y-6 max-w-md">
                <?php
                    $features = [
                        ['Punto de Venta Ágil', 'Cobra rápido, realiza descuentos de stock e integra IGV de forma automática.', 'M2.25 3h1.386c.51 0 .955.343 1.087.836l.383 1.437M7.5 14.25a3 3 0 0 0-3 3h15.75m-12.75-3h11.218c1.121-2.3 2.1-4.684 2.924-7.138a60.114 60.114 0 0 0-16.536-1.84M7.5 14.25 5.106 5.272M6 20.25a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Zm12.75 0a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Z'],
                        ['Inventario y Kardex', 'Controla entradas, salidas, alertas de stock mínimo y ajustes en tiempo real.', 'M6 6.878V6a2.25 2.25 0 0 1 2.25-2.25h7.5A2.25 2.25 0 0 1 18 6v.878m-12 0c.235-.083.487-.128.75-.128h10.5c.263 0 .515.045.75.128m-12 0A2.25 2.25 0 0 0 4.5 9v.878m13.5-3A2.25 2.25 0 0 1 19.5 9v.878M19.5 9.878a2.246 2.246 0 0 0-.75-.128H5.25c-.263 0-.515.045-.75.128m15 0A2.25 2.25 0 0 1 21 12v6a2.25 2.25 0 0 1-2.25 2.25H5.25A2.25 2.25 0 0 1 3 18v-6c0-.98.626-1.813 1.5-2.122'],
                        ['Reportes de Venta', 'Visualiza tus ingresos diarios, gráficos comparativos y descarga reportes en PDF.', 'M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z'],
                        ['Módulo Multi-dispositivo', 'Accede de forma segura desde computadoras, tablets o tu app móvil Yusu.', 'M10.5 1.5H8.25A2.25 2.25 0 0 0 6 3.75v16.5a2.25 2.25 0 0 0 2.25 2.25h7.5A2.25 2.25 0 0 0 18 20.25V3.75a2.25 2.25 0 0 0-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 18.75h3'],
                    ];
                    foreach ($features as [$title, $desc, $d]) {
                        echo '
                        <div class="flex items-start gap-4">
                            <div class="flex items-center justify-center w-11 h-11 shrink-0 rounded-xl bg-white/15 backdrop-blur">
                                <svg class="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.7"><path stroke-linecap="round" stroke-linejoin="round" d="'.$d.'"/></svg>
                            </div>
                            <div>
                                <p class="font-semibold text-white">'.$title.'</p>
                                <p class="text-sm text-emerald-100/80">'.$desc.'</p>
                            </div>
                        </div>';
                    }
                ?>
            </div>

            <div class="mt-12 grid grid-cols-3 gap-3 max-w-md">
                <?php
                    $stats = [['SUNAT', 'Integrado'], ['100%', 'Seguro'], ['Yusu', 'App Móvil']];
                    foreach ($stats as [$num, $lbl]) {
                        echo '
                        <div class="rounded-2xl bg-white/10 backdrop-blur px-4 py-3 text-center">
                            <p class="text-xl font-extrabold text-white">'.$num.'</p>
                            <p class="text-[10px] text-emerald-100/80 uppercase tracking-wider font-semibold mt-0.5">'.$lbl.'</p>
                        </div>';
                    }
                ?>
            </div>
        </div>
    </div>

    <div class="w-full lg:w-1/2 flex items-center justify-center bg-white p-8 sm:p-16">
        <div class="w-full max-w-sm">
            <div class="lg:hidden flex flex-col items-center mb-8">
                <img class="w-16 h-16 rounded-2xl bg-gradient-to-br from-brand-500 to-emerald-600 shadow-md mb-3 object-cover" src="<?php echo $logoPath; ?>" onerror="this.src='vistas/assets/dist/img/logos_empresas/mi_logo_tutorialesphperu.png';" alt="Logo">
                <h1 class="text-2xl font-extrabold text-slate-800"><?php echo htmlspecialchars($nombreNegocio); ?></h1>
            </div>

            <h2 class="text-3xl font-extrabold text-slate-800 tracking-tight">Bienvenido 👋</h2>
            <p class="text-sm text-slate-500 mt-1 mb-8">Ingresa tus credenciales para acceder al sistema</p>

            <form class="space-y-5 needs-validation-login" novalidate>
                <div>
                    <label class="block text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1.5">Usuario del Sistema</label>
                    <div class="relative">
                        <span class="absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
                            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.6"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z" /></svg>
                        </span>
                        <input type="text" id="loginUsuario" required autofocus
                            class="w-full rounded-xl border border-slate-200 pl-11 pr-4 py-3 text-sm focus:border-brand-500 focus:ring-2 focus:ring-brand-100 outline-none transition"
                            placeholder="Ingrese su usuario">
                    </div>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1.5">Contraseña</label>
                    <div class="relative">
                        <span class="absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
                            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.6"><path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 1 0-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 0 0 2.25-2.25v-6.75a2.25 2.25 0 0 0-2.25-2.25H6.75a2.25 2.25 0 0 0-2.25 2.25v6.75a2.25 2.25 0 0 0 2.25 2.25Z"/></svg>
                        </span>
                        <input type="password" id="loginPassword" required
                            class="w-full rounded-xl border border-slate-200 pl-11 pr-4 py-3 text-sm focus:border-brand-500 focus:ring-2 focus:ring-brand-100 outline-none transition"
                            placeholder="••••••••">
                    </div>
                </div>
                <div class="flex items-center justify-between pt-1">
                    <label class="flex items-center gap-2 text-sm text-slate-600 cursor-pointer">
                        <input type="checkbox" name="remember" class="rounded border-slate-300 text-brand-600 focus:ring-brand-500">
                        Recordarme
                    </label>
                    <a style="cursor: pointer;" id="btnReestablecerPassword" class="text-sm font-semibold text-brand-600 hover:text-brand-700 transition">¿Olvidaste tu contraseña?</a>
                </div>
                
                <button type="button" id="btnIniciarSesion"
                    class="w-full flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-brand-500 to-emerald-600 px-4 py-3.5 text-sm font-semibold text-white shadow-lg shadow-emerald-100 hover:from-brand-600 hover:to-emerald-700 transition active:scale-95">
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0 0 13.5 3h-6a2.25 2.25 0 0 0-2.25 2.25v13.5A2.25 2.25 0 0 0 7.5 21h6a2.25 2.25 0 0 0 2.25-2.25V15M12 9l3 3m0 0-3 3m3-3H2.25"/></svg>
                    Iniciar Sesión
                </button>
            </form>

            <p class="text-center text-xs text-slate-400 mt-16">© <?php echo date('Y'); ?> <?php echo htmlspecialchars($nombreNegocio); ?> · Todos los derechos reservados</p>
        </div>
    </div>
</div>

<!-- =============================================================================================================================
VENTANA MODAL PARA CAMBIAR PASSWORD (BOOTSTRAP)
===============================================================================================================================-->
<div class="modal fade" id="modalReestablecerPassword" tabindex="-1" aria-labelledby="exampleModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content" style="border-radius: 16px; overflow: hidden; border: none;">

            <!-- cabecera del modal -->
            <div class="modal-header py-3" style="background-color: #00c292; color: #fff;">
                <h5 class="modal-title font-bold text-white"><i class="fas fa-key mr-2"></i>Reestablecer Contraseña</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>

            <div class="modal-body p-4">
                <form id="frm-datos-usuario" class="needs-validation-usuario" autocomplete="off" novalidate>
                    <div class="row g-3">
                        <!-- USUARIO DEL SISTEMA -->
                        <div class="col-12">
                            <label class="form-label text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1"><i class="fas fa-id-card mr-1"></i>Usuario del Sistema</label>
                            <input autocomplete="false" autofill="off" type="text" style="border-radius: 8px;" placeholder="Ingrese su usuario" class="form-control" id="usuario" name="usuario" aria-label="Small" id_usuario="0" onchange="validateJS(event, 'usuario_login')" required>
                            <div class="invalid-feedback">Ingrese usuario del sistema</div>
                        </div>

                        <!-- PASSWORD -->
                        <div class="col-12">
                            <label class="form-label text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1"><i class="fas fa-lock mr-1"></i>Contraseña <span class="text-danger" style="font-size: 11px;">(Mínimo 6 caracteres)</span></label>
                            <input autocomplete="false" type="password" style="border-radius: 8px;" placeholder="Ingrese nueva contraseña" class="form-control" id="password" name="password" required>
                            <div class="invalid-feedback">Ingrese la contraseña</div>
                        </div>

                        <!-- CONFIRMAR PASSWORD -->
                        <div class="col-12">
                            <label class="form-label text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1"><i class="fas fa-lock mr-1"></i>Confirmar Contraseña</label>
                            <input autocomplete="false" type="password" style="border-radius: 8px;" placeholder="Confirme nueva contraseña" class="form-control" id="confirmar_password" name="confirmar_password" required>
                            <div class="invalid-feedback">Ingrese la confirmación</div>
                        </div>

                        <div class="col-12 d-flex justify-content-end gap-2 mt-4">
                            <button type="button" class="btn btn-secondary" style="border-radius: 8px;" data-bs-dismiss="modal">Cancelar</button>
                            <button type="button" class="btn text-white" style="background-color: #00c292; border-radius: 8px;" id="btnCambiarPassword">Guardar</button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<script>
    $(document).ready(function() {
        $("#btnIniciarSesion").on('click', function() {
            fnc_login();
        });

        $('#loginPassword').keypress(function(e) {
            var key = e.which;
            if (key == 13) {
                fnc_login();
            }
        });

        $("#btnReestablecerPassword").on('click', function() {
            $("#modalReestablecerPassword").modal('show');
        });

        $("#confirmar_password").change(function() {
            if ($("#confirmar_password").val() != $("#password").val()) {
                $("#confirmar_password").addClass("is-invalid");
                $("#confirmar_password").parent().children(".invalid-feedback").html("Las contraseñas no coinciden");
                $("#confirmar_password").val("");
            } else {
                $("#confirmar_password").removeClass("is-invalid");
            }
        });

        $("#password").change(function() {
            if ($("#password").val().length < 6) {
                $("#password").addClass("is-invalid");
                $("#password").parent().children(".invalid-feedback").html("Mínimo 6 caracteres");
                $("#password").val("");
            } else {
                $("#password").removeClass("is-invalid");
            }
        });

        $("#btnCambiarPassword").on('click', function() {
            fnc_CambiarPassword();
        });
    });

    function fnc_login() {
        var forms = document.getElementsByClassName('needs-validation-login');
        var validation = Array.prototype.filter.call(forms, function(form) {
            if (form.checkValidity() === true) {
                var formData = new FormData();
                formData.append('accion', 'login');
                formData.append('usuario', $("#loginUsuario").val());
                formData.append('password', $("#loginPassword").val());

                response = SolicitudAjax("ajax/auth.ajax.php", "POST", formData);
                
                if (response["tipo_msj"] == "success") {
                    $("#btnIniciarSesion").addClass('disabled');                    
                    mensajeToast(response["tipo_msj"], response["msj"]);

                    setInterval(() => {
                        $("#btnIniciarSesion").removeClass('disabled');
                        window.location = "<?php echo $ruta; ?>";
                    }, 1200);
                } else {
                    mensajeToast(response["tipo_msj"], response["msj"]);
                    $("#btnIniciarSesion").removeClass('disabled');
                }
            } else {
                mensajeToast('error', 'Ingrese el usuario y contraseña');
            }
        });
    }

    function fnc_CambiarPassword() {
        form_usuario_validate = true;
        
        // Validar campos del formulario
        if ($("#usuario").val() == "" || $("#password").val() == "" || $("#confirmar_password").val() == "") {
            form_usuario_validate = false;
        }

        if (!form_usuario_validate) {
            mensajeToast("error", "Complete los datos obligatorios");
            return;
        }

        Swal.fire({
            title: '¿Está seguro(a) de cambiar la contraseña?',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#00c292',
            cancelButtonColor: '#d33',
            confirmButtonText: 'Sí!',
            cancelButtonText: 'No',
        }).then((result) => {
            if (result.isConfirmed) {
                var formData = new FormData();
                formData.append('accion', 'cambiar_password');
                formData.append('usuario', $("#usuario").val());
                formData.append('password', $("#password").val());

                response = SolicitudAjax('ajax/usuarios.ajax.php', 'POST', formData);

                Swal.fire({
                    position: 'top-center',
                    icon: response['tipo_msj'],
                    title: response['msj'],
                    showConfirmButton: true,
                    timer: 2000
                });

                $("#modalReestablecerPassword").modal('hide');
            }
        });
    }
</script>