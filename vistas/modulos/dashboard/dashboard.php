<?php
    // include "ajax/rutas.ajax.php";
    // $ruta = Rutas::RutaProyecto();
    // var_dump($ruta);
?>

<?php
    // Obtener datos de la sesión para el saludo
    $nombreUsuario = $_SESSION["usuario"]->nombre_usuario ?? "Usuario";

    $dias = array("domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado");
    $meses = array("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre");
    
    $diaSemana = $dias[date('w')];
    $dia = date('d');
    $mes = $meses[date('n') - 1];
    $anio = date('Y');
    
    $fechaCompleta = ucfirst($diaSemana) . ", $dia de $mes de $anio";
?>

<!-- Importar Tailwind CSS e Inter Font para el Dashboard -->
<script src="https://cdn.tailwindcss.com"></script>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">

<style>
    .content-wrapper {
        background-color: #f8fafc !important;
        font-family: 'Inter', sans-serif !important;
    }
    
    /* Estilos personalizados para mantener el diseño premium de saas_minimarket */
    .titulo-fieldset {
        background-color: #00c292 !important;
        color: #ffffff !important;
        font-weight: 700;
        font-size: 13px;
        letter-spacing: 0.5px;
        text-transform: uppercase;
        border-radius: 8px;
        position: absolute;
        top: -15px;
        left: 20px;
        box-shadow: 0 4px 10px rgba(0, 194, 146, 0.2);
    }
    
    .dashboard-card {
        border-radius: 16px !important;
        border: 1px solid #edf2f7 !important;
        background-color: #ffffff !important;
        box-shadow: 0 4px 6px -1px rgba(0,0,0,0.02), 0 2px 4px -1px rgba(0,0,0,0.01) !important;
    }
    
    .table thead th {
        border-bottom: 2px solid #edf2f7 !important;
        color: #718096 !important;
        font-size: 12px !important;
        font-weight: 700 !important;
        text-transform: uppercase !important;
        letter-spacing: 0.5px;
    }
    
    .table td {
        border-bottom: 1px solid #f1f5f9 !important;
        padding: 12px 8px !important;
        font-size: 14px !important;
        color: #4a5568 !important;
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
                        500: '#00c292',
                        600: '#00a87d',
                        700: '#008f6a'
                    }
                }
            }
        }
    }
</script>

<!-- Content Header -->
<div class="content-header px-4 pt-4">
    <div class="container-fluid">
        <!-- Banner de bienvenida -->
        <div class="mb-4 flex items-center gap-3 rounded-xl border border-brand-200 bg-brand-50 px-4 py-3 shadow-sm">
            <svg class="w-5 h-5 text-brand-600 shrink-0" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z" clip-rule="evenodd"/>
            </svg>
            <p class="text-sm font-semibold text-brand-800">¡Bienvenido Administrador del Sistema!</p>
        </div>

        <div class="mb-5 flex flex-col md:flex-row md:items-center md:justify-between">
            <div>
                <h2 class="text-3xl font-extrabold text-slate-800 tracking-tight">¡Hola, <?php echo explode(' ', $nombreUsuario)[0]; ?>! 👋</h2>
                <p class="text-slate-500 text-sm mt-0.5">Resumen de tu negocio</p>
            </div>
            <div class="flex items-center gap-2 text-slate-500 bg-white border border-slate-200 px-4 py-2.5 rounded-xl shadow-sm text-sm font-semibold mt-3 md:mt-0">
                <i class="far fa-calendar-alt text-[#00c292] text-base"></i>
                <span><?php echo $fechaCompleta; ?></span>
            </div>
        </div>
    </div>
</div>

<!-- Main content -->
<div class="content px-4">
    <div class="container-fluid">

        <!-- KPI CARDS GRID -->
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-6 gap-4 mb-6">
            
            <!-- Ventas del día -->
            <div class="relative overflow-hidden rounded-2xl bg-gradient-to-br from-teal-400 to-cyan-600 p-4 text-white shadow-md">
                <div class="flex items-start justify-between">
                    <div class="rounded-lg bg-white/20 p-2">
                        <i class="fas fa-calendar-day text-lg"></i>
                    </div>
                    <span class="rounded-full bg-white/20 px-2.5 py-0.5 text-[9px] font-bold tracking-wide">HOY</span>
                </div>
                <p class="mt-3 text-xs font-semibold text-white/80">Ventas del día</p>
                <p class="text-xl font-extrabold" id="totalVentasHoy">S/ 0.00</p>
            </div>

            <!-- Costo Inventario -->
            <div class="relative overflow-hidden rounded-2xl bg-gradient-to-br from-blue-400 to-blue-600 p-4 text-white shadow-md">
                <div class="flex items-start justify-between">
                    <div class="rounded-lg bg-white/20 p-2">
                        <i class="fas fa-boxes text-lg"></i>
                    </div>
                    <span class="rounded-full bg-white/20 px-2.5 py-0.5 text-[9px] font-bold tracking-wide">INVENTARIO</span>
                </div>
                <p class="mt-3 text-xs font-semibold text-white/80">Costo Inventario</p>
                <p class="text-xl font-extrabold" id="totalCompras">S/ 0.00</p>
            </div>

            <!-- Total Ventas -->
            <div class="relative overflow-hidden rounded-2xl bg-gradient-to-br from-amber-400 to-orange-500 p-4 text-white shadow-md">
                <div class="flex items-start justify-between">
                    <div class="rounded-lg bg-white/20 p-2">
                        <i class="fas fa-shopping-cart text-lg"></i>
                    </div>
                    <span class="rounded-full bg-white/20 px-2.5 py-0.5 text-[9px] font-bold tracking-wide">VENTAS</span>
                </div>
                <p class="mt-3 text-xs font-semibold text-white/80">Total Ventas</p>
                <p class="text-xl font-extrabold" id="totalVentas">S/ 0.00</p>
            </div>

            <!-- Total Ganancias -->
            <div class="relative overflow-hidden rounded-2xl bg-gradient-to-br from-violet-400 to-purple-600 p-4 text-white shadow-md">
                <div class="flex items-start justify-between">
                    <div class="rounded-lg bg-white/20 p-2">
                        <i class="fas fa-chart-pie text-lg"></i>
                    </div>
                    <span class="rounded-full bg-white/20 px-2.5 py-0.5 text-[9px] font-bold tracking-wide">GANANCIA</span>
                </div>
                <p class="mt-3 text-xs font-semibold text-white/80">Total Ganancias</p>
                <p class="text-xl font-extrabold" id="totalGanancias">S/ 0.00</p>
            </div>

            <!-- Productos Registrados -->
            <div class="relative overflow-hidden rounded-2xl bg-gradient-to-br from-emerald-400 to-emerald-600 p-4 text-white shadow-md">
                <div class="flex items-start justify-between">
                    <div class="rounded-lg bg-white/20 p-2">
                        <i class="fas fa-clipboard-list text-lg"></i>
                    </div>
                    <span class="rounded-full bg-white/20 px-2.5 py-0.5 text-[9px] font-bold tracking-wide">ITEMS</span>
                </div>
                <p class="mt-3 text-xs font-semibold text-white/80">Productos</p>
                <p class="text-xl font-extrabold" id="totalProductos">0</p>
            </div>

            <!-- Productos poco stock -->
            <div class="relative overflow-hidden rounded-2xl bg-gradient-to-br from-rose-400 to-red-600 p-4 text-white shadow-md">
                <div class="flex items-start justify-between">
                    <div class="rounded-lg bg-white/20 p-2">
                        <i class="fas fa-exclamation-triangle text-lg"></i>
                    </div>
                    <span class="rounded-full bg-white/20 px-2.5 py-0.5 text-[9px] font-bold tracking-wide">ALERTAS</span>
                </div>
                <p class="mt-3 text-xs font-semibold text-white/80">Poco Stock</p>
                <p class="text-xl font-extrabold" id="totalProductosMinStock">0</p>
            </div>

        </div> <!-- ./row Tarjetas Informativas -->

        <!-- GRÁFICOS Y ANÁLISIS -->
        <div class="row">
            
            <!-- Ventas del Mes (Gráfico de Barras) -->
            <div class="col-12">
                <div class="card dashboard-card mt-5 relative">
                    <div class="card-body px-3 py-3" style="position: relative;">
                        <span class="titulo-fieldset px-4 py-1.5" id="title-header-ventas-mes">Ventas del Mes</span>
                        <div class="row mt-4">
                            <div class="col-12">
                                <div class="card-body">
                                    <div class="chart">
                                        <canvas id="barChart" style="min-height: 250px; height: 300px; max-height: 350px; width: 100%;"></canvas>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Ventas por Categorías -->
            <div class="col-12 col-lg-6">
                <div class="card dashboard-card mt-5 relative">
                    <div class="card-body px-3 py-3">
                        <span class="titulo-fieldset px-4 py-1.5">Top Ventas por Categorías</span>
                        <div class="row mt-4">
                            <div class="col-12">
                                <div class="chart py-2">
                                    <div id="chartContainer" style="min-height: 250px; height: 300px; max-height: 350px; width: 100%;"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Comprobantes Emitidos -->
            <div class="col-12 col-lg-6">
                <div class="card dashboard-card mt-5 relative">
                    <div class="card-body px-3 py-3">
                        <span class="titulo-fieldset px-4 py-1.5">Comprobantes Emitidos</span>
                        <div class="row mt-4">
                            <div class="col-12">
                                <div class="chart py-2">
                                    <div id="chartContainerFacturasBoletas" style="min-height: 250px; height: 300px; max-height: 350px; width: 100%;"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

        </div><!-- ./row Graficos -->

        <!-- PRODUCTOS MAS VENDIDOS Y POCO STOCK -->
        <div class="row mb-5">

            <!-- Productos Más Vendidos -->
            <div class="col-lg-6">
                <div class="card dashboard-card mt-5 relative">
                    <div class="card-body px-3 py-3">
                        <span class="titulo-fieldset px-4 py-1.5">Productos Más Vendidos</span>
                        <div class="row mt-4">
                            <div class="col-12">
                                <div class="table-responsive">
                                    <table class="table" id="tbl_productos_mas_vendidos">
                                        <thead>
                                            <tr class="text-slate-500">
                                                <th>Producto</th>
                                                <th class="text-center">Cantidad</th>
                                                <th class="text-center">Ventas</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <!-- Se llena dinámicamente -->
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Productos Poco Stock -->
            <div class="col-lg-6">
                <div class="card dashboard-card mt-5 relative">
                    <div class="card-body px-3 py-3">
                        <span class="titulo-fieldset px-4 py-1.5">Productos con Poco Stock</span>
                        <div class="row mt-4">
                            <div class="col-12">
                                <div class="table-responsive">
                                    <table class="table" id="tbl_productos_poco_stock">
                                        <thead>
                                            <tr class="text-slate-500">
                                                <th>Producto</th>
                                                <th class="text-center">Stock Actual</th>
                                                <th class="text-center">Mín. Stock</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <!-- Se llena dinámicamente -->
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

        </div><!-- ./row Tablas -->

    </div><!-- /.container-fluid -->
</div>
<!-- /.content -->

<div class="loading">Loading</div>

<script>
    $(document).ready(function() {

        // console.log($ruta);
        fnc_MostrarLoader()

        cargarTarjetasInformativas();
        cargarGraficoBarras();
        cargarGraficoDoughnut();
        cargarProductosMasVendidos();
        cargarProductosPocoStock();


        setInterval(() => {
            $.ajax({
                url: "ajax/dashboard.ajax.php",
                method: 'POST',
                data: {
                    'accion': 'datos_dashboard'
                },
                dataType: 'json',
                success: function(respuesta) {

                    $("#totalProductos").html(respuesta[0]['totalProductos']);
                    $("#totalCompras").html(respuesta[0]['totalCompras'])
                    $("#totalVentas").html(respuesta[0]['totalVentas'])
                    $("#totalGanancias").html(respuesta[0]['ganancias'])
                    $("#totalProductosMinStock").html(respuesta[0]['productosPocoStock'])
                    $("#totalVentasHoy").html(respuesta[0]['ventasHoy'])

                    // cargarTarjetasInformativas();
                    // cargarGraficoBarras();
                    // cargarGraficoDoughnut();
                    // cargarProductosMasVendidos();
                    // cargarProductosPocoStock();

                }
            });
        }, 30000);

        fnc_OcultarLoader();

    })

    function fnc_MostrarLoader() {
        $(".loading").removeClass('d-none');
        $(".loading").addClass('d-block');
    }

    function fnc_OcultarLoader() {
        $(".loading").removeClass('d-block');
        $(".loading").addClass('d-none')
    }

    /* =======================================================
    SOLICITUD AJAX TARJETAS INFORMATIVAS
    =======================================================*/
    function cargarTarjetasInformativas() {

        $.ajax({
            url: "ajax/dashboard.ajax.php",
            method: 'POST',
            data: {
                'accion': 'datos_dashboard'
            },
            dataType: 'json',
            success: function(respuesta) {
                $("#totalProductos").html(respuesta[0]['totalProductos']);
                $("#totalCompras").html(respuesta[0]['totalCompras'])
                $("#totalVentas").html(respuesta[0]['totalVentas'])
                $("#totalGanancias").html(respuesta[0]['ganancias'])
                $("#totalProductosMinStock").html(respuesta[0]['productosPocoStock'])
                $("#totalVentasHoy").html(respuesta[0]['ventasHoy'])
            }
        });

    }


    /* =======================================================
    SOLICITUD AJAX GRAFICO DE BARRAS DE VENTAS DEL MES
    =======================================================*/
    function cargarGraficoBarras() {

        $.ajax({
            url: "ajax/dashboard.ajax.php",
            method: 'POST',
            data: {
                'accion': 'grafico_barras' //parametro para obtener las ventas del mes
            },
            dataType: 'json',
            success: function(respuesta) {

                var fecha_venta = [];
                var total_venta = [];
                var total_venta_ant = [];

                var mes_actual = new Date();
                var mes_anterior = moment(mes_actual, "DD-MM-YYYY").add(-1, 'months').format('MM/YYYY');

                var total_ventas_mes = 0;

                for (let i = 0; i < respuesta.length; i++) {

                    fecha_venta.push(respuesta[i]['fecha_venta']);
                    total_venta.push(respuesta[i]['total_venta']);
                    total_venta_ant.push(respuesta[i]['total_venta_ant']);
                    total_ventas_mes = parseFloat(total_ventas_mes) + parseFloat(respuesta[i]['total_venta']);

                }

                total_venta.push(0);

                $("#title-header-ventas-mes").html('VENTAS DEL MES: S./ ' + total_ventas_mes.toFixed(2).toString().replace(/\d(?=(\d{3})+\.)/g, "$&,"));

                var barChartCanvas = $("#barChart").get(0).getContext('2d');

                var areaChartData = {
                    labels: fecha_venta,
                    datasets: [{
                        label: 'Mes Anterior - ' + mes_anterior,
                        backgroundColor: 'rgb(255, 140, 0,0.9)',
                        data: total_venta_ant
                    }, {
                        label: 'Mes Actual- ' + +Number(mes_actual.getMonth() + 1) + '/' + mes_actual.getFullYear(),
                        backgroundColor: 'rgba(60,141,188,0.9)',
                        data: total_venta
                    }]
                }

                var barChartData = $.extend(true, {}, areaChartData);

                var temp0 = areaChartData.datasets[0];

                barChartData.datasets[0] = temp0;

                var barChartOptions = {
                    maintainAspectRatio: false,
                    responsive: true,
                    events: false,
                    legend: {
                        display: true
                    },
                    scales: {
                        xAxes: [{
                            stacked: true,
                        }],
                        yAxes: [{
                            stacked: true
                        }]
                    },
                    animation: {
                        duration: 500,
                        easing: "easeOutQuart",
                        onComplete: function() {
                            var ctx = this.chart.ctx;
                            ctx.font = Chart.helpers.fontString(Chart.defaults.global
                                .defaultFontFamily, 'bold',
                                Chart.defaults.global.defaultFontFamily);
                            ctx.textAlign = 'center';
                            ctx.textBaseline = 'bottom';

                            for (var i = 0; i < this.data.datasets[1].data.length; i++) {

                                var model = this.data.datasets[1]._meta[Object.keys(this.data.datasets[1]._meta)[0]].data[i]._model,
                                    scale_max = this.data.datasets[1]._meta[Object.keys(this.data.datasets[1]._meta)[0]].data[i]._yScale.maxHeight;

                                var y_pos = model.y;

                                ctx.fillStyle = '#ffa500';
                                ctx.fillText(this.data.datasets[0].data[i], model.x + 20, y_pos);

                                ctx.fillStyle = '#0083ff';
                                ctx.fillText(this.data.datasets[1].data[i], model.x - 20, y_pos);
                            }
                        }
                    }
                }

                new Chart(barChartCanvas, {
                    type: 'bar',
                    data: barChartData,
                    options: barChartOptions
                })


            }
        });

    }


    /* =======================================================
    SOLICITUD AJAX GRAFICO DE DOUGHNUT
    =======================================================*/
    function cargarGraficoDoughnut() {

        $.ajax({
            url: "ajax/dashboard.ajax.php",
            method: 'POST',
            data: {
                'accion': 'grafico_doughnut' //parametro para obtener las ventas del mes
            },
            dataType: 'json',
            success: function(respuesta) {

                var chart = new CanvasJS.Chart("chartContainer", {
                    animationEnabled: true,
                    // title:{
                    //     text: "Email Categories",
                    //     horizontalAlign: "left"
                    // },
                    data: [{
                        type: "doughnut",
                        startAngle: 60,
                        //innerRadius: 60,
                        indexLabelFontSize: 17,
                        indexLabel: "{label} - #percent%",
                        toolTipContent: "<b>{label}:</b> {y} (#percent%)",
                        dataPoints: respuesta
                    }]
                });
                chart.render();

            }
        });

        $.ajax({
            url: "ajax/dashboard.ajax.php",
            method: 'POST',
            data: {
                'accion': 'grafico_doughnut_facturas_boletas' //parametro para obtener las ventas del mes
            },
            dataType: 'json',
            success: function(respuesta) {

                var chart = new CanvasJS.Chart("chartContainerFacturasBoletas", {
                    animationEnabled: true,
                    // title:{
                    //     text: "Email Categories",
                    //     horizontalAlign: "left"
                    // },
                    data: [{
                        type: "doughnut",
                        startAngle: 60,
                        //innerRadius: 60,
                        indexLabelFontSize: 17,
                        indexLabel: "{label} - #percent%",
                        toolTipContent: "<b>{label}:</b> {y} (#percent%)",
                        dataPoints: respuesta
                    }]
                });
                chart.render();

            }
        });



    }


    /* =======================================================
    SOLICITUD AJAX PRODUCTOS MAS VENDIDOS
    =======================================================*/
    function cargarProductosMasVendidos() {

        $("#tbl_productos_mas_vendidos tbody").html('');

        $.ajax({
            url: "ajax/dashboard.ajax.php",
            type: "POST",
            data: {
                'accion': 'productos_mas_vendidos' // listar los 10 productos mas vendidos
            },
            dataType: 'json',
            success: function(respuesta) {

                for (let i = 0; i < respuesta.length; i++) {
                    filas = '<tr>' +
                        // '<td>'+ respuesta[i]["codigo_producto"] + '</td>'+
                        '<td>' + respuesta[i]["descripcion"] + '</td>' +
                        '<td class="text-center">' + respuesta[i]["cantidad"] + '</td>' +
                        '<td class="text-center"> S./ ' + respuesta[i]["total_venta"] + '</td>' +
                        '</tr>'
                    $("#tbl_productos_mas_vendidos tbody").append(filas);
                }

            }
        });

    }


    /* =======================================================
    SOLICITUD AJAX PRODUCTOS CON POCO STOCK
    =======================================================*/
    function cargarProductosPocoStock() {

        $("#tbl_productos_poco_stock tbody").html('');

        $.ajax({
            url: "ajax/dashboard.ajax.php",
            type: "POST",
            data: {
                'accion': 'productos_poco_stock' // listar los  productos con poco stock
            },
            dataType: 'json',
            success: function(respuesta) {
                for (let i = 0; i < respuesta.length; i++) {
                    filas = '<tr>' +
                        // '<td>'+ respuesta[i]["codigo_producto"] + '</td>'+   
                        '<td>' + respuesta[i]["descripcion"] + '</td>' +
                        '<td class="text-center">' + respuesta[i]["stock"] + '</td>' +
                        '<td class="text-center">' + respuesta[i]["minimo_stock"] + '</td>' +
                        '</tr>'
                    $("#tbl_productos_poco_stock tbody").append(filas);
                }

            }
        });

    }
</script>