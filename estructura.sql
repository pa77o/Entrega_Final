-- =====================================================================
-- Proyecto Capstone: Análisis Exploratorio de Datos en PostgreSQL
-- Archivo: estructura.sql
-- Contenido: creación de la base, de las tablas y carga del dataset.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Base de datos
-- Ejecutar esta línea conectado a cualquier base (por ejemplo postgres)
-- y después cambiar la conexión a capstone_project para el resto.
-- ---------------------------------------------------------------------
CREATE DATABASE capstone_project;

-- ---------------------------------------------------------------------
-- 2. Tablas
-- Se usa DATE para fechas y NUMERIC(10,2) para montos, porque los
-- importes necesitan precisión exacta (FLOAT puede generar redondeos).
-- Algunas columnas críticas quedan NULL-ables a propósito: el dataset
-- simula datos reales con faltantes que se tratan en la etapa de limpieza.
-- ---------------------------------------------------------------------

CREATE TABLE clientes (
    cliente_id     SERIAL PRIMARY KEY,
    nombre         VARCHAR(150) NOT NULL,
    email          VARCHAR(150) UNIQUE NOT NULL,
    ciudad         VARCHAR(100),
    fecha_registro DATE NOT NULL
);

CREATE TABLE productos (
    producto_id     SERIAL PRIMARY KEY,
    nombre_producto VARCHAR(150) NOT NULL,
    categoria       VARCHAR(100),
    precio          NUMERIC(10,2) CHECK (precio > 0)
);

-- pedidos depende de clientes y productos, por eso se crea al final
CREATE TABLE pedidos (
    pedido_id       SERIAL PRIMARY KEY,
    cliente_id      INT NOT NULL REFERENCES clientes(cliente_id),
    producto_id     INT NOT NULL REFERENCES productos(producto_id),
    fecha_pedido    DATE,
    cantidad        INT CHECK (cantidad > 0),
    precio_unitario NUMERIC(10,2) CHECK (precio_unitario > 0)
);

-- ---------------------------------------------------------------------
-- 3. Carga de datos (transacción: si falla un INSERT no queda nada a medias)
-- Período: enero a junio 2026. 12 clientes, 12 productos, 60 pedidos.
-- ---------------------------------------------------------------------
BEGIN;

INSERT INTO clientes (nombre, email, ciudad, fecha_registro) VALUES
('Ana García', 'ana.garcia@mail.com', 'Buenos Aires', '2025-03-12'),
('Luis Pérez', 'luis.perez@mail.com', 'Córdoba', '2025-05-02'),
('María López', 'maria.lopez@mail.com', 'Rosario', '2025-06-18'),
('Carlos Ruiz', 'carlos.ruiz@mail.com', 'Buenos Aires', '2025-07-01'),
('Sofía Torres', 'sofia.torres@mail.com', 'Mendoza', '2025-08-22'),
('Diego Fernández', 'diego.fernandez@mail.com', 'Buenos Aires', '2025-09-10'),
('Lucía Romero', 'lucia.romero@mail.com', 'La Plata', '2025-10-05'),
('Martín Gómez', 'martin.gomez@mail.com', 'Córdoba', '2025-11-14'),
('Valentina Díaz', 'valentina.diaz@mail.com', NULL, '2025-12-01'),
('Joaquín Álvarez', 'joaquin.alvarez@mail.com', 'Rosario', '2026-01-08'),
('Camila Sosa', 'camila.sosa@mail.com', 'Mendoza', '2026-02-15'),
('Tomás Herrera', 'tomas.herrera@mail.com', NULL, '2026-03-03');

INSERT INTO productos (nombre_producto, categoria, precio) VALUES
('Teclado Mecánico', 'Periféricos', 95.00),
('Mouse Gaming', 'Periféricos', 45.00),
('Alfombrilla XL', 'Periféricos', 15.00),
('Monitor 24"', 'Monitores', 210.00),
('Monitor 27" 4K', 'Monitores', 390.00),
('Auriculares Bluetooth', 'Audio', 65.00),
('Parlante Portátil', 'Audio', 55.00),
('Micrófono USB', 'Audio', 80.00),
('Webcam HD', 'Accesorios', 50.00),
('Hub USB-C', 'Accesorios', 35.00),
('Soporte para Notebook', NULL, 28.00),
('Cable HDMI 2m', 'Accesorios', NULL);

INSERT INTO pedidos (cliente_id, producto_id, fecha_pedido, cantidad, precio_unitario) VALUES
(3, 1, '2026-06-02', 1, 95.00),
(1, 6, '2026-06-07', 1, NULL),
(5, 2, '2026-06-14', 1, 45.00),
(1, 2, '2026-06-19', 1, 45.00),
(5, 12, '2026-01-18', 1, NULL),
(2, 1, '2026-04-18', 3, 95.00),
(6, 6, '2026-04-04', 2, 65.00),
(6, 6, '2026-05-22', 2, 65.00),
(3, 6, '2026-05-12', 1, 65.00),
(2, 8, '2026-02-19', 1, 80.00),
(10, 7, '2026-04-20', 1, NULL),
(5, 7, '2026-03-16', 2, NULL),
(7, 7, '2026-06-26', 1, 55.00),
(4, 4, NULL, 1, 210.00),
(5, 6, '2026-01-24', 3, 65.00),
(6, 6, '2026-05-10', 3, 65.00),
(7, 1, '2026-05-12', 1, 95.00),
(5, 2, '2026-04-05', 3, 45.00),
(5, 10, '2026-02-06', 2, 35.00),
(3, 1, '2026-05-28', 2, 95.00),
(5, 3, '2026-05-08', 1, NULL),
(2, 6, '2026-01-16', 2, 65.00),
(3, 1, '2026-06-12', NULL, 95.00),
(11, 6, '2026-06-20', 3, 65.00),
(1, 10, '2026-06-26', 2, 35.00),
(5, 1, '2026-06-13', 1, 95.00),
(12, 3, '2026-02-11', 2, NULL),
(1, 1, '2026-02-12', 2, NULL),
(10, 6, '2026-03-21', 1, 65.00),
(6, 4, '2026-02-28', 2, 210.00),
(5, 4, '2026-02-05', 1, 210.00),
(8, 4, '2026-03-17', 1, 210.00),
(11, 3, '2026-06-01', 2, 15.00),
(7, 1, '2026-04-17', 1, 95.00),
(4, 2, '2026-06-25', 2, 45.00),
(3, 9, '2026-03-26', 1, 50.00),
(8, 2, '2026-06-16', 1, 45.00),
(12, 8, '2026-05-09', 1, 80.00),
(11, 3, '2026-04-12', 1, 15.00),
(3, 2, '2026-03-16', 2, 45.00),
(6, 1, '2026-06-12', 3, NULL),
(7, 10, NULL, 1, 35.00),
(6, 1, '2026-05-15', 2, 95.00),
(1, 2, '2026-03-01', 1, 45.00),
(5, 6, '2026-06-27', 2, 65.00),
(7, 3, '2026-06-18', 1, NULL),
(8, 7, '2026-02-17', 3, 55.00),
(5, 10, '2026-03-01', 1, 35.00),
(5, 7, '2026-04-09', 2, 55.00),
(1, 10, '2026-04-15', 3, 35.00),
(10, 3, '2026-06-05', 2, 15.00),
(5, 10, '2026-03-20', 1, 35.00),
(2, 1, '2026-06-24', 1, 95.00),
(3, 4, '2026-06-16', 1, 210.00),
(1, 2, '2026-01-25', 1, 45.00),
(6, 7, '2026-02-15', 1, 55.00),
(5, 4, '2026-04-15', 2, 210.00),
(5, 11, '2026-06-09', 2, 28.00),
(2, 3, '2026-05-04', 2, 15.00),
(1, 2, '2026-02-07', 3, 45.00);

COMMIT;
