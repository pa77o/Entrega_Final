# Proyecto Capstone: Análisis Exploratorio de Ventas en PostgreSQL

Análisis de las ventas de una tienda online de tecnología (enero a junio 2026) para responder tres preguntas de negocio: quiénes son los clientes que más aportan, cómo evolucionan las ventas mes a mes y qué productos del catálogo conviene revisar.

## Problema de negocio

La tienda creció durante el semestre, pero no tiene claro de dónde vienen sus ingresos. El equipo directivo necesita saber en qué clientes concentrar la fidelización, si el crecimiento es sostenido y qué productos no están rindiendo, para decidir campañas, compras de stock y cambios en el catálogo.

## Dataset

Base `capstone_project` con tres tablas creadas para el proyecto:

| Tabla | Registros | Descripción |
|---|---|---|
| `clientes` | 12 | Datos de contacto, ciudad y fecha de registro |
| `productos` | 12 | Nombre, categoría y precio de lista |
| `pedidos` | 60 | Cliente, producto, fecha, cantidad y precio cobrado |

El dataset incluye faltantes a propósito (fechas, precios, cantidades, categorías y ciudades) para simular datos reales.

## Limpieza de datos

El diagnóstico encontró 9 pedidos sin precio (15%), 2 sin fecha, 1 sin cantidad, 1 producto sin precio de lista y 1 sin categoría. Se creó la vista `pedidos_limpios` con estas reglas, aplicadas con `COALESCE`:

- **Precio:** si el pedido no tiene precio, se usa el precio de lista del producto. Así se recuperaron 8 de los 9 pedidos; el restante (Cable HDMI, sin precio en ningún lado) queda en 0 y marcado con `precio_faltante`.
- **Cantidad:** un pedido registrado implica al menos 1 unidad.
- **Categoría y ciudad:** se etiquetan como "Sin categoría" y "Sin dato" para que no desaparezcan de los agrupamientos.
- **Fecha:** no se inventa. Los 2 pedidos sin fecha cuentan para el gasto por cliente, pero quedan fuera del análisis mensual.

También se verificó que los tipos sean correctos (`DATE` para fechas, `NUMERIC` para montos) y que los JOINs no dupliquen filas (60 pedidos antes y después de unir las tablas).

## Hallazgos principales

**1. Los ingresos dependen de muy pocos clientes.** Sofía Torres y Diego Fernández suman $3.066 de los $6.696 facturados, casi el 46% del total, entre los 11 clientes que compraron (uno de los 12 registrados nunca hizo un pedido). Tienen perfiles distintos: Sofía compra seguido (15 pedidos, ticket promedio de $111) y Diego compra menos pero caro (7 pedidos, ticket promedio de $201). Perder a cualquiera de los dos tendría un impacto fuerte, así que son la prioridad para un programa de fidelización.

**2. Las ventas crecen, pero con altibajos.** El semestre empezó con $370 en enero y cerró con $1.746 en junio, el mejor mes, con 19 pedidos. Sin embargo, la curva alterna subas y bajas (febrero sube, marzo cae, abril sube, mayo cae), lo que sugiere un crecimiento impulsado por picos puntuales más que por una demanda estable. Conviene investigar qué pasó en febrero, abril y junio para repetirlo.

**3. Periféricos y Audio sostienen el negocio.** Entre las dos categorías generan el 68% de los ingresos. Monitores aporta el 25% con muy pocas unidades (8), porque su precio es alto. Accesorios apenas llega al 6%.

**4. Hay productos que no rinden.** El Monitor 27" 4K no tuvo ninguna venta en seis meses: a $390 es el producto más caro y probablemente no encuentra comprador. La Webcam HD vendió una sola unidad. Ambos son candidatos a una promoción o a salir del catálogo.

**5. La calidad de datos necesita atención.** Que el 15% de los pedidos no registre el precio cobrado es un problema del sistema de ventas, no solo del análisis. El Cable HDMI no tiene precio cargado en ningún lado, así que su venta figura con ingreso 0. Se recomienda que precio y fecha sean obligatorios en el sistema.

## Recomendaciones

- Lanzar un programa de beneficios para los clientes de mayor gasto, empezando por los dos que concentran casi la mitad de los ingresos.
- Analizar las acciones comerciales de los meses pico para convertirlas en campañas recurrentes.
- Probar una promoción sobre el Monitor 27" 4K y la Webcam HD antes de decidir si se discontinúan.
- Cargar el precio del Cable HDMI y exigir precio y fecha en cada pedido.

## Estructura del repositorio

| Archivo | Contenido |
|---|---|
| `estructura.sql` | Creación de la base y las tablas, y carga de datos |
| `analisis.sql` | Validación, limpieza (vista `pedidos_limpios`) y 5 consultas de análisis comentadas |
| `README.md` | Este documento |

## Cómo ejecutarlo

1. Abrí pgAdmin conectado a la base `postgres` y ejecutá solo la línea `CREATE DATABASE capstone_project;` de `estructura.sql`.
2. Hacé clic derecho en `capstone_project` → **Query Tool**, abrí `estructura.sql` y ejecutá el resto del archivo (desde `CREATE TABLE clientes`).
3. En la misma conexión, abrí `analisis.sql` y ejecutá cada bloque por separado para ver sus resultados. La vista `pedidos_limpios` tiene que crearse antes de correr las consultas de la etapa 2.

Probado en PostgreSQL 16.
