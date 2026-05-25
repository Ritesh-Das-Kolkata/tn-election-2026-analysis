-- ============================================================
--  TN 2026 ELECTION — ADVANCED ANALYSIS QUERIES (CORRECTED)
--  All 6 analyses with accurate framing and comments
--  Run these AFTER tn_election_analysis.sql
--  Database: atliq_media
-- ============================================================

--  IMPORTANT NOTE ON TVK:
--  TVK (Tamilaga Vettri Kazhagam) was founded in 2024.
--  It did NOT exist in 2021.
--  Therefore vote share comparisons involving TVK across
--  2021 and 2026 are NOT party-level comparisons.
--  They are CONSTITUENCY-LEVEL comparisons — comparing
--  whoever won in 2021 vs whoever won in 2026 in the same seat.
--  True apples-to-apples party swing is only possible for
--  DMK, AIADMK, INC, PMK who contested BOTH elections.
-- ============================================================

USE atliq_media;


-- ============================================================
-- ANALYSIS 1: VOTE FRAGMENTATION ANALYSIS
-- (Previously called "Swing Analysis" — corrected framing)
-- ============================================================

-- CORRECT FRAMING:
-- This does NOT measure TVK's performance over time.
-- It measures how much the WINNING VOTE SHARE compressed
-- in each constituency between 2021 and 2026.
-- Reason: TVK entered as a new party in 2026, splitting
-- votes 3 ways instead of 2 — so all winners got smaller
-- shares, regardless of which party won.

-- A1.1 — Constituency-level vote share compression (full list)
-- compression = vote_share_2026 - vote_share_2021
-- Negative = 2026 winner was less dominant than 2021 winner
-- This is normal — more parties split the vote in 2026
SELECT
    w26.ac_number,
    w26.constituency,
    w26.region,
    w26.reserved,
    w21.winning_party                                       AS party_2021,
    ROUND(w21.winner_votes/w21.total_votes*100, 1)         AS winner_pct_2021,
    w26.winning_party                                       AS party_2026,
    ROUND(w26.winner_votes/w26.total_votes*100, 1)         AS winner_pct_2026,
    ROUND(
        (w26.winner_votes/w26.total_votes*100) -
        (w21.winner_votes/w21.total_votes*100)
    , 1)                                                    AS vote_share_compression,
    CASE WHEN w21.winning_party = w26.winning_party
         THEN 'Retained' ELSE 'Flipped' END                AS seat_status
FROM winners_2026 w26
JOIN winners_2021 w21 ON w26.ac_number = w21.ac_number
ORDER BY vote_share_compression ASC;


-- A1.2 — How compressed was the vote on average?
-- Overall picture: 2021 winners vs 2026 winners
SELECT
    ROUND(AVG(w21.winner_votes/w21.total_votes*100), 1)    AS avg_winner_pct_2021,
    ROUND(AVG(w26.winner_votes/w26.total_votes*100), 1)    AS avg_winner_pct_2026,
    ROUND(
        AVG(w26.winner_votes/w26.total_votes*100) -
        AVG(w21.winner_votes/w21.total_votes*100)
    , 1)                                                    AS avg_compression,
    COUNT(*)                                                AS total_constituencies
FROM winners_2026 w26
JOIN winners_2021 w21 ON w26.ac_number = w21.ac_number;


-- A1.3 — TRUE party-level swing: DMK in retained seats only
-- This is the only valid apples-to-apples comparison for DMK
-- DMK 2021 vote share vs DMK 2026 vote share — SAME seats
SELECT
    w26.constituency,
    w26.region,
    w26.reserved,
    ROUND(w21.winner_votes/w21.total_votes*100, 1)         AS dmk_pct_2021,
    ROUND(w26.winner_votes/w26.total_votes*100, 1)         AS dmk_pct_2026,
    ROUND(
        (w26.winner_votes/w26.total_votes*100) -
        (w21.winner_votes/w21.total_votes*100)
    , 1)                                                    AS actual_dmk_swing,
    w26.margin                                             AS margin_2026,
    w21.margin                                             AS margin_2021
FROM winners_2026 w26
JOIN winners_2021 w21 ON w26.ac_number = w21.ac_number
WHERE w26.winning_party = 'DMK'
  AND w21.winning_party = 'DMK'
ORDER BY actual_dmk_swing ASC;


-- A1.4 — TRUE party-level swing: AIADMK in retained seats only
SELECT
    w26.constituency,
    w26.region,
    w26.reserved,
    ROUND(w21.winner_votes/w21.total_votes*100, 1)         AS aiadmk_pct_2021,
    ROUND(w26.winner_votes/w26.total_votes*100, 1)         AS aiadmk_pct_2026,
    ROUND(
        (w26.winner_votes/w26.total_votes*100) -
        (w21.winner_votes/w21.total_votes*100)
    , 1)                                                    AS actual_aiadmk_swing,
    w26.margin                                             AS margin_2026,
    w21.margin                                             AS margin_2021
FROM winners_2026 w26
JOIN winners_2021 w21 ON w26.ac_number = w21.ac_number
WHERE w26.winning_party = 'AIADMK'
  AND w21.winning_party = 'AIADMK'
ORDER BY actual_aiadmk_swing ASC;


-- A1.5 — Summary: true swing for parties that contested both years
-- Only DMK, AIADMK, INC, PMK are valid for this comparison
-- TVK is excluded — it did not exist in 2021
SELECT
    w26.winning_party                                       AS party,
    COUNT(*)                                                AS retained_seats,
    ROUND(AVG(w21.winner_votes/w21.total_votes*100), 1)    AS avg_vote_pct_2021,
    ROUND(AVG(w26.winner_votes/w26.total_votes*100), 1)    AS avg_vote_pct_2026,
    ROUND(
        AVG(w26.winner_votes/w26.total_votes*100) -
        AVG(w21.winner_votes/w21.total_votes*100)
    , 1)                                                    AS true_swing_pct,
    ROUND(AVG(w21.margin), 0)                              AS avg_margin_2021,
    ROUND(AVG(w26.margin), 0)                              AS avg_margin_2026
FROM winners_2026 w26
JOIN winners_2021 w21 ON w26.ac_number = w21.ac_number
WHERE w26.winning_party = w21.winning_party
  AND w26.winning_party NOT IN ('TVK')
GROUP BY w26.winning_party
HAVING COUNT(*) >= 2
ORDER BY true_swing_pct ASC;


-- ============================================================
-- ANALYSIS 2: DOMINANCE SCORE
-- Which party won its 2026 seats most convincingly?
-- ============================================================

-- WHY: Seat count alone does not tell the full story.
-- TVK won 108 seats but with avg margin 22,631 — strong.
-- DMK won only 59 seats and with avg margin 9,572 — thin.
-- These are all 2026 numbers only — no cross-year comparison.

-- A2.1 — Dominance scorecard per party (2026 only)
SELECT
    party_2026                                              AS party,
    COUNT(*)                                                AS seats_won,
    ROUND(AVG(margin_2026), 0)                             AS avg_margin,
    ROUND(AVG(vote_share_2026), 1)                         AS avg_vote_share_pct,
    MIN(margin_2026)                                       AS narrowest_win,
    MAX(margin_2026)                                       AS biggest_win,
    SUM(CASE WHEN margin_2026 < 5000  THEN 1 ELSE 0 END)  AS wins_under_5K,
    SUM(CASE WHEN margin_2026 >= 20000 THEN 1 ELSE 0 END)  AS wins_above_20K
FROM winners_2026
GROUP BY party_2026
HAVING COUNT(*) >= 2
ORDER BY avg_margin DESC;


-- A2.2 — Margin distribution: TVK vs DMK vs AIADMK
-- Buckets show how many seats each party won at each margin range
SELECT
    party_2026,
    SUM(CASE WHEN margin_2026 < 5000                   THEN 1 ELSE 0 END) AS razor_thin_under5K,
    SUM(CASE WHEN margin_2026 BETWEEN 5000  AND 19999  THEN 1 ELSE 0 END) AS moderate_5K_20K,
    SUM(CASE WHEN margin_2026 BETWEEN 20000 AND 49999  THEN 1 ELSE 0 END) AS comfortable_20K_50K,
    SUM(CASE WHEN margin_2026 >= 50000                 THEN 1 ELSE 0 END) AS dominant_above50K,
    COUNT(*)                                                                AS total
FROM winners_2026
WHERE party_2026 IN ('TVK','DMK','AIADMK')
GROUP BY party_2026
ORDER BY FIELD(party_2026, 'TVK','DMK','AIADMK');


-- A2.3 — TVK's wins categorised (for Power BI visual)
SELECT
    constituency,
    region,
    reserved,
    margin_2026,
    ROUND(vote_share_2026, 1)                              AS vote_share_pct,
    CASE
        WHEN margin_2026 < 5000  THEN 'Razor thin (under 5K)'
        WHEN margin_2026 < 20000 THEN 'Moderate (5K to 20K)'
        ELSE 'Comfortable (above 20K)'
    END                                                    AS win_type
FROM winners_2026
WHERE party_2026 = 'TVK'
ORDER BY margin_2026 ASC;


-- ============================================================
-- ANALYSIS 3: RESERVED SEAT PERFORMANCE
-- Did SC and ST constituencies break differently from GEN?
-- ============================================================

-- WHY: Tamil Nadu has 44 SC + 2 ST reserved constituencies.
-- TVK won 52.3% of SC seats vs 44.7% of GEN seats.
-- This means TVK's wave was stronger in reserved constituencies
-- than in general seats — an important demographic insight.
-- NOTE: All numbers are 2026 results only.

-- A3.1 — Seats won by party and reservation category (2026)
SELECT
    reserved,
    party_2026,
    COUNT(*)                                               AS seats_won,
    ROUND(COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (PARTITION BY reserved), 1)    AS pct_of_category
FROM winners_2026
GROUP BY reserved, party_2026
ORDER BY FIELD(reserved,'SC','ST','GEN'), seats_won DESC;


-- A3.2 — TVK, DMK, AIADMK win rate by reservation category
SELECT
    reserved                                               AS category,
    COUNT(*)                                               AS total_seats,
    SUM(CASE WHEN party_2026 = 'TVK'    THEN 1 ELSE 0 END) AS tvk_seats,
    ROUND(SUM(CASE WHEN party_2026 = 'TVK' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1)                            AS tvk_win_rate,
    SUM(CASE WHEN party_2026 = 'DMK'    THEN 1 ELSE 0 END) AS dmk_seats,
    ROUND(SUM(CASE WHEN party_2026 = 'DMK' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1)                            AS dmk_win_rate,
    SUM(CASE WHEN party_2026 = 'AIADMK' THEN 1 ELSE 0 END) AS aiadmk_seats,
    ROUND(SUM(CASE WHEN party_2026 = 'AIADMK' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1)                            AS aiadmk_win_rate
FROM winners_2026
GROUP BY reserved
ORDER BY FIELD(reserved,'SC','ST','GEN');


-- A3.3 — Did reserved seats flip at a different rate than GEN?
-- Flip rate comparison: SC vs GEN
SELECT
    w26.reserved                                           AS category,
    COUNT(*)                                               AS total_seats,
    SUM(CASE WHEN w21.winning_party != w26.winning_party
             THEN 1 ELSE 0 END)                            AS flipped,
    SUM(CASE WHEN w21.winning_party = w26.winning_party
             THEN 1 ELSE 0 END)                            AS retained,
    ROUND(SUM(CASE WHEN w21.winning_party != w26.winning_party
             THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1)                            AS flip_rate_pct
FROM winners_2026 w26
JOIN winners_2021 w21 ON w26.ac_number = w21.ac_number
GROUP BY w26.reserved
ORDER BY FIELD(w26.reserved,'SC','ST','GEN');


-- ============================================================
-- ANALYSIS 4: INCUMBENT PERFORMANCE
-- Survival rate per party from 2021 to 2026
-- ============================================================

-- WHY: DMK held 133 seats in 2021 (ruling alliance).
-- It survived in only 40 (30.1%) — historic collapse.
-- BJP lost ALL 4 seats it held — 0% survival.
-- CPI retained 100% — the only party fully intact.
-- TVK does NOT appear in 2021 column — it did not exist then.

-- A4.1 — Survival rate per party (2021 holders)
SELECT
    w21.winning_party                                      AS party_2021,
    COUNT(*)                                               AS seats_held_2021,
    SUM(CASE WHEN w21.winning_party = w26.winning_party
             THEN 1 ELSE 0 END)                            AS seats_retained,
    SUM(CASE WHEN w21.winning_party != w26.winning_party
             THEN 1 ELSE 0 END)                            AS seats_lost,
    ROUND(SUM(CASE WHEN w21.winning_party = w26.winning_party
             THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1)                            AS survival_rate_pct
FROM winners_2021 w21
JOIN winners_2026 w26 ON w21.ac_number = w26.ac_number
GROUP BY w21.winning_party
ORDER BY seats_held_2021 DESC;


-- A4.2 — Where did DMK's 93 lost seats go?
SELECT
    w26.winning_party                                      AS taken_by,
    COUNT(*)                                               AS seats
FROM winners_2021 w21
JOIN winners_2026 w26 ON w21.ac_number = w26.ac_number
WHERE w21.winning_party = 'DMK'
  AND w21.winning_party != w26.winning_party
GROUP BY w26.winning_party
ORDER BY seats DESC;


-- A4.3 — Where did AIADMK's 44 lost seats go?
SELECT
    w26.winning_party                                      AS taken_by,
    COUNT(*)                                               AS seats
FROM winners_2021 w21
JOIN winners_2026 w26 ON w21.ac_number = w26.ac_number
WHERE w21.winning_party = 'AIADMK'
  AND w21.winning_party != w26.winning_party
GROUP BY w26.winning_party
ORDER BY seats DESC;


-- A4.4 — BJP's 4 lost seats — full detail
-- BJP held 4 seats in 2021, won 0 in 2026
SELECT
    w21.constituency,
    w21.region,
    w21.reserved,
    w21.winning_party                                      AS party_2021,
    w21.margin                                             AS margin_2021,
    ROUND(w21.winner_votes/w21.total_votes*100,1)         AS vote_pct_2021,
    w26.winning_party                                      AS party_2026,
    w26.margin                                             AS margin_2026,
    ROUND(w26.winner_votes/w26.total_votes*100,1)         AS vote_pct_2026
FROM winners_2021 w21
JOIN winners_2026 w26 ON w21.ac_number = w26.ac_number
WHERE w21.winning_party = 'BJP'
ORDER BY w21.margin DESC;


-- ============================================================
-- ANALYSIS 5: REGIONAL STRONGHOLDS (2026)
-- Which region belongs to which party?
-- ============================================================

-- WHY: Chennai Metro = TVK fortress (90.6% of 32 seats).
-- AIADMK's only survival zones = North (40.5%) and Central (36.6%).
-- DMK's strongest region = Delta (42.4%).
-- All comparisons are 2026 results — no cross-year assumption.

-- A5.1 — Seats and win rate per party per region (2026)
SELECT
    region,
    COUNT(*)                                               AS total_seats,
    SUM(CASE WHEN party_2026='TVK'    THEN 1 ELSE 0 END)  AS tvk,
    ROUND(SUM(CASE WHEN party_2026='TVK'    THEN 1 ELSE 0 END)*100.0/COUNT(*),1) AS tvk_pct,
    SUM(CASE WHEN party_2026='DMK'    THEN 1 ELSE 0 END)  AS dmk,
    ROUND(SUM(CASE WHEN party_2026='DMK'    THEN 1 ELSE 0 END)*100.0/COUNT(*),1) AS dmk_pct,
    SUM(CASE WHEN party_2026='AIADMK' THEN 1 ELSE 0 END)  AS aiadmk,
    ROUND(SUM(CASE WHEN party_2026='AIADMK' THEN 1 ELSE 0 END)*100.0/COUNT(*),1) AS aiadmk_pct,
    SUM(CASE WHEN party_2026 NOT IN ('TVK','DMK','AIADMK')
             THEN 1 ELSE 0 END)                            AS others
FROM winners_2026
GROUP BY region
ORDER BY FIELD(region,'Chennai Metro','North','Central','Kongu','Delta','South');


-- A5.2 — AIADMK's seat count 2021 vs 2026 by region
-- Shows clearly where AIADMK survived and where it collapsed
SELECT
    region,
    SUM(CASE WHEN y='2021' THEN seats ELSE 0 END)         AS aiadmk_2021,
    SUM(CASE WHEN y='2026' THEN seats ELSE 0 END)         AS aiadmk_2026,
    SUM(CASE WHEN y='2026' THEN seats ELSE 0 END) -
    SUM(CASE WHEN y='2021' THEN seats ELSE 0 END)         AS change
FROM (
    SELECT region, COUNT(*) AS seats, '2021' AS y
    FROM winners_2021 WHERE winning_party = 'AIADMK'
    GROUP BY region
    UNION ALL
    SELECT region, COUNT(*) AS seats, '2026' AS y
    FROM winners_2026 WHERE party_2026 = 'AIADMK'
    GROUP BY region
) t
GROUP BY region
ORDER BY FIELD(region,'Chennai Metro','North','Central','Kongu','Delta','South');


-- A5.3 — Full party breakdown per region (for Power BI)
SELECT
    region,
    party_2026,
    COUNT(*)                                               AS seats,
    ROUND(COUNT(*)*100.0/SUM(COUNT(*)) OVER
        (PARTITION BY region), 1)                         AS pct_of_region
FROM winners_2026
GROUP BY region, party_2026
ORDER BY region, seats DESC;


-- ============================================================
-- ANALYSIS 6: TURNOUT VS MARGIN CORRELATION (2021 only)
-- ============================================================

-- WHY: We use 2021 data only because 2026 turnout is not
-- available in the dataset (intentionally blank per brief).
-- Correlation = -0.161 (weak negative).
-- Higher turnout in 2021 was associated with slightly
-- smaller margins — competitive seats drove more voters out.
-- Low turnout seats tended to be one-sided landslides.

-- A6.1 — Turnout buckets vs average winning margin (2021)
SELECT
    CASE
        WHEN turnout < 70 THEN '1. Below 70%'
        WHEN turnout < 75 THEN '2. 70% to 75%'
        WHEN turnout < 80 THEN '3. 75% to 80%'
        WHEN turnout < 85 THEN '4. 80% to 85%'
        ELSE                    '5. Above 85%'
    END                                                    AS turnout_bucket,
    COUNT(*)                                               AS seats,
    ROUND(AVG(margin), 0)                                  AS avg_margin_2021,
    MIN(margin)                                            AS min_margin,
    MAX(margin)                                            AS max_margin
FROM winners_2021
WHERE turnout IS NOT NULL
GROUP BY turnout_bucket
ORDER BY turnout_bucket;


-- A6.2 — Scatter data: every constituency 2021 turnout vs margin
-- Export this as CSV → use in Power BI scatter chart
SELECT
    ac_number,
    constituency,
    region,
    winning_party                                          AS party_2021,
    turnout                                                AS turnout_2021,
    margin                                                 AS margin_2021,
    ROUND(winner_votes/total_votes*100, 1)                AS vote_share_2021,
    CASE
        WHEN turnout < 70 THEN 'Below 70%'
        WHEN turnout < 75 THEN '70 to 75%'
        WHEN turnout < 80 THEN '75 to 80%'
        WHEN turnout < 85 THEN '80 to 85%'
        ELSE '85% and above'
    END                                                    AS turnout_bucket
FROM winners_2021
WHERE turnout IS NOT NULL
ORDER BY turnout ASC;


-- A6.3 — Average turnout by region (2021)
-- Was high turnout concentrated in specific regions?
SELECT
    region,
    COUNT(*)                                               AS seats,
    ROUND(AVG(turnout), 1)                                AS avg_turnout,
    ROUND(MIN(turnout), 1)                                AS min_turnout,
    ROUND(MAX(turnout), 1)                                AS max_turnout
FROM winners_2021
WHERE turnout IS NOT NULL
GROUP BY region
ORDER BY avg_turnout DESC;


-- ============================================================
-- BONUS: ADVANCED MASTER TABLE FOR POWER BI
-- Export as tn_master_advanced.csv
-- Replace your existing Power BI data source with this file
-- ============================================================

-- NOTE ON vote_share_compression column:
-- This compares 2026 WINNER's vote share vs 2021 WINNER's
-- vote share in the same constituency.
-- It does NOT compare the same party across years.
-- It measures how fragmented the 2026 vote was vs 2021.

SELECT
    w26.ac_number,
    w26.constituency,
    w26.region,
    w26.reserved,

    -- 2026 result
    w26.winning_party                                      AS party_2026,
    w26.winning_candidate                                  AS candidate_2026,
    w26.winner_votes                                       AS winner_votes_2026,
    w26.total_votes                                        AS total_votes_2026,
    w26.margin                                             AS margin_2026,
    ROUND(w26.winner_votes/w26.total_votes*100, 1)        AS vote_share_2026,

    -- 2021 result
    w21.winning_party                                      AS party_2021,
    w21.winning_candidate                                  AS candidate_2021,
    w21.winner_votes                                       AS winner_votes_2021,
    w21.total_votes                                        AS total_votes_2021,
    w21.margin                                             AS margin_2021,
    ROUND(w21.winner_votes/w21.total_votes*100, 1)        AS vote_share_2021,
    w21.turnout                                            AS turnout_2021,

    -- Seat status
    CASE WHEN w21.winning_party = w26.winning_party
         THEN 'Retained' ELSE 'Flipped' END               AS seat_status,

    -- Vote share compression (constituency level — NOT party level)
    -- Negative means 2026 winner was less dominant than 2021 winner
    -- due to more parties splitting the vote
    ROUND(
        (w26.winner_votes/w26.total_votes*100) -
        (w21.winner_votes/w21.total_votes*100)
    , 1)                                                   AS vote_share_compression,

    -- True party swing flag — only valid when same party won both years
    CASE WHEN w21.winning_party = w26.winning_party
         THEN 'True swing (same party)'
         ELSE 'Different parties — not comparable'
    END                                                    AS swing_validity,

    -- Win type in 2026
    CASE
        WHEN w26.margin < 5000  THEN 'Razor thin'
        WHEN w26.margin < 20000 THEN 'Moderate'
        ELSE 'Comfortable'
    END                                                    AS win_type_2026,

    -- Seat type (readable)
    CASE w26.reserved
        WHEN 'SC' THEN 'SC Reserved'
        WHEN 'ST' THEN 'ST Reserved'
        ELSE 'General'
    END                                                    AS seat_type,

    -- Turnout bucket 2021
    CASE
        WHEN w21.turnout < 70 THEN 'Below 70%'
        WHEN w21.turnout < 75 THEN '70 to 75%'
        WHEN w21.turnout < 80 THEN '75 to 80%'
        WHEN w21.turnout < 85 THEN '80 to 85%'
        ELSE '85% and above'
    END                                                    AS turnout_bucket_2021,

    -- Vote share bucket 2026
    CASE
        WHEN ROUND(w26.winner_votes/w26.total_votes*100,1) > 50  THEN 'Above 50%'
        WHEN ROUND(w26.winner_votes/w26.total_votes*100,1) >= 35 THEN '35% to 50%'
        ELSE 'Below 35%'
    END                                                    AS vote_share_bucket

FROM winners_2026 w26
LEFT JOIN winners_2021 w21 ON w26.ac_number = w21.ac_number
ORDER BY w26.ac_number;

-- ============================================================
-- END OF ADVANCED ANALYSIS SCRIPT (CORRECTED VERSION)
-- ============================================================