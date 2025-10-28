-- =====================================================
-- ESQUEMA COMPLETO DE BASE DE DATOS PARA SISTEMA DE TRANSPORTE INTERMUNICIPAL
-- Departamento de Nariño, Colombia
-- =====================================================

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. TABLA DE USUARIOS (Base para todos los roles)
-- =====================================================
CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('usuario', 'conductor', 'empresa', 'admin')),
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    cedula VARCHAR(20) UNIQUE NOT NULL,
    telefono VARCHAR(15),
    fecha_nacimiento DATE,
    direccion TEXT,
    municipio VARCHAR(100),
    departamento VARCHAR(100) DEFAULT 'Nariño',
    foto_perfil_url TEXT,
    estado VARCHAR(20) DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo', 'suspendido')),
    email_verificado BOOLEAN DEFAULT FALSE,
    telefono_verificado BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 2. TABLA DE EMPRESAS TRANSPORTADORAS
-- =====================================================
CREATE TABLE empresas_transportadoras (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre_empresa VARCHAR(200) NOT NULL,
    nit VARCHAR(20) UNIQUE NOT NULL,
    representante_legal VARCHAR(200) NOT NULL,
    cedula_representante VARCHAR(20) NOT NULL,
    direccion_empresa TEXT NOT NULL,
    municipio_sede VARCHAR(100) NOT NULL,
    telefono_empresa VARCHAR(15) NOT NULL,
    email_empresa VARCHAR(255) NOT NULL,
    sitio_web VARCHAR(255),
    
    -- Documentos de habilitación
    resolucion_habilitacion VARCHAR(100),
    fecha_habilitacion DATE,
    fecha_vencimiento_habilitacion DATE,
    documento_habilitacion_url TEXT,
    rut_url TEXT,
    camara_comercio_url TEXT,
    
    -- Estado y verificación
    estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'verificado', 'rechazado', 'suspendido')),
    verificado_por UUID REFERENCES usuarios(id),
    fecha_verificacion TIMESTAMP WITH TIME ZONE,
    observaciones TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 3. TABLA DE CONDUCTORES
-- =====================================================
CREATE TABLE conductores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    empresa_id UUID REFERENCES empresas_transportadoras(id) ON DELETE SET NULL,
    
    -- Información específica del conductor
    numero_licencia VARCHAR(20) UNIQUE NOT NULL,
    categoria_licencia VARCHAR(10) NOT NULL,
    fecha_expedicion_licencia DATE NOT NULL,
    fecha_vencimiento_licencia DATE NOT NULL,
    licencia_url TEXT,
    
    -- Documentos adicionales
    soat_url TEXT,
    fecha_vencimiento_soat DATE,
    revision_tecnomecanica_url TEXT,
    fecha_vencimiento_tecnomecanica DATE,
    cedula_url TEXT,
    antecedentes_url TEXT,
    
    -- Estado operativo
    estado_operativo VARCHAR(20) DEFAULT 'disponible' CHECK (estado_operativo IN ('disponible', 'en_ruta', 'fuera_servicio', 'descanso')),
    calificacion_promedio DECIMAL(3,2) DEFAULT 0.00,
    total_viajes INTEGER DEFAULT 0,
    
    -- Verificación
    verificado BOOLEAN DEFAULT FALSE,
    verificado_por UUID REFERENCES usuarios(id),
    fecha_verificacion TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 4. TABLA DE VEHÍCULOS
-- =====================================================
CREATE TABLE vehiculos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID REFERENCES empresas_transportadoras(id) ON DELETE CASCADE,
    conductor_asignado_id UUID REFERENCES conductores(id) ON DELETE SET NULL,
    
    -- Información del vehículo
    placa VARCHAR(10) UNIQUE NOT NULL,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    año INTEGER NOT NULL,
    color VARCHAR(30) NOT NULL,
    numero_interno VARCHAR(20),
    
    -- Capacidad y características
    capacidad_pasajeros INTEGER NOT NULL,
    tipo_vehiculo VARCHAR(30) NOT NULL CHECK (tipo_vehiculo IN ('bus', 'microbus', 'van', 'automovil')),
    tiene_aire_acondicionado BOOLEAN DEFAULT FALSE,
    tiene_wifi BOOLEAN DEFAULT FALSE,
    tiene_tv BOOLEAN DEFAULT FALSE,
    tiene_baño BOOLEAN DEFAULT FALSE,
    
    -- Documentos
    tarjeta_propiedad_url TEXT,
    soat_url TEXT,
    fecha_vencimiento_soat DATE,
    tecnomecanica_url TEXT,
    fecha_vencimiento_tecnomecanica DATE,
    poliza_contractual_url TEXT,
    poliza_extracontractual_url TEXT,
    
    -- Estado
    estado VARCHAR(20) DEFAULT 'activo' CHECK (estado IN ('activo', 'mantenimiento', 'fuera_servicio', 'inactivo')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 5. TABLA DE RUTAS (Actualizada)
-- =====================================================
CREATE TABLE rutas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID REFERENCES empresas_transportadoras(id) ON DELETE CASCADE,
    
    -- Información de la ruta
    nombre_ruta VARCHAR(200) NOT NULL,
    ciudad_origen VARCHAR(100) NOT NULL,
    ciudad_destino VARCHAR(100) NOT NULL,
    distancia_km DECIMAL(8,2),
    duracion_estimada_minutos INTEGER,
    
    -- Puntos intermedios (JSON array)
    puntos_intermedios JSONB DEFAULT '[]',
    
    -- Coordenadas
    coordenadas_origen JSONB, -- {lat: number, lng: number}
    coordenadas_destino JSONB, -- {lat: number, lng: number}
    
    -- Precios y configuración
    precio_base DECIMAL(10,2) NOT NULL,
    precio_estudiante DECIMAL(10,2),
    precio_adulto_mayor DECIMAL(10,2),
    
    -- Estado
    activa BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 6. TABLA DE VIAJES PROGRAMADOS
-- =====================================================
CREATE TABLE viajes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID REFERENCES empresas_transportadoras(id) ON DELETE CASCADE,
    ruta_id UUID REFERENCES rutas(id) ON DELETE CASCADE,
    vehiculo_id UUID REFERENCES vehiculos(id) ON DELETE SET NULL,
    conductor_id UUID REFERENCES conductores(id) ON DELETE SET NULL,
    
    -- Programación del viaje
    fecha_viaje DATE NOT NULL,
    hora_salida TIME NOT NULL,
    hora_llegada_estimada TIME,
    
    -- Capacidad y disponibilidad
    cupos_totales INTEGER NOT NULL,
    cupos_disponibles INTEGER NOT NULL,
    cupos_reservados INTEGER DEFAULT 0,
    
    -- Precios específicos del viaje
    precio_adulto DECIMAL(10,2) NOT NULL,
    precio_estudiante DECIMAL(10,2),
    precio_adulto_mayor DECIMAL(10,2),
    
    -- Estado del viaje
    estado VARCHAR(20) DEFAULT 'programado' CHECK (estado IN ('programado', 'en_curso', 'finalizado', 'cancelado')),
    
    -- Tiempos reales
    hora_salida_real TIMESTAMP WITH TIME ZONE,
    hora_llegada_real TIMESTAMP WITH TIME ZONE,
    
    -- Observaciones
    observaciones TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 7. TABLA DE RESERVAS (Actualizada)
-- =====================================================
CREATE TABLE reservas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    viaje_id UUID REFERENCES viajes(id) ON DELETE CASCADE,
    
    -- Información del pasajero
    nombre_pasajero VARCHAR(200) NOT NULL,
    cedula_pasajero VARCHAR(20) NOT NULL,
    telefono_pasajero VARCHAR(15),
    email_pasajero VARCHAR(255),
    tipo_pasajero VARCHAR(20) DEFAULT 'adulto' CHECK (tipo_pasajero IN ('adulto', 'estudiante', 'adulto_mayor', 'niño')),
    
    -- Detalles de la reserva
    numero_asiento INTEGER,
    precio_pagado DECIMAL(10,2) NOT NULL,
    codigo_reserva VARCHAR(20) UNIQUE NOT NULL,
    
    -- Estado de la reserva
    estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'confirmada', 'pagada', 'abordado', 'no_show', 'cancelada')),
    
    -- Información de pago
    metodo_pago VARCHAR(30),
    referencia_pago VARCHAR(100),
    fecha_pago TIMESTAMP WITH TIME ZONE,
    
    -- Fechas importantes
    fecha_reserva TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_cancelacion TIMESTAMP WITH TIME ZONE,
    motivo_cancelacion TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 8. TABLA DE PAGOS
-- =====================================================
CREATE TABLE pagos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reserva_id UUID REFERENCES reservas(id) ON DELETE CASCADE,
    empresa_id UUID REFERENCES empresas_transportadoras(id) ON DELETE CASCADE,
    
    -- Información del pago
    monto DECIMAL(10,2) NOT NULL,
    metodo_pago VARCHAR(30) NOT NULL CHECK (metodo_pago IN ('efectivo', 'tarjeta', 'transferencia', 'pse', 'nequi', 'daviplata')),
    estado_pago VARCHAR(20) DEFAULT 'pendiente' CHECK (estado_pago IN ('pendiente', 'completado', 'fallido', 'reembolsado')),
    
    -- Referencias externas
    referencia_externa VARCHAR(100),
    id_transaccion_pasarela VARCHAR(100),
    
    -- Detalles adicionales
    descripcion TEXT,
    comprobante_url TEXT,
    
    -- Fechas
    fecha_pago TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_confirmacion TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 9. TABLA DE CALIFICACIONES
-- =====================================================
CREATE TABLE calificaciones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reserva_id UUID REFERENCES reservas(id) ON DELETE CASCADE,
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    conductor_id UUID REFERENCES conductores(id) ON DELETE CASCADE,
    empresa_id UUID REFERENCES empresas_transportadoras(id) ON DELETE CASCADE,
    
    -- Calificaciones (1-5 estrellas)
    calificacion_conductor INTEGER CHECK (calificacion_conductor BETWEEN 1 AND 5),
    calificacion_vehiculo INTEGER CHECK (calificacion_vehiculo BETWEEN 1 AND 5),
    calificacion_servicio INTEGER CHECK (calificacion_servicio BETWEEN 1 AND 5),
    calificacion_general INTEGER CHECK (calificacion_general BETWEEN 1 AND 5),
    
    -- Comentarios
    comentario TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 10. TABLA DE NOTIFICACIONES
-- =====================================================
CREATE TABLE notificaciones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    
    -- Contenido de la notificación
    titulo VARCHAR(200) NOT NULL,
    mensaje TEXT NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('reserva', 'pago', 'viaje', 'sistema', 'promocion')),
    
    -- Estado
    leida BOOLEAN DEFAULT FALSE,
    fecha_lectura TIMESTAMP WITH TIME ZONE,
    
    -- Datos adicionales
    datos_adicionales JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

-- Índices para usuarios
CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_usuarios_cedula ON usuarios(cedula);
CREATE INDEX idx_usuarios_rol ON usuarios(rol);

-- Índices para empresas
CREATE INDEX idx_empresas_nit ON empresas_transportadoras(nit);
CREATE INDEX idx_empresas_estado ON empresas_transportadoras(estado);

-- Índices para conductores
CREATE INDEX idx_conductores_empresa ON conductores(empresa_id);
CREATE INDEX idx_conductores_licencia ON conductores(numero_licencia);
CREATE INDEX idx_conductores_estado ON conductores(estado_operativo);

-- Índices para vehículos
CREATE INDEX idx_vehiculos_placa ON vehiculos(placa);
CREATE INDEX idx_vehiculos_empresa ON vehiculos(empresa_id);

-- Índices para rutas
CREATE INDEX idx_rutas_empresa ON rutas(empresa_id);
CREATE INDEX idx_rutas_origen_destino ON rutas(ciudad_origen, ciudad_destino);

-- Índices para viajes
CREATE INDEX idx_viajes_fecha ON viajes(fecha_viaje);
CREATE INDEX idx_viajes_ruta ON viajes(ruta_id);
CREATE INDEX idx_viajes_estado ON viajes(estado);

-- Índices para reservas
CREATE INDEX idx_reservas_usuario ON reservas(usuario_id);
CREATE INDEX idx_reservas_viaje ON reservas(viaje_id);
CREATE INDEX idx_reservas_codigo ON reservas(codigo_reserva);
CREATE INDEX idx_reservas_estado ON reservas(estado);

-- =====================================================
-- TRIGGERS PARA UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar trigger a todas las tablas con updated_at
CREATE TRIGGER update_usuarios_updated_at BEFORE UPDATE ON usuarios FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_empresas_updated_at BEFORE UPDATE ON empresas_transportadoras FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_conductores_updated_at BEFORE UPDATE ON conductores FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vehiculos_updated_at BEFORE UPDATE ON vehiculos FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_rutas_updated_at BEFORE UPDATE ON rutas FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_viajes_updated_at BEFORE UPDATE ON viajes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reservas_updated_at BEFORE UPDATE ON reservas FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pagos_updated_at BEFORE UPDATE ON pagos FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCIONES AUXILIARES
-- =====================================================

-- Función para generar código de reserva único
CREATE OR REPLACE FUNCTION generar_codigo_reserva()
RETURNS TEXT AS $$
DECLARE
    codigo TEXT;
    existe BOOLEAN;
BEGIN
    LOOP
        codigo := 'RES' || LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
        SELECT EXISTS(SELECT 1 FROM reservas WHERE codigo_reserva = codigo) INTO existe;
        IF NOT existe THEN
            EXIT;
        END IF;
    END LOOP;
    RETURN codigo;
END;
$$ LANGUAGE plpgsql;

-- Función para actualizar cupos disponibles
CREATE OR REPLACE FUNCTION actualizar_cupos_viaje()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE viajes 
        SET cupos_disponibles = cupos_disponibles - 1,
            cupos_reservados = cupos_reservados + 1
        WHERE id = NEW.viaje_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE viajes 
        SET cupos_disponibles = cupos_disponibles + 1,
            cupos_reservados = cupos_reservados - 1
        WHERE id = OLD.viaje_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar cupos automáticamente
CREATE TRIGGER trigger_actualizar_cupos
    AFTER INSERT OR DELETE ON reservas
    FOR EACH ROW EXECUTE FUNCTION actualizar_cupos_viaje();