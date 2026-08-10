import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://nkvwglldhghshpdldnly.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5rdndnbGxkaGdoc2hwZGxkbmx5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyOTE2NDEsImV4cCI6MjA5MDg2NzY0MX0.jmLJl59t1FBBAWD6qjAX6VZQt7jgmRTgpYKSYA3Ymwg';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export const getBaseApiUrl = (): string => {
  return '';
};
