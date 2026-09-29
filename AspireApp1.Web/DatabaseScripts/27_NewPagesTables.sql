-- Database Migration Script
-- Creates 3 new tables: PlayArea, Dining, Experience
-- Connects them to the existing [Zones] table via ZoneId foreign keys.
-- Run this script in SQL Server Management Studio (SSMS) or via your EF Core / SQL execution environment.

USE [ZooDatabase]
GO

-- 1. DROP TABLES IF THEY ALREADY EXIST (Ensures safe re-run)
IF OBJECT_ID('dbo.Experience', 'U') IS NOT NULL
    DROP TABLE dbo.Experience;
GO

IF OBJECT_ID('dbo.Dining', 'U') IS NOT NULL
    DROP TABLE dbo.Dining;
GO

IF OBJECT_ID('dbo.PlayArea', 'U') IS NOT NULL
    DROP TABLE dbo.PlayArea;
GO


-- 2. CREATE TABLE [PlayArea]
CREATE TABLE dbo.PlayArea (
    PlayAreaId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(MAX) NULL,
    Location NVARCHAR(200) NOT NULL,
    ImagePath NVARCHAR(255) NULL,
    MinAge INT DEFAULT 0 CONSTRAINT CK_PlayArea_MinAge CHECK (MinAge >= 0),
    Capacity INT NULL CONSTRAINT CK_PlayArea_Capacity CHECK (Capacity >= 0),
    IsAccessible BIT DEFAULT 1,
    ZoneId INT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    
    -- Foreign Key to Zones table
    CONSTRAINT FK_PlayArea_Zones FOREIGN KEY (ZoneId) REFERENCES dbo.Zones(ZoneId)
        ON DELETE SET NULL
);
GO


-- 3. CREATE TABLE [Dining]
CREATE TABLE dbo.Dining (
    DiningId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Tagline NVARCHAR(200) NULL,
    Description NVARCHAR(MAX) NULL,
    Location NVARCHAR(200) NOT NULL,
    OpeningHours NVARCHAR(100) NULL,
    ImagePath NVARCHAR(255) NULL,
    MenuLink NVARCHAR(255) NULL,
    ZoneId INT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    
    -- Foreign Key to Zones table
    CONSTRAINT FK_Dining_Zones FOREIGN KEY (ZoneId) REFERENCES dbo.Zones(ZoneId)
        ON DELETE SET NULL
);
GO


-- 4. CREATE TABLE [Experience]
CREATE TABLE dbo.Experience (
    ExperienceId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(MAX) NULL,
    DurationMinutes INT NULL CONSTRAINT CK_Experience_Duration CHECK (DurationMinutes >= 0),
    Price DECIMAL(18,2) NOT NULL DEFAULT 0.00 CONSTRAINT CK_Experience_Price CHECK (Price >= 0.00),
    MinAge INT DEFAULT 0 CONSTRAINT CK_Experience_MinAge CHECK (MinAge >= 0),
    Capacity INT NULL CONSTRAINT CK_Experience_Capacity CHECK (Capacity >= 0),
    Location NVARCHAR(200) NOT NULL,
    ImagePath NVARCHAR(255) NULL,
    ZoneId INT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    
    -- Foreign Key to Zones table
    CONSTRAINT FK_Experience_Zones FOREIGN KEY (ZoneId) REFERENCES dbo.Zones(ZoneId)
        ON DELETE SET NULL
);
GO


-- 5. INSERT SEED DATA FOR NEW TABLES (Example reference entries matching UI elements)
-- PlayArea Seed Data
INSERT INTO dbo.PlayArea (Name, Description, Location, ImagePath, MinAge, Capacity, IsAccessible, ZoneId)
VALUES 
('Madagascar Play!', 'Climb like a lemur and uncover our tree-top hideaways in the Lost Forest.', 'Lost Forest Reserve', '/Source/play-area/play area/madagasca play!/carousel/madagasca-carousel-1.jpeg', 3, 50, 1, 1),
('Nature Play!', 'Connect directly with nature in our curated mud kitchen and sensory climbing structures.', 'East Gate Meadow', '/Source/play-area/play area/nature play!/nature-play.jpg', 2, 40, 1, 1),
('Treetop Challenge', 'Tackle high obstacles and cargo nets among the pine trees.', 'Wilds Canopy Area', '/Source/play-area/play area/treetop challenge/carousel/treetop-carousel-1.jpeg', 8, 30, 0, 1);

-- Dining Seed Data
INSERT INTO dbo.Dining (Name, Tagline, Location, OpeningHours, ImagePath, MenuLink, ZoneId)
VALUES 
('The Gannet', 'Curated British classics & premium artisan ingredients', 'Main Courtyard Hub', '11:30 AM - 5:00 PM', '/Source/dining/chicken.jpg', '/Source/menu/dining/gannet-menu.pdf', NULL),
('Grasslands', 'Gourmet family burgers & vibrant seasonal healthy salads', 'East Reserve near Elephant Trek', '10:00 AM - 4:30 PM', '/Source/dining/grasslands.jpg', '/Source/menu/dining/grasslands-menu.pdf', NULL),
('Jaguar Coffee House', 'Enjoy specialty coffees & sandwiches right next to the jaguar habitat', 'Next to Spirit of the Jaguar', '8:15 AM - 9:45 AM', '/Source/dining/restaurant.jpg', '/Source/menu/dining/gannet-menu.pdf', NULL);

-- Experience Seed Data
INSERT INTO dbo.Experience (Name, Description, DurationMinutes, Price, MinAge, Capacity, Location, ImagePath, ZoneId)
VALUES 
('Orangutan Experience', 'Join expert keepers for an unforgettable adventure high above Monsoon Forest.', 30, 195.00, 16, 2, 'Monsoon Forest', '/Source/experience/orangutan-experience.jpg', 1),
('Meerkat Experience', 'Get up close and personal with our adorable meerkat mob.', 20, 70.00, 8, 4, 'African Savannah', '/Source/experience/meerkat-experience.jpg', 1);
GO
