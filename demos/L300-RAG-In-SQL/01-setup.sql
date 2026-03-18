-- =============================================================================
-- L300 Demo: End-to-End RAG App with AI Orchestrated Inside SQL
-- Setup Script
-- =============================================================================
-- This script sets up the knowledge base and chat history tables needed for
-- the Retrieval-Augmented Generation (RAG) demo.
--
-- It builds on TechDayDemo created in L100 / L200.
-- =============================================================================

USE TechDayDemo;
GO

-- ① Knowledge base — documents that the AI will search over
IF OBJECT_ID('dbo.KnowledgeBase', 'U') IS NOT NULL
    DROP TABLE dbo.KnowledgeBase;
GO

CREATE TABLE dbo.KnowledgeBase (
    DocumentId   INT            IDENTITY(1,1) PRIMARY KEY,
    Title        NVARCHAR(200)  NOT NULL,
    Content      NVARCHAR(MAX)  NOT NULL,
    Department   NVARCHAR(100)  NOT NULL,
    -- Row Level Security column — each doc belongs to a department
    Embedding    VECTOR(1536)   NULL,
    LastUpdated  DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- ② Chat history — SQL as the audit trail for all AI interactions
IF OBJECT_ID('dbo.ChatHistory', 'U') IS NOT NULL
    DROP TABLE dbo.ChatHistory;
GO

CREATE TABLE dbo.ChatHistory (
    ConversationId  UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    MessageId       INT              IDENTITY(1,1) PRIMARY KEY,
    Role            NVARCHAR(20)     NOT NULL CHECK (Role IN ('user','assistant','system')),
    Content         NVARCHAR(MAX)    NOT NULL,
    SourceDocIds    NVARCHAR(MAX)    NULL,   -- JSON array of DocumentId used as context
    CreatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- ③ Seed the knowledge base with realistic policy/product documents
INSERT INTO dbo.KnowledgeBase (Title, Department, Content) VALUES
(
    'Password Reset Policy',
    'IT Support',
    'Users can reset their password via the self-service portal at https://aka.ms/sspr. ' +
    'If the portal is unavailable, users should contact the IT helpdesk on extension 1234. ' +
    'Passwords must be at least 12 characters, include uppercase, lowercase, digits, and symbols. ' +
    'Password resets are logged and monitored for security compliance.'
),
(
    'Slow Application Performance — Troubleshooting Guide',
    'IT Support',
    'If the application is slow after login, first clear the browser cache and cookies. ' +
    'Check whether the issue is isolated to one browser or occurs across all browsers. ' +
    'If the issue persists, collect a performance trace using the built-in diagnostics tool and submit ticket to Level 2 support. ' +
    'Known issue: Performance degrades on Internet Explorer; recommend using Edge or Chrome.'
),
(
    'Azure SQL Pricing Tiers',
    'Sales',
    'Azure SQL Database is available in three primary tiers: ' +
    'General Purpose (best for most workloads, 2–96 vCores, up to 4TB), ' +
    'Business Critical (mission-critical with in-memory OLTP, up to 128 vCores), and ' +
    'Hyperscale (up to 100TB, rapid scaling, independent compute/storage). ' +
    'Pricing is per-vCore-hour. Dev/Test pricing is available for non-production workloads.'
),
(
    'Refund and Billing Policy',
    'Finance',
    'Duplicate charges will be refunded within 5–7 business days upon submission of a support ticket with the transaction IDs. ' +
    'Subscription refunds are prorated for unused days in the billing cycle. ' +
    'International transactions may take up to 10 business days due to currency conversion. ' +
    'Contact billing@techday.example.com for escalations.'
),
(
    'Product Warranty and Returns',
    'Customer Success',
    'Hardware products carry a 1-year limited warranty. ' +
    'Surface devices qualify for Microsoft Complete extended warranty. ' +
    'Returns are accepted within 30 days of purchase with original packaging. ' +
    'Defective units are replaced within 3–5 business days after receipt of the returned item.'
);
GO

PRINT 'Knowledge base seeded. Run 02-generate-embeddings.sql to vectorise the documents.';
GO
