-- ============================================================
-- 11_ViewsComplete.sql
-- Views cho TẤT CẢ bảng trong ZooDatabase
-- Chạy sau 10_ProceduresRevenue.sql
-- ============================================================

USE [ZooDatabase]
GO

-- ============================================================
-- PHẦN 1: VIEWS CƠ BẢN (1 bảng đơn lẻ)
-- ============================================================

-- View 1: Roles
CREATE OR ALTER VIEW vw_Roles AS
SELECT 
    RoleId,
    RoleName
FROM Roles;
GO

-- View 2: Users (ẩn PasswordHash vì bảo mật)
CREATE OR ALTER VIEW vw_Users AS
SELECT 
    UserId,
    RoleId,
    Username,
    Email,
    FullName,
    CreatedAt
    -- KHÔNG hiển thị PasswordHash
FROM Users;
GO

-- View 3: MembershipTypes
CREATE OR ALTER VIEW vw_MembershipTypes AS
SELECT 
    MembershipTypeId,
    Name,
    Price,
    DurationMonths,
    Benefits
FROM MembershipTypes;
GO

-- View 4: Zones
CREATE OR ALTER VIEW vw_Zones AS
SELECT 
    ZoneId,
    Name,
    Description
FROM Zones;
GO

-- View 5: Animals
CREATE OR ALTER VIEW vw_Animals AS
SELECT 
    AnimalId,
    ZoneId,
    Name,
    Species,
    ConservationStatus,
    Description,
    ImagePath
FROM Animals;
GO

-- View 6: Attractions
CREATE OR ALTER VIEW vw_Attractions AS
SELECT 
    AttractionId,
    ZoneId,
    Name,
    Category,
    Description
FROM Attractions;
GO

-- View 7: Events
CREATE OR ALTER VIEW vw_Events AS
SELECT 
    EventId,
    Title,
    Description,
    EventDate,
    Capacity,
    BasePrice,
    ImagePath,
    Status,
    Location
FROM Events;
GO

-- View 8: TicketTypes
CREATE OR ALTER VIEW vw_TicketTypes AS
SELECT 
    TicketTypeId,
    Name,
    BasePrice,
    Description,
    AgeRange,
    IsActive
FROM TicketTypes;
GO

-- View 9: Orders
CREATE OR ALTER VIEW vw_Orders AS
SELECT 
    OrderId,
    UserId,
    OrderDate,
    TotalAmount,
    PaymentStatus
FROM Orders;
GO

-- View 10: OrderItems
CREATE OR ALTER VIEW vw_OrderItems AS
SELECT 
    OrderItemId,
    OrderId,
    TicketTypeId,
    VisitDate,
    Quantity,
    UnitPrice,
    (Quantity * UnitPrice) AS LineTotal
FROM OrderItems;
GO

-- View 11: Customers (bao gồm Email mới)
CREATE OR ALTER VIEW vw_Customers AS
SELECT 
    CustomerId,
    UserId,
    FirstName,
    FullName,
    Email,
    Phone,
    Address,
    Gender,
    DateOfBirth
FROM Customers;
GO

-- View 12: Employees
CREATE OR ALTER VIEW vw_Employees AS
SELECT 
    EmployeeId,
    UserId,
    FirstName,
    FullName,
    Phone,
    Address,
    Designation
FROM Employees;
GO

-- View 13: Proceeds
CREATE OR ALTER VIEW vw_Proceeds AS
SELECT 
    ProceedId,
    EventId,
    CustomerId,
    TicketTypeId,
    CustomerName,
    Quantity,
    UnitPrice,
    TotalAmount,
    PurchaseDate,
    PaymentMethod,
    PaymentStatus,
    TransactionRef,
    Notes,
    CreatedAt
FROM Proceeds;
GO

-- View 14: PaymentLog
CREATE OR ALTER VIEW vw_PaymentLog AS
SELECT 
    PaymentLogId,
    ProceedId,
    OrderId,
    Amount,
    PaymentMethod,
    TransactionRef,
    PaymentDate,
    Status,
    Notes
FROM PaymentLog;
GO

-- View 15: AuditLog
CREATE OR ALTER VIEW vw_AuditLog AS
SELECT 
    AuditId,
    TableName,
    RecordId,
    Action,
    ChangedBy,
    ChangedAt,
    OldValues,
    NewValues
FROM AuditLog;
GO

-- ============================================================
-- PHẦN 2: VIEWS LIÊN KẾT (JOIN nhiều bảng)
-- Cập nhật lại các view đã có + thêm mới
-- ============================================================

-- View 16: User Details (cập nhật — giữ tên cũ)
CREATE OR ALTER VIEW vw_UserDetails AS
SELECT 
    u.UserId,
    u.Username,
    u.Email,
    u.FullName,
    u.CreatedAt,
    r.RoleId,
    r.RoleName
FROM Users u
INNER JOIN Roles r ON u.RoleId = r.RoleId;
GO

-- View 17: User Memberships Full (giữ tên cũ)
CREATE OR ALTER VIEW vw_UserMembershipsFull AS
SELECT 
    um.UserMembershipId,
    u.UserId,
    u.Username,
    u.FullName,
    mt.MembershipTypeId,
    mt.Name AS MembershipType,
    mt.Price,
    mt.Benefits,
    um.StartDate,
    um.EndDate,
    um.Status,
    CASE 
        WHEN um.EndDate < GETDATE() THEN N'Đã hết hạn'
        WHEN um.EndDate >= GETDATE() AND um.Status = 'Active' THEN N'Đang hoạt động'
        ELSE um.Status
    END AS StatusDisplay
FROM UserMemberships um
INNER JOIN Users u ON um.UserId = u.UserId
INNER JOIN MembershipTypes mt ON um.MembershipTypeId = mt.MembershipTypeId;
GO

-- View 18: Animal Details (giữ tên cũ)
CREATE OR ALTER VIEW vw_AnimalDetails AS
SELECT 
    a.AnimalId,
    a.Name AS AnimalName,
    a.Species,
    a.ConservationStatus,
    a.Description AS AnimalDescription,
    a.ImagePath,
    z.ZoneId,
    z.Name AS ZoneName,
    z.Description AS ZoneDescription
FROM Animals a
INNER JOIN Zones z ON a.ZoneId = z.ZoneId;
GO

-- View 19: Order Details Full (giữ tên cũ)
CREATE OR ALTER VIEW vw_OrderDetailsFull AS
SELECT 
    o.OrderId,
    o.OrderDate,
    o.TotalAmount,
    o.PaymentStatus,
    u.UserId,
    u.Username,
    u.FullName AS CustomerName,
    oi.OrderItemId,
    tt.TicketTypeId,
    tt.Name AS TicketType,
    tt.AgeRange,
    oi.VisitDate,
    oi.Quantity,
    oi.UnitPrice,
    (oi.Quantity * oi.UnitPrice) AS LineTotal
FROM Orders o
LEFT JOIN Users u ON o.UserId = u.UserId
INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId
INNER JOIN TicketTypes tt ON oi.TicketTypeId = tt.TicketTypeId;
GO

-- View 20: Event Bookings Full (giữ tên cũ)
CREATE OR ALTER VIEW vw_EventBookingsFull AS
SELECT 
    eb.BookingId,
    eb.BookingDate,
    eb.Participants,
    eb.TotalPrice,
    e.EventId,
    e.Title AS EventTitle,
    e.EventDate,
    e.Location AS EventLocation,
    e.Status AS EventStatus,
    u.UserId,
    u.Username,
    u.FullName AS CustomerName
FROM EventBookings eb
INNER JOIN Events e ON eb.EventId = e.EventId
INNER JOIN Users u ON eb.UserId = u.UserId;
GO

-- View 21: Proceeds Full (MỚI — join với Event + Customer + TicketType)
CREATE OR ALTER VIEW vw_ProceedsFull AS
SELECT 
    p.ProceedId,
    p.CustomerName,
    p.Quantity,
    p.UnitPrice,
    p.TotalAmount,
    p.PurchaseDate,
    p.PaymentMethod,
    p.PaymentStatus,
    p.TransactionRef,
    p.Notes,
    -- Event info
    e.EventId,
    e.Title AS EventTitle,
    e.EventDate,
    -- Customer info
    c.CustomerId,
    c.Email AS CustomerEmail,
    c.Phone AS CustomerPhone,
    -- Ticket Type info
    tt.TicketTypeId,
    tt.Name AS TicketTypeName,
    tt.AgeRange
FROM Proceeds p
LEFT JOIN Events e ON p.EventId = e.EventId
LEFT JOIN Customers c ON p.CustomerId = c.CustomerId
INNER JOIN TicketTypes tt ON p.TicketTypeId = tt.TicketTypeId;
GO

-- View 22: Customer Info (MỚI — chuyên dùng cho trang CustomerInfo khi đăng nhập)
CREATE OR ALTER VIEW vw_CustomerInfo AS
SELECT 
    c.CustomerId,
    c.FirstName,
    c.FullName,
    c.Email,
    c.Phone,
    c.Address,
    c.Gender,
    c.DateOfBirth,
    u.UserId,
    u.Username,
    u.CreatedAt AS MemberSince,
    r.RoleName,
    -- Thống kê mua hàng
    (SELECT COUNT(*) FROM Proceeds p WHERE p.CustomerId = c.CustomerId) AS TotalTransactions,
    (SELECT ISNULL(SUM(p.TotalAmount), 0) FROM Proceeds p WHERE p.CustomerId = c.CustomerId) AS TotalSpent,
    (SELECT ISNULL(SUM(p.Quantity), 0) FROM Proceeds p WHERE p.CustomerId = c.CustomerId) AS TotalTicketsBought
FROM Customers c
LEFT JOIN Users u ON c.UserId = u.UserId
LEFT JOIN Roles r ON u.RoleId = r.RoleId;
GO

-- View 23: OrderHistory (THAY THẾ bảng OrderHistory đã xóa)
CREATE OR ALTER VIEW vw_OrderHistory AS
SELECT 
    o.OrderId,
    c.CustomerId,
    ISNULL(c.FullName, u.FullName) AS CustomerName,
    o.OrderDate AS PurchaseDate,
    SUM(oi.Quantity) AS TotalQuantity,
    o.TotalAmount AS TotalPrice,
    o.PaymentStatus,
    STRING_AGG(tt.Name + ' x' + CAST(oi.Quantity AS NVARCHAR(5)), ', ') AS OrderDetails
FROM Orders o
LEFT JOIN Users u ON o.UserId = u.UserId
LEFT JOIN Customers c ON u.UserId = c.UserId
INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId
INNER JOIN TicketTypes tt ON oi.TicketTypeId = tt.TicketTypeId
GROUP BY o.OrderId, c.CustomerId, c.FullName, u.FullName, o.OrderDate, o.TotalAmount, o.PaymentStatus;
GO

-- View 24: Daily Revenue Summary (tiện ích cho dashboard)
CREATE OR ALTER VIEW vw_DailyRevenueSummary AS
SELECT 
    CAST(p.PurchaseDate AS DATE) AS SaleDate,
    COUNT(p.ProceedId) AS TransactionCount,
    SUM(p.Quantity) AS TotalTicketsSold,
    SUM(p.TotalAmount) AS TotalRevenue
FROM Proceeds p
WHERE p.PaymentStatus = 'Completed'
GROUP BY CAST(p.PurchaseDate AS DATE);
GO

-- View 25: Monthly Revenue Summary (tiện ích cho dashboard)
CREATE OR ALTER VIEW vw_MonthlyRevenueSummary AS
SELECT 
    YEAR(p.PurchaseDate) AS [Year],
    MONTH(p.PurchaseDate) AS [Month],
    DATENAME(MONTH, p.PurchaseDate) AS MonthName,
    COUNT(p.ProceedId) AS TransactionCount,
    SUM(p.Quantity) AS TotalTicketsSold,
    SUM(p.TotalAmount) AS TotalRevenue
FROM Proceeds p
WHERE p.PaymentStatus = 'Completed'
GROUP BY YEAR(p.PurchaseDate), MONTH(p.PurchaseDate), DATENAME(MONTH, p.PurchaseDate);
GO

PRINT N'========================================';
PRINT N'✅ 11_ViewsComplete.sql HOÀN TẤT (25 Views)';
PRINT N'========================================';
GO
