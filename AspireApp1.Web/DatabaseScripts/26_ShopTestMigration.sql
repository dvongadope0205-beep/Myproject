-- ============================================================
-- 26_ShopTestMigration.sql
-- Migrate database to match new Shoptest product catalog
-- Run AFTER deploying the new Shop pages
-- ============================================================

USE [ZooDatabase]
GO

-- ============================================================
-- STEP 1: Update ShopCategories to match Shoptest collections
-- ============================================================

-- Deactivate old categories
UPDATE ShopCategories SET IsActive = 0 WHERE IsActive = 1;

-- Insert new categories matching Shoptest
IF NOT EXISTS (SELECT 1 FROM ShopCategories WHERE Name = 'New')
    INSERT INTO ShopCategories (Name, IconClass, SortOrder, IsActive) VALUES ('New', 'fa-star', 1, 1);
ELSE
    UPDATE ShopCategories SET IconClass = 'fa-star', SortOrder = 1, IsActive = 1 WHERE Name = 'New';

IF NOT EXISTS (SELECT 1 FROM ShopCategories WHERE Name = 'Apparel')
    INSERT INTO ShopCategories (Name, IconClass, SortOrder, IsActive) VALUES ('Apparel', 'fa-tshirt', 2, 1);
ELSE
    UPDATE ShopCategories SET IconClass = 'fa-tshirt', SortOrder = 2, IsActive = 1 WHERE Name = 'Apparel';

IF NOT EXISTS (SELECT 1 FROM ShopCategories WHERE Name = 'Plush')
    INSERT INTO ShopCategories (Name, IconClass, SortOrder, IsActive) VALUES ('Plush', 'fa-heart', 3, 1);
ELSE
    UPDATE ShopCategories SET IconClass = 'fa-heart', SortOrder = 3, IsActive = 1 WHERE Name = 'Plush';

IF NOT EXISTS (SELECT 1 FROM ShopCategories WHERE Name = 'Accessories')
    INSERT INTO ShopCategories (Name, IconClass, SortOrder, IsActive) VALUES ('Accessories', 'fa-gem', 4, 1);
ELSE
    UPDATE ShopCategories SET IconClass = 'fa-gem', SortOrder = 4, IsActive = 1 WHERE Name = 'Accessories';

IF NOT EXISTS (SELECT 1 FROM ShopCategories WHERE Name = 'Bundles')
    INSERT INTO ShopCategories (Name, IconClass, SortOrder, IsActive) VALUES ('Bundles', 'fa-box-open', 5, 1);
ELSE
    UPDATE ShopCategories SET IconClass = 'fa-box-open', SortOrder = 5, IsActive = 1 WHERE Name = 'Bundles';

IF NOT EXISTS (SELECT 1 FROM ShopCategories WHERE Name = 'Gift Cards')
    INSERT INTO ShopCategories (Name, IconClass, SortOrder, IsActive) VALUES ('Gift Cards', 'fa-gift', 6, 1);
ELSE
    UPDATE ShopCategories SET IconClass = 'fa-gift', SortOrder = 6, IsActive = 1 WHERE Name = 'Gift Cards';

IF NOT EXISTS (SELECT 1 FROM ShopCategories WHERE Name = 'Games')
    INSERT INTO ShopCategories (Name, IconClass, SortOrder, IsActive) VALUES ('Games', 'fa-gamepad', 7, 1);
ELSE
    UPDATE ShopCategories SET IconClass = 'fa-gamepad', SortOrder = 7, IsActive = 1 WHERE Name = 'Games';

IF NOT EXISTS (SELECT 1 FROM ShopCategories WHERE Name = 'Stationery')
    INSERT INTO ShopCategories (Name, IconClass, SortOrder, IsActive) VALUES ('Stationery', 'fa-pencil-alt', 8, 1);
ELSE
    UPDATE ShopCategories SET IconClass = 'fa-pencil-alt', SortOrder = 8, IsActive = 1 WHERE Name = 'Stationery';

-- ============================================================
-- STEP 2: Add new columns to ShopProducts if needed
-- ============================================================

-- Add Slug column for URL-friendly product names
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ShopProducts' AND COLUMN_NAME = 'Slug')
    ALTER TABLE ShopProducts ADD Slug NVARCHAR(200) NULL;

-- Add OriginalPrice for sale display
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ShopProducts' AND COLUMN_NAME = 'OriginalPrice')
    ALTER TABLE ShopProducts ADD OriginalPrice DECIMAL(18,2) NULL;

-- Add ThumbnailPath for hover images
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ShopProducts' AND COLUMN_NAME = 'ThumbnailPath')
    ALTER TABLE ShopProducts ADD ThumbnailPath NVARCHAR(500) NULL;

-- Add HoverImagePath for second image on hover
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ShopProducts' AND COLUMN_NAME = 'HoverImagePath')
    ALTER TABLE ShopProducts ADD HoverImagePath NVARCHAR(500) NULL;

-- Add PageSlug for linking to individual product Razor Pages
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ShopProducts' AND COLUMN_NAME = 'PageSlug')
    ALTER TABLE ShopProducts ADD PageSlug NVARCHAR(200) NULL;
GO

-- ============================================================
-- STEP 3: Deactivate old products and insert Shoptest products
-- ============================================================

-- Deactivate all old products
UPDATE ShopProducts SET IsActive = 0 WHERE IsActive = 1;

-- Declare category IDs
DECLARE @CatNew INT = (SELECT CategoryId FROM ShopCategories WHERE Name = 'New');
DECLARE @CatApparel INT = (SELECT CategoryId FROM ShopCategories WHERE Name = 'Apparel');
DECLARE @CatPlush INT = (SELECT CategoryId FROM ShopCategories WHERE Name = 'Plush');
DECLARE @CatAccessories INT = (SELECT CategoryId FROM ShopCategories WHERE Name = 'Accessories');
DECLARE @CatBundles INT = (SELECT CategoryId FROM ShopCategories WHERE Name = 'Bundles');
DECLARE @CatGiftCards INT = (SELECT CategoryId FROM ShopCategories WHERE Name = 'Gift Cards');
DECLARE @CatGames INT = (SELECT CategoryId FROM ShopCategories WHERE Name = 'Games');
DECLARE @CatStationery INT = (SELECT CategoryId FROM ShopCategories WHERE Name = 'Stationery');

-- ── PLUSH PRODUCTS ──
INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, IsActive, ImagePath, Slug, OriginalPrice, PageSlug)
VALUES
(@CatPlush, N'Batrick Plush With Sunglasses And Hawaiian Shirt', N'Adorable Batrick plush toy with sunglasses and hawaiian shirt', 21.00, 100, 1, N'/Source/shop-img/plush/batrick hawaiin/thumbnail/batrick-hawaiin-thumbnail-1.png', N'batrick-plush', 27.00, N'BatrickPlush'),
(@CatPlush, N'Kevin the Otter Plush with Magnetic Rocks & Seashell', N'Kevin the otter plush with magnetic accessories', 23.00, 100, 1, N'/Source/shop-img/Bundle/Spring Magnetic Plush Bundle/Kevin/thumbnail/Kevin-1.png', N'kevin-plush', 29.00, N'KevinPlush'),
(@CatPlush, N'Emily The Axolotl Plush With Detachable Limbs & Tail', N'Emily the axolotl plush with detachable parts', 23.00, 100, 1, N'/Source/shop-img/Bundle/Spring Magnetic Plush Bundle/Emily/thumbnail/emily-1.png', N'emily-plush', 29.00, N'EmilyPlush'),
(@CatPlush, N'Talking Mouth Plush', N'Interactive talking mouth plush toy', 24.00, 100, 1, N'/Source/shop-img/Bundle/Talking Mouth & Screaming Albie Plush Bundle/Mouth/thumbnail/mouth1.png', N'mouth-plush', 30.00, N'MouthPlush'),
(@CatPlush, N'Lisa Plush With Balloon', N'Lisa plush toy with balloon accessory', 23.00, 100, 1, N'/Source/shop-img/plush/Lisa/thumbnail/Lisa-1.png', N'lisa-plush', 29.00, N'LisaPlush'),
(@CatPlush, N'Albie Plush', N'Classic Albie plush toy', 23.00, 100, 1, N'/Source/shop-img/plush/Lisa/thumbnail/Lisa-1.png', N'albie-plush', 29.00, N'AlbiePlush'),
(@CatPlush, N'Jason Plush', N'Jason character plush toy', 23.00, 100, 1, N'/Source/shop-img/plush/Lisa/thumbnail/Lisa-1.png', N'jason-plush', 29.00, N'JasonPlush'),
(@CatPlush, N'Chris Plush', N'Chris character plush toy', 23.00, 100, 1, N'/Source/shop-img/plush/Lisa/thumbnail/Lisa-1.png', N'chris-plush', 29.00, N'ChrisPlush'),
(@CatPlush, N'Robert Plush', N'Robert character plush toy', 23.00, 100, 1, N'/Source/shop-img/plush/Lisa/thumbnail/Lisa-1.png', N'robert-plush', 29.00, N'RobertPlush'),
(@CatPlush, N'Bro Plush', N'Bro character plush toy', 23.00, 100, 1, N'/Source/shop-img/plush/Lisa/thumbnail/Lisa-1.png', N'bro-plush', 29.00, N'BroPlush');

-- ── APPAREL PRODUCTS ──
INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, IsActive, ImagePath, Slug, OriginalPrice, PageSlug)
VALUES
(@CatApparel, N'Batrick Crewneck', N'Batrick themed crewneck sweatshirt', 35.00, 100, 1, N'/Source/shop-img/Apparel/batrick crewneck/thumbnail/batrickcrewneck1.jpg', N'batrick-crewneck', 45.00, N'BatrickCrewneck'),
(@CatApparel, N'Batrick Hoodie', N'Batrick themed hoodie', 40.00, 100, 1, N'/Source/shop-img/Apparel/batrick crewneck/thumbnail/batrickcrewneck1.jpg', N'batrick-hoodie', 50.00, N'BatrickHoodie'),
(@CatApparel, N'Batrick Tee', N'Batrick themed t-shirt', 21.00, 100, 1, N'/Source/shop-img/Apparel/batrick crewneck/thumbnail/batrickcrewneck1.jpg', N'batrick-tee', 26.00, N'BatrickTee'),
(@CatApparel, N'Axolotl Tee', N'Axolotl themed t-shirt', 21.00, 100, 1, N'/Source/shop-img/Apparel/batrick crewneck/thumbnail/batrickcrewneck1.jpg', N'axolotl-tee', 26.00, N'AxolotlTee'),
(@CatApparel, N'Lisa Tee', N'Lisa character themed t-shirt', 21.00, 100, 1, N'/Source/shop-img/Apparel/batrick crewneck/thumbnail/batrickcrewneck1.jpg', N'lisa-tee', 26.00, N'LisaTee'),
(@CatApparel, N'Robert''s Pancake Tee', N'Robert themed pancake t-shirt', 21.00, 100, 1, N'/Source/shop-img/Apparel/robert t/thumbnail/roberttee1.jpg', N'robert-tee', 26.00, N'RobertTee'),
(@CatApparel, N'NH Tee', N'Natural Habitat classic t-shirt', 21.00, 100, 1, N'/Source/shop-img/Apparel/robert t/thumbnail/roberttee1.jpg', N'nh-tee', 26.00, N'NHTee'),
(@CatApparel, N'NH Fall Hoodie', N'Natural Habitat fall collection hoodie', 45.00, 100, 1, N'/Source/shop-img/Apparel/robert t/thumbnail/roberttee1.jpg', N'nh-fall-hoodie', 55.00, N'NHFallHoodie'),
(@CatApparel, N'NH Lineart Hoodie', N'Natural Habitat lineart hoodie', 40.00, 100, 1, N'/Source/shop-img/Apparel/robert t/thumbnail/roberttee1.jpg', N'nh-lineart-hoodie', 50.00, N'NHLineartHoodie'),
(@CatApparel, N'Summer Hoodie', N'Summer collection hoodie', 40.00, 100, 1, N'/Source/shop-img/Apparel/robert t/thumbnail/roberttee1.jpg', N'summer-hoodie', 50.00, N'SummerHoodie'),
(@CatApparel, N'Kevin Backpack', N'Kevin themed backpack', 35.00, 100, 1, N'/Source/shop-img/Apparel/robert t/thumbnail/roberttee1.jpg', N'kevin-backpack', 45.00, N'KevinBackpack'),
(@CatApparel, N'Summer Tote Bag', N'Summer collection tote bag', 18.00, 100, 1, N'/Source/shop-img/Apparel/robert t/thumbnail/roberttee1.jpg', N'summer-tote-bag', 22.00, N'SummerToteBag');

-- ── ACCESSORIES / STATIONERY ──
INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, IsActive, ImagePath, Slug, OriginalPrice, PageSlug)
VALUES
(@CatAccessories, N'Albie Pin', N'Collectible Albie enamel pin', 8.00, 200, 1, N'/Source/shop-img/Accessory/Albie pin/thumbnail/albie-pin1.png', N'albie-pin', 10.00, N'AlbiePin'),
(@CatAccessories, N'Ashley Pin', N'Collectible Ashley enamel pin', 8.00, 200, 1, N'/Source/shop-img/Accessory/Albie pin/thumbnail/albie-pin1.png', N'ashley-pin', 10.00, N'AshleyPin'),
(@CatAccessories, N'Jason Pin', N'Collectible Jason enamel pin', 8.00, 200, 1, N'/Source/shop-img/Accessory/Albie pin/thumbnail/albie-pin1.png', N'jason-pin', 10.00, N'JasonPin'),
(@CatAccessories, N'Kevin Pin', N'Collectible Kevin enamel pin', 8.00, 200, 1, N'/Source/shop-img/Accessory/Albie pin/thumbnail/albie-pin1.png', N'kevin-pin', 10.00, N'KevinPin'),
(@CatAccessories, N'Lisa Pin', N'Collectible Lisa enamel pin', 8.00, 200, 1, N'/Source/shop-img/Accessory/Albie pin/thumbnail/albie-pin1.png', N'lisa-pin', 10.00, N'LisaPin'),
(@CatAccessories, N'Lizard Pin', N'Collectible Lizard enamel pin', 8.00, 200, 1, N'/Source/shop-img/Accessory/Albie pin/thumbnail/albie-pin1.png', N'lizard-pin', 10.00, N'LizardPin');

INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, IsActive, ImagePath, Slug, OriginalPrice, PageSlug)
VALUES
(@CatStationery, N'NH Notebook', N'Natural Habitat notebook', 12.00, 150, 1, N'/Source/shop-img/stationery/Spring sticker pack/thumbnail/spring-ticket-pack-1.png', N'nh-notebook', 15.00, N'NHNotebook'),
(@CatStationery, N'NH Sticker', N'Natural Habitat sticker pack', 8.00, 200, 1, N'/Source/shop-img/stationery/Spring sticker pack/thumbnail/spring-ticket-pack-1.png', N'nh-sticker', 9.00, N'NHSticker'),
(@CatStationery, N'Holiday Sticker', N'Holiday collection sticker pack', 8.00, 200, 1, N'/Source/shop-img/stationery/Spring sticker pack/thumbnail/spring-ticket-pack-1.png', N'holiday-sticker', 9.00, N'HolidaySticker'),
(@CatStationery, N'Spring Sticker Pack', N'Spring collection sticker pack', 8.00, 200, 1, N'/Source/shop-img/stationery/Spring sticker pack/thumbnail/spring-ticket-pack-1.png', N'spring-sticker', 9.00, N'SpringSticker'),
(@CatStationery, N'Summer Sticker Pack', N'Summer collection sticker pack', 8.00, 200, 1, N'/Source/shop-img/stationery/Spring sticker pack/thumbnail/spring-ticket-pack-1.png', N'summer-sticker', 9.00, N'SummerSticker'),
(@CatStationery, N'Lineart Print', N'Natural Habitat lineart art print', 15.00, 100, 1, N'/Source/shop-img/stationery/Spring sticker pack/thumbnail/spring-ticket-pack-1.png', N'lineart', 18.00, N'Lineart');

-- ── BUNDLES ──
INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, IsActive, ImagePath, Slug, OriginalPrice, PageSlug)
VALUES
(@CatBundles, N'Spring Magnetic Plush Bundle', N'Bundle of spring magnetic plush toys', 55.00, 50, 1, N'/Source/shop-img/Bundle/Spring Magnetic Plush Bundle/Kevin/thumbnail/Kevin-1.png', N'spring-magnetic-plush', 70.00, N'SpringMagneticPlush'),
(@CatBundles, N'Talking Mouth & Screaming Albie Bundle', N'Bundle with talking mouth and screaming Albie', 45.00, 50, 1, N'/Source/shop-img/Bundle/Talking Mouth & Screaming Albie Plush Bundle/Mouth/thumbnail/mouth1.png', N'mouth-albie-bundle', 58.00, N'MouthAlbieBundle'),
(@CatBundles, N'Robert & Bro Bundle', N'Bundle with Robert and Bro plush', 40.00, 50, 1, N'/Source/shop-img/plush/Lisa/thumbnail/Lisa-1.png', N'robert-bro-bundle', 52.00, N'RobertBroBundle');

-- ── GAMES ──
INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, IsActive, ImagePath, Slug, OriginalPrice, PageSlug)
VALUES
(@CatGames, N'Natural Habitat Board Game', N'The official Natural Habitat board game', 30.00, 75, 1, N'/Source/shop-img/game/thumbnail/game1.png', N'board-game', 35.00, N'BoardGame');

-- ── GIFT CARDS ──
INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, IsActive, ImagePath, Slug, OriginalPrice, PageSlug)
VALUES
(@CatGiftCards, N'Gift Card - £25', N'Natural Habitat £25 digital gift card', 25.00, 999, 1, N'/Source/shop-img/gift card/thumbnail/giftcard1.png', N'gift-card-25', NULL, N'GiftCards'),
(@CatGiftCards, N'Gift Card - £50', N'Natural Habitat £50 digital gift card', 50.00, 999, 1, N'/Source/shop-img/gift card/thumbnail/giftcard1.png', N'gift-card-50', NULL, N'GiftCards'),
(@CatGiftCards, N'Gift Card - £100', N'Natural Habitat £100 digital gift card', 100.00, 999, 1, N'/Source/shop-img/gift card/thumbnail/giftcard1.png', N'gift-card-100', NULL, N'GiftCards');

PRINT N'✅ ShopTest Migration completed: Categories updated, Products inserted.';
GO
