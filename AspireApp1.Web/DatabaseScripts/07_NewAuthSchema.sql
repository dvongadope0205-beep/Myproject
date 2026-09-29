USE [ZooDatabase]
GO

-- 1. Create Roles if not existing
IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Admin')
BEGIN
    INSERT INTO Roles (RoleName) VALUES ('Admin');
END

IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Customer')
BEGIN
    INSERT INTO Roles (RoleName) VALUES ('Customer');
END

IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Employee')
BEGIN
    INSERT INTO Roles (RoleName) VALUES ('Employee');
END

-- 2. Create the Customer Table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customers]') AND type in (N'U'))
BEGIN
    CREATE TABLE Customers (
        CustomerId INT IDENTITY(1,1) PRIMARY KEY,
        UserId INT, -- Links to Users table
        FirstName NVARCHAR(50),
        FullName NVARCHAR(150),
        Phone NVARCHAR(20),
        Address NVARCHAR(255),
        FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE SET NULL
    );
END

-- 3. Create the Employee Table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Employees]') AND type in (N'U'))
BEGIN
    CREATE TABLE Employees (
        EmployeeId INT IDENTITY(1,1) PRIMARY KEY,
        UserId INT, -- Links to Users table
        FirstName NVARCHAR(50),
        FullName NVARCHAR(150),
        Phone NVARCHAR(20),
        Address NVARCHAR(255),
        Designation NVARCHAR(100), -- Role within company
        FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE SET NULL
    );
END

-- 4. Create OrderHistory Table (Abstracted view of detailed orders for history tracking)
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OrderHistory]') AND type in (N'U'))
BEGIN
    CREATE TABLE OrderHistory (
        HistoryId INT IDENTITY(1,1) PRIMARY KEY,
        OrderId INT, -- Can link to actual Orders if required
        CustomerId INT,
        CustomerName NVARCHAR(150),
        PurchaseDate DATETIME DEFAULT GETDATE(),
        TotalQuantity INT,
        TotalPrice DECIMAL(18,2),
        Notes NVARCHAR(MAX),
        FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId) ON DELETE SET NULL
    );
END

-- 5. Seed Test Users (Admin and Customer)
DECLARE @AdminRoleId INT;
SELECT @AdminRoleId = RoleId FROM Roles WHERE RoleName = 'Admin';

-- Using plaintext for simplicity in this dev environment unless hashed strictly in C#.
-- Password: "admin"
IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'admin')
BEGIN
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName) 
    VALUES (@AdminRoleId, 'admin', 'admin@zoo.com', 'admin', 'System Administrator');
    
    DECLARE @AdminUserId INT = SCOPE_IDENTITY();
    
    INSERT INTO Employees (UserId, FirstName, FullName, Phone, Address, Designation)
    VALUES (@AdminUserId, 'Admin', 'System Administrator', '0123456789', 'Zoo HQ', 'Chief Administrator');
END


DECLARE @CustomerRoleId INT;
SELECT @CustomerRoleId = RoleId FROM Roles WHERE RoleName = 'Customer';

-- Password: "customer"
IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'customer')
BEGIN
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName) 
    VALUES (@CustomerRoleId, 'customer', 'john@gmail.com', 'customer', 'John Doe');
    
    DECLARE @CustUserId INT = SCOPE_IDENTITY();
    
    INSERT INTO Customers (UserId, FirstName, FullName, Phone, Address)
    VALUES (@CustUserId, 'John', 'John Doe', '0987654321', '123 Fake Street');
    
    -- Add a dummy order history
    DECLARE @NewCustId INT = SCOPE_IDENTITY();
    INSERT INTO OrderHistory (OrderId, CustomerId, CustomerName, TotalQuantity, TotalPrice, Notes)
    VALUES (1001, @NewCustId, 'John Doe', 3, 45.00, '3 General Admission Tickets');
END
GO
