USE [ZooDatabase]
GO

-- 1. View for User Details (combines Users and Roles)
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

-- 2. View for User Memberships details
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
    um.Status
FROM UserMemberships um
INNER JOIN Users u ON um.UserId = u.UserId
INNER JOIN MembershipTypes mt ON um.MembershipTypeId = mt.MembershipTypeId;
GO

-- 3. View for Animal and their Habitat/Zone
CREATE OR ALTER VIEW vw_AnimalDetails AS
SELECT 
    a.AnimalId,
    a.Name AS AnimalName,
    a.Species,
    a.ConservationStatus,
    a.ImagePath,
    z.ZoneId,
    z.Name AS ZoneName,
    z.Description AS ZoneDescription
FROM Animals a
INNER JOIN Zones z ON a.ZoneId = z.ZoneId;
GO

-- 4. View for Full Ticket Order History
CREATE OR ALTER VIEW vw_OrderDetailsFull AS
SELECT 
    o.OrderId,
    o.OrderDate,
    o.TotalAmount,
    o.PaymentStatus,
    u.UserId,
    u.Username,
    oi.OrderItemId,
    tt.Name AS TicketType,
    oi.VisitDate,
    oi.Quantity,
    oi.UnitPrice,
    (oi.Quantity * oi.UnitPrice) AS LineTotal
FROM Orders o
LEFT JOIN Users u ON o.UserId = u.UserId
INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId
INNER JOIN TicketTypes tt ON oi.TicketTypeId = tt.TicketTypeId;
GO

-- 5. View for Event Bookings
CREATE OR ALTER VIEW vw_EventBookingsFull AS
SELECT 
    eb.BookingId,
    eb.BookingDate,
    eb.Participants,
    eb.TotalPrice,
    e.EventId,
    e.Title AS EventTitle,
    e.EventDate,
    u.UserId,
    u.Username
FROM EventBookings eb
INNER JOIN Events e ON eb.EventId = e.EventId
INNER JOIN Users u ON eb.UserId = u.UserId;
GO
