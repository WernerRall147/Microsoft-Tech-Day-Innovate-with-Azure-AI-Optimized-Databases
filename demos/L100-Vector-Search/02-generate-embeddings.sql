-- =============================================================================
-- L100 Demo: AI Inside SQL — Vector / Semantic Search
-- Step 2: Generate embeddings for every ticket using Azure OpenAI
-- =============================================================================
-- This script calls sp_invoke_external_rest_endpoint for each ticket and
-- stores the resulting embedding vector back into the Embedding column.
--
-- Values are pre-filled from .env — ready to run.
-- =============================================================================

DECLARE @aoai_endpoint   NVARCHAR(500) = 'https://<AOAI_ENDPOINT>.openai.azure.com/openai/deployments/<DEPLOYMENT_NAME>/embeddings?api-version=2023-05-15';
DECLARE @aoai_headers    NVARCHAR(500) = '{"api-key":"<AOAI_KEY>"}';
DECLARE @ticket_text     NVARCHAR(2000);
DECLARE @ticket_id       INT;
DECLARE @json_payload    NVARCHAR(MAX);
DECLARE @response        NVARCHAR(MAX);
DECLARE @embedding_json  NVARCHAR(MAX);

-- Cursor over tickets that do not have an embedding yet
DECLARE ticket_cursor CURSOR FOR
    SELECT TicketId, TicketText
    FROM   dbo.SupportTickets
    WHERE  Embedding IS NULL;

OPEN ticket_cursor;
FETCH NEXT FROM ticket_cursor INTO @ticket_id, @ticket_text;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Build the JSON payload for the embedding request
    SET @json_payload = JSON_OBJECT('input': @ticket_text);

    -- Call Azure OpenAI embedding endpoint
    EXEC sp_invoke_external_rest_endpoint
        @url        = @aoai_endpoint,
        @method     = 'POST',
        @headers    = @aoai_headers,
        @payload    = @json_payload,
        @response   = @response OUTPUT;

    -- Extract the embedding array from the response
    SET @embedding_json = (
        SELECT [value]
        FROM   OPENJSON(@response, '$.result.data')
        WHERE  [key] = 0
        -- The embedding array is nested: $.result.data[0].embedding
    );

    -- Parse and store the embedding vector
    UPDATE dbo.SupportTickets
    SET    Embedding = CAST(
               JSON_QUERY(
                   @embedding_json, '$.embedding'
               ) AS VECTOR(1536)
           )
    WHERE  TicketId = @ticket_id;

    FETCH NEXT FROM ticket_cursor INTO @ticket_id, @ticket_text;
END

CLOSE ticket_cursor;
DEALLOCATE ticket_cursor;

PRINT 'Embeddings generated for all tickets. Run 03-demo.sql to see semantic search.';
GO
