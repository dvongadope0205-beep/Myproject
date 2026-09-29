USE [ZooDatabase];
GO

-- Set standard SQL options required for triggers and computed columns
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_WARNINGS ON;
SET ANSI_PADDING ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET ARITHABORT ON;
GO

SET NOCOUNT ON;

PRINT '=========================================================================';
PRINT 'RUNNING ADVANCED SYSTEM INTEGRATION & QA/QC VALIDATION TESTS (V2)';
PRINT '=========================================================================';

-- -------------------------------------------------------------------------
-- SETUP MOCK DATA
-- -------------------------------------------------------------------------
PRINT 'Setting up mock test users, memberships, experiences, and orders...';

-- Clean up any previous test remnants first
DELETE FROM dbo.PaymentLog WHERE OrderId IN (SELECT OrderId FROM dbo.Orders WHERE Notes LIKE 'QA-TEST-%');
DELETE FROM dbo.PaymentLog WHERE Notes LIKE 'QA-TEST-%';
DELETE FROM dbo.OrderItems WHERE ItemName LIKE 'QA-TEST-%';
DELETE FROM dbo.UserMemberships WHERE UserId IN (SELECT UserId FROM dbo.Users WHERE Username IN ('qa_member_active', 'qa_member_expired', 'qa_member_expired_status', 'qa_non_member'));
DELETE FROM dbo.Orders WHERE Notes LIKE 'QA-TEST-%';
DELETE FROM dbo.Users WHERE Username IN ('qa_member_active', 'qa_member_expired', 'qa_member_expired_status', 'qa_non_member');
DELETE FROM dbo.Experience WHERE Name = 'QA-TEST-Experience';

-- Get standard User Role
DECLARE @RoleId INT;
SELECT @RoleId = RoleId FROM dbo.Roles WHERE RoleName = 'User';
IF @RoleId IS NULL
BEGIN
    INSERT INTO dbo.Roles (RoleName) VALUES ('User');
    SET @RoleId = SCOPE_IDENTITY();
END

-- 1. Create Test Users
INSERT INTO dbo.Users (RoleId, Username, Email, PasswordHash, FullName, IsActive) VALUES
(@RoleId, 'qa_member_active', 'qa_active@test.com', 'hash', 'QA Active Member', 1),
(@RoleId, 'qa_member_expired', 'qa_expired@test.com', 'hash', 'QA Expired Date Member', 1),
(@RoleId, 'qa_member_expired_status', 'qa_expired_status@test.com', 'hash', 'QA Expired Status Member', 1),
(@RoleId, 'qa_non_member', 'qa_non@test.com', 'hash', 'QA Non-Member', 1);

DECLARE @UserIdActive INT, @UserIdExpired INT, @UserIdExpiredStatus INT, @UserIdNonMember INT;
SELECT @UserIdActive = UserId FROM dbo.Users WHERE Username = 'qa_member_active';
SELECT @UserIdExpired = UserId FROM dbo.Users WHERE Username = 'qa_member_expired';
SELECT @UserIdExpiredStatus = UserId FROM dbo.Users WHERE Username = 'qa_member_expired_status';
SELECT @UserIdNonMember = UserId FROM dbo.Users WHERE Username = 'qa_non_member';

-- 2. Setup Membership Type
DECLARE @MembershipTypeId INT;
SELECT @MembershipTypeId = MembershipTypeId FROM dbo.MembershipTypes WHERE Name = 'Standard';
IF @MembershipTypeId IS NULL
BEGIN
    INSERT INTO dbo.MembershipTypes (Name, Price, DurationMonths, IsActive) VALUES ('Standard', 50.00, 12, 1);
    SET @MembershipTypeId = SCOPE_IDENTITY();
END

-- 3. Create User Memberships
-- A. Active Membership: End date is in the future
INSERT INTO dbo.UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status)
VALUES (@UserIdActive, @MembershipTypeId, DATEADD(day, -30, GETUTCDATE()), DATEADD(day, 30, GETUTCDATE()), 'Active');

-- B. Expired Membership (by Date): End date is in the past
INSERT INTO dbo.UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status)
VALUES (@UserIdExpired, @MembershipTypeId, DATEADD(day, -60, GETUTCDATE()), DATEADD(day, -1, GETUTCDATE()), 'Active');

-- C. Expired Membership (by Status): End date in future but status is Expired
INSERT INTO dbo.UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status)
VALUES (@UserIdExpiredStatus, @MembershipTypeId, DATEADD(day, -10, GETUTCDATE()), DATEADD(day, 10, GETUTCDATE()), 'Expired');

-- 4. Create Test Experience (Price $100.00)
INSERT INTO dbo.Experience (Name, Description, Price, Location, ZoneId)
VALUES ('QA-TEST-Experience', 'QA Test Experience description', 100.00, 'Test Location', 1);

DECLARE @ExperienceId INT = SCOPE_IDENTITY();

-- -------------------------------------------------------------------------
-- TEST CASES
-- -------------------------------------------------------------------------
PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'TEST CASE 1: Active Member Booking (Should get 20% discount)';
PRINT '-------------------------------------------------------------------------';

-- Create order for Active Member
DECLARE @OrderIdActive INT;
INSERT INTO dbo.Orders (UserId, OrderType, TotalAmount, Notes)
VALUES (@UserIdActive, 'Event', 100.00, 'QA-TEST-Active-Order');
SET @OrderIdActive = SCOPE_IDENTITY();

-- Insert experience item (Joining by ExperienceId)
INSERT INTO dbo.OrderItems (OrderId, ItemType, ItemName, ExperienceId, Quantity, UnitPrice)
VALUES (@OrderIdActive, 'Event', 'QA-TEST-Experience', @ExperienceId, 1, 100.00);

-- Verify
DECLARE @PriceActive DECIMAL(18,2), @TotalActive DECIMAL(18,2);
SELECT @PriceActive = UnitPrice FROM dbo.OrderItems WHERE OrderId = @OrderIdActive;
SELECT @TotalActive = TotalAmount FROM dbo.Orders WHERE OrderId = @OrderIdActive;

IF @PriceActive = 80.00 AND @TotalActive = 80.00
    PRINT '  ✔ TC-09 (Active Member) Passed: UnitPrice = $80.00, Order Total = $80.00 (20% discount applied)';
ELSE
    PRINT '  ❌ TC-09 (Active Member) Failed: UnitPrice = $' + CAST(@PriceActive AS VARCHAR) + ', Total = $' + CAST(@TotalActive AS VARCHAR);

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'TEST CASE 2: Non-Member Booking (Should NOT get discount)';
PRINT '-------------------------------------------------------------------------';

-- Create order for Non-Member
DECLARE @OrderIdNon INT;
INSERT INTO dbo.Orders (UserId, OrderType, TotalAmount, Notes)
VALUES (@UserIdNonMember, 'Event', 100.00, 'QA-TEST-NonMember-Order');
SET @OrderIdNon = SCOPE_IDENTITY();

INSERT INTO dbo.OrderItems (OrderId, ItemType, ItemName, ExperienceId, Quantity, UnitPrice)
VALUES (@OrderIdNon, 'Event', 'QA-TEST-Experience', @ExperienceId, 1, 100.00);

-- Verify
DECLARE @PriceNon DECIMAL(18,2), @TotalNon DECIMAL(18,2);
SELECT @PriceNon = UnitPrice FROM dbo.OrderItems WHERE OrderId = @OrderIdNon;
SELECT @TotalNon = TotalAmount FROM dbo.Orders WHERE OrderId = @OrderIdNon;

IF @PriceNon = 100.00 AND @TotalNon = 100.00
    PRINT '  ✔ TC-10 (Non-Member) Passed: UnitPrice = $100.00, Order Total = $100.00 (No discount)';
ELSE
    PRINT '  ❌ TC-10 (Non-Member) Failed: UnitPrice = $' + CAST(@PriceNon AS VARCHAR) + ', Total = $' + CAST(@TotalNon AS VARCHAR);

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'TEST CASE 3: TC-11 - Member with Expired Date (Should NOT get discount)';
PRINT '-------------------------------------------------------------------------';

-- Create order for Member with Expired Date
DECLARE @OrderIdExpDate INT;
INSERT INTO dbo.Orders (UserId, OrderType, TotalAmount, Notes)
VALUES (@UserIdExpired, 'Event', 100.00, 'QA-TEST-ExpiredDate-Order');
SET @OrderIdExpDate = SCOPE_IDENTITY();

INSERT INTO dbo.OrderItems (OrderId, ItemType, ItemName, ExperienceId, Quantity, UnitPrice)
VALUES (@OrderIdExpDate, 'Event', 'QA-TEST-Experience', @ExperienceId, 1, 100.00);

-- Verify
DECLARE @PriceExpDate DECIMAL(18,2), @TotalExpDate DECIMAL(18,2);
SELECT @PriceExpDate = UnitPrice FROM dbo.OrderItems WHERE OrderId = @OrderIdExpDate;
SELECT @TotalExpDate = TotalAmount FROM dbo.Orders WHERE OrderId = @OrderIdExpDate;

IF @PriceExpDate = 100.00 AND @TotalExpDate = 100.00
    PRINT '  ✔ TC-11a (Expired Date Member) Passed: UnitPrice = $100.00, Order Total = $100.00 (No discount)';
ELSE
    PRINT '  ❌ TC-11a (Expired Date Member) Failed: UnitPrice = $' + CAST(@PriceExpDate AS VARCHAR) + ', Total = $' + CAST(@TotalExpDate AS VARCHAR);

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'TEST CASE 4: TC-11 - Member with Expired Status (Should NOT get discount)';
PRINT '-------------------------------------------------------------------------';

-- Create order for Member with Expired Status
DECLARE @OrderIdExpStatus INT;
INSERT INTO dbo.Orders (UserId, OrderType, TotalAmount, Notes)
VALUES (@UserIdExpiredStatus, 'Event', 100.00, 'QA-TEST-ExpiredStatus-Order');
SET @OrderIdExpStatus = SCOPE_IDENTITY();

INSERT INTO dbo.OrderItems (OrderId, ItemType, ItemName, ExperienceId, Quantity, UnitPrice)
VALUES (@OrderIdExpStatus, 'Event', 'QA-TEST-Experience', @ExperienceId, 1, 100.00);

-- Verify
DECLARE @PriceExpStatus DECIMAL(18,2), @TotalExpStatus DECIMAL(18,2);
SELECT @PriceExpStatus = UnitPrice FROM dbo.OrderItems WHERE OrderId = @OrderIdExpStatus;
SELECT @TotalExpStatus = TotalAmount FROM dbo.Orders WHERE OrderId = @OrderIdExpStatus;

IF @PriceExpStatus = 100.00 AND @TotalExpStatus = 100.00
    PRINT '  ✔ TC-11b (Expired Status Member) Passed: UnitPrice = $100.00, Order Total = $100.00 (No discount)';
ELSE
    PRINT '  ❌ TC-11b (Expired Status Member) Failed: UnitPrice = $' + CAST(@PriceExpStatus AS VARCHAR) + ', Total = $' + CAST(@TotalExpStatus AS VARCHAR);

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'TEST CASE 5: Constraint Validation - Expired Status on Events Table';
PRINT '-------------------------------------------------------------------------';

-- Insert event with 'Expired' status (should succeed now under updated CK_Events_Status)
BEGIN TRY
    INSERT INTO Events (Title, Description, EventDate, Capacity, BasePrice, ImagePath, Status)
    VALUES ('QA Expired Event', 'Integration test expired', GETUTCDATE(), 100, 10.00, '/images/test.jpg', 'Expired');
    
    DECLARE @TempEventId INT = SCOPE_IDENTITY();
    DELETE FROM Events WHERE EventId = @TempEventId;
    PRINT '  ✔ Check Constraint Update Passed: Status = ''Expired'' is allowed on Events table.';
END TRY
BEGIN CATCH
    PRINT '  ❌ Check Constraint Update Failed: ' + ERROR_MESSAGE();
END CATCH

-- -------------------------------------------------------------------------
-- CLEANUP MOCK DATA
-- -------------------------------------------------------------------------
PRINT '';
PRINT 'Cleaning up database...';
DELETE FROM dbo.PaymentLog WHERE OrderId IN (SELECT OrderId FROM dbo.Orders WHERE Notes LIKE 'QA-TEST-%');
DELETE FROM dbo.PaymentLog WHERE Notes LIKE 'QA-TEST-%';
DELETE FROM dbo.OrderItems WHERE ItemName LIKE 'QA-TEST-%';
DELETE FROM dbo.UserMemberships WHERE UserId IN (@UserIdActive, @UserIdExpired, @UserIdExpiredStatus, @UserIdNonMember);
DELETE FROM dbo.Orders WHERE Notes LIKE 'QA-TEST-%';
DELETE FROM dbo.Users WHERE Username IN ('qa_member_active', 'qa_member_expired', 'qa_member_expired_status', 'qa_non_member');
DELETE FROM dbo.Experience WHERE Name = 'QA-TEST-Experience';

PRINT 'All Integration Checks Finished.';
GO
