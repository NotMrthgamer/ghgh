import dotenv from 'dotenv';
dotenv.config();

export interface LeaderboardConfig {
  mysql: {
    host: string;
    port: number;
    database: string;
    user: string;
    password: string;
    connectionLimit: number;
    connectTimeout: number;
  };
  supabase: {
    url: string;
    key: string;
    table: string;
    syncToken: string;
  };
  sync: {
    intervalSeconds: number;
    batchSize: number;
    metrics: string[];
  };
}

export function loadConfig(): LeaderboardConfig {
  const host = process.env.MYSQL_HOST || '168.119.102.138';
  const port = Number(process.env.MYSQL_PORT || 3306);
  const database = process.env.MYSQL_DATABASE || 's168_MainStore';
  const user = process.env.MYSQL_USER || 'u168_50U0Rj2EOa';
  const password = process.env.MYSQL_PASSWORD ?? 'm@gOsxCyU2.=DaCka@THfhcf';

  const supabaseUrl = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL || 'https://sce6tjpwseiyai5m7nx5ze.supabase.co';
  const supabaseKey = process.env.SUPABASE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.VITE_SUPABASE_ANON_KEY || '';
  const supabaseTable = process.env.SUPABASE_TABLE || 'minecraft_leaderboards';
  const syncToken = process.env.SUPABASE_SYNC_TOKEN || 'ajlb-sync-token-secret-2026';

  const intervalSeconds = Number(process.env.SYNC_INTERVAL_SECONDS || 60);
  const batchSize = Number(process.env.SYNC_BATCH_SIZE || 100);

  return {
    mysql: {
      host,
      port,
      database,
      user,
      password,
      connectionLimit: 5,
      connectTimeout: 5000,
    },
    supabase: {
      url: supabaseUrl,
      key: supabaseKey,
      table: supabaseTable,
      syncToken,
    },
    sync: {
      intervalSeconds,
      batchSize,
      metrics: ['kills', 'deaths', 'money', 'playtime', 'blocks_broken', 'blocks_placed', 'mob_kills', 'votes'],
    },
  };
}
