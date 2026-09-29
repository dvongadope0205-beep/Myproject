USE [ZooDatabase]
GO

-- PROCEDURE: Create Role
CREATE OR ALTER PROC sp_CreateRole 
    @RoleName NVARCHAR(50), 
    @RoleId INT OUTPUT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = @RoleName)
    BEGIN
        INSERT INTO Roles (RoleName) VALUES (@RoleName);
        SET @RoleId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        SELECT @RoleId = RoleId FROM Roles WHERE RoleName = @RoleName;
    END
END
GO

-- PROCEDURE: Mange Users / Login
CREATE OR ALTER PROC sp_CreateUser
    @Username NVARCHAR(50),
    @Email NVARCHAR(100),
    @PasswordHash NVARCHAR(256),
    @FullName NVARCHAR(100),
    @RoleName NVARCHAR(50),
    @UserId INT OUTPUT
AS
BEGIN
    DECLARE @RoleId INT;
    SELECT @RoleId = RoleId FROM Roles WHERE RoleName = @RoleName;
    
    -- Default to Customer if role not found
    IF @RoleId IS NULL 
    BEGIN
        SELECT @RoleId = RoleId FROM Roles WHERE RoleName = 'Customer';
    END

    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName)
    VALUES (@RoleId, @Username, @Email, @PasswordHash, @FullName);

    SET @UserId = SCOPE_IDENTITY();
END
GO

-- PROCEDURE: Insert Member/Membership
CREATE OR ALTER PROC sp_AddMembershipToUser
    @UserId INT,
    @MembershipTypeName NVARCHAR(100),
    @StartDate DATETIME
AS
BEGIN
    DECLARE @MembershipTypeId INT, @DurationMonths INT;
    SELECT @MembershipTypeId = MembershipTypeId, @DurationMonths = DurationMonths 
    FROM MembershipTypes WHERE Name = @MembershipTypeName;

    IF @MembershipTypeId IS NOT NULL
    BEGIN
        INSERT INTO UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status)
        VALUES (@UserId, @MembershipTypeId, @StartDate, DATEADD(MONTH, @DurationMonths, @StartDate), 'Active');
    END
END
GO

-- PROCEDURE: Setup Animal Data
CREATE OR ALTER PROC sp_InsertAnimal
    @ZoneName NVARCHAR(100),
    @AnimalName NVARCHAR(100),
    @Species NVARCHAR(100),
    @ConservationStatus NVARCHAR(100),
    @Description NVARCHAR(MAX),
    @ImagePath NVARCHAR(255)
AS
BEGIN
    DECLARE @ZoneId INT;
    SELECT @ZoneId = ZoneId FROM Zones WHERE Name = @ZoneName;
    
    -- Auto create zone if missing
    IF @ZoneId IS NULL
    BEGIN
        INSERT INTO Zones (Name) VALUES (@ZoneName);
        SET @ZoneId = SCOPE_IDENTITY();
    END

    INSERT INTO Animals (ZoneId, Name, Species, ConservationStatus, Description, ImagePath)
    VALUES (@ZoneId, @AnimalName, @Species, @ConservationStatus, @Description, @ImagePath);
END
GO

-- PROCEDURE: Place Ticket Order
CREATE OR ALTER PROC sp_PlaceTicketOrder
    @UserId INT, -- NULL for Guest
    @TicketTypeName NVARCHAR(100),
    @VisitDate DATE,
    @Quantity INT
AS
BEGIN
    DECLARE @TicketTypeId INT, @UnitPrice DECIMAL(18,2);
    SELECT @TicketTypeId = TicketTypeId, @UnitPrice = BasePrice FROM TicketTypes WHERE Name = @TicketTypeName;

    IF @TicketTypeId IS NOT NULL
    BEGIN
        DECLARE @OrderId INT;
        DECLARE @TotalAmount DECIMAL(18,2) = @UnitPrice * @Quantity;

        INSERT INTO Orders (UserId, TotalAmount, PaymentStatus)
        VALUES (@UserId, @TotalAmount, 'Completed');
        SET @OrderId = SCOPE_IDENTITY();

        INSERT INTO OrderItems (OrderId, TicketTypeId, VisitDate, Quantity, UnitPrice)
        VALUES (@OrderId, @TicketTypeId, @VisitDate, @Quantity, @UnitPrice);
    END
END
GO
