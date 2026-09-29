-- ============================================================
-- 16_SystemFixes.sql
-- Fix PaymentLog constraint, update triggers, tối ưu schema
-- Chạy sau 15_DonationsNotifications.sql
-- ============================================================

USE [ZooDatabase]
GO

-- ============================================================
-- FIX 1: PaymentLog.Status constraint thiếu 'Pending'
-- Code C# insert PaymentLog với Status='Pending' nhưng constraint
-- chỉ cho phép ('Success','Failed','Refunded') → crash runtime
-- ============================================================

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_PaymentLog_Status')
BEGIN
    ALTER TABLE PaymentLog DROP CONSTRAINT CK_PaymentLog_Status;
    PRINT N'✅ Đã xóa constraint CK_PaymentLog_Status cũ';
END
GO

ALTER TABLE PaymentLog ADD CONSTRAINT CK_PaymentLog_Status 
    CHECK (Status IN ('Success', 'Failed', 'Refunded', 'Pending'));
PRINT N'✅ Đã tạo constraint CK_PaymentLog_Status mới (thêm Pending)';
GO

-- ============================================================
-- FIX 2: Trigger trg_Proceeds_AutoPaymentLog
-- Cập nhật để handle PaymentStatus = 'Pending' đúng
-- và tránh trùng lặp khi C# code đã tự INSERT PaymentLog
-- ============================================================

CREATE OR ALTER TRIGGER trg_Proceeds_AutoPaymentLog
ON Proceeds
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ tạo PaymentLog khi PaymentStatus = 'Completed' (không phải Pending)
    -- Vì flow QR Payment: C# code sẽ tự quản lý PaymentLog cho Pending records
    INSERT INTO PaymentLog (ProceedId, OrderId, Amount, PaymentMethod, TransactionRef, PaymentDate, Status, Notes)
    SELECT 
        i.ProceedId,
        NULL,
        i.Quantity * i.UnitPrice,
        i.PaymentMethod,
        i.TransactionRef,
        GETDATE(),
        CASE 
            WHEN i.PaymentStatus = 'Completed' THEN 'Success'
            WHEN i.PaymentStatus = 'Failed' THEN 'Failed'
            WHEN i.PaymentStatus = 'Refunded' THEN 'Refunded'
            WHEN i.PaymentStatus = 'Pending' THEN 'Pending'
            ELSE 'Success'
        END,
        N'Tự động ghi từ Proceeds #' + CAST(i.ProceedId AS NVARCHAR(10))
    FROM inserted i;

    PRINT N'⚡ Trigger trg_Proceeds_AutoPaymentLog: Đã ghi PaymentLog';
END
GO
PRINT N'✅ Đã cập nhật Trigger: trg_Proceeds_AutoPaymentLog (handle Pending)';
GO

-- ============================================================
-- FIX 3: Trigger trg_Proceeds_UpdateCapacity - Ngăn bán vượt sức chứa
-- Phiên bản cũ chỉ PRINT cảnh báo, phiên bản mới sẽ ROLLBACK
-- ============================================================

CREATE OR ALTER TRIGGER trg_Proceeds_UpdateCapacity
ON Proceeds
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra sức chứa TRƯỚC khi giảm
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Events e ON i.EventId = e.EventId
        WHERE i.EventId IS NOT NULL AND e.Capacity < i.Quantity
    )
    BEGIN
        RAISERROR(N'❌ LỖI: Sự kiện đã hết chỗ! Không đủ sức chứa cho số vé yêu cầu.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Chỉ xử lý khi có EventId (vé sự kiện, không phải vé thường)
    UPDATE e
    SET e.Capacity = e.Capacity - i.Quantity
    FROM Events e
    INNER JOIN inserted i ON e.EventId = i.EventId
    WHERE i.EventId IS NOT NULL;

    PRINT N'⚡ Trigger trg_Proceeds_UpdateCapacity: Đã cập nhật Capacity';
END
GO
PRINT N'✅ Đã cập nhật Trigger: trg_Proceeds_UpdateCapacity (ngăn bán vượt)';
GO

-- ============================================================
-- FIX 4: Xóa cột thừa PurchaseDate (giữ CreatedAt)
-- Cả 2 cột đều DEFAULT GETDATE() → thừa
-- Không thực hiện DROP cột vì C# code đang dùng PurchaseDate
-- Thay vào đó, đảm bảo cả 2 cột luôn đồng bộ
-- ============================================================

-- Tạo trigger đồng bộ PurchaseDate = CreatedAt
CREATE OR ALTER TRIGGER trg_Proceeds_SyncDates
ON Proceeds
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE p
    SET p.PurchaseDate = p.CreatedAt
    FROM Proceeds p
    INNER JOIN inserted i ON p.ProceedId = i.ProceedId
    WHERE p.PurchaseDate != p.CreatedAt;
END
GO
PRINT N'✅ Đã tạo Trigger đồng bộ PurchaseDate/CreatedAt';
GO

-- ============================================================
-- FIX 5: Index bổ sung cho PaymentLog.TransactionRef
-- Để ConfirmPayment UPDATE theo TransactionRef nhanh hơn
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PaymentLog_TransactionRef')
BEGIN
    CREATE NONCLUSTERED INDEX IX_PaymentLog_TransactionRef ON PaymentLog(TransactionRef);
    PRINT N'✅ Đã tạo index IX_PaymentLog_TransactionRef';
END
GO

-- ============================================================
-- FIX 6: Đánh dấu bảng Orders/OrderItems là deprecated
-- Không xóa ngay vì có thể có dữ liệu cũ
-- Thêm ghi chú vào AuditLog
-- ============================================================

INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
VALUES (
    'SYSTEM', 
    0, 
    'UPDATE', 
    N'Bảng Orders/OrderItems đang active',
    N'Bảng Orders/OrderItems được đánh dấu DEPRECATED - Toàn bộ hệ thống đã chuyển sang dùng Proceeds/PaymentLog'
);
PRINT N'✅ Đã ghi nhận deprecation Orders/OrderItems vào AuditLog';
GO

PRINT N'========================================';
PRINT N'✅ 16_SystemFixes.sql HOÀN TẤT';
PRINT N'========================================';
GO
