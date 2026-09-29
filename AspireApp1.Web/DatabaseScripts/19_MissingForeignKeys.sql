-- ============================================================
-- 19_MissingForeignKeys.sql
-- Bổ sung FK cho các bảng THIẾU liên kết trong Diagram:
-- Notifications, AuditLog (partial), EventSupportLogs, Donations
-- + Thêm liên kết cho Animals/Zones nếu bị mất
-- Chạy sau 18_RefundsAndUsersMerge.sql
-- ============================================================

USE [ZooDatabase]
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN 1: NOTIFICATIONS — Thêm FK liên kết                  ║
-- ║  Hiện tại chỉ dùng text (RecipientRole, RecipientEmail)     ║
-- ║  → Thêm UserId FK để liên kết trực tiếp với Users           ║
-- ╚══════════════════════════════════════════════════════════════╝

-- 1a. Thêm cột UserId vào Notifications (liên kết person cụ thể)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Notifications') AND name = 'UserId')
BEGIN
    ALTER TABLE Notifications ADD UserId INT NULL;
    PRINT N'✅ Đã thêm cột UserId vào Notifications';
END
GO

-- 1b. Migrate: Tìm UserId từ RecipientEmail
UPDATE n
SET n.UserId = u.UserId
FROM Notifications n
INNER JOIN Users u ON n.RecipientEmail = u.Email
WHERE n.UserId IS NULL AND n.RecipientEmail IS NOT NULL;
PRINT N'✅ Đã migrate Notifications.RecipientEmail → UserId';
GO

-- 1c. FK: Notifications.UserId → Users.UserId
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Notifications_Users')
BEGIN
    ALTER TABLE Notifications
    ADD CONSTRAINT FK_Notifications_Users
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
    ON DELETE SET NULL
    ON UPDATE CASCADE;
    PRINT N'✅ FK: Notifications.UserId → Users (ON DELETE SET NULL)';
END
GO

-- 1d. Thêm cột CreatedByUserId (ai tạo notification — system/admin)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Notifications') AND name = 'CreatedByUserId')
BEGIN
    ALTER TABLE Notifications ADD CreatedByUserId INT NULL;
    PRINT N'✅ Đã thêm cột CreatedByUserId vào Notifications';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Notifications_CreatedBy')
BEGIN
    ALTER TABLE Notifications
    ADD CONSTRAINT FK_Notifications_CreatedBy
    FOREIGN KEY (CreatedByUserId) REFERENCES Users(UserId)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
    PRINT N'✅ FK: Notifications.CreatedByUserId → Users';
END
GO

-- 1e. Index cho Notifications.UserId
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Notifications_UserId')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Notifications_UserId ON Notifications(UserId);
    PRINT N'✅ Index: IX_Notifications_UserId';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN 2: AUDITLOG — Thêm FK (partial)                      ║
-- ║  AuditLog cần liên kết với Users (ai thay đổi)              ║
-- ║  KHÔNG thêm FK cho TableName/RecordId vì là polymorphic     ║
-- ╚══════════════════════════════════════════════════════════════╝

-- 2a. Thêm cột UserId vào AuditLog (ai thực hiện thay đổi)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('AuditLog') AND name = 'UserId')
BEGIN
    ALTER TABLE AuditLog ADD UserId INT NULL;
    PRINT N'✅ Đã thêm cột UserId vào AuditLog';
END
GO

-- 2b. FK: AuditLog.UserId → Users.UserId
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_AuditLog_Users')
BEGIN
    ALTER TABLE AuditLog
    ADD CONSTRAINT FK_AuditLog_Users
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
    ON DELETE SET NULL
    ON UPDATE CASCADE;
    PRINT N'✅ FK: AuditLog.UserId → Users (ON DELETE SET NULL)';
END
GO

-- 2c. Index
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AuditLog_UserId')
BEGIN
    CREATE NONCLUSTERED INDEX IX_AuditLog_UserId ON AuditLog(UserId);
    PRINT N'✅ Index: IX_AuditLog_UserId';
END

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AuditLog_TableName')
BEGIN
    CREATE NONCLUSTERED INDEX IX_AuditLog_TableName ON AuditLog(TableName);
    PRINT N'✅ Index: IX_AuditLog_TableName';
END

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AuditLog_ChangedAt')
BEGIN
    CREATE NONCLUSTERED INDEX IX_AuditLog_ChangedAt ON AuditLog(ChangedAt DESC);
    PRINT N'✅ Index: IX_AuditLog_ChangedAt';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN 3: ZONES ↔ ANIMALS ↔ ATTRACTIONS                     ║
-- ║  Đảm bảo FK tồn tại (có thể bị mất khi chạy script 17)    ║
-- ╚══════════════════════════════════════════════════════════════╝

-- 3a. Animals.ZoneId → Zones.ZoneId
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('Animals') 
    AND referenced_object_id = OBJECT_ID('Zones'))
BEGIN
    ALTER TABLE Animals
    ADD CONSTRAINT FK_Animals_Zones
    FOREIGN KEY (ZoneId) REFERENCES Zones(ZoneId)
    ON DELETE NO ACTION
    ON UPDATE CASCADE;
    PRINT N'✅ FK: Animals.ZoneId → Zones (restored)';
END
ELSE
    PRINT N'ℹ️ FK Animals → Zones đã tồn tại';
GO

-- 3b. Attractions.ZoneId → Zones.ZoneId
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('Attractions') 
    AND referenced_object_id = OBJECT_ID('Zones'))
BEGIN
    ALTER TABLE Attractions
    ADD CONSTRAINT FK_Attractions_Zones
    FOREIGN KEY (ZoneId) REFERENCES Zones(ZoneId)
    ON DELETE CASCADE
    ON UPDATE CASCADE;
    PRINT N'✅ FK: Attractions.ZoneId → Zones (restored)';
END
ELSE
    PRINT N'ℹ️ FK Attractions → Zones đã tồn tại';
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN 4: EVENTSUPPORTLOGS — Thêm FK đến Users              ║
-- ║  Hiện chỉ có FK đến Employees (ResolvedBy)                  ║
-- ║  Thêm UserId để biết customer nào gửi request               ║
-- ╚══════════════════════════════════════════════════════════════╝

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('EventSupportLogs') AND name = 'UserId')
BEGIN
    ALTER TABLE EventSupportLogs ADD UserId INT NULL;
    PRINT N'✅ Đã thêm cột UserId vào EventSupportLogs';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_EventSupportLogs_Users')
BEGIN
    ALTER TABLE EventSupportLogs
    ADD CONSTRAINT FK_EventSupportLogs_Users
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
    ON DELETE SET NULL
    ON UPDATE CASCADE;
    PRINT N'✅ FK: EventSupportLogs.UserId → Users';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN 5: INQUIRIES — Thêm FK đến Users                     ║
-- ║  Cho phép liên kết inquiry với user đã đăng nhập            ║
-- ╚══════════════════════════════════════════════════════════════╝

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inquiries') AND name = 'UserId')
BEGIN
    ALTER TABLE Inquiries ADD UserId INT NULL;
    PRINT N'✅ Đã thêm cột UserId vào Inquiries';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Inquiries_Users')
BEGIN
    ALTER TABLE Inquiries
    ADD CONSTRAINT FK_Inquiries_Users
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
    ON DELETE SET NULL
    ON UPDATE CASCADE;
    PRINT N'✅ FK: Inquiries.UserId → Users';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN 6: GROUPREQUESTS — Thêm FK đến Users                 ║
-- ╚══════════════════════════════════════════════════════════════╝

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('GroupRequests') AND name = 'UserId')
BEGIN
    ALTER TABLE GroupRequests ADD UserId INT NULL;
    PRINT N'✅ Đã thêm cột UserId vào GroupRequests';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_GroupRequests_Users')
BEGIN
    ALTER TABLE GroupRequests
    ADD CONSTRAINT FK_GroupRequests_Users
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
    ON DELETE SET NULL
    ON UPDATE CASCADE;
    PRINT N'✅ FK: GroupRequests.UserId → Users';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN 7: DONATIONS — Đảm bảo FK tồn tại                   ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Donations.UserId đã được thêm ở script 17, chỉ verify
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('Donations') 
    AND referenced_object_id = OBJECT_ID('Users'))
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Donations') AND name = 'UserId')
    BEGIN
        ALTER TABLE Donations ADD UserId INT NULL;
    END

    ALTER TABLE Donations
    ADD CONSTRAINT FK_Donations_Users_Link
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
    ON DELETE SET NULL
    ON UPDATE CASCADE;
    PRINT N'✅ FK: Donations.UserId → Users (restored)';
END
ELSE
    PRINT N'ℹ️ FK Donations → Users đã tồn tại';
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN 8: SƠ ĐỒ LIÊN KẾT HOÀN CHỈNH                       ║
-- ╚══════════════════════════════════════════════════════════════╝

PRINT N'';
PRINT N'╔══════════════════════════════════════════════════════════════════════╗';
PRINT N'║  SƠ ĐỒ FK HOÀN CHỈNH SAU SCRIPT 19                               ║';
PRINT N'╠══════════════════════════════════════════════════════════════════════╣';
PRINT N'║                                                                    ║';
PRINT N'║  ┌─ Roles                                                         ║';
PRINT N'║  │   └─→ Users.RoleId                                             ║';
PRINT N'║  │                                                                 ║';
PRINT N'║  ├─ Users (TRUNG TÂM — mọi bảng đều liên kết)                    ║';
PRINT N'║  │   ├─→ Proceeds.UserId           (vé đã mua)                    ║';
PRINT N'║  │   ├─→ Refunds.UserId            (yêu cầu hoàn tiền)           ║';
PRINT N'║  │   ├─→ UserMemberships.UserId    (thành viên)                   ║';
PRINT N'║  │   ├─→ EventBookings.UserId      (đặt chỗ sự kiện)             ║';
PRINT N'║  │   ├─→ Donations.UserId          (đóng góp)                     ║';
PRINT N'║  │   ├─→ Notifications.UserId      (thông báo)          ★ MỚI    ║';
PRINT N'║  │   ├─→ AuditLog.UserId           (nhật ký thay đổi)   ★ MỚI    ║';
PRINT N'║  │   ├─→ Inquiries.UserId          (liên hệ)            ★ MỚI    ║';
PRINT N'║  │   ├─→ GroupRequests.UserId       (đặt nhóm)           ★ MỚI    ║';
PRINT N'║  │   ├─→ EventSupportLogs.UserId   (hỗ trợ sự kiện)    ★ MỚI    ║';
PRINT N'║  │   ├─→ Orders.UserId             (đơn hàng cũ)                  ║';
PRINT N'║  │   └─→ Employees.UserId / Customers.UserId (deprecated)        ║';
PRINT N'║  │                                                                 ║';
PRINT N'║  ├─ Zones                                                          ║';
PRINT N'║  │   ├─→ Animals.ZoneId            (động vật)            ✔ VERIFIED║';
PRINT N'║  │   └─→ Attractions.ZoneId        (điểm tham quan)     ✔ VERIFIED║';
PRINT N'║  │                                                                 ║';
PRINT N'║  ├─ Events                                                         ║';
PRINT N'║  │   ├─→ EventBookings.EventId                                    ║';
PRINT N'║  │   └─→ Proceeds.EventId                                         ║';
PRINT N'║  │                                                                 ║';
PRINT N'║  ├─ TicketTypes                                                    ║';
PRINT N'║  │   └─→ Proceeds.TicketTypeId                                    ║';
PRINT N'║  │                                                                 ║';
PRINT N'║  ├─ MembershipTypes                                                ║';
PRINT N'║  │   └─→ UserMemberships.MembershipTypeId                         ║';
PRINT N'║  │                                                                 ║';
PRINT N'║  ├─ Proceeds                                                       ║';
PRINT N'║  │   ├─→ Refunds.ProceedId                                        ║';
PRINT N'║  │   └─→ PaymentLog.ProceedId                                     ║';
PRINT N'║  │                                                                 ║';
PRINT N'║  ├─ RefundReasons                                                  ║';
PRINT N'║  │   └─→ Refunds.RefundReason                                     ║';
PRINT N'║  │                                                                 ║';
PRINT N'║  └─ Employees                                                      ║';
PRINT N'║      ├─→ Refunds.ProcessedBy                                      ║';
PRINT N'║      ├─→ Inquiries.ResolvedBy                                     ║';
PRINT N'║      ├─→ GroupRequests.ProcessedBy                                 ║';
PRINT N'║      └─→ EventSupportLogs.ResolvedBy                              ║';
PRINT N'║                                                                    ║';
PRINT N'║  TỔNG: 0 bảng cô lập (trước đây: 2 bảng cô lập)                 ║';
PRINT N'╚══════════════════════════════════════════════════════════════════════╝';
GO

PRINT N'';
PRINT N'========================================';
PRINT N'✅ 19_MissingForeignKeys.sql HOÀN TẤT';
PRINT N'========================================';
GO
