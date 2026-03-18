-- =============================================================================
-- L100 Demo: AI Inside SQL — Vector / Semantic Search
-- Step 3: DEMO — Traditional LIKE search vs. Semantic/Vector Search
-- =============================================================================
-- Talk track:
--   "This is not an AI app.
--    This is a SQL query — but now it understands meaning, not just keywords."
-- =============================================================================

-- ---------------------------------------------------------------------------
-- PART A — Traditional keyword search  ❌
-- The user types: "slow performance after login"
-- ---------------------------------------------------------------------------

PRINT '--- PART A: Traditional LIKE search ---';

SELECT
    TicketId,
    CustomerName,
    Category,
    TicketText
FROM  dbo.SupportTickets
WHERE TicketText LIKE '%slow%'
   OR TicketText LIKE '%performance%'
   OR TicketText LIKE '%login%';
-- Point out: misses "grinds to a halt", "unresponsive", "lags badly" etc.
GO

-- ---------------------------------------------------------------------------
-- PART B — Semantic / Vector search  ✅
-- We embed the user's search phrase on the fly and measure cosine similarity.
-- Replace <AOAI_ENDPOINT> / <DEPLOYMENT_NAME> as in 02-generate-embeddings.sql
-- ---------------------------------------------------------------------------

PRINT '--- PART B: Semantic / Vector search ---';

DECLARE @search_phrase  NVARCHAR(500) = 'slow performance after login';
DECLARE @aoai_endpoint  NVARCHAR(500) = 'https://<AOAI_ENDPOINT>.openai.azure.com/openai/deployments/<DEPLOYMENT_NAME>/embeddings?api-version=2023-05-15';
DECLARE @json_payload   NVARCHAR(MAX);
DECLARE @response       NVARCHAR(MAX);
DECLARE @query_vector   VECTOR(1536);

-- ① Embed the search phrase
SET @json_payload = JSON_OBJECT('input': @search_phrase);

EXEC sp_invoke_external_rest_endpoint
    @url        = @aoai_endpoint,
    @method     = 'POST',
    @headers    = '{"Content-Type":"application/json"}',
    @credential = [AzureOpenAI_Credential],
    @payload    = @json_payload,
    @response   = @response OUTPUT;

SET @query_vector = CAST(
    JSON_QUERY(
        JSON_QUERY(@response, '$.result.data[0]'),
        '$.embedding'
    ) AS VECTOR(1536)
);

-- ② Rank tickets by cosine similarity (VECTOR_DISTANCE returns distance;
--    lower = closer; flip for similarity score)
SELECT TOP (5)
    TicketId,
    CustomerName,
    Category,
    TicketText,
    ROUND(1 - VECTOR_DISTANCE('cosine', Embedding, @query_vector), 4) AS SimilarityScore
FROM  dbo.SupportTickets
ORDER BY VECTOR_DISTANCE('cosine', Embedding, @query_vector);
-- Point out:
--   * "grinds to a halt" ranked high — same MEANING, different WORDS
--   * No Python, no external vector DB, still T-SQL
GO

-- ---------------------------------------------------------------------------
-- KEY DEMO POINTS (say out loud):
--   1. No Python required
--   2. No external vector database required
--   3. Still plain T-SQL — any DBA can read and maintain this
--   4. Security and auditing work exactly as before
--   5. Existing indexes, permissions, and tooling unchanged
-- ---------------------------------------------------------------------------
