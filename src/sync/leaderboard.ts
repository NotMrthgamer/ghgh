import { executeReadOnlyQuery } from './mysql.js';
import { SyncLogger } from './logger.js';

export interface LeaderboardPlayerRecord {
  uuid: string;
  name: string;
  score: number;
  rank: number;
}

export interface MetricQueryResult {
  leaderboard_type: string;
  players: LeaderboardPlayerRecord[];
}

export async function fetchMetricLeaderboard(
  metric: string,
  tables: string[],
  batchSize = 100
): Promise<MetricQueryResult> {
  SyncLogger.info(`Fetching leaderboard data for metric: "${metric}" (limit: ${batchSize})`);

  let rawPlayers: Array<{ uuid?: string; username?: string; name?: string; value?: any }> = [];

  // Strategy 1: Dedicated table search (e.g., ajlb_kills, ajleaderboards_kills, ajlb_playtime)
  const targetTable = tables.find(t => {
    const l = t.toLowerCase();
    return l === `ajlb_${metric}` || 
           l === `ajleaderboards_${metric}` || 
           l.endsWith(`_${metric}`);
  });

  const extrasTable = tables.find(t => {
    const l = t.toLowerCase();
    return l.includes('extras') || l.includes('users') || l.includes('players');
  });

  if (targetTable) {
    try {
      const rawCols = await executeReadOnlyQuery(`SHOW COLUMNS FROM \`${targetTable}\``);
      const colNames = rawCols.map(c => String(c.Field).toLowerCase());
      
      const valCol = colNames.find(c => ['value', 'score', 'amount', 'stat', 'kills', 'balance', 'deaths'].includes(c)) || colNames[1] || 'value';
      const nameCol = colNames.find(c => ['name', 'namecache', 'username', 'player', 'player_name'].includes(c));
      const foreignKey = colNames.find(c => ['user_id', 'uuid', 'id', 'player_id'].includes(c)) || 'user_id';

      if (extrasTable && foreignKey) {
        const [extrasCols] = [await executeReadOnlyQuery(`SHOW COLUMNS FROM \`${extrasTable}\``)];
        const eCols = extrasCols.map(c => String(c.Field).toLowerCase());
        const eNameCol = eCols.find(c => ['namecache', 'name', 'username', 'player_name'].includes(c)) || 'namecache';
        const eUuidCol = eCols.find(c => ['uuid', 'player_uuid'].includes(c));
        const eIdCol = eCols.find(c => ['user_id', 'id', 'uuid'].includes(c)) || 'user_id';

        const uuidSelect = eUuidCol ? `e.\`${eUuidCol}\`` : `''`;

        const sql = `
          SELECT ${uuidSelect} AS uuid, e.\`${eNameCol}\` AS username, s.\`${valCol}\` AS value 
          FROM \`${targetTable}\` s 
          INNER JOIN \`${extrasTable}\` e ON s.\`${foreignKey}\` = e.\`${eIdCol}\` 
          ORDER BY (s.\`${valCol}\` + 0) DESC LIMIT ${batchSize}
        `;

        const rows = await executeReadOnlyQuery(sql);
        if (rows.length > 0) {
          rawPlayers = rows;
        }
      }

      if (rawPlayers.length === 0 && nameCol) {
        const sql = `
          SELECT '' AS uuid, \`${nameCol}\` AS username, \`${valCol}\` AS value 
          FROM \`${targetTable}\` 
          ORDER BY (\`${valCol}\` + 0) DESC LIMIT ${batchSize}
        `;
        rawPlayers = await executeReadOnlyQuery(sql);
      }
    } catch (err: any) {
      SyncLogger.warn(`Query for dedicated table "${targetTable}" failed: ${err.message}`);
    }
  }

  // Strategy 2: Search in unified data table (e.g. ajlb_data)
  if (rawPlayers.length === 0) {
    const unifiedTables = tables.filter(t => t.toLowerCase().includes('ajlb') || t.toLowerCase().includes('ajleaderboards'));
    for (const uTbl of unifiedTables) {
      try {
        const uColsRaw = await executeReadOnlyQuery(`SHOW COLUMNS FROM \`${uTbl}\``);
        const uCols = uColsRaw.map(c => String(c.Field).toLowerCase());
        const boardCol = uCols.find(c => ['board', 'type', 'stat', 'metric', 'category'].includes(c));
        const nameCol = uCols.find(c => ['name', 'namecache', 'username', 'player'].includes(c)) || 'name';
        const valCol = uCols.find(c => ['value', 'score', 'amount', 'stat'].includes(c)) || 'value';

        if (boardCol) {
          const sql = `
            SELECT '' AS uuid, \`${nameCol}\` AS username, \`${valCol}\` AS value 
            FROM \`${uTbl}\` 
            WHERE \`${boardCol}\` LIKE ? 
            ORDER BY (\`${valCol}\` + 0) DESC LIMIT ${batchSize}
          `;
          const rows = await executeReadOnlyQuery(sql, [`%${metric}%`]);
          if (rows.length > 0) {
            rawPlayers = rows;
            break;
          }
        }
      } catch (e) {
        // Ignore
      }
    }
  }

  // Data Sanitization & Deduplication
  const validPlayers = rawPlayers
    .map(p => {
      const name = String(p.username || p.name || '').trim();
      const rawVal = Number(p.value || 0);
      const uuid = String(p.uuid || name || 'player-uuid');
      return {
        uuid: uuid || name,
        name,
        score: isNaN(rawVal) ? 0 : Math.max(0, rawVal)
      };
    })
    .filter(p => p.name.length >= 2 && !p.name.includes('?'));

  // Keep highest score per username
  const map = new Map<string, { uuid: string; name: string; score: number }>();
  for (const p of validPlayers) {
    const existing = map.get(p.name);
    if (!existing || p.score > existing.score) {
      map.set(p.name, p);
    }
  }

  const sortedList = Array.from(map.values()).sort((a, b) => b.score - a.score);

  const formattedPlayers: LeaderboardPlayerRecord[] = sortedList.map((item, index) => ({
    uuid: item.uuid,
    name: item.name,
    score: item.score,
    rank: index + 1
  }));

  SyncLogger.info(`Verified ${formattedPlayers.length} top records for metric "${metric}".`);

  return {
    leaderboard_type: metric,
    players: formattedPlayers
  };
}
