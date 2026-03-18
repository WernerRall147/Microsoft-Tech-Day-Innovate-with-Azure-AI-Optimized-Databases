-- =============================================================================
-- L300 Demo: RAG in SQL — Step 2
-- Generate embeddings for knowledge base documents
-- =============================================================================
-- Reuses the AzureOpenAI_Credential created in L100.
-- Values are pre-filled from .env — ready to run.
-- =============================================================================

USE TechDayDemo;
GO

DECLARE @aoai_endpoint  NVARCHAR(500) = 'https://<AOAI_ENDPOINT>.openai.azure.com/openai/deployments/<DEPLOYMENT_NAME>/embeddings?api-version=2023-05-15';
DECLARE @aoai_headers   NVARCHAR(500) = '{"api-key":"<AOAI_KEY>"}';
DECLARE @doc_id         INT;
DECLARE @doc_content    NVARCHAR(MAX);
DECLARE @json_payload   NVARCHAR(MAX);
DECLARE @response       NVARCHAR(MAX);

DECLARE doc_cursor CURSOR FOR
    SELECT DocumentId, Content
    FROM   dbo.KnowledgeBase
    WHERE  Embedding IS NULL;

OPEN doc_cursor;
FETCH NEXT FROM doc_cursor INTO @doc_id, @doc_content;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @json_payload = JSON_OBJECT('input': @doc_content);

    EXEC sp_invoke_external_rest_endpoint
        @url        = @aoai_endpoint,
        @method     = 'POST',
        @headers    = @aoai_headers,
        @payload    = @json_payload,
        @response   = @response OUTPUT;

    UPDATE dbo.KnowledgeBase
    SET    Embedding = CAST(
               JSON_QUERY(
                   JSON_QUERY(@response, '$.result.data[0]'),
                   '$.embedding'
               ) AS VECTOR(1536)
           )
    WHERE  DocumentId = @doc_id;

    FETCH NEXT FROM doc_cursor INTO @doc_id, @doc_content;
END

CLOSE doc_cursor;
DEALLOCATE doc_cursor;

PRINT 'Document embeddings generated. Run 03-rag-demo.sql for the live demo.';
GO
