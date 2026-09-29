

USE [ZooDatabase]
GO

-- Insert từng MembershipType riêng (nếu chưa có)
IF NOT EXISTS (SELECT 1 FROM MembershipTypes WHERE Name = 'Individual')
    INSERT INTO MembershipTypes (Name, Price, DurationMonths, Benefits)
    VALUES ('Individual', 79.99, 12, N'Unlimited visits, 10% gift shop discount, member events');

IF NOT EXISTS (SELECT 1 FROM MembershipTypes WHERE Name = 'Family')
    INSERT INTO MembershipTypes (Name, Price, DurationMonths, Benefits)
    VALUES ('Family', 149.99, 12, N'Unlimited visits for 4, 15% gift shop discount, member events, free parking');

IF NOT EXISTS (SELECT 1 FROM MembershipTypes WHERE Name = 'Premium')
    INSERT INTO MembershipTypes (Name, Price, DurationMonths, Benefits)
    VALUES ('Premium', 249.99, 12, N'Unlimited visits, 20% all discounts, VIP events, behind-the-scenes tours, free parking');

IF NOT EXISTS (SELECT 1 FROM MembershipTypes WHERE Name = 'Student')
    INSERT INTO MembershipTypes (Name, Price, DurationMonths, Benefits)
    VALUES ('Student', 49.99, 12, N'Unlimited visits, 10% food court discount, valid student ID required');

PRINT N'✅ Đã đảm bảo 4 MembershipTypes tồn tại';
GO

-- Xóa membership data lỗi (nếu có)  
-- Rồi insert lại đúng
DECLARE @IndvId INT, @FamilyId INT, @PremiumId INT, @StudentId INT;
SELECT @IndvId = MembershipTypeId FROM MembershipTypes WHERE Name = 'Individual';
SELECT @FamilyId = MembershipTypeId FROM MembershipTypes WHERE Name = 'Family';
SELECT @PremiumId = MembershipTypeId FROM MembershipTypes WHERE Name = 'Premium';
SELECT @StudentId = MembershipTypeId FROM MembershipTypes WHERE Name = 'Student';

-- Kiểm tra debug
PRINT N'Individual ID: ' + ISNULL(CAST(@IndvId AS NVARCHAR), 'NULL');
PRINT N'Family ID: ' + ISNULL(CAST(@FamilyId AS NVARCHAR), 'NULL');
PRINT N'Premium ID: ' + ISNULL(CAST(@PremiumId AS NVARCHAR), 'NULL');
PRINT N'Student ID: ' + ISNULL(CAST(@StudentId AS NVARCHAR), 'NULL');

DECLARE @U3 INT, @U4 INT, @U5 INT, @U6 INT, @U7 INT;
DECLARE @U8 INT, @U9 INT, @U10 INT, @U11 INT, @U12 INT;
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

-- Chỉ insert nếu user này chưa có membership
IF @U3 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM UserMemberships WHERE UserId = @U3)
    INSERT INTO UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status)
    VALUES (@U3, @IndvId, '2026-01-01', '2027-01-01', 'Active');

IF @U4 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM UserMemberships WHERE UserId = @U4)
    INSERT INTO UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status)
    VALUES (@U4, @FamilyId, '2026-02-15', '2027-02-15', 'Active');

IF @U5 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM UserMemberships WHERE UserId = @U5)
    INSERT INTO UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status)
    VALUES (@U5, @StudentId, '2026-03-01', '2027-03-01', 'Active');

IF @U6 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM UserMemberships WHERE UserId = @U6)
    INSERT INTO UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status)
    VALUES (@U6, @PremiumId, '2025-06-01', '2026-06-01', 'Active');

IF @U7 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM UserMemberships WHERE UserId = @U7)
    INSERT INTO UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status)
    VALUES (@U7, @IndvId, '2025-10-01', '2026-10-01', 'Active');

IF @U8 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM UserMemberships WHERE UserId = @U8)
    INSERT INTO UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status)
    VALUES (@U8, @FamilyId, '2026-04-01', '2027-04-01', 'Active');

IF @U9 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM UserMemberships WHERE UserId = @U9)
    INSERT INTO UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status)
    VALUES (@U9, @PremiumId, '2026-01-15', '2027-01-15', 'Active');

IF @U10 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM UserMemberships WHERE UserId = @U10)
    INSERT INTO UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status)
    VALUES (@U10, @StudentId, '2025-09-01', '2026-09-01', 'Active');

IF @U11 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM UserMemberships WHERE UserId = @U11)
    INSERT INTO UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status)
    VALUES (@U11, @IndvId, '2024-12-01', '2025-12-01', 'Expired');

IF @U12 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM UserMemberships WHERE UserId = @U12)
    INSERT INTO UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status)
    VALUES (@U12, @FamilyId, '2026-03-20', '2027-03-20', 'Active');

PRINT N'✅ Đã seed UserMemberships thành công';
GO

PRINT N'╔═══════════════════════════════════╗';
PRINT N'║ ✅ 22_FixMemberships.sql HOÀN TẤT ║';
PRINT N'╚═══════════════════════════════════╝';
GO
