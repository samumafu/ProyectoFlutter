ALTER TABLE public.reservations ADD COLUMN IF NOT EXISTS seat_numbers TEXT[] DEFAULT '{}';
