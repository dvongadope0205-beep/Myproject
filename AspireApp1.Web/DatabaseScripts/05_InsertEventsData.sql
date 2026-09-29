USE [ZooDatabase]
GO

-- Xóa dữ liệu cũ nếu có bị trùng lặp trong khâu testing
-- (Chỉ an toàn cho bước phát triển, không dùng trên Prod)
DELETE FROM Events;
DBCC CHECKIDENT ('Events', RESEED, 0);

-- Nhập dữ liệu Sự kiện đặc biệt (Special Events & Camps)
INSERT INTO Events (Title, Description, EventDate, Capacity, BasePrice)
VALUES 
('🌟 Spring Break Safari Event', 'Special access bundle including standard admission, unlimited zoo train rides, and a souvenir cup. Available for limited dates only.', '2026-03-25', 100, 35.00),
('🌟 ZooLights Winter Festival', 'See the zoo transformed into a winter wonderland with over a million glowing LEDs. Hot cocoa and treats available!', '2026-11-15', 500, 25.00),
('🌟 Annual Conservation Gala', 'A black-tie evening to raise funds for our global wildlife protection initiatives. Dinner and auction included.', '2026-10-12', 200, 250.00),
('🏕️ Zookeeper Camp Ticket', 'A week-long immersive experience learning the daily life of professional zookeepers. Ages 10-14', '2026-07-06', 30, 150.00),
('🏕️ Up-Close Animal Encounters Camp', 'Half-day experiences meeting our animal ambassadors. Ages 5-9', '2026-07-13', 25, 150.00),
('🏕️ Themed Ecosystem Camp', 'Immersive week exploring bio-zones across the zoo property. Ages 8-12', '2026-07-20', 25, 150.00),
('🏕️ Conservation Action Camp', 'Learn advanced ecological concepts and design eco-campaigns. Ages 12-16', '2026-07-27', 20, 150.00);

GO
