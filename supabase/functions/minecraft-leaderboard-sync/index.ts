// Supabase Edge Function: minecraft-leaderboard-sync
// Deploy via: supabase functions deploy minecraft-leaderboard-sync

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.101.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-sync-token",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const syncTokenHeader = req.headers.get("x-sync-token") || req.headers.get("authorization")?.replace("Bearer ", "");
    const expectedToken = Deno.env.get("SUPABASE_SYNC_TOKEN") || "ajlb-sync-token-secret-2026";

    // Authenticate sync token
    if (syncTokenHeader !== expectedToken) {
      return new Response(
        JSON.stringify({ success: false, error: "Unauthorized: Invalid SUPABASE_SYNC_TOKEN" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const payload = await req.json();
    const { leaderboard_type, players } = payload;

    if (!leaderboard_type || !Array.isArray(players)) {
      return new Response(
        JSON.stringify({ success: false, error: "Invalid payload: 'leaderboard_type' and 'players' array required." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase Admin Client using Service Role Key
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const now = new Date().toISOString();
    const formattedRows = players.map((p: any) => ({
      leaderboard_type,
      player_uuid: p.uuid || p.name,
      player_name: p.name,
      score: Number(p.score || 0),
      rank: Number(p.rank || 0),
      updated_at: now
    }));

    const { error } = await supabase
      .from("minecraft_leaderboards")
      .upsert(formattedRows, { onConflict: "leaderboard_type,player_uuid" });

    if (error) {
      return new Response(
        JSON.stringify({ success: false, error: error.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Successfully updated ${formattedRows.length} leaderboard records for '${leaderboard_type}'`,
        updatedCount: formattedRows.length,
        timestamp: now
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ success: false, error: err.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
