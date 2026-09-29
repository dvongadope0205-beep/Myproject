USE [ZooDatabase]
GO

-- 1. Setup Basic Roles
DECLARE @AdminRoleId INT, @StaffRoleId INT, @CustomerRoleId INT, @MemberRoleId INT;
EXEC sp_CreateRole 'Admin', @AdminRoleId OUTPUT;
EXEC sp_CreateRole 'Staff', @StaffRoleId OUTPUT;
EXEC sp_CreateRole 'Customer', @CustomerRoleId OUTPUT;
EXEC sp_CreateRole 'Membership', @MemberRoleId OUTPUT;

-- 2. Setup Base Users
DECLARE @AdminId INT, @JohnDoeId INT;
EXEC sp_CreateUser 'admin_zoo', 'admin@nationalzoo.com', 'hashed_pwd_here', 'Master Admin', 'Admin', @AdminId OUTPUT;
EXEC sp_CreateUser 'johndoe', 'john@gmail.com', 'hashed_pwd_here', 'John Doe', 'Customer', @JohnDoeId OUTPUT;

-- 3. Populate Membership Types
INSERT INTO MembershipTypes (Name, Price, DurationMonths, Benefits)
VALUES 
('Individual', 50.00, 12, '1 Adult'),
('Joint', 80.00, 12, '2 Adults'),
('Family', 120.00, 12, '2 Adults, 2 Children');

-- 4. Convert John to Member using string mapping in PROC
EXEC sp_AddMembershipToUser @JohnDoeId, 'Family', '2026-04-13';

-- 5. Populate Zones & Animals using stored procedure
-- This validates that PROC auto-creates missing Zones
EXEC sp_InsertAnimal 'African Plains', 'Lion', 'Panthera leo', 'Vulnerable', 'The king of the beasts.', '~/Source/Picture/lion1.jpg';
EXEC sp_InsertAnimal 'African Plains', 'Elephant', 'Loxodonta', 'Endangered', 'Largest land mammal.', '~/Source/Picture/elephant1.jpg';
EXEC sp_InsertAnimal 'Reptile House', 'Crocodile', 'Crocodylidae', 'Least Concern', 'Large aquatic reptile.', '~/Source/Picture/crocodile.jpg';
EXEC sp_InsertAnimal 'Aviary', 'Flamingo', 'Phoenicopteridae', 'Least Concern', 'Tall, pink wading bird.', '~/Source/Picture/flamingo.jpg';

-- 6. Ticket Types Base Data
INSERT INTO TicketTypes (Name, BasePrice)
VALUES 
('Adult', 25.00),
('Child', 15.00),
('Senior', 20.00);

-- 7. Place a ticket order for John Doe via PROC
EXEC sp_PlaceTicketOrder @JohnDoeId, 'Adult', '2026-05-01', 2;
EXEC sp_PlaceTicketOrder @JohnDoeId, 'Child', '2026-05-01', 2;
GO
