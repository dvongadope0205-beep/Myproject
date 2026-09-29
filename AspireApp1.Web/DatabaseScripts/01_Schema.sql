-- Database Schema for National Conservation Zoo
-- Run this script first to generate table structure and foreign keys.

-- CREATE DATABASE [ZooDatabase];
-- GO

USE [ZooDatabase] -- Replace with actual Database name if different
GO

-- 1. Authentication & Roles
CREATE TABLE Roles (
    RoleId INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    RoleId INT NOT NULL,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(256) NOT NULL,
    FullName NVARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (RoleId) REFERENCES Roles(RoleId)
);

-- 2. Memberships (Join page)
CREATE TABLE MembershipTypes (
    MembershipTypeId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    DurationMonths INT NOT NULL DEFAULT 12,
    Benefits NVARCHAR(MAX)
);

CREATE TABLE UserMemberships (
    UserMembershipId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    MembershipTypeId INT NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL,
    Status NVARCHAR(50) DEFAULT 'Active',
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (MembershipTypeId) REFERENCES MembershipTypes(MembershipTypeId)
);

-- 3. Zones & Animals (Attractions/Animals pages)
CREATE TABLE Zones (
    ZoneId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(MAX)
);

CREATE TABLE Animals (
    AnimalId INT IDENTITY(1,1) PRIMARY KEY,
    ZoneId INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Species NVARCHAR(100) NOT NULL,
    ConservationStatus NVARCHAR(100),
    Description NVARCHAR(MAX),
    ImagePath NVARCHAR(255),
    FOREIGN KEY (ZoneId) REFERENCES Zones(ZoneId)
);

CREATE TABLE Attractions (
    AttractionId INT IDENTITY(1,1) PRIMARY KEY,
    ZoneId INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Category NVARCHAR(50), -- e.g., 'Dining', 'Ride'
    Description NVARCHAR(MAX),
    FOREIGN KEY (ZoneId) REFERENCES Zones(ZoneId)
);

-- 4. Events & Bookings
CREATE TABLE Events (
    EventId INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX),
    EventDate DATETIME NOT NULL,
    Capacity INT,
    BasePrice DECIMAL(18,2)
);

CREATE TABLE EventBookings (
    BookingId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    EventId INT NOT NULL,
    BookingDate DATETIME DEFAULT GETDATE(),
    Participants INT NOT NULL,
    TotalPrice DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (EventId) REFERENCES Events(EventId)
);

-- 5. Ticketing & Orders (Tickets page)
CREATE TABLE TicketTypes (
    TicketTypeId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    BasePrice DECIMAL(18,2) NOT NULL
);

CREATE TABLE Orders (
    OrderId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT, -- Nullable for Guest purchases
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(18,2) NOT NULL,
    PaymentStatus NVARCHAR(50) DEFAULT 'Pending',
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

CREATE TABLE OrderItems (
    OrderItemId INT IDENTITY(1,1) PRIMARY KEY,
    OrderId INT NOT NULL,
    TicketTypeId INT NOT NULL,
    VisitDate DATE NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
    FOREIGN KEY (TicketTypeId) REFERENCES TicketTypes(TicketTypeId)
);
GO
