-- ============================================================
-- 09_Triggers.sql
-- Tất cả 11 Triggers cho ZooDatabase
-- Chạy sau 08_SchemaOptimization.sql
-- ============================================================

USE [ZooDatabase]
GO

-- ============================================================
-- NHÓM 1: PROCEEDS (Doanh thu bán vé)
-- ============================================================

-- ──────────────────────────────────────────────
-- TRIGGER 1: trg_Proceeds_CalcTotal
-- Tự động tính TotalAmount = Quantity × UnitPrice
-- Khi INSERT hoặc UPDATE trên bảng Proceeds
-- ──────────────────────────────────────────────
CREATE OR ALTER TRIGGER trg_Proceeds_CalcTotal
ON Proceeds
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.TotalAmount = p.Quantity * p.UnitPrice
    FROM Proceeds p
    INNER JOIN inserted i ON p.ProceedId = i.ProceedId;

    PRINT N'⚡ Trigger trg_Proceeds_CalcTotal: Đã tự động tính TotalAmount';
END
GO
PRINT N'✅ Đã tạo Trigger 1: trg_Proceeds_CalcTotal';
GO

-- ──────────────────────────────────────────────
-- TRIGGER 2: trg_Proceeds_UpdateCapacity
-- Giảm Events.Capacity khi bán vé sự kiện
-- Ngăn bán vượt quá sức chứa
-- ──────────────────────────────────────────────
CREATE OR ALTER TRIGGER trg_Proceeds_UpdateCapacity
ON Proceeds
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ xử lý khi có EventId (vé sự kiện, không phải vé thường)
    UPDATE e
    SET e.Capacity = e.Capacity - i.Quantity
    FROM Events e
    INNER JOIN inserted i ON e.EventId = i.EventId
    WHERE i.EventId IS NOT NULL;

    -- Cảnh báo nếu Capacity bị âm (bán quá)
    IF EXISTS (
        SELECT 1 FROM Events e
        INNER JOIN inserted i ON e.EventId = i.EventId
        WHERE i.EventId IS NOT NULL AND e.Capacity < 0
    )
    BEGIN
        PRINT N'⚠️ CẢNH BÁO: Sự kiện đã bán vượt sức chứa!';
    END

    PRINT N'⚡ Trigger trg_Proceeds_UpdateCapacity: Đã cập nhật Capacity';
END
GO
PRINT N'✅ Đã tạo Trigger 2: trg_Proceeds_UpdateCapacity';
GO

-- ──────────────────────────────────────────────
-- TRIGGER 3: trg_Proceeds_AutoPaymentLog
-- Tự động ghi nhật ký thanh toán vào PaymentLog
-- mỗi khi có giao dịch Proceeds mới
-- ──────────────────────────────────────────────
CREATE OR ALTER TRIGGER trg_Proceeds_AutoPaymentLog
ON Proceeds
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO PaymentLog (ProceedId, OrderId, Amount, PaymentMethod, TransactionRef, PaymentDate, Status, Notes)
    SELECT 
        i.ProceedId,
        NULL,                   -- Không liên quan đến Orders
        i.Quantity * i.UnitPrice,
        i.PaymentMethod,
        i.TransactionRef,
        GETDATE(),
        CASE 
            WHEN i.PaymentStatus = 'Completed' THEN 'Success'
            WHEN i.PaymentStatus = 'Failed' THEN 'Failed'
            WHEN i.PaymentStatus = 'Refunded' THEN 'Refunded'
            ELSE 'Success'
        END,
        N'Tự động ghi từ Proceeds #' + CAST(i.ProceedId AS NVARCHAR(10))
    FROM inserted i;

    PRINT N'⚡ Trigger trg_Proceeds_AutoPaymentLog: Đã ghi PaymentLog';
END
GO
PRINT N'✅ Đã tạo Trigger 3: trg_Proceeds_AutoPaymentLog';
GO

-- ============================================================
-- NHÓM 2: ORDERS (Đơn hàng vé thường)
-- ============================================================

-- ──────────────────────────────────────────────
-- TRIGGER 4: trg_OrderItems_RecalcTotal
-- Khi OrderItems thay đổi (INSERT/UPDATE/DELETE)
-- → Tự tính lại Orders.TotalAmount = SUM(Quantity × UnitPrice)
-- ──────────────────────────────────────────────
CREATE OR ALTER TRIGGER trg_OrderItems_RecalcTotal
ON OrderItems
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Lấy tất cả OrderId bị ảnh hưởng (từ cả inserted và deleted)
    DECLARE @AffectedOrders TABLE (OrderId INT);

    INSERT INTO @AffectedOrders (OrderId)
    SELECT DISTINCT OrderId FROM inserted
    UNION
    SELECT DISTINCT OrderId FROM deleted;

    -- Tính lại TotalAmount cho mỗi Order bị ảnh hưởng
    UPDATE o
    SET o.TotalAmount = ISNULL(
        (SELECT SUM(oi.Quantity * oi.UnitPrice) 
         FROM OrderItems oi 
         WHERE oi.OrderId = o.OrderId), 0)
    FROM Orders o
    INNER JOIN @AffectedOrders a ON o.OrderId = a.OrderId;

    PRINT N'⚡ Trigger trg_OrderItems_RecalcTotal: Đã tính lại Orders.TotalAmount';
END
GO
PRINT N'✅ Đã tạo Trigger 4: trg_OrderItems_RecalcTotal';
GO

-- ============================================================
-- NHÓM 3: EVENT BOOKINGS (Đặt chỗ sự kiện)
-- ============================================================

-- ──────────────────────────────────────────────
-- TRIGGER 5: trg_EventBookings_CheckCapacity
-- Kiểm tra sức chứa TRƯỚC khi cho đặt chỗ
-- Nếu SUM(Participants) > Events.Capacity → ROLLBACK
-- ──────────────────────────────────────────────
CREATE OR ALTER TRIGGER trg_EventBookings_CheckCapacity
ON EventBookings
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra từng booking xem có vượt sức chứa không
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Events e ON i.EventId = e.EventId
        WHERE (
            ISNULL((SELECT SUM(eb.Participants) FROM EventBookings eb WHERE eb.EventId = i.EventId), 0) 
            + i.Participants
        ) > e.Capacity
    )
    BEGIN
        RAISERROR(N'❌ LỖI: Sự kiện đã hết chỗ! Không thể đặt thêm.', 16, 1);
        RETURN;
    END

    -- Nếu hợp lệ → INSERT bình thường
    INSERT INTO EventBookings (UserId, EventId, BookingDate, Participants, TotalPrice)
    SELECT UserId, EventId, BookingDate, Participants, TotalPrice
    FROM inserted;

    PRINT N'⚡ Trigger trg_EventBookings_CheckCapacity: Đặt chỗ thành công';
END
GO
PRINT N'✅ Đã tạo Trigger 5: trg_EventBookings_CheckCapacity';
GO

-- ──────────────────────────────────────────────
-- TRIGGER 6: trg_EventBookings_CalcPrice
-- Tự tính TotalPrice = Participants × Events.BasePrice
-- khi không truyền giá trị TotalPrice
-- ──────────────────────────────────────────────
CREATE OR ALTER TRIGGER trg_EventBookings_CalcPrice
ON EventBookings
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE eb
    SET eb.TotalPrice = eb.Participants * e.BasePrice
    FROM EventBookings eb
    INNER JOIN inserted i ON eb.BookingId = i.BookingId
    INNER JOIN Events e ON eb.EventId = e.EventId
    WHERE eb.TotalPrice = 0 OR eb.TotalPrice IS NULL;

    PRINT N'⚡ Trigger trg_EventBookings_CalcPrice: Đã tính TotalPrice';
END
GO
PRINT N'✅ Đã tạo Trigger 6: trg_EventBookings_CalcPrice';
GO

-- ============================================================
-- NHÓM 4: MEMBERSHIP (Thành viên)
-- ============================================================

-- ──────────────────────────────────────────────
-- TRIGGER 7: trg_UserMemberships_AutoEndDate
-- Tự tính EndDate = DATEADD(MONTH, DurationMonths, StartDate)
-- từ bảng MembershipTypes khi INSERT
-- ──────────────────────────────────────────────
CREATE OR ALTER TRIGGER trg_UserMemberships_AutoEndDate
ON UserMemberships
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE um
    SET um.EndDate = DATEADD(MONTH, mt.DurationMonths, um.StartDate)
    FROM UserMemberships um
    INNER JOIN inserted i ON um.UserMembershipId = i.UserMembershipId
    INNER JOIN MembershipTypes mt ON um.MembershipTypeId = mt.MembershipTypeId
    WHERE um.EndDate IS NULL 
       OR um.EndDate = um.StartDate;  -- Khi chưa tính EndDate

    PRINT N'⚡ Trigger trg_UserMemberships_AutoEndDate: Đã tính EndDate tự động';
END
GO
PRINT N'✅ Đã tạo Trigger 7: trg_UserMemberships_AutoEndDate';
GO

-- ============================================================
-- NHÓM 5: AUDIT LOG (Nhật ký thay đổi)
-- ============================================================

-- ──────────────────────────────────────────────
-- TRIGGER 8: trg_Audit_Events
-- Ghi log INSERT/UPDATE/DELETE trên bảng Events
-- ──────────────────────────────────────────────
CREATE OR ALTER TRIGGER trg_Audit_Events
ON Events
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'Events', i.EventId, 'INSERT', NULL,
            N'Title=' + ISNULL(i.Title, '') + N' | Date=' + ISNULL(CONVERT(NVARCHAR(20), i.EventDate, 120), '') + N' | Price=' + ISNULL(CAST(i.BasePrice AS NVARCHAR(20)), '')
        FROM inserted i;
    END

    -- DELETE
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'Events', d.EventId, 'DELETE',
            N'Title=' + ISNULL(d.Title, '') + N' | Date=' + ISNULL(CONVERT(NVARCHAR(20), d.EventDate, 120), '') + N' | Price=' + ISNULL(CAST(d.BasePrice AS NVARCHAR(20)), ''),
            NULL
        FROM deleted d;
    END

    -- UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'Events', i.EventId, 'UPDATE',
            N'Title=' + ISNULL(d.Title, '') + N' | Date=' + ISNULL(CONVERT(NVARCHAR(20), d.EventDate, 120), '') + N' | Price=' + ISNULL(CAST(d.BasePrice AS NVARCHAR(20)), ''),
            N'Title=' + ISNULL(i.Title, '') + N' | Date=' + ISNULL(CONVERT(NVARCHAR(20), i.EventDate, 120), '') + N' | Price=' + ISNULL(CAST(i.BasePrice AS NVARCHAR(20)), '')
        FROM inserted i
        INNER JOIN deleted d ON i.EventId = d.EventId;
    END
END
GO
PRINT N'✅ Đã tạo Trigger 8: trg_Audit_Events';
GO

-- ──────────────────────────────────────────────
-- TRIGGER 9: trg_Audit_Animals
-- Ghi log INSERT/UPDATE/DELETE trên bảng Animals
-- Quan trọng vì đây là trang web về ĐỘNG VẬT
-- ──────────────────────────────────────────────
CREATE OR ALTER TRIGGER trg_Audit_Animals
ON Animals
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'Animals', i.AnimalId, 'INSERT', NULL,
            N'Name=' + ISNULL(i.Name, '') + N' | Species=' + ISNULL(i.Species, '') + N' | Status=' + ISNULL(i.ConservationStatus, '')
        FROM inserted i;
    END

    -- DELETE
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'Animals', d.AnimalId, 'DELETE',
            N'Name=' + ISNULL(d.Name, '') + N' | Species=' + ISNULL(d.Species, '') + N' | Status=' + ISNULL(d.ConservationStatus, ''),
            NULL
        FROM deleted d;
    END

    -- UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'Animals', i.AnimalId, 'UPDATE',
            N'Name=' + ISNULL(d.Name, '') + N' | Species=' + ISNULL(d.Species, '') + N' | Status=' + ISNULL(d.ConservationStatus, ''),
            N'Name=' + ISNULL(i.Name, '') + N' | Species=' + ISNULL(i.Species, '') + N' | Status=' + ISNULL(i.ConservationStatus, '')
        FROM inserted i
        INNER JOIN deleted d ON i.AnimalId = d.AnimalId;
    END
END
GO
PRINT N'✅ Đã tạo Trigger 9: trg_Audit_Animals';
GO

-- ──────────────────────────────────────────────
-- TRIGGER 10: trg_Audit_Users
-- Ghi log thay đổi trên bảng Users (bảo mật)
-- KHÔNG ghi PasswordHash để bảo mật
-- ──────────────────────────────────────────────
CREATE OR ALTER TRIGGER trg_Audit_Users
ON Users
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'Users', i.UserId, 'INSERT', NULL,
            N'Username=' + ISNULL(i.Username, '') + N' | Email=' + ISNULL(i.Email, '') + N' | FullName=' + ISNULL(i.FullName, '') + N' | RoleId=' + CAST(i.RoleId AS NVARCHAR(10))
        FROM inserted i;
    END

    -- DELETE
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'Users', d.UserId, 'DELETE',
            N'Username=' + ISNULL(d.Username, '') + N' | Email=' + ISNULL(d.Email, '') + N' | FullName=' + ISNULL(d.FullName, ''),
            NULL
        FROM deleted d;
    END

    -- UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'Users', i.UserId, 'UPDATE',
            N'Username=' + ISNULL(d.Username, '') + N' | Email=' + ISNULL(d.Email, '') + N' | FullName=' + ISNULL(d.FullName, ''),
            N'Username=' + ISNULL(i.Username, '') + N' | Email=' + ISNULL(i.Email, '') + N' | FullName=' + ISNULL(i.FullName, '')
        FROM inserted i
        INNER JOIN deleted d ON i.UserId = d.UserId;
    END
END
GO
PRINT N'✅ Đã tạo Trigger 10: trg_Audit_Users';
GO

-- ============================================================
-- NHÓM 6: BẢO VỆ DỮ LIỆU
-- ============================================================

-- ──────────────────────────────────────────────
-- TRIGGER 11: trg_Events_PreventDeleteWithBookings
-- Không cho xóa Event nếu đã có bookings hoặc proceeds
-- Bảo vệ dữ liệu liên quan
-- ──────────────────────────────────────────────
CREATE OR ALTER TRIGGER trg_Events_PreventDeleteWithBookings
ON Events
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra có EventBookings liên quan không
    IF EXISTS (
        SELECT 1 FROM EventBookings eb
        INNER JOIN deleted d ON eb.EventId = d.EventId
    )
    BEGIN
        RAISERROR(N'❌ LỖI: Không thể xóa sự kiện đã có đặt chỗ (EventBookings)! Hãy xóa các booking trước.', 16, 1);
        RETURN;
    END

    -- Kiểm tra có Proceeds liên quan không
    IF EXISTS (
        SELECT 1 FROM Proceeds p
        INNER JOIN deleted d ON p.EventId = d.EventId
    )
    BEGIN
        RAISERROR(N'❌ LỖI: Không thể xóa sự kiện đã có doanh thu (Proceeds)! Hãy xóa các proceeds trước.', 16, 1);
        RETURN;
    END

    -- Nếu an toàn → cho phép xóa
    DELETE e
    FROM Events e
    INNER JOIN deleted d ON e.EventId = d.EventId;

    PRINT N'⚡ Trigger trg_Events_PreventDeleteWithBookings: Đã xóa sự kiện an toàn';
END
GO
PRINT N'✅ Đã tạo Trigger 11: trg_Events_PreventDeleteWithBookings';
GO

PRINT N'========================================';
PRINT N'✅ 09_Triggers.sql HOÀN TẤT (11/11 Triggers)';
PRINT N'========================================';
GO
