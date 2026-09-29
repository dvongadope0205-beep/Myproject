-- ============================================================
-- 15_DonationsNotifications.sql
-- Bảng Donations, EventSupportLogs, Notifications
-- + Views + Indexes
-- ============================================================
USE ZooDatabase;
GO

-- ===================== DONATIONS TABLE =====================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Donations')
BEGIN
    CREATE TABLE Donations (
        DonationId        INT IDENTITY(1,1) PRIMARY KEY,
        DonorFirstName    NVARCHAR(100) NOT NULL,
        DonorLastName     NVARCHAR(100) NOT NULL,
        Email             NVARCHAR(200) NOT NULL,
        Phone             NVARCHAR(50) NULL,
        Amount            DECIMAL(10,2) NOT NULL CHECK (Amount > 0),
        Currency          NVARCHAR(10) DEFAULT 'USD',
        DonationFrequency NVARCHAR(20) DEFAULT 'OneTime',    -- OneTime / Monthly
        GiftPurpose       NVARCHAR(100) DEFAULT 'GreatestNeed', -- AnimalCare / Conservation / GreatestNeed
        DedicationType    NVARCHAR(50) DEFAULT 'None',        -- None / InHonorOf / InMemoryOf
        DedicationName    NVARCHAR(200) NULL,
        CoverFees         BIT DEFAULT 0,
        TransactionRef    NVARCHAR(100) UNIQUE NOT NULL,
        Status            NVARCHAR(50) DEFAULT 'Pending',     -- Pending / Completed / Failed
        PaymentMethod     NVARCHAR(50) DEFAULT 'QR',          -- QR / Card / BankTransfer
        Notes             NVARCHAR(MAX) NULL,
        CreatedAt         DATETIME DEFAULT GETDATE(),
        CompletedAt       DATETIME NULL
    );
    PRINT 'Created table: Donations';
END
GO

-- ===================== EVENT SUPPORT LOGS TABLE =====================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'EventSupportLogs')
BEGIN
    CREATE TABLE EventSupportLogs (
        LogId             INT IDENTITY(1,1) PRIMARY KEY,
        FullName          NVARCHAR(200) NOT NULL,
        Email             NVARCHAR(200) NOT NULL,
        Phone             NVARCHAR(50) NULL,
        EventType         NVARCHAR(100) NOT NULL,             -- Birthday / Corporate / Wedding / SchoolTrip / Other
        PreferredDate     DATE NULL,
        GuestCount        INT DEFAULT 0,
        Message           NVARCHAR(MAX) NOT NULL,
        Status            NVARCHAR(50) DEFAULT 'New',         -- New / InProgress / Resolved
        CreatedAt         DATETIME DEFAULT GETDATE(),
        ResolvedAt        DATETIME NULL,
        ResolvedBy        INT NULL                             -- FK to Employees (optional)
    );
    PRINT 'Created table: EventSupportLogs';
END
GO

-- ===================== NOTIFICATIONS TABLE =====================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Notifications')
BEGIN
    CREATE TABLE Notifications (
        NotificationId    INT IDENTITY(1,1) PRIMARY KEY,
        RecipientRole     NVARCHAR(50) NOT NULL,              -- Admin / Customer
        RecipientEmail    NVARCHAR(200) NULL,                 -- NULL = all admins, specific email = specific user
        Title             NVARCHAR(200) NOT NULL,
        Message           NVARCHAR(500) NOT NULL,
        Type              NVARCHAR(50) NOT NULL,              -- Ticket / Donation / EventRequest / Contact / System
        ReferenceId       NVARCHAR(100) NULL,                 -- TransactionRef or InquiryId etc.
        IconClass         NVARCHAR(50) DEFAULT 'fa-bell',     -- FontAwesome icon class
        IsRead            BIT DEFAULT 0,
        CreatedAt         DATETIME DEFAULT GETDATE()
    );
    PRINT 'Created table: Notifications';
END
GO

-- ===================== INDEXES =====================
-- Donations indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Donations_Status')
    CREATE INDEX IX_Donations_Status ON Donations(Status);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Donations_CreatedAt')
    CREATE INDEX IX_Donations_CreatedAt ON Donations(CreatedAt DESC);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Donations_Email')
    CREATE INDEX IX_Donations_Email ON Donations(Email);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Donations_TransactionRef')
    CREATE INDEX IX_Donations_TransactionRef ON Donations(TransactionRef);

-- EventSupportLogs indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_EventSupportLogs_Status')
    CREATE INDEX IX_EventSupportLogs_Status ON EventSupportLogs(Status);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_EventSupportLogs_CreatedAt')
    CREATE INDEX IX_EventSupportLogs_CreatedAt ON EventSupportLogs(CreatedAt DESC);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_EventSupportLogs_EventType')
    CREATE INDEX IX_EventSupportLogs_EventType ON EventSupportLogs(EventType);

-- Notifications indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Notifications_RecipientRole')
    CREATE INDEX IX_Notifications_RecipientRole ON Notifications(RecipientRole, IsRead);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Notifications_RecipientEmail')
    CREATE INDEX IX_Notifications_RecipientEmail ON Notifications(RecipientEmail, IsRead);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Notifications_CreatedAt')
    CREATE INDEX IX_Notifications_CreatedAt ON Notifications(CreatedAt DESC);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Notifications_Type')
    CREATE INDEX IX_Notifications_Type ON Notifications(Type);
GO

-- ===================== VIEWS =====================

-- View: Donations Summary
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_DonationsSummary') DROP VIEW vw_DonationsSummary;
GO
CREATE VIEW vw_DonationsSummary AS
SELECT 
    DonationId,
    DonorFirstName + ' ' + DonorLastName AS DonorFullName,
    Email,
    Phone,
    Amount,
    Currency,
    DonationFrequency,
    GiftPurpose,
    DedicationType,
    DedicationName,
    CoverFees,
    TransactionRef,
    Status,
    PaymentMethod,
    CreatedAt,
    CompletedAt
FROM Donations;
GO

-- View: Donations Statistics (totals)
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_DonationsStatistics') DROP VIEW vw_DonationsStatistics;
GO
CREATE VIEW vw_DonationsStatistics AS
SELECT 
    COUNT(*) AS TotalDonations,
    SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) AS CompletedDonations,
    SUM(CASE WHEN Status = 'Pending' THEN 1 ELSE 0 END) AS PendingDonations,
    SUM(CASE WHEN Status = 'Completed' THEN Amount ELSE 0 END) AS TotalAmountCompleted,
    SUM(Amount) AS TotalAmountAll,
    AVG(CASE WHEN Status = 'Completed' THEN Amount ELSE NULL END) AS AverageDonation,
    MAX(CASE WHEN Status = 'Completed' THEN Amount ELSE NULL END) AS LargestDonation,
    SUM(CASE WHEN DonationFrequency = 'Monthly' THEN 1 ELSE 0 END) AS MonthlyDonors,
    SUM(CASE WHEN DonationFrequency = 'OneTime' THEN 1 ELSE 0 END) AS OneTimeDonors
FROM Donations;
GO

-- View: Donations by Gift Purpose
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_DonationsByPurpose') DROP VIEW vw_DonationsByPurpose;
GO
CREATE VIEW vw_DonationsByPurpose AS
SELECT 
    GiftPurpose,
    COUNT(*) AS DonationCount,
    SUM(CASE WHEN Status = 'Completed' THEN Amount ELSE 0 END) AS TotalAmount,
    AVG(CASE WHEN Status = 'Completed' THEN Amount ELSE NULL END) AS AvgAmount
FROM Donations
GROUP BY GiftPurpose;
GO

-- View: Recent Donations (last 30 days)
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_RecentDonations') DROP VIEW vw_RecentDonations;
GO
CREATE VIEW vw_RecentDonations AS
SELECT 
    DonationId,
    DonorFirstName + ' ' + DonorLastName AS DonorName,
    Email,
    Amount,
    GiftPurpose,
    DonationFrequency,
    TransactionRef,
    Status,
    CreatedAt
FROM Donations
WHERE CreatedAt >= DATEADD(DAY, -30, GETDATE());
GO

-- View: EventSupportLogs Summary
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_EventSupportLogsSummary') DROP VIEW vw_EventSupportLogsSummary;
GO
CREATE VIEW vw_EventSupportLogsSummary AS
SELECT 
    LogId,
    FullName,
    Email,
    Phone,
    EventType,
    PreferredDate,
    GuestCount,
    LEFT(Message, 150) + CASE WHEN LEN(Message) > 150 THEN '...' ELSE '' END AS MessagePreview,
    Status,
    CreatedAt,
    ResolvedAt
FROM EventSupportLogs;
GO

-- View: EventSupportLogs Statistics
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_EventSupportStatistics') DROP VIEW vw_EventSupportStatistics;
GO
CREATE VIEW vw_EventSupportStatistics AS
SELECT 
    COUNT(*) AS TotalRequests,
    SUM(CASE WHEN Status = 'New' THEN 1 ELSE 0 END) AS NewRequests,
    SUM(CASE WHEN Status = 'InProgress' THEN 1 ELSE 0 END) AS InProgressRequests,
    SUM(CASE WHEN Status = 'Resolved' THEN 1 ELSE 0 END) AS ResolvedRequests,
    SUM(GuestCount) AS TotalGuests,
    AVG(GuestCount) AS AvgGuestCount
FROM EventSupportLogs;
GO

-- View: EventSupportLogs by Type
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_EventSupportByType') DROP VIEW vw_EventSupportByType;
GO
CREATE VIEW vw_EventSupportByType AS
SELECT 
    EventType,
    COUNT(*) AS RequestCount,
    SUM(GuestCount) AS TotalGuests,
    SUM(CASE WHEN Status = 'New' THEN 1 ELSE 0 END) AS Pending,
    SUM(CASE WHEN Status = 'Resolved' THEN 1 ELSE 0 END) AS Resolved
FROM EventSupportLogs
GROUP BY EventType;
GO

-- View: Notifications Summary
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_NotificationsSummary') DROP VIEW vw_NotificationsSummary;
GO
CREATE VIEW vw_NotificationsSummary AS
SELECT 
    NotificationId,
    RecipientRole,
    RecipientEmail,
    Title,
    Message,
    Type,
    ReferenceId,
    IconClass,
    IsRead,
    CreatedAt
FROM Notifications;
GO

-- View: Unread Notifications Count by Role
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_UnreadNotificationsByRole') DROP VIEW vw_UnreadNotificationsByRole;
GO
CREATE VIEW vw_UnreadNotificationsByRole AS
SELECT 
    RecipientRole,
    RecipientEmail,
    COUNT(*) AS UnreadCount
FROM Notifications
WHERE IsRead = 0
GROUP BY RecipientRole, RecipientEmail;
GO

-- View: Notifications Statistics
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_NotificationsStatistics') DROP VIEW vw_NotificationsStatistics;
GO
CREATE VIEW vw_NotificationsStatistics AS
SELECT 
    COUNT(*) AS TotalNotifications,
    SUM(CASE WHEN IsRead = 0 THEN 1 ELSE 0 END) AS UnreadCount,
    SUM(CASE WHEN IsRead = 1 THEN 1 ELSE 0 END) AS ReadCount,
    SUM(CASE WHEN Type = 'Ticket' THEN 1 ELSE 0 END) AS TicketNotifs,
    SUM(CASE WHEN Type = 'Donation' THEN 1 ELSE 0 END) AS DonationNotifs,
    SUM(CASE WHEN Type = 'EventRequest' THEN 1 ELSE 0 END) AS EventNotifs,
    SUM(CASE WHEN Type = 'Contact' THEN 1 ELSE 0 END) AS ContactNotifs
FROM Notifications;
GO

PRINT '=== 15_DonationsNotifications.sql completed ==='
