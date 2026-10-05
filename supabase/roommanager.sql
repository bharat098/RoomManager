-- RoomManager production schema for Supabase
-- Run this once in Supabase SQL Editor. It is safe to re-run because policies/triggers are recreated.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  currency text not null default 'INR',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  currency text not null default 'INR',
  notifications_enabled boolean not null default true,
  face_id_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.payment_sources (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  kind text not null default 'manual',
  emoji text not null default '🧾',
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  unique(user_id,name)
);
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  emoji text not null default '📦',
  created_at timestamptz not null default now(),
  unique(user_id,name)
);
create table if not exists public.merchants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  normalized_name text not null,
  default_category_id uuid references public.categories(id) on delete set null,
  created_at timestamptz not null default now(),
  unique(user_id,normalized_name)
);
create table if not exists public.merchant_rules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  pattern text not null,
  merchant_name text,
  category_id uuid references public.categories(id) on delete set null,
  priority integer not null default 100,
  created_at timestamptz not null default now(),
  unique(user_id,pattern)
);
create table if not exists public.import_batches (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source text not null,
  file_name text,
  total_detected integer not null default 0,
  total_imported integer not null default 0,
  total_duplicates integer not null default 0,
  total_review integer not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount numeric(14,2) not null check(amount>=0),
  currency text not null default 'INR',
  merchant_id uuid references public.merchants(id) on delete set null,
  original_merchant_name text,
  normalized_merchant_name text,
  category_id uuid references public.categories(id) on delete set null,
  payment_source_id uuid references public.payment_sources(id) on delete set null,
  transaction_date date not null default current_date,
  transaction_time time,
  payment_method text,
  source text not null default 'manual',
  external_reference text,
  notes text,
  import_batch_id uuid references public.import_batches(id) on delete set null,
  fingerprint text,
  needs_review boolean not null default false,
  is_duplicate boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id,fingerprint)
);
create table if not exists public.bills (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  category_id uuid references public.categories(id) on delete set null,
  amount numeric(14,2) not null check(amount>=0),
  due_day integer not null check(due_day between 1 and 31),
  frequency text not null default 'monthly',
  payment_source_id uuid references public.payment_sources(id) on delete set null,
  provider text,
  notes text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.bill_payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  bill_id uuid not null references public.bills(id) on delete cascade,
  transaction_id uuid not null references public.transactions(id) on delete cascade,
  paid_on date not null default current_date,
  amount numeric(14,2) not null check(amount>=0),
  created_at timestamptz not null default now(),
  unique(bill_id,paid_on)
);
create table if not exists public.household_members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  role text not null default 'Cook',
  monthly_salary numeric(14,2) not null default 0,
  working_days integer not null default 26,
  weekly_off text,
  per_day_rate_override numeric(14,2),
  start_date date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  member_id uuid not null references public.household_members(id) on delete cascade,
  attendance_date date not null,
  status text not null check(status in ('Present','Absent','Leave','Half Day','Not Marked')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(member_id,attendance_date)
);

create index if not exists transactions_user_date_idx on public.transactions(user_id,transaction_date desc);
create index if not exists transactions_user_source_idx on public.transactions(user_id,payment_source_id);
create index if not exists transactions_user_category_idx on public.transactions(user_id,category_id);
create index if not exists transactions_user_fingerprint_idx on public.transactions(user_id,fingerprint);
create index if not exists bills_user_due_idx on public.bills(user_id,due_day);
create index if not exists attendance_member_date_idx on public.attendance(member_id,attendance_date desc);

alter table public.profiles enable row level security;
alter table public.settings enable row level security;
alter table public.payment_sources enable row level security;
alter table public.categories enable row level security;
alter table public.merchants enable row level security;
alter table public.merchant_rules enable row level security;
alter table public.import_batches enable row level security;
alter table public.transactions enable row level security;
alter table public.bills enable row level security;
alter table public.bill_payments enable row level security;
alter table public.household_members enable row level security;
alter table public.attendance enable row level security;

drop policy if exists "profiles own" on public.profiles;
drop policy if exists "settings own" on public.settings;
drop policy if exists "payment sources own" on public.payment_sources;
drop policy if exists "categories own" on public.categories;
drop policy if exists "merchants own" on public.merchants;
drop policy if exists "merchant rules own" on public.merchant_rules;
drop policy if exists "import batches own" on public.import_batches;
drop policy if exists "transactions own" on public.transactions;
drop policy if exists "bills own" on public.bills;
drop policy if exists "bill payments own" on public.bill_payments;
drop policy if exists "household own" on public.household_members;
drop policy if exists "attendance own" on public.attendance;
create policy "profiles own" on public.profiles for all using(id=auth.uid()) with check(id=auth.uid());
create policy "settings own" on public.settings for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "payment sources own" on public.payment_sources for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "categories own" on public.categories for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "merchants own" on public.merchants for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "merchant rules own" on public.merchant_rules for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "import batches own" on public.import_batches for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "transactions own" on public.transactions for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "bills own" on public.bills for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "bill payments own" on public.bill_payments for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "household own" on public.household_members for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "attendance own" on public.attendance for all using(user_id=auth.uid()) with check(user_id=auth.uid());

create or replace function public.touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at=now();return new;end;$$;

drop trigger if exists profiles_touch on public.profiles; create trigger profiles_touch before update on public.profiles for each row execute function public.touch_updated_at();
drop trigger if exists settings_touch on public.settings; create trigger settings_touch before update on public.settings for each row execute function public.touch_updated_at();
drop trigger if exists transactions_touch on public.transactions; create trigger transactions_touch before update on public.transactions for each row execute function public.touch_updated_at();
drop trigger if exists bills_touch on public.bills; create trigger bills_touch before update on public.bills for each row execute function public.touch_updated_at();
drop trigger if exists household_touch on public.household_members; create trigger household_touch before update on public.household_members for each row execute function public.touch_updated_at();
drop trigger if exists attendance_touch on public.attendance; create trigger attendance_touch before update on public.attendance for each row execute function public.touch_updated_at();

create or replace function public.seed_roommanager_defaults()
returns trigger language plpgsql security definer set search_path=public as $$
declare food_id uuid; grocery_id uuid; wifi_id uuid; elec_id uuid;
begin
  insert into public.profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',split_part(coalesce(new.email,''),'@',1))) on conflict do nothing;
  insert into public.settings(user_id) values(new.id) on conflict do nothing;
  insert into public.payment_sources(user_id,name,kind,emoji) values
    (new.id,'PhonePe','sync','📱'),(new.id,'Cash','manual','💵'),(new.id,'Card','import','💳'),
    (new.id,'UPI','import','🏦'),(new.id,'Bank','import','🏦'),(new.id,'Manual','manual','✍️'),(new.id,'Other','manual','🧾')
    on conflict do nothing;
  insert into public.categories(user_id,name,emoji) values
    (new.id,'Rent','🏠'),(new.id,'Electricity','⚡'),(new.id,'WiFi','📶'),(new.id,'Cook','👨‍🍳'),(new.id,'Maid','🧹'),
    (new.id,'Groceries','🛒'),(new.id,'Food','🍔'),(new.id,'Swiggy','🍔'),(new.id,'Zomato','🍕'),(new.id,'Blinkit','🛒'),
    (new.id,'Zepto','🛍️'),(new.id,'Milk','🥛'),(new.id,'Gas','🔥'),(new.id,'Maintenance','🧰'),(new.id,'Shopping','🛍️'),
    (new.id,'Transport','🚕'),(new.id,'Medical','💊'),(new.id,'Entertainment','🎬'),(new.id,'Other','📦')
    on conflict do nothing;
  select id into food_id from public.categories where user_id=new.id and name='Food';
  select id into grocery_id from public.categories where user_id=new.id and name='Groceries';
  select id into wifi_id from public.categories where user_id=new.id and name='WiFi';
  select id into elec_id from public.categories where user_id=new.id and name='Electricity';
  insert into public.merchant_rules(user_id,pattern,merchant_name,category_id,priority) values
    (new.id,'SWIGGY','Swiggy',food_id,10),(new.id,'ZOMATO','Zomato',food_id,10),(new.id,'BLINKIT','Blinkit',grocery_id,10),
    (new.id,'ZEPTO','Zepto',grocery_id,10),(new.id,'ACT FIBERNET','ACT Fibernet',wifi_id,10),(new.id,'ELECTRICITY','Electricity',elec_id,10)
    on conflict do nothing;
  return new;
end;$$;

drop trigger if exists on_auth_user_created_roommanager on auth.users;
create trigger on_auth_user_created_roommanager after insert on auth.users for each row execute function public.seed_roommanager_defaults();

-- Data API privileges: RLS remains the primary row-level protection.
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.profiles, public.settings, public.payment_sources, public.categories,
  public.merchants, public.merchant_rules, public.import_batches, public.transactions, public.bills,
  public.bill_payments, public.household_members, public.attendance to authenticated;
