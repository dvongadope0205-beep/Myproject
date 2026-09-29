-- ============================================================
-- 14_PaymentQRSupport.sql
-- Cập nhật constraint để hỗ trợ thanh toán QR Code
-- Chạy sau 08_SchemaOptimization.sql
-- ============================================================

USE [ZooDatabase]
GO

-- ============================================================
-- PHẦN 1: Cập nhật PaymentMethod constraint cho bảng Proceeds
-- ============================================================

-- Xóa constraint cũ (chỉ cho phép: Online, Cash, Card, Transfer)
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Proceeds_PaymentMethod')
BEGIN
    ALTER TABLE Proceeds DROP CONSTRAINT CK_Proceeds_PaymentMethod;
    PRINT N'✅ Đã xóa constraint CK_Proceeds_PaymentMethod cũ';
END
GO

-- Tạo constraint mới có thêm 'QR Code'
ALTER TABLE Proceeds ADD CONSTRAINT CK_Proceeds_PaymentMethod 
    CHECK (PaymentMethod IN ('Online', 'Cash', 'Card', 'Transfer', 'QR Code'));
PRINT N'✅ Đã tạo constraint CK_Proceeds_PaymentMethod mới (thêm QR Code)';
GO

-- ============================================================
-- PHẦN 2: Thêm index cho TransactionRef để tìm kiếm nhanh
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Proceeds_TransactionRef')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Proceeds_TransactionRef ON Proceeds(TransactionRef);
    PRINT N'✅ Đã tạo index IX_Proceeds_TransactionRef';
END
GO

PRINT N'========================================';
PRINT N'✅ 14_PaymentQRSupport.sql HOÀN TẤT';
PRINT N'========================================';
GO
