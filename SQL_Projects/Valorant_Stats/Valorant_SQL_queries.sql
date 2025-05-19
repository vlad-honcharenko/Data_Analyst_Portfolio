-- 1.
SELECT name, tag, kd_ratio, kills, deaths
FROM val_stats
ORDER BY kd_ratio DESC
LIMIT 10;
-- 2.
SELECT name, tag, damage_round
FROM val_stats
ORDER BY damage_round DESC
LIMIT 10;
-- 3.
SELECT name, tag, headshot_percent, headshots
FROM val_stats
WHERE headshots >= 500
ORDER BY headshot_percent DESC
LIMIT 5;
-- 4.
SELECT gun_name, SUM(kills) AS total_kills
FROM (
    SELECT gun1_name AS gun_name, gun1_kills AS kills FROM val_stats
    UNION ALL
    SELECT gun2_name, gun2_kills AS kills FROM val_stats
    UNION ALL
    SELECT gun3_name, gun3_kills AS kills FROM val_stats
)
GROUP BY gun_name
ORDER BY total_kills DESC;
-- 5.
SELECT name, tag, wins, win_percent
FROM val_stats
WHERE wins > 100
ORDER BY win_percent DESC
LIMIT 10;
-- 6.
WITH all_agent_picks AS (
    SELECT rating, agent_1 AS agent FROM val_stats
    UNION ALL
    SELECT rating, agent_2 FROM val_stats
    UNION ALL
    SELECT rating, agent_3 FROM val_stats
),
agent_pick_counts AS (
    SELECT rating, agent, COUNT(*) AS pick_count
    FROM all_agent_picks
    WHERE agent IS NOT NULL AND agent != ''
    GROUP BY rating, agent
),
rank_totals AS (
    SELECT rating, COUNT(*) AS total_picks
    FROM all_agent_picks
    WHERE agent IS NOT NULL AND agent != ''
    GROUP BY rating
)
SELECT 
    a.rating,
    a.agent,
    a.pick_count,
    r.total_picks,
    ROUND(100.0 * a.pick_count / r.total_picks, 2) AS pick_percent
FROM agent_pick_counts a
JOIN rank_totals r ON a.rating = r.rating
ORDER BY a.rating, pick_percent DESC;
-- 7.
WITH top_players AS (
    SELECT *
    FROM val_stats
    ORDER BY kd_ratio DESC
    LIMIT 10
),
all_weapon_hits AS (
    SELECT gun1_name AS weapon, gun1_head AS head, gun1_body AS body, gun1_legs AS legs FROM top_players
    UNION ALL
    SELECT gun2_name, gun2_head, gun2_body, gun2_legs FROM top_players
    UNION ALL
    SELECT gun3_name, gun3_head, gun3_body, gun3_legs FROM top_players
),
weapon_hit_summary AS (
    SELECT 
        weapon,
        SUM(head) AS total_head,
        SUM(body) AS total_body,
        SUM(legs) AS total_legs,
        SUM(head + body + legs) AS total_hits
    FROM all_weapon_hits
    WHERE weapon IS NOT NULL AND weapon != ''
    GROUP BY weapon
)
SELECT 
    weapon,
    total_head,
    total_hits,
    ROUND(100.0 * total_head / total_hits, 2) AS headshot_percent
FROM weapon_hit_summary
ORDER BY headshot_percent DESC;