-- =============================================================================
-- L100 Demo: AI Inside SQL — Vector / Semantic Search
-- Setup Script
-- =============================================================================
-- Prerequisites:
--   * Azure SQL Database (General Purpose or Business Critical, or
--     SQL Server 2022 CU9+ with vector preview enabled)
--   * An Azure OpenAI resource with the text-embedding-ada-002 (or
--     text-embedding-3-small) model deployed.
--   * DATABASE SCOPED CREDENTIAL for Azure OpenAI (see comments below).
-- =============================================================================

-- ① Create the demo database (run from master or skip if already created)
-- CREATE DATABASE TechDayDemo;
-- GO
-- USE TechDayDemo;
-- GO

-- ② Enable the vector data type (Azure SQL preview or SQL Server 2025+)
--    Nothing extra needed — VECTOR is a built-in type in Azure SQL.

-- ③ Azure OpenAI authentication
--    We pass the API key via @headers in sp_invoke_external_rest_endpoint.
--    The key is stored in our .env file (never committed to git).

-- ④ Create the support-tickets table with a VECTOR column for embeddings
IF OBJECT_ID('dbo.SupportTickets', 'U') IS NOT NULL
    DROP TABLE dbo.SupportTickets;
GO

CREATE TABLE dbo.SupportTickets (
    TicketId     INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(100)  NOT NULL,
    Category     NVARCHAR(50)   NOT NULL,
    TicketText   NVARCHAR(2000) NOT NULL,
    -- 1536 dimensions = text-embedding-ada-002
    -- 1536 dimensions = text-embedding-3-small (also works)
    Embedding    VECTOR(1536)   NULL
);
GO

-- ⑤ Insert sample support tickets
INSERT INTO dbo.SupportTickets (CustomerName, Category, TicketText) VALUES
('Alice Johnson',   'Performance', 'The application becomes extremely slow after I log in. Pages take over 30 seconds to load.'),
('Bob Smith',       'Performance', 'After signing in, everything grinds to a halt. The dashboard is unresponsive for minutes.'),
('Carol White',     'Error',       'I keep getting a 500 Internal Server Error when I try to submit my order.'),
('David Lee',       'Login',       'I cannot reset my password. The reset email never arrives even after multiple attempts.'),
('Emma Davis',      'Performance', 'Video streaming quality drops significantly and buffers constantly during peak hours.'),
('Frank Miller',    'Billing',     'I was charged twice for the same subscription this month. Please refund the duplicate charge.'),
('Grace Wilson',    'Error',       'The export to PDF feature throws an unhandled exception every time I click the button.'),
('Henry Moore',     'Login',       'Two-factor authentication code is not being accepted despite entering it correctly.'),
('Isabella Taylor', 'Performance', 'The mobile app lags badly when scrolling through large product catalogues.'),
('James Anderson',  'Billing',     'My invoice shows incorrect tax amounts. The total does not match what was quoted.');
GO

PRINT 'Sample tickets inserted. Next: run 02-generate-embeddings.sql';
GO
