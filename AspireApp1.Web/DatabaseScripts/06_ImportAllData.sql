USE [ZooDatabase]
GO

-- 1. Ensure a default Zone exists for migrated data
IF NOT EXISTS (SELECT 1 FROM Zones WHERE ZoneId = 1)
BEGIN
    SET IDENTITY_INSERT Zones ON;
    INSERT INTO Zones (ZoneId, Name, Description) VALUES (1, 'Main Zoo Area', 'Default area for migrated records');
    SET IDENTITY_INSERT Zones OFF;
END
GO

-- 2. Clear out older migration data to avoid duplicates if testing
DELETE FROM Animals;
DBCC CHECKIDENT ('Animals', RESEED, 0);

DELETE FROM Attractions;
DBCC CHECKIDENT ('Attractions', RESEED, 0);

-- 3. Populate Animals Table (from animal.js)
INSERT INTO Animals (ZoneId, Name, Species, ConservationStatus, Description, ImagePath) VALUES
(1, 'African Lion', 'MAMMALS', 'Vulnerable', 'The African lion is a majestic apex predator known for its impressive mane and powerful roar. Living in highly social family units called prides, they dominate the savanna ecosystem.', '/Source/Picture/lionn.jpg'),
(1, 'Bengal Tiger', 'MAMMALS', 'Endangered', 'Native to the Indian subcontinent, the Bengal tiger is characterized by its striking orange coat and dark stripes. As solitary hunters, they rely on stealth and power.', '/Source/Picture/bengaltiger.jpg'),
(1, 'Asian Elephant', 'MAMMALS', 'Endangered', 'The Asian elephant is a highly intelligent and social creature. They play a vital role in maintaining the forest ecosystem by dispersing seeds.', '/Source/Picture/elephant2.jpg'),
(1, 'Reticulated Giraffe', 'MAMMALS', 'Vulnerable', 'Recognized by its distinct polygonal spots, the giraffe is the tallest land mammal on Earth. Their incredibly long necks allow them to reach nutrient-rich leaves.', '/Source/Picture/giraffe1.jpg'),
(1, 'Giant Panda', 'MAMMALS', 'Vulnerable', 'Endemic to the mountainous regions of China, the giant panda is a global symbol for wildlife conservation. Their diet consists almost entirely of bamboo.', '/Source/Picture/panda.jpg'),
(1, 'Plains Zebra', 'MAMMALS', 'Near Threatened', 'The plains zebra is iconic for its dazzling black-and-white striped coat, which acts as a natural camouflage against predators across the plains.', '/Source/Picture/zebra.jpg'),
(1, 'Silverback Gorilla', 'PRIMATES', 'Critically Endangered', 'Silverback gorillas are the large, dominant males that lead troops of these peaceful primates in the dense forests of central Africa.', '/Source/Picture/gorilla.jpg'),
(1, 'Emperor Penguin', 'BIRDS', 'Near Threatened', 'Endemic to Antarctica, the Emperor penguin is the tallest and heaviest of all living penguin species, enduring the harshest winters on the planet to breed.', '/Source/Picture/penguin1.jpg'),
(1, 'Red Kangaroo', 'MARSUPIALS', 'Least Concern', 'The red kangaroo is the largest terrestrial mammal native to Australia. Adapted to the arid outback, they can travel vast distances at high speeds.', '/Source/Picture/kangaroo.jpg'),
(1, 'Koala Bear', 'MARSUPIALS', 'Vulnerable', 'Often mistakenly called a bear, the koala is a marsupial strictly native to Australia. They spend almost their entire lives in the canopies of eucalyptus trees.', '/Source/Picture/koala.jpg'),
(1, 'White Rhinoceros', 'MAMMALS', 'Near Threatened', 'The white rhinoceros is a massive, heavily armored herbivore native to southern Africa. They have a wide, square lip perfectly adapted for grazing.', '/Source/Picture/Rhino.jpg'),
(1, 'Hippopotamus', 'MAMMALS', 'Vulnerable', 'Despite their bulky appearance, hippos are highly dangerous. These semi-aquatic mammals keep cool in rivers during the day and graze at night.', '/Source/Picture/Hippo.jpg'),
(1, 'Cheetah', 'MAMMALS', 'Vulnerable', 'Renowned as the fastest land animal, the cheetah can reach astonishing speeds in short bursts, perfectly evolved for high-speed chases.', '/Source/Picture/cheetah.jpg'),
(1, 'Snow Leopard', 'MAMMALS', 'Vulnerable', 'The Snow leopard is one of the rarest big cats, adapted to the freezing, rugged mountains of Central and South Asia with its thick, smoky-gray fur.', '/Source/Picture/snowleopard.jpg'),
(1, 'Gray Wolf', 'MAMMALS', 'Least Concern', 'The gray wolf is a highly intelligent, pack-hunting carnivore that plays a critical role as a keystone species in maintaining the balance of its ecosystem.', '/Source/Picture/graywolf.jpg'),
(1, 'Grizzly Bear', 'MAMMALS', 'Least Concern', 'The grizzly bear is a formidable omnivore native to North America. Known for their immense strength, they forage heavily to build fat reserves for hibernation.', '/Source/Picture/bear.jpg'),
(1, 'Bald Eagle', 'BIRDS', 'Least Concern', 'The bald eagle, a symbol of freedom and strength, is a large bird of prey found near open water. They possess incredible eyesight for spotting fish.', '/Source/Picture/eagle.jpg'),
(1, 'Saltwater Crocodile', 'REPTILES', 'Least Concern', 'The saltwater crocodile is the largest living reptile, capable of growing over 20 feet long. They are formidable, opportunistic ambush predators.', '/Source/Picture/Crocodile.jpg'),
(1, 'Caribbean Flamingo', 'BIRDS', 'Least Concern', 'Famous for their stunning bright pink plumage, Caribbean flamingos are highly social birds that congregate in massive flocks.', '/Source/Picture/flamingo.jpg'),
(1, 'Meerkat', 'MAMMALS', 'Least Concern', 'Meerkats are small, highly social mongooses native to the deserts. They live in underground networks and are famous for their upright ''sentry'' posture.', '/Source/Picture/Meerkat.jpg');

-- 4. Populate Attractions Table (from Attractions.cshtml)
INSERT INTO Attractions (ZoneId, Name, Category, Description) VALUES
(1, 'Pherris Wheel', 'Ride', 'Elevate your Zoo experience to breathtaking new heights on the spectacular Pherris Wheel! This family-friendly gondola ride gently lifts you 100 feet above the canopy, offering sensational 360-degree panoramic views.'),
(1, 'Flamingo Cove', 'Exhibit', 'Step into a vibrant paradise at Flamingo Cove, our breathtakingly immersive wetland aviary! Get closer than ever to a magnificent flock of spectacularly pink Caribbean and African greater flamingos.'),
(1, 'Wild Explorer Virtual Reality', 'Interactive', 'Strap in for the ultimate sensory journey without ever leaving the zoo! The Wild Explorer Virtual Reality Experience utilizes state-of-the-art motion-syncing pods to transport you into the deepest oceans.'),
(1, 'SEPTA PZ Express Train', 'Ride', 'All aboard for a relaxing journey on the beloved SEPTA PZ Express! This iconic scale-model locomotive winds its way along a scenic, private track.'),
(1, 'Amazon Rainforest Carousel', 'Ride', 'Discover timeless magic beneath the grand canopy of the Amazon Rainforest Carousel. Choose your favorite steed from a magnificent collection of over forty meticulously hand-carved animals.'),
(1, 'Wings of the World', 'Exhibit', 'Enter an enchanting tropical rainforest where dozens of vibrantly colored bird species fly completely free around you! Walk along winding footpaths through dense jungle foliage.'),
(1, 'Giraffe Experience', 'Encounter', 'Prepare for a spectacular face-to-face encounter with the undisputed giants of the savanna! Step onto our elevated viewing deck to meet our towering reticulated giraffes right at eye level.'),
(1, 'Lemur Island', 'Encounter', 'Journey straight to the evolutionary wonders of Madagascar by walking directly through Lemur Island! Experience a barrier-free, dynamic habitat where charismatic ring-tailed lemurs leap gracefully.'),
(1, 'Barnyard at KidZooU', 'Contact Yard', 'Dive into hands-on agricultural fun right at the Barnyard! This bustling, interactive contact yard encourages our youngest visitors to freely mingle with friendly ambassador animals.');

-- 5. Add any generic missing Events
IF NOT EXISTS (SELECT 1 FROM Events WHERE Title LIKE '%Brew%')
BEGIN
    INSERT INTO Events (Title, Description, EventDate, Capacity, BasePrice)
    VALUES ('Brew at the Zoo', 'Join us for our annual beer festival supporting conservation. 21+ only. Live music and local breweries.', '2026-06-20', 500, 45.00);
END

IF NOT EXISTS (SELECT 1 FROM Events WHERE Title LIKE '%Keeper Talk%')
BEGIN
    INSERT INTO Events (Title, Description, EventDate, Capacity, BasePrice)
    VALUES ('Keeper Talk Series', 'Learn straight from the experts! Join our specialized keepers as they discuss daily animal care routines.', '2026-08-10', 200, 10.00);
END

GO
