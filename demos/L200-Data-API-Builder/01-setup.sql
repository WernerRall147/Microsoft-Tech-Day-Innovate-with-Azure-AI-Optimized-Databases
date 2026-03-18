-- =============================================================================
-- L200 Demo: From SQL to API to App in Minutes
-- Setup Script — Data API Builder on Azure SQL
-- =============================================================================
-- This script re-uses the TechDayDemo database created in L100 and adds:
--   * A Products table (shows JSON column usage)
--   * A stored procedure exposed as a REST action
-- =============================================================================

USE TechDayDemo;
GO

-- ① Products table with a JSON column
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL
    DROP TABLE dbo.Products;
GO

CREATE TABLE dbo.Products (
    ProductId    INT            IDENTITY(1,1) PRIMARY KEY,
    Name         NVARCHAR(200)  NOT NULL,
    Category     NVARCHAR(100)  NOT NULL,
    Price        DECIMAL(10, 2) NOT NULL,
    -- JSON column for flexible attributes (size, colour, specs…)
    Attributes   NVARCHAR(MAX)  NULL CHECK (ISJSON(Attributes) = 1),
    InStock      BIT            NOT NULL DEFAULT 1,
    CreatedAt    DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- ② Helpful index on the JSON 'brand' property (shows JSON indexing)
CREATE INDEX IX_Products_Brand
    ON dbo.Products (Category)
    INCLUDE (Name, Price);
GO

-- ③ Insert sample products
INSERT INTO dbo.Products (Name, Category, Price, Attributes) VALUES
('Surface Pro 10',      'Laptop',  1599.99, '{"brand":"Microsoft","ram_gb":16,"storage_gb":512,"colour":"Platinum"}'),
('Surface Laptop 6',    'Laptop',  1299.99, '{"brand":"Microsoft","ram_gb":32,"storage_gb":1024,"colour":"Black"}'),
('Xbox Series X',       'Console', 499.99,  '{"brand":"Microsoft","storage_gb":1000,"resolution":"4K","fps":120}'),
('Microsoft 365 Basic', 'Software', 69.99,  '{"brand":"Microsoft","licences":1,"term_months":12,"type":"subscription"}'),
('Surface Headphones 2','Audio',   249.99,  '{"brand":"Microsoft","noise_cancelling":true,"battery_hours":20}'),
('Arc Mouse',           'Accessory', 79.99, '{"brand":"Microsoft","wireless":true,"colour":"Platinum"}'),
('Surface Pen',         'Accessory', 99.99, '{"brand":"Microsoft","tilt_support":true,"pressure_points":4096}'),
('HoloLens 2',          'Mixed Reality', 3500.00, '{"brand":"Microsoft","fov_degrees":52,"battery_hours":2.5}');
GO

-- ④ Stored procedure — used as a custom REST action in DAB
IF OBJECT_ID('dbo.usp_GetProductsByCategory', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_GetProductsByCategory;
GO

CREATE PROCEDURE dbo.usp_GetProductsByCategory
    @Category NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ProductId,
        Name,
        Category,
        Price,
        Attributes,
        InStock,
        -- Extract a typed value from the JSON column
        JSON_VALUE(Attributes, '$.brand') AS Brand
    FROM  dbo.Products
    WHERE Category = @Category
      AND InStock   = 1
    ORDER BY Price DESC;
END;
GO

PRINT 'L200 setup complete. Open dab-config.json and follow the README.';
GO
