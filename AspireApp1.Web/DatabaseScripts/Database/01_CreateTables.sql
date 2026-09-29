-- ============================================================
-- 01_CreateTables.sql
-- ZooDatabase V2 — Tạo tất cả bảng
-- Chạy đầu tiên trên database mới
-- ============================================================

USE [ZooDatabase]
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  NHÓM 1: XÁC THỰC & NGƯỜI DÙNG                            ║
-- ╚══════════════════════════════════════════════════════════════╝

-- 1.1 Roles (Admin, User)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Roles')
CREATE TABLE Roles (
    RoleId      INT IDENTITY(1,1) PRIMARY KEY,
    RoleName    NVARCHAR(50) NOT NULL UNIQUE
);
GO

-- 1.2 Users (Bảng chính — gộp tất cả thông tin người dùng)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
CREATE TABLE Users (
    UserId              INT IDENTITY(1,1) PRIMARY KEY,
    RoleId              INT NOT NULL,
    Username            NVARCHAR(50) NOT NULL UNIQUE,
    Email               NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash        NVARCHAR(256) NOT NULL,
    FullName            NVARCHAR(100) NULL,
    Phone               NVARCHAR(20) NULL,
    Address             NVARCHAR(255) NULL,
    Gender              NVARCHAR(10) NULL,
    DateOfBirth         DATE NULL,
    AvatarPath          NVARCHAR(255) NULL,
    ResetToken          NVARCHAR(100) NULL,
    ResetTokenExpiry    DATETIME NULL,
    IsActive            BIT DEFAULT 1,
    CreatedAt           DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleId) REFERENCES Roles(RoleId),
    CONSTRAINT CK_Users_Gender CHECK (Gender IN ('Male', 'Female', 'Other') OR Gender IS NULL)
);
GO

-- 1.3 UserAvatarHistory (Lịch sử đổi avatar)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserAvatarHistory')
CREATE TABLE UserAvatarHistory (
    AvatarHistoryId INT IDENTITY(1,1) PRIMARY KEY,
    UserId          INT NOT NULL,
    AvatarPath      NVARCHAR(255) NOT NULL,
    UploadedAt      DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_AvatarHistory_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE
);
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  NHÓM 2: NỘI DUNG SỞ THÚ                                  ║
-- ╚══════════════════════════════════════════════════════════════╝

-- 2.1 Zones
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Zones')
CREATE TABLE Zones (
    ZoneId      INT IDENTITY(1,1) PRIMARY KEY,
    Name        NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(MAX) NULL
);
GO

-- 2.2 Animals
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Animals')
CREATE TABLE Animals (
    AnimalId            INT IDENTITY(1,1) PRIMARY KEY,
    ZoneId              INT NOT NULL,
    Name                NVARCHAR(100) NOT NULL,
    Species             NVARCHAR(100) NOT NULL,
    ConservationStatus  NVARCHAR(100) NULL,
    Description         NVARCHAR(MAX) NULL,
    ImagePath           NVARCHAR(255) NULL,

    CONSTRAINT FK_Animals_Zones FOREIGN KEY (ZoneId) REFERENCES Zones(ZoneId)
);
GO

-- 2.3 Attractions
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Attractions')
CREATE TABLE Attractions (
    AttractionId    INT IDENTITY(1,1) PRIMARY KEY,
    ZoneId          INT NOT NULL,
    Name            NVARCHAR(100) NOT NULL,
    Category        NVARCHAR(50) NULL,
    Description     NVARCHAR(MAX) NULL,

    CONSTRAINT FK_Attractions_Zones FOREIGN KEY (ZoneId) REFERENCES Zones(ZoneId)
);
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  NHÓM 3: SẢN PHẨM & DỊCH VỤ (4 LUỒNG MUA HÀNG)          ║
-- ╚══════════════════════════════════════════════════════════════╝

-- 3.1 TicketTypes (Luồng Tickets)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TicketTypes')
CREATE TABLE TicketTypes (
    TicketTypeId    INT IDENTITY(1,1) PRIMARY KEY,
    Name            NVARCHAR(100) NOT NULL,
    BasePrice       DECIMAL(18,2) NOT NULL,
    Description     NVARCHAR(MAX) NULL,
    AgeRange        NVARCHAR(50) NULL,
    IsActive        BIT DEFAULT 1,

    CONSTRAINT CK_TicketTypes_Price CHECK (BasePrice >= 0)
);
GO

-- 3.2 MembershipTypes (Luồng Membership)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MembershipTypes')
CREATE TABLE MembershipTypes (
    MembershipTypeId    INT IDENTITY(1,1) PRIMARY KEY,
    Name                NVARCHAR(100) NOT NULL,
    Price               DECIMAL(18,2) NOT NULL,
    DurationMonths      INT NOT NULL DEFAULT 12,
    Benefits            NVARCHAR(MAX) NULL,
    ImagePath           NVARCHAR(255) NULL,
    IsActive            BIT DEFAULT 1,

    CONSTRAINT CK_MembershipTypes_Price CHECK (Price >= 0),
    CONSTRAINT CK_MembershipTypes_Duration CHECK (DurationMonths > 0)
);
GO

-- 3.3 Events (Luồng Events)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Events')
CREATE TABLE Events (
    EventId     INT IDENTITY(1,1) PRIMARY KEY,
    Title       NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    EventDate   DATETIME NOT NULL,
    Capacity    INT NULL,
    BasePrice   DECIMAL(18,2) NULL,
    ImagePath   NVARCHAR(255) NULL,
    Status      NVARCHAR(50) DEFAULT 'Active',
    Location    NVARCHAR(200) NULL,
    CreatedAt   DATETIME DEFAULT GETDATE(),

    CONSTRAINT CK_Events_Capacity CHECK (Capacity >= 0),
    CONSTRAINT CK_Events_Price CHECK (BasePrice >= 0),
    CONSTRAINT CK_Events_Status CHECK (Status IN ('Active', 'Cancelled', 'Completed', 'Postponed'))
);
GO

-- 3.4 ShopCategories (Luồng Shop)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ShopCategories')
CREATE TABLE ShopCategories (
    CategoryId  INT IDENTITY(1,1) PRIMARY KEY,
    Name        NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(MAX) NULL,
    IconClass   NVARCHAR(50) DEFAULT 'fa-tag',
    SortOrder   INT DEFAULT 0,
    IsActive    BIT DEFAULT 1
);
GO

-- 3.5 ShopProducts (Admin quản lý thêm/sửa/xóa)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ShopProducts')
CREATE TABLE ShopProducts (
    ProductId       INT IDENTITY(1,1) PRIMARY KEY,
    CategoryId      INT NOT NULL,
    Name            NVARCHAR(200) NOT NULL,
    Description     NVARCHAR(MAX) NULL,
    Price           DECIMAL(18,2) NOT NULL,
    ImagePath       NVARCHAR(255) NULL,
    StockQuantity   INT DEFAULT 0,
    IsActive        BIT DEFAULT 1,
    CreatedAt       DATETIME DEFAULT GETDATE(),
    UpdatedAt       DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_ShopProducts_Categories FOREIGN KEY (CategoryId) REFERENCES ShopCategories(CategoryId),
    CONSTRAINT CK_ShopProducts_Price CHECK (Price >= 0),
    CONSTRAINT CK_ShopProducts_Stock CHECK (StockQuantity >= 0)
);
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  NHÓM 4: ĐƠN HÀNG & THANH TOÁN (THỐNG NHẤT 4 LUỒNG)     ║
-- ╚══════════════════════════════════════════════════════════════╝

-- 4.1 Orders (Đơn hàng chính — OrderType phân biệt 4 luồng)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Orders')
CREATE TABLE Orders (
    OrderId         INT IDENTITY(1,1) PRIMARY KEY,
    UserId          INT NULL,
    OrderType       NVARCHAR(20) NOT NULL,          -- 'Ticket', 'Membership', 'Event', 'Shop'
    OrderDate       DATETIME DEFAULT GETDATE(),
    TotalAmount     DECIMAL(18,2) NOT NULL DEFAULT 0,
    PaymentMethod   NVARCHAR(50) DEFAULT 'QR Code',
    PaymentStatus   NVARCHAR(50) DEFAULT 'Pending',
    TransactionRef  NVARCHAR(100) NULL,
    Notes           NVARCHAR(MAX) NULL,
    CreatedAt       DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Orders_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE SET NULL,
    CONSTRAINT CK_Orders_Type CHECK (OrderType IN ('Ticket', 'Membership', 'Event', 'Shop')),
    CONSTRAINT CK_Orders_Total CHECK (TotalAmount >= 0),
    CONSTRAINT CK_Orders_PaymentStatus CHECK (PaymentStatus IN ('Pending', 'Completed', 'Failed', 'Refunded')),
    CONSTRAINT CK_Orders_PaymentMethod CHECK (PaymentMethod IN ('Online', 'Cash', 'Card', 'Transfer', 'QR Code'))
);
GO

-- 4.2 OrderItems (Chi tiết — linh hoạt cho cả 4 loại)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'OrderItems')
CREATE TABLE OrderItems (
    OrderItemId     INT IDENTITY(1,1) PRIMARY KEY,
    OrderId         INT NOT NULL,
    ItemType        NVARCHAR(20) NOT NULL,          -- 'Ticket', 'Membership', 'Event', 'Shop'
    ItemName        NVARCHAR(200) NOT NULL,          -- Tên hiển thị
    -- FK linh hoạt (chỉ 1 trong 4 có giá trị, còn lại NULL)
    TicketTypeId    INT NULL,
    EventId         INT NULL,
    MembershipTypeId INT NULL,
    ProductId       INT NULL,
    VisitDate       DATE NULL,                       -- Ngày tham quan (Ticket, Event)
    Quantity        INT NOT NULL DEFAULT 1,
    UnitPrice       DECIMAL(18,2) NOT NULL,

    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItems_TicketTypes FOREIGN KEY (TicketTypeId) REFERENCES TicketTypes(TicketTypeId),
    CONSTRAINT FK_OrderItems_Events FOREIGN KEY (EventId) REFERENCES Events(EventId),
    CONSTRAINT FK_OrderItems_MembershipTypes FOREIGN KEY (MembershipTypeId) REFERENCES MembershipTypes(MembershipTypeId),
    CONSTRAINT FK_OrderItems_ShopProducts FOREIGN KEY (ProductId) REFERENCES ShopProducts(ProductId),
    CONSTRAINT CK_OrderItems_Type CHECK (ItemType IN ('Ticket', 'Membership', 'Event', 'Shop')),
    CONSTRAINT CK_OrderItems_Qty CHECK (Quantity > 0),
    CONSTRAINT CK_OrderItems_Price CHECK (UnitPrice >= 0)
);
GO

-- 4.3 PaymentLog (Nhật ký thanh toán)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PaymentLog')
CREATE TABLE PaymentLog (
    PaymentLogId    INT IDENTITY(1,1) PRIMARY KEY,
    OrderId         INT NULL,
    Amount          DECIMAL(18,2) NOT NULL,
    PaymentMethod   NVARCHAR(50) NULL,
    TransactionRef  NVARCHAR(100) NULL,
    PaymentDate     DATETIME DEFAULT GETDATE(),
    Status          NVARCHAR(50) DEFAULT 'Success',
    Notes           NVARCHAR(MAX) NULL,

    CONSTRAINT FK_PaymentLog_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
    CONSTRAINT CK_PaymentLog_Status CHECK (Status IN ('Success', 'Failed', 'Refunded', 'Pending'))
);
GO

-- 4.4 UserMemberships (Membership đã kích hoạt)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserMemberships')
CREATE TABLE UserMemberships (
    UserMembershipId    INT IDENTITY(1,1) PRIMARY KEY,
    UserId              INT NOT NULL,
    MembershipTypeId    INT NOT NULL,
    OrderId             INT NULL,
    StartDate           DATETIME NOT NULL,
    EndDate             DATETIME NOT NULL,
    Status              NVARCHAR(50) DEFAULT 'Active',

    CONSTRAINT FK_UserMemberships_Users FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT FK_UserMemberships_Types FOREIGN KEY (MembershipTypeId) REFERENCES MembershipTypes(MembershipTypeId),
    CONSTRAINT FK_UserMemberships_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
    CONSTRAINT CK_UserMemberships_Status CHECK (Status IN ('Active', 'Expired', 'Cancelled'))
);
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  NHÓM 5: TƯƠNG TÁC & HỖ TRỢ                              ║
-- ╚══════════════════════════════════════════════════════════════╝

-- 5.1 Donations
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Donations')
CREATE TABLE Donations (
    DonationId          INT IDENTITY(1,1) PRIMARY KEY,
    DonorFirstName      NVARCHAR(100) NOT NULL,
    DonorLastName       NVARCHAR(100) NOT NULL,
    Email               NVARCHAR(200) NOT NULL,
    Phone               NVARCHAR(50) NULL,
    Amount              DECIMAL(10,2) NOT NULL,
    Currency            NVARCHAR(10) DEFAULT 'USD',
    DonationFrequency   NVARCHAR(20) DEFAULT 'OneTime',
    GiftPurpose         NVARCHAR(100) DEFAULT 'GreatestNeed',
    DedicationType      NVARCHAR(50) DEFAULT 'None',
    DedicationName      NVARCHAR(200) NULL,
    CoverFees           BIT DEFAULT 0,
    TransactionRef      NVARCHAR(100) UNIQUE NOT NULL,
    Status              NVARCHAR(50) DEFAULT 'Pending',
    PaymentMethod       NVARCHAR(50) DEFAULT 'QR',
    Notes               NVARCHAR(MAX) NULL,
    CreatedAt           DATETIME DEFAULT GETDATE(),
    CompletedAt         DATETIME NULL,

    CONSTRAINT CK_Donations_Amount CHECK (Amount > 0),
    CONSTRAINT CK_Donations_Status CHECK (Status IN ('Pending', 'Completed', 'Failed'))
);
GO

-- 5.2 Inquiries (Contact Form)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Inquiries')
CREATE TABLE Inquiries (
    InquiryId   INT IDENTITY(1,1) PRIMARY KEY,
    FirstName   NVARCHAR(100) NOT NULL,
    LastName    NVARCHAR(100) NOT NULL,
    Email       NVARCHAR(200) NOT NULL,
    Subject     NVARCHAR(100) DEFAULT 'General Support',
    Message     NVARCHAR(MAX) NOT NULL,
    Status      NVARCHAR(50) DEFAULT 'New',
    CreatedAt   DATETIME DEFAULT GETDATE(),
    ResolvedAt  DATETIME NULL,

    CONSTRAINT CK_Inquiries_Status CHECK (Status IN ('New', 'InProgress', 'Resolved'))
);
GO

-- 5.3 GroupRequests
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'GroupRequests')
CREATE TABLE GroupRequests (
    RequestId           INT IDENTITY(1,1) PRIMARY KEY,
    OrganizationName    NVARCHAR(200) NOT NULL,
    ContactName         NVARCHAR(200) NOT NULL,
    Email               NVARCHAR(200) NOT NULL,
    Phone               NVARCHAR(50) NULL,
    Headcount           INT NOT NULL,
    PreferredDate       DATE NULL,
    AdditionalNeeds     NVARCHAR(MAX) NOT NULL,
    Status              NVARCHAR(50) DEFAULT 'Pending',
    CreatedAt           DATETIME DEFAULT GETDATE(),
    ProcessedAt         DATETIME NULL,

    CONSTRAINT CK_GroupRequests_Headcount CHECK (Headcount >= 15),
    CONSTRAINT CK_GroupRequests_Status CHECK (Status IN ('Pending', 'Approved', 'Rejected'))
);
GO

-- 5.4 EventSupportLogs
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'EventSupportLogs')
CREATE TABLE EventSupportLogs (
    LogId           INT IDENTITY(1,1) PRIMARY KEY,
    FullName        NVARCHAR(200) NOT NULL,
    Email           NVARCHAR(200) NOT NULL,
    Phone           NVARCHAR(50) NULL,
    EventType       NVARCHAR(100) NOT NULL,
    PreferredDate   DATE NULL,
    GuestCount      INT DEFAULT 0,
    Message         NVARCHAR(MAX) NOT NULL,
    Status          NVARCHAR(50) DEFAULT 'New',
    CreatedAt       DATETIME DEFAULT GETDATE(),
    ResolvedAt      DATETIME NULL,

    CONSTRAINT CK_EventSupport_Status CHECK (Status IN ('New', 'InProgress', 'Resolved'))
);
GO

-- 5.5 Notifications
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Notifications')
CREATE TABLE Notifications (
    NotificationId  INT IDENTITY(1,1) PRIMARY KEY,
    RecipientRole   NVARCHAR(50) NOT NULL,
    RecipientEmail  NVARCHAR(200) NULL,
    Title           NVARCHAR(200) NOT NULL,
    Message         NVARCHAR(500) NOT NULL,
    Type            NVARCHAR(50) NOT NULL,
    ReferenceId     NVARCHAR(100) NULL,
    IconClass       NVARCHAR(50) DEFAULT 'fa-bell',
    IsRead          BIT DEFAULT 0,
    CreatedAt       DATETIME DEFAULT GETDATE(),

    CONSTRAINT CK_Notifications_Type CHECK (Type IN ('Ticket', 'Donation', 'EventRequest', 'Contact', 'System', 'Shop', 'Membership', 'Refund'))
);
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  NHÓM 6: HOÀN TIỀN & AUDIT                                ║
-- ╚══════════════════════════════════════════════════════════════╝

-- 6.1 RefundReasons (Lookup)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RefundReasons')
CREATE TABLE RefundReasons (
    ReasonCode      NVARCHAR(50) PRIMARY KEY,
    ReasonLabel     NVARCHAR(200) NOT NULL,
    ReasonLabelVi   NVARCHAR(200) NULL,
    RequiresDetail  BIT DEFAULT 0,
    IsActive        BIT DEFAULT 1,
    SortOrder       INT DEFAULT 0
);
GO

-- 6.2 Refunds
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Refunds')
CREATE TABLE Refunds (
    RefundId        INT IDENTITY(1,1) PRIMARY KEY,
    OrderId         INT NOT NULL,
    UserId          INT NULL,
    RefundReason    NVARCHAR(50) NOT NULL,
    ReasonDetail    NVARCHAR(MAX) NULL,
    RefundAmount    DECIMAL(18,2) NOT NULL,
    OriginalAmount  DECIMAL(18,2) NOT NULL,
    RefundPercent   DECIMAL(5,2) DEFAULT 100.00,
    RefundMethod    NVARCHAR(50) DEFAULT 'Original',
    Status          NVARCHAR(50) DEFAULT 'Requested',
    RequestedAt     DATETIME DEFAULT GETDATE(),
    ProcessedAt     DATETIME NULL,
    ProcessedBy     INT NULL,               -- UserId of Admin who processed
    CompletedAt     DATETIME NULL,
    AdminNotes      NVARCHAR(MAX) NULL,
    TransactionRef  NVARCHAR(100) NULL,

    CONSTRAINT FK_Refunds_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
    CONSTRAINT FK_Refunds_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE SET NULL,
    CONSTRAINT FK_Refunds_ProcessedBy FOREIGN KEY (ProcessedBy) REFERENCES Users(UserId),
    CONSTRAINT FK_Refunds_Reasons FOREIGN KEY (RefundReason) REFERENCES RefundReasons(ReasonCode),
    CONSTRAINT CK_Refunds_Amount CHECK (RefundAmount >= 0),
    CONSTRAINT CK_Refunds_Original CHECK (OriginalAmount > 0),
    CONSTRAINT CK_Refunds_Percent CHECK (RefundPercent >= 0 AND RefundPercent <= 100),
    CONSTRAINT CK_Refunds_Status CHECK (Status IN ('Requested', 'Approved', 'Rejected', 'Completed')),
    CONSTRAINT CK_Refunds_Method CHECK (RefundMethod IN ('Original', 'BankTransfer', 'Cash'))
);
GO

-- 6.3 AuditLog
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AuditLog')
CREATE TABLE AuditLog (
    AuditId     INT IDENTITY(1,1) PRIMARY KEY,
    TableName   NVARCHAR(100) NOT NULL,
    RecordId    INT NULL,
    Action      NVARCHAR(20) NOT NULL,
    ChangedBy   NVARCHAR(100) DEFAULT SYSTEM_USER,
    ChangedAt   DATETIME DEFAULT GETDATE(),
    OldValues   NVARCHAR(MAX) NULL,
    NewValues   NVARCHAR(MAX) NULL,

    CONSTRAINT CK_AuditLog_Action CHECK (Action IN ('INSERT', 'UPDATE', 'DELETE'))
);
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  INDEXES                                                    ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Users
CREATE NONCLUSTERED INDEX IX_Users_Email ON Users(Email);
CREATE NONCLUSTERED INDEX IX_Users_Username ON Users(Username);
CREATE NONCLUSTERED INDEX IX_Users_RoleId ON Users(RoleId);
CREATE NONCLUSTERED INDEX IX_Users_ResetToken ON Users(ResetToken) WHERE ResetToken IS NOT NULL;

-- Orders
CREATE NONCLUSTERED INDEX IX_Orders_UserId ON Orders(UserId);
CREATE NONCLUSTERED INDEX IX_Orders_OrderDate ON Orders(OrderDate);
CREATE NONCLUSTERED INDEX IX_Orders_OrderType ON Orders(OrderType);
CREATE NONCLUSTERED INDEX IX_Orders_PaymentStatus ON Orders(PaymentStatus);
CREATE NONCLUSTERED INDEX IX_Orders_TransactionRef ON Orders(TransactionRef);

-- OrderItems
CREATE NONCLUSTERED INDEX IX_OrderItems_OrderId ON OrderItems(OrderId);
CREATE NONCLUSTERED INDEX IX_OrderItems_VisitDate ON OrderItems(VisitDate);

-- Events
CREATE NONCLUSTERED INDEX IX_Events_EventDate ON Events(EventDate);
CREATE NONCLUSTERED INDEX IX_Events_Status ON Events(Status);

-- ShopProducts
CREATE NONCLUSTERED INDEX IX_ShopProducts_CategoryId ON ShopProducts(CategoryId);
CREATE NONCLUSTERED INDEX IX_ShopProducts_IsActive ON ShopProducts(IsActive);

-- UserMemberships
CREATE NONCLUSTERED INDEX IX_UserMemberships_UserId ON UserMemberships(UserId);

-- Donations
CREATE NONCLUSTERED INDEX IX_Donations_Status ON Donations(Status);
CREATE NONCLUSTERED INDEX IX_Donations_CreatedAt ON Donations(CreatedAt DESC);

-- Notifications
CREATE NONCLUSTERED INDEX IX_Notifications_Role_Read ON Notifications(RecipientRole, IsRead);
CREATE NONCLUSTERED INDEX IX_Notifications_Email_Read ON Notifications(RecipientEmail, IsRead);
CREATE NONCLUSTERED INDEX IX_Notifications_CreatedAt ON Notifications(CreatedAt DESC);

-- Refunds
CREATE NONCLUSTERED INDEX IX_Refunds_OrderId ON Refunds(OrderId);
CREATE NONCLUSTERED INDEX IX_Refunds_Status ON Refunds(Status);
CREATE NONCLUSTERED INDEX IX_Refunds_RequestedAt ON Refunds(RequestedAt DESC);

-- PaymentLog
CREATE NONCLUSTERED INDEX IX_PaymentLog_OrderId ON PaymentLog(OrderId);
CREATE NONCLUSTERED INDEX IX_PaymentLog_PaymentDate ON PaymentLog(PaymentDate);

-- AuditLog
CREATE NONCLUSTERED INDEX IX_AuditLog_TableName ON AuditLog(TableName);
CREATE NONCLUSTERED INDEX IX_AuditLog_ChangedAt ON AuditLog(ChangedAt DESC);

-- AvatarHistory
CREATE NONCLUSTERED INDEX IX_AvatarHistory_UserId ON UserAvatarHistory(UserId);
GO

PRINT N'╔═══════════════════════════════════════════╗';
PRINT N'║ ✅ 01_CreateTables.sql HOÀN TẤT (20 bảng) ║';
PRINT N'╚═══════════════════════════════════════════╝';
GO
