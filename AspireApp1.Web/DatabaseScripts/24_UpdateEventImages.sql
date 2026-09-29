-- ============================================================
-- 24_UpdateEventImages.sql
-- Cập nhật ImagePath cho tất cả Events
-- Sử dụng ảnh từ /Source/General/ (mỗi event 1 ảnh riêng biệt)
-- ============================================================

USE [ZooDatabase]
GO

-- Event: Night Safari → 8.jpg (gia đình xem voi - phù hợp night safari)
UPDATE Events SET ImagePath = '/Source/General/8.jpg'
WHERE Title LIKE '%Night Safari%';

-- Event: Brew at the Zoo → 7.jpg (keeper với lemur)
UPDATE Events SET ImagePath = '/Source/General/7.jpg'
WHERE Title LIKE '%Brew%Zoo%' OR Title LIKE '%Brew at%';

-- Event: ZooLights Festival → 15.jpg (lung linh ánh sáng)
UPDATE Events SET ImagePath = '/Source/General/15.jpg'
WHERE Title LIKE '%ZooLights%';

-- Event: Conservation Gala → 13.jpg (sư tử trong chuồng - sang trọng)
UPDATE Events SET ImagePath = '/Source/General/13.jpg'
WHERE Title LIKE '%Conservation Gala%';

-- Event: Ecosystem Exploration → 2.jpg (hươu cao cổ & ngựa vằn - hệ sinh thái)
UPDATE Events SET ImagePath = '/Source/General/2.jpg'
WHERE Title LIKE '%Ecosystem%';

-- Event: Wildlife Action Day → 6.jpg (gia đình cho hươu ăn)
UPDATE Events SET ImagePath = '/Source/General/6.jpg'
WHERE Title LIKE '%Wildlife Action%';

-- Event: Zookeeper Camp → 11.jpg (keeper cho kangaroo ăn)
UPDATE Events SET ImagePath = '/Source/General/11.jpg'
WHERE Title LIKE '%Zookeeper Camp%';

-- Event: Up-Close Animal Encounters Camp → 9.jpg (mẹ con cho hươu ăn)
UPDATE Events SET ImagePath = '/Source/General/9.jpg'
WHERE Title LIKE '%Up-Close Animal%';

-- Event: Themed Ecosystem Camp → 4.jpg (bé xem báo)
UPDATE Events SET ImagePath = '/Source/General/4.jpg'
WHERE Title LIKE '%Themed Ecosystem%';

-- Event: Conservation Action Camp → 3.jpg (bé với bướm - thiên nhiên)
UPDATE Events SET ImagePath = '/Source/General/3.jpg'
WHERE Title LIKE '%Conservation Action%';

-- Event: Keeper Talk Series → 12.jpg (keeper cho kangaroo ăn - hướng dẫn viên)
UPDATE Events SET ImagePath = '/Source/General/12.jpg'
WHERE Title LIKE '%Keeper Talk%';

-- Event: Spring Break Safari → 14.jpg (bé cho dê ăn)
UPDATE Events SET ImagePath = '/Source/General/14.jpg'
WHERE Title LIKE '%Spring Break Safari%';

GO

PRINT N'════════════════════════════════════════';
PRINT N'✅ 24_UpdateEventImages.sql HOÀN TẤT';
PRINT N'   Đã cập nhật ImagePath cho tất cả Events';
PRINT N'   Sử dụng ảnh từ /Source/General/';
PRINT N'════════════════════════════════════════';
GO
