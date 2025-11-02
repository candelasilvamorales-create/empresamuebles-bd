-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 03-11-2025 a las 00:28:06
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
-- Base de datos: `empresamuebles`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `insertar_pedido` (IN `proveedor_id` INT, IN `fecha_pedido` DATE, IN `id_producto_1` INT, IN `cantidad_1` INT, IN `id_producto_2` INT, IN `cantidad_2` INT)   BEGIN
    DECLARE pedido_id INT;

    INSERT INTO Pedidos (id_proveedor, fecha, monto)
    VALUES (proveedor_id, fecha_pedido, 0);

    SET pedido_id = LAST_INSERT_ID();

    INSERT INTO Detalle_pedidos (id_pedido, id_producto, cantidad)
    VALUES (pedido_id, id_producto_1, cantidad_1);

    INSERT INTO Detalle_pedidos (id_pedido, id_producto, cantidad)
    VALUES (pedido_id, id_producto_2, cantidad_2);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `insertar_venta` (IN `cliente_id` INT, IN `fecha_venta` DATE, IN `id_producto_1` INT, IN `cantidad_1` INT, IN `id_producto_2` INT, IN `cantidad_2` INT)   BEGIN
    DECLARE venta_id INT;

    INSERT INTO Ventas (id_cliente, fecha, monto)
    VALUES (cliente_id, fecha_venta, 0);

    SET venta_id = LAST_INSERT_ID();

    INSERT INTO Detalle_ventas (id_venta, id_producto, cantidad)
    VALUES (venta_id, id_producto_1, cantidad_1);

    INSERT INTO Detalle_ventas (id_venta, id_producto, cantidad)
    VALUES (venta_id, id_producto_2, cantidad_2);
END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `calcular_valor_stock_producto` (`producto_id` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE valor_stock DECIMAL(10, 2);

    SELECT (pr.stock * pr.precio_compra)
    INTO valor_stock
    FROM Productos pr
    WHERE pr.id_producto = producto_id;

    IF valor_stock IS NULL THEN
        SET valor_stock = 0;
    END IF;

    RETURN valor_stock;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `calcular_ventas_producto` (`producto_id` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE total_ventas DECIMAL(10, 2);

    SELECT SUM(dv.cantidad * pr.precio_venta)
    INTO total_ventas
    FROM Detalle_ventas dv
    JOIN Productos pr ON dv.id_producto = pr.id_producto
    WHERE pr.id_producto = producto_id;

    IF total_ventas IS NULL THEN
        SET total_ventas = 0;
    END IF;

    RETURN total_ventas;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `id_cliente` int(11) NOT NULL,
  `tipo_cliente` enum('mayorista','minorista') NOT NULL,
  `razon_social` varchar(255) NOT NULL,
  `cuit` varchar(50) NOT NULL,
  `pais` varchar(100) DEFAULT NULL,
  `provincia` varchar(100) DEFAULT NULL,
  `direccion` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `clientes`
--

INSERT INTO `clientes` (`id_cliente`, `tipo_cliente`, `razon_social`, `cuit`, `pais`, `provincia`, `direccion`) VALUES
(1, 'mayorista', 'Casa Deco SA', '30-10000000-1', 'Argentina', 'Buenos Aires', 'Av. Santa Fe 1200'),
(2, 'minorista', 'Lucía Fernández', '27-20000000-2', 'Argentina', 'Córdoba', 'Bv. San Juan 955'),
(3, 'minorista', 'Tomás Pereyra', '20-30000000-3', 'Argentina', 'Santa Fe', 'San Martín 1800');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_pedidos`
--

CREATE TABLE `detalle_pedidos` (
  `id_pedido` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalle_pedidos`
--

INSERT INTO `detalle_pedidos` (`id_pedido`, `id_producto`, `cantidad`) VALUES
(1, 1, 12),
(1, 3, 5),
(2, 2, 10),
(2, 6, 6);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_ventas`
--

CREATE TABLE `detalle_ventas` (
  `id_venta` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalle_ventas`
--

INSERT INTO `detalle_ventas` (`id_venta`, `id_producto`, `cantidad`) VALUES
(1, 1, 4),
(1, 3, 1),
(2, 2, 2),
(2, 6, 1),
(3, 1, 2),
(3, 5, 1);

--
-- Disparadores `detalle_ventas`
--
DELIMITER $$
CREATE TRIGGER `after_detalle_ventas_insert` AFTER INSERT ON `detalle_ventas` FOR EACH ROW BEGIN
    DECLARE total DECIMAL(10, 2);

    SELECT SUM(dv.cantidad * pr.precio_venta)
    INTO total
    FROM Detalle_ventas dv
    JOIN Productos pr ON dv.id_producto = pr.id_producto
    WHERE dv.id_venta = NEW.id_venta;

    UPDATE Ventas
    SET monto = total
    WHERE id_venta = NEW.id_venta;

    UPDATE Productos
    SET stock = stock - NEW.cantidad
    WHERE id_producto = NEW.id_producto;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_detalle_ventas_update` AFTER UPDATE ON `detalle_ventas` FOR EACH ROW BEGIN
    DECLARE total DECIMAL(10, 2);
    
    SELECT SUM(dv.cantidad * pr.precio_venta)
    INTO total
    FROM Detalle_ventas dv
    JOIN Productos pr ON dv.id_producto = pr.id_producto
    WHERE dv.id_venta = NEW.id_venta;

    UPDATE Ventas
    SET monto = total
    WHERE id_venta = NEW.id_venta;

    UPDATE Productos
    SET stock = stock - NEW.cantidad
    WHERE id_producto = NEW.id_producto;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pedidos`
--

CREATE TABLE `pedidos` (
  `id_pedido` int(11) NOT NULL,
  `id_proveedor` int(11) DEFAULT NULL,
  `fecha` date NOT NULL,
  `monto` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `pedidos`
--

INSERT INTO `pedidos` (`id_pedido`, `id_proveedor`, `fecha`, `monto`) VALUES
(1, 1, '2025-10-10', 0.00),
(2, 2, '2025-10-12', 0.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id_producto` int(11) NOT NULL,
  `tipo` varchar(50) NOT NULL,
  `modelo` varchar(100) NOT NULL,
  `color` varchar(50) DEFAULT NULL,
  `medida` varchar(50) DEFAULT NULL,
  `precio_compra` decimal(10,2) NOT NULL,
  `precio_venta` decimal(10,2) NOT NULL,
  `stock` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id_producto`, `tipo`, `modelo`, `color`, `medida`, `precio_compra`, `precio_venta`, `stock`) VALUES
(1, 'Silla', 'Nordic', 'Blanco', '45x45x90', 15000.00, 24990.00, 54),
(2, 'Silla', 'Industrial', 'Negro', '45x45x90', 17000.00, 27990.00, 43),
(3, 'Mesa', 'Roble', 'Roble', '140x80x75', 40000.00, 65990.00, 19),
(4, 'Mesa', 'Minimal', 'Gris', '120x70x75', 35000.00, 59990.00, 25),
(5, 'Sillón', 'Urban', 'Gris', '200x90x85', 80000.00, 129990.00, 9),
(6, 'Escritorio', 'Studio', 'Roble', '120x60x75', 30000.00, 49990.00, 29);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores`
--

CREATE TABLE `proveedores` (
  `id_proveedor` int(11) NOT NULL,
  `tipo_proveedor` enum('nacional','internacional') NOT NULL,
  `razon_social` varchar(255) NOT NULL,
  `cuit` varchar(50) NOT NULL,
  `pais` varchar(100) DEFAULT NULL,
  `provincia` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `proveedores`
--

INSERT INTO `proveedores` (`id_proveedor`, `tipo_proveedor`, `razon_social`, `cuit`, `pais`, `provincia`) VALUES
(1, 'nacional', 'Maderas Andinas SRL', '30-40000000-4', 'Argentina', 'Mendoza'),
(2, 'internacional', 'GlobalFurni LTD', '90-50000000-5', 'Brasil', 'Sao Paulo'),
(3, 'nacional', 'Herrajes del Sur SA', '30-60000000-6', 'Argentina', 'Buenos Aires');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ventas`
--

CREATE TABLE `ventas` (
  `id_venta` int(11) NOT NULL,
  `id_cliente` int(11) DEFAULT NULL,
  `fecha` date NOT NULL,
  `monto` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `ventas`
--

INSERT INTO `ventas` (`id_venta`, `id_cliente`, `fecha`, `monto`) VALUES
(1, 1, '2025-10-15', 165950.00),
(2, 2, '2025-10-16', 105970.00),
(3, 3, '2025-10-18', 179970.00);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_detalles_pedidos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_detalles_pedidos` (
`id_pedido` int(11)
,`fecha_pedido` date
,`monto_pedido` decimal(10,2)
,`id_producto` int(11)
,`cantidad` int(11)
,`precio_compra` decimal(10,2)
,`costo_total` decimal(20,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_detalles_ventas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_detalles_ventas` (
`id_venta` int(11)
,`fecha_venta` date
,`monto_venta` decimal(10,2)
,`id_cliente` int(11)
,`cliente_razon_social` varchar(255)
,`id_producto` int(11)
,`cantidad` int(11)
,`precio_venta` decimal(10,2)
,`total_producto` decimal(20,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_historial_pedidos_proveedor`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_historial_pedidos_proveedor` (
`id_proveedor` int(11)
,`proveedor_razon_social` varchar(255)
,`proveedor_pais` varchar(100)
,`id_pedido` int(11)
,`fecha_pedido` date
,`monto_pedido` decimal(10,2)
,`id_producto` int(11)
,`cantidad` int(11)
,`total_producto` decimal(20,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_historial_ventas_cliente`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_historial_ventas_cliente` (
`id_cliente` int(11)
,`cliente_razon_social` varchar(255)
,`tipo_cliente` enum('mayorista','minorista')
,`id_venta` int(11)
,`fecha_venta` date
,`monto_venta` decimal(10,2)
,`id_producto` int(11)
,`cantidad` int(11)
,`total_producto` decimal(20,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_productos_mas_vendidos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_productos_mas_vendidos` (
`id_producto` int(11)
,`total_vendido` decimal(32,0)
,`total_ventas` decimal(42,2)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_detalles_pedidos`
--
DROP TABLE IF EXISTS `vista_detalles_pedidos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_detalles_pedidos`  AS SELECT `pe`.`id_pedido` AS `id_pedido`, `pe`.`fecha` AS `fecha_pedido`, `pe`.`monto` AS `monto_pedido`, `dp`.`id_producto` AS `id_producto`, `dp`.`cantidad` AS `cantidad`, `pr`.`precio_compra` AS `precio_compra`, `dp`.`cantidad`* `pr`.`precio_compra` AS `costo_total` FROM ((`pedidos` `pe` join `detalle_pedidos` `dp` on(`pe`.`id_pedido` = `dp`.`id_pedido`)) join `productos` `pr` on(`dp`.`id_producto` = `pr`.`id_producto`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_detalles_ventas`
--
DROP TABLE IF EXISTS `vista_detalles_ventas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_detalles_ventas`  AS SELECT `ve`.`id_venta` AS `id_venta`, `ve`.`fecha` AS `fecha_venta`, `ve`.`monto` AS `monto_venta`, `cl`.`id_cliente` AS `id_cliente`, `cl`.`razon_social` AS `cliente_razon_social`, `dv`.`id_producto` AS `id_producto`, `dv`.`cantidad` AS `cantidad`, `pr`.`precio_venta` AS `precio_venta`, `dv`.`cantidad`* `pr`.`precio_venta` AS `total_producto` FROM (((`ventas` `ve` join `clientes` `cl` on(`ve`.`id_cliente` = `cl`.`id_cliente`)) join `detalle_ventas` `dv` on(`ve`.`id_venta` = `dv`.`id_venta`)) join `productos` `pr` on(`dv`.`id_producto` = `pr`.`id_producto`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_historial_pedidos_proveedor`
--
DROP TABLE IF EXISTS `vista_historial_pedidos_proveedor`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_historial_pedidos_proveedor`  AS SELECT `pv`.`id_proveedor` AS `id_proveedor`, `pv`.`razon_social` AS `proveedor_razon_social`, `pv`.`pais` AS `proveedor_pais`, `pe`.`id_pedido` AS `id_pedido`, `pe`.`fecha` AS `fecha_pedido`, `pe`.`monto` AS `monto_pedido`, `dp`.`id_producto` AS `id_producto`, `dp`.`cantidad` AS `cantidad`, `dp`.`cantidad`* `pr`.`precio_compra` AS `total_producto` FROM (((`proveedores` `pv` join `pedidos` `pe` on(`pv`.`id_proveedor` = `pe`.`id_proveedor`)) join `detalle_pedidos` `dp` on(`pe`.`id_pedido` = `dp`.`id_pedido`)) join `productos` `pr` on(`dp`.`id_producto` = `pr`.`id_producto`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_historial_ventas_cliente`
--
DROP TABLE IF EXISTS `vista_historial_ventas_cliente`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_historial_ventas_cliente`  AS SELECT `cl`.`id_cliente` AS `id_cliente`, `cl`.`razon_social` AS `cliente_razon_social`, `cl`.`tipo_cliente` AS `tipo_cliente`, `ve`.`id_venta` AS `id_venta`, `ve`.`fecha` AS `fecha_venta`, `ve`.`monto` AS `monto_venta`, `dv`.`id_producto` AS `id_producto`, `dv`.`cantidad` AS `cantidad`, `dv`.`cantidad`* `pr`.`precio_venta` AS `total_producto` FROM (((`clientes` `cl` join `ventas` `ve` on(`cl`.`id_cliente` = `ve`.`id_cliente`)) join `detalle_ventas` `dv` on(`ve`.`id_venta` = `dv`.`id_venta`)) join `productos` `pr` on(`dv`.`id_producto` = `pr`.`id_producto`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_productos_mas_vendidos`
--
DROP TABLE IF EXISTS `vista_productos_mas_vendidos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_productos_mas_vendidos`  AS SELECT `pr`.`id_producto` AS `id_producto`, sum(`dv`.`cantidad`) AS `total_vendido`, sum(`dv`.`cantidad` * `pr`.`precio_venta`) AS `total_ventas` FROM (`productos` `pr` join `detalle_ventas` `dv` on(`pr`.`id_producto` = `dv`.`id_producto`)) GROUP BY `pr`.`id_producto` ORDER BY sum(`dv`.`cantidad`) DESC ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id_cliente`),
  ADD UNIQUE KEY `cuit` (`cuit`);

--
-- Indices de la tabla `detalle_pedidos`
--
ALTER TABLE `detalle_pedidos`
  ADD PRIMARY KEY (`id_pedido`,`id_producto`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `detalle_ventas`
--
ALTER TABLE `detalle_ventas`
  ADD PRIMARY KEY (`id_venta`,`id_producto`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD PRIMARY KEY (`id_pedido`),
  ADD KEY `id_proveedor` (`id_proveedor`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id_producto`);

--
-- Indices de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD PRIMARY KEY (`id_proveedor`),
  ADD UNIQUE KEY `cuit` (`cuit`);

--
-- Indices de la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD PRIMARY KEY (`id_venta`),
  ADD KEY `id_cliente` (`id_cliente`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `clientes`
--
ALTER TABLE `clientes`
  MODIFY `id_cliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  MODIFY `id_pedido` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id_producto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  MODIFY `id_proveedor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `ventas`
--
ALTER TABLE `ventas`
  MODIFY `id_venta` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `detalle_pedidos`
--
ALTER TABLE `detalle_pedidos`
  ADD CONSTRAINT `detalle_pedidos_ibfk_1` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`),
  ADD CONSTRAINT `detalle_pedidos_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`);

--
-- Filtros para la tabla `detalle_ventas`
--
ALTER TABLE `detalle_ventas`
  ADD CONSTRAINT `detalle_ventas_ibfk_1` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`),
  ADD CONSTRAINT `detalle_ventas_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`);

--
-- Filtros para la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD CONSTRAINT `pedidos_ibfk_1` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedores` (`id_proveedor`);

--
-- Filtros para la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD CONSTRAINT `ventas_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
