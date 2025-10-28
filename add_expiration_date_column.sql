-- Agregar columna expiration_date a la tabla company_schedules
ALTER TABLE public.company_schedules 
ADD COLUMN IF NOT EXISTS expiration_date TIMESTAMP WITH TIME ZONE;

-- Crear índice para mejorar el rendimiento de las consultas de expiración
CREATE INDEX IF NOT EXISTS idx_company_schedules_expiration_date 
ON public.company_schedules(expiration_date);