-- ============================================================
-- 03_Views.sql
-- ZooDatabase V2 — Tất cả Views
-- Chạy sau 02_StoredProcedures.sql
-- ============================================================

USE [ZooDatabase]
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  VIEWS CƠ BẢN (Bảng đơn lẻ)                               ║
-- ╚══════════════════════════════════════════════════════════════╝

-- V1. Roles
CREATE OR ALTER VIEW vw_Roles AS
SELECT RoleId, RoleName FROM Roles;
GO

-- V2. Users (ẩn PasswordHash, ResetToken)
CREATE OR ALTER VIEW vw_Users AS
SELECT UserId, RoleId, Username, Email, FullName, Phone, Address,
       Gender, DateOfBirth, AvatarPath, IsActive, CreatedAt
FROM Users;
GO

-- V3. TicketTypes
CREATE OR ALTER VIEW vw_TicketTypes AS
SELECT TicketTypeId, Name, BasePrice, Description, AgeRange, IsActive
FROM TicketTypes WHERE IsActive = 1;
GO

-- V4. MembershipTypes
CREATE OR ALTER VIEW vw_MembershipTypes AS
SELECT MembershipTypeId, Name, Price, DurationMonths, Benefits, ImagePath, IsActive
FROM MembershipTypes WHERE IsActive = 1;
GO

-- V5. Events (Active)
CREATE OR ALTER VIEW vw_EventsActive AS
SELECT EventId, Title, Description, EventDate, Capacity, BasePrice, ImagePath, Status, Location, CreatedAt
FROM Events WHERE Status = 'Active';
GO

-- V6. Events (All)
CREATE OR ALTER VIEW vw_Events AS
SELECT EventId, Title, Description, EventDate, Capacity, BasePrice, ImagePath, Status, Location, CreatedAt
FROM Events;
GO

-- V7. Zones
CREATE OR ALTER VIEW vw_Zones AS
SELECT ZoneId, Name, Description FROM Zones;
GO

-- V8. Animals
CREATE OR ALTER VIEW vw_Animals AS
SELECT AnimalId, ZoneId, Name, Species, ConservationStatus, Description, ImagePath
FROM Animals;
GO

-- V9. Attractions
CREATE OR ALTER VIEW vw_Attractions AS
SELECT AttractionId, ZoneId, Name, Category, Description
FROM Attractions;
GO

-- V10. ShopCategories
CREATE OR ALTER VIEW vw_ShopCategories AS
SELECT CategoryId, Name, Description, IconClass, SortOrder, IsActive
FROM ShopCategories WHERE IsActive = 1;
GO

-- V11. ShopProducts (Active)
CREATE OR ALTER VIEW vw_ShopProducts AS
SELECT ProductId, CategoryId, Name, Description, Price, ImagePath, StockQuantity, IsActive, CreatedAt
FROM ShopProducts WHERE IsActive = 1;
GO

-- V12. Orders
CREATE OR ALTER VIEW vw_Orders AS
SELECT OrderId, UserId, OrderType, OrderDate, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, Notes, CreatedAt
FROM Orders;
GO

-- V13. PaymentLog
CREATE OR ALTER VIEW vw_PaymentLog AS
SELECT PaymentLogId, OrderId, Amount, PaymentMethod, TransactionRef, PaymentDate, Status, Notes
FROM PaymentLog;
GO

-- V14. Notifications
CREATE OR ALTER VIEW vw_Notifications AS
SELECT NotificationId, RecipientRole, RecipientEmail, Title, Message, Type, ReferenceId, IconClass, IsRead, CreatedAt
FROM Notifications;
GO

-- V15. AuditLog
CREATE OR ALTER VIEW vw_AuditLog AS
SELECT AuditId, TableName, RecordId, Action, ChangedBy, ChangedAt, OldValues, NewValues
FROM AuditLog;
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  VIEWS LIÊN KẾT (JOIN nhiều bảng)                          ║
-- ╚══════════════════════════════════════════════════════════════╝

-- V16. User Profile (đầy đủ với thống kê)
CREATE OR ALTER VIEW vw_UserProfile AS
SELECT 
    u.UserId, u.Username, u.FullName, u.Email, u.Phone, u.Address,
    u.Gender, u.DateOfBirth, u.AvatarPath, u.IsActive,
    u.CreatedAt AS MemberSince,
    r.RoleName,
    (SELECT COUNT(*) FROM Orders o WHERE o.UserId = u.UserId AND o.PaymentStatus = 'Completed') AS TotalOrders,
    (SELECT ISNULL(SUM(o.TotalAmount), 0) FROM Orders o WHERE o.UserId = u.UserId AND o.PaymentStatus = 'Completed') AS TotalSpent,
    (SELECT COUNT(*) FROM Refunds rf WHERE rf.UserId = u.UserId) AS TotalRefunds
FROM Users u
LEFT JOIN Roles r ON u.RoleId = r.RoleId;
GO

-- V17. User Details (User + Role)
CREATE OR ALTER VIEW vw_UserDetails AS
SELECT 
    u.UserId, u.Username, u.Email, u.FullName, u.CreatedAt,
    r.RoleId, r.RoleName
FROM Users u
INNER JOIN Roles r ON u.RoleId = r.RoleId;
GO

-- V18. User Memberships Full
CREATE OR ALTER VIEW vw_UserMembershipsFull AS
SELECT 
    um.UserMembershipId, u.UserId, u.Username, u.FullName,
    mt.MembershipTypeId, mt.Name AS MembershipType, mt.Price, mt.Benefits,
    um.StartDate, um.EndDate, um.Status,
    CASE 
        WHEN um.EndDate < GETDATE() THEN N'Đã hết hạn'
        WHEN um.Status = 'Active' THEN N'Đang hoạt động'
        ELSE um.Status
    END AS StatusDisplay
FROM UserMemberships um
INNER JOIN Users u ON um.UserId = u.UserId
INNER JOIN MembershipTypes mt ON um.MembershipTypeId = mt.MembershipTypeId;
GO

-- V19. Animal Details (+ Zone)
CREATE OR ALTER VIEW vw_AnimalDetails AS
SELECT 
    a.AnimalId, a.Name AS AnimalName, a.Species, a.ConservationStatus,
    a.Description AS AnimalDescription, a.ImagePath,
    z.ZoneId, z.Name AS ZoneName, z.Description AS ZoneDescription
FROM Animals a
INNER JOIN Zones z ON a.ZoneId = z.ZoneId;
GO

-- V20. Shop Products Full (+ Category)
CREATE OR ALTER VIEW vw_ShopProductsFull AS
SELECT 
    sp.ProductId, sp.Name AS ProductName, sp.Description, sp.Price,
    sp.ImagePath, sp.StockQuantity, sp.IsActive, sp.CreatedAt, sp.UpdatedAt,
    sc.CategoryId, sc.Name AS CategoryName, sc.IconClass
FROM ShopProducts sp
INNER JOIN ShopCategories sc ON sp.CategoryId = sc.CategoryId;
GO

-- V21. Orders Full (+ User + Items)
CREATE OR ALTER VIEW vw_OrdersFull AS
SELECT 
    o.OrderId, o.OrderType, o.OrderDate, o.TotalAmount,
    o.PaymentMethod, o.PaymentStatus, o.TransactionRef, o.Notes,
    u.UserId, u.Username, u.FullName AS CustomerName, u.Email AS CustomerEmail,
    (SELECT COUNT(*) FROM OrderItems oi WHERE oi.OrderId = o.OrderId) AS ItemCount
FROM Orders o
LEFT JOIN Users u ON o.UserId = u.UserId;
GO

-- V22. Order Details (từng item)
CREATE OR ALTER VIEW vw_OrderDetailsFull AS
SELECT 
    o.OrderId, o.OrderType, o.OrderDate, o.TotalAmount, o.PaymentStatus, o.TransactionRef,
    u.UserId, u.FullName AS CustomerName,
    oi.OrderItemId, oi.ItemType, oi.ItemName, oi.Quantity, oi.UnitPrice,
    (oi.Quantity * oi.UnitPrice) AS LineTotal, oi.VisitDate
FROM Orders o
LEFT JOIN Users u ON o.UserId = u.UserId
INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId;
GO

-- V23. Order History (cho trang CustomerInfo)
CREATE OR ALTER VIEW vw_OrderHistory AS
SELECT 
    o.OrderId, o.OrderType, o.OrderDate, o.TotalAmount,
    o.PaymentMethod, o.PaymentStatus, o.TransactionRef,
    u.UserId, u.FullName AS CustomerName,
    STRING_AGG(oi.ItemName + ' x' + CAST(oi.Quantity AS NVARCHAR(5)), ', ') AS OrderDetails
FROM Orders o
LEFT JOIN Users u ON o.UserId = u.UserId
INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId
GROUP BY o.OrderId, o.OrderType, o.OrderDate, o.TotalAmount, 
         o.PaymentMethod, o.PaymentStatus, o.TransactionRef, u.UserId, u.FullName;
GO

-- V24. Daily Revenue
CREATE OR ALTER VIEW vw_DailyRevenue AS
SELECT 
    CAST(o.OrderDate AS DATE) AS SaleDate,
    o.OrderType,
    COUNT(o.OrderId) AS OrderCount,
    SUM(o.TotalAmount) AS TotalRevenue
FROM Orders o
WHERE o.PaymentStatus = 'Completed'
GROUP BY CAST(o.OrderDate AS DATE), o.OrderType;
GO

-- V25. Monthly Revenue
CREATE OR ALTER VIEW vw_MonthlyRevenue AS
SELECT 
    YEAR(o.OrderDate) AS [Year],
    MONTH(o.OrderDate) AS [Month],
    DATENAME(MONTH, o.OrderDate) AS MonthName,
    o.OrderType,
    COUNT(o.OrderId) AS OrderCount,
    SUM(o.TotalAmount) AS TotalRevenue
FROM Orders o
WHERE o.PaymentStatus = 'Completed'
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate), DATENAME(MONTH, o.OrderDate), o.OrderType;
GO

-- V26. Refunds Summary
CREATE OR ALTER VIEW vw_RefundsSummary AS
SELECT 
    r.RefundId, r.OrderId,
    u.FullName AS CustomerName, u.Email AS CustomerEmail,
    rr.ReasonLabel, rr.ReasonLabelVi, r.ReasonDetail,
    r.RefundAmount, r.OriginalAmount, r.RefundPercent,
    r.RefundMethod, r.Status, r.RequestedAt, r.ProcessedAt,
    admin_u.FullName AS ProcessedByName,
    r.CompletedAt, r.AdminNotes, r.TransactionRef,
    o.TransactionRef AS OriginalTransactionRef,
    o.OrderType, o.PaymentMethod AS OriginalPaymentMethod
FROM Refunds r
INNER JOIN Orders o ON r.OrderId = o.OrderId
LEFT JOIN Users u ON r.UserId = u.UserId
LEFT JOIN Users admin_u ON r.ProcessedBy = admin_u.UserId
LEFT JOIN RefundReasons rr ON r.RefundReason = rr.ReasonCode;
GO

-- V27. Refund Statistics
CREATE OR ALTER VIEW vw_RefundStatistics AS
SELECT 
    COUNT(*) AS TotalRequests,
    SUM(CASE WHEN Status = 'Requested' THEN 1 ELSE 0 END) AS Pending,
    SUM(CASE WHEN Status = 'Approved' THEN 1 ELSE 0 END) AS Approved,
    SUM(CASE WHEN Status = 'Rejected' THEN 1 ELSE 0 END) AS Rejected,
    SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) AS Completed,
    SUM(CASE WHEN Status = 'Completed' THEN RefundAmount ELSE 0 END) AS TotalRefunded
FROM Refunds;
GO

-- V28. Donations Summary
CREATE OR ALTER VIEW vw_DonationsSummary AS
SELECT 
    DonationId,
    DonorFirstName + ' ' + DonorLastName AS DonorFullName,
    Email, Phone, Amount, Currency, DonationFrequency, GiftPurpose,
    DedicationType, DedicationName, CoverFees,
    TransactionRef, Status, PaymentMethod, CreatedAt, CompletedAt
FROM Donations;
GO

-- V29. Donations Statistics
CREATE OR ALTER VIEW vw_DonationsStatistics AS
SELECT 
    COUNT(*) AS TotalDonations,
    SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) AS CompletedDonations,
    SUM(CASE WHEN Status = 'Completed' THEN Amount ELSE 0 END) AS TotalAmountCompleted,
    AVG(CASE WHEN Status = 'Completed' THEN Amount ELSE NULL END) AS AverageDonation,
    MAX(CASE WHEN Status = 'Completed' THEN Amount ELSE NULL END) AS LargestDonation
FROM Donations;
GO

-- V30. Unread Notifications Count
CREATE OR ALTER VIEW vw_UnreadNotifications AS
SELECT 
    RecipientRole, RecipientEmail,
    COUNT(*) AS UnreadCount
FROM Notifications
WHERE IsRead = 0
GROUP BY RecipientRole, RecipientEmail;
GO

-- V31. EventSupportLogs Summary
CREATE OR ALTER VIEW vw_EventSupportSummary AS
SELECT 
    LogId, FullName, Email, Phone, EventType, PreferredDate, GuestCount,
    LEFT(Message, 150) + CASE WHEN LEN(Message) > 150 THEN '...' ELSE '' END AS MessagePreview,
    Status, CreatedAt, ResolvedAt
FROM EventSupportLogs;
GO

-- V32. Inquiries Summary
CREATE OR ALTER VIEW vw_InquiriesSummary AS
SELECT 
    InquiryId,
    FirstName + ' ' + LastName AS FullName,
    Email, Subject,
    LEFT(Message, 100) + CASE WHEN LEN(Message) > 100 THEN '...' ELSE '' END AS MessagePreview,
    Status, CreatedAt, ResolvedAt
FROM Inquiries;
GO

-- V33. GroupRequests Summary
CREATE OR ALTER VIEW vw_GroupRequestsSummary AS
SELECT 
    RequestId, OrganizationName, ContactName, Email,
    Headcount, PreferredDate, Status, CreatedAt
FROM GroupRequests;
GO

PRINT N'╔═════════════════════════════════════════╗';
PRINT N'║ ✅ 03_Views.sql HOÀN TẤT (33 Views)    ║';
PRINT N'╚═════════════════════════════════════════╝';
GO
