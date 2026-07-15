<?php
date_default_timezone_set('America/Lima');
require_once "modelos/conexion.php";

// 1. Extraer subdominio dinámicamente de la URL (ej: agrovision.sistemaventa358.com)
$subdomain = "";
if (isset($_SERVER['HTTP_HOST'])) {
    $host = $_SERVER['HTTP_HOST'];
    $hostParts = explode('.', $host);
    // Si tiene subdominio (ej: agrovision.sistemaventa358.com o local.mipos.com) y no es 'www'
    if (count($hostParts) > 2 && $hostParts[0] !== 'www') {
        $subdomain = strtolower($hostParts[0]);
    }
}

// 2. Obtener datos de la empresa (Nombre comercial, teléfono, etc.)
try {
    if (!empty($subdomain)) {
        // Intentar buscar por nombre comercial limpio, razón social limpia o por ID numérico directo
        $stmtEmpresa = Conexion::conectar()->prepare("
            SELECT id_empresa, razon_social, nombre_comercial, ruc, direccion, telefono, logo 
            FROM empresas 
            WHERE REPLACE(LOWER(nombre_comercial), ' ', '') = :subdomain 
               OR REPLACE(LOWER(razon_social), ' ', '') = :subdomain
               OR id_empresa = :subdomain_val
            LIMIT 1
        ");
        $stmtEmpresa->bindValue(":subdomain", $subdomain, PDO::PARAM_STR);
        $subdomainVal = is_numeric($subdomain) ? (int)$subdomain : 0;
        $stmtEmpresa->bindValue(":subdomain_val", $subdomainVal, PDO::PARAM_INT);
    } else {
        // Si no hay subdominio, cargar la primera empresa registrada
        $stmtEmpresa = Conexion::conectar()->prepare("
            SELECT id_empresa, razon_social, nombre_comercial, ruc, direccion, telefono, logo 
            FROM empresas 
            LIMIT 1
        ");
    }
    
    $stmtEmpresa->execute();
    $empresa = $stmtEmpresa->fetch(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    $empresa = null;
}

// Valores por defecto si la base de datos no tiene datos de empresa
$nombreNegocio = ($empresa && !empty($empresa['nombre_comercial'])) ? $empresa['nombre_comercial'] : (($empresa && !empty($empresa['razon_social'])) ? $empresa['razon_social'] : "Yusu Catálogo");
$rucNegocio = ($empresa && !empty($empresa['ruc'])) ? $empresa['ruc'] : "";
$direccionNegocio = ($empresa && !empty($empresa['direccion'])) ? $empresa['direccion'] : "";
$telefonoNegocio = ($empresa && !empty($empresa['telefono'])) ? $empresa['telefono'] : "51918604494"; 

// Limpiar el teléfono para que solo tenga dígitos y código de país
$whatsappNumero = preg_replace('/\D/', '', $telefonoNegocio);
if (strlen($whatsappNumero) === 9) {
    $whatsappNumero = "51" . $whatsappNumero; 
}

// Logo de la empresa
$logoFile = ($empresa && !empty($empresa['logo'])) ? $empresa['logo'] : "mi_logo_tutorialesphperu.png";
$logoPath = "vistas/assets/dist/img/logos_empresas/" . $logoFile;

// 3. Obtener lista de productos activos (filtrando por almacén vinculado si corresponde)
$productos = [];
try {
    // Si la empresa tiene un almacén en específico, aquí podríamos cambiar pa.id_almacen por el id_empresa
    $id_almacen_consulta = ($empresa && isset($empresa['id_empresa'])) ? (int)$empresa['id_empresa'] : 1;

    $stmt = Conexion::conectar()->prepare("
        SELECT  
            p.id, 
            p.codigo_producto, 
            p.descripcion as producto, 
            p.precio_unitario_con_igv, 
            IFNULL(pa.stock, 0) as stock, 
            p.imagen
        FROM productos p 
        LEFT JOIN productos_almacenes pa ON p.codigo_producto = pa.codigo_producto AND pa.id_almacen = :id_almacen
        WHERE p.estado = 1
        ORDER BY p.descripcion ASC
    ");
    $stmt->bindValue(":id_almacen", $id_almacen_consulta, PDO::PARAM_INT);
    $stmt->execute();
    $productos = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    // Silencioso en producción
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Catálogo Online - <?php echo htmlspecialchars($nombreNegocio); ?></title>
    
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    
    <!-- Ionicons for Icons -->
    <script type="module" src="https://unpkg.com/ionicons@7.1.0/dist/ionicons/ionicons.esm.js"></script>
    <script nomodule src="https://unpkg.com/ionicons@7.1.0/dist/ionicons/ionicons.js"></script>

    <style>
        :root {
            --primary: #00c292;
            --primary-dark: #00a87d;
            --primary-light: #e6f9f4;
            --dark: #1a202c;
            --gray-text: #718096;
            --gray-light: #f7fafc;
            --gray-border: #edf2f7;
            --white: #ffffff;
            --transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Outfit', sans-serif;
            -webkit-tap-highlight-color: transparent;
        }

        body {
            background-color: var(--gray-light);
            color: var(--dark);
            padding-bottom: 90px;
            overflow-x: hidden;
        }

        /* Cabecera Principal */
        header {
            background-color: var(--white);
            padding: 20px 16px;
            text-align: center;
            border-bottom: 1px solid var(--gray-border);
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
            position: sticky;
            top: 0;
            z-index: 100;
        }

        .header-logo {
            width: 70px;
            height: 70px;
            border-radius: 50%;
            object-fit: cover;
            margin-bottom: 10px;
            border: 2px solid var(--primary-light);
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }

        .header-title {
            font-size: 22px;
            font-weight: 800;
            color: var(--dark);
            letter-spacing: -0.5px;
        }

        .header-subtitle {
            font-size: 13px;
            color: var(--gray-text);
            margin-top: 4px;
            font-weight: 500;
        }

        /* Buscador */
        .search-container {
            padding: 16px;
            background-color: var(--white);
            border-bottom: 1px solid var(--gray-border);
            position: sticky;
            top: 130px;
            z-index: 99;
        }

        .search-wrapper {
            display: flex;
            align-items: center;
            background-color: var(--gray-light);
            border: 1px solid var(--gray-border);
            border-radius: 12px;
            padding: 0 14px;
            height: 48px;
            transition: var(--transition);
        }

        .search-wrapper:focus-within {
            border-color: var(--primary);
            background-color: var(--white);
            box-shadow: 0 0 0 3px var(--primary-light);
        }

        .search-icon {
            font-size: 20px;
            color: var(--gray-text);
            margin-right: 10px;
        }

        .search-input {
            flex: 1;
            border: none;
            background: transparent;
            outline: none;
            font-size: 15px;
            color: var(--dark);
            font-weight: 500;
        }

        /* Contenido de Productos */
        .content {
            padding: 16px;
            max-width: 600px;
            margin: 0 auto;
        }

        .grid-layout {
            display: grid;
            grid-template-columns: 1fr;
            gap: 16px;
        }

        /* Tarjeta de Producto */
        .product-card {
            background-color: var(--white);
            border-radius: 16px;
            overflow: hidden;
            display: flex;
            align-items: center;
            padding: 12px;
            border: 1px solid var(--gray-border);
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.02);
            transition: var(--transition);
        }

        .product-card:active {
            transform: scale(0.98);
        }

        .product-image-wrapper {
            position: relative;
            margin-right: 14px;
        }

        .product-image {
            width: 80px;
            height: 80px;
            border-radius: 12px;
            object-fit: cover;
            background-color: var(--gray-light);
        }

        .product-placeholder {
            width: 80px;
            height: 80px;
            border-radius: 12px;
            background-color: #4e5d6c;
            display: flex;
            justify-content: center;
            align-items: center;
            color: var(--white);
            font-weight: 800;
            font-size: 16px;
            text-transform: uppercase;
            text-align: center;
            padding: 4px;
        }

        .product-info {
            flex: 1;
            display: flex;
            flex-direction: column;
            justify-content: center;
            min-width: 0; /* Permite truncado de texto */
        }

        .product-name {
            font-size: 16px;
            font-weight: 600;
            color: var(--dark);
            line-height: 1.3;
            margin-bottom: 4px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .product-stock {
            font-size: 12px;
            font-weight: 600;
            color: var(--gray-text);
            margin-bottom: 8px;
        }

        .stock-alert {
            color: #dd6b20;
        }

        .stock-empty {
            color: #e53e3e;
        }

        .product-price-action {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-top: 2px;
        }

        .product-price {
            font-size: 18px;
            font-weight: 800;
            color: var(--dark);
        }

        /* Controles de Cantidad en la Tarjeta */
        .action-container {
            display: flex;
            align-items: center;
        }

        .add-cart-btn {
            background-color: var(--primary);
            color: var(--white);
            border: none;
            width: 36px;
            height: 36px;
            border-radius: 50%;
            display: flex;
            justify-content: center;
            align-items: center;
            cursor: pointer;
            transition: var(--transition);
            box-shadow: 0 4px 6px rgba(0, 194, 146, 0.2);
        }

        .add-cart-btn:active {
            transform: scale(0.9);
            background-color: var(--primary-dark);
        }

        .quantity-selector {
            display: flex;
            align-items: center;
            background-color: var(--primary-light);
            border-radius: 20px;
            padding: 2px;
        }

        .qty-btn {
            background: transparent;
            border: none;
            width: 32px;
            height: 32px;
            border-radius: 50%;
            display: flex;
            justify-content: center;
            align-items: center;
            color: var(--primary);
            font-size: 18px;
            font-weight: bold;
            cursor: pointer;
        }

        .qty-value {
            font-size: 15px;
            font-weight: 700;
            color: var(--primary-dark);
            padding: 0 10px;
            min-width: 25px;
            text-align: center;
        }

        /* Barra de Carrito Flotante */
        .cart-bar {
            position: fixed;
            bottom: 20px;
            left: 16px;
            right: 16px;
            background-color: var(--dark);
            border-radius: 16px;
            padding: 16px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            color: var(--white);
            box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3);
            z-index: 101;
            transform: translateY(120px);
            transition: transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        }

        .cart-bar.visible {
            transform: translateY(0);
        }

        .cart-bar-left {
            display: flex;
            align-items: center;
        }

        .cart-badge {
            background-color: var(--primary);
            color: var(--white);
            font-size: 12px;
            font-weight: 800;
            padding: 4px 10px;
            border-radius: 20px;
            margin-right: 12px;
        }

        .cart-bar-info {
            display: flex;
            flex-direction: column;
        }

        .cart-bar-total {
            font-size: 18px;
            font-weight: 800;
        }

        .cart-bar-label {
            font-size: 11px;
            color: var(--gray-text);
        }

        .cart-bar-btn {
            background-color: var(--primary);
            color: var(--white);
            border: none;
            padding: 10px 16px;
            border-radius: 12px;
            font-size: 14px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 6px;
            cursor: pointer;
        }

        /* Modal / Cajón del Carrito */
        .cart-drawer-backdrop {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: rgba(0,0,0,0.5);
            z-index: 102;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.3s ease;
        }

        .cart-drawer-backdrop.visible {
            opacity: 1;
            pointer-events: auto;
        }

        .cart-drawer {
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            background-color: var(--white);
            border-top-left-radius: 24px;
            border-top-right-radius: 24px;
            max-height: 85%;
            z-index: 103;
            transform: translateY(100%);
            transition: transform 0.35s cubic-bezier(0.25, 0.8, 0.25, 1);
            display: flex;
            flex-direction: column;
            padding-bottom: env(safe-area-inset-bottom, 20px);
        }

        .cart-drawer.visible {
            transform: translateY(0);
        }

        .drawer-header {
            padding: 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-bottom: 1px solid var(--gray-border);
        }

        .drawer-title {
            font-size: 18px;
            font-weight: 800;
        }

        .close-drawer-btn {
            background: transparent;
            border: none;
            font-size: 28px;
            color: var(--gray-text);
            cursor: pointer;
        }

        .drawer-items {
            flex: 1;
            overflow-y: auto;
            padding: 10px 20px;
            max-height: 300px;
        }

        .drawer-item-row {
            display: flex;
            align-items: center;
            padding: 14px 0;
            border-bottom: 1px solid var(--gray-border);
        }

        .drawer-item-row:last-child {
            border-bottom: none;
        }

        .drawer-item-name {
            flex: 1;
            font-size: 15px;
            font-weight: 600;
            color: var(--dark);
            padding-right: 10px;
        }

        .drawer-item-price {
            font-size: 15px;
            font-weight: 700;
            color: var(--dark);
            margin-right: 15px;
        }

        .drawer-footer {
            padding: 20px;
            border-top: 1px solid var(--gray-border);
            background-color: var(--gray-light);
        }

        .drawer-summary-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 16px;
        }

        .summary-label {
            font-size: 15px;
            font-weight: 600;
            color: var(--gray-text);
        }

        .summary-value {
            font-size: 20px;
            font-weight: 800;
            color: var(--dark);
        }

        .whatsapp-submit-btn {
            background-color: #25d366; /* Color Oficial WhatsApp */
            color: var(--white);
            border: none;
            width: 100%;
            height: 52px;
            border-radius: 14px;
            font-size: 16px;
            font-weight: 700;
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 10px;
            cursor: pointer;
            box-shadow: 0 4px 10px rgba(37, 211, 102, 0.3);
            transition: var(--transition);
        }

        .whatsapp-submit-btn:active {
            transform: scale(0.98);
            background-color: #1ebd5c;
        }

        /* Empty state */
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: var(--gray-text);
        }

        .empty-state ion-icon {
            font-size: 64px;
            margin-bottom: 12px;
            color: #ccd6e0;
        }

        .empty-state-text {
            font-size: 15px;
            font-weight: 500;
        }
    </style>
</head>
<body>

    <!-- Cabecera -->
    <header>
        <img class="header-logo" src="<?php echo htmlspecialchars($logoPath); ?>" onerror="this.src='vistas/assets/dist/img/mi_logo_tutorialesphperu.png';" alt="Logo">
        <h1 class="header-title"><?php echo htmlspecialchars($nombreNegocio); ?></h1>
        <p class="header-subtitle">Realiza tu pedido y recíbelo por WhatsApp</p>
    </header>

    <!-- Buscador -->
    <div class="search-container">
        <div class="search-wrapper">
            <ion-icon class="search-icon" name="search-outline"></ion-icon>
            <input class="search-input" type="text" id="searchInput" placeholder="Buscar productos..." oninput="filtrarProductos()">
        </div>
    </div>

    <!-- Contenido -->
    <div class="content">
        <div class="grid-layout" id="productsGrid">
            <?php if (empty($productos)): ?>
                <div class="empty-state">
                    <ion-icon name="cube-outline"></ion-icon>
                    <p class="empty-state-text">No hay productos disponibles por el momento.</p>
                </div>
            <?php else: ?>
                <?php foreach ($productos as $prod): 
                    $id = $prod['id'];
                    $codigo = htmlspecialchars($prod['codigo_producto']);
                    $nombre = htmlspecialchars($prod['producto']);
                    $precio = number_format((float)$prod['precio_unitario_con_igv'], 2, '.', '');
                    $stock = (int)$prod['stock'];
                    
                    // Formatear Imagen
                    $imagenUrl = "";
                    if (!empty($prod['imagen'])) {
                        $cleanPath = preg_replace('/^\.\.\//', '', $prod['imagen']);
                        if (strpos($cleanPath, 'vistas/assets/') === false) {
                            $cleanPath = "vistas/assets/imagenes/productos/" . $cleanPath;
                        }
                        $imagenUrl = $cleanPath;
                    }
                    
                    // Primer palabra para el placeholder
                    $words = explode(" ", trim($nombre));
                    $firstWord = !empty($words[0]) ? substr($words[0], 0, 7) : "Item";
                ?>
                    <div class="product-card" data-id="<?php echo $id; ?>" data-codigo="<?php echo $codigo; ?>" data-nombre="<?php echo $nombre; ?>" data-precio="<?php echo $precio; ?>">
                        <div class="product-image-wrapper">
                            <?php if (!empty($imagenUrl) && file_exists($imagenUrl)): ?>
                                <img class="product-image" src="<?php echo $imagenUrl; ?>" alt="<?php echo $nombre; ?>">
                            <?php else: ?>
                                <div class="product-placeholder"><?php echo htmlspecialchars($firstWord); ?></div>
                            <?php endif; ?>
                        </div>
                        
                        <div class="product-info">
                            <h3 class="product-name"><?php echo $nombre; ?></h3>
                            
                            <?php if ($stock === 0): ?>
                                <span class="product-stock stock-empty">Agotado</span>
                            <?php elseif ($stock <= 10): ?>
                                <span class="product-stock stock-alert">¡Pocas unidades! (<?php echo $stock; ?> disp.)</span>
                            <?php else: ?>
                                <span class="product-stock"><?php echo $stock; ?> disponibles</span>
                            <?php endif; ?>
                            
                            <div class="product-price-action">
                                <span class="product-price">S/ <?php echo number_format($precio, 2); ?></span>
                                
                                <div class="action-container" id="action-<?php echo $id; ?>">
                                    <?php if ($stock > 0): ?>
                                        <button class="add-cart-btn" onclick="addToCart(<?php echo $id; ?>)">
                                            <ion-icon name="add-outline" style="font-size: 20px;"></ion-icon>
                                        </button>
                                    <?php endif; ?>
                                </div>
                            </div>
                        </div>
                    </div>
                <?php endforeach; ?>
            <?php endif; ?>
        </div>
    </div>

    <!-- Barra Flotante de Carrito -->
    <div class="cart-bar" id="cartBar" onclick="toggleDrawer(true)">
        <div class="cart-bar-left">
            <span class="cart-badge" id="cartBadge">0</span>
            <div class="cart-bar-info">
                <span class="cart-bar-total" id="cartTotal">S/ 0.00</span>
                <span class="cart-bar-label">Ver Carrito</span>
            </div>
        </div>
        <button class="cart-bar-btn">
            Pedir
            <ion-icon name="arrow-forward-outline"></ion-icon>
        </button>
    </div>

    <!-- Cajón del Carrito (Modal) -->
    <div class="cart-drawer-backdrop" id="drawerBackdrop" onclick="toggleDrawer(false)"></div>
    <div class="cart-drawer" id="cartDrawer">
        <div class="drawer-header">
            <span class="drawer-title">Tu Pedido</span>
            <button class="close-drawer-btn" onclick="toggleDrawer(false)">
                <ion-icon name="close-outline"></ion-icon>
            </button>
        </div>
        
        <div class="drawer-items" id="drawerItems">
            <!-- Items de forma dinámica -->
        </div>
        
        <div class="drawer-footer">
            <div class="drawer-summary-row">
                <span class="summary-label">Total a pagar:</span>
                <span class="summary-value" id="drawerTotal">S/ 0.00</span>
            </div>
            
            <button class="whatsapp-submit-btn" onclick="sendOrder()">
                <ion-icon name="logo-whatsapp" style="font-size: 24px;"></ion-icon>
                Enviar pedido por WhatsApp
            </button>
        </div>
    </div>

    <script>
        // Objeto Carrito
        let cart = {};

        // Cargar carrito guardado en localStorage
        document.addEventListener("DOMContentLoaded", () => {
            const savedCart = localStorage.getItem("yusu_cart");
            if (savedCart) {
                try {
                    cart = JSON.parse(savedCart);
                    updateCartUI();
                } catch(e) {
                    cart = {};
                }
            }
        });

        // Guardar Carrito
        function saveCart() {
            localStorage.setItem("yusu_cart", JSON.stringify(cart));
        }

        // Agregar al carrito
        function addToCart(productId) {
            const card = document.querySelector(`.product-card[data-id="${productId}"]`);
            if (!card) return;

            const name = card.getAttribute("data-nombre");
            const price = parseFloat(card.getAttribute("data-precio"));
            
            if (!cart[productId]) {
                cart[productId] = {
                    id: productId,
                    name: name,
                    price: price,
                    quantity: 1
                };
            } else {
                cart[productId].quantity += 1;
            }

            updateCartUI();
            saveCart();
        }

        // Quitar o disminuir cantidad
        function decreaseQuantity(productId) {
            if (!cart[productId]) return;

            cart[productId].quantity -= 1;
            if (cart[productId].quantity <= 0) {
                delete cart[productId];
            }

            updateCartUI();
            saveCart();
        }

        // Actualizar la interfaz (Tarjetas, Contador flotante, modal)
        function updateCartUI() {
            let totalItems = 0;
            let totalPrice = 0;

            // 1. Limpiar todos los botones en las tarjetas de producto
            document.querySelectorAll(".action-container").forEach(container => {
                const id = container.id.split("-")[1];
                const card = document.querySelector(`.product-card[data-id="${id}"]`);
                if (card) {
                    // Reestablecer al botón "+"
                    container.innerHTML = `
                        <button class="add-cart-btn" onclick="addToCart(${id})">
                            <ion-icon name="add-outline" style="font-size: 20px;"></ion-icon>
                        </button>
                    `;
                }
            });

            // 2. Modificar tarjetas con cantidades seleccionadas
            Object.values(cart).forEach(item => {
                totalItems += item.quantity;
                totalPrice += item.price * item.quantity;

                const container = document.getElementById(`action-${item.id}`);
                if (container) {
                    container.innerHTML = `
                        <div class="quantity-selector">
                            <button class="qty-btn" onclick="decreaseQuantity(${item.id})">-</button>
                            <span class="qty-value">${item.quantity}</span>
                            <button class="qty-btn" onclick="addToCart(${item.id})">+</button>
                        </div>
                    `;
                }
            });

            // 3. Actualizar la barra flotante de abajo
            const cartBar = document.getElementById("cartBar");
            const cartBadge = document.getElementById("cartBadge");
            const cartTotal = document.getElementById("cartTotal");

            if (totalItems > 0) {
                cartBadge.innerText = totalItems;
                cartTotal.innerText = "S/ " + totalPrice.toFixed(2);
                cartBar.classList.add("visible");
            } else {
                cartBar.classList.remove("visible");
                toggleDrawer(false); // Cerrar modal si se vacía
            }

            // 4. Actualizar datos en el modal/drawer
            updateDrawerContent(totalPrice);
        }

        // Renderizar el contenido interno del Cajón de compras
        function updateDrawerContent(totalPrice) {
            const drawerItems = document.getElementById("drawerItems");
            const drawerTotal = document.getElementById("drawerTotal");

            drawerTotal.innerText = "S/ " + totalPrice.toFixed(2);

            if (Object.keys(cart).length === 0) {
                drawerItems.innerHTML = `
                    <div class="empty-state" style="padding: 30px 10px;">
                        <ion-icon name="cart-outline" style="font-size: 40px;"></ion-icon>
                        <p class="empty-state-text">Tu carrito está vacío</p>
                    </div>
                `;
                return;
            }

            let html = "";
            Object.values(cart).forEach(item => {
                const subtotal = item.price * item.quantity;
                html += `
                    <div class="drawer-item-row">
                        <span class="drawer-item-name">${item.name}</span>
                        <span class="drawer-item-price">S/ ${subtotal.toFixed(2)}</span>
                        <div class="quantity-selector" style="transform: scale(0.9)">
                            <button class="qty-btn" onclick="decreaseQuantity(${item.id})">-</button>
                            <span class="qty-value">${item.quantity}</span>
                            <button class="qty-btn" onclick="addToCart(${item.id})">+</button>
                        </div>
                    </div>
                `;
            });

            drawerItems.innerHTML = html;
        }

        // Abrir / Cerrar el Cajón del Carrito
        function toggleDrawer(show) {
            const drawer = document.getElementById("cartDrawer");
            const backdrop = document.getElementById("drawerBackdrop");
            
            if (show && Object.keys(cart).length > 0) {
                drawer.classList.add("visible");
                backdrop.classList.add("visible");
            } else {
                drawer.classList.remove("visible");
                backdrop.classList.remove("visible");
            }
        }

        // Filtrar productos en el catálogo
        function filtrarProductos() {
            const searchVal = document.getElementById("searchInput").value.toLowerCase();
            const cards = document.querySelectorAll(".product-card");
            
            cards.forEach(card => {
                const nombre = card.getAttribute("data-nombre").toLowerCase();
                const codigo = card.getAttribute("data-codigo").toLowerCase();
                
                if (nombre.includes(searchVal) || codigo.includes(searchVal)) {
                    card.style.display = "flex";
                } else {
                    card.style.display = "none";
                }
            });
        }

        // Construir mensaje y enviar pedido por WhatsApp
        function sendOrder() {
            if (Object.keys(cart).length === 0) return;

            let message = "*¡Hola! Me gustaría hacer el siguiente pedido:*\n\n";
            let total = 0;
            
            Object.values(cart).forEach((item, index) => {
                const subtotal = item.price * item.quantity;
                total += subtotal;
                message += `${index + 1}. *${item.name}*\n`;
                message += `   Cant: ${item.quantity}  x  S/ ${item.price.toFixed(2)}  =  *S/ ${subtotal.toFixed(2)}*\n\n`;
            });
            
            message += `--------------------------------\n`;
            message += `*Total estimado a pagar: S/ ${total.toFixed(2)}*\n\n`;
            message += `Por favor, confírmame disponibilidad y métodos de entrega/pago.`;
            
            // Codificar el mensaje para URL
            const encodedMessage = encodeURIComponent(message);
            const phone = "<?php echo $whatsappNumero; ?>";
            const url = `https://api.whatsapp.com/send?phone=${phone}&text=${encodedMessage}`;
            
            // Limpiar carrito local
            cart = {};
            updateCartUI();
            saveCart();
            
            // Redirigir a WhatsApp
            window.open(url, "_blank");
        }
    </script>
</body>
</html>
