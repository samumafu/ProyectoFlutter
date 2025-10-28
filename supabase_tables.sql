-- Crear tabla companies
CREATE TABLE IF NOT EXISTS public.companies (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address TEXT NOT NULL,
    nit VARCHAR(20) UNIQUE NOT NULL,
    description TEXT DEFAULT '',
    logo_url TEXT DEFAULT '',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    routes TEXT[] DEFAULT '{}',
    settings JSONB DEFAULT '{}'
);

-- Crear tabla company_schedules
CREATE TABLE IF NOT EXISTS public.company_schedules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    origin VARCHAR(255) NOT NULL,
    destination VARCHAR(255) NOT NULL,
    departure_time TIMESTAMP WITH TIME ZONE NOT NULL,
    arrival_time TIMESTAMP WITH TIME ZONE NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    available_seats INTEGER NOT NULL,
    total_seats INTEGER NOT NULL,
    vehicle_type VARCHAR(100) NOT NULL,
    vehicle_id VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    additional_info JSONB DEFAULT '{}',
    expiration_date TIMESTAMP WITH TIME ZONE
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_companies_email ON public.companies(email);
CREATE INDEX IF NOT EXISTS idx_companies_nit ON public.companies(nit);
CREATE INDEX IF NOT EXISTS idx_companies_is_active ON public.companies(is_active);

CREATE INDEX IF NOT EXISTS idx_company_schedules_company_id ON public.company_schedules(company_id);
CREATE INDEX IF NOT EXISTS idx_company_schedules_origin_destination ON public.company_schedules(origin, destination);
CREATE INDEX IF NOT EXISTS idx_company_schedules_departure_time ON public.company_schedules(departure_time);
CREATE INDEX IF NOT EXISTS idx_company_schedules_is_active ON public.company_schedules(is_active);

-- Habilitar RLS (Row Level Security)
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_schedules ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad para companies
CREATE POLICY "Companies can be viewed by everyone" ON public.companies
    FOR SELECT USING (true);

CREATE POLICY "Companies can insert their own data" ON public.companies
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Companies can update their own data" ON public.companies
    FOR UPDATE USING (true);

-- Políticas de seguridad para company_schedules
CREATE POLICY "Company schedules can be viewed by everyone" ON public.company_schedules
    FOR SELECT USING (true);

CREATE POLICY "Companies can manage their own schedules" ON public.company_schedules
    FOR ALL USING (true);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar updated_at en companies
CREATE TRIGGER update_companies_updated_at 
    BEFORE UPDATE ON public.companies 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();