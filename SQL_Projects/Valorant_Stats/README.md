### Who are the top 10 players with the highest K/D ratio?

```sql
SELECT name, tag, kd_ratio, kills, deaths
FROM val_stats
ORDER BY kd_ratio DESC
LIMIT 10;
```

**Output:**

| Row | name           | tag     | kd_ratio | kills  | deaths |
|-----|----------------|---------|----------|--------|--------|
| 1   | PentaStorm     | #NA1    | 6.5      | 26     | 4      |
| 2   | enkil          | #troll  | 5.75     | 23     | 4      |
| 3   | Emo            | #dead   | 3.8      | 19     | 5      |
| 4   | Pappy          | #8263   | 3.29     | 23     | 7      |
| 5   | Dw Final Loka  | #Dwfl   | 3.12     | 25     | 8      |
| 6   | cabbage        | #thew   | 3.1      | 31     | 10     |
| 7   | Rias Gremory   | #pong   | 3.09     | 34     | 11     |
| 8   | RoyaaaL        | #0807   | 3.08     | 40     | 13     |
| 9   | Ic3 W1z4rd2011 | #roblx  | 3        | 18     | 6      |
| 10  | SleepytigerabIe| #NA1    | 3        | 27     | 9      |

---

### Who are the top 10 players with the highest damage per round?

```sql
SELECT name, tag, damage_round
FROM val_stats
ORDER BY damage_round DESC
LIMIT 10;
```

**Output:**

| Row | name            | tag     | damage_round |
|-----|-----------------|---------|---------------|
| 1   | CTT Joaxtacy    | #0000   | 340.6         |
| 2   | PentaStorm      | #NA1    | 332.2         |
| 3   | 13396           | #TR1    | 323.4         |
| 4   | Rias Gremory    | #pong   | 318.4         |
| 5   | Bot Zinboo      | #EUW    | 285.1         |
| 6   | cabbage         | #thew   | 281.1         |
| 7   | LFT Nu3F        | #Chun   | 273.2         |
| 8   | SleepytigerabIe | #NA1    | 271.9         |
| 9   | viNN            | #1337   | 271.8         |
| 10  | RoyaaaL         | #0807   | 266.9         |

---

### Who has the highest headshot percentage among players with at least 500 headshots?

```sql
SELECT name, tag, headshot_percent, headshots
FROM val_stats
WHERE headshots >= 500
ORDER BY headshot_percent DESC
LIMIT 5;
```

**Output:**

| Row | name           | tag     | headshot_percent | headshots |
|-----|----------------|---------|------------------|-----------|
| 1   | volleymeeR     | #2555   | 56.7             | 1,501     |
| 2   | S V M          | #0000   | 56.1             | 1,683     |
| 3   | pls pls pls    | #letme  | 53.7             | 1,655     |
| 4   | 165hz 1ms gsync| #fsync  | 53.3             | 2,219     |
| 5   | 14 yo sisi     | #siege  | 53.2             | 2,038     |

---

### Which guns have the highest total kills across all players?

```sql
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
```

**Output:**

| Row | gun_name  | total_kills |
|-----|-----------|-------------|
| 1   | Vandal    | 28330769    |
| 2   | Phantom   | 9640593     |
| 3   | Spectre   | 2680241     |
| 4   | Operator  | 1424530     |
| 5   | Ghost     | 1182148     |

---

### Who are the top 10 players with the most wins and highest win percentage (min 100 wins)?

```sql
SELECT name, tag, wins, win_percent
FROM val_stats
WHERE wins > 100
ORDER BY win_percent DESC
LIMIT 10;
```

**Output:**

| Row | name          | tag    | wins | win_percent |
|-----|---------------|--------|------|-------------|
| 1   | Roteekuay     | #uwuu  | 108  | 76.1        |
| 2   | trigoncs      | #pro   | 104  | 69.3        |
| 3   | Apla          | #1510  | 107  | 69          |
| 4   | yeanlovefamily| #jun2t | 115  | 65          |
| 5   | t1mo          | #420   | 101  | 64.3        |

---

### Which agents are most picked in each rank and what is their pick percentage?

```sql
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
```

**Output:**

| Row | rating      | agent   | pick_count | total_picks | pick_percent |
|-----|-------------|---------|------------|-------------|--------------|
| 1   | Immortal 1  | Chamber | 24193      | 147611      | 16.39        |
| 2   | Immortal 1  | Reyna   | 17611      | 147611      | 11.93        |
| 3   | Immortal 1  | Jett    | 14561      | 147611      | 9.86         |
| --- | ----------- | ----------- | --------- | ------------ | ------------- | --------------- |
| 4   | Radiant    | Chamber  | 1480       | 7790        | 19.00         |
| 5   | Radiant    | Jett     | 937        | 7790        | 12.03         |
| 6   | Radiant    | Reyna    | 801        | 7790        | 10.28         |
---

### Weapon with highest headshot % among Top 10 players.

```sql
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
ORDER BY total_hits DESC, headshot_percent DESC;
```

**Output:**

| Row | weapon      | total_head   | totatl_hits | headshot_percent |
|-----|-------------|--------------|-------------|------------------|
| 1   | Vandal      | 237          | 801         | 29.59            |
| 2   | Ghost       | 159          | 500         | 31.80            |
| 3   | Spectre     | 55           | 401         | 13.72            |
| 4   | Phantom     | 193          | 400         | 48.75            |
| 5   | Operator    | 66           | 301         | 21.93            |
| --- | ----------- | ----------- | --------- | ------------ | ------------- | --------------- |