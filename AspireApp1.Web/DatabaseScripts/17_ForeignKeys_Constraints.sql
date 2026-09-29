-- ============================================================
-- 17_ForeignKeys_Constraints.sql
-- Bổ sung khóa ngoại (FK) cho các bảng mới
-- Cập nhật CASCADE rules cho toàn bộ hệ thống
-- Chạy sau 16_SystemFixes.sql
-- ============================================================

USE [ZooDatabase]
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN 1: KHÓA NGOẠI CHO CÁC BẢNG MỚI (THIẾU FK)          ║
-- ║  Inquiries, GroupRequests, EventSupportLogs, Donations      ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ──────────────────────────────────────────────
-- 1a. Inquiries.ResolvedBy → Employees.EmployeeId
-- Khi xóa Employee: SET NULL (inquiry vẫn giữ, chỉ mất thông tin ai resolve)
-- ──────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Inquiries_Employees')
BEGIN
    ALTER TABLE Inquiries
    ADD CONSTRAINT FK_Inquiries_Employees
    FOREIGN KEY (ResolvedBy) REFERENCES Employees(EmployeeId)
    ON DELETE SET NULL
    ON UPDATE CASCADE;
    PRINT N'✅ FK: Inquiries.ResolvedBy → Employees (ON DELETE SET NULL)';
END
GO

-- ──────────────────────────────────────────────
-- 1b. GroupRequests.ProcessedBy → Employees.EmployeeId
-- Khi xóa Employee: SET NULL
-- ──────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_GroupRequests_Employees')
BEGIN
    ALTER TABLE GroupRequests
    ADD CONSTRAINT FK_GroupRequests_Employees
    FOREIGN KEY (ProcessedBy) REFERENCES Employees(EmployeeId)
    ON DELETE SET NULL
    ON UPDATE CASCADE;
    PRINT N'✅ FK: GroupRequests.ProcessedBy → Employees (ON DELETE SET NULL)';
END
GO

-- ──────────────────────────────────────────────
-- 1c. EventSupportLogs.ResolvedBy → Employees.EmployeeId
-- Khi xóa Employee: SET NULL
-- ──────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_EventSupportLogs_Employees')
BEGIN
    ALTER TABLE EventSupportLogs
    ADD CONSTRAINT FK_EventSupportLogs_Employees
    FOREIGN KEY (ResolvedBy) REFERENCES Employees(EmployeeId)
    ON DELETE SET NULL
    ON UPDATE CASCADE;
    PRINT N'✅ FK: EventSupportLogs.ResolvedBy → Employees (ON DELETE SET NULL)';
END
GO

-- ──────────────────────────────────────────────
-- 1d. Donations — Thêm cột UserId liên kết user đăng nhập
-- Cho phép theo dõi donation của user đã đăng ký
-- Khi xóa User: SET NULL (donation vẫn giữ)
-- ──────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Donations') AND name = 'UserId')
BEGIN
    ALTER TABLE Donations ADD UserId INT NULL;
    PRINT N'✅ Đã thêm cột UserId vào Donations';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Donations_Users')
BEGIN
    ALTER TABLE Donations
    ADD CONSTRAINT FK_Donations_Users
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
    ON DELETE SET NULL
    ON UPDATE CASCADE;
    PRINT N'✅ FK: Donations.UserId → Users (ON DELETE SET NULL)';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN 2: CẬP NHẬT CASCADE RULES CHO CÁC FK HIỆN TẠI       ║
-- ║  Xóa FK cũ (không có cascade) → Tạo lại FK mới (có cascade)║
-- ╚══════════════════════════════════════════════════════════════╝

-- ──────────────────────────────────────────────
-- 2a. Users.RoleId → Roles.RoleId
-- Khi xóa Role: NO ACTION (không cho xóa Role nếu còn User dùng)
-- Khi update RoleId: CASCADE (cập nhật theo)
-- ──────────────────────────────────────────────
-- Tìm tên FK cũ và xóa
DECLARE @fkName NVARCHAR(200);

-- Users → Roles
SELECT @fkName = fk.name 
FROM sys.foreign_keys fk 
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID('Users') 
  AND fkc.parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'RoleId')
  AND fk.name != 'FK_Users_Roles_Cascade';

IF @fkName IS NOT NULL
BEGIN
    EXEC('ALTER TABLE Users DROP CONSTRAINT [' + @fkName + ']');
    PRINT N'✅ Đã xóa FK cũ: ' + @fkName;
END

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Users_Roles_Cascade')
BEGIN
    ALTER TABLE Users
    ADD CONSTRAINT FK_Users_Roles_Cascade
    FOREIGN KEY (RoleId) REFERENCES Roles(RoleId)
    ON DELETE NO ACTION
    ON UPDATE CASCADE;
    PRINT N'✅ FK: Users.RoleId → Roles (ON UPDATE CASCADE, ON DELETE NO ACTION)';
END
GO

-- ──────────────────────────────────────────────
-- 2b. UserMemberships.UserId → Users.UserId
-- Khi xóa User: CASCADE (xóa luôn membership)
-- Khi update UserId: CASCADE
-- ──────────────────────────────────────────────
DECLARE @fkName2 NVARCHAR(200);
SELECT @fkName2 = fk.name 
FROM sys.foreign_keys fk 
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID('UserMemberships') 
  AND fkc.parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('UserMemberships') AND name = 'UserId')
  AND fk.name != 'FK_UserMemberships_Users_Cascade';

IF @fkName2 IS NOT NULL
BEGIN
    EXEC('ALTER TABLE UserMemberships DROP CONSTRAINT [' + @fkName2 + ']');
    PRINT N'✅ Đã xóa FK cũ: ' + @fkName2;
END

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_UserMemberships_Users_Cascade')
BEGIN
    ALTER TABLE UserMemberships
    ADD CONSTRAINT FK_UserMemberships_Users_Cascade
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
    ON DELETE CASCADE
    ON UPDATE CASCADE;
    PRINT N'✅ FK: UserMemberships.UserId → Users (ON DELETE CASCADE)';
END
GO

-- ──────────────────────────────────────────────
-- 2c. UserMemberships.MembershipTypeId → MembershipTypes
-- Khi xóa MembershipType: NO ACTION (không cho xóa nếu còn user dùng)
-- Khi update: CASCADE
-- ──────────────────────────────────────────────
DECLARE @fkName3 NVARCHAR(200);
SELECT @fkName3 = fk.name 
FROM sys.foreign_keys fk 
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID('UserMemberships') 
  AND fkc.parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('UserMemberships') AND name = 'MembershipTypeId')
  AND fk.name != 'FK_UserMemberships_MembershipTypes_Cascade';

IF @fkName3 IS NOT NULL
BEGIN
    EXEC('ALTER TABLE UserMemberships DROP CONSTRAINT [' + @fkName3 + ']');
    PRINT N'✅ Đã xóa FK cũ: ' + @fkName3;
END

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_UserMemberships_MembershipTypes_Cascade')
BEGIN
    ALTER TABLE UserMemberships
    ADD CONSTRAINT FK_UserMemberships_MembershipTypes_Cascade
    FOREIGN KEY (MembershipTypeId) REFERENCES MembershipTypes(MembershipTypeId)
    ON DELETE NO ACTION
    ON UPDATE CASCADE;
    PRINT N'✅ FK: UserMemberships.MembershipTypeId → MembershipTypes (ON DELETE NO ACTION)';
END
GO

-- ──────────────────────────────────────────────
-- 2d. Animals.ZoneId → Zones.ZoneId
-- Khi xóa Zone: NO ACTION (không cho xóa zone nếu còn animal)
-- Khi update: CASCADE
-- ──────────────────────────────────────────────
DECLARE @fkName4 NVARCHAR(200);
SELECT @fkName4 = fk.name 
FROM sys.foreign_keys fk 
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID('Animals') 
  AND fkc.parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('Animals') AND name = 'ZoneId')
  AND fk.name != 'FK_Animals_Zones_Cascade';

IF @fkName4 IS NOT NULL
BEGIN
    EXEC('ALTER TABLE Animals DROP CONSTRAINT [' + @fkName4 + ']');
    PRINT N'✅ Đã xóa FK cũ: ' + @fkName4;
END

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Animals_Zones_Cascade')
BEGIN
    ALTER TABLE Animals
    ADD CONSTRAINT FK_Animals_Zones_Cascade
    FOREIGN KEY (ZoneId) REFERENCES Zones(ZoneId)
    ON DELETE NO ACTION
    ON UPDATE CASCADE;
    PRINT N'✅ FK: Animals.ZoneId → Zones (ON DELETE NO ACTION, ON UPDATE CASCADE)';
END
GO

-- ──────────────────────────────────────────────
-- 2e. Attractions.ZoneId → Zones.ZoneId
-- Khi xóa Zone: CASCADE (xóa luôn attraction)
-- ──────────────────────────────────────────────
DECLARE @fkName5 NVARCHAR(200);
SELECT @fkName5 = fk.name 
FROM sys.foreign_keys fk 
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID('Attractions') 
  AND fkc.parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('Attractions') AND name = 'ZoneId')
  AND fk.name != 'FK_Attractions_Zones_Cascade';

IF @fkName5 IS NOT NULL
BEGIN
    EXEC('ALTER TABLE Attractions DROP CONSTRAINT [' + @fkName5 + ']');
    PRINT N'✅ Đã xóa FK cũ: ' + @fkName5;
END

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Attractions_Zones_Cascade')
BEGIN
    ALTER TABLE Attractions
    ADD CONSTRAINT FK_Attractions_Zones_Cascade
    FOREIGN KEY (ZoneId) REFERENCES Zones(ZoneId)
    ON DELETE CASCADE
    ON UPDATE CASCADE;
    PRINT N'✅ FK: Attractions.ZoneId → Zones (ON DELETE CASCADE)';
END
GO

-- ──────────────────────────────────────────────
-- 2f. EventBookings.UserId → Users.UserId
-- Khi xóa User: CASCADE (xóa luôn booking)
-- ──────────────────────────────────────────────
DECLARE @fkName6 NVARCHAR(200);
SELECT @fkName6 = fk.name 
FROM sys.foreign_keys fk 
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID('EventBookings') 
  AND fkc.parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('EventBookings') AND name = 'UserId')
  AND fk.name != 'FK_EventBookings_Users_Cascade';

IF @fkName6 IS NOT NULL
BEGIN
    EXEC('ALTER TABLE EventBookings DROP CONSTRAINT [' + @fkName6 + ']');
    PRINT N'✅ Đã xóa FK cũ: ' + @fkName6;
END

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_EventBookings_Users_Cascade')
BEGIN
    ALTER TABLE EventBookings
    ADD CONSTRAINT FK_EventBookings_Users_Cascade
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
    ON DELETE CASCADE
    ON UPDATE CASCADE;
    PRINT N'✅ FK: EventBookings.UserId → Users (ON DELETE CASCADE)';
END
GO

-- ──────────────────────────────────────────────
-- 2g. EventBookings.EventId → Events.EventId
-- Khi xóa Event: NO ACTION (trigger trg_Events_PreventDeleteWithBookings xử lý)
-- Khi update: CASCADE
-- ──────────────────────────────────────────────
DECLARE @fkName7 NVARCHAR(200);
SELECT @fkName7 = fk.name 
FROM sys.foreign_keys fk 
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID('EventBookings') 
  AND fkc.parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('EventBookings') AND name = 'EventId')
  AND fk.name != 'FK_EventBookings_Events_Cascade';

IF @fkName7 IS NOT NULL
BEGIN
    EXEC('ALTER TABLE EventBookings DROP CONSTRAINT [' + @fkName7 + ']');
    PRINT N'✅ Đã xóa FK cũ: ' + @fkName7;
END

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_EventBookings_Events_Cascade')
BEGIN
    ALTER TABLE EventBookings
    ADD CONSTRAINT FK_EventBookings_Events_Cascade
    FOREIGN KEY (EventId) REFERENCES Events(EventId)
    ON DELETE NO ACTION
    ON UPDATE CASCADE;
    PRINT N'✅ FK: EventBookings.EventId → Events (ON DELETE NO ACTION — trigger bảo vệ)';
END
GO

-- ──────────────────────────────────────────────
-- 2h. OrderItems.OrderId → Orders.OrderId
-- Khi xóa Order: CASCADE (xóa luôn OrderItems)
-- ──────────────────────────────────────────────
DECLARE @fkName8 NVARCHAR(200);
SELECT @fkName8 = fk.name 
FROM sys.foreign_keys fk 
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID('OrderItems') 
  AND fkc.parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('OrderItems') AND name = 'OrderId')
  AND fk.name != 'FK_OrderItems_Orders_Cascade';

IF @fkName8 IS NOT NULL
BEGIN
    EXEC('ALTER TABLE OrderItems DROP CONSTRAINT [' + @fkName8 + ']');
    PRINT N'✅ Đã xóa FK cũ: ' + @fkName8;
END

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_OrderItems_Orders_Cascade')
BEGIN
    ALTER TABLE OrderItems
    ADD CONSTRAINT FK_OrderItems_Orders_Cascade
    FOREIGN KEY (OrderId) REFERENCES Orders(OrderId)
    ON DELETE CASCADE
    ON UPDATE CASCADE;
    PRINT N'✅ FK: OrderItems.OrderId → Orders (ON DELETE CASCADE)';
END
GO

-- ──────────────────────────────────────────────
-- 2i. OrderItems.TicketTypeId → TicketTypes.TicketTypeId
-- Khi xóa TicketType: NO ACTION (không cho xóa nếu có order dùng)
-- ──────────────────────────────────────────────
DECLARE @fkName9 NVARCHAR(200);
SELECT @fkName9 = fk.name 
FROM sys.foreign_keys fk 
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID('OrderItems') 
  AND fkc.parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('OrderItems') AND name = 'TicketTypeId')
  AND fk.name != 'FK_OrderItems_TicketTypes_Cascade';

IF @fkName9 IS NOT NULL
BEGIN
    EXEC('ALTER TABLE OrderItems DROP CONSTRAINT [' + @fkName9 + ']');
    PRINT N'✅ Đã xóa FK cũ: ' + @fkName9;
END

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_OrderItems_TicketTypes_Cascade')
BEGIN
    ALTER TABLE OrderItems
    ADD CONSTRAINT FK_OrderItems_TicketTypes_Cascade
    FOREIGN KEY (TicketTypeId) REFERENCES TicketTypes(TicketTypeId)
    ON DELETE NO ACTION
    ON UPDATE CASCADE;
    PRINT N'✅ FK: OrderItems.TicketTypeId → TicketTypes (ON DELETE NO ACTION)';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN 3: CẬP NHẬT CASCADE CHO PROCEEDS & PAYMENTLOG        ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ──────────────────────────────────────────────
-- 3a. Proceeds.EventId → Events (ON DELETE SET NULL, ON UPDATE CASCADE)
-- Khi xóa Event: SET NULL (giữ proceed, chỉ mất liên kết event)
-- Lưu ý: Trigger trg_Events_PreventDeleteWithBookings ngăn xóa Event có proceeds
-- SET NULL là fallback an toàn nếu trigger bị disable
-- ──────────────────────────────────────────────
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Proceeds_Events')
BEGIN
    ALTER TABLE Proceeds DROP CONSTRAINT FK_Proceeds_Events;
    PRINT N'✅ Đã xóa FK cũ: FK_Proceeds_Events';
END
GO

ALTER TABLE Proceeds
ADD CONSTRAINT FK_Proceeds_Events
FOREIGN KEY (EventId) REFERENCES Events(EventId)
ON DELETE SET NULL
ON UPDATE CASCADE;
PRINT N'✅ FK: Proceeds.EventId → Events (ON DELETE SET NULL, ON UPDATE CASCADE)';
GO

-- ──────────────────────────────────────────────
-- 3b. Proceeds.CustomerId → Customers (ON DELETE SET NULL, ON UPDATE CASCADE)
-- Khi xóa Customer: giữ proceed, chỉ mất liên kết customer
-- ──────────────────────────────────────────────
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Proceeds_Customers')
BEGIN
    ALTER TABLE Proceeds DROP CONSTRAINT FK_Proceeds_Customers;
    PRINT N'✅ Đã xóa FK cũ: FK_Proceeds_Customers';
END
GO

ALTER TABLE Proceeds
ADD CONSTRAINT FK_Proceeds_Customers
FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId)
ON DELETE SET NULL
ON UPDATE CASCADE;
PRINT N'✅ FK: Proceeds.CustomerId → Customers (ON DELETE SET NULL, ON UPDATE CASCADE)';
GO

-- ──────────────────────────────────────────────
-- 3c. Proceeds.TicketTypeId → TicketTypes (ON DELETE NO ACTION, ON UPDATE CASCADE)
-- Không cho xóa TicketType nếu có proceeds
-- ──────────────────────────────────────────────
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Proceeds_TicketTypes')
BEGIN
    ALTER TABLE Proceeds DROP CONSTRAINT FK_Proceeds_TicketTypes;
    PRINT N'✅ Đã xóa FK cũ: FK_Proceeds_TicketTypes';
END
GO

ALTER TABLE Proceeds
ADD CONSTRAINT FK_Proceeds_TicketTypes
FOREIGN KEY (TicketTypeId) REFERENCES TicketTypes(TicketTypeId)
ON DELETE NO ACTION
ON UPDATE CASCADE;
PRINT N'✅ FK: Proceeds.TicketTypeId → TicketTypes (ON DELETE NO ACTION, ON UPDATE CASCADE)';
GO

-- ──────────────────────────────────────────────
-- 3d. PaymentLog.ProceedId → Proceeds (ON DELETE CASCADE, ON UPDATE CASCADE)
-- Khi xóa Proceed: xóa luôn PaymentLog liên quan
-- ──────────────────────────────────────────────
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PaymentLog_Proceeds')
BEGIN
    ALTER TABLE PaymentLog DROP CONSTRAINT FK_PaymentLog_Proceeds;
    PRINT N'✅ Đã xóa FK cũ: FK_PaymentLog_Proceeds';
END
GO

ALTER TABLE PaymentLog
ADD CONSTRAINT FK_PaymentLog_Proceeds
FOREIGN KEY (ProceedId) REFERENCES Proceeds(ProceedId)
ON DELETE CASCADE
ON UPDATE CASCADE;
PRINT N'✅ FK: PaymentLog.ProceedId → Proceeds (ON DELETE CASCADE)';
GO

-- ──────────────────────────────────────────────
-- 3e. PaymentLog.OrderId → Orders (ON DELETE SET NULL, ON UPDATE NO ACTION)
-- Khi xóa Order: SET NULL (giữ log)
-- ON UPDATE NO ACTION để tránh multiple cascade paths
-- (Users → Orders → PaymentLog vs Users → Proceeds → PaymentLog)
-- ──────────────────────────────────────────────
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PaymentLog_Orders')
BEGIN
    ALTER TABLE PaymentLog DROP CONSTRAINT FK_PaymentLog_Orders;
    PRINT N'✅ Đã xóa FK cũ: FK_PaymentLog_Orders';
END
GO

ALTER TABLE PaymentLog
ADD CONSTRAINT FK_PaymentLog_Orders
FOREIGN KEY (OrderId) REFERENCES Orders(OrderId)
ON DELETE SET NULL
ON UPDATE NO ACTION;
PRINT N'✅ FK: PaymentLog.OrderId → Orders (ON DELETE SET NULL)';
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN 4: CHECK CONSTRAINTS BỔ SUNG CHO BẢNG MỚI            ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Donations
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Donations_Status')
BEGIN
    ALTER TABLE Donations ADD CONSTRAINT CK_Donations_Status 
        CHECK (Status IN ('Pending', 'Completed', 'Failed', 'Refunded'));
    PRINT N'✅ CHECK: Donations.Status';
END

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Donations_PaymentMethod')
BEGIN
    ALTER TABLE Donations ADD CONSTRAINT CK_Donations_PaymentMethod 
        CHECK (PaymentMethod IN ('QR', 'Card', 'BankTransfer', 'Cash'));
    PRINT N'✅ CHECK: Donations.PaymentMethod';
END

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Donations_Frequency')
BEGIN
    ALTER TABLE Donations ADD CONSTRAINT CK_Donations_Frequency 
        CHECK (DonationFrequency IN ('OneTime', 'Monthly'));
    PRINT N'✅ CHECK: Donations.DonationFrequency';
END

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Donations_DedicationType')
BEGIN
    ALTER TABLE Donations ADD CONSTRAINT CK_Donations_DedicationType 
        CHECK (DedicationType IN ('None', 'InHonorOf', 'InMemoryOf'));
    PRINT N'✅ CHECK: Donations.DedicationType';
END
GO

-- EventSupportLogs
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_EventSupportLogs_Status')
BEGIN
    ALTER TABLE EventSupportLogs ADD CONSTRAINT CK_EventSupportLogs_Status 
        CHECK (Status IN ('New', 'InProgress', 'Resolved'));
    PRINT N'✅ CHECK: EventSupportLogs.Status';
END

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_EventSupportLogs_GuestCount')
BEGIN
    ALTER TABLE EventSupportLogs ADD CONSTRAINT CK_EventSupportLogs_GuestCount 
        CHECK (GuestCount >= 0);
    PRINT N'✅ CHECK: EventSupportLogs.GuestCount >= 0';
END
GO

-- Inquiries
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Inquiries_Status')
BEGIN
    ALTER TABLE Inquiries ADD CONSTRAINT CK_Inquiries_Status 
        CHECK (Status IN ('New', 'In Progress', 'Resolved'));
    PRINT N'✅ CHECK: Inquiries.Status';
END
GO

-- GroupRequests
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_GroupRequests_Status')
BEGIN
    ALTER TABLE GroupRequests ADD CONSTRAINT CK_GroupRequests_Status 
        CHECK (Status IN ('Pending', 'Approved', 'Rejected'));
    PRINT N'✅ CHECK: GroupRequests.Status';
END
GO

-- Notifications
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Notifications_RecipientRole')
BEGIN
    ALTER TABLE Notifications ADD CONSTRAINT CK_Notifications_RecipientRole 
        CHECK (RecipientRole IN ('Admin', 'Customer', 'Employee'));
    PRINT N'✅ CHECK: Notifications.RecipientRole';
END

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Notifications_Type')
BEGIN
    ALTER TABLE Notifications ADD CONSTRAINT CK_Notifications_Type 
        CHECK (Type IN ('Ticket', 'Donation', 'EventRequest', 'Contact', 'System', 'GroupBooking'));
    PRINT N'✅ CHECK: Notifications.Type';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN 5: BẢNG TỔNG HỢP — SƠ ĐỒ TOÀN BỘ FK                ║
-- ╚══════════════════════════════════════════════════════════════╝

-- In ra sơ đồ FK hoàn chỉnh
PRINT N'';
PRINT N'╔══════════════════════════════════════════════════════════════╗';
PRINT N'║  SƠ ĐỒ KHÓA NGOẠI HOÀN CHỈNH — ZooDatabase               ║';
PRINT N'╠══════════════════════════════════════════════════════════════╣';
PRINT N'║                                                            ║';
PRINT N'║  Roles ─────┐                                              ║';
PRINT N'║             ├─→ Users (ON DELETE NO ACTION)                 ║';
PRINT N'║                  │                                          ║';
PRINT N'║                  ├─→ Customers (ON DELETE SET NULL)         ║';
PRINT N'║                  │     └─→ Proceeds (ON DELETE SET NULL)    ║';
PRINT N'║                  │           └─→ PaymentLog (ON DELETE CASCADE)';
PRINT N'║                  │                                          ║';
PRINT N'║                  ├─→ Employees (ON DELETE SET NULL)         ║';
PRINT N'║                  │     ├─→ Inquiries.ResolvedBy (SET NULL)  ║';
PRINT N'║                  │     ├─→ GroupRequests.ProcessedBy (SET NULL)';
PRINT N'║                  │     └─→ EventSupportLogs.ResolvedBy (SET NULL)';
PRINT N'║                  │                                          ║';
PRINT N'║                  ├─→ UserMemberships (ON DELETE CASCADE)    ║';
PRINT N'║                  ├─→ EventBookings (ON DELETE CASCADE)      ║';
PRINT N'║                  ├─→ Orders (ON DELETE SET NULL)            ║';
PRINT N'║                  │     ├─→ OrderItems (ON DELETE CASCADE)   ║';
PRINT N'║                  │     └─→ PaymentLog (ON DELETE SET NULL)  ║';
PRINT N'║                  └─→ Donations (ON DELETE SET NULL)         ║';
PRINT N'║                                                            ║';
PRINT N'║  MembershipTypes ─→ UserMemberships (ON DELETE NO ACTION)  ║';
PRINT N'║  Zones ──────────┬─→ Animals (ON DELETE NO ACTION)         ║';
PRINT N'║                  └─→ Attractions (ON DELETE CASCADE)       ║';
PRINT N'║  Events ─────────┬─→ EventBookings (ON DELETE NO ACTION)   ║';
PRINT N'║                  └─→ Proceeds (ON DELETE SET NULL)         ║';
PRINT N'║  TicketTypes ────┬─→ OrderItems (ON DELETE NO ACTION)      ║';
PRINT N'║                  └─→ Proceeds (ON DELETE NO ACTION)        ║';
PRINT N'║                                                            ║';
PRINT N'╚══════════════════════════════════════════════════════════════╝';
GO

PRINT N'';
PRINT N'========================================';
PRINT N'✅ 17_ForeignKeys_Constraints.sql HOÀN TẤT';
PRINT N'========================================';
GO
