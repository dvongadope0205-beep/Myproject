-- ============================================================
-- 05_SeedData.sql — ZooDatabase V2 — Dữ liệu mẫu
-- Chạy sau 04_TriggersAndFunctions.sql
-- ============================================================
USE [ZooDatabase]
GO

-- ══════ ROLES ══════
IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Admin')
    INSERT INTO Roles (RoleName) VALUES ('Admin');
IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'User')
    INSERT INTO Roles (RoleName) VALUES ('User');
GO

-- ══════ USERS (1 Admin + 10 Users) ══════
DECLARE @AdminRole INT, @UserRole INT;
SELECT @AdminRole = RoleId FROM Roles WHERE RoleName = 'Admin';
SELECT @UserRole = RoleId FROM Roles WHERE RoleName = 'User';

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'admin')
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@AdminRole, 'admin', 'admin@zoo.com', 'admin', 'System Administrator', '0123456789', 'Zoo HQ', 'Male', '1985-01-15');

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'johndoe')
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@UserRole, 'johndoe', 'john@gmail.com', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'John Doe', '0987654321', '123 Fake Street', 'Male', '1990-05-20');

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'nguyenvana')
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@UserRole, 'nguyenvana', 'nguyenvana@gmail.com', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', N'Nguyễn Văn A', '0901234567', N'123 Lê Lợi, Q1, TP.HCM', 'Male', '1990-05-15');

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'tranthib')
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@UserRole, 'tranthib', 'tranthib@gmail.com', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', N'Trần Thị B', '0912345678', N'456 Nguyễn Huệ, Q1', 'Female', '1985-08-22');

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'leminhc')
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@UserRole, 'leminhc', 'leminhc@gmail.com', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', N'Lê Minh C', '0923456789', N'789 Hai Bà Trưng, Q3', 'Male', '1992-11-03');

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'phamthid')
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@UserRole, 'phamthid', 'phamthid@gmail.com', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', N'Phạm Thị D', '0934567890', N'101 Võ Văn Tần, Q3', 'Female', '1988-02-14');

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'hoangvane')
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@UserRole, 'hoangvane', 'hoangvane@gmail.com', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', N'Hoàng Văn E', '0945678901', N'202 Điện Biên Phủ, Bình Thạnh', 'Male', '1995-07-30');

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'vothif')
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@UserRole, 'vothif', 'vothif@gmail.com', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', N'Võ Thị F', '0956789012', N'303 Cách Mạng Tháng 8, Q10', 'Female', '1993-12-25');

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'dangquocg')
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@UserRole, 'dangquocg', 'dangquocg@gmail.com', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', N'Đặng Quốc G', '0967890123', N'404 Trần Hưng Đạo, Q5', 'Male', '1987-04-18');

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'buithih')
    INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, Gender, DateOfBirth)
    VALUES (@UserRole, 'buithih', 'buithih@gmail.com', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', N'Bùi Thị H', '0978901234', N'505 Lý Thường Kiệt, Q10', 'Female', '1991-09-08');
GO
PRINT N'✅ Đã seed Roles + Users';
GO

-- ══════ TICKET TYPES ══════
IF NOT EXISTS (SELECT 1 FROM TicketTypes WHERE Name = 'Adult')
BEGIN
    INSERT INTO TicketTypes (Name, BasePrice, Description, AgeRange) VALUES
    ('Adult', 15.00, N'Vé người lớn từ 12 tuổi', '12+'),
    ('Child', 10.00, N'Vé trẻ em từ 3-11 tuổi', '3-11'),
    ('Senior', 12.00, N'Vé ưu đãi người cao tuổi 65+', '65+');
END
GO

-- ══════ MEMBERSHIP TYPES ══════
IF NOT EXISTS (SELECT 1 FROM MembershipTypes WHERE Name = 'Individual')
BEGIN
    INSERT INTO MembershipTypes (Name, Price, DurationMonths, Benefits) VALUES
    ('Individual', 79.99, 12, N'Unlimited visits, 10% gift shop discount, member events'),
    ('Family', 149.99, 12, N'Unlimited visits for 4, 15% gift shop discount, free parking'),
    ('Premium', 249.99, 12, N'Unlimited visits, 20% all discounts, VIP events, behind-the-scenes tours'),
    ('Student', 49.99, 12, N'Unlimited visits, 10% food court discount, valid student ID required');
END
GO

-- ══════ EVENTS ══════
IF NOT EXISTS (SELECT 1 FROM Events WHERE Title = 'Night Safari')
BEGIN
    INSERT INTO Events (Title, Description, EventDate, Capacity, BasePrice, ImagePath, Location) VALUES
    ('Night Safari', 'Experience the zoo after dark with guided tours.', '2026-06-15', 200, 25.00, '/Source/General/8.jpg', 'Main Zoo Trail'),
    ('Brew at the Zoo', 'Annual beer festival supporting conservation. 21+ only. Live music and local breweries.', '2026-06-20', 500, 30.00, '/Source/General/7.jpg', 'Central Plaza'),
    ('ZooLights Festival', 'Spectacular light displays throughout the zoo.', '2026-07-04', 500, 30.00, '/Source/General/15.jpg', 'Central Plaza'),
    ('Conservation Gala', 'Annual fundraising gala for conservation.', '2026-08-20', 150, 20.00, '/Source/General/13.jpg', 'Grand Pavilion'),
    ('Ecosystem Exploration', 'Learn about ecosystems with expert guides.', '2026-09-10', 100, 18.00, '/Source/General/2.jpg', 'Education Center'),
    ('Wildlife Action Day', 'Interactive activities for the whole family.', '2026-10-05', 300, 15.00, '/Source/General/6.jpg', 'Adventure Zone'),
    ('Zookeeper Camp', 'A week-long immersive experience learning the daily life of professional zookeepers. Ages 10-14', '2026-07-06', 30, 150.00, '/Source/General/11.jpg', 'Education Center'),
    ('Up-Close Animal Encounters Camp', 'Half-day experiences meeting our animal ambassadors. Ages 5-9', '2026-07-13', 25, 150.00, '/Source/General/9.jpg', 'Education Center'),
    ('Keeper Talk Series', 'Learn from the experts! Join our keepers as they discuss daily animal care, training techniques, and behavioral observations.', '2026-08-10', 100, 35.00, '/Source/General/12.jpg', 'Amphitheater');
END
GO

-- ══════ ZONES & ANIMALS ══════
IF NOT EXISTS (SELECT 1 FROM Zones WHERE Name = 'African Savanna')
BEGIN
    INSERT INTO Zones (Name, Description) VALUES
    ('African Savanna', 'Home to lions, elephants, and giraffes'),
    ('Asian Rainforest', 'Tigers, orangutans, and exotic birds'),
    ('Arctic Tundra', 'Polar bears and arctic foxes'),
    ('Australian Outback', 'Kangaroos and koalas'),
    ('Reptile House', 'Snakes, lizards, and crocodiles'),
    ('Aquatic World', 'Penguins, sea lions, and fish');
END
GO

DECLARE @Z1 INT, @Z2 INT, @Z3 INT, @Z4 INT, @Z5 INT, @Z6 INT;
SELECT @Z1=ZoneId FROM Zones WHERE Name='African Savanna';
SELECT @Z2=ZoneId FROM Zones WHERE Name='Asian Rainforest';
SELECT @Z3=ZoneId FROM Zones WHERE Name='Arctic Tundra';
SELECT @Z4=ZoneId FROM Zones WHERE Name='Australian Outback';
SELECT @Z5=ZoneId FROM Zones WHERE Name='Reptile House';
SELECT @Z6=ZoneId FROM Zones WHERE Name='Aquatic World';

IF NOT EXISTS (SELECT 1 FROM Animals WHERE Name = 'Leo the Lion')
BEGIN
    INSERT INTO Animals (ZoneId, Name, Species, ConservationStatus, Description, ImagePath) VALUES
    (@Z1, 'Leo the Lion', 'Panthera leo', 'Vulnerable', 'King of the African Savanna', '/Source/Picture/animal-lion.jpg'),
    (@Z1, 'Ellie the Elephant', 'Loxodonta africana', 'Endangered', 'African bush elephant', '/Source/Picture/animal-elephant.jpg'),
    (@Z1, 'Gerald the Giraffe', 'Giraffa camelopardalis', 'Vulnerable', 'Tallest land animal', '/Source/Picture/animal-giraffe.jpg'),
    (@Z2, 'Raja the Tiger', 'Panthera tigris', 'Endangered', 'Bengal tiger from India', '/Source/Picture/animal-tiger.jpg'),
    (@Z2, 'Oscar the Orangutan', 'Pongo pygmaeus', 'Critically Endangered', 'Bornean orangutan', '/Source/Picture/animal-orangutan.jpg'),
    (@Z3, 'Frost the Polar Bear', 'Ursus maritimus', 'Vulnerable', 'Arctic polar bear', '/Source/Picture/animal-polarbear.jpg'),
    (@Z4, 'Joey the Kangaroo', 'Macropus rufus', 'Least Concern', 'Red kangaroo', '/Source/Picture/animal-kangaroo.jpg'),
    (@Z4, 'Cuddles the Koala', 'Phascolarctos cinereus', 'Vulnerable', 'Australian koala', '/Source/Picture/animal-koala.jpg'),
    (@Z5, 'Scales the Python', 'Python reticulatus', 'Least Concern', 'Reticulated python', '/Source/Picture/animal-snake.jpg'),
    (@Z6, 'Splash the Penguin', 'Aptenodytes patagonicus', 'Least Concern', 'King penguin', '/Source/Picture/animal-penguin.jpg');
END
GO

-- ══════ SHOP CATEGORIES ══════
IF NOT EXISTS (SELECT 1 FROM ShopCategories WHERE Name = 'Plush Toys')
BEGIN
    INSERT INTO ShopCategories (Name, Description, IconClass, SortOrder) VALUES
    ('Plush Toys', 'Soft animal plush toys', 'fa-paw', 1),
    ('Apparel', 'T-shirts, hats, and clothing', 'fa-tshirt', 2),
    ('Accessories', 'Mugs, keychains, and more', 'fa-coffee', 3),
    ('Books', 'Educational books and guides', 'fa-book', 4),
    ('Souvenirs', 'Postcards, magnets, figurines', 'fa-gift', 5),
    ('Eco Products', 'Sustainable and eco-friendly items', 'fa-leaf', 6);
END
GO

-- ══════ SHOP PRODUCTS ══════
DECLARE @C1 INT, @C2 INT, @C3 INT, @C4 INT, @C5 INT, @C6 INT;
SELECT @C1=CategoryId FROM ShopCategories WHERE Name='Plush Toys';
SELECT @C2=CategoryId FROM ShopCategories WHERE Name='Apparel';
SELECT @C3=CategoryId FROM ShopCategories WHERE Name='Accessories';
SELECT @C4=CategoryId FROM ShopCategories WHERE Name='Books';
SELECT @C5=CategoryId FROM ShopCategories WHERE Name='Souvenirs';
SELECT @C6=CategoryId FROM ShopCategories WHERE Name='Eco Products';

IF NOT EXISTS (SELECT 1 FROM ShopProducts WHERE Name = 'Plush Giraffe')
BEGIN
    INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, ImagePath) VALUES
    (@C1, 'Plush Giraffe', 'Soft 30cm giraffe plush toy', 24.99, 50, '/Source/Picture/animal-giraffe.jpg'),
    (@C1, 'Plush Lion', 'Cute 25cm lion plush', 22.99, 40, '/Source/Picture/animal-lion.jpg'),
    (@C1, 'Plush Elephant', 'Large 40cm elephant plush', 29.99, 35, '/Source/Picture/animal-elephant.jpg'),
    (@C2, 'Conservation T-Shirt', '100% cotton zoo t-shirt', 19.99, 100, '/Source/Picture/animal-tiger.jpg'),
    (@C2, 'Safari Cap', 'Adjustable safari-style cap', 14.99, 80, '/Source/Picture/animal-tiger.jpg'),
    (@C2, 'Kids Animal Hoodie', 'Warm hoodie with animal ears', 34.99, 45, '/Source/Picture/animal-tiger.jpg'),
    (@C3, 'Zoo Mug - Lion', 'Ceramic mug with lion design', 14.99, 60, '/Source/Picture/animal-polarbear.jpg'),
    (@C3, 'Animal Keychain Set', 'Set of 5 animal keychains', 9.99, 120, '/Source/Picture/animal-orangutan.jpg'),
    (@C4, 'Animal Encyclopedia', 'Comprehensive guide to 500+ animals', 29.99, 30, '/Source/Picture/animal-penguin.jpg'),
    (@C4, 'Kids Activity Book', 'Coloring and activity book', 12.99, 75, '/Source/Picture/animal-penguin.jpg'),
    (@C5, 'Zoo Magnet Collection', 'Set of 8 animal magnets', 8.99, 90, '/Source/Picture/animal-koala.jpg'),
    (@C6, 'Bamboo Water Bottle', 'Eco-friendly reusable bottle', 18.99, 55, '/Source/Picture/animal-snake.jpg');
END
GO

-- ══════ REFUND REASONS ══════
IF NOT EXISTS (SELECT 1 FROM RefundReasons WHERE ReasonCode = 'ScheduleChange')
BEGIN
    INSERT INTO RefundReasons (ReasonCode, ReasonLabel, ReasonLabelVi, RequiresDetail, SortOrder) VALUES
    ('ScheduleChange', 'Schedule change', N'Thay đổi lịch trình', 0, 1),
    ('NoLongerInterested', 'No longer interested', N'Không còn muốn tham quan', 0, 2),
    ('DuplicatePurchase', 'Duplicate purchase', N'Mua trùng hoặc mua nhầm', 0, 3),
    ('EventCancelled', 'Event cancelled', N'Sự kiện bị hủy', 0, 4),
    ('WeatherIssue', 'Bad weather', N'Thời tiết xấu', 0, 5),
    ('HealthIssue', 'Health reasons', N'Lý do sức khỏe', 0, 6),
    ('FamilyEmergency', 'Family emergency', N'Việc gia đình khẩn cấp', 0, 7),
    ('PriceDispute', 'Incorrect price', N'Bị tính giá sai', 1, 8),
    ('ServiceComplaint', 'Unsatisfied with service', N'Không hài lòng dịch vụ', 1, 9),
    ('Other', 'Other reason', N'Lý do khác', 1, 10);
END
GO

-- ══════ SAMPLE ORDERS (Tickets) ══════
DECLARE @U1 INT, @U2 INT, @U3 INT, @U4 INT, @U5 INT;
SELECT @U1=UserId FROM Users WHERE Username='johndoe';
SELECT @U2=UserId FROM Users WHERE Username='nguyenvana';
SELECT @U3=UserId FROM Users WHERE Username='tranthib';
SELECT @U4=UserId FROM Users WHERE Username='leminhc';
SELECT @U5=UserId FROM Users WHERE Username='phamthid';

DECLARE @AdultTT INT, @ChildTT INT, @SeniorTT INT;
SELECT @AdultTT=TicketTypeId FROM TicketTypes WHERE Name='Adult';
SELECT @ChildTT=TicketTypeId FROM TicketTypes WHERE Name='Child';
SELECT @SeniorTT=TicketTypeId FROM TicketTypes WHERE Name='Senior';

IF NOT EXISTS (SELECT 1 FROM Orders WHERE TransactionRef = 'TXN-SEED-001')
BEGIN
    -- Order 1: John Doe - 2 Adult tickets
    INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (@U1, 'Ticket', 30.00, 'QR Code', 'Completed', 'TXN-SEED-001', 'General Admission');
    DECLARE @O1 INT = SCOPE_IDENTITY();
    INSERT INTO OrderItems (OrderId, ItemType, ItemName, TicketTypeId, VisitDate, Quantity, UnitPrice)
    VALUES (@O1, 'Ticket', 'Adult Ticket', @AdultTT, '2026-05-01', 2, 15.00);

    -- Order 2: Nguyen Van A - Event ticket
    INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (@U2, 'Event', 50.00, 'Card', 'Completed', 'TXN-SEED-002', 'Night Safari');
    DECLARE @O2 INT = SCOPE_IDENTITY();
    DECLARE @Evt1 INT; SELECT @Evt1=EventId FROM Events WHERE Title='Night Safari';
    INSERT INTO OrderItems (OrderId, ItemType, ItemName, EventId, VisitDate, Quantity, UnitPrice)
    VALUES (@O2, 'Event', 'Night Safari', @Evt1, '2026-06-15', 2, 25.00);

    -- Order 3: Tran Thi B - 3 Child tickets
    INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (@U3, 'Ticket', 30.00, 'Online', 'Completed', 'TXN-SEED-003', 'Children visit');
    DECLARE @O3 INT = SCOPE_IDENTITY();
    INSERT INTO OrderItems (OrderId, ItemType, ItemName, TicketTypeId, VisitDate, Quantity, UnitPrice)
    VALUES (@O3, 'Ticket', 'Child Ticket', @ChildTT, '2026-05-10', 3, 10.00);

    -- Order 4: Le Minh C - Shop purchase
    INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (@U4, 'Shop', 44.98, 'QR Code', 'Completed', 'TXN-SEED-004', 'Shop purchase');
    DECLARE @O4 INT = SCOPE_IDENTITY();
    DECLARE @P1 INT, @P2 INT;
    SELECT @P1=ProductId FROM ShopProducts WHERE Name='Plush Giraffe';
    SELECT @P2=ProductId FROM ShopProducts WHERE Name='Conservation T-Shirt';
    INSERT INTO OrderItems (OrderId, ItemType, ItemName, ProductId, Quantity, UnitPrice) VALUES
    (@O4, 'Shop', 'Plush Giraffe', @P1, 1, 24.99),
    (@O4, 'Shop', 'Conservation T-Shirt', @P2, 1, 19.99);

    -- Order 5: Pham Thi D - Membership
    INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, Notes)
    VALUES (@U5, 'Membership', 149.99, 'Transfer', 'Completed', 'TXN-SEED-005', 'Family Membership');
    DECLARE @O5 INT = SCOPE_IDENTITY();
    DECLARE @FamMT INT; SELECT @FamMT=MembershipTypeId FROM MembershipTypes WHERE Name='Family';
    INSERT INTO OrderItems (OrderId, ItemType, ItemName, MembershipTypeId, Quantity, UnitPrice)
    VALUES (@O5, 'Membership', 'Family Membership', @FamMT, 1, 149.99);

    PRINT N'✅ Đã seed 5 Orders mẫu';
END
GO

-- ══════ SAMPLE MEMBERSHIPS ══════
DECLARE @MU2 INT, @MU3 INT, @MU5 INT;
SELECT @MU2=UserId FROM Users WHERE Username='nguyenvana';
SELECT @MU3=UserId FROM Users WHERE Username='tranthib';
SELECT @MU5=UserId FROM Users WHERE Username='phamthid';

DECLARE @IndvMT INT, @FamilyMT INT, @StudentMT INT;
SELECT @IndvMT=MembershipTypeId FROM MembershipTypes WHERE Name='Individual';
SELECT @FamilyMT=MembershipTypeId FROM MembershipTypes WHERE Name='Family';
SELECT @StudentMT=MembershipTypeId FROM MembershipTypes WHERE Name='Student';

IF NOT EXISTS (SELECT 1 FROM UserMemberships um INNER JOIN Users u ON um.UserId=u.UserId WHERE u.Username='nguyenvana')
BEGIN
    INSERT INTO UserMemberships (UserId, MembershipTypeId, StartDate, EndDate, Status) VALUES
    (@MU2, @IndvMT, '2026-01-01', '2027-01-01', 'Active'),
    (@MU3, @StudentMT, '2026-03-01', '2027-03-01', 'Active'),
    (@MU5, @FamilyMT, '2026-02-15', '2027-02-15', 'Active');
    PRINT N'✅ Đã seed UserMemberships';
END
GO

PRINT N'╔═════════════════════════════════════════╗';
PRINT N'║ ✅ 05_SeedData.sql HOÀN TẤT             ║';
PRINT N'╚═════════════════════════════════════════╝';
GO
