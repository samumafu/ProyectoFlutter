DROP TABLE IF EXISTS company_schedules,companies,favorites,ratings,chat_messages,reservations,trips,pasajeros,conductores,empresas,users CASCADE;

CREATE TABLE IF NOT EXISTS public.users(
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  email text UNIQUE NOT NULL,
  password_hash text NOT NULL,
  role text NOT NULL CHECK(role IN('empresa','conductor','pasajero')),
  created_at timestamp DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.companies (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
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

CREATE TABLE IF NOT EXISTS public.conductores (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  phone text,
  auto_model text,
  auto_color text,
  auto_plate text,
  available boolean DEFAULT true,
  rating numeric DEFAULT 5,
  created_at timestamp DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.pasajeros (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  phone text,
  rating numeric DEFAULT 5,
  created_at timestamp DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.company_schedules (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
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
  additional_info JSONB DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS public.reservations (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id uuid REFERENCES public.company_schedules(id) ON DELETE CASCADE,
  passenger_id uuid REFERENCES public.pasajeros(id) ON DELETE CASCADE,
  seats_reserved int DEFAULT 1,
  total_price numeric,
  status text DEFAULT 'pending' CHECK(status IN('pending','confirmed','cancelled')),
  created_at timestamp DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.chat_messages (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id uuid REFERENCES public.company_schedules(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES public.users(id),
  message text NOT NULL,
  created_at timestamp DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ratings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_user uuid REFERENCES public.users(id),
  to_user uuid REFERENCES public.users(id),
  trip_id uuid REFERENCES public.company_schedules(id),
  stars int CHECK(stars BETWEEN 1 AND 5),
  comment text,
  created_at timestamp DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.favorites (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  passenger_id uuid REFERENCES public.pasajeros(id) ON DELETE CASCADE,
  origin text,
  destination text,
  created_at timestamp DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_companies_email ON public.companies(email);
CREATE INDEX IF NOT EXISTS idx_companies_nit ON public.companies(nit);
CREATE INDEX IF NOT EXISTS idx_companies_is_active ON public.companies(is_active);
CREATE INDEX IF NOT EXISTS idx_company_schedules_company_id ON public.company_schedules(company_id);
CREATE INDEX IF NOT EXISTS idx_company_schedules_origin_destination ON public.company_schedules(origin, destination);
CREATE INDEX IF NOT EXISTS idx_company_schedules_departure_time ON public.company_schedules(departure_time);
CREATE INDEX IF NOT EXISTS idx_company_schedules_is_active ON public.company_schedules(is_active);

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Companies can be viewed by everyone" ON public.companies FOR SELECT USING(true);
CREATE POLICY "Companies can insert their own data" ON public.companies FOR INSERT WITH CHECK(true);
CREATE POLICY "Companies can update their own data" ON public.companies FOR UPDATE USING(true);
CREATE POLICY "Company schedules can be viewed by everyone" ON public.company_schedules FOR SELECT USING(true);
CREATE POLICY "Companies can manage their own schedules" ON public.company_schedules FOR ALL USING(true);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_companies_updated_at
BEFORE UPDATE ON public.companies
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
