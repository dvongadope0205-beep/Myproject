-- ============================================================
-- 18_RefundsAndUsersMerge.sql
-- 1. Gộp Users + Customers (thêm cột vào Users, migrate data)
-- 2. Tạo bảng Refunds + RefundReasons
-- 3. Cập nhật Proceeds: CustomerId → UserId
-- 4. Views, Indexes, Triggers, Sample Data
-- Chạy sau 17_ForeignKeys_Constraints.sql
-- ============================================================

USE [ZooDatabase]
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN A: GỘP USERS + CUSTOMERS                             ║
-- ║  Thêm cột thiếu vào Users, migrate data từ Customers       ║
-- ╚══════════════════════════════════════════════════════════════╝

-- A1. Thêm cột mới vào Users (từ Customers)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'Phone')
BEGIN
    ALTER TABLE Users ADD Phone NVARCHAR(20) NULL;
    PRINT N'✅ Đã thêm cột Phone vào Users';
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'Address')
BEGIN
    ALTER TABLE Users ADD Address NVARCHAR(255) NULL;
    PRINT N'✅ Đã thêm cột Address vào Users';
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'Gender')
BEGIN
    ALTER TABLE Users ADD Gender NVARCHAR(10) NULL;
    PRINT N'✅ Đã thêm cột Gender vào Users';
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'DateOfBirth')
BEGIN
    ALTER TABLE Users ADD DateOfBirth DATE NULL;
    PRINT N'✅ Đã thêm cột DateOfBirth vào Users';
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'Photo')
BEGIN
    ALTER TABLE Users ADD Photo NVARCHAR(255) NULL;
    PRINT N'✅ Đã thêm cột Photo vào Users';
END
GO

-- A2. Migrate data từ Customers → Users
UPDATE u
SET 
    u.Phone = ISNULL(u.Phone, c.Phone),
    u.Address = ISNULL(u.Address, c.Address),
    u.Gender = ISNULL(u.Gender, c.Gender),
    u.DateOfBirth = ISNULL(u.DateOfBirth, c.DateOfBirth)
FROM Users u
INNER JOIN Customers c ON u.UserId = c.UserId
WHERE c.UserId IS NOT NULL;
PRINT N'✅ Đã migrate data từ Customers → Users';
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN B: CẬP NHẬT PROCEEDS — THÊM UserId                  ║
-- ║  Giữ CustomerId tạm (backward compat), thêm UserId mới     ║
-- ╚══════════════════════════════════════════════════════════════╝

-- B1. Thêm cột UserId vào Proceeds
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Proceeds') AND name = 'UserId')
BEGIN
    ALTER TABLE Proceeds ADD UserId INT NULL;
    PRINT N'✅ Đã thêm cột UserId vào Proceeds';
END
GO

-- B2. Migrate CustomerId → UserId trong Proceeds
UPDATE p
SET p.UserId = c.UserId
FROM Proceeds p
INNER JOIN Customers c ON p.CustomerId = c.CustomerId
WHERE p.UserId IS NULL AND c.UserId IS NOT NULL;
PRINT N'✅ Đã migrate Proceeds.CustomerId → UserId';
GO

-- B3. Tạo FK Proceeds.UserId → Users.UserId
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Proceeds_Users')
BEGIN
    ALTER TABLE Proceeds
    ADD CONSTRAINT FK_Proceeds_Users
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
    ON DELETE SET NULL
    ON UPDATE CASCADE;
    PRINT N'✅ FK: Proceeds.UserId → Users (ON DELETE SET NULL)';
END
GO

-- B4. Index cho Proceeds.UserId
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Proceeds_UserId')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Proceeds_UserId ON Proceeds(UserId);
    PRINT N'✅ Index: IX_Proceeds_UserId';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN C: BẢNG RefundReasons (Lookup Table)                  ║
-- ╚══════════════════════════════════════════════════════════════╝

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RefundReasons')
BEGIN
    CREATE TABLE RefundReasons (
        ReasonCode       NVARCHAR(50) PRIMARY KEY,
        ReasonLabel      NVARCHAR(200) NOT NULL,        -- Tên hiển thị (EN)
        ReasonLabelVi    NVARCHAR(200) NULL,             -- Tên hiển thị (VI)
        RequiresDetail   BIT DEFAULT 0,                  -- Có cần nhập chi tiết?
        IsActive         BIT DEFAULT 1,                  -- Còn sử dụng?
        SortOrder        INT DEFAULT 0                   -- Thứ tự hiển thị
    );
    PRINT N'✅ Đã tạo bảng RefundReasons';
END
GO

-- Seed RefundReasons
IF NOT EXISTS (SELECT 1 FROM RefundReasons)
BEGIN
    INSERT INTO RefundReasons (ReasonCode, ReasonLabel, ReasonLabelVi, RequiresDetail, IsActive, SortOrder)
    VALUES
        ('ScheduleChange',      'Schedule change',                  N'Thay đổi lịch trình',             0, 1, 1),
        ('NoLongerInterested',  'No longer interested in visiting', N'Không còn muốn tham quan',         0, 1, 2),
        ('DuplicatePurchase',   'Duplicate / incorrect purchase',   N'Mua trùng hoặc mua nhầm',         0, 1, 3),
        ('EventCancelled',      'Event cancelled by organizer',     N'Sự kiện bị hủy bởi ban tổ chức',  0, 1, 4),
        ('WeatherIssue',        'Bad weather conditions',           N'Thời tiết xấu / bão lụt',         0, 1, 5),
        ('HealthIssue',         'Health / medical reasons',         N'Lý do sức khỏe / y tế',           0, 1, 6),
        ('FamilyEmergency',     'Family emergency',                 N'Việc gia đình khẩn cấp',          0, 1, 7),
        ('PriceDispute',        'Incorrect price was charged',      N'Bị tính giá sai',                 1, 1, 8),
        ('ServiceComplaint',    'Unsatisfied with service',         N'Không hài lòng với dịch vụ',      1, 1, 9),
        ('Other',               'Other reason (please specify)',    N'Lý do khác (vui lòng ghi rõ)',    1, 1, 10);
    PRINT N'✅ Đã seed 10 RefundReasons';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN D: BẢNG Refunds                                       ║
-- ╚══════════════════════════════════════════════════════════════╝

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Refunds')
BEGIN
    CREATE TABLE Refunds (
        RefundId         INT IDENTITY(1,1) PRIMARY KEY,
        ProceedId        INT NOT NULL,                       -- FK → Proceeds (vé nào hoàn tiền)
        UserId           INT NULL,                           -- FK → Users (ai yêu cầu)
        RefundReason     NVARCHAR(50) NOT NULL,              -- FK → RefundReasons.ReasonCode
        ReasonDetail     NVARCHAR(MAX) NULL,                 -- Chi tiết lý do (free-text)
        RefundAmount     DECIMAL(18,2) NOT NULL,             -- Số tiền hoàn
        OriginalAmount   DECIMAL(18,2) NOT NULL,             -- Số tiền gốc
        RefundPercent    DECIMAL(5,2) DEFAULT 100.00,        -- % hoàn tiền
        RefundMethod     NVARCHAR(50) DEFAULT 'Original',    -- Original / BankTransfer / Cash
        Status           NVARCHAR(50) DEFAULT 'Requested',   -- Requested / Approved / Rejected / Completed
        RequestedAt      DATETIME DEFAULT GETDATE(),         -- Thời điểm yêu cầu
        ProcessedAt      DATETIME NULL,                      -- Thời điểm admin xử lý
        ProcessedBy      INT NULL,                           -- FK → Employees (ai xử lý)
        CompletedAt      DATETIME NULL,                      -- Thời điểm hoàn tiền xong
        AdminNotes       NVARCHAR(MAX) NULL,                 -- Ghi chú admin
        TransactionRef   NVARCHAR(100) NULL,                 -- Mã giao dịch hoàn tiền

        -- Foreign Keys
        CONSTRAINT FK_Refunds_Proceeds FOREIGN KEY (ProceedId) REFERENCES Proceeds(ProceedId) ON DELETE NO ACTION,
        CONSTRAINT FK_Refunds_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE SET NULL ON UPDATE CASCADE,
        CONSTRAINT FK_Refunds_Employees FOREIGN KEY (ProcessedBy) REFERENCES Employees(EmployeeId) ON DELETE SET NULL ON UPDATE CASCADE,
        CONSTRAINT FK_Refunds_Reasons FOREIGN KEY (RefundReason) REFERENCES RefundReasons(ReasonCode) ON UPDATE CASCADE,

        -- Check Constraints
        CONSTRAINT CK_Refunds_Amount CHECK (RefundAmount >= 0),
        CONSTRAINT CK_Refunds_OriginalAmount CHECK (OriginalAmount > 0),
        CONSTRAINT CK_Refunds_Percent CHECK (RefundPercent >= 0 AND RefundPercent <= 100),
        CONSTRAINT CK_Refunds_Status CHECK (Status IN ('Requested', 'Approved', 'Rejected', 'Completed')),
        CONSTRAINT CK_Refunds_Method CHECK (RefundMethod IN ('Original', 'BankTransfer', 'Cash'))
    );
    PRINT N'✅ Đã tạo bảng Refunds';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN E: INDEXES CHO REFUNDS                               ║
-- ╚══════════════════════════════════════════════════════════════╝

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Refunds_ProceedId')
    CREATE NONCLUSTERED INDEX IX_Refunds_ProceedId ON Refunds(ProceedId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Refunds_UserId')
    CREATE NONCLUSTERED INDEX IX_Refunds_UserId ON Refunds(UserId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Refunds_Status')
    CREATE NONCLUSTERED INDEX IX_Refunds_Status ON Refunds(Status);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Refunds_RequestedAt')
    CREATE NONCLUSTERED INDEX IX_Refunds_RequestedAt ON Refunds(RequestedAt DESC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Refunds_RefundReason')
    CREATE NONCLUSTERED INDEX IX_Refunds_RefundReason ON Refunds(RefundReason);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Refunds_TransactionRef')
    CREATE NONCLUSTERED INDEX IX_Refunds_TransactionRef ON Refunds(TransactionRef);

-- Index cho Users mới (Phone)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_Phone')
    CREATE NONCLUSTERED INDEX IX_Users_Phone ON Users(Phone);

PRINT N'✅ Đã tạo tất cả Indexes cho Refunds';
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN F: VIEWS CHO REFUNDS                                  ║
-- ╚══════════════════════════════════════════════════════════════╝

-- View: Refunds Summary (cho Admin Dashboard)
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_RefundsSummary') DROP VIEW vw_RefundsSummary;
GO
CREATE VIEW vw_RefundsSummary AS
SELECT 
    r.RefundId,
    r.ProceedId,
    u.FullName AS CustomerName,
    u.Email AS CustomerEmail,
    rr.ReasonLabel,
    rr.ReasonLabelVi,
    r.ReasonDetail,
    r.RefundAmount,
    r.OriginalAmount,
    r.RefundPercent,
    r.RefundMethod,
    r.Status,
    r.RequestedAt,
    r.ProcessedAt,
    e.FullName AS ProcessedByName,
    r.CompletedAt,
    r.AdminNotes,
    r.TransactionRef,
    p.TransactionRef AS OriginalTransactionRef,
    p.PaymentMethod AS OriginalPaymentMethod,
    ev.Title AS EventTitle,
    tt.Name AS TicketType,
    p.Quantity AS TicketQuantity
FROM Refunds r
INNER JOIN Proceeds p ON r.ProceedId = p.ProceedId
LEFT JOIN Users u ON r.UserId = u.UserId
LEFT JOIN Employees e ON r.ProcessedBy = e.EmployeeId
LEFT JOIN RefundReasons rr ON r.RefundReason = rr.ReasonCode
LEFT JOIN Events ev ON p.EventId = ev.EventId
LEFT JOIN TicketTypes tt ON p.TicketTypeId = tt.TicketTypeId;
GO
PRINT N'✅ Đã tạo View: vw_RefundsSummary';
GO

-- View: Refund Statistics
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_RefundStatistics') DROP VIEW vw_RefundStatistics;
GO
CREATE VIEW vw_RefundStatistics AS
SELECT 
    COUNT(*) AS TotalRefundRequests,
    SUM(CASE WHEN Status = 'Requested' THEN 1 ELSE 0 END) AS PendingRequests,
    SUM(CASE WHEN Status = 'Approved' THEN 1 ELSE 0 END) AS ApprovedRequests,
    SUM(CASE WHEN Status = 'Rejected' THEN 1 ELSE 0 END) AS RejectedRequests,
    SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) AS CompletedRefunds,
    SUM(CASE WHEN Status = 'Completed' THEN RefundAmount ELSE 0 END) AS TotalRefunded,
    SUM(OriginalAmount) AS TotalOriginalAmount,
    AVG(CASE WHEN Status = 'Completed' THEN RefundPercent ELSE NULL END) AS AvgRefundPercent,
    MAX(RefundAmount) AS LargestRefund
FROM Refunds;
GO
PRINT N'✅ Đã tạo View: vw_RefundStatistics';
GO

-- View: Refund by Reason (phân tích lý do hoàn tiền)
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_RefundsByReason') DROP VIEW vw_RefundsByReason;
GO
CREATE VIEW vw_RefundsByReason AS
SELECT 
    r.RefundReason,
    rr.ReasonLabel,
    rr.ReasonLabelVi,
    COUNT(*) AS RequestCount,
    SUM(CASE WHEN r.Status = 'Completed' THEN 1 ELSE 0 END) AS CompletedCount,
    SUM(CASE WHEN r.Status = 'Rejected' THEN 1 ELSE 0 END) AS RejectedCount,
    SUM(CASE WHEN r.Status = 'Completed' THEN r.RefundAmount ELSE 0 END) AS TotalRefunded,
    AVG(CASE WHEN r.Status = 'Completed' THEN r.RefundPercent ELSE NULL END) AS AvgRefundPercent
FROM Refunds r
LEFT JOIN RefundReasons rr ON r.RefundReason = rr.ReasonCode
GROUP BY r.RefundReason, rr.ReasonLabel, rr.ReasonLabelVi;
GO
PRINT N'✅ Đã tạo View: vw_RefundsByReason';
GO

-- View: User Info (thay thế query cũ từ Customers)
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_UserProfile') DROP VIEW vw_UserProfile;
GO
CREATE VIEW vw_UserProfile AS
SELECT 
    u.UserId,
    u.Username,
    u.FullName,
    u.Email,
    u.Phone,
    u.Address,
    u.Gender,
    u.DateOfBirth,
    u.Photo,
    u.CreatedAt AS MemberSince,
    r.RoleName,
    (SELECT COUNT(*) FROM Proceeds p WHERE p.UserId = u.UserId) AS TotalTransactions,
    (SELECT ISNULL(SUM(p.TotalAmount), 0) FROM Proceeds p WHERE p.UserId = u.UserId AND p.PaymentStatus = 'Completed') AS TotalSpent,
    (SELECT ISNULL(SUM(p.Quantity), 0) FROM Proceeds p WHERE p.UserId = u.UserId AND p.PaymentStatus = 'Completed') AS TotalTicketsBought,
    (SELECT COUNT(*) FROM Refunds rf WHERE rf.UserId = u.UserId) AS TotalRefundRequests
FROM Users u
LEFT JOIN Roles r ON u.RoleId = r.RoleId;
GO
PRINT N'✅ Đã tạo View: vw_UserProfile';
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN G: TRIGGERS CHO REFUNDS                              ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Trigger: Khi Refund Completed → cập nhật Proceeds.PaymentStatus = 'Refunded'
CREATE OR ALTER TRIGGER trg_Refunds_UpdateProceeds
ON Refunds
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Khi Status chuyển sang 'Completed' → đánh dấu Proceeds là Refunded
    IF EXISTS (
        SELECT 1 FROM inserted i
        INNER JOIN deleted d ON i.RefundId = d.RefundId
        WHERE i.Status = 'Completed' AND d.Status != 'Completed'
    )
    BEGIN
        UPDATE p
        SET p.PaymentStatus = 'Refunded'
        FROM Proceeds p
        INNER JOIN inserted i ON p.ProceedId = i.ProceedId
        INNER JOIN deleted d ON i.RefundId = d.RefundId
        WHERE i.Status = 'Completed' AND d.Status != 'Completed';

        PRINT N'⚡ Trigger: Proceeds.PaymentStatus → Refunded';
    END
END
GO
PRINT N'✅ Đã tạo Trigger: trg_Refunds_UpdateProceeds';
GO

-- Trigger: Auto-log refund vào AuditLog
CREATE OR ALTER TRIGGER trg_Audit_Refunds
ON Refunds
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'Refunds', i.RefundId, 'INSERT', NULL,
            N'ProceedId=' + CAST(i.ProceedId AS NVARCHAR(10)) + 
            N' | Reason=' + ISNULL(i.RefundReason, '') + 
            N' | Amount=' + CAST(i.RefundAmount AS NVARCHAR(20)) + 
            N' | Status=' + ISNULL(i.Status, '')
        FROM inserted i;
    END

    -- UPDATE (status change)
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
        SELECT 'Refunds', i.RefundId, 'UPDATE',
            N'Status=' + ISNULL(d.Status, '') + N' | Amount=' + CAST(d.RefundAmount AS NVARCHAR(20)),
            N'Status=' + ISNULL(i.Status, '') + N' | Amount=' + CAST(i.RefundAmount AS NVARCHAR(20)) +
            N' | ProcessedAt=' + ISNULL(CONVERT(NVARCHAR(20), i.ProcessedAt, 120), 'NULL')
        FROM inserted i
        INNER JOIN deleted d ON i.RefundId = d.RefundId;
    END
END
GO
PRINT N'✅ Đã tạo Trigger: trg_Audit_Refunds';
GO

-- Trigger: Auto-tạo Notification khi có Refund request mới
CREATE OR ALTER TRIGGER trg_Refunds_Notification
ON Refunds
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Thông báo cho Admin
    INSERT INTO Notifications (RecipientRole, RecipientEmail, Title, Message, Type, ReferenceId, IconClass)
    SELECT 
        'Admin',
        NULL,
        N'Refund Request #' + CAST(i.RefundId AS NVARCHAR(10)),
        N'Customer requested refund of $' + CAST(i.RefundAmount AS NVARCHAR(20)) + 
        N' for Proceed #' + CAST(i.ProceedId AS NVARCHAR(10)) + 
        N' — Reason: ' + ISNULL(i.RefundReason, 'Unknown'),
        'System',
        ISNULL(i.TransactionRef, CAST(i.RefundId AS NVARCHAR(10))),
        'fa-undo'
    FROM inserted i;

    -- Thông báo cho Customer
    INSERT INTO Notifications (RecipientRole, RecipientEmail, Title, Message, Type, ReferenceId, IconClass)
    SELECT 
        'Customer',
        u.Email,
        N'Refund Request Submitted',
        N'Your refund request for $' + CAST(i.RefundAmount AS NVARCHAR(20)) + N' has been submitted and is being reviewed.',
        'System',
        ISNULL(i.TransactionRef, CAST(i.RefundId AS NVARCHAR(10))),
        'fa-clock'
    FROM inserted i
    LEFT JOIN Users u ON i.UserId = u.UserId
    WHERE u.Email IS NOT NULL;

    PRINT N'⚡ Trigger: Refund notifications created';
END
GO
PRINT N'✅ Đã tạo Trigger: trg_Refunds_Notification';
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN H: SAMPLE DATA — USERS MỚI (10+ Users)               ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Seed thêm Users (nếu chưa có đủ)
DECLARE @CustomerRoleId INT;
SELECT @CustomerRoleId = RoleId FROM Roles WHERE RoleName = 'Customer';

-- User 3: Nguyễn Văn A
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'nguyenvana@gmail.com')
BEGIN
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@CustomerRoleId, 'nguyenvana', 'nguyenvana@gmail.com', 
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', -- hashed
            N'Nguyễn Văn A', '0901234567', N'123 Lê Lợi, Q1, TP.HCM', 'Male', '1990-05-15');
END

-- User 4: Trần Thị B
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'tranthib@gmail.com')
BEGIN
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@CustomerRoleId, 'tranthib', 'tranthib@gmail.com',
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            N'Trần Thị B', '0912345678', N'456 Nguyễn Huệ, Q1, TP.HCM', 'Female', '1985-08-22');
END

-- User 5: Lê Minh C
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'leminhc@gmail.com')
BEGIN
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@CustomerRoleId, 'leminhc', 'leminhc@gmail.com',
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            N'Lê Minh C', '0923456789', N'789 Hai Bà Trưng, Q3, TP.HCM', 'Male', '1992-11-03');
END

-- User 6: Phạm Thị D
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'phamthid@gmail.com')
BEGIN
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@CustomerRoleId, 'phamthid', 'phamthid@gmail.com',
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            N'Phạm Thị D', '0934567890', N'101 Võ Văn Tần, Q3, TP.HCM', 'Female', '1988-02-14');
END

-- User 7: Hoàng Văn E
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'hoangvane@gmail.com')
BEGIN
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@CustomerRoleId, 'hoangvane', 'hoangvane@gmail.com',
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            N'Hoàng Văn E', '0945678901', N'202 Điện Biên Phủ, Bình Thạnh, TP.HCM', 'Male', '1995-07-30');
END

-- User 8: Võ Thị F
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'vothif@gmail.com')
BEGIN
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@CustomerRoleId, 'vothif', 'vothif@gmail.com',
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            N'Võ Thị F', '0956789012', N'303 Cách Mạng Tháng 8, Q10, TP.HCM', 'Female', '1993-12-25');
END

-- User 9: Đặng Quốc G
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'dangquocg@gmail.com')
BEGIN
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@CustomerRoleId, 'dangquocg', 'dangquocg@gmail.com',
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            N'Đặng Quốc G', '0967890123', N'404 Trần Hưng Đạo, Q5, TP.HCM', 'Male', '1987-04-18');
END

-- User 10: Bùi Thị H
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'buithih@gmail.com')
BEGIN
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@CustomerRoleId, 'buithih', 'buithih@gmail.com',
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            N'Bùi Thị H', '0978901234', N'505 Lý Thường Kiệt, Q10, TP.HCM', 'Female', '1991-09-08');
END

-- User 11: Ngô Thanh I
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'ngothanhi@gmail.com')
BEGIN
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@CustomerRoleId, 'ngothanhi', 'ngothanhi@gmail.com',
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            N'Ngô Thanh I', '0989012345', N'606 Nguyễn Trãi, Q5, TP.HCM', 'Male', '1996-01-20');
END

-- User 12: Dương Thị K
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'duongthik@gmail.com')
BEGIN
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@CustomerRoleId, 'duongthik', 'duongthik@gmail.com',
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            N'Dương Thị K', '0990123456', N'707 Phan Xích Long, Phú Nhuận, TP.HCM', 'Female', '1994-06-12');
END
GO
PRINT N'✅ Đã seed 10 Users mới';
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN I: SAMPLE PROCEEDS (cho Users mới, 10+ records)       ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Lấy IDs
DECLARE @AdultTicketId INT, @ChildTicketId INT, @SeniorTicketId INT;
SELECT @AdultTicketId = TicketTypeId FROM TicketTypes WHERE Name = 'Adult';
SELECT @ChildTicketId = TicketTypeId FROM TicketTypes WHERE Name = 'Child';
SELECT @SeniorTicketId = TicketTypeId FROM TicketTypes WHERE Name = 'Senior';

DECLARE @User3 INT, @User4 INT, @User5 INT, @User6 INT, @User7 INT;
DECLARE @User8 INT, @User9 INT, @User10 INT, @User11 INT, @User12 INT;
SELECT @User3 = UserId FROM Users WHERE Email = 'nguyenvana@gmail.com';
SELECT @User4 = UserId FROM Users WHERE Email = 'tranthib@gmail.com';
SELECT @User5 = UserId FROM Users WHERE Email = 'leminhc@gmail.com';
SELECT @User6 = UserId FROM Users WHERE Email = 'phamthid@gmail.com';
SELECT @User7 = UserId FROM Users WHERE Email = 'hoangvane@gmail.com';
SELECT @User8 = UserId FROM Users WHERE Email = 'vothif@gmail.com';
SELECT @User9 = UserId FROM Users WHERE Email = 'dangquocg@gmail.com';
SELECT @User10 = UserId FROM Users WHERE Email = 'buithih@gmail.com';
SELECT @User11 = UserId FROM Users WHERE Email = 'ngothanhi@gmail.com';
SELECT @User12 = UserId FROM Users WHERE Email = 'duongthik@gmail.com';

-- Chỉ insert nếu chưa có sample data
IF NOT EXISTS (SELECT 1 FROM Proceeds WHERE TransactionRef = 'TXN-SAMPLE-001')
BEGIN
    -- Proceed 1: Nguyễn Văn A — 2 Adult tickets
    INSERT INTO Proceeds (EventId, UserId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (NULL, @User3, @AdultTicketId, N'Nguyễn Văn A', 2, 15.00, 'QR Code', 'Completed', 'TXN-SAMPLE-001', 'General Admission');

    -- Proceed 2: Trần Thị B — 1 Adult + Event
    INSERT INTO Proceeds (EventId, UserId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (1, @User4, @AdultTicketId, N'Trần Thị B', 1, 25.00, 'Card', 'Completed', 'TXN-SAMPLE-002', 'Night Safari');

    -- Proceed 3: Lê Minh C — 3 Child tickets
    INSERT INTO Proceeds (EventId, UserId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (NULL, @User5, @ChildTicketId, N'Lê Minh C', 3, 10.00, 'Online', 'Completed', 'TXN-SAMPLE-003', 'General Admission - Children');

    -- Proceed 4: Phạm Thị D — 2 Senior tickets
    INSERT INTO Proceeds (EventId, UserId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (NULL, @User6, @SeniorTicketId, N'Phạm Thị D', 2, 12.00, 'Cash', 'Completed', 'TXN-SAMPLE-004', 'Senior Admission');

    -- Proceed 5: Hoàng Văn E — 4 Adult + Event
    INSERT INTO Proceeds (EventId, UserId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (2, @User7, @AdultTicketId, N'Hoàng Văn E', 4, 30.00, 'QR Code', 'Completed', 'TXN-SAMPLE-005', 'ZooLights Festival');

    -- Proceed 6: Võ Thị F — 1 Adult Pending
    INSERT INTO Proceeds (EventId, UserId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (NULL, @User8, @AdultTicketId, N'Võ Thị F', 1, 15.00, 'QR Code', 'Pending', 'TXN-SAMPLE-006', 'Pending QR Payment');

    -- Proceed 7: Đặng Quốc G — 2 Adult + 2 Child
    INSERT INTO Proceeds (EventId, UserId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (NULL, @User9, @AdultTicketId, N'Đặng Quốc G', 2, 15.00, 'Transfer', 'Completed', 'TXN-SAMPLE-007', 'Family Visit - Adults');

    INSERT INTO Proceeds (EventId, UserId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (NULL, @User9, @ChildTicketId, N'Đặng Quốc G', 2, 10.00, 'Transfer', 'Completed', 'TXN-SAMPLE-007B', 'Family Visit - Children');

    -- Proceed 8: Bùi Thị H — Event ticket
    INSERT INTO Proceeds (EventId, UserId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (1, @User10, @AdultTicketId, N'Bùi Thị H', 2, 25.00, 'Card', 'Completed', 'TXN-SAMPLE-008', 'Night Safari for 2');

    -- Proceed 9: Ngô Thanh I — General admission
    INSERT INTO Proceeds (EventId, UserId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (NULL, @User11, @AdultTicketId, N'Ngô Thanh I', 1, 15.00, 'Online', 'Completed', 'TXN-SAMPLE-009', 'Solo Visit');

    -- Proceed 10: Dương Thị K — Group event
    INSERT INTO Proceeds (EventId, UserId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (3, @User12, @AdultTicketId, N'Dương Thị K', 5, 20.00, 'Transfer', 'Completed', 'TXN-SAMPLE-010', 'Conservation Gala Group');

    PRINT N'✅ Đã seed 11 Proceeds sample';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN J: SAMPLE REFUNDS (10+ records)                       ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Chỉ insert nếu chưa có sample Refunds
IF NOT EXISTS (SELECT 1 FROM Refunds WHERE TransactionRef LIKE 'RFD-SAMPLE%')
BEGIN
    DECLARE @ProceedIds TABLE (RowNum INT IDENTITY(1,1), ProceedId INT, UserId INT, TotalAmount DECIMAL(18,2));
    
    INSERT INTO @ProceedIds (ProceedId, UserId, TotalAmount)
    SELECT TOP 11 ProceedId, UserId, TotalAmount
    FROM Proceeds
    WHERE TransactionRef LIKE 'TXN-SAMPLE%'
    ORDER BY ProceedId;

    DECLARE @empId INT;
    SELECT TOP 1 @empId = EmployeeId FROM Employees;

    -- Refund 1: ScheduleChange — Completed (100%)
    INSERT INTO Refunds (ProceedId, UserId, RefundReason, ReasonDetail, RefundAmount, OriginalAmount, RefundPercent, RefundMethod, Status, RequestedAt, ProcessedAt, ProcessedBy, CompletedAt, AdminNotes, TransactionRef)
    SELECT ProceedId, UserId, 'ScheduleChange', N'Gia đình có việc gấp, phải đổi lịch du lịch', 
           TotalAmount, TotalAmount, 100.00, 'Original', 'Completed',
           DATEADD(DAY, -10, GETDATE()), DATEADD(DAY, -9, GETDATE()), @empId, DATEADD(DAY, -8, GETDATE()),
           N'Approved - full refund', 'RFD-SAMPLE-001'
    FROM @ProceedIds WHERE RowNum = 1;

    -- Refund 2: NoLongerInterested — Completed (75%)
    INSERT INTO Refunds (ProceedId, UserId, RefundReason, ReasonDetail, RefundAmount, OriginalAmount, RefundPercent, RefundMethod, Status, RequestedAt, ProcessedAt, ProcessedBy, CompletedAt, AdminNotes, TransactionRef)
    SELECT ProceedId, UserId, 'NoLongerInterested', N'Đã đến sở thú khác rồi, không muốn đi nữa',
           TotalAmount * 0.75, TotalAmount, 75.00, 'BankTransfer', 'Completed',
           DATEADD(DAY, -8, GETDATE()), DATEADD(DAY, -7, GETDATE()), @empId, DATEADD(DAY, -6, GETDATE()),
           N'75% refund - cancelled 2 days before event', 'RFD-SAMPLE-002'
    FROM @ProceedIds WHERE RowNum = 2;

    -- Refund 3: DuplicatePurchase — Completed (100%)
    INSERT INTO Refunds (ProceedId, UserId, RefundReason, ReasonDetail, RefundAmount, OriginalAmount, RefundPercent, RefundMethod, Status, RequestedAt, ProcessedAt, ProcessedBy, CompletedAt, AdminNotes, TransactionRef)
    SELECT ProceedId, UserId, 'DuplicatePurchase', N'Bấm mua 2 lần do lỗi mạng',
           TotalAmount, TotalAmount, 100.00, 'Original', 'Completed',
           DATEADD(DAY, -7, GETDATE()), DATEADD(DAY, -7, GETDATE()), @empId, DATEADD(DAY, -6, GETDATE()),
           N'Verified duplicate - full refund approved', 'RFD-SAMPLE-003'
    FROM @ProceedIds WHERE RowNum = 3;

    -- Refund 4: WeatherIssue — Approved (waiting completion)
    INSERT INTO Refunds (ProceedId, UserId, RefundReason, ReasonDetail, RefundAmount, OriginalAmount, RefundPercent, RefundMethod, Status, RequestedAt, ProcessedAt, ProcessedBy, CompletedAt, AdminNotes, TransactionRef)
    SELECT ProceedId, UserId, 'WeatherIssue', N'Dự báo bão số 5 sắp đổ bộ ngày đi',
           TotalAmount, TotalAmount, 100.00, 'BankTransfer', 'Approved',
           DATEADD(DAY, -5, GETDATE()), DATEADD(DAY, -4, GETDATE()), @empId, NULL,
           N'Weather verified - approved, pending bank transfer', 'RFD-SAMPLE-004'
    FROM @ProceedIds WHERE RowNum = 4;

    -- Refund 5: HealthIssue — Requested (pending review)
    INSERT INTO Refunds (ProceedId, UserId, RefundReason, ReasonDetail, RefundAmount, OriginalAmount, RefundPercent, RefundMethod, Status, RequestedAt, ProcessedAt, ProcessedBy, CompletedAt, AdminNotes, TransactionRef)
    SELECT ProceedId, UserId, 'HealthIssue', N'Con bị sốt cao, bác sĩ khuyên không nên ra ngoài',
           TotalAmount, TotalAmount, 100.00, 'Original', 'Requested',
           DATEADD(DAY, -3, GETDATE()), NULL, NULL, NULL,
           NULL, 'RFD-SAMPLE-005'
    FROM @ProceedIds WHERE RowNum = 5;

    -- Refund 6: FamilyEmergency — Completed (100%)
    INSERT INTO Refunds (ProceedId, UserId, RefundReason, ReasonDetail, RefundAmount, OriginalAmount, RefundPercent, RefundMethod, Status, RequestedAt, ProcessedAt, ProcessedBy, CompletedAt, AdminNotes, TransactionRef)
    SELECT ProceedId, UserId, 'FamilyEmergency', N'Bà ngoại nhập viện cấp cứu',
           TotalAmount, TotalAmount, 100.00, 'Original', 'Completed',
           DATEADD(DAY, -6, GETDATE()), DATEADD(DAY, -6, GETDATE()), @empId, DATEADD(DAY, -5, GETDATE()),
           N'Emergency verified - priority refund', 'RFD-SAMPLE-006'
    FROM @ProceedIds WHERE RowNum = 6;

    -- Refund 7: PriceDispute — Rejected
    INSERT INTO Refunds (ProceedId, UserId, RefundReason, ReasonDetail, RefundAmount, OriginalAmount, RefundPercent, RefundMethod, Status, RequestedAt, ProcessedAt, ProcessedBy, CompletedAt, AdminNotes, TransactionRef)
    SELECT ProceedId, UserId, 'PriceDispute', N'Giá trên website khác giá tính tiền, mắc hơn 5$',
           5.00, TotalAmount, 16.67, 'Cash', 'Rejected',
           DATEADD(DAY, -4, GETDATE()), DATEADD(DAY, -3, GETDATE()), @empId, NULL,
           N'Price verified correct - promotional price ended before purchase', 'RFD-SAMPLE-007'
    FROM @ProceedIds WHERE RowNum = 7;

    -- Refund 8: ServiceComplaint — Requested
    INSERT INTO Refunds (ProceedId, UserId, RefundReason, ReasonDetail, RefundAmount, OriginalAmount, RefundPercent, RefundMethod, Status, RequestedAt, ProcessedAt, ProcessedBy, CompletedAt, AdminNotes, TransactionRef)
    SELECT ProceedId, UserId, 'ServiceComplaint', N'Nhân viên không nhiệt tình, khu vực vui chơi bẩn',
           TotalAmount * 0.50, TotalAmount, 50.00, 'BankTransfer', 'Requested',
           DATEADD(DAY, -2, GETDATE()), NULL, NULL, NULL,
           NULL, 'RFD-SAMPLE-008'
    FROM @ProceedIds WHERE RowNum = 8;

    -- Refund 9: EventCancelled — Completed (100%)
    INSERT INTO Refunds (ProceedId, UserId, RefundReason, ReasonDetail, RefundAmount, OriginalAmount, RefundPercent, RefundMethod, Status, RequestedAt, ProcessedAt, ProcessedBy, CompletedAt, AdminNotes, TransactionRef)
    SELECT ProceedId, UserId, 'EventCancelled', N'Ban tổ chức thông báo hủy sự kiện do thiếu nhân sự',
           TotalAmount, TotalAmount, 100.00, 'Original', 'Completed',
           DATEADD(DAY, -5, GETDATE()), DATEADD(DAY, -5, GETDATE()), @empId, DATEADD(DAY, -4, GETDATE()),
           N'Event cancelled by organizer - auto full refund', 'RFD-SAMPLE-009'
    FROM @ProceedIds WHERE RowNum = 9;

    -- Refund 10: Other — Requested
    INSERT INTO Refunds (ProceedId, UserId, RefundReason, ReasonDetail, RefundAmount, OriginalAmount, RefundPercent, RefundMethod, Status, RequestedAt, ProcessedAt, ProcessedBy, CompletedAt, AdminNotes, TransactionRef)
    SELECT ProceedId, UserId, 'Other', N'Đi công tác đột xuất, không kịp đi vào ngày đã mua vé',
           TotalAmount, TotalAmount, 100.00, 'BankTransfer', 'Requested',
           DATEADD(DAY, -1, GETDATE()), NULL, NULL, NULL,
           NULL, 'RFD-SAMPLE-010'
    FROM @ProceedIds WHERE RowNum = 10;

    -- Refund 11: ScheduleChange — Approved
    INSERT INTO Refunds (ProceedId, UserId, RefundReason, ReasonDetail, RefundAmount, OriginalAmount, RefundPercent, RefundMethod, Status, RequestedAt, ProcessedAt, ProcessedBy, CompletedAt, AdminNotes, TransactionRef)
    SELECT ProceedId, UserId, 'ScheduleChange', N'Lịch học đại học thay đổi, trùng ngày thi',
           TotalAmount * 0.80, TotalAmount, 80.00, 'Original', 'Approved',
           DATEADD(DAY, -2, GETDATE()), DATEADD(DAY, -1, GETDATE()), @empId, NULL,
           N'Student schedule change verified - 80% refund approved', 'RFD-SAMPLE-011'
    FROM @ProceedIds WHERE RowNum = 11;

    PRINT N'✅ Đã seed 11 Refunds sample';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN K: SAMPLE MEMBERSHIPS (cho Users mới, 10+ records)    ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Seed MembershipTypes nếu chưa có
IF NOT EXISTS (SELECT 1 FROM MembershipTypes WHERE Name = 'Individual')
BEGIN
    INSERT INTO MembershipTypes (Name, Price, DurationMonths, Benefits)
    VALUES 
        ('Individual', 79.99, 12, N'Unlimited visits, 10% gift shop discount, member events'),
        ('Family', 149.99, 12, N'Unlimited visits for 4, 15% gift shop discount, member events, free parking'),
        ('Premium', 249.99, 12, N'Unlimited visits, 20% all discounts, VIP events, behind-the-scenes tours, free parking'),
        ('Student', 49.99, 12, N'Unlimited visits, 10% food court discount, valid student ID required');
    PRINT N'✅ Đã seed 4 MembershipTypes mới';
END
GO

DECLARE @IndvMembership INT, @FamilyMembership INT, @PremiumMembership INT, @StudentMembership INT;
SELECT @IndvMembership = MembershipTypeId FROM MembershipTypes WHERE Name = 'Individual';
SELECT @FamilyMembership = MembershipTypeId FROM MembershipTypes WHERE Name = 'Family';
SELECT @PremiumMembership = MembershipTypeId FROM MembershipTypes WHERE Name = 'Premium';
SELECT @StudentMembership = MembershipTypeId FROM MembershipTypes WHERE Name = 'Student';

DECLARE @U3 INT, @U4 INT, @U5 INT, @U6 INT, @U7 INT, @U8 INT, @U9 INT, @U10 INT, @U11 INT, @U12 INT;
SELECT @U3 = UserId FROM Users WHERE Email = 'nguyenvana@gmail.com';
SELECT @U4 = UserId FROM Users WHERE Email = 'tranthib@gmail.com';
SELECT @U5 = UserId FROM Users WHERE Email = 'leminhc@gmail.com';
SELECT @U6 = UserId FROM Users WHERE Email = 'phamthid@gmail.com';
SELECT @U7 = UserId FROM Users WHERE Email = 'hoangvane@gmail.com';
SELECT @U8 = UserId FROM Users WHERE Email = 'vothif@gmail.com';
SELECT @U9 = UserId FROM Users WHERE Email = 'dangquocg@gmail.com';
SELECT @U10 = UserId FROM Users WHERE Email = 'buithih@gmail.com';
SELECT @U11 = UserId FROM Users WHERE Email = 'ngothanhi@gmail.com';
SELECT @U12 = UserId FROM Users WHERE Email = 'duongthik@gmail.com';

-- Seed Memberships (10 records)
IF NOT EXISTS (SELECT 1 FROM UserMemberships um INNER JOIN Users u ON um.UserId = u.UserId WHERE u.Email = 'nguyenvana@gmail.com')
BEGIN
    INSERT INTO UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status)
    VALUES
        (@U3,  @IndvMembership,    '2026-01-01', '2027-01-01', 'Active'),
        (@U4,  @FamilyMembership,  '2026-02-15', '2027-02-15', 'Active'),
        (@U5,  @StudentMembership, '2026-03-01', '2027-03-01', 'Active'),
        (@U6,  @PremiumMembership, '2025-06-01', '2026-06-01', 'Active'),
        (@U7,  @IndvMembership,    '2025-10-01', '2026-10-01', 'Active'),
        (@U8,  @FamilyMembership,  '2026-04-01', '2027-04-01', 'Active'),
        (@U9,  @PremiumMembership, '2026-01-15', '2027-01-15', 'Active'),
        (@U10, @StudentMembership, '2025-09-01', '2026-09-01', 'Active'),
        (@U11, @IndvMembership,    '2024-12-01', '2025-12-01', 'Expired'),
        (@U12, @FamilyMembership,  '2026-03-20', '2027-03-20', 'Active');
    PRINT N'✅ Đã seed 10 UserMemberships';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHẦN L: ĐÁNH DẤU CUSTOMERS TABLE LÀ DEPRECATED            ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Ghi vào AuditLog
INSERT INTO AuditLog (TableName, RecordId, Action, OldValues, NewValues)
VALUES (
    'SYSTEM', 0, 'UPDATE',
    N'Bảng Customers đang active, dùng riêng biệt với Users',
    N'Bảng Customers DEPRECATED — Dữ liệu đã merge vào Users. Code C# sẽ dùng Users trực tiếp. Bảng Customers giữ lại tạm cho backward compatibility.'
);
PRINT N'✅ Đã đánh dấu Customers table deprecated';
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SƠ ĐỒ FINAL                                               ║
-- ╚══════════════════════════════════════════════════════════════╝

PRINT N'';
PRINT N'╔══════════════════════════════════════════════════════════════╗';
PRINT N'║  CẤU TRÚC MỚI SAU MIGRATION                              ║';
PRINT N'╠══════════════════════════════════════════════════════════════╣';
PRINT N'║                                                            ║';
PRINT N'║  Users (GỘP từ Users + Customers)                         ║';
PRINT N'║    │── UserId, Username, Email, PasswordHash, FullName     ║';
PRINT N'║    │── Phone, Address, Gender, DateOfBirth, Photo (MỚI)   ║';
PRINT N'║    │── RoleId, CreatedAt, IsActive                        ║';
PRINT N'║    │                                                       ║';
PRINT N'║    ├─→ Proceeds.UserId (thay CustomerId)                  ║';
PRINT N'║    ├─→ UserMemberships.UserId                             ║';
PRINT N'║    ├─→ EventBookings.UserId                               ║';
PRINT N'║    ├─→ Donations.UserId                                   ║';
PRINT N'║    └─→ Refunds.UserId (MỚI)                              ║';
PRINT N'║                                                            ║';
PRINT N'║  Refunds (MỚI)                                            ║';
PRINT N'║    │── ProceedId → Proceeds                               ║';
PRINT N'║    │── UserId → Users                                     ║';
PRINT N'║    │── RefundReason → RefundReasons                       ║';
PRINT N'║    │── ProcessedBy → Employees                            ║';
PRINT N'║    └── Status: Requested → Approved → Completed           ║';
PRINT N'║                                                            ║';
PRINT N'║  RefundReasons (MỚI — Lookup)                             ║';
PRINT N'║    └── 10 lý do chuẩn hóa                                ║';
PRINT N'║                                                            ║';
PRINT N'║  Customers — DEPRECATED (giữ backward compat)            ║';
PRINT N'║                                                            ║';
PRINT N'╚══════════════════════════════════════════════════════════════╝';
GO

PRINT N'';
PRINT N'========================================';
PRINT N'✅ 18_RefundsAndUsersMerge.sql HOÀN TẤT';
PRINT N'========================================';
GO
