-- Cập nhật ImagePath cho sản phẩm shop (DB đã seed trước khi có cột / giá trị rỗng).
-- Chạy một lần trên SQL Server nếu ảnh trong DB vẫn NULL.

UPDATE ShopProducts SET ImagePath = '/Source/Picture/animal-giraffe.jpg' WHERE Name = N'Plush Giraffe' AND (ImagePath IS NULL OR LTRIM(RTRIM(ImagePath)) = N'');
UPDATE ShopProducts SET ImagePath = '/Source/Picture/animal-lion.jpg' WHERE Name = N'Plush Lion' AND (ImagePath IS NULL OR LTRIM(RTRIM(ImagePath)) = N'');
UPDATE ShopProducts SET ImagePath = '/Source/Picture/animal-elephant.jpg' WHERE Name = N'Plush Elephant' AND (ImagePath IS NULL OR LTRIM(RTRIM(ImagePath)) = N'');
UPDATE ShopProducts SET ImagePath = '/Source/Picture/animal-tiger.jpg' WHERE Name = N'Conservation T-Shirt' AND (ImagePath IS NULL OR LTRIM(RTRIM(ImagePath)) = N'');
UPDATE ShopProducts SET ImagePath = '/Source/Picture/animal-tiger.jpg' WHERE Name = N'Safari Cap' AND (ImagePath IS NULL OR LTRIM(RTRIM(ImagePath)) = N'');
UPDATE ShopProducts SET ImagePath = '/Source/Picture/animal-tiger.jpg' WHERE Name = N'Kids Animal Hoodie' AND (ImagePath IS NULL OR LTRIM(RTRIM(ImagePath)) = N'');
UPDATE ShopProducts SET ImagePath = '/Source/Picture/animal-polarbear.jpg' WHERE Name = N'Zoo Mug - Lion' AND (ImagePath IS NULL OR LTRIM(RTRIM(ImagePath)) = N'');
UPDATE ShopProducts SET ImagePath = '/Source/Picture/animal-orangutan.jpg' WHERE Name = N'Animal Keychain Set' AND (ImagePath IS NULL OR LTRIM(RTRIM(ImagePath)) = N'');
UPDATE ShopProducts SET ImagePath = '/Source/Picture/animal-penguin.jpg' WHERE Name = N'Animal Encyclopedia' AND (ImagePath IS NULL OR LTRIM(RTRIM(ImagePath)) = N'');
UPDATE ShopProducts SET ImagePath = '/Source/Picture/animal-penguin.jpg' WHERE Name = N'Kids Activity Book' AND (ImagePath IS NULL OR LTRIM(RTRIM(ImagePath)) = N'');
UPDATE ShopProducts SET ImagePath = '/Source/Picture/animal-koala.jpg' WHERE Name = N'Zoo Magnet Collection' AND (ImagePath IS NULL OR LTRIM(RTRIM(ImagePath)) = N'');
UPDATE ShopProducts SET ImagePath = '/Source/Picture/animal-snake.jpg' WHERE Name = N'Bamboo Water Bottle' AND (ImagePath IS NULL OR LTRIM(RTRIM(ImagePath)) = N'');

PRINT N'Đã cập nhật ImagePath cho ShopProducts (nếu đang trống).';
