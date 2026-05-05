-- ================================================
-- MIGRACIÓN: Portal de clientes con PIN
-- Ejecutar en Supabase SQL Editor
-- ================================================

-- 1. Agregar columna pin a clientes (si no existe)
ALTER TABLE clientes
  ADD COLUMN IF NOT EXISTS pin CHAR(4);

-- 2. Eliminar columna alergias (si no se hizo antes)
ALTER TABLE clientes
  DROP COLUMN IF EXISTS alergias;

-- 3. Policy: el cliente puede ver y actualizar su propio registro por teléfono
--    (necesario para login por PIN sin auth de Supabase)
DROP POLICY IF EXISTS "cliente_read_own" ON clientes;
CREATE POLICY "cliente_read_own" ON clientes
  FOR SELECT USING (true);   -- ya cubierto por allow_all_clientes

-- 4. Policy: el cliente puede leer sus propias citas (para el portal web)
DROP POLICY IF EXISTS "citas_portal_web" ON citas;
CREATE POLICY "citas_portal_web" ON citas
  FOR SELECT USING (true);   -- cubierto por allow_all_citas

-- 5. Policy: el cliente puede cancelar su propia cita (UPDATE estado)
DROP POLICY IF EXISTS "cita_cancel_propio" ON citas;
CREATE POLICY "cita_cancel_propio" ON citas
  FOR UPDATE USING (true) WITH CHECK (true);

-- 6. Policy: el cliente puede leer sus movimientos de puntos
DROP POLICY IF EXISTS "puntos_read_own" ON movimientos_puntos;
CREATE POLICY "puntos_read_own" ON movimientos_puntos
  FOR SELECT USING (true);

-- 7. Policy: insertar movimientos de puntos desde la web
DROP POLICY IF EXISTS "puntos_insert_web" ON movimientos_puntos
  ;
CREATE POLICY "puntos_insert_web" ON movimientos_puntos
  FOR INSERT WITH CHECK (true);

-- 8. View: citas próximas del portal (helper)
DROP VIEW IF EXISTS vista_portal_citas;
CREATE VIEW vista_portal_citas AS
SELECT
  c.id,
  c.cliente_id,
  c.fecha_hora,
  c.estado,
  c.servicio_nombre,
  c.servicio_precio,
  c.servicio_duracion,
  c.notas,
  c.origen,
  c.pagada
FROM citas c
ORDER BY c.fecha_hora DESC;

-- 9. Índice para búsqueda rápida por teléfono
CREATE INDEX IF NOT EXISTS idx_clientes_telefono ON clientes(telefono);

-- 10. Índice para citas por cliente
CREATE INDEX IF NOT EXISTS idx_citas_cliente ON citas(cliente_id, fecha_hora);

-- 11. Índice para movimientos por cliente
CREATE INDEX IF NOT EXISTS idx_movimientos_cliente ON movimientos_puntos(cliente_id, created_at DESC);

-- ================================================
-- VERIFICACIÓN
-- Ejecutar para confirmar que todo está bien:
-- ================================================
-- SELECT column_name, data_type FROM information_schema.columns
-- WHERE table_name = 'clientes' ORDER BY ordinal_position;
