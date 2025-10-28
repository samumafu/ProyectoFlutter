-- =====================================================
-- POLÍTICAS DE ROW LEVEL SECURITY (RLS)
-- Sistema de Transporte Intermunicipal - Nariño
-- =====================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE empresas_transportadoras ENABLE ROW LEVEL SECURITY;
ALTER TABLE conductores ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehiculos ENABLE ROW LEVEL SECURITY;
ALTER TABLE rutas ENABLE ROW LEVEL SECURITY;
ALTER TABLE viajes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservas ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos ENABLE ROW LEVEL SECURITY;
ALTER TABLE calificaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE notificaciones ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLÍTICAS PARA TABLA USUARIOS
-- =====================================================

-- Los usuarios pueden ver y editar su propio perfil
CREATE POLICY "usuarios_own_profile" ON usuarios
    FOR ALL USING (auth.uid()::text = id::text);

-- Los admins pueden ver todos los usuarios
CREATE POLICY "admin_view_all_users" ON usuarios
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE id::text = auth.uid()::text 
            AND rol = 'admin'
        )
    );

-- =====================================================
-- POLÍTICAS PARA EMPRESAS TRANSPORTADORAS
-- =====================================================

-- Las empresas pueden ver y editar su propia información
CREATE POLICY "empresas_own_data" ON empresas_transportadoras
    FOR ALL USING (usuario_id::text = auth.uid()::text);

-- Los conductores pueden ver información de su empresa
CREATE POLICY "conductores_view_empresa" ON empresas_transportadoras
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM conductores c
            WHERE c.empresa_id = empresas_transportadoras.id
            AND c.usuario_id::text = auth.uid()::text
        )
    );

-- Los usuarios pueden ver empresas verificadas (para búsquedas)
CREATE POLICY "usuarios_view_empresas_verificadas" ON empresas_transportadoras
    FOR SELECT USING (estado = 'verificado');

-- Los admins pueden ver y editar todas las empresas
CREATE POLICY "admin_manage_empresas" ON empresas_transportadoras
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE id::text = auth.uid()::text 
            AND rol = 'admin'
        )
    );

-- =====================================================
-- POLÍTICAS PARA CONDUCTORES
-- =====================================================

-- Los conductores pueden ver y editar su propia información
CREATE POLICY "conductores_own_data" ON conductores
    FOR ALL USING (usuario_id::text = auth.uid()::text);

-- Las empresas pueden ver y gestionar sus conductores
CREATE POLICY "empresas_manage_conductores" ON conductores
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM empresas_transportadoras e
            WHERE e.id = conductores.empresa_id
            AND e.usuario_id::text = auth.uid()::text
        )
    );

-- Los usuarios pueden ver conductores verificados (para calificaciones)
CREATE POLICY "usuarios_view_conductores_verificados" ON conductores
    FOR SELECT USING (verificado = true);

-- =====================================================
-- POLÍTICAS PARA VEHÍCULOS
-- =====================================================

-- Las empresas pueden gestionar sus vehículos
CREATE POLICY "empresas_manage_vehiculos" ON vehiculos
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM empresas_transportadoras e
            WHERE e.id = vehiculos.empresa_id
            AND e.usuario_id::text = auth.uid()::text
        )
    );

-- Los conductores pueden ver vehículos de su empresa
CREATE POLICY "conductores_view_vehiculos" ON vehiculos
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM conductores c
            WHERE c.empresa_id = vehiculos.empresa_id
            AND c.usuario_id::text = auth.uid()::text
        )
    );

-- Los usuarios pueden ver vehículos activos (para reservas)
CREATE POLICY "usuarios_view_vehiculos_activos" ON vehiculos
    FOR SELECT USING (estado = 'activo');

-- =====================================================
-- POLÍTICAS PARA RUTAS
-- =====================================================

-- Las empresas pueden gestionar sus rutas
CREATE POLICY "empresas_manage_rutas" ON rutas
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM empresas_transportadoras e
            WHERE e.id = rutas.empresa_id
            AND e.usuario_id::text = auth.uid()::text
        )
    );

-- Los conductores pueden ver rutas de su empresa
CREATE POLICY "conductores_view_rutas" ON rutas
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM conductores c
            WHERE c.empresa_id = rutas.empresa_id
            AND c.usuario_id::text = auth.uid()::text
        )
    );

-- Los usuarios pueden ver rutas activas
CREATE POLICY "usuarios_view_rutas_activas" ON rutas
    FOR SELECT USING (activa = true);

-- =====================================================
-- POLÍTICAS PARA VIAJES
-- =====================================================

-- Las empresas pueden gestionar sus viajes
CREATE POLICY "empresas_manage_viajes" ON viajes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM empresas_transportadoras e
            WHERE e.id = viajes.empresa_id
            AND e.usuario_id::text = auth.uid()::text
        )
    );

-- Los conductores pueden ver y actualizar sus viajes asignados
CREATE POLICY "conductores_manage_viajes_asignados" ON viajes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM conductores c
            WHERE c.id = viajes.conductor_id
            AND c.usuario_id::text = auth.uid()::text
        )
    );

-- Los usuarios pueden ver viajes disponibles
CREATE POLICY "usuarios_view_viajes_disponibles" ON viajes
    FOR SELECT USING (
        estado IN ('programado', 'en_curso') 
        AND cupos_disponibles > 0
    );

-- =====================================================
-- POLÍTICAS PARA RESERVAS
-- =====================================================

-- Los usuarios pueden gestionar sus propias reservas
CREATE POLICY "usuarios_manage_reservas" ON reservas
    FOR ALL USING (usuario_id::text = auth.uid()::text);

-- Las empresas pueden ver reservas de sus viajes
CREATE POLICY "empresas_view_reservas" ON reservas
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM viajes v
            JOIN empresas_transportadoras e ON v.empresa_id = e.id
            WHERE v.id = reservas.viaje_id
            AND e.usuario_id::text = auth.uid()::text
        )
    );

-- Los conductores pueden ver reservas de sus viajes asignados
CREATE POLICY "conductores_view_reservas_viajes" ON reservas
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM viajes v
            JOIN conductores c ON v.conductor_id = c.id
            WHERE v.id = reservas.viaje_id
            AND c.usuario_id::text = auth.uid()::text
        )
    );

-- =====================================================
-- POLÍTICAS PARA PAGOS
-- =====================================================

-- Los usuarios pueden ver sus propios pagos
CREATE POLICY "usuarios_view_pagos" ON pagos
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM reservas r
            WHERE r.id = pagos.reserva_id
            AND r.usuario_id::text = auth.uid()::text
        )
    );

-- Las empresas pueden ver pagos de sus servicios
CREATE POLICY "empresas_view_pagos" ON pagos
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM empresas_transportadoras e
            WHERE e.id = pagos.empresa_id
            AND e.usuario_id::text = auth.uid()::text
        )
    );

-- Las empresas pueden actualizar estado de pagos
CREATE POLICY "empresas_update_pagos" ON pagos
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM empresas_transportadoras e
            WHERE e.id = pagos.empresa_id
            AND e.usuario_id::text = auth.uid()::text
        )
    );

-- =====================================================
-- POLÍTICAS PARA CALIFICACIONES
-- =====================================================

-- Los usuarios pueden crear y ver sus propias calificaciones
CREATE POLICY "usuarios_manage_calificaciones" ON calificaciones
    FOR ALL USING (usuario_id::text = auth.uid()::text);

-- Las empresas pueden ver calificaciones de sus servicios
CREATE POLICY "empresas_view_calificaciones" ON calificaciones
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM empresas_transportadoras e
            WHERE e.id = calificaciones.empresa_id
            AND e.usuario_id::text = auth.uid()::text
        )
    );

-- Los conductores pueden ver sus calificaciones
CREATE POLICY "conductores_view_calificaciones" ON calificaciones
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM conductores c
            WHERE c.id = calificaciones.conductor_id
            AND c.usuario_id::text = auth.uid()::text
        )
    );

-- =====================================================
-- POLÍTICAS PARA NOTIFICACIONES
-- =====================================================

-- Los usuarios pueden gestionar sus propias notificaciones
CREATE POLICY "usuarios_manage_notificaciones" ON notificaciones
    FOR ALL USING (usuario_id::text = auth.uid()::text);

-- =====================================================
-- POLÍTICAS ADICIONALES PARA ADMINISTRADORES
-- =====================================================

-- Los admins pueden ver y gestionar todo
CREATE POLICY "admin_full_access_empresas" ON empresas_transportadoras
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE id::text = auth.uid()::text 
            AND rol = 'admin'
        )
    );

CREATE POLICY "admin_full_access_conductores" ON conductores
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE id::text = auth.uid()::text 
            AND rol = 'admin'
        )
    );

CREATE POLICY "admin_full_access_vehiculos" ON vehiculos
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE id::text = auth.uid()::text 
            AND rol = 'admin'
        )
    );

CREATE POLICY "admin_full_access_viajes" ON viajes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE id::text = auth.uid()::text 
            AND rol = 'admin'
        )
    );

CREATE POLICY "admin_full_access_reservas" ON reservas
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE id::text = auth.uid()::text 
            AND rol = 'admin'
        )
    );

CREATE POLICY "admin_full_access_pagos" ON pagos
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE id::text = auth.uid()::text 
            AND rol = 'admin'
        )
    );

-- =====================================================
-- FUNCIONES DE SEGURIDAD ADICIONALES
-- =====================================================

-- Función para verificar si un usuario es admin
CREATE OR REPLACE FUNCTION es_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM usuarios 
        WHERE id::text = auth.uid()::text 
        AND rol = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para verificar si un usuario es empresa
CREATE OR REPLACE FUNCTION es_empresa()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM usuarios 
        WHERE id::text = auth.uid()::text 
        AND rol = 'empresa'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para verificar si un usuario es conductor
CREATE OR REPLACE FUNCTION es_conductor()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM usuarios 
        WHERE id::text = auth.uid()::text 
        AND rol = 'conductor'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;