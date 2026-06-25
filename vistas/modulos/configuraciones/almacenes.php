<div class="content-header">
    <div class="container-fluid">
        <div class="row">
            <div class="col-md-6">
                <h2 class="m-0 fw-bold">ADMINISTRAR ALMACENES</h2>
            </div>
            <div class="col-md-6 d-none d-md-block">
                <ol class="breadcrumb float-md-right">
                    <li class="breadcrumb-item"><a href="index.php">Inicio</a></li>
                    <li class="breadcrumb-item">Configuraciones</li>
                    <li class="breadcrumb-item active">Almacenes</li>
                </ol>
            </div>
        </div>
    </div>
</div>

<div class="content">
    <div class="container-fluid">
        <div class="card card-gray shadow mt-4">
            <div class="card-body px-3 py-3" style="position: relative;">
                <span class="titulo-fieldset px-3 py-1">LISTADO DE ALMACENES</span>
                <div class="row my-3">
                    <div class="col-12">
                        <table id="tbl_almacenes" class="table table-striped w-100 shadow border border-secondary">
                            <thead class="bg-main text-left">
                                <th>Opciones</th>
                                <th>Id</th>
                                <th>Nombre</th>
                                <th>Dirección</th>
                                <th>Estado</th>
                            </thead>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="mdlGestionarAlmacen" tabindex="-1" aria-labelledby="exampleModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-md modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header bg-main py-2">
                <h6 class="modal-title titulo_modal_almacen">Registrar Almacén</h6>
                <button type="button" class="text-white m-0 px-1 badge badge-pill badge-danger" data-bs-dismiss="modal" aria-label="Close">
                    <i class="fas fa-times text-white"></i>
                </button>
            </div>
            <div class="modal-body">
                <form class="needs-validation-almacenes" novalidate>
                    <div class="row">
                        <div class="col-md-12 mb-3">
                            <label class="mb-0 ml-1 text-sm my-text-color"><i class="fas fa-warehouse mr-1 my-text-color"></i>Nombre del Almacén</label>
                            <input type="text" style="border-radius: 20px;" class="form-control form-control-sm" id="nombre_almacen" name="nombre_almacen" required>
                            <div class="invalid-feedback">Ingrese el nombre del almacén</div>
                        </div>
                        <div class="col-md-12 mb-3">
                            <label class="mb-0 ml-1 text-sm my-text-color"><i class="fas fa-map-marker-alt mr-1 my-text-color"></i>Dirección</label>
                            <input type="text" style="border-radius: 20px;" class="form-control form-control-sm" id="direccion_almacen" name="direccion_almacen" required>
                            <div class="invalid-feedback">Ingrese la dirección del almacén</div>
                        </div>
                        <div class="col-md-12 mb-3">
                            <label class="mb-0 ml-1 text-sm my-text-color"><i class="fas fa-toggle-on mr-1 my-text-color"></i>Estado</label>
                            <select class="form-select form-select-sm" id="estado_almacen" name="estado_almacen" required>
                                <option value="1">ACTIVO</option>
                                <option value="0">INACTIVO</option>
                            </select>
                        </div>
                        <div class="col-md-12 mt-3 text-center">
                            <a class="btn btn-sm btn-success fw-bold" id="btnRegistrarAlmacen" style="position: relative; width: 50%;">
                                <span class="text-button">GUARDAR</span>
                                <span class="btn fw-bold icon-btn-success d-flex align-items-center">
                                    <i class="fas fa-save fs-5 text-white m-0 p-0"></i>
                                </span>
                            </a>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<script>
    var $global_id_almacen = 0;

    $(document).ready(function() {
        fnc_InicializarFormulario();

        $('#tbl_almacenes tbody').on('click', '.btnEditarAlmacen', function() {
            var data = $('#tbl_almacenes').DataTable().row($(this).parents('tr')).data();
            fnc_MostrarModalEditarAlmacen(data);
        });

        $('#tbl_almacenes tbody').on('click', '.btnEliminarAlmacen', function() {
            var data = $('#tbl_almacenes').DataTable().row($(this).parents('tr')).data();
            fnc_EliminarAlmacen(data.id);
        });

        $('#tbl_almacenes tbody').on('click', '.btnActivarAlmacen', function() {
            var data = $('#tbl_almacenes').DataTable().row($(this).parents('tr')).data();
            fnc_CambiarEstadoAlmacen(data.id, data.nombre, data.direccion, 1);
        });

        $('#tbl_almacenes tbody').on('click', '.btnDesactivarAlmacen', function() {
            var data = $('#tbl_almacenes').DataTable().row($(this).parents('tr')).data();
            fnc_CambiarEstadoAlmacen(data.id, data.nombre, data.direccion, 0);
        });

        $("#btnRegistrarAlmacen").on('click', function() {
            fnc_guardarAlmacen();
        });

        $('#mdlGestionarAlmacen').on('hidden.bs.modal', function(e) {
            $("#nombre_almacen").val('');
            $("#direccion_almacen").val('');
            $("#estado_almacen").val('1');
            $(".needs-validation-almacenes").removeClass("was-validated");
        });
    });

    function fnc_InicializarFormulario() {
        fnc_CargarDatatableAlmacenes();
    }

    function fnc_CargarDatatableAlmacenes() {
        if ($.fn.DataTable.isDataTable('#tbl_almacenes')) {
            $('#tbl_almacenes').DataTable().destroy();
            $('#tbl_almacenes tbody').empty();
        }

        $("#tbl_almacenes").DataTable({
            dom: 'Bfrtip',
            buttons: [{
                    text: 'Agregar Almacén',
                    className: 'addNewRecord',
                    action: function(e, dt, node, config) {
                        $(".titulo_modal_almacen").html("Registrar Almacén");
                        $("#mdlGestionarAlmacen").modal('show');
                        $global_id_almacen = 0;
                    }
                },
                {
                    extend: 'excel',
                    title: function() {
                        return 'LISTADO DE ALMACENES';
                    }
                }, 'pageLength'
            ],
            ajax: {
                url: 'ajax/almacenes.ajax.php',
                type: 'POST',
                data: {
                    'accion': 'listar_almacenes'
                },
                dataSrc: ""
            },
            scrollX: true,
            columns: [
                { data: null },
                { data: 'id' },
                { data: 'nombre' },
                { data: 'direccion' },
                { data: 'estado' }
            ],
            columnDefs: [
                {
                    className: "dt-center",
                    targets: "_all"
                },
                {
                    targets: 0,
                    sortable: false,
                    render: function(data, type, full, meta) {
                        var opciones = `<center>
                                        <span class='btnEditarAlmacen text-primary px-1' style='cursor:pointer;' data-bs-toggle='tooltip' data-bs-placement='top' title='Editar Almacén'> 
                                            <i class='fas fa-pencil-alt fs-5'></i> 
                                        </span>`;
                        if (full.estado === "ACTIVO") {
                            opciones += `<span class='btnDesactivarAlmacen text-success px-1' style='cursor:pointer;' data-bs-toggle='tooltip' data-bs-placement='top' title='Desactivar Almacén'>
                                            <i class='fas fa-toggle-on fs-5'></i> 
                                         </span>`;
                        } else {
                            opciones += `<span class='btnActivarAlmacen text-danger px-1' style='cursor:pointer;' data-bs-toggle='tooltip' data-bs-placement='top' title='Activar Almacén'>
                                            <i class='fas fa-toggle-off fs-5'></i>
                                         </span>`;
                        }
                        opciones += `</center>`;
                        return opciones;
                    }
                },
                {
                    targets: 4,
                    createdCell: function(td, cellData, rowData, row, col) {
                        if (cellData === 'ACTIVO') {
                            $(td).html('<span class="bg-success px-2 py-1 rounded-pill fw-bold"> ACTIVO </span>');
                        } else {
                            $(td).html('<span class="bg-danger px-2 py-1 rounded-pill fw-bold"> INACTIVO </span>');
                        }
                    }
                }
            ],
            language: {
                url: "ajax/language/spanish.json"
            }
        });
    }

    function fnc_guardarAlmacen() {
        var form_validate = validarFormulario('needs-validation-almacenes');

        if (!form_validate) {
            mensajeToast("error", "Complete los datos obligatorios");
            return;
        }

        Swal.fire({
            title: '¿Está seguro de ' + ($global_id_almacen > 0 ? 'actualizar' : 'registrar') + ' el almacén?',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#3085d6',
            cancelButtonColor: '#d33',
            confirmButtonText: 'Aceptar!',
            cancelButtonText: 'Cancelar!',
        }).then((result) => {
            if (result.isConfirmed) {
                var formData = new FormData();
                formData.append('accion', $global_id_almacen > 0 ? 'actualizar_almacen' : 'registrar_almacen');
                if ($global_id_almacen > 0) {
                    formData.append("id", $global_id_almacen);
                }
                formData.append("nombre", $("#nombre_almacen").val());
                formData.append("direccion", $("#direccion_almacen").val());
                formData.append("estado", $("#estado_almacen").val());

                var response = SolicitudAjax("ajax/almacenes.ajax.php", "POST", formData);

                Swal.fire({
                    position: 'top-center',
                    icon: response.tipo_msj,
                    title: response.msj,
                    showConfirmButton: true
                });

                $("#mdlGestionarAlmacen").modal('hide');
                fnc_CargarDatatableAlmacenes();
            }
        });
    }

    function fnc_MostrarModalEditarAlmacen(data) {
        $(".titulo_modal_almacen").html("Actualizar Almacén");
        $("#mdlGestionarAlmacen").modal('show');

        $global_id_almacen = data.id;
        $("#nombre_almacen").val(data.nombre);
        $("#direccion_almacen").val(data.direccion);
        $("#estado_almacen").val(data.estado === 'ACTIVO' ? '1' : '0');
    }

    function fnc_CambiarEstadoAlmacen(id, nombre, direccion, estado) {
        var formData = new FormData();
        formData.append("accion", 'actualizar_almacen');
        formData.append("id", id);
        formData.append("nombre", nombre);
        formData.append("direccion", direccion);
        formData.append("estado", estado);

        var response = SolicitudAjax("ajax/almacenes.ajax.php", "POST", formData);

        Swal.fire({
            position: 'top-center',
            icon: response.tipo_msj,
            title: response.msj,
            showConfirmButton: true
        });

        fnc_CargarDatatableAlmacenes();
    }
</script>
