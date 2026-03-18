-- =============================================================================
-- L200 Demo: Data API Builder — SQL bonus queries
-- Show SQL features that surface as API capabilities (live in SSMS)
-- =============================================================================

USE TechDayDemo;
GO

-- ---------------------------------------------------------------------------
-- 1. Show the Products table structure — includes the JSON column
-- ---------------------------------------------------------------------------
SELECT
    ProductId,
    Name,
    Category,
    Price,
    Attributes,        -- raw JSON
    InStock
FROM dbo.Products;
GO

-- ---------------------------------------------------------------------------
-- 2. Query individual JSON properties using JSON_VALUE
--    "The database understands the document — not just the column"
-- ---------------------------------------------------------------------------
SELECT
    ProductId,
    Name,
    Price,
    JSON_VALUE(Attributes, '$.brand')        AS Brand,
    JSON_VALUE(Attributes, '$.ram_gb')       AS RAM_GB,
    JSON_VALUE(Attributes, '$.colour')       AS Colour
FROM  dbo.Products
WHERE Category = 'Laptop';
GO

-- ---------------------------------------------------------------------------
-- 3. Filter using JSON_VALUE — same as a REST ?$filter call
--    Equivalent to: GET /api/Product?$filter=attributes/brand eq 'Microsoft'
-- ---------------------------------------------------------------------------
SELECT
    Name,
    Price,
    Attributes
FROM  dbo.Products
WHERE JSON_VALUE(Attributes, '$.noise_cancelling') = 'true';
GO

-- ---------------------------------------------------------------------------
-- 4. Show that permissions are SQL-based (Row Level Security preview)
--    Point: "Security is not reimplemented in the API layer — it lives in SQL"
-- ---------------------------------------------------------------------------
-- (Illustrative — not run live, just walk through the concept)
-- CREATE SECURITY POLICY ProductInStockPolicy
--     ADD FILTER PREDICATE dbo.fn_InStockFilter(InStock)
--     ON dbo.Products
--     WITH (STATE = ON);
-- The API automatically respects this — zero config change in DAB.
GO

-- ---------------------------------------------------------------------------
-- KEY POINTS TO SAY:
--   * "We didn't replace SQL with a service — we turned SQL into a service."
--   * No backend code written
--   * No ORM mapping
--   * Security still enforced at the SQL layer
--   * REST and GraphQL from one config file
-- ---------------------------------------------------------------------------
