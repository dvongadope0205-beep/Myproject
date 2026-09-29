
USE [ZooDatabase]
GO


DELETE FROM Animals;
DBCC CHECKIDENT ('Animals', RESEED, 0);
GO

-- Đảm bảo Zone mặc định tồn tại
IF NOT EXISTS (SELECT 1 FROM Zones WHERE Name = 'Main Zoo Area')
    INSERT INTO Zones (Name, Description) VALUES ('Main Zoo Area', 'Default area for all animals');
GO

DECLARE @Z INT;
SELECT @Z = ZoneId FROM Zones WHERE Name = 'Main Zoo Area';

INSERT INTO Animals (ZoneId, Name, Species, ConservationStatus, Description, ImagePath) VALUES
(@Z, 'African Lion', 'MAMMALS', 'Vulnerable', 'The African lion is a majestic apex predator known for its impressive mane and powerful roar. Living in highly social family units called prides, they dominate the savanna ecosystem.', '/Source/Picture/lionn.jpg'),
(@Z, 'Bengal Tiger', 'MAMMALS', 'Endangered', 'Native to the Indian subcontinent, the Bengal tiger is characterized by its striking orange coat and dark stripes. As solitary hunters, they rely on stealth and power.', '/Source/Picture/bengaltiger.jpg'),
(@Z, 'Asian Elephant', 'MAMMALS', 'Endangered', 'The Asian elephant is a highly intelligent and social creature. They play a vital role in maintaining the forest ecosystem by dispersing seeds.', '/Source/Picture/elephant2.jpg'),
(@Z, 'Reticulated Giraffe', 'MAMMALS', 'Vulnerable', 'Recognized by its distinct polygonal spots, the giraffe is the tallest land mammal on Earth. Their incredibly long necks allow them to reach nutrient-rich leaves.', '/Source/Picture/giraffe1.jpg'),
(@Z, 'Giant Panda', 'MAMMALS', 'Vulnerable', 'Endemic to the mountainous regions of China, the giant panda is a global symbol for wildlife conservation. Their diet consists almost entirely of bamboo.', '/Source/Picture/panda.jpg'),
(@Z, 'Plains Zebra', 'MAMMALS', 'Near Threatened', 'The plains zebra is iconic for its dazzling black-and-white striped coat, which acts as a natural camouflage against predators across the plains.', '/Source/Picture/zebra.jpg'),
(@Z, 'Silverback Gorilla', 'PRIMATES', 'Critically Endangered', 'Silverback gorillas are the large, dominant males that lead troops of these peaceful primates in the dense forests of central Africa.', '/Source/Picture/gorilla.jpg'),
(@Z, 'Emperor Penguin', 'BIRDS', 'Near Threatened', 'Endemic to Antarctica, the Emperor penguin is the tallest and heaviest of all living penguin species, enduring the harshest winters on the planet to breed.', '/Source/Picture/penguin1.jpg'),
(@Z, 'Red Kangaroo', 'MARSUPIALS', 'Least Concern', 'The red kangaroo is the largest terrestrial mammal native to Australia. Adapted to the arid outback, they can travel vast distances at high speeds.', '/Source/Picture/kangaroo.jpg'),
(@Z, 'Koala Bear', 'MARSUPIALS', 'Vulnerable', 'Often mistakenly called a bear, the koala is a marsupial strictly native to Australia. They spend almost their entire lives in the canopies of eucalyptus trees.', '/Source/Picture/koala.jpg'),
(@Z, 'White Rhinoceros', 'MAMMALS', 'Near Threatened', 'The white rhinoceros is a massive, heavily armored herbivore native to southern Africa. They have a wide, square lip perfectly adapted for grazing.', '/Source/Picture/Rhino.jpg'),
(@Z, 'Hippopotamus', 'MAMMALS', 'Vulnerable', 'Despite their bulky appearance, hippos are highly dangerous. These semi-aquatic mammals keep cool in rivers during the day and graze at night.', '/Source/Picture/Hippo.jpg'),
(@Z, 'Cheetah', 'MAMMALS', 'Vulnerable', 'Renowned as the fastest land animal, the cheetah can reach astonishing speeds in short bursts, perfectly evolved for high-speed chases.', '/Source/Picture/cheetah.jpg'),
(@Z, 'Snow Leopard', 'MAMMALS', 'Vulnerable', 'The Snow leopard is one of the rarest big cats, adapted to the freezing, rugged mountains of Central and South Asia with its thick, smoky-gray fur.', '/Source/Picture/snowleopard.jpg'),
(@Z, 'Gray Wolf', 'MAMMALS', 'Least Concern', 'The gray wolf is a highly intelligent, pack-hunting carnivore that plays a critical role as a keystone species in maintaining the balance of its ecosystem.', '/Source/Picture/graywolf.jpg'),
(@Z, 'Grizzly Bear', 'MAMMALS', 'Least Concern', 'The grizzly bear is a formidable omnivore native to North America. Known for their immense strength, they forage heavily to build fat reserves for hibernation.', '/Source/Picture/bear.jpg'),
(@Z, 'Bald Eagle', 'BIRDS', 'Least Concern', 'The bald eagle, a symbol of freedom and strength, is a large bird of prey found near open water. They possess incredible eyesight for spotting fish.', '/Source/Picture/eagle.jpg'),
(@Z, 'Saltwater Crocodile', 'REPTILES', 'Least Concern', 'The saltwater crocodile is the largest living reptile, capable of growing over 20 feet long. They are formidable, opportunistic ambush predators.', '/Source/Picture/Crocodile.jpg'),
(@Z, 'Caribbean Flamingo', 'BIRDS', 'Least Concern', 'Famous for their stunning bright pink plumage, Caribbean flamingos are highly social birds that congregate in massive flocks.', '/Source/Picture/flamingo.jpg'),
(@Z, 'Meerkat', 'MAMMALS', 'Least Concern', 'Meerkats are small, highly social mongooses native to the deserts. They live in underground networks and are famous for their upright sentry posture.', '/Source/Picture/Meerkat.jpg');
GO
PRINT N'✅ 20 Animals từ DB cũ';
GO

-- ══════ ATTRACTIONS  ══════
DELETE FROM Attractions;
DBCC CHECKIDENT ('Attractions', RESEED, 0);
GO

DECLARE @ZA INT;
SELECT @ZA = ZoneId FROM Zones WHERE Name = 'Main Zoo Area';

INSERT INTO Attractions (ZoneId, Name, Category, Description) VALUES
(@ZA, 'Pherris Wheel', 'Ride', 'Elevate your Zoo experience to breathtaking new heights on the spectacular Pherris Wheel! This family-friendly gondola ride gently lifts you 100 feet above the canopy, offering sensational 360-degree panoramic views.'),
(@ZA, 'Flamingo Cove', 'Exhibit', 'Step into a vibrant paradise at Flamingo Cove, our breathtakingly immersive wetland aviary! Get closer than ever to a magnificent flock of spectacularly pink Caribbean and African greater flamingos.'),
(@ZA, 'Wild Explorer Virtual Reality', 'Interactive', 'Strap in for the ultimate sensory journey without ever leaving the zoo! The Wild Explorer Virtual Reality Experience utilizes state-of-the-art motion-syncing pods.'),
(@ZA, 'SEPTA PZ Express Train', 'Ride', 'All aboard for a relaxing journey on the beloved SEPTA PZ Express! This iconic scale-model locomotive winds its way along a scenic, private track.'),
(@ZA, 'Amazon Rainforest Carousel', 'Ride', 'Discover timeless magic beneath the grand canopy of the Amazon Rainforest Carousel. Choose your favorite steed from a magnificent collection of over forty hand-carved animals.'),
(@ZA, 'Wings of the World', 'Exhibit', 'Enter an enchanting tropical rainforest where dozens of vibrantly colored bird species fly completely free around you!'),
(@ZA, 'Giraffe Experience', 'Encounter', 'Prepare for a spectacular face-to-face encounter with the giants of the savanna! Step onto our elevated viewing deck to meet our towering reticulated giraffes at eye level.'),
(@ZA, 'Lemur Island', 'Encounter', 'Journey straight to the evolutionary wonders of Madagascar by walking directly through Lemur Island! Experience a barrier-free, dynamic habitat.'),
(@ZA, 'Barnyard at KidZooU', 'Contact Yard', 'Dive into hands-on agricultural fun right at the Barnyard! This interactive contact yard encourages our youngest visitors to freely mingle with friendly ambassador animals.');
GO
PRINT N'✅ 9 Attractions từ DB cũ';
GO

-- ══════ EVENTS BỔ SUNG  ══════
IF NOT EXISTS (SELECT 1 FROM Events WHERE Title LIKE '%Brew%')
    INSERT INTO Events (Title, Description, EventDate, Capacity, BasePrice, Location) VALUES
    ('Brew at the Zoo', 'Annual beer festival supporting conservation. 21+ only. Live music and local breweries.', '2026-06-20', 500, 45.00, 'Central Plaza');

IF NOT EXISTS (SELECT 1 FROM Events WHERE Title LIKE '%Keeper Talk%')
    INSERT INTO Events (Title, Description, EventDate, Capacity, BasePrice, Location) VALUES
    ('Keeper Talk Series', 'Learn from the experts! Join our keepers as they discuss daily animal care routines.', '2026-08-10', 200, 10.00, 'Education Center');

IF NOT EXISTS (SELECT 1 FROM Events WHERE Title LIKE '%Zookeeper Camp%')
    INSERT INTO Events (Title, Description, EventDate, Capacity, BasePrice, Location) VALUES
    ('Zookeeper Camp', 'A week-long immersive experience learning the daily life of professional zookeepers. Ages 10-14.', '2026-07-06', 30, 150.00, 'Camp Area');

IF NOT EXISTS (SELECT 1 FROM Events WHERE Title LIKE '%Animal Encounters Camp%')
    INSERT INTO Events (Title, Description, EventDate, Capacity, BasePrice, Location) VALUES
    ('Up-Close Animal Encounters Camp', 'Half-day experiences meeting our animal ambassadors. Ages 5-9.', '2026-07-13', 25, 150.00, 'Camp Area');
GO
PRINT N'✅ Events bổ sung từ DB cũ';
GO

-- ══════ SAMPLE ORDERS BỔ SUNG (đa dạng ngày cho revenue) ══════
DECLARE @U1 INT, @U2 INT, @U3 INT;
SELECT @U1=UserId FROM Users WHERE Username='johndoe';
SELECT @U2=UserId FROM Users WHERE Username='nguyenvana';
SELECT @U3=UserId FROM Users WHERE Username='tranthib';

DECLARE @ATT INT, @CTT INT, @STT INT;
SELECT @ATT=TicketTypeId FROM TicketTypes WHERE Name='Adult';
SELECT @CTT=TicketTypeId FROM TicketTypes WHERE Name='Child';
SELECT @STT=TicketTypeId FROM TicketTypes WHERE Name='Senior';

-- Hôm qua
IF NOT EXISTS (SELECT 1 FROM Orders WHERE TransactionRef = 'TXN-OLD-Y01')
BEGIN
    INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, OrderDate)
    VALUES (NULL, 'Ticket', 50.00, 'Cash', 'Completed', 'TXN-OLD-Y01', DATEADD(DAY,-1,GETDATE()));
    INSERT INTO OrderItems (OrderId, ItemType, ItemName, TicketTypeId, VisitDate, Quantity, UnitPrice)
    VALUES (SCOPE_IDENTITY(), 'Ticket', 'Adult Ticket', @ATT, CAST(DATEADD(DAY,-1,GETDATE()) AS DATE), 2, 25.00);

    INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, OrderDate)
    VALUES (NULL, 'Ticket', 30.00, 'Online', 'Completed', 'TXN-OLD-Y02', DATEADD(DAY,-1,GETDATE()));
    INSERT INTO OrderItems (OrderId, ItemType, ItemName, TicketTypeId, VisitDate, Quantity, UnitPrice)
    VALUES (SCOPE_IDENTITY(), 'Ticket', 'Child Ticket', @CTT, CAST(DATEADD(DAY,-1,GETDATE()) AS DATE), 3, 10.00);
END

-- Tuần trước
IF NOT EXISTS (SELECT 1 FROM Orders WHERE TransactionRef = 'TXN-OLD-W01')
BEGIN
    INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, OrderDate)
    VALUES (@U2, 'Ticket', 60.00, 'Online', 'Completed', 'TXN-OLD-W01', DATEADD(DAY,-7,GETDATE()));
    INSERT INTO OrderItems (OrderId, ItemType, ItemName, TicketTypeId, VisitDate, Quantity, UnitPrice)
    VALUES (SCOPE_IDENTITY(), 'Ticket', 'Adult Ticket', @ATT, CAST(DATEADD(DAY,-7,GETDATE()) AS DATE), 4, 15.00);
END

-- Tháng trước 
IF NOT EXISTS (SELECT 1 FROM Orders WHERE TransactionRef = 'TXN-OLD-M01')
BEGIN
    INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, OrderDate)
    VALUES (NULL, 'Ticket', 75.00, 'Online', 'Completed', 'TXN-OLD-M01', DATEADD(MONTH,-1,GETDATE()));
    INSERT INTO OrderItems (OrderId, ItemType, ItemName, TicketTypeId, VisitDate, Quantity, UnitPrice)
    VALUES (SCOPE_IDENTITY(), 'Ticket', 'Adult Ticket', @ATT, CAST(DATEADD(MONTH,-1,GETDATE()) AS DATE), 5, 15.00);

    INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, OrderDate)
    VALUES (@U3, 'Ticket', 24.00, 'Card', 'Completed', 'TXN-OLD-M02', DATEADD(MONTH,-1,GETDATE()));
    INSERT INTO OrderItems (OrderId, ItemType, ItemName, TicketTypeId, VisitDate, Quantity, UnitPrice)
    VALUES (SCOPE_IDENTITY(), 'Ticket', 'Senior Ticket', @STT, CAST(DATEADD(MONTH,-1,GETDATE()) AS DATE), 2, 12.00);
END

-- Event orders
IF NOT EXISTS (SELECT 1 FROM Orders WHERE TransactionRef = 'TXN-OLD-E01')
BEGIN
    DECLARE @BrewEvt INT; SELECT @BrewEvt=EventId FROM Events WHERE Title LIKE '%Brew%';
    IF @BrewEvt IS NOT NULL
    BEGIN
        INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef)
        VALUES (@U1, 'Event', 90.00, 'Card', 'Completed', 'TXN-OLD-E01');
        INSERT INTO OrderItems (OrderId, ItemType, ItemName, EventId, VisitDate, Quantity, UnitPrice)
        VALUES (SCOPE_IDENTITY(), 'Event', 'Brew at the Zoo', @BrewEvt, '2026-06-20', 2, 45.00);
    END
END
GO
