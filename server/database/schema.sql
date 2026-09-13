-- مخطط قاعدة بيانات ديباناج — Supabase / PostgreSQL
-- شغّل هذا الملف مرة واحدة في SQL Editor الخاص بمشروع Supabase.

create extension if not exists "uuid-ossp";

create table if not exists users (
  id uuid primary key default uuid_generate_v4(),
  phone text unique not null,
  name text default '',
  role text not null default 'client' check (role in ('client', 'driver', 'admin')),
  blocked boolean default false,
  created_at timestamptz default now()
);

create table if not exists drivers (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references users(id) on delete cascade,
  license_number text not null,
  license_expiry date,
  plate_number text not null,
  vehicle_year int,
  vehicle_types text[] not null default '{}',
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  rejection_reason text,
  created_at timestamptz default now()
);

create table if not exists documents (
  id uuid primary key default uuid_generate_v4(),
  driver_id uuid references drivers(id) on delete cascade,
  type text not null,
  image_url text not null,
  verified boolean default false,
  created_at timestamptz default now()
);

create table if not exists tow_requests (
  id uuid primary key default uuid_generate_v4(),
  client_id uuid references users(id),
  provider_id uuid references users(id),
  vehicle_category text not null,
  pickup_lat double precision not null,
  pickup_lng double precision not null,
  dropoff_lat double precision not null,
  dropoff_lng double precision not null,
  price numeric not null,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')),
  created_at timestamptz default now()
);

create table if not exists offers (
  id uuid primary key default uuid_generate_v4(),
  request_id uuid references tow_requests(id) on delete cascade,
  driver_id uuid references users(id),
  price numeric not null,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected')),
  created_at timestamptz default now()
);

create table if not exists trips (
  id uuid primary key default uuid_generate_v4(),
  request_id uuid references tow_requests(id),
  driver_id uuid references users(id),
  client_id uuid references users(id),
  vehicle_category text,
  pickup_lat double precision,
  pickup_lng double precision,
  dropoff_lat double precision,
  dropoff_lng double precision,
  final_price numeric,
  rating int check (rating between 1 and 5),
  status text not null default 'completed'
    check (status in ('in_progress', 'completed', 'cancelled')),
  created_at timestamptz default now(),
  completed_at timestamptz
);

create table if not exists ratings (
  id uuid primary key default uuid_generate_v4(),
  trip_id uuid references trips(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  tags text[] default '{}',
  created_at timestamptz default now()
);

create table if not exists wallets (
  user_id uuid primary key references users(id) on delete cascade,
  balance numeric not null default 0
);

create table if not exists transactions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references users(id),
  amount numeric not null,
  type text not null check (type in ('credit', 'debit')),
  reason text,
  created_at timestamptz default now()
);

create table if not exists workshops (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  specialty text,
  phone text,
  lat double precision not null,
  lng double precision not null,
  rating numeric default 0
);

create table if not exists app_settings (
  key text primary key,
  value text not null
);

insert into app_settings (key, value) values
  ('commission_rate', '15'),
  ('min_wallet_balance', '500'),
  ('price_per_km_motorcycle', '300'),
  ('price_per_km_car', '500'),
  ('price_per_km_truck', '900')
on conflict (key) do nothing;

-- فهارس أساسية لتسريع الاستعلامات الشائعة
create index if not exists idx_tow_requests_client on tow_requests(client_id);
create index if not exists idx_tow_requests_provider on tow_requests(provider_id, status);
create index if not exists idx_offers_request on offers(request_id);
create index if not exists idx_drivers_user on drivers(user_id);
create index if not exists idx_drivers_status on drivers(status);
