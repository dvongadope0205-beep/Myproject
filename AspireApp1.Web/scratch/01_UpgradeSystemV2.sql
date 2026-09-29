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

PRINT 'Starting Database Upgrades...';

-- 1. Add ExperienceId column and Foreign Key to OrderItems if they don't exist
IF NOT EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.OrderItems') AND name = 'ExperienceId'
)
BEGIN
    PRINT 'Adding ExperienceId column to OrderItems table...';
    ALTER TABLE dbo.OrderItems ADD ExperienceId INT NULL;
    
    PRINT 'Creating FK_OrderItems_Experience foreign key constraint...';
    ALTER TABLE dbo.OrderItems ADD CONSTRAINT FK_OrderItems_Experience 
        FOREIGN KEY (ExperienceId) REFERENCES dbo.Experience(ExperienceId);
END
ELSE
BEGIN
    PRINT 'ExperienceId column already exists in OrderItems table.';
END
GO

-- 2. Populate ExperienceId for existing experience order items by matching name
PRINT 'Syncing ExperienceId for existing historical order items...';
UPDATE oi
SET oi.ExperienceId = e.ExperienceId
FROM dbo.OrderItems oi
INNER JOIN dbo.Experience e ON oi.ItemName = e.Name
WHERE oi.ExperienceId IS NULL;
GO

-- 3. Drop and Recreate Check Constraint for Event Status
PRINT 'Updating CK_Events_Status constraint...';
IF EXISTS (
    SELECT 1 
    FROM sys.check_constraints 
    WHERE name = 'CK_Events_Status' AND parent_object_id = OBJECT_ID('dbo.Events')
)
BEGIN
    ALTER TABLE dbo.Events DROP CONSTRAINT CK_Events_Status;
END
GO

ALTER TABLE dbo.Events ADD CONSTRAINT CK_Events_Status 
    CHECK (Status IN ('Active', 'Cancelled', 'Completed', 'Postponed', 'Expired', 'Archived'));
GO

-- 4. Recreate the Trigger for Member Experience Discount with ID joins and Group By optimizations
PRINT 'Recreating Trigger trg_OrderItems_MemberExperienceDiscount...';
IF OBJECT_ID('dbo.trg_OrderItems_MemberExperienceDiscount', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_OrderItems_MemberExperienceDiscount;
GO

CREATE TRIGGER dbo.trg_OrderItems_MemberExperienceDiscount
ON dbo.OrderItems
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Avoid infinite recursion in triggers
    IF TRIGGER_NESTLEVEL() > 3
        RETURN;

    -- Update the UnitPrice of Experience items if the customer is an active Member.
    -- Join using ExperienceId foreign key instead of string comparison.
    UPDATE oi
    SET oi.UnitPrice = e.Price * 0.8
    FROM dbo.OrderItems oi
    INNER JOIN inserted i ON oi.OrderItemId = i.OrderItemId
    INNER JOIN dbo.Orders o ON oi.OrderId = o.OrderId
    INNER JOIN dbo.Experience e ON oi.ExperienceId = e.ExperienceId
    WHERE o.UserId IS NOT NULL
      AND oi.UnitPrice <> e.Price * 0.8
      AND EXISTS (
          SELECT 1 
          FROM dbo.UserMemberships um
          WHERE um.UserId = o.UserId
            AND um.Status = 'Active'
            AND um.EndDate >= GETUTCDATE() -- Standardized to UTC date comparison
      );

    -- Recalculate TotalAmount for affected orders to prevent deadlocks.
    -- Group by OrderId from inserted virtual table.
    IF @@ROWCOUNT > 0 OR EXISTS (SELECT 1 FROM inserted)
    BEGIN
        UPDATE o
        SET o.TotalAmount = totals.NewTotal
        FROM dbo.Orders o
        INNER JOIN (
            SELECT oi.OrderId, SUM(oi.Quantity * oi.UnitPrice) AS NewTotal
            FROM dbo.OrderItems oi
            WHERE oi.OrderId IN (SELECT DISTINCT OrderId FROM inserted)
            GROUP BY oi.OrderId
        ) totals ON o.OrderId = totals.OrderId;
    END
END;
GO

PRINT 'Database Upgrades Completed Successfully.';
GO
