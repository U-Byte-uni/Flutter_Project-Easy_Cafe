
-- 1. Create Profiles table (if not exists) and trigger for new users
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
  full_name TEXT,
  avatar_url TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Enable RLS on Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Public profiles are viewable by everyone.') THEN
        CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert their own profile.') THEN
        CREATE POLICY "Users can insert their own profile." ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update their own profile.') THEN
        CREATE POLICY "Users can update their own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id);
    END IF;
END $$;

-- 2. Create Orders table
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'Pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Enable RLS on Orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view their own orders.') THEN
        CREATE POLICY "Users can view their own orders." ON public.orders FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert their own orders.') THEN
        CREATE POLICY "Users can insert their own orders." ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update their own orders.') THEN
        CREATE POLICY "Users can update their own orders." ON public.orders FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;

-- 3. Create Order Items table
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID REFERENCES public.orders ON DELETE CASCADE NOT NULL,
  product_id BIGINT REFERENCES public.products(id) NOT NULL,
  quantity INTEGER NOT NULL,
  price DECIMAL(10,2) NOT NULL
);

-- Enable RLS on Order Items
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view their own order items.') THEN
        CREATE POLICY "Users can view their own order items." ON public.order_items FOR SELECT USING (
          EXISTS (
            SELECT 1 FROM public.orders
            WHERE public.orders.id = order_id AND public.orders.user_id = auth.uid()
          )
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert their own order items.') THEN
        CREATE POLICY "Users can insert their own order items." ON public.order_items FOR INSERT WITH CHECK (
          EXISTS (
            SELECT 1 FROM public.orders
            WHERE public.orders.id = order_id AND public.orders.user_id = auth.uid()
          )
        );
    END IF;
END $$;

-- 4. Create Favorites table
CREATE TABLE IF NOT EXISTS public.favorites (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  product_id BIGINT REFERENCES public.products(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  UNIQUE(user_id, product_id)
);

-- Enable RLS on Favorites
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view their own favorites.') THEN
        CREATE POLICY "Users can view their own favorites." ON public.favorites FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert their own favorites.') THEN
        CREATE POLICY "Users can insert their own favorites." ON public.favorites FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can delete their own favorites.') THEN
        CREATE POLICY "Users can delete their own favorites." ON public.favorites FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;
