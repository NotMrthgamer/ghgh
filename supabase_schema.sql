-- Full fresh database setup for Eternity Hub (Supabase)
-- WARNING: This will drop previous tables to clear any corrupted schemas & old data.

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. DROP EXISTING TABLES CASCADE (Deletes previous data and resets cache)
DROP TABLE IF EXISTS admin_emails CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS purchases CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
DROP TABLE IF EXISTS ranks CASCADE;
DROP TABLE IF EXISTS rules CASCADE;
DROP TABLE IF EXISTS news CASCADE;
DROP TABLE IF EXISTS vote_links CASCADE;
DROP TABLE IF EXISTS settings CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

-- 2. CREATE FRESH TABLES WITH ROBUST STR-UUID DEFAULTS

-- Categories Table
CREATE TABLE categories (
  id text DEFAULT gen_random_uuid()::text PRIMARY KEY,
  name text NOT NULL,
  "order" integer NOT NULL DEFAULT 0,
  image_url text
);

-- Products Table
CREATE TABLE products (
  id text DEFAULT gen_random_uuid()::text PRIMARY KEY,
  name text NOT NULL,
  description text,
  price numeric NOT NULL DEFAULT 0,
  stock integer NOT NULL DEFAULT -1, -- -1 for unlimited
  category_id text REFERENCES categories(id) ON DELETE CASCADE,
  image_url text,
  product_type text NOT NULL DEFAULT 'others',
  "order" integer NOT NULL DEFAULT 0,
  purchase_options jsonb DEFAULT '[]'::jsonb
);

-- Settings Table (Holds global design & IP settings)
CREATE TABLE settings (
  id text PRIMARY KEY DEFAULT 'global',
  server_name text,
  server_ip text,
  discord_link text,
  server_icon text,
  primary_color text,
  secondary_color text,
  brand_color_1 text,
  brand_color_2 text,
  brand_name_split integer DEFAULT 1,
  brand_name_first text,
  brand_name_second text,
  hero_bg_url text,
  patron_image_url text,
  rules_bg_url text,
  rules_border_color text,
  discord_order_webhook text,
  store_banner_url text,
  store_welcome_title text,
  store_welcome_description text,
  payment_number_bkash text,
  payment_number_nagad text,
  payment_number_rocket text,
  payment_info_bkash text,
  payment_info_nagad text,
  payment_info_rocket text,
  payment_info_other text,
  mysql_host text,
  mysql_port text,
  mysql_database text,
  mysql_user text,
  mysql_password text,
  mysql_jdbc_string text
);

-- Vote Links Table
CREATE TABLE vote_links (
  id text DEFAULT gen_random_uuid()::text PRIMARY KEY,
  name text NOT NULL,
  url text NOT NULL
);

-- News Table
CREATE TABLE news (
  id text DEFAULT gen_random_uuid()::text PRIMARY KEY,
  title text NOT NULL,
  content text NOT NULL,
  author text NOT NULL,
  image_url text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- Rules Table
CREATE TABLE rules (
  id text DEFAULT gen_random_uuid()::text PRIMARY KEY,
  title text NOT NULL,
  description text NOT NULL,
  "order" integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- Ranks Table (For Staff)
CREATE TABLE ranks (
  id text DEFAULT gen_random_uuid()::text PRIMARY KEY,
  name text NOT NULL,
  "order" integer NOT NULL DEFAULT 0
);

-- Staff Table
CREATE TABLE staff (
  id text DEFAULT gen_random_uuid()::text PRIMARY KEY,
  ign text NOT NULL,
  uuid text,
  username text, -- Crucial column requested
  rank_id text REFERENCES ranks(id) ON DELETE CASCADE
);

-- Orders Table (Checkout / Store transactions)
CREATE TABLE orders (
  id text DEFAULT gen_random_uuid()::text PRIMARY KEY,
  user_id text DEFAULT 'guest',
  ign text NOT NULL,
  payment_method text,
  sender_number text,
  transaction_id text,
  status text NOT NULL DEFAULT 'pending', -- 'pending' or 'verified'
  total_amount numeric NOT NULL DEFAULT 0,
  items jsonb DEFAULT '[]'::jsonb,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- Purchases Table (Manual payment verification panel)
CREATE TABLE purchases (
  id text DEFAULT gen_random_uuid()::text PRIMARY KEY,
  username text NOT NULL,
  rank_name text NOT NULL,
  amount_paid numeric NOT NULL,
  sender_number text,
  trx_id text,
  status text NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
  purchase_date timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- Profiles Table (Users & Admins)
CREATE TABLE profiles (
  id text PRIMARY KEY, -- Maps to supabase auth user id
  email text NOT NULL,
  display_name text,
  role text NOT NULL DEFAULT 'user', -- 'user' or 'admin'
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- Admin Emails Table (Whitelist mapping)
CREATE TABLE admin_emails (
  id text DEFAULT gen_random_uuid()::text PRIMARY KEY,
  email text NOT NULL UNIQUE,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);


-- 3. BYPASS OR CONFIG ROW LEVEL SECURITY (RLS) FOR UNRESTRICTED ACCESS
-- Supabase enforces RLS policies on new tables. We enable RLS and explicitly grant full access to everyone (public).
-- This completely prevents "violates row-level security policy" errors.

-- 1. Categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public access on categories" ON categories;
CREATE POLICY "Allow public access on categories" ON categories FOR ALL TO public USING (true) WITH CHECK (true);

-- 2. Products
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public access on products" ON products;
CREATE POLICY "Allow public access on products" ON products FOR ALL TO public USING (true) WITH CHECK (true);

-- 3. Settings
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public access on settings" ON settings;
CREATE POLICY "Allow public access on settings" ON settings FOR ALL TO public USING (true) WITH CHECK (true);

-- 4. Vote Links
ALTER TABLE vote_links ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public access on vote_links" ON vote_links;
CREATE POLICY "Allow public access on vote_links" ON vote_links FOR ALL TO public USING (true) WITH CHECK (true);

-- 5. News
ALTER TABLE news ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public access on news" ON news;
CREATE POLICY "Allow public access on news" ON news FOR ALL TO public USING (true) WITH CHECK (true);

-- 6. Rules
ALTER TABLE rules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public access on rules" ON rules;
CREATE POLICY "Allow public access on rules" ON rules FOR ALL TO public USING (true) WITH CHECK (true);

-- 7. Ranks
ALTER TABLE ranks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public access on ranks" ON ranks;
CREATE POLICY "Allow public access on ranks" ON ranks FOR ALL TO public USING (true) WITH CHECK (true);

-- 8. Staff
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public access on staff" ON staff;
CREATE POLICY "Allow public access on staff" ON staff FOR ALL TO public USING (true) WITH CHECK (true);

-- 9. Orders
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public access on orders" ON orders;
CREATE POLICY "Allow public access on orders" ON orders FOR ALL TO public USING (true) WITH CHECK (true);

-- 10. Purchases
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public access on purchases" ON purchases;
CREATE POLICY "Allow public access on purchases" ON purchases FOR ALL TO public USING (true) WITH CHECK (true);

-- 11. Profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public access on profiles" ON profiles;
CREATE POLICY "Allow public access on profiles" ON profiles FOR ALL TO public USING (true) WITH CHECK (true);

-- 12. Admin Emails
ALTER TABLE admin_emails ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public access on admin_emails" ON admin_emails;
CREATE POLICY "Allow public access on admin_emails" ON admin_emails FOR ALL TO public USING (true) WITH CHECK (true);


-- 4. SEED FRESH INITIAL DEFAULT DATA

-- Insert default categories
INSERT INTO categories (id, name, "order") VALUES
('cat-1', 'Ranks', 1),
('cat-2', 'Keys', 2),
('cat-3', 'Coins', 3);

-- Insert default products
INSERT INTO products (id, name, price, description, category_id, stock, image_url, product_type) VALUES
('prod-1', 'VIP Rank', 500, 'Get a fancy VIP tag, special kits, and priority queue entrance!', 'cat-1', -1, 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png', 'rank'),
('prod-2', 'MVP Rank', 1000, 'Get all VIP perks plus /fly commands, custom particles, and extra chest slots!', 'cat-1', -1, 'https://cdn-icons-png.flaticon.com/512/3135/3135768.png', 'rank'),
('prod-3', 'Vortex Rank', 2500, 'The ULTIMATE rank. /fly, custom tag, monthly coins, exclusive discord access, and more!', 'cat-1', 15, 'https://cdn-icons-png.flaticon.com/512/3135/3135755.png', 'rank'),
('prod-4', 'Vortex Key', 100, 'Open the custom Vortex Crate at spawn for extremely rare loot and weapons!', 'cat-2', -1, 'https://cdn-icons-png.flaticon.com/512/2889/2889312.png', 'others'),
('prod-5', 'Mega Coins Package', 300, 'Get 50,000 server coins instantly credited to your in-game balance.', 'cat-3', -1, 'https://cdn-icons-png.flaticon.com/512/272/272525.png', 'others');

-- Insert default global settings
INSERT INTO settings (id, server_name, server_ip, discord_link, server_icon, primary_color, secondary_color, brand_color_1, brand_color_2, brand_name_split, brand_name_first, brand_name_second, hero_bg_url, patron_image_url, rules_bg_url, rules_border_color, discord_order_webhook) VALUES
('global', 'Eternity Hub', 'play.eternityhub.fun', 'https://discord.gg/eternity', 'https://cdn-icons-png.flaticon.com/512/3135/3135755.png', '#9333ea', '#22d3ee', '#9333ea', '#22d3ee', 8, 'Eternity', 'Hub', '', '', '', '#9333ea', '');

-- Insert default rules
INSERT INTO rules (id, title, description, "order") VALUES
('rule-1', 'Fair Play', 'No hacking, cheating, or exploiting client modifications that give unfair advantages.', 1),
('rule-2', 'Respect Others', 'Keep chat clean and friendly. No toxic behavior, harassment, racism, or offensive slurs.', 2),
('rule-3', 'No Griefing / Stealing', 'Do not steal or destroy other players buildings, items, or claimed territories.', 3),
('rule-4', 'Lag Security', 'Do not build massive lag machines, infinite redstone loops, or mob farms designed to lag the tickrate.', 4);

-- Insert default news
INSERT INTO news (id, title, content, author) VALUES
('news-1', 'Season 4 Launch!', 'Welcome to Season 4 of Eternity Hub! We have reset the map with a beautiful new seed, custom structures, a revamped store, and massive gameplay updates! Log on now to claim your free welcome kit.', 'Owner'),
('news-2', 'Staff Application Open', 'We are looking for motivated helpers to join our team! Head over to discord to submit an application if you have experience with moderation.', 'Moderator Manager');

-- Insert default vote links
INSERT INTO vote_links (id, name, url) VALUES
('v-1', 'Planet Minecraft (Vote 1)', 'https://www.planetminecraft.com'),
('v-2', 'MinecraftServers.org (Vote 2)', 'https://minecraftservers.org');

-- Insert default ranks
INSERT INTO ranks (id, name, "order") VALUES
('r-1', 'Owner', 1),
('r-2', 'Admin', 2),
('r-3', 'Developer', 3),
('r-4', 'Moderator', 4),
('r-5', 'Helper', 5);

-- Insert default staff members
INSERT INTO staff (id, ign, uuid, username, rank_id) VALUES
('s-1', 'knightsoul14323', '', 'knightsoul14323', 'r-1'),
('s-2', 'VortexManager', '', 'VortexManager', 'r-2'),
('s-3', 'CodeNinja', '', 'CodeNinja', 'r-3');

-- Insert default whitelisted admin emails
INSERT INTO admin_emails (id, email) VALUES
('ae_1', 'knightsoul14323@gmail.com');


-- ALTER TABLE COMMANDS FOR UPDATING EXISTING DATABASES IN-PLACE:
-- Run these statements in your Supabase SQL Editor if you are updating an existing database:
--
-- ALTER TABLE categories ADD COLUMN IF NOT EXISTS image_url text;
-- ALTER TABLE settings ADD COLUMN IF NOT EXISTS store_banner_url text;
-- ALTER TABLE settings ADD COLUMN IF NOT EXISTS store_welcome_title text;
-- ALTER TABLE settings ADD COLUMN IF NOT EXISTS store_welcome_description text;
-- ALTER TABLE products ADD COLUMN IF NOT EXISTS "order" integer NOT NULL DEFAULT 0;
-- ALTER TABLE products ADD COLUMN IF NOT EXISTS "purchase_options" jsonb DEFAULT '[]'::jsonb;
-- ALTER TABLE settings ADD COLUMN IF NOT EXISTS payment_number_bkash text;
-- ALTER TABLE settings ADD COLUMN IF NOT EXISTS payment_number_nagad text;
-- ALTER TABLE settings ADD COLUMN IF NOT EXISTS payment_number_rocket text;
-- ALTER TABLE settings ADD COLUMN IF NOT EXISTS payment_info_bkash text;
-- ALTER TABLE settings ADD COLUMN IF NOT EXISTS payment_info_nagad text;
-- ALTER TABLE settings ADD COLUMN IF NOT EXISTS payment_info_rocket text;
-- ALTER TABLE settings ADD COLUMN IF NOT EXISTS payment_info_other text;

