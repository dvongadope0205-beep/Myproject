USE [ZooDatabase]
GO

-- 1. Add IsSizeEnabled and IsSizeChartEnabled to ShopProducts if they do not exist
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ShopProducts' AND COLUMN_NAME = 'IsSizeEnabled')
BEGIN
    ALTER TABLE dbo.ShopProducts ADD IsSizeEnabled BIT NOT NULL DEFAULT 0;
    PRINT N'✅ Added IsSizeEnabled column to ShopProducts';
END
ELSE
BEGIN
    PRINT N'ℹ️ IsSizeEnabled column already exists in ShopProducts';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ShopProducts' AND COLUMN_NAME = 'IsSizeChartEnabled')
BEGIN
    ALTER TABLE dbo.ShopProducts ADD IsSizeChartEnabled BIT NOT NULL DEFAULT 0;
    PRINT N'✅ Added IsSizeChartEnabled column to ShopProducts';
END
ELSE
BEGIN
    PRINT N'ℹ️ IsSizeChartEnabled column already exists in ShopProducts';
END
GO

-- 2. Enable size and size chart by default for all products in the Apparel category
UPDATE p 
SET p.IsSizeEnabled = 1, p.IsSizeChartEnabled = 1
FROM dbo.ShopProducts p
INNER JOIN dbo.ShopCategories c ON p.CategoryId = c.CategoryId
WHERE c.Name = 'Apparel';
PRINT N'✅ Enabled size and size charts for all existing Apparel products';
GO

-- 3. Verify/Ensure CK_Orders_PaymentMethod constraint allows QR Code and Cash
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Orders_PaymentMethod')
BEGIN
    ALTER TABLE dbo.Orders ADD CONSTRAINT CK_Orders_PaymentMethod 
        CHECK (PaymentMethod IN ('QR Code', 'Transfer', 'Card', 'Cash', 'Online'));
    PRINT N'✅ Created CK_Orders_PaymentMethod constraint';
END
ELSE
BEGIN
    PRINT N'ℹ️ CK_Orders_PaymentMethod constraint already exists';
END

-- 4. Verify/Ensure CK_Orders_PaymentStatus constraint allows Pending and Completed
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Orders_PaymentStatus')
BEGIN
    ALTER TABLE dbo.Orders ADD CONSTRAINT CK_Orders_PaymentStatus 
        CHECK (PaymentStatus IN ('Pending', 'Completed', 'Failed', 'Refunded'));
    PRINT N'✅ Created CK_Orders_PaymentStatus constraint';
END
ELSE
BEGIN
    PRINT N'ℹ️ CK_Orders_PaymentStatus constraint already exists';
END
GO
