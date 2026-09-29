-- ============================================================
-- 08_SchemaOptimization.sql
-- Tối ưu hóa schema: ALTER bảng, thêm bảng mới, constraints, indexes
-- Chạy sau 07_NewAuthSchema.sql
-- ============================================================

USE [ZooDatabase]
GO

-- ============================================================
-- PHẦN 1: XÓA BẢNG DƯ THỪA
-- ============================================================

-- Xóa bảng OrderHistory (sẽ thay bằng VIEW ở script Views)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OrderHistory]') AND type in (N'U'))
BEGIN
    DROP TABLE OrderHistory;
    PRINT N'✅ Đã xóa bảng OrderHistory (thay bằng VIEW)';
END
GO

-- ============================================================
-- PHẦN 2: ALTER CÁC BẢNG HIỆN TẠI
-- ============================================================

-- 2a. Customers: Thêm Email, DateOfBirth, Gender
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Customers') AND name = 'Email')
BEGIN
    ALTER TABLE Customers ADD Email NVARCHAR(100);
    PRINT N'✅ Đã thêm cột Email vào Customers';
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Customers') AND name = 'DateOfBirth')
BEGIN
    ALTER TABLE Customers ADD DateOfBirth DATE;
    PRINT N'✅ Đã thêm cột DateOfBirth vào Customers';
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Customers') AND name = 'Gender')
BEGIN
    ALTER TABLE Customers ADD Gender NVARCHAR(10);
    PRINT N'✅ Đã thêm cột Gender vào Customers';
END
GO

-- 2b. Events: Thêm ImagePath, Status, Location
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Events') AND name = 'ImagePath')
BEGIN
    ALTER TABLE Events ADD ImagePath NVARCHAR(255);
    PRINT N'✅ Đã thêm cột ImagePath vào Events';
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Events') AND name = 'Status')
BEGIN
    ALTER TABLE Events ADD Status NVARCHAR(50) DEFAULT 'Active';
    PRINT N'✅ Đã thêm cột Status vào Events';
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Events') AND name = 'Location')
BEGIN
    ALTER TABLE Events ADD Location NVARCHAR(200);
    PRINT N'✅ Đã thêm cột Location vào Events';
END
GO

-- 2c. TicketTypes: Thêm Description, AgeRange, IsActive
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('TicketTypes') AND name = 'Description')
BEGIN
    ALTER TABLE TicketTypes ADD Description NVARCHAR(MAX);
    PRINT N'✅ Đã thêm cột Description vào TicketTypes';
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('TicketTypes') AND name = 'AgeRange')
BEGIN
    ALTER TABLE TicketTypes ADD AgeRange NVARCHAR(50);
    PRINT N'✅ Đã thêm cột AgeRange vào TicketTypes';
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('TicketTypes') AND name = 'IsActive')
BEGIN
    ALTER TABLE TicketTypes ADD IsActive BIT DEFAULT 1;
    PRINT N'✅ Đã thêm cột IsActive vào TicketTypes';
END
GO

-- Cập nhật dữ liệu TicketTypes hiện có
UPDATE TicketTypes SET Description = N'Vé dành cho người lớn từ 12 tuổi trở lên', AgeRange = '12+', IsActive = 1 WHERE Name = 'Adult';
UPDATE TicketTypes SET Description = N'Vé dành cho trẻ em từ 3 đến 11 tuổi', AgeRange = '3-11', IsActive = 1 WHERE Name = 'Child';
UPDATE TicketTypes SET Description = N'Vé ưu đãi cho người cao tuổi từ 65 tuổi', AgeRange = '65+', IsActive = 1 WHERE Name = 'Senior';
PRINT N'✅ Đã cập nhật dữ liệu TicketTypes';
GO

-- Cập nhật Email cho customer test hiện có
UPDATE c SET c.Email = u.Email
FROM Customers c
INNER JOIN Users u ON c.UserId = u.UserId
WHERE c.Email IS NULL;
PRINT N'✅ Đã đồng bộ Email từ Users sang Customers';
GO

-- ============================================================
-- PHẦN 3: TẠO BẢNG MỚI
-- ============================================================

-- 3a. Bảng Proceeds — Ghi nhận doanh thu bán vé
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Proceeds]') AND type in (N'U'))
BEGIN
    CREATE TABLE Proceeds (
        ProceedId       INT IDENTITY(1,1) PRIMARY KEY,
        EventId         INT NULL,                                   -- FK → Events (NULL nếu vé vào cổng thường)
        CustomerId      INT NULL,                                   -- FK → Customers
        TicketTypeId    INT NOT NULL,                                -- FK → TicketTypes (Adult/Child/Senior)
        CustomerName    NVARCHAR(150) NOT NULL,                      -- Tên khách hàng mua vé
        Quantity        INT NOT NULL,                                -- Số lượng vé
        UnitPrice       DECIMAL(18,2) NOT NULL,                      -- Đơn giá mỗi vé
        TotalAmount     DECIMAL(18,2) NULL,                          -- Tổng thu (trigger tự tính)
        PurchaseDate    DATETIME DEFAULT GETDATE(),                  -- Ngày mua
        PaymentMethod   NVARCHAR(50) DEFAULT 'Online',               -- Online/Cash/Card/Transfer
        PaymentStatus   NVARCHAR(50) DEFAULT 'Completed',            -- Completed/Pending/Refunded/Failed
        TransactionRef  NVARCHAR(100) NULL,                          -- Mã giao dịch tham chiếu
        Notes           NVARCHAR(MAX) NULL,                          -- Ghi chú thêm
        CreatedAt       DATETIME DEFAULT GETDATE(),                  -- Thời gian tạo record

        CONSTRAINT FK_Proceeds_Events FOREIGN KEY (EventId) REFERENCES Events(EventId),
        CONSTRAINT FK_Proceeds_Customers FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId),
        CONSTRAINT FK_Proceeds_TicketTypes FOREIGN KEY (TicketTypeId) REFERENCES TicketTypes(TicketTypeId),
        CONSTRAINT CK_Proceeds_Quantity CHECK (Quantity > 0),
        CONSTRAINT CK_Proceeds_UnitPrice CHECK (UnitPrice >= 0),
        CONSTRAINT CK_Proceeds_PaymentStatus CHECK (PaymentStatus IN ('Completed', 'Pending', 'Refunded', 'Failed')),
        CONSTRAINT CK_Proceeds_PaymentMethod CHECK (PaymentMethod IN ('Online', 'Cash', 'Card', 'Transfer'))
    );
    PRINT N'✅ Đã tạo bảng Proceeds';
END
GO

-- 3b. Bảng PaymentLog — Nhật ký thanh toán
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PaymentLog]') AND type in (N'U'))
BEGIN
    CREATE TABLE PaymentLog (
        PaymentLogId    INT IDENTITY(1,1) PRIMARY KEY,
        ProceedId       INT NULL,                                    -- FK → Proceeds (NULL nếu từ Orders)
        OrderId         INT NULL,                                    -- FK → Orders (NULL nếu từ Proceeds)
        Amount          DECIMAL(18,2) NOT NULL,                      -- Số tiền thanh toán
        PaymentMethod   NVARCHAR(50) NULL,                           -- Phương thức thanh toán
        TransactionRef  NVARCHAR(100) NULL,                          -- Mã giao dịch
        PaymentDate     DATETIME DEFAULT GETDATE(),                  -- Ngày thanh toán
        Status          NVARCHAR(50) DEFAULT 'Success',              -- Success/Failed/Refunded
        Notes           NVARCHAR(MAX) NULL,                          -- Ghi chú

        CONSTRAINT FK_PaymentLog_Proceeds FOREIGN KEY (ProceedId) REFERENCES Proceeds(ProceedId),
        CONSTRAINT FK_PaymentLog_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
        CONSTRAINT CK_PaymentLog_Status CHECK (Status IN ('Success', 'Failed', 'Refunded'))
    );
    PRINT N'✅ Đã tạo bảng PaymentLog';
END
GO

-- 3c. Bảng AuditLog — Nhật ký thay đổi dữ liệu
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AuditLog]') AND type in (N'U'))
BEGIN
    CREATE TABLE AuditLog (
        AuditId     INT IDENTITY(1,1) PRIMARY KEY,
        TableName   NVARCHAR(100) NOT NULL,              -- Tên bảng bị thay đổi
        RecordId    INT NULL,                             -- ID record bị ảnh hưởng
        Action      NVARCHAR(20) NOT NULL,                -- INSERT / UPDATE / DELETE
        ChangedBy   NVARCHAR(100) DEFAULT SYSTEM_USER,    -- Ai thay đổi
        ChangedAt   DATETIME DEFAULT GETDATE(),           -- Khi nào
        OldValues   NVARCHAR(MAX) NULL,                   -- Giá trị cũ (JSON format)
        NewValues   NVARCHAR(MAX) NULL,                   -- Giá trị mới (JSON format)

        CONSTRAINT CK_AuditLog_Action CHECK (Action IN ('INSERT', 'UPDATE', 'DELETE'))
    );
    PRINT N'✅ Đã tạo bảng AuditLog';
END
GO

-- ============================================================
-- PHẦN 4: CHECK CONSTRAINTS cho các bảng hiện tại
-- ============================================================

-- EventBookings
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_EventBookings_Participants')
BEGIN
    ALTER TABLE EventBookings ADD CONSTRAINT CK_EventBookings_Participants CHECK (Participants > 0);
    PRINT N'✅ Thêm CHECK Participants > 0 cho EventBookings';
END

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_EventBookings_TotalPrice')
BEGIN
    ALTER TABLE EventBookings ADD CONSTRAINT CK_EventBookings_TotalPrice CHECK (TotalPrice >= 0);
    PRINT N'✅ Thêm CHECK TotalPrice >= 0 cho EventBookings';
END

-- OrderItems
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_OrderItems_Quantity')
BEGIN
    ALTER TABLE OrderItems ADD CONSTRAINT CK_OrderItems_Quantity CHECK (Quantity > 0);
    PRINT N'✅ Thêm CHECK Quantity > 0 cho OrderItems';
END

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_OrderItems_UnitPrice')
BEGIN
    ALTER TABLE OrderItems ADD CONSTRAINT CK_OrderItems_UnitPrice CHECK (UnitPrice >= 0);
    PRINT N'✅ Thêm CHECK UnitPrice >= 0 cho OrderItems';
END

-- Orders
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Orders_TotalAmount')
BEGIN
    ALTER TABLE Orders ADD CONSTRAINT CK_Orders_TotalAmount CHECK (TotalAmount >= 0);
    PRINT N'✅ Thêm CHECK TotalAmount >= 0 cho Orders';
END

-- Events
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Events_Capacity')
BEGIN
    ALTER TABLE Events ADD CONSTRAINT CK_Events_Capacity CHECK (Capacity >= 0);
    PRINT N'✅ Thêm CHECK Capacity >= 0 cho Events';
END

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Events_BasePrice')
BEGIN
    ALTER TABLE Events ADD CONSTRAINT CK_Events_BasePrice CHECK (BasePrice >= 0);
    PRINT N'✅ Thêm CHECK BasePrice >= 0 cho Events';
END

-- TicketTypes
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_TicketTypes_BasePrice')
BEGIN
    ALTER TABLE TicketTypes ADD CONSTRAINT CK_TicketTypes_BasePrice CHECK (BasePrice >= 0);
    PRINT N'✅ Thêm CHECK BasePrice >= 0 cho TicketTypes';
END

-- MembershipTypes
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_MembershipTypes_Price')
BEGIN
    ALTER TABLE MembershipTypes ADD CONSTRAINT CK_MembershipTypes_Price CHECK (Price >= 0);
    PRINT N'✅ Thêm CHECK Price >= 0 cho MembershipTypes';
END

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_MembershipTypes_Duration')
BEGIN
    ALTER TABLE MembershipTypes ADD CONSTRAINT CK_MembershipTypes_Duration CHECK (DurationMonths > 0);
    PRINT N'✅ Thêm CHECK DurationMonths > 0 cho MembershipTypes';
END
GO

-- ============================================================
-- PHẦN 5: INDEXES cho hiệu năng
-- ============================================================

-- Users indexes (login performance)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_Email')
    CREATE NONCLUSTERED INDEX IX_Users_Email ON Users(Email);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_Username')
    CREATE NONCLUSTERED INDEX IX_Users_Username ON Users(Username);

-- Orders indexes (revenue reports)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Orders_OrderDate')
    CREATE NONCLUSTERED INDEX IX_Orders_OrderDate ON Orders(OrderDate);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Orders_UserId')
    CREATE NONCLUSTERED INDEX IX_Orders_UserId ON Orders(UserId);

-- Events indexes
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Events_EventDate')
    CREATE NONCLUSTERED INDEX IX_Events_EventDate ON Events(EventDate);

-- OrderItems indexes
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OrderItems_VisitDate')
    CREATE NONCLUSTERED INDEX IX_OrderItems_VisitDate ON OrderItems(VisitDate);

-- Proceeds indexes (revenue queries, most critical)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Proceeds_PurchaseDate')
    CREATE NONCLUSTERED INDEX IX_Proceeds_PurchaseDate ON Proceeds(PurchaseDate);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Proceeds_EventId')
    CREATE NONCLUSTERED INDEX IX_Proceeds_EventId ON Proceeds(EventId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Proceeds_CustomerId')
    CREATE NONCLUSTERED INDEX IX_Proceeds_CustomerId ON Proceeds(CustomerId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Proceeds_TicketTypeId')
    CREATE NONCLUSTERED INDEX IX_Proceeds_TicketTypeId ON Proceeds(TicketTypeId);

-- EventBookings indexes
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_EventBookings_EventId')
    CREATE NONCLUSTERED INDEX IX_EventBookings_EventId ON EventBookings(EventId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_EventBookings_UserId')
    CREATE NONCLUSTERED INDEX IX_EventBookings_UserId ON EventBookings(UserId);

-- PaymentLog indexes
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PaymentLog_PaymentDate')
    CREATE NONCLUSTERED INDEX IX_PaymentLog_PaymentDate ON PaymentLog(PaymentDate);

-- Customers indexes
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Customers_UserId')
    CREATE NONCLUSTERED INDEX IX_Customers_UserId ON Customers(UserId);

PRINT N'✅ Đã tạo tất cả Indexes';
GO

PRINT N'========================================';
PRINT N'✅ 08_SchemaOptimization.sql HOÀN TẤT';
PRINT N'========================================';
GO
