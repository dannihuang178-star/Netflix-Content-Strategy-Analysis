-- =============================================================================
-- Netflix Content Strategy Analysis — SQL Version
-- =============================================================================
-- Business Question:
-- Netflix's yearly content additions peaked in 2018 and declined afterward.
-- At the same time, TV shows grew from ~21% to over 53% of new releases.
-- Is Netflix shrinking its catalog, or pivoting from a volume-driven,
-- movie-heavy model to a curated, series-first strategy?
--
-- This file contains four query groups that trace the same analytical chain
-- as the Python notebook: volume → type mix → movie duration → geography.
-- Each query ends with a business interpretation.
--
-- Data: Kaggle Netflix Movies and TV Shows (CC0), ~8,800 titles
-- Compatibility: SQLite / PostgreSQL / MySQL (standard SQL)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- SETUP: Load CSV into a table (SQLite example)
-- -----------------------------------------------------------------------------
-- If using SQLite CLI:
--   .mode csv
--   .import netflix_titles.csv netflix_titles
--
-- If using PostgreSQL, create the table first then COPY FROM CSV.
-- The queries below assume the table `netflix_titles` already exists with
-- columns: show_id, type, title, director, cast, country, date_added,
--           release_year, rating, duration, listed_in, description


-- =============================================================================
-- 1. CONTENT VOLUME: How has the total number of releases changed over time?
-- =============================================================================
-- Context: If Netflix is contracting, we expect a steady decline.
-- If it's pivoting, we expect a peak followed by a deliberate reduction.

SELECT
    release_year,
    COUNT(*) AS total_titles,
    COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY release_year) AS yoy_change,
    ROUND(
        (COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY release_year)) * 100.0
        / LAG(COUNT(*)) OVER (ORDER BY release_year),
        1
    ) AS yoy_change_pct
FROM netflix_titles
WHERE release_year BETWEEN 2010 AND 2021
GROUP BY release_year
ORDER BY release_year;

-- Finding: Content additions grew ~6x from 2010 to 2018, then declined.
-- The YoY change column shows the inflection point clearly.
-- But volume alone doesn't tell us whether this is contraction or reallocation.
-- → Next: break down by content type.


-- =============================================================================
-- 2. CONTENT TYPE MIX: Are movies and TV shows declining equally?
-- =============================================================================
-- Context: If both types decline together, it's contraction.
-- If TV shows grow while movies shrink, it's strategic reallocation.

SELECT
    release_year,
    SUM(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END) AS movies,
    SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) AS tv_shows,
    COUNT(*) AS total,
    ROUND(SUM(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS movie_pct,
    ROUND(SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS tv_show_pct
FROM netflix_titles
WHERE release_year BETWEEN 2010 AND 2021
GROUP BY release_year
ORDER BY release_year;

-- Finding: TV shows went from ~21% (2010) to ~53% (2021) of new releases.
-- In absolute terms, TV show additions grew >12x while movies peaked earlier
-- and fell more steeply. The "missing" volume is almost entirely movies.
--
-- So what: The decline is not uniform — it's a deliberate shift from movies
-- to series. A content acquisition team should reallocate budget accordingly.


-- =============================================================================
-- 2b. The crossover point: when did TV shows overtake movies?
-- =============================================================================

SELECT
    release_year,
    SUM(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END) AS movies,
    SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) AS tv_shows,
    CASE
        WHEN SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END)
           > SUM(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END)
        THEN 'TV Shows lead'
        ELSE 'Movies lead'
    END AS dominant_type
FROM netflix_titles
WHERE release_year BETWEEN 2010 AND 2021
GROUP BY release_year
ORDER BY release_year;

-- This shows the exact year TV shows overtook movies in annual additions —
-- the structural inversion that confirms the strategic pivot.


-- =============================================================================
-- 3. MOVIE DURATION: Are the remaining movies changing in character?
-- =============================================================================
-- Context: Shorter movies (docs, stand-up, genre films) suggest Netflix is
-- optimizing for engagement frequency over engagement depth.

-- 3a. Overall average movie duration trend
SELECT
    release_year,
    COUNT(*) AS movie_count,
    ROUND(AVG(CAST(REPLACE(duration, ' min', '') AS INTEGER)), 1) AS avg_duration_min,
    MIN(CAST(REPLACE(duration, ' min', '') AS INTEGER)) AS min_duration,
    MAX(CAST(REPLACE(duration, ' min', '') AS INTEGER)) AS max_duration
FROM netflix_titles
WHERE type = 'Movie'
  AND duration IS NOT NULL
  AND release_year BETWEEN 2011 AND 2021
GROUP BY release_year
ORDER BY release_year;

-- 3b. US vs. overall average movie duration
SELECT
    release_year,
    ROUND(AVG(CAST(REPLACE(duration, ' min', '') AS INTEGER)), 1) AS overall_avg,
    ROUND(AVG(CASE WHEN country = 'United States'
              THEN CAST(REPLACE(duration, ' min', '') AS INTEGER)
              END), 1) AS us_avg,
    ROUND(AVG(CASE WHEN country != 'United States' OR country IS NULL
              THEN CAST(REPLACE(duration, ' min', '') AS INTEGER)
              END), 1) AS non_us_avg
FROM netflix_titles
WHERE type = 'Movie'
  AND duration IS NOT NULL
  AND release_year BETWEEN 2011 AND 2021
GROUP BY release_year
ORDER BY release_year;

-- Finding: Average movie duration dropped ~13 minutes over the decade.
-- US movies were consistently shorter (~85-87 min), suggesting the US catalog
-- already skewed toward shorter formats. The international catalog brought
-- longer features that are now declining.
--
-- So what: For movie acquisitions, prioritize sub-100-minute content.
-- Stand-up specials, documentaries, and genre films fit the platform's
-- revealed preference better than 2.5-hour prestige dramas.


-- =============================================================================
-- 4. GEOGRAPHIC FOOTPRINT: Where is Netflix's content coming from?
-- =============================================================================

-- 4a. Top producing countries (2010–2021)
SELECT
    country,
    COUNT(*) AS title_count
FROM netflix_titles
WHERE release_year BETWEEN 2010 AND 2021
  AND country IS NOT NULL
  AND country != ''
GROUP BY country
ORDER BY title_count DESC
LIMIT 10;

-- 4b. US vs. international share over time
SELECT
    release_year,
    COUNT(*) AS total,
    SUM(CASE WHEN country LIKE '%United States%' THEN 1 ELSE 0 END) AS us_titles,
    COUNT(*) - SUM(CASE WHEN country LIKE '%United States%' THEN 1 ELSE 0 END) AS non_us_titles,
    ROUND(
        (COUNT(*) - SUM(CASE WHEN country LIKE '%United States%' THEN 1 ELSE 0 END)) * 100.0
        / COUNT(*),
        1
    ) AS international_pct
FROM netflix_titles
WHERE release_year BETWEEN 2010 AND 2021
  AND country IS NOT NULL
  AND country != ''
GROUP BY release_year
ORDER BY release_year;

-- Finding: While the US remains the dominant source, India, UK, Japan, and
-- South Korea each contribute significantly. International content that
-- travels well aligns with Netflix's global subscriber growth strategy.


-- =============================================================================
-- SYNTHESIS
-- =============================================================================
-- Three signals, one strategy:
--
--   Volume:   Peaked 2018, declined since          → Fewer titles, deliberately
--   Type mix: TV shows 21% → 53%                   → Movies replaced by series
--   Duration: Avg movie runtime dropped ~13 min     → Remaining movies skew shorter
--
-- Netflix is not contracting. It is pivoting from a volume-driven, movie-heavy
-- model to a curated, series-first model supplemented by shorter-format films.
--
-- Recommendations:
-- 1. Shift acquisition budget toward series with multi-season potential
-- 2. For movies, prioritize sub-100-minute formats (docs, stand-up, genre)
-- 3. Diversify country of origin — international genre content travels well
-- =============================================================================
