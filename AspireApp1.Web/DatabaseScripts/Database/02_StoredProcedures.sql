-- ============================================================
-- 02_StoredProcedures.sql
-- ZooDatabase V2 — Tất cả Stored Procedures
-- Chạy sau 01_CreateTables.sql
-- ============================================================

USE [ZooDatabase]
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  NHÓM A: XÁC THỰC (Auth)                                  ║
-- ╚══════════════════════════════════════════════════════════════╝

-- A1. Đăng ký User mới
CREATE OR ALTER PROC sp_RegisterUser
    @Username       NVARCHAR(50),
    @Email          NVARCHAR(100),
    @PasswordHash   NVARCHAR(256),
    @FullName       NVARCHAR(100),
    @UserId         INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra email đã tồn tại
    IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email)
    BEGIN
        RAISERROR(N'Email đã được đăng ký.', 16, 1);
        RETURN;
    END

    -- Kiểm tra username đã tồn tại
    IF EXISTS (SELECT 1 FROM Users WHERE Username = @Username)
    BEGIN
        RAISERROR(N'Username đã tồn tại.', 16, 1);
        RETURN;
    END

    DECLARE @RoleId INT;
    SELECT @RoleId = RoleId FROM Roles WHERE RoleName = 'User';

    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, IsActive)
    VALUES (@RoleId, @Username, @Email, @PasswordHash, @FullName, 1);

    SET @UserId = SCOPE_IDENTITY();
    PRINT N'✅ Đăng ký thành công: ' + @Username;
END
GO

-- A2. Yêu cầu Reset Password
CREATE OR ALTER PROC sp_RequestPasswordReset
    @Email          NVARCHAR(100),
    @ResetToken     NVARCHAR(100),
    @ExpiryMinutes  INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = @Email AND IsActive = 1)
    BEGIN
        RAISERROR(N'Email không tồn tại trong hệ thống.', 16, 1);
        RETURN;
    END

    UPDATE Users
    SET ResetToken = @ResetToken,
        ResetTokenExpiry = DATEADD(MINUTE, @ExpiryMinutes, GETDATE())
    WHERE Email = @Email;

    PRINT N'✅ Reset token đã được tạo cho: ' + @Email;
END
GO

-- A3. Đổi mật khẩu bằng Token
CREATE OR ALTER PROC sp_ResetPassword
    @ResetToken     NVARCHAR(100),
    @NewPasswordHash NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Users WHERE ResetToken = @ResetToken AND ResetTokenExpiry > GETDATE())
    BEGIN
        RAISERROR(N'Token không hợp lệ hoặc đã hết hạn.', 16, 1);
        RETURN;
    END

    UPDATE Users
    SET PasswordHash = @NewPasswordHash,
        ResetToken = NULL,
        ResetTokenExpiry = NULL
    WHERE ResetToken = @ResetToken AND ResetTokenExpiry > GETDATE();

    PRINT N'✅ Mật khẩu đã được đổi thành công.';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  NHÓM B: PROFILE NGƯỜI DÙNG                               ║
-- ╚══════════════════════════════════════════════════════════════╝

-- B1. Cập nhật Avatar
CREATE OR ALTER PROC sp_UpdateUserAvatar
    @UserId     INT,
    @AvatarPath NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- Lưu avatar cũ vào lịch sử (nếu có)
    DECLARE @OldAvatar NVARCHAR(255);
    SELECT @OldAvatar = AvatarPath FROM Users WHERE UserId = @UserId;

    IF @OldAvatar IS NOT NULL
    BEGIN
        INSERT INTO UserAvatarHistory (UserId, AvatarPath)
        VALUES (@UserId, @OldAvatar);
    END

    -- Cập nhật avatar mới
    UPDATE Users SET AvatarPath = @AvatarPath WHERE UserId = @UserId;

    PRINT N'✅ Avatar đã được cập nhật.';
END
GO

-- B2. Cập nhật Profile
CREATE OR ALTER PROC sp_UpdateUserProfile
    @UserId     INT,
    @FullName   NVARCHAR(100) = NULL,
    @Phone      NVARCHAR(20) = NULL,
    @Address    NVARCHAR(255) = NULL,
    @Gender     NVARCHAR(10) = NULL,
    @DateOfBirth DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Users
    SET FullName     = ISNULL(@FullName, FullName),
        Phone        = ISNULL(@Phone, Phone),
        Address      = ISNULL(@Address, Address),
        Gender       = ISNULL(@Gender, Gender),
        DateOfBirth  = ISNULL(@DateOfBirth, DateOfBirth)
    WHERE UserId = @UserId;

    PRINT N'✅ Profile đã được cập nhật.';
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  NHÓM C: ĐƠN HÀNG & THANH TOÁN                           ║
-- ╚══════════════════════════════════════════════════════════════╝

-- C1. Tạo đơn hàng mới
CREATE OR ALTER PROC sp_CreateOrder
    @UserId         INT = NULL,
    @OrderType      NVARCHAR(20),
    @PaymentMethod  NVARCHAR(50) = 'QR Code',
    @Notes          NVARCHAR(MAX) = NULL,
    @OrderId        INT OUTPUT,
    @TransactionRef NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Tạo mã giao dịch
    SET @TransactionRef = 'TXN-' + FORMAT(GETDATE(), 'yyyyMMdd') + '-' + 
        UPPER(LEFT(REPLACE(CAST(NEWID() AS NVARCHAR(36)), '-', ''), 8));

    INSERT INTO Orders (UserId, OrderType, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (@UserId, @OrderType, @PaymentMethod, 'Pending', @TransactionRef, @Notes);

    SET @OrderId = SCOPE_IDENTITY();
    PRINT N'✅ Đơn hàng #' + CAST(@OrderId AS NVARCHAR(10)) + N' đã tạo.';
END
GO

-- C2. Thêm chi tiết đơn hàng
CREATE OR ALTER PROC sp_AddOrderItem
    @OrderId        INT,
    @ItemType       NVARCHAR(20),
    @ItemName       NVARCHAR(200),
    @TicketTypeId   INT = NULL,
    @EventId        INT = NULL,
    @MembershipTypeId INT = NULL,
    @ProductId      INT = NULL,
    @VisitDate      DATE = NULL,
    @Quantity       INT = 1,
    @UnitPrice      DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO OrderItems (OrderId, ItemType, ItemName, TicketTypeId, EventId, MembershipTypeId, ProductId, VisitDate, Quantity, UnitPrice)
    VALUES (@OrderId, @ItemType, @ItemName, @TicketTypeId, @EventId, @MembershipTypeId, @ProductId, @VisitDate, @Quantity, @UnitPrice);

    -- Cập nhật TotalAmount
    UPDATE Orders
    SET TotalAmount = (SELECT SUM(Quantity * UnitPrice) FROM OrderItems WHERE OrderId = @OrderId)
    WHERE OrderId = @OrderId;

    PRINT N'✅ Đã thêm item vào đơn hàng #' + CAST(@OrderId AS NVARCHAR(10));
END
GO

-- C3. Xác nhận thanh toán
CREATE OR ALTER PROC sp_ConfirmPayment
    @TransactionRef NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OrderId INT, @Amount DECIMAL(18,2), @Method NVARCHAR(50);

    SELECT @OrderId = OrderId, @Amount = TotalAmount, @Method = PaymentMethod
    FROM Orders WHERE TransactionRef = @TransactionRef AND PaymentStatus = 'Pending';

    IF @OrderId IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy đơn hàng Pending cho mã giao dịch này.', 16, 1);
        RETURN;
    END

    -- Cập nhật trạng thái
    UPDATE Orders SET PaymentStatus = 'Completed' WHERE OrderId = @OrderId;

    -- Ghi PaymentLog
    INSERT INTO PaymentLog (OrderId, Amount, PaymentMethod, TransactionRef, Status, Notes)
    VALUES (@OrderId, @Amount, @Method, @TransactionRef, 'Success', N'QR Payment confirmed');

    -- Nếu là Membership → tạo UserMemberships
    DECLARE @OrderType NVARCHAR(20), @UserId INT;
    SELECT @OrderType = OrderType, @UserId = UserId FROM Orders WHERE OrderId = @OrderId;

    IF @OrderType = 'Membership' AND @UserId IS NOT NULL
    BEGIN
        INSERT INTO UserMemberships (UserId, MembershipTypeId, OrderId, StartDate, EndDate, Status)
        SELECT @UserId, oi.MembershipTypeId, @OrderId, GETDATE(), 
               DATEADD(MONTH, mt.DurationMonths, GETDATE()), 'Active'
        FROM OrderItems oi
        INNER JOIN MembershipTypes mt ON oi.MembershipTypeId = mt.MembershipTypeId
        WHERE oi.OrderId = @OrderId AND oi.ItemType = 'Membership';
    END

    -- Nếu là Shop → giảm stock
    IF @OrderType = 'Shop'
    BEGIN
        UPDATE sp
        SET sp.StockQuantity = sp.StockQuantity - oi.Quantity
        FROM ShopProducts sp
        INNER JOIN OrderItems oi ON sp.ProductId = oi.ProductId
        WHERE oi.OrderId = @OrderId AND oi.ItemType = 'Shop';
    END

    PRINT N'✅ Thanh toán đã xác nhận: ' + @TransactionRef;
END
GO

-- C4. Mua Membership
CREATE OR ALTER PROC sp_PurchaseMembership
    @UserId             INT,
    @MembershipTypeName NVARCHAR(100),
    @PaymentMethod      NVARCHAR(50) = 'QR Code'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MembershipTypeId INT, @Price DECIMAL(18,2), @Duration INT;
    SELECT @MembershipTypeId = MembershipTypeId, @Price = Price, @Duration = DurationMonths
    FROM MembershipTypes WHERE Name = @MembershipTypeName AND IsActive = 1;

    IF @MembershipTypeId IS NULL
    BEGIN
        RAISERROR(N'Gói membership không tồn tại.', 16, 1);
        RETURN;
    END

    DECLARE @OrderId INT, @TxRef NVARCHAR(100);
    EXEC sp_CreateOrder @UserId, 'Membership', @PaymentMethod, NULL, @OrderId OUTPUT, @TxRef OUTPUT;
    EXEC sp_AddOrderItem @OrderId, 'Membership', @MembershipTypeName, NULL, NULL, @MembershipTypeId, NULL, NULL, 1, @Price;

    PRINT N'✅ Membership order tạo thành công. TxRef: ' + @TxRef;
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  NHÓM D: SHOP (Admin CRUD)                                ║
-- ╚══════════════════════════════════════════════════════════════╝

-- D1. Admin thêm sản phẩm
CREATE OR ALTER PROC sp_InsertShopProduct
    @CategoryName   NVARCHAR(100),
    @Name           NVARCHAR(200),
    @Description    NVARCHAR(MAX) = NULL,
    @Price          DECIMAL(18,2),
    @ImagePath      NVARCHAR(255) = NULL,
    @StockQuantity  INT = 0,
    @ProductId      INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CategoryId INT;
    SELECT @CategoryId = CategoryId FROM ShopCategories WHERE Name = @CategoryName AND IsActive = 1;

    IF @CategoryId IS NULL
    BEGIN
        RAISERROR(N'Danh mục "%s" không tồn tại.', 16, 1, @CategoryName);
        RETURN;
    END

    INSERT INTO ShopProducts (CategoryId, Name, Description, Price, ImagePath, StockQuantity)
    VALUES (@CategoryId, @Name, @Description, @Price, @ImagePath, @StockQuantity);

    SET @ProductId = SCOPE_IDENTITY();
    PRINT N'✅ Sản phẩm đã thêm: ' + @Name;
END
GO

-- D2. Admin sửa sản phẩm
CREATE OR ALTER PROC sp_UpdateShopProduct
    @ProductId      INT,
    @Name           NVARCHAR(200) = NULL,
    @Description    NVARCHAR(MAX) = NULL,
    @Price          DECIMAL(18,2) = NULL,
    @ImagePath      NVARCHAR(255) = NULL,
    @StockQuantity  INT = NULL,
    @IsActive       BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ShopProducts
    SET Name            = ISNULL(@Name, Name),
        Description     = ISNULL(@Description, Description),
        Price           = ISNULL(@Price, Price),
        ImagePath       = ISNULL(@ImagePath, ImagePath),
        StockQuantity   = ISNULL(@StockQuantity, StockQuantity),
        IsActive        = ISNULL(@IsActive, IsActive),
        UpdatedAt       = GETDATE()
    WHERE ProductId = @ProductId;

    PRINT N'✅ Sản phẩm #' + CAST(@ProductId AS NVARCHAR(10)) + N' đã cập nhật.';
END
GO

-- D3. Admin xóa sản phẩm (soft delete)
CREATE OR ALTER PROC sp_DeleteShopProduct
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ShopProducts SET IsActive = 0, UpdatedAt = GETDATE() WHERE ProductId = @ProductId;
    PRINT N'✅ Sản phẩm #' + CAST(@ProductId AS NVARCHAR(10)) + N' đã ngừng bán.';
END
GO

-- D4. Admin thêm danh mục Shop
CREATE OR ALTER PROC sp_InsertShopCategory
    @Name       NVARCHAR(100),
    @Description NVARCHAR(MAX) = NULL,
    @IconClass  NVARCHAR(50) = 'fa-tag',
    @SortOrder  INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM ShopCategories WHERE Name = @Name)
    BEGIN
        RAISERROR(N'Danh mục đã tồn tại.', 16, 1);
        RETURN;
    END

    INSERT INTO ShopCategories (Name, Description, IconClass, SortOrder)
    VALUES (@Name, @Description, @IconClass, @SortOrder);

    PRINT N'✅ Danh mục đã thêm: ' + @Name;
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  NHÓM E: ZOO CONTENT                                      ║
-- ╚══════════════════════════════════════════════════════════════╝

-- E1. Thêm động vật
CREATE OR ALTER PROC sp_InsertAnimal
    @ZoneName           NVARCHAR(100),
    @AnimalName         NVARCHAR(100),
    @Species            NVARCHAR(100),
    @ConservationStatus NVARCHAR(100) = NULL,
    @Description        NVARCHAR(MAX) = NULL,
    @ImagePath          NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ZoneId INT;
    SELECT @ZoneId = ZoneId FROM Zones WHERE Name = @ZoneName;

    IF @ZoneId IS NULL
    BEGIN
        INSERT INTO Zones (Name) VALUES (@ZoneName);
        SET @ZoneId = SCOPE_IDENTITY();
    END

    INSERT INTO Animals (ZoneId, Name, Species, ConservationStatus, Description, ImagePath)
    VALUES (@ZoneId, @AnimalName, @Species, @ConservationStatus, @Description, @ImagePath);

    PRINT N'✅ Đã thêm: ' + @AnimalName;
END
GO

-- E2. Thêm sự kiện
CREATE OR ALTER PROC sp_InsertEvent
    @Title      NVARCHAR(200),
    @Description NVARCHAR(MAX) = NULL,
    @EventDate  DATETIME,
    @Capacity   INT = NULL,
    @BasePrice  DECIMAL(18,2) = NULL,
    @ImagePath  NVARCHAR(255) = NULL,
    @Location   NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Events (Title, Description, EventDate, Capacity, BasePrice, ImagePath, Location)
    VALUES (@Title, @Description, @EventDate, @Capacity, @BasePrice, @ImagePath, @Location);

    PRINT N'✅ Sự kiện đã thêm: ' + @Title;
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  NHÓM F: HOÀN TIỀN                                        ║
-- ╚══════════════════════════════════════════════════════════════╝

-- F1. Yêu cầu hoàn tiền
CREATE OR ALTER PROC sp_RequestRefund
    @OrderId        INT,
    @UserId         INT,
    @RefundReason   NVARCHAR(50),
    @ReasonDetail   NVARCHAR(MAX) = NULL,
    @RefundPercent  DECIMAL(5,2) = 100.00
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OriginalAmount DECIMAL(18,2);
    SELECT @OriginalAmount = TotalAmount FROM Orders WHERE OrderId = @OrderId AND PaymentStatus = 'Completed';

    IF @OriginalAmount IS NULL
    BEGIN
        RAISERROR(N'Đơn hàng không tồn tại hoặc chưa thanh toán.', 16, 1);
        RETURN;
    END

    DECLARE @RefundAmount DECIMAL(18,2) = @OriginalAmount * @RefundPercent / 100;
    DECLARE @TxRef NVARCHAR(100) = 'RFD-' + FORMAT(GETDATE(), 'yyyyMMdd') + '-' + 
        UPPER(LEFT(REPLACE(CAST(NEWID() AS NVARCHAR(36)), '-', ''), 8));

    INSERT INTO Refunds (OrderId, UserId, RefundReason, ReasonDetail, RefundAmount, OriginalAmount, RefundPercent, Status, TransactionRef)
    VALUES (@OrderId, @UserId, @RefundReason, @ReasonDetail, @RefundAmount, @OriginalAmount, @RefundPercent, 'Requested', @TxRef);

    PRINT N'✅ Yêu cầu hoàn tiền đã gửi. Ref: ' + @TxRef;
END
GO

-- F2. Admin xử lý hoàn tiền
CREATE OR ALTER PROC sp_ProcessRefund
    @RefundId   INT,
    @AdminUserId INT,
    @NewStatus  NVARCHAR(50),
    @AdminNotes NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Refunds
    SET Status = @NewStatus,
        ProcessedAt = GETDATE(),
        ProcessedBy = @AdminUserId,
        AdminNotes = @AdminNotes,
        CompletedAt = CASE WHEN @NewStatus = 'Completed' THEN GETDATE() ELSE CompletedAt END
    WHERE RefundId = @RefundId;

    -- Nếu completed → cập nhật Order status
    IF @NewStatus = 'Completed'
    BEGIN
        DECLARE @OrderId INT;
        SELECT @OrderId = OrderId FROM Refunds WHERE RefundId = @RefundId;
        UPDATE Orders SET PaymentStatus = 'Refunded' WHERE OrderId = @OrderId;
    END

    PRINT N'✅ Refund #' + CAST(@RefundId AS NVARCHAR(10)) + N' → ' + @NewStatus;
END
GO

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  NHÓM G: BÁO CÁO DOANH THU                               ║
-- ╚══════════════════════════════════════════════════════════════╝

-- G1. Doanh thu theo ngày
CREATE OR ALTER PROC sp_RevenueByDay
    @TargetDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chi tiết theo loại đơn hàng
    SELECT 
        o.OrderType     AS N'Loại',
        COUNT(o.OrderId) AS N'Số đơn',
        SUM(o.TotalAmount) AS N'Doanh thu'
    FROM Orders o
    WHERE CAST(o.OrderDate AS DATE) = @TargetDate AND o.PaymentStatus = 'Completed'
    GROUP BY o.OrderType;

    -- Chi tiết theo phương thức thanh toán
    SELECT 
        o.PaymentMethod AS N'Phương thức',
        COUNT(o.OrderId) AS N'Số đơn',
        SUM(o.TotalAmount) AS N'Doanh thu'
    FROM Orders o
    WHERE CAST(o.OrderDate AS DATE) = @TargetDate AND o.PaymentStatus = 'Completed'
    GROUP BY o.PaymentMethod;

    -- Tổng ngày
    SELECT 
        @TargetDate AS N'Ngày',
        COUNT(o.OrderId) AS N'Tổng đơn',
        SUM(o.TotalAmount) AS N'TỔNG DOANH THU'
    FROM Orders o
    WHERE CAST(o.OrderDate AS DATE) = @TargetDate AND o.PaymentStatus = 'Completed';
END
GO

-- G2. Doanh thu theo tháng
CREATE OR ALTER PROC sp_RevenueByMonth
    @Year INT,
    @Month INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Theo loại đơn hàng
    SELECT 
        o.OrderType     AS N'Loại',
        COUNT(o.OrderId) AS N'Số đơn',
        SUM(o.TotalAmount) AS N'Doanh thu'
    FROM Orders o
    WHERE YEAR(o.OrderDate) = @Year AND MONTH(o.OrderDate) = @Month AND o.PaymentStatus = 'Completed'
    GROUP BY o.OrderType;

    -- Theo ngày trong tháng
    SELECT 
        CAST(o.OrderDate AS DATE) AS N'Ngày',
        COUNT(o.OrderId) AS N'Số đơn',
        SUM(o.TotalAmount) AS N'Doanh thu'
    FROM Orders o
    WHERE YEAR(o.OrderDate) = @Year AND MONTH(o.OrderDate) = @Month AND o.PaymentStatus = 'Completed'
    GROUP BY CAST(o.OrderDate AS DATE)
    ORDER BY CAST(o.OrderDate AS DATE);

    -- Tổng tháng + so sánh tháng trước
    DECLARE @CurrentRev DECIMAL(18,2), @PrevRev DECIMAL(18,2);
    DECLARE @PrevMonth INT = @Month - 1, @PrevYear INT = @Year;
    IF @PrevMonth = 0 BEGIN SET @PrevMonth = 12; SET @PrevYear = @Year - 1; END

    SELECT @CurrentRev = ISNULL(SUM(TotalAmount), 0) FROM Orders
    WHERE YEAR(OrderDate) = @Year AND MONTH(OrderDate) = @Month AND PaymentStatus = 'Completed';

    SELECT @PrevRev = ISNULL(SUM(TotalAmount), 0) FROM Orders
    WHERE YEAR(OrderDate) = @PrevYear AND MONTH(OrderDate) = @PrevMonth AND PaymentStatus = 'Completed';

    SELECT 
        @CurrentRev AS N'Doanh thu tháng này',
        @PrevRev AS N'Doanh thu tháng trước',
        @CurrentRev - @PrevRev AS N'Chênh lệch',
        CASE WHEN @PrevRev > 0 
            THEN CAST(ROUND((@CurrentRev - @PrevRev) / @PrevRev * 100, 2) AS NVARCHAR(10)) + '%'
            ELSE N'N/A'
        END AS N'Tăng trưởng';
END
GO

PRINT N'╔════════════════════════════════════════════════════╗';
PRINT N'║ ✅ 02_StoredProcedures.sql HOÀN TẤT (20 procedures) ║';
PRINT N'╚════════════════════════════════════════════════════╝';
GO
