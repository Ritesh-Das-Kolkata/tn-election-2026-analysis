SELECT COUNT(*) FROM `constituency_master`;
SELECT COUNT(*) FROM `tn_2021_results`;
SELECT COUNT(*) FROM `tn_2026_results`;
USE atliq_media;

CREATE OR REPLACE VIEW winners_2021 AS
SELECT
    r.ac_number,
    r.constituency,
    r.region,
    r.reserved,
    r.party AS winning_party,
    r.candidate AS winning_candidate,
    r.votes AS winner_votes,
    SUM(all_r.votes) AS total_votes,
    r.turnout,
    r.votes - (
        SELECT MAX(r2.votes)
        FROM tn_2021_results r2
        WHERE r2.ac_number = r.ac_number AND r2.votes < r.votes
    ) AS margin
FROM tn_2021_results r
JOIN (SELECT ac_number, MAX(votes) AS max_votes FROM tn_2021_results GROUP BY ac_number) mv
    ON r.ac_number = mv.ac_number AND r.votes = mv.max_votes
JOIN tn_2021_results all_r ON all_r.ac_number = r.ac_number
GROUP BY r.ac_number, r.constituency, r.region, r.reserved,
         r.party, r.candidate, r.votes, r.turnout;


CREATE OR REPLACE VIEW winners_2026 AS
SELECT
    r.ac_number,
    r.constituency,
    r.region,
    r.reserved,
    r.party AS winning_party,
    r.candidate AS winning_candidate,
    r.votes AS winner_votes,
    SUM(all_r.votes) AS total_votes,
    r.turnout,
    r.votes - (
        SELECT MAX(r2.votes)
        FROM tn_2026_results r2
        WHERE r2.ac_number = r.ac_number AND r2.votes < r.votes
    ) AS margin
FROM tn_2026_results r
JOIN (SELECT ac_number, MAX(votes) AS max_votes FROM tn_2026_results GROUP BY ac_number) mv
    ON r.ac_number = mv.ac_number AND r.votes = mv.max_votes
JOIN tn_2026_results all_r ON all_r.ac_number = r.ac_number
GROUP BY r.ac_number, r.constituency, r.region, r.reserved,
         r.party, r.candidate, r.votes, r.turnout;
         
SELECT COUNT(*) FROM winners_2021;
  -- should return 234
SELECT COUNT(*) FROM winners_2026;
  -- should return 234
  
  USE atliq_media;

-- ============================================================
-- STORY 1: THE GREAT FLIP
-- ============================================================

-- Q2.1 Overall flip count
SELECT
    SUM(CASE WHEN w21.winning_party = w26.winning_party THEN 1 ELSE 0 END) AS seats_retained,
    SUM(CASE WHEN w21.winning_party <> w26.winning_party THEN 1 ELSE 0 END) AS seats_flipped,
    COUNT(*) AS total_seats,
    ROUND(SUM(CASE WHEN w21.winning_party <> w26.winning_party THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS flip_percentage
FROM winners_2021 w21
JOIN winners_2026 w26 ON w21.ac_number = w26.ac_number;

-- Q2.2 Sankey source data
SELECT
    w21.winning_party AS party_2021,
    w26.winning_party AS party_2026,
    COUNT(*) AS seats
FROM winners_2021 w21
JOIN winners_2026 w26 ON w21.ac_number = w26.ac_number
WHERE w21.winning_party <> w26.winning_party
GROUP BY w21.winning_party, w26.winning_party
ORDER BY seats DESC;

-- Q2.3 Party gains vs losses
SELECT
    party,
    SUM(seats_2021) AS seats_2021,
    SUM(seats_2026) AS seats_2026,
    SUM(seats_2026) - SUM(seats_2021) AS net_change
FROM (
    SELECT winning_party AS party, COUNT(*) AS seats_2021, 0 AS seats_2026
    FROM winners_2021 GROUP BY winning_party
    UNION ALL
    SELECT winning_party AS party, 0 AS seats_2021, COUNT(*) AS seats_2026
    FROM winners_2026 GROUP BY winning_party
) combined
GROUP BY party
ORDER BY seats_2026 DESC;

-- ============================================================
-- STORY 2: THE GEOGRAPHIC SWEEP
-- ============================================================

-- Q1.1a Seats by region 2021
SELECT region,
    SUM(CASE WHEN winning_party = 'DMK'    THEN 1 ELSE 0 END) AS DMK,
    SUM(CASE WHEN winning_party = 'AIADMK' THEN 1 ELSE 0 END) AS AIADMK,
    SUM(CASE WHEN winning_party = 'INC'    THEN 1 ELSE 0 END) AS INC,
    SUM(CASE WHEN winning_party = 'PMK'    THEN 1 ELSE 0 END) AS PMK,
    SUM(CASE WHEN winning_party = 'VCK'    THEN 1 ELSE 0 END) AS VCK,
    SUM(CASE WHEN winning_party = 'BJP'    THEN 1 ELSE 0 END) AS BJP,
    COUNT(*) AS total_seats
FROM winners_2021
GROUP BY region
ORDER BY FIELD(region,'Chennai Metro','North','Central','Kongu','Delta','South');

-- Q1.1b Seats by region 2026
SELECT region,
    SUM(CASE WHEN winning_party = 'TVK'    THEN 1 ELSE 0 END) AS TVK,
    SUM(CASE WHEN winning_party = 'DMK'    THEN 1 ELSE 0 END) AS DMK,
    SUM(CASE WHEN winning_party = 'AIADMK' THEN 1 ELSE 0 END) AS AIADMK,
    SUM(CASE WHEN winning_party = 'INC'    THEN 1 ELSE 0 END) AS INC,
    SUM(CASE WHEN winning_party = 'PMK'    THEN 1 ELSE 0 END) AS PMK,
    SUM(CASE WHEN winning_party = 'VCK'    THEN 1 ELSE 0 END) AS VCK,
    COUNT(*) AS total_seats
FROM winners_2026
GROUP BY region
ORDER BY FIELD(region,'Chennai Metro','North','Central','Kongu','Delta','South');

-- Q1.2 Regional net swing
SELECT region, party,
    SUM(seats_2021) AS seats_2021,
    SUM(seats_2026) AS seats_2026,
    SUM(seats_2026) - SUM(seats_2021) AS net_swing
FROM (
    SELECT region, winning_party AS party, COUNT(*) AS seats_2021, 0 AS seats_2026
    FROM winners_2021 GROUP BY region, winning_party
    UNION ALL
    SELECT region, winning_party AS party, 0 AS seats_2021, COUNT(*) AS seats_2026
    FROM winners_2026 GROUP BY region, winning_party
) t
GROUP BY region, party
ORDER BY region, net_swing DESC;

-- ============================================================
-- STORY 3: THE FRAGMENTED MANDATE
-- ============================================================

-- Q6.1 Average margin comparison
SELECT '2021' AS election_year,
    ROUND(AVG(margin), 0) AS avg_margin,
    MIN(margin) AS min_margin,
    MAX(margin) AS max_margin
FROM winners_2021
UNION ALL
SELECT '2026',
    ROUND(AVG(margin), 0),
    MIN(margin),
    MAX(margin)
FROM winners_2026;

-- Q6.2 Vote share buckets 2026
SELECT
    SUM(CASE WHEN ROUND(winner_votes / total_votes * 100, 1) > 50  THEN 1 ELSE 0 END) AS won_above_50pct,
    SUM(CASE WHEN ROUND(winner_votes / total_votes * 100, 1) BETWEEN 35 AND 50 THEN 1 ELSE 0 END) AS won_35_to_50pct,
    SUM(CASE WHEN ROUND(winner_votes / total_votes * 100, 1) < 35  THEN 1 ELSE 0 END) AS won_below_35pct,
    COUNT(*) AS total
FROM winners_2026;

-- Q6.3 Vote share buckets 2021 vs 2026
SELECT '2021' AS year,
    SUM(CASE WHEN ROUND(winner_votes/total_votes*100,1) > 50  THEN 1 ELSE 0 END) AS above_50,
    SUM(CASE WHEN ROUND(winner_votes/total_votes*100,1) BETWEEN 35 AND 50 THEN 1 ELSE 0 END) AS btw_35_50,
    SUM(CASE WHEN ROUND(winner_votes/total_votes*100,1) < 35  THEN 1 ELSE 0 END) AS below_35
FROM winners_2021
UNION ALL
SELECT '2026',
    SUM(CASE WHEN ROUND(winner_votes/total_votes*100,1) > 50  THEN 1 ELSE 0 END),
    SUM(CASE WHEN ROUND(winner_votes/total_votes*100,1) BETWEEN 35 AND 50 THEN 1 ELSE 0 END),
    SUM(CASE WHEN ROUND(winner_votes/total_votes*100,1) < 35  THEN 1 ELSE 0 END)
FROM winners_2026;

-- Q6.4 Top 10 closest wins 2026
SELECT ac_number, constituency, region, winning_party,
    winner_votes, total_votes, margin,
    ROUND(winner_votes / total_votes * 100, 1) AS vote_share_pct
FROM winners_2026
ORDER BY margin ASC LIMIT 10;

-- ============================================================
-- BONUS: POWER BI MASTER TABLE  ← most important export
-- ============================================================
SELECT
    w26.ac_number, w26.constituency, w26.region, w26.reserved,
    w26.winning_party AS party_2026,
    w26.winning_candidate AS candidate_2026,
    w26.winner_votes AS winner_votes_2026,
    w26.total_votes AS total_votes_2026,
    w26.margin AS margin_2026,
    ROUND(w26.winner_votes / w26.total_votes * 100, 1) AS vote_share_2026,
    w21.winning_party AS party_2021,
    w21.winning_candidate AS candidate_2021,
    w21.winner_votes AS winner_votes_2021,
    w21.total_votes AS total_votes_2021,
    w21.margin AS margin_2021,
    ROUND(w21.winner_votes / w21.total_votes * 100, 1) AS vote_share_2021,
    w21.turnout AS turnout_2021,
    CASE WHEN w21.winning_party = w26.winning_party THEN 'Retained' ELSE 'Flipped' END AS seat_status,
    CASE
        WHEN ROUND(w26.winner_votes / w26.total_votes * 100, 1) > 50  THEN 'Above 50%'
        WHEN ROUND(w26.winner_votes / w26.total_votes * 100, 1) >= 35 THEN '35% to 50%'
        ELSE 'Below 35%'
    END AS vote_share_bucket
FROM winners_2026 w26
LEFT JOIN winners_2021 w21 ON w26.ac_number = w21.ac_number
ORDER BY w26.ac_number;