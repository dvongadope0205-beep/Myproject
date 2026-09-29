-- ============================================================
-- 12_SampleProceedsData.sql
-- Dữ liệu mẫu cho bảng Proceeds + Test triggers & procedures
-- Chạy sau 11_ViewsComplete.sql
-- ============================================================

USE [ZooDatabase]
GO

-- ============================================================
-- PHẦN 1: Thêm dữ liệu mẫu Proceeds
-- ============================================================

-- Lấy ID của customer test
DECLARE @TestCustomerId INT;
SELECT @TestCustomerId = CustomerId FROM Customers WHERE FullName = 'John Doe';

-- Lấy TicketType IDs
DECLARE @AdultId INT, @ChildId INT, @SeniorId INT;
SELECT @AdultId = TicketTypeId FROM TicketTypes WHERE Name = 'Adult';
SELECT @ChildId = TicketTypeId FROM TicketTypes WHERE Name = 'Child';
SELECT @SeniorId = TicketTypeId FROM TicketTypes WHERE Name = 'Senior';

-- Lấy Event IDs
DECLARE @SafariEventId INT, @ZooLightsId INT, @GalaId INT, @BrewId INT;
SELECT @SafariEventId = EventId FROM Events WHERE Title LIKE '%Safari%';
SELECT @ZooLightsId = EventId FROM Events WHERE Title LIKE '%ZooLights%';
SELECT @GalaId = EventId FROM Events WHERE Title LIKE '%Gala%';
SELECT @BrewId = EventId FROM Events WHERE Title LIKE '%Brew%';

-- ── Dữ liệu mẫu: Vé vào cổng thường (không có sự kiện) ──

-- Ngày hôm nay
INSERT INTO Proceeds (EventId, CustomerId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, Notes)
VALUES 
    (NULL, @TestCustomerId, @AdultId, N'John Doe', 2, 25.00, 'Online', 'Completed', N'Gia đình đi chơi cuối tuần'),
    (NULL, @TestCustomerId, @ChildId, N'John Doe', 2, 15.00, 'Online', 'Completed', N'Vé cho con'),
    (NULL, NULL, @AdultId, N'Nguyễn Văn An', 1, 25.00, 'Cash', 'Completed', N'Khách vãng lai'),
    (NULL, NULL, @SeniorId, N'Trần Thị Bình', 2, 20.00, 'Card', 'Completed', N'Khách cao tuổi'),
    (NULL, NULL, @AdultId, N'Lê Minh Châu', 3, 25.00, 'Online', 'Completed', N'Nhóm bạn');

-- Ngày hôm qua (giả lập)
INSERT INTO Proceeds (EventId, CustomerId, TicketTypeId, CustomerName, Quantity, UnitPrice, PurchaseDate, PaymentMethod, PaymentStatus, Notes)
VALUES
    (NULL, NULL, @AdultId, N'Phạm Đức Duy', 2, 25.00, DATEADD(DAY, -1, GETDATE()), 'Online', 'Completed', NULL),
    (NULL, NULL, @ChildId, N'Hoàng Thị Em', 3, 15.00, DATEADD(DAY, -1, GETDATE()), 'Cash', 'Completed', NULL),
    (NULL, NULL, @SeniorId, N'Vũ Văn Phúc', 1, 20.00, DATEADD(DAY, -1, GETDATE()), 'Card', 'Completed', NULL);

-- Tuần trước
INSERT INTO Proceeds (EventId, CustomerId, TicketTypeId, CustomerName, Quantity, UnitPrice, PurchaseDate, PaymentMethod, PaymentStatus, Notes)
VALUES
    (NULL, NULL, @AdultId, N'Đặng Thu Giang', 4, 25.00, DATEADD(DAY, -7, GETDATE()), 'Online', 'Completed', N'Đoàn khách'),
    (NULL, NULL, @ChildId, N'Bùi Hải Hà', 2, 15.00, DATEADD(DAY, -7, GETDATE()), 'Transfer', 'Completed', NULL);

-- Tháng trước (để test so sánh tháng)
INSERT INTO Proceeds (EventId, CustomerId, TicketTypeId, CustomerName, Quantity, UnitPrice, PurchaseDate, PaymentMethod, PaymentStatus, Notes)
VALUES
    (NULL, NULL, @AdultId, N'Cao Văn Ích', 5, 25.00, DATEADD(MONTH, -1, GETDATE()), 'Online', 'Completed', N'Nhóm lớn'),
    (NULL, NULL, @ChildId, N'Đinh Thị Kim', 3, 15.00, DATEADD(MONTH, -1, GETDATE()), 'Cash', 'Completed', NULL),
    (NULL, NULL, @SeniorId, N'Lý Minh Long', 2, 20.00, DATEADD(MONTH, -1, GETDATE()), 'Card', 'Completed', NULL);

-- ── Dữ liệu mẫu: Vé sự kiện ──

-- Vé sự kiện Safari
IF @SafariEventId IS NOT NULL
BEGIN
    INSERT INTO Proceeds (EventId, CustomerId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, Notes)
    VALUES 
        (@SafariEventId, @TestCustomerId, @AdultId, N'John Doe', 2, 35.00, 'Online', 'Completed', N'Safari 家庭'),
        (@SafariEventId, NULL, @ChildId, N'Ngô Thanh Mai', 2, 35.00, 'Online', 'Completed', N'Vé Safari cho trẻ em');
END

-- Vé sự kiện Brew at the Zoo
IF @BrewId IS NOT NULL
BEGIN
    INSERT INTO Proceeds (EventId, CustomerId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, Notes)
    VALUES 
        (@BrewId, NULL, @AdultId, N'Phan Quốc Nam', 2, 45.00, 'Card', 'Completed', N'Brew at the Zoo'),
        (@BrewId, NULL, @AdultId, N'Trịnh Văn Oanh', 1, 45.00, 'Online', 'Completed', NULL);
END

-- Vé giao dịch Pending (chưa thanh toán)
INSERT INTO Proceeds (EventId, CustomerId, TicketTypeId, CustomerName, Quantity, UnitPrice, PaymentMethod, PaymentStatus, Notes)
VALUES 
    (NULL, NULL, @AdultId, N'Ung Thị Phương', 2, 25.00, 'Online', 'Pending', N'Chờ thanh toán');

PRINT N'✅ Đã thêm dữ liệu mẫu cho Proceeds';
GO

-- ============================================================
-- PHẦN 2: TEST TRIGGERS
-- ============================================================

PRINT N'';
PRINT N'══════════════════════════════════════';
PRINT N'🧪 KIỂM TRA TRIGGERS';
PRINT N'══════════════════════════════════════';

-- Test 1: Kiểm tra trigger CalcTotal đã tính TotalAmount chưa
PRINT N'';
PRINT N'─── Test 1: TotalAmount đã được tự động tính? ───';
SELECT TOP 5 
    ProceedId, CustomerName, Quantity, UnitPrice, TotalAmount,
    CASE WHEN TotalAmount = Quantity * UnitPrice THEN N'✅ ĐÚNG' ELSE N'❌ SAI' END AS KiemTra
FROM Proceeds
ORDER BY ProceedId DESC;
GO

-- Test 2: Kiểm tra PaymentLog đã được tự động ghi chưa
PRINT N'';
PRINT N'─── Test 2: PaymentLog tự động ghi? ───';
SELECT TOP 5
    pl.PaymentLogId, pl.ProceedId, pl.Amount, pl.Status, pl.PaymentDate
FROM PaymentLog pl
ORDER BY pl.PaymentLogId DESC;
GO

-- Test 3: Kiểm tra AuditLog
PRINT N'';
PRINT N'─── Test 3: AuditLog có ghi nhận? ───';
SELECT TOP 5
    AuditId, TableName, RecordId, Action, ChangedBy, ChangedAt
FROM AuditLog
ORDER BY AuditId DESC;
GO

-- ============================================================
-- PHẦN 3: TEST PROCEDURES
-- ============================================================

PRINT N'';
PRINT N'══════════════════════════════════════';
PRINT N'🧪 KIỂM TRA STORED PROCEDURES';
PRINT N'══════════════════════════════════════';

-- Test sp_RevenueByDay
PRINT N'';
PRINT N'─── Test: sp_RevenueByDay (hôm nay) ───';
EXEC sp_RevenueByDay @TargetDate = NULL; -- Sẽ dùng GETDATE() format
GO

-- Gọi lại đúng cách
DECLARE @Today DATE = CAST(GETDATE() AS DATE);
EXEC sp_RevenueByDay @TargetDate = @Today;
GO

-- Test sp_RevenueByMonth  
PRINT N'';
PRINT N'─── Test: sp_RevenueByMonth (tháng hiện tại) ───';
EXEC sp_RevenueByMonth @Year = 2026, @Month = 4;
GO

-- ============================================================
-- PHẦN 4: KIỂM TRA VIEWS
-- ============================================================

PRINT N'';
PRINT N'══════════════════════════════════════';
PRINT N'🧪 KIỂM TRA VIEWS';
PRINT N'══════════════════════════════════════';

PRINT N'─── vw_ProceedsFull ───';
SELECT TOP 5 * FROM vw_ProceedsFull;

PRINT N'─── vw_CustomerInfo ───';
SELECT * FROM vw_CustomerInfo;

PRINT N'─── vw_DailyRevenueSummary ───';
SELECT * FROM vw_DailyRevenueSummary;

PRINT N'─── vw_MonthlyRevenueSummary ───';
SELECT * FROM vw_MonthlyRevenueSummary;

PRINT N'─── vw_OrderHistory (VIEW thay thế bảng cũ) ───';
SELECT * FROM vw_OrderHistory;
GO

PRINT N'========================================';
PRINT N'✅ 12_SampleProceedsData.sql HOÀN TẤT';
PRINT N'========================================';
GO
