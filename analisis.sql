-- =====================================================================
-- Proyecto Capstone: Análisis Exploratorio de Datos en PostgreSQL
-- Archivo: analisis.sql
-- Ejecutar conectado a la base capstone_project, después de estructura.sql.
-- Pregunta de negocio: ¿quiénes son nuestros mejores clientes, cómo
-- evolucionan las ventas y qué productos conviene revisar del catálogo?
-- =====================================================================


-- =====================================================================
-- ETAPA 1: VALIDACIÓN Y LIMPIEZA
-- =====================================================================

-- 1.1 Verificación de tipos de datos
-- Antes de analizar confirmamos que las fechas sean DATE y los montos
-- NUMERIC; si un importe estuviera guardado como texto, SUM fallaría o
-- ordenaría mal.
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND column_name IN ('fecha_pedido', 'fecha_registro', 'precio', 'precio_unitario', 'cantidad')
ORDER BY table_name, column_name;

-- 1.2 Diagnóstico de nulos en columnas críticas
-- Medimos cuántos faltantes hay para decidir cómo tratarlos, en lugar de
-- descubrirlos después como resultados sesgados. COUNT(*) - COUNT(col)
-- da exactamente la cantidad de NULL de cada columna.
SELECT
    COUNT(*)                          AS total_pedidos,
    COUNT(*) - COUNT(fecha_pedido)    AS pedidos_sin_fecha,
    COUNT(*) - COUNT(cantidad)        AS pedidos_sin_cantidad,
    COUNT(*) - COUNT(precio_unitario) AS pedidos_sin_precio
FROM pedidos;

SELECT
    COUNT(*) - COUNT(precio)    AS productos_sin_precio,
    COUNT(*) - COUNT(categoria) AS productos_sin_categoria
FROM productos;

-- 1.3 Control de explosión de filas
-- La cantidad de filas después del JOIN debe ser igual a la de pedidos
-- (60). Si fuera mayor, habría duplicados en productos o clientes.
SELECT COUNT(*) AS filas_despues_del_join
FROM pedidos pe
JOIN productos pr ON pr.producto_id = pe.producto_id
JOIN clientes  c  ON c.cliente_id   = pe.cliente_id;

-- 1.4 Vista de pedidos limpios
-- Reglas de negocio para los faltantes:
--   * precio: si el pedido no registró precio, usamos el precio de lista
--     del producto; si tampoco existe, queda en 0 y se marca con
--     precio_faltante para no confundirlo con una venta gratuita.
--   * cantidad: un pedido registrado implica al menos 1 unidad.
--   * categoría y ciudad: se etiquetan como 'Sin categoría' / 'Sin dato'
--     para que no desaparezcan de los agrupamientos.
--   * fecha: no se inventa; los pedidos sin fecha cuentan para el gasto
--     por cliente pero se excluyen del análisis mensual.
CREATE OR REPLACE VIEW pedidos_limpios AS
SELECT
    pe.pedido_id,
    pe.fecha_pedido,
    c.cliente_id,
    c.nombre                                          AS cliente,
    COALESCE(c.ciudad, 'Sin dato')                    AS ciudad,
    pr.producto_id,
    pr.nombre_producto,
    COALESCE(pr.categoria, 'Sin categoría')           AS categoria,
    COALESCE(pe.cantidad, 1)                          AS cantidad,
    COALESCE(pe.precio_unitario, pr.precio, 0)        AS precio_final,
    COALESCE(pe.cantidad, 1)
        * COALESCE(pe.precio_unitario, pr.precio, 0)  AS monto,
    (pe.precio_unitario IS NULL AND pr.precio IS NULL) AS precio_faltante
FROM pedidos pe
JOIN clientes  c  ON c.cliente_id   = pe.cliente_id
JOIN productos pr ON pr.producto_id = pe.producto_id;

-- Comprobación: después de la limpieza no deberían quedar NULL en las
-- columnas que usan los cálculos.
SELECT
    COUNT(*) - COUNT(cantidad)     AS cantidad_nula,
    COUNT(*) - COUNT(precio_final) AS precio_nulo,
    SUM(CASE WHEN precio_faltante THEN 1 ELSE 0 END) AS pedidos_sin_precio_recuperable
FROM pedidos_limpios;


-- =====================================================================
-- ETAPA 2: ANÁLISIS
-- =====================================================================

-- 2.1 Top 5 clientes por gasto total
-- Identifica el segmento que más ingresos aporta, candidato a un
-- programa de fidelización. Se incluye la cantidad de pedidos para
-- distinguir si gastan mucho por frecuencia o por ticket alto.
SELECT
    cliente,
    ciudad,
    COUNT(*)             AS cantidad_pedidos,
    SUM(monto)           AS gasto_total,
    ROUND(AVG(monto), 2) AS ticket_promedio
FROM pedidos_limpios
GROUP BY cliente_id, cliente, ciudad
ORDER BY gasto_total DESC
LIMIT 5;

-- 2.2 Ventas totales por mes
-- Muestra la tendencia del semestre para planificar stock y campañas.
-- Se excluyen los pedidos sin fecha porque no se pueden asignar a un mes.
-- La variación contra el mes anterior (LAG) indica si el crecimiento
-- es sostenido o puntual.
SELECT
    TO_CHAR(DATE_TRUNC('month', fecha_pedido), 'YYYY-MM') AS mes,
    COUNT(*)                                              AS pedidos,
    SUM(monto)                                            AS ventas_totales,
    SUM(monto) - LAG(SUM(monto)) OVER (ORDER BY DATE_TRUNC('month', fecha_pedido))
                                                          AS variacion_vs_mes_anterior
FROM pedidos_limpios
WHERE fecha_pedido IS NOT NULL
GROUP BY DATE_TRUNC('month', fecha_pedido)
ORDER BY mes;

-- 2.3 Los 3 productos menos vendidos
-- Detecta productos candidatos a promoción o a salir del catálogo.
-- Se parte de productos con LEFT JOIN para que un producto que nunca se
-- vendió aparezca con 0 unidades en lugar de quedar fuera del reporte.
SELECT
    pr.nombre_producto,
    COALESCE(pr.categoria, 'Sin categoría') AS categoria,
    COALESCE(SUM(pl.cantidad), 0)           AS unidades_vendidas,
    COALESCE(SUM(pl.monto), 0)              AS ingresos
FROM productos pr
LEFT JOIN pedidos_limpios pl ON pl.producto_id = pr.producto_id
GROUP BY pr.producto_id, pr.nombre_producto, pr.categoria
ORDER BY unidades_vendidas ASC, ingresos ASC
LIMIT 3;

-- 2.4 Ranking de pedidos por categoría
-- Ordena los pedidos de cada categoría por monto para ver cuáles son los
-- de mayor valor dentro de su rubro. Se muestran solo los 3 primeros de
-- cada categoría, y el CASE clasifica el pedido según su peso dentro de
-- la categoría para detectar compras excepcionales.
WITH ranking AS (
    SELECT
        categoria,
        pedido_id,
        cliente,
        nombre_producto,
        monto,
        RANK() OVER (PARTITION BY categoria ORDER BY monto DESC) AS posicion,
        AVG(monto) OVER (PARTITION BY categoria)                 AS promedio_categoria
    FROM pedidos_limpios
    WHERE NOT precio_faltante
)
SELECT
    categoria,
    posicion,
    pedido_id,
    cliente,
    nombre_producto,
    monto,
    CASE
        WHEN monto >= 2 * promedio_categoria THEN 'Pedido excepcional'
        WHEN monto >= promedio_categoria     THEN 'Sobre el promedio'
        ELSE 'Bajo el promedio'
    END AS clasificacion
FROM ranking
WHERE posicion <= 3
ORDER BY categoria, posicion;

-- 2.5 Participación de cada categoría en los ingresos
-- Complementa el ranking: muestra qué rubros sostienen el negocio.
-- El porcentaje se calcula con una función de ventana sobre el total.
SELECT
    categoria,
    SUM(cantidad) AS unidades,
    SUM(monto)    AS ingresos,
    ROUND(100.0 * SUM(monto) / SUM(SUM(monto)) OVER (), 1) AS porcentaje_ingresos
FROM pedidos_limpios
GROUP BY categoria
ORDER BY ingresos DESC;
