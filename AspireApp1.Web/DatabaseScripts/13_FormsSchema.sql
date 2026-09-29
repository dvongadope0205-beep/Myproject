-- ============================================================
-- 13_FormsSchema.sql
-- Bảng Inquiries (Contact Form) và GroupRequests (Group Booking)
-- ============================================================
USE ZooDatabase;
GO

-- ===================== INQUIRIES TABLE =====================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Inquiries')
BEGIN
    CREATE TABLE Inquiries (
        InquiryId       INT IDENTITY(1,1) PRIMARY KEY,
        FirstName       NVARCHAR(100) NOT NULL,
        LastName        NVARCHAR(100) NOT NULL,
        Email           NVARCHAR(200) NOT NULL,
        Subject         NVARCHAR(100) DEFAULT 'General Support',
        Message         NVARCHAR(MAX) NOT NULL,
        Status          NVARCHAR(50) DEFAULT 'New', -- New, In Progress, Resolved
        CreatedAt       DATETIME DEFAULT GETDATE(),
        ResolvedAt      DATETIME NULL,
        ResolvedBy      INT NULL -- FK to Employees
    );
    PRINT 'Created table: Inquiries';
END
GO

-- ===================== GROUP REQUESTS TABLE =====================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'GroupRequests')
BEGIN
    CREATE TABLE GroupRequests (
        RequestId       INT IDENTITY(1,1) PRIMARY KEY,
        OrganizationName NVARCHAR(200) NOT NULL,
        ContactName     NVARCHAR(200) NOT NULL,
        Email           NVARCHAR(200) NOT NULL,
        Phone           NVARCHAR(50) NULL,
        Headcount       INT NOT NULL CHECK (Headcount >= 15),
        PreferredDate   DATE NULL,
        AdditionalNeeds NVARCHAR(MAX) NOT NULL,
        Status          NVARCHAR(50) DEFAULT 'Pending', -- Pending, Approved, Rejected
        CreatedAt       DATETIME DEFAULT GETDATE(),
        ProcessedAt     DATETIME NULL,
        ProcessedBy     INT NULL -- FK to Employees
    );
    PRINT 'Created table: GroupRequests';
END
GO

-- ===================== INDEXES =====================
CREATE INDEX IX_Inquiries_Status ON Inquiries(Status);
CREATE INDEX IX_Inquiries_CreatedAt ON Inquiries(CreatedAt DESC);
CREATE INDEX IX_GroupRequests_Status ON GroupRequests(Status);
CREATE INDEX IX_GroupRequests_PreferredDate ON GroupRequests(PreferredDate);
GO

-- ===================== VIEWS =====================
-- View cho Inquiries
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_InquiriesSummary') DROP VIEW vw_InquiriesSummary;
GO
CREATE VIEW vw_InquiriesSummary AS
SELECT 
    InquiryId,
    FirstName + ' ' + LastName AS FullName,
    Email,
    Subject,
    LEFT(Message, 100) + '...' AS MessagePreview,
    Status,
    CreatedAt,
    ResolvedAt
FROM Inquiries;
GO

-- View cho GroupRequests
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_GroupRequestsSummary') DROP VIEW vw_GroupRequestsSummary;
GO
CREATE VIEW vw_GroupRequestsSummary AS
SELECT 
    RequestId,
    OrganizationName,
    ContactName,
    Email,
    Headcount,
    PreferredDate,
    Status,
    CreatedAt
FROM GroupRequests;
GO

PRINT '=== 13_FormsSchema.sql completed ===';
