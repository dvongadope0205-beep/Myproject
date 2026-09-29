=== TRIGGER: trg_OrderItems_RecalcTotal ===

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  TRIGGERS — NHÓM 1: ORDERS (Đơn hàng)                     ║
-- ╚══════════════════════════════════════════════════════════════╝

-- T1. Auto tính TotalAmount khi OrderItems thay đổi
CREATE   TRIGGER trg_OrderItems_RecalcTotal
ON OrderItems
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AffectedOrders TABLE (OrderId INT);
    INSERT INTO @AffectedOrders (OrderId)
    SELECT DISTINCT OrderId FROM inserted
    UNION
    SELECT DISTINCT OrderId FROM deleted;

    UPDATE o
    SET o.TotalAmount = ISNULL(
        (SELECT SUM(oi.Quantity * oi.UnitPrice) FROM OrderItems oi WHERE oi.OrderId = o.OrderId), 0)
    FROM Orders o
    INNER JOIN @AffectedOrders a ON o.OrderId = a.OrderId;
END

GO

=== TRIGGER: trg_Orders_AutoPaymentLog ===
    CREATE   TRIGGER trg_Orders_AutoPaymentLog
    ON Orders
    AFTER INSERT, UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;

        -- 1. For new Orders (INSERT)
        IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO PaymentLog (OrderId, Amount, PaymentMethod, TransactionRef, Status, Notes, type)
            SELECT 
                i.OrderId, 
                i.TotalAmount, 
                i.PaymentMethod, 
                i.TransactionRef, 
                CASE WHEN i.PaymentStatus = 'Completed' THEN 'complete' ELSE 'pending' END,
                N'Auto-logged: Order created',
                CASE 
                    WHEN i.OrderType = 'Membership' THEN 'member'
                    WHEN i.OrderType = 'Shop' THEN 'shop'
                    ELSE 'ticket'
                END
            FROM inserted i;
        END

        -- 2. For updated Orders (UPDATE)
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            UPDATE pl
            SET 
                pl.Status = CASE WHEN i.PaymentStatus = 'Completed' THEN 'complete' ELSE 'pending' END,
                pl.Notes = N'Auto-logged: Order updated to ' + i.PaymentStatus
            FROM PaymentLog pl
            INNER JOIN inserted i ON pl.OrderId = i.OrderId
            INNER JOIN deleted d ON i.OrderId = d.OrderId
            WHERE i.PaymentStatus != d.PaymentStatus;
        END
    END
GO

=== TRIGGER: trg_Orders_UpdateEventCapacity ===

-- T3. Giảm Event Capacity khi bán vé sự kiện (Completed)
CREATE   TRIGGER trg_Orders_UpdateEventCapacity
ON Orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Khi Order type Event chuyển sang Completed
    IF EXISTS (
        SELECT 1 FROM inserted i
        INNER JOIN deleted d ON i.OrderId = d.OrderId
        WHERE i.PaymentStatus = 'Completed' AND d.PaymentStatus != 'Completed'
        AND i.OrderType IN ('Event', 'Ticket')
    )
    BEGIN
        UPDATE e
        SET e.Capacity = e.Capacity - sub.TotalQty
        FROM Events e
        INNER JOIN (
            SELECT oi.EventId, SUM(oi.Quantity) AS TotalQty
            FROM OrderItems oi
            INNER JOIN inserted i ON oi.OrderId = i.OrderId
            INNER JOIN deleted d ON i.OrderId = d.OrderId
            WHERE i.PaymentStatus = 'Completed' AND d.PaymentStatus != 'Completed'
            AND oi.EventId IS NOT NULL
            GROUP BY oi.EventId
        ) sub ON e.EventId = sub.EventId;
    END
END

GO

=== TRIGGER: trg_UserMemberships_AutoEndDate ===

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  TRIGGERS — NHÓM 2: MEMBERSHIP                            ║
-- ╚══════════════════════════════════════════════════════════════╝

-- T4. Auto tính EndDate
CREATE   TRIGGER trg_UserMemberships_AutoEndDate
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
    WHERE um.EndDate IS NULL OR um.EndDate = um.StartDate;
END

GO

=== TRIGGER: trg_Events_PreventDeleteWithOrders ===

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  TRIGGERS — NHÓM 3: EVENTS (Bảo vệ dữ liệu)             ║
-- ╚══════════════════════════════════════════════════════════════╝

-- T5. Không cho xóa Event nếu có đơn hàng
CREATE   TRIGGER trg_Events_PreventDeleteWithOrders
ON Events
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM OrderItems oi
        INNER JOIN deleted d ON oi.EventId = d.EventId
    )
    BEGIN
        RAISERROR(N'Không thể xóa sự kiện đã có đơn hàng! Hãy xóa đơn hàng trước.', 16, 1);
        RETURN;
    END

    DELETE e FROM Events e INNER JOIN deleted d ON e.EventId = d.EventId;
END

GO

=== TRIGGER: trg_Refunds_UpdateOrder ===

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  TRIGGERS — NHÓM 4: REFUNDS                               ║
-- ╚══════════════════════════════════════════════════════════════╝

-- T6. Khi Refund Completed → cập nhật Order.PaymentStatus = 'Refunded'
CREATE   TRIGGER trg_Refunds_UpdateOrder
ON Refunds
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM inserted i
        INNER JOIN deleted d ON i.RefundId = d.RefundId
        WHERE i.Status = 'Completed' AND d.Status != 'Completed'
    )
    BEGIN
        UPDATE o
        SET o.PaymentStatus = 'Refunded'
        FROM Orders o
        INNER JOIN inserted i ON o.OrderId = i.OrderId
        INNER JOIN deleted d ON i.RefundId = d.RefundId
        WHERE i.Status = 'Completed' AND d.Status != 'Completed';
    END
END

GO

=== TRIGGER: trg_Refunds_Notification ===

-- T7. Auto Notification khi có Refund request
CREATE   TRIGGER trg_Refunds_Notification
ON Refunds
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Thông báo Admin
    INSERT INTO Notifications (RecipientRole, RecipientEmail, Title, Message, Type, ReferenceId, IconClass)
    SELECT 'Admin', NULL,
        N'Refund Request #' + CAST(i.RefundId AS NVARCHAR(10)),
        N'Customer requested refund of $' + CAST(i.RefundAmount AS NVARCHAR(20)) +
        N' for Order #' + CAST(i.OrderId AS NVARCHAR(10)),
        'Refund', ISNULL(i.TransactionRef, CAST(i.RefundId AS NVARCHAR(10))), 'fa-undo'
    FROM inserted i;

    -- Thông báo Customer
    INSERT INTO Notifications (RecipientRole, RecipientEmail, Title, Message, Type, ReferenceId, IconClass)
    SELECT 'User', u.Email,
        N'Refund Request Submitted',
        N'Your refund request for $' + CAST(i.RefundAmount AS NVARCHAR(20)) + N' is being reviewed.',
        'Refund', ISNULL(i.TransactionRef, CAST(i.RefundId AS NVARCHAR(10))), 'fa-clock'
    FROM inserted i
    LEFT JOIN Users u ON i.UserId = u.UserId
    WHERE u.Email IS NOT NULL;
END

GO

=== TRIGGER: trg_Audit_Users ===

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  TRIGGERS — NHÓM 5: AUDIT LOG                             ║
-- ╚══════════════════════════════════════════════════════════════╝

-- T8. Audit Users (không ghi PasswordHash)
CREATE   TRIGGER trg_Audit_Users
ON Users
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        INSERT INTO AuditLog (TableName, RecordId, Action, NewValues)
        SELECT 'Users', i.UserId, 'INSERT',
            N'Username=' + ISNULL(i.Username, '') + N' | Email=' + ISNULL(i.Email, '') + N' | FullName=' + ISNULL(i.FullName, '')
        FROM inserted i;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues)
        SELECT 'Users', d.UserId, 'DELETE',
            N'Username=' + ISNULL(d.Username, '') + N' | Email=' + ISNULL(d.Email, '')
        FROM deleted d;

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'Users', i.UserId, 'UPDATE',
            N'Username=' + ISNULL(d.Username, '') + N' | Email=' + ISNULL(d.Email, '') + N' | FullName=' + ISNULL(d.FullName, ''),
            N'Username=' + ISNULL(i.Username, '') + N' | Email=' + ISNULL(i.Email, '') + N' | FullName=' + ISNULL(i.FullName, '')
        FROM inserted i INNER JOIN deleted d ON i.UserId = d.UserId;
END

GO

=== TRIGGER: trg_Audit_Events ===

-- T9. Audit Events
CREATE   TRIGGER trg_Audit_Events
ON Events
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        INSERT INTO AuditLog (TableName, RecordId, Action, NewValues)
        SELECT 'Events', i.EventId, 'INSERT',
            N'Title=' + ISNULL(i.Title, '') + N' | Date=' + ISNULL(CONVERT(NVARCHAR(20), i.EventDate, 120), '')
        FROM inserted i;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues)
        SELECT 'Events', d.EventId, 'DELETE',
            N'Title=' + ISNULL(d.Title, '') + N' | Date=' + ISNULL(CONVERT(NVARCHAR(20), d.EventDate, 120), '')
        FROM deleted d;

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'Events', i.EventId, 'UPDATE',
            N'Title=' + ISNULL(d.Title, ''),
            N'Title=' + ISNULL(i.Title, '')
        FROM inserted i INNER JOIN deleted d ON i.EventId = d.EventId;
END

GO

=== TRIGGER: trg_Audit_Animals ===

-- T10. Audit Animals
CREATE   TRIGGER trg_Audit_Animals
ON Animals
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        INSERT INTO AuditLog (TableName, RecordId, Action, NewValues)
        SELECT 'Animals', i.AnimalId, 'INSERT',
            N'Name=' + ISNULL(i.Name, '') + N' | Species=' + ISNULL(i.Species, '')
        FROM inserted i;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues)
        SELECT 'Animals', d.AnimalId, 'DELETE',
            N'Name=' + ISNULL(d.Name, '') + N' | Species=' + ISNULL(d.Species, '')
        FROM deleted d;

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'Animals', i.AnimalId, 'UPDATE',
            N'Name=' + ISNULL(d.Name, ''),
            N'Name=' + ISNULL(i.Name, '')
        FROM inserted i INNER JOIN deleted d ON i.AnimalId = d.AnimalId;
END

GO

=== TRIGGER: trg_Audit_ShopProducts ===

-- T11. Audit ShopProducts
CREATE   TRIGGER trg_Audit_ShopProducts
ON ShopProducts
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        INSERT INTO AuditLog (TableName, RecordId, Action, NewValues)
        SELECT 'ShopProducts', i.ProductId, 'INSERT',
            N'Name=' + ISNULL(i.Name, '') + N' | Price=' + CAST(i.Price AS NVARCHAR(20))
        FROM inserted i;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues)
        SELECT 'ShopProducts', d.ProductId, 'DELETE',
            N'Name=' + ISNULL(d.Name, '') + N' | Price=' + CAST(d.Price AS NVARCHAR(20))
        FROM deleted d;

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'ShopProducts', i.ProductId, 'UPDATE',
            N'Name=' + ISNULL(d.Name, '') + N' | Price=' + CAST(d.Price AS NVARCHAR(20)) + N' | Active=' + CAST(d.IsActive AS NVARCHAR(1)),
            N'Name=' + ISNULL(i.Name, '') + N' | Price=' + CAST(i.Price AS NVARCHAR(20)) + N' | Active=' + CAST(i.IsActive AS NVARCHAR(1))
        FROM inserted i INNER JOIN deleted d ON i.ProductId = d.ProductId;
END

GO

=== TRIGGER: trg_Audit_Refunds ===

-- T12. Audit Refunds
CREATE   TRIGGER trg_Audit_Refunds
ON Refunds
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        INSERT INTO AuditLog (TableName, RecordId, Action, NewValues)
        SELECT 'Refunds', i.RefundId, 'INSERT',
            N'OrderId=' + CAST(i.OrderId AS NVARCHAR(10)) + N' | Amount=' + CAST(i.RefundAmount AS NVARCHAR(20)) + N' | Status=' + ISNULL(i.Status, '')
        FROM inserted i;

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'Refunds', i.RefundId, 'UPDATE',
            N'Status=' + ISNULL(d.Status, ''),
            N'Status=' + ISNULL(i.Status, '') + N' | ProcessedAt=' + ISNULL(CONVERT(NVARCHAR(20), i.ProcessedAt, 120), 'NULL')
        FROM inserted i INNER JOIN deleted d ON i.RefundId = d.RefundId;
END

GO

=== TRIGGER: trg_OrderItems_MemberExperienceDiscount ===

CREATE TRIGGER dbo.trg_OrderItems_MemberExperienceDiscount
ON dbo.OrderItems
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Avoid infinite recursion in triggers
    IF TRIGGER_NESTLEVEL() > 3
        RETURN;

    -- Update the UnitPrice of Experience items if the customer is an active Member.
    -- Join using ExperienceId foreign key instead of string comparison.
    UPDATE oi
    SET oi.UnitPrice = e.Price * 0.8
    FROM dbo.OrderItems oi
    INNER JOIN inserted i ON oi.OrderItemId = i.OrderItemId
    INNER JOIN dbo.Orders o ON oi.OrderId = o.OrderId
    INNER JOIN dbo.Experience e ON oi.ExperienceId = e.ExperienceId
    WHERE o.UserId IS NOT NULL
      AND oi.UnitPrice <> e.Price * 0.8
      AND EXISTS (
          SELECT 1 
          FROM dbo.UserMemberships um
          WHERE um.UserId = o.UserId
            AND um.Status = 'Active'
            AND um.EndDate >= GETUTCDATE() -- Standardized to UTC date comparison
      );

    -- Recalculate TotalAmount for affected orders to prevent deadlocks.
    -- Group by OrderId from inserted virtual table.
    IF @@ROWCOUNT > 0 OR EXISTS (SELECT 1 FROM inserted)
    BEGIN
        UPDATE o
        SET o.TotalAmount = totals.NewTotal
        FROM dbo.Orders o
        INNER JOIN (
            SELECT oi.OrderId, SUM(oi.Quantity * oi.UnitPrice) AS NewTotal
            FROM dbo.OrderItems oi
            WHERE oi.OrderId IN (SELECT DISTINCT OrderId FROM inserted)
            GROUP BY oi.OrderId
        ) totals ON o.OrderId = totals.OrderId;
    END
END;

GO

