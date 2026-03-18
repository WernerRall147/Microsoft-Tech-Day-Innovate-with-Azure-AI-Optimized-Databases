-- =============================================================================
-- L300 Demo: End-to-End RAG App — SQL Orchestrates the AI
-- =============================================================================
-- Talk track:
--   "This is not a chatbot querying SQL.
--    This is SQL *orchestrating* the AI."
--
-- Values are pre-filled from .env — ready to run.
-- =============================================================================

USE TechDayDemo;
GO

-- ===========================================================================
-- STORED PROCEDURE: usp_RAGQuery
-- Encapsulates the full RAG pipeline inside a single T-SQL call.
-- ===========================================================================
IF OBJECT_ID('dbo.usp_RAGQuery', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_RAGQuery;
GO

CREATE PROCEDURE dbo.usp_RAGQuery
    @UserQuestion     NVARCHAR(1000),
    @ConversationId   UNIQUEIDENTIFIER = NULL,   -- optional: link to session
    @TopK             INT              = 3,       -- number of context docs to retrieve
    @SystemPrompt     NVARCHAR(MAX)    = NULL,    -- override the default system prompt
    @Temperature      FLOAT            = 0.1,     -- LLM temperature (0 = deterministic)
    @MaxTokens        INT              = 500       -- maximum tokens in the LLM response
AS
BEGIN
    SET NOCOUNT ON;

    -- -----------------------------------------------------------------------
    -- Configuration
    -- -----------------------------------------------------------------------
    DECLARE @embed_endpoint NVARCHAR(500) =
        'https://<AOAI_ENDPOINT>.openai.azure.com/openai/deployments/<EMBEDDING_DEPLOYMENT>/embeddings?api-version=2023-05-15';

    DECLARE @chat_endpoint  NVARCHAR(500) =
        'https://<AOAI_ENDPOINT>.openai.azure.com/openai/deployments/<CHAT_DEPLOYMENT>/chat/completions?api-version=2024-02-01';

    DECLARE @aoai_headers   NVARCHAR(500) =
        '{"api-key":"<AOAI_KEY>"}';

    -- -----------------------------------------------------------------------
    -- STEP 1: Embed the user question
    -- -----------------------------------------------------------------------
    DECLARE @embed_payload  NVARCHAR(MAX) = JSON_OBJECT('input': @UserQuestion);
    DECLARE @embed_response NVARCHAR(MAX);

    EXEC sp_invoke_external_rest_endpoint
        @url        = @embed_endpoint,
        @method     = 'POST',
        @headers    = @aoai_headers,
        @payload    = @embed_payload,
        @response   = @embed_response OUTPUT;

    DECLARE @question_vector VECTOR(1536) = CAST(
        JSON_QUERY(
            JSON_QUERY(@embed_response, '$.result.data[0]'),
            '$.embedding'
        ) AS VECTOR(1536)
    );

    -- -----------------------------------------------------------------------
    -- STEP 2: Retrieve the most relevant documents (vector search)
    -- -----------------------------------------------------------------------
    CREATE TABLE #TopDocs (
        DocumentId INT,
        Title      NVARCHAR(200),
        Content    NVARCHAR(MAX),
        Department NVARCHAR(100),
        Distance   FLOAT
    );

    INSERT INTO #TopDocs
    SELECT TOP (@TopK)
        DocumentId,
        Title,
        Content,
        Department,
        VECTOR_DISTANCE('cosine', Embedding, @question_vector) AS Distance
    FROM  dbo.KnowledgeBase
    ORDER BY VECTOR_DISTANCE('cosine', Embedding, @question_vector);

    -- -----------------------------------------------------------------------
    -- STEP 3: Build context string from retrieved documents
    -- -----------------------------------------------------------------------
    DECLARE @context NVARCHAR(MAX) = '';

    SELECT @context = @context +
        '--- Document: ' + Title + ' [' + Department + '] ---' + CHAR(10) +
        Content + CHAR(10) + CHAR(10)
    FROM #TopDocs
    ORDER BY Distance;

    -- -----------------------------------------------------------------------
    -- STEP 4: Build chat prompt and call the LLM
    -- -----------------------------------------------------------------------
    -- Use caller-supplied system prompt or fall back to the default
    IF @SystemPrompt IS NULL
        SET @SystemPrompt =
            'You are a helpful assistant. Answer the user''s question using ONLY the ' +
            'context documents provided. If the answer is not in the documents, say ' +
            '"I don''t have that information in my knowledge base." ' +
            'Always cite the document title you used.';

    DECLARE @chat_payload NVARCHAR(MAX) = JSON_OBJECT(
        'messages': JSON_ARRAY(
            JSON_OBJECT('role': 'system',    'content': @SystemPrompt),
            JSON_OBJECT('role': 'user',      'content': 'Context:' + CHAR(10) + @context + CHAR(10) + 'Question: ' + @UserQuestion)
        ),
        'temperature': @Temperature,
        'max_tokens':  @MaxTokens
    );

    DECLARE @chat_response NVARCHAR(MAX);

    EXEC sp_invoke_external_rest_endpoint
        @url        = @chat_endpoint,
        @method     = 'POST',
        @headers    = @aoai_headers,
        @payload    = @chat_payload,
        @response   = @chat_response OUTPUT;

    DECLARE @answer NVARCHAR(MAX) = JSON_VALUE(
        @chat_response,
        '$.result.choices[0].message.content'
    );

    -- -----------------------------------------------------------------------
    -- STEP 5: Store the interaction in audit/chat history
    -- -----------------------------------------------------------------------
    IF @ConversationId IS NULL
        SET @ConversationId = NEWID();

    DECLARE @source_doc_ids NVARCHAR(MAX) = (
        SELECT DocumentId AS id
        FROM   #TopDocs
        FOR    JSON AUTO
    );

    INSERT INTO dbo.ChatHistory (ConversationId, Role, Content, SourceDocIds)
    VALUES (@ConversationId, 'user',      @UserQuestion, NULL),
           (@ConversationId, 'assistant', @answer,       @source_doc_ids);

    -- -----------------------------------------------------------------------
    -- STEP 6: Return the grounded answer + source rows (trust + auditability)
    -- -----------------------------------------------------------------------
    SELECT @answer AS Answer;

    SELECT
        DocumentId,
        Title,
        Department,
        ROUND(1 - Distance, 4) AS RelevanceScore
    FROM #TopDocs
    ORDER BY Distance;

    DROP TABLE #TopDocs;
END;
GO

-- ===========================================================================
-- LIVE DEMO — Run these queries one at a time
-- ===========================================================================

-- DEMO QUERY 1: Performance issue (should match "Slow Application Performance")
EXEC dbo.usp_RAGQuery
    @UserQuestion = 'My application is really slow after I log in. What should I do?';
GO

-- DEMO QUERY 2: Billing question (should match "Refund and Billing Policy")
EXEC dbo.usp_RAGQuery
    @UserQuestion = 'I was charged twice this month. How do I get a refund?';
GO

-- DEMO QUERY 3: Out-of-scope question (should gracefully say "I don't have that")
EXEC dbo.usp_RAGQuery
    @UserQuestion = 'What is the weather forecast for Seattle tomorrow?';
GO

-- ===========================================================================
-- SHOW AUDIT TRAIL — SQL Ledger-style chat history
-- ===========================================================================
SELECT
    ConversationId,
    MessageId,
    Role,
    LEFT(Content, 120) AS ContentPreview,
    SourceDocIds,
    CreatedAt
FROM  dbo.ChatHistory
ORDER BY MessageId DESC;
GO

-- ===========================================================================
-- OPTIONAL ADVANCED FLEX — Row Level Security on AI results
-- ===========================================================================
-- Illustrates that RAG results can be department-scoped automatically
-- by applying RLS to dbo.KnowledgeBase.
--
-- CREATE FUNCTION dbo.fn_DepartmentSecurityPredicate(@Department NVARCHAR(100))
-- RETURNS TABLE
-- WITH SCHEMABINDING
-- AS RETURN
--     SELECT 1 AS fn_result
--     WHERE @Department = SESSION_CONTEXT(N'CurrentDepartment')
--        OR IS_MEMBER('db_owner') = 1;
-- GO
--
-- CREATE SECURITY POLICY KnowledgeBaseRLS
--     ADD FILTER PREDICATE dbo.fn_DepartmentSecurityPredicate(Department)
--     ON dbo.KnowledgeBase
--     WITH (STATE = ON);
-- GO
--
-- EXEC sp_set_session_context N'CurrentDepartment', N'IT Support';
-- EXEC dbo.usp_RAGQuery @UserQuestion = 'How do I reset my password?';
-- -- Finance docs will NOT appear in context — automatically!
