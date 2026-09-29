
USE [ZooDatabase]
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Orders') AND name = 'QRScannedAt')
BEGIN
    ALTER TABLE Orders ADD QRScannedAt DATETIME NULL;
    PRINT N'✅ Added QRScannedAt column to Orders table';
END
ELSE
    PRINT N'⏭️ QRScannedAt column already exists';
GO
