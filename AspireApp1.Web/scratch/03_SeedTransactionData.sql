USE [ZooDatabase]
GO

-- ============================================================================
-- SEED 100 HISTORICAL TRANSACTIONS (May 1 - June 1, 2026)
-- Categories: Ticket, Event, Membership, Shop
-- Payment Methods: QR Code (-> Completed), Cash (-> Pending)
-- Mix of Guest and Authenticated users
-- ============================================================================

SET NOCOUNT ON;

-- Helper variables
DECLARE @i INT = 1;
DECLARE @OrderType NVARCHAR(20);
DECLARE @PaymentMethod NVARCHAR(20);
DECLARE @PaymentStatus NVARCHAR(20);
DECLARE @TotalAmount DECIMAL(18,2);
DECLARE @UserId INT;
DECLARE @OrderDate DATETIME;
DECLARE @TransactionRef NVARCHAR(100);
DECLARE @CustomerName NVARCHAR(100);
DECLARE @CustomerEmail NVARCHAR(100);
DECLARE @CustomerPhone NVARCHAR(50);
DECLARE @CustomerAddress NVARCHAR(255);
DECLARE @Notes NVARCHAR(500);
DECLARE @OrderId INT;
DECLARE @Rand FLOAT;
DECLARE @RandCat INT;
DECLARE @ItemQty INT;
DECLARE @UnitPrice DECIMAL(18,2);
DECLARE @ItemName NVARCHAR(200);
DECLARE @ItemType NVARCHAR(50);
DECLARE @TicketTypeId INT;
DECLARE @EventId INT;
DECLARE @ProductId INT;
DECLARE @ExperienceId INT;

-- Guest name pools
DECLARE @GuestNames TABLE (Id INT IDENTITY(1,1), GName NVARCHAR(100), GEmail NVARCHAR(100), GPhone NVARCHAR(50), GAddress NVARCHAR(200));
INSERT INTO @GuestNames VALUES
('Alex Johnson', 'alex.j@outlook.com', '+1-555-0101', '123 Elm St, New York, NY 10001'),
('Maria Garcia', 'maria.g@yahoo.com', '+1-555-0202', '456 Oak Ave, Los Angeles, CA 90001'),
('James Wilson', 'james.w@gmail.com', '+1-555-0303', '789 Pine Rd, Chicago, IL 60601'),
('Sophie Brown', 'sophie.b@hotmail.com', '+44-20-7946-0958', '10 Baker St, London, UK'),
('Liam O''Brien', 'liam.ob@gmail.com', '+1-555-0404', '321 Maple Dr, Houston, TX 77001'),
('Emma Davis', 'emma.d@outlook.com', '+1-555-0505', '654 Cedar Ln, Phoenix, AZ 85001'),
('Oliver Smith', 'oliver.s@yahoo.com', '+44-20-7946-1234', '22 King Rd, Manchester, UK'),
('Ava Martinez', 'ava.m@gmail.com', '+1-555-0606', '987 Birch Ct, Philadelphia, PA 19101'),
('Noah Taylor', 'noah.t@hotmail.com', '+1-555-0707', '159 Walnut Way, San Antonio, TX 78201'),
('Isabella Anderson', 'isabella.a@gmail.com', '+1-555-0808', '753 Spruce Blvd, San Diego, CA 92101'),
('Nguyen Van Tuan', 'tuan.nv@gmail.com', '+84-909-123456', '12 Le Loi, Quan 1, TP.HCM'),
('Tran Thi Mai', 'mai.tt@gmail.com', '+84-912-654321', '45 Hai Ba Trung, Ha Noi'),
('Pham Duc Anh', 'anh.pd@outlook.com', '+84-903-789012', '78 Nguyen Hue, Da Nang'),
('Le Hoang Nam', 'nam.lh@yahoo.com', '+84-935-456789', '23 Tran Phu, Nha Trang'),
('Vo Thi Lan', 'lan.vt@gmail.com', '+84-908-321654', '56 Bach Dang, Hue');

-- Product pools
DECLARE @ShopItems TABLE (PId INT, PName NVARCHAR(200), PPrice DECIMAL(18,2));
INSERT INTO @ShopItems VALUES
(13, 'Batrick Plush With Sunglasses And Hawaiian Shirt', 21.00),
(14, 'Kevin the Otter Plush', 23.00),
(15, 'Emily The Axolotl Plush', 23.00),
(16, 'Talking Mouth Plush', 24.00),
(17, 'Lisa Plush With Balloon', 23.00),
(18, 'Albie Plush', 23.00),
(19, 'Jason Plush', 23.00),
(20, 'Chris Plush', 23.00),
(23, 'Batrick Crewneck', 35.00),
(24, 'Batrick Hoodie', 45.00),
(25, 'Batrick Tee', 21.00),
(26, 'Axolotl Tee', 21.00),
(27, 'Lisa Tee', 21.00),
(29, 'NH Tee', 18.00),
(30, 'NH Fall Hoodie', 50.00),
(33, 'Kevin Backpack', 38.00),
(41, 'NH Notebook', 12.00),
(42, 'NH Sticker', 8.00);

WHILE @i <= 100
BEGIN
    -- Random date between May 1 and June 1, 2026
    SET @Rand = RAND(CHECKSUM(NEWID()));
    SET @OrderDate = DATEADD(MINUTE, CAST(@Rand * 44640 AS INT), '2026-05-01');  -- 31 days * 24h * 60m = 44640 minutes

    -- Random category: 1=Ticket(35%), 2=Event(25%), 3=Membership(15%), 4=Shop(25%)
    SET @RandCat = CASE
        WHEN @Rand < 0.35 THEN 1
        WHEN @Rand < 0.60 THEN 2
        WHEN @Rand < 0.75 THEN 3
        ELSE 4
    END;

    -- Random payment: QR Code (60%) or Cash (40%)
    IF RAND(CHECKSUM(NEWID())) < 0.60
    BEGIN
        SET @PaymentMethod = 'QR Code';
        SET @PaymentStatus = 'Completed';
        SET @TransactionRef = 'QR-' + LEFT(REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', ''), 8);
    END
    ELSE
    BEGIN
        SET @PaymentMethod = 'Cash';
        SET @PaymentStatus = 'Pending';
        SET @TransactionRef = 'CASH-' + LEFT(REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', ''), 8);
    END

    -- Random user: 50% authenticated, 50% guest
    IF RAND(CHECKSUM(NEWID())) < 0.50
    BEGIN
        -- Authenticated user (pick from UserId 2-10)
        SET @UserId = 2 + ABS(CHECKSUM(NEWID())) % 9;
        SELECT @CustomerName = FullName, @CustomerEmail = Email 
        FROM Users WHERE UserId = @UserId;
        SET @CustomerPhone = '+1-555-' + RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS VARCHAR), 4);
        SET @CustomerAddress = CAST(ABS(CHECKSUM(NEWID())) % 999 + 1 AS VARCHAR) + ' Main St, City, State';
    END
    ELSE
    BEGIN
        -- Guest user
        SET @UserId = NULL;
        DECLARE @GuestIdx INT = 1 + ABS(CHECKSUM(NEWID())) % 15;
        SELECT @CustomerName = GName, @CustomerEmail = GEmail, @CustomerPhone = GPhone, @CustomerAddress = GAddress
        FROM @GuestNames WHERE Id = @GuestIdx;
    END

    SET @Notes = 'Seeded transaction #' + CAST(@i AS VARCHAR) + ' - ' + @PaymentMethod;

    -- ═══════ TICKET ORDERS ═══════
    IF @RandCat = 1
    BEGIN
        SET @OrderType = 'Ticket';
        SET @ItemQty = 1 + ABS(CHECKSUM(NEWID())) % 4;  -- 1-4 tickets
        
        -- Pick random ticket type
        SET @TicketTypeId = 1 + ABS(CHECKSUM(NEWID())) % 3;
        SELECT @UnitPrice = BasePrice, @ItemName = Name FROM TicketTypes WHERE TicketTypeId = @TicketTypeId;
        SET @TotalAmount = @UnitPrice * @ItemQty;

        INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, Notes, OrderDate, CustomerName, CustomerEmail, CustomerPhone, CustomerAddress)
        VALUES (@UserId, @OrderType, @TotalAmount, @PaymentMethod, @PaymentStatus, @TransactionRef, @Notes, @OrderDate, @CustomerName, @CustomerEmail, @CustomerPhone, @CustomerAddress);
        SET @OrderId = SCOPE_IDENTITY();

        INSERT INTO OrderItems (OrderId, ItemType, ItemName, TicketTypeId, Quantity, UnitPrice, VisitDate)
        VALUES (@OrderId, 'Ticket', @ItemName + ' Ticket', @TicketTypeId, @ItemQty, @UnitPrice, DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 14, @OrderDate));
    END

    -- ═══════ EVENT ORDERS ═══════
    ELSE IF @RandCat = 2
    BEGIN
        SET @OrderType = 'Event';
        SET @ItemQty = 1 + ABS(CHECKSUM(NEWID())) % 3;  -- 1-3 tickets

        -- Pick random event
        SET @EventId = 1 + ABS(CHECKSUM(NEWID())) % 8;
        SELECT @UnitPrice = BasePrice, @ItemName = Title FROM Events WHERE EventId = @EventId;
        IF @ItemName IS NULL BEGIN SET @ItemName = 'Event Ticket'; SET @UnitPrice = 20.00; SET @EventId = 1; END
        SET @TotalAmount = @UnitPrice * @ItemQty;

        INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, Notes, OrderDate, CustomerName, CustomerEmail, CustomerPhone, CustomerAddress)
        VALUES (@UserId, @OrderType, @TotalAmount, @PaymentMethod, @PaymentStatus, @TransactionRef, @Notes, @OrderDate, @CustomerName, @CustomerEmail, @CustomerPhone, @CustomerAddress);
        SET @OrderId = SCOPE_IDENTITY();

        INSERT INTO OrderItems (OrderId, ItemType, ItemName, EventId, Quantity, UnitPrice)
        VALUES (@OrderId, 'Event', @ItemName, @EventId, @ItemQty, @UnitPrice);
    END

    -- ═══════ MEMBERSHIP ORDERS ═══════
    ELSE IF @RandCat = 3
    BEGIN
        SET @OrderType = 'Membership';
        SET @ItemQty = 1;

        -- Membership tiers
        DECLARE @MemberTier INT = 1 + ABS(CHECKSUM(NEWID())) % 3;
        IF @MemberTier = 1
        BEGIN SET @ItemName = 'Individual Membership'; SET @UnitPrice = 79.00; END
        ELSE IF @MemberTier = 2
        BEGIN SET @ItemName = 'Family Membership'; SET @UnitPrice = 149.00; END
        ELSE
        BEGIN SET @ItemName = 'Premium Membership'; SET @UnitPrice = 249.00; END

        SET @TotalAmount = @UnitPrice;

        INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, Notes, OrderDate, CustomerName, CustomerEmail, CustomerPhone, CustomerAddress)
        VALUES (@UserId, @OrderType, @TotalAmount, @PaymentMethod, @PaymentStatus, @TransactionRef, @Notes, @OrderDate, @CustomerName, @CustomerEmail, @CustomerPhone, @CustomerAddress);
        SET @OrderId = SCOPE_IDENTITY();

        INSERT INTO OrderItems (OrderId, ItemType, ItemName, Quantity, UnitPrice)
        VALUES (@OrderId, 'Membership', @ItemName, 1, @UnitPrice);
    END

    -- ═══════ SHOP ORDERS ═══════
    ELSE
    BEGIN
        SET @OrderType = 'Shop';
        
        -- Pick 1-3 random products
        DECLARE @NumItems INT = 1 + ABS(CHECKSUM(NEWID())) % 3;
        SET @TotalAmount = 0;

        INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, Notes, OrderDate, CustomerName, CustomerEmail, CustomerPhone, CustomerAddress)
        VALUES (@UserId, @OrderType, 0, @PaymentMethod, @PaymentStatus, @TransactionRef, @Notes, @OrderDate, @CustomerName, @CustomerEmail, @CustomerPhone, @CustomerAddress);
        SET @OrderId = SCOPE_IDENTITY();

        DECLARE @j INT = 1;
        WHILE @j <= @NumItems
        BEGIN
            DECLARE @ProdIdx INT = 1 + ABS(CHECKSUM(NEWID())) % 18;
            SELECT TOP 1 @ProductId = PId, @ItemName = PName, @UnitPrice = PPrice FROM @ShopItems WHERE PId = (SELECT TOP 1 PId FROM @ShopItems ORDER BY NEWID());
            SET @ItemQty = 1 + ABS(CHECKSUM(NEWID())) % 3;
            SET @TotalAmount = @TotalAmount + (@UnitPrice * @ItemQty);

            INSERT INTO OrderItems (OrderId, ItemType, ItemName, ProductId, Quantity, UnitPrice)
            VALUES (@OrderId, 'Shop', @ItemName, @ProductId, @ItemQty, @UnitPrice);

            SET @j = @j + 1;
        END

        -- Update total after all items inserted
        UPDATE Orders SET TotalAmount = @TotalAmount WHERE OrderId = @OrderId;
    END

    SET @i = @i + 1;
END

PRINT N'✅ Successfully seeded 100 historical transactions (May 1 - June 1, 2026)';

-- Verify counts
SELECT 'Total Orders' AS Metric, COUNT(*) AS Value FROM Orders
UNION ALL
SELECT 'Total OrderItems', COUNT(*) FROM OrderItems
UNION ALL
SELECT 'Seeded Orders (May 2026)', COUNT(*) FROM Orders WHERE OrderDate >= '2026-05-01' AND OrderDate < '2026-06-02' AND Notes LIKE 'Seeded%'
UNION ALL
SELECT 'QR Code (Completed)', COUNT(*) FROM Orders WHERE PaymentMethod = 'QR Code' AND PaymentStatus = 'Completed' AND Notes LIKE 'Seeded%'
UNION ALL
SELECT 'Cash (Pending)', COUNT(*) FROM Orders WHERE PaymentMethod = 'Cash' AND PaymentStatus = 'Pending' AND Notes LIKE 'Seeded%';
GO
