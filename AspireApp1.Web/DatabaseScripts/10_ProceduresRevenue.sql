-- ============================================================
-- 10_ProceduresRevenue.sql
-- Stored Procedures: Doanh thu theo ngày và theo tháng
-- Chạy sau 09_Triggers.sql
-- ============================================================

USE [ZooDatabase]
GO

-- ============================================================
-- PROCEDURE 1: sp_RevenueByDay
-- Báo cáo doanh thu theo ngày cụ thể
-- Trả về: Chi tiết từng loại vé + tổng doanh thu
-- ============================================================
CREATE OR ALTER PROC sp_RevenueByDay
    @TargetDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    PRINT N'══════════════════════════════════════';
    PRINT N'📊 BÁO CÁO DOANH THU NGÀY: ' + CONVERT(NVARCHAR(10), @TargetDate, 120);
    PRINT N'══════════════════════════════════════';

    -- Chi tiết doanh thu theo từng loại vé
    SELECT 
        tt.Name AS N'Loại vé',
        tt.AgeRange AS N'Độ tuổi',
        COUNT(p.ProceedId) AS N'Số giao dịch',
        SUM(p.Quantity) AS N'Tổng số vé bán',
        MIN(p.UnitPrice) AS N'Đơn giá',
        SUM(p.TotalAmount) AS N'Doanh thu'
    FROM Proceeds p
    INNER JOIN TicketTypes tt ON p.TicketTypeId = tt.TicketTypeId
    WHERE CAST(p.PurchaseDate AS DATE) = @TargetDate
    GROUP BY tt.Name, tt.AgeRange
    ORDER BY SUM(p.TotalAmount) DESC;

    -- Doanh thu theo sự kiện (nếu có)
    SELECT 
        e.Title AS N'Sự kiện',
        COUNT(p.ProceedId) AS N'Số giao dịch',
        SUM(p.Quantity) AS N'Tổng vé bán',
        SUM(p.TotalAmount) AS N'Doanh thu sự kiện'
    FROM Proceeds p
    INNER JOIN Events e ON p.EventId = e.EventId
    WHERE CAST(p.PurchaseDate AS DATE) = @TargetDate
    GROUP BY e.Title
    ORDER BY SUM(p.TotalAmount) DESC;

    -- Doanh thu theo phương thức thanh toán
    SELECT
        p.PaymentMethod AS N'Phương thức',
        COUNT(p.ProceedId) AS N'Số giao dịch',
        SUM(p.TotalAmount) AS N'Doanh thu'
    FROM Proceeds p
    WHERE CAST(p.PurchaseDate AS DATE) = @TargetDate
    GROUP BY p.PaymentMethod;

    -- Tổng cộng doanh thu ngày
    SELECT 
        @TargetDate AS N'Ngày',
        COUNT(p.ProceedId) AS N'Tổng giao dịch',
        SUM(p.Quantity) AS N'Tổng vé bán',
        SUM(p.TotalAmount) AS N'TỔNG DOANH THU',
        AVG(p.TotalAmount) AS N'Trung bình / giao dịch'
    FROM Proceeds p
    WHERE CAST(p.PurchaseDate AS DATE) = @TargetDate;
END
GO
PRINT N'✅ Đã tạo Procedure: sp_RevenueByDay';
GO

-- ============================================================
-- PROCEDURE 2: sp_RevenueByMonth
-- Báo cáo doanh thu theo tháng
-- Trả về: Chi tiết từng loại vé + tổng doanh thu + so sánh
-- ============================================================
CREATE OR ALTER PROC sp_RevenueByMonth
    @Year INT,
    @Month INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MonthName NVARCHAR(20);
    SET @MonthName = DATENAME(MONTH, DATEFROMPARTS(@Year, @Month, 1));

    PRINT N'══════════════════════════════════════';
    PRINT N'📊 BÁO CÁO DOANH THU THÁNG ' + CAST(@Month AS NVARCHAR(2)) + N'/' + CAST(@Year AS NVARCHAR(4));
    PRINT N'══════════════════════════════════════';

    -- Chi tiết doanh thu theo từng loại vé trong tháng
    SELECT 
        tt.Name AS N'Loại vé',
        tt.AgeRange AS N'Độ tuổi',
        COUNT(p.ProceedId) AS N'Số giao dịch',
        SUM(p.Quantity) AS N'Tổng số vé bán',
        SUM(p.TotalAmount) AS N'Doanh thu'
    FROM Proceeds p
    INNER JOIN TicketTypes tt ON p.TicketTypeId = tt.TicketTypeId
    WHERE YEAR(p.PurchaseDate) = @Year AND MONTH(p.PurchaseDate) = @Month
    GROUP BY tt.Name, tt.AgeRange
    ORDER BY SUM(p.TotalAmount) DESC;

    -- Doanh thu theo sự kiện trong tháng
    SELECT 
        e.Title AS N'Sự kiện',
        CONVERT(NVARCHAR(10), e.EventDate, 120) AS N'Ngày sự kiện',
        COUNT(p.ProceedId) AS N'Số giao dịch',
        SUM(p.Quantity) AS N'Tổng vé bán',
        SUM(p.TotalAmount) AS N'Doanh thu sự kiện'
    FROM Proceeds p
    INNER JOIN Events e ON p.EventId = e.EventId
    WHERE YEAR(p.PurchaseDate) = @Year AND MONTH(p.PurchaseDate) = @Month
    GROUP BY e.Title, e.EventDate
    ORDER BY SUM(p.TotalAmount) DESC;

    -- Doanh thu theo từng ngày trong tháng (trend)
    SELECT 
        CAST(p.PurchaseDate AS DATE) AS N'Ngày',
        COUNT(p.ProceedId) AS N'Số giao dịch',
        SUM(p.Quantity) AS N'Tổng vé bán',
        SUM(p.TotalAmount) AS N'Doanh thu ngày'
    FROM Proceeds p
    WHERE YEAR(p.PurchaseDate) = @Year AND MONTH(p.PurchaseDate) = @Month
    GROUP BY CAST(p.PurchaseDate AS DATE)
    ORDER BY CAST(p.PurchaseDate AS DATE);

    -- Doanh thu theo phương thức thanh toán
    SELECT
        p.PaymentMethod AS N'Phương thức',
        COUNT(p.ProceedId) AS N'Số giao dịch',
        SUM(p.TotalAmount) AS N'Doanh thu'
    FROM Proceeds p
    WHERE YEAR(p.PurchaseDate) = @Year AND MONTH(p.PurchaseDate) = @Month
    GROUP BY p.PaymentMethod;

    -- Tổng cộng doanh thu tháng
    SELECT 
        CAST(@Month AS NVARCHAR(2)) + N'/' + CAST(@Year AS NVARCHAR(4)) AS N'Tháng',
        COUNT(p.ProceedId) AS N'Tổng giao dịch',
        SUM(p.Quantity) AS N'Tổng vé bán',
        SUM(p.TotalAmount) AS N'TỔNG DOANH THU',
        AVG(p.TotalAmount) AS N'Trung bình / giao dịch',
        MAX(p.TotalAmount) AS N'Giao dịch lớn nhất',
        MIN(p.TotalAmount) AS N'Giao dịch nhỏ nhất'
    FROM Proceeds p
    WHERE YEAR(p.PurchaseDate) = @Year AND MONTH(p.PurchaseDate) = @Month;

    -- So sánh với tháng trước (nếu có dữ liệu)
    DECLARE @PrevMonth INT = @Month - 1;
    DECLARE @PrevYear INT = @Year;
    IF @PrevMonth = 0 BEGIN SET @PrevMonth = 12; SET @PrevYear = @Year - 1; END

    DECLARE @CurrentRevenue DECIMAL(18,2), @PrevRevenue DECIMAL(18,2);

    SELECT @CurrentRevenue = ISNULL(SUM(TotalAmount), 0)
    FROM Proceeds
    WHERE YEAR(PurchaseDate) = @Year AND MONTH(PurchaseDate) = @Month;

    SELECT @PrevRevenue = ISNULL(SUM(TotalAmount), 0)
    FROM Proceeds
    WHERE YEAR(PurchaseDate) = @PrevYear AND MONTH(PurchaseDate) = @PrevMonth;

    SELECT
        @CurrentRevenue AS N'Doanh thu tháng này',
        @PrevRevenue AS N'Doanh thu tháng trước',
        @CurrentRevenue - @PrevRevenue AS N'Chênh lệch',
        CASE 
            WHEN @PrevRevenue > 0 
            THEN CAST(ROUND((@CurrentRevenue - @PrevRevenue) / @PrevRevenue * 100, 2) AS NVARCHAR(10)) + '%'
            ELSE N'N/A (Không có dữ liệu tháng trước)'
        END AS N'Tăng trưởng';
END
GO
PRINT N'✅ Đã tạo Procedure: sp_RevenueByMonth';
GO

-- ============================================================
-- PROCEDURE 3: sp_InsertProceed
-- Thêm giao dịch Proceeds mới (tiện ích)
-- ============================================================
CREATE OR ALTER PROC sp_InsertProceed
    @EventId INT = NULL,
    @CustomerId INT = NULL,
    @TicketTypeName NVARCHAR(100),
    @CustomerName NVARCHAR(150),
    @Quantity INT,
    @PaymentMethod NVARCHAR(50) = 'Online',
    @Notes NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TicketTypeId INT, @UnitPrice DECIMAL(18,2);
    
    SELECT @TicketTypeId = TicketTypeId, @UnitPrice = BasePrice
    FROM TicketTypes 
    WHERE Name = @TicketTypeName AND (IsActive = 1 OR IsActive IS NULL);

    IF @TicketTypeId IS NULL
    BEGIN
        RAISERROR(N'❌ Loại vé "%s" không tồn tại hoặc đã ngừng bán', 16, 1, @TicketTypeName);
        RETURN;
    END

    -- Kiểm tra sức chứa sự kiện nếu có EventId
    IF @EventId IS NOT NULL
    BEGIN
        DECLARE @RemainingCapacity INT;
        SELECT @RemainingCapacity = Capacity FROM Events WHERE EventId = @EventId;
        
        IF @RemainingCapacity IS NOT NULL AND @Quantity > @RemainingCapacity
        BEGIN
            RAISERROR(N'❌ Sự kiện chỉ còn %d chỗ, không đủ cho %d vé', 16, 1, @RemainingCapacity, @Quantity);
            RETURN;
        END
    END

    -- Tạo mã giao dịch tự động
    DECLARE @TransactionRef NVARCHAR(100);
    SET @TransactionRef = 'TXN-' + FORMAT(GETDATE(), 'yyyyMMdd-HHmmss') + '-' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS NVARCHAR(5));

    INSERT INTO Proceeds (EventId, CustomerId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (@EventId, @CustomerId, @TicketTypeId, @CustomerName, @Quantity, @UnitPrice, @PaymentMethod, 'Completed', @TransactionRef, @Notes);

    -- TotalAmount sẽ được trigger trg_Proceeds_CalcTotal tự tính
    PRINT N'✅ Đã tạo giao dịch - Mã: ' + @TransactionRef;
END
GO
PRINT N'✅ Đã tạo Procedure: sp_InsertProceed';
GO

PRINT N'========================================';
PRINT N'✅ 10_ProceduresRevenue.sql HOÀN TẤT';
PRINT N'========================================';
GO
