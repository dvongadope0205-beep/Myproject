-- ============================================================
-- seed_shop2_products.sql
-- Delete old shopnew products and seed Shop2 products
-- ============================================================

USE [ZooDatabase]
GO

-- STEP 1: Delete references in OrderItems for ProductId > 12 to prevent foreign key errors
DELETE FROM OrderItems WHERE ProductId > 12;

-- STEP 2: Delete old shopnew products
DELETE FROM ShopProducts WHERE ProductId > 12;

-- STEP 3: Declare category variables
DECLARE @CatApparel INT = (SELECT CategoryId FROM ShopCategories WHERE Name = 'Apparel');
DECLARE @CatPlush INT = (SELECT CategoryId FROM ShopCategories WHERE Name = 'Plush');
DECLARE @CatAccessories INT = (SELECT CategoryId FROM ShopCategories WHERE Name = 'Accessories');
DECLARE @CatBundles INT = (SELECT CategoryId FROM ShopCategories WHERE Name = 'Bundles');
DECLARE @CatGiftCards INT = (SELECT CategoryId FROM ShopCategories WHERE Name = 'Gift Cards');
DECLARE @CatGames INT = (SELECT CategoryId FROM ShopCategories WHERE Name = 'Games');
DECLARE @CatStationery INT = (SELECT CategoryId FROM ShopCategories WHERE Name = 'Stationery');

-- STEP 4: Insert Shop2 products
-- ── Plush (11 items) ──
INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, IsActive, ImagePath, HoverImagePath, Slug, OriginalPrice, PageSlug, IsFeatured, IsNew, IsSizeEnabled, IsSizeChartEnabled)
VALUES
(@CatPlush, N'Batrick Plush With Sunglasses And Hawaiin Shirt', N'Plush Batrick with Sunglasses and Hawaiian Shirt', 21.00, 100, 1, N'/Source/shop2-img/plush/batrick hawaiin/thumbnail/batrick-hawaiin-thumbnail-1.png', N'/Source/shop2-img/plush/batrick hawaiin/thumbnail/batrick-hawaiin-thumbnail-2.png', N'batrick-plush', 27.00, N'BatrickPlush', 1, 0, 0, 0),
(@CatPlush, N'Brother Plush', N'Brother Plush yellow bird', 12.00, 100, 1, N'/Source/shop2-img/Bundle/robert & brother/brother/thumbnail/Yellow_bird1.png', N'/Source/shop2-img/Bundle/robert & brother/brother/thumbnail/Yellow_bird2.png', N'bro-plush', NULL, N'BroPlush', 1, 0, 0, 0),
(@CatPlush, N'Chris The Platypus Plush - Glows-In-The-Dark!', N'Chris the Platypus Plush', 21.00, 100, 1, N'/Source/shop2-img/plush/chris the platypus/thumbnail/Chris_main1.png', N'/Source/shop2-img/plush/chris the platypus/thumbnail/Chris_main2.png', N'chris-plush', 26.00, N'ChrisPlush', 1, 0, 0, 0),
(@CatPlush, N'Emily The Axolotl Plush With Detachable Limbs & Tail', N'Emily the Axolotl Plush', 23.00, 100, 1, N'/Source/shop2-img/Bundle/Spring Magnetic Plush Bundle/Emily/thumbnail/emily-1.png', N'/Source/shop2-img/Bundle/Spring Magnetic Plush Bundle/Emily/thumbnail/emily-2.png', N'emily-plush', 29.00, N'EmilyPlush', 1, 0, 0, 0),
(@CatPlush, N'GPS Rat Plush - He Talks!', N'GPS Rat Plush with talking function', 27.00, 100, 1, N'/Source/shop2-img/plush/GPS Rat/thumbnail/rat1.png', N'/Source/shop2-img/plush/GPS Rat/thumbnail/rat2.png', N'rat-plush', NULL, N'RatPlush', 0, 1, 0, 0),
(@CatPlush, N'Jason Plush With Handkerchief', N'Jason Plush with Handkerchief', 21.00, 100, 1, N'/Source/shop2-img/plush/Jason Plush With Handkerchief/thumbnail/jason-thumbnail-1.jpg', N'/Source/shop2-img/plush/Jason Plush With Handkerchief/thumbnail/jason-thumbnail-2.jpg', N'jason-plush', 27.00, N'JasonPlush', 1, 0, 0, 0),
(@CatPlush, N'Kevin the Otter Plush with Magnetic Rocks & Seashell', N'Kevin the Otter Plush', 23.00, 100, 1, N'/Source/shop2-img/Bundle/Spring Magnetic Plush Bundle/Kevin/thumbnail/Kevin-1.png', N'/Source/shop2-img/Bundle/Spring Magnetic Plush Bundle/Kevin/thumbnail/Kevin-2.jpg', N'kevin-plush', 29.00, N'KevinPlush', 1, 0, 0, 0),
(@CatPlush, N'Lisa Plush With Balloon', N'Lisa Plush with Balloon', 23.00, 100, 1, N'/Source/shop2-img/plush/Lisa/thumbnail/Lisa-1.png', N'/Source/shop2-img/plush/Lisa/thumbnail/Lisa-2.png', N'lisa-plush', 29.00, N'LisaPlush', 1, 0, 0, 0),
(@CatPlush, N'Robert Plush', N'Robert Plush black bird', 27.00, 100, 1, N'/Source/shop2-img/Bundle/robert & brother/robert/thumbnail/black_bird1.png', N'/Source/shop2-img/Bundle/robert & brother/robert/thumbnail/black_bird2.png', N'robert-plush', NULL, N'RobertPlush', 1, 0, 0, 0),
(@CatPlush, N'Screaming Albie Plush', N'Screaming Albie Plush', 21.00, 100, 1, N'/Source/shop2-img/Bundle/Talking Mouth & Screaming Albie Plush Bundle/Albie/thumbnail/Alb_1.png', N'/Source/shop2-img/Bundle/Talking Mouth & Screaming Albie Plush Bundle/Albie/thumbnail/Alb_2.png', N'albie-plush', 26.00, N'AlbiePlush', 0, 0, 0, 0),
(@CatPlush, N'Talking Mouth Plush', N'Talking Mouth Plush', 24.00, 100, 1, N'/Source/shop2-img/Bundle/Talking Mouth & Screaming Albie Plush Bundle/Mouth/thumbnail/mouth1.png', N'/Source/shop2-img/Bundle/Talking Mouth & Screaming Albie Plush Bundle/Mouth/thumbnail/mouth2.png', N'mouth-plush', 30.00, N'MouthPlush', 1, 0, 0, 0);

-- ── Apparel (10 items) ──
INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, IsActive, ImagePath, HoverImagePath, Slug, OriginalPrice, PageSlug, IsFeatured, IsNew, IsSizeEnabled, IsSizeChartEnabled)
VALUES
(@CatApparel, N'Axolotl Family Tee', N'Axolotl Family Tee', 21.00, 100, 1, N'/Source/shop2-img/Apparel/axolotl family tee/thumbnail/axolotl1.png', N'/Source/shop2-img/Apparel/axolotl family tee/thumbnail/axolotl2.png', N'axolotl-tee', 26.00, N'AxolotlTee', 0, 0, 1, 1),
(@CatApparel, N'Batrick Crewneck', N'Batrick Crewneck', 35.00, 100, 1, N'/Source/shop2-img/Apparel/batrick crewneck/thumbnail/batrickcrewneck1.jpg', N'/Source/shop2-img/Apparel/batrick crewneck/thumbnail/batrickcrewneck2.jpg', N'batrick-crewneck', 44.00, N'BatrickCrewneck', 0, 0, 1, 1),
(@CatApparel, N'Batrick Hoodie', N'Batrick Hoodie', 42.00, 100, 1, N'/Source/shop2-img/Apparel/Batrick hoodie/thumbnail/battr_hoodie.png', N'/Source/shop2-img/Apparel/Batrick hoodie/thumbnail/battr_hoodie.png', N'batrick-hoodie', 53.00, N'BatrickHoodie', 0, 0, 1, 1),
(@CatApparel, N'Batrick The Bat Pocket Tee', N'Batrick The Bat Pocket Tee', 21.00, 100, 1, N'/Source/shop2-img/Apparel/batrick the bat pocket tee/thumbnail/pocket-tee1.png', N'/Source/shop2-img/Apparel/batrick the bat pocket tee/thumbnail/pocket-tee2.png', N'batrick-tee', 26.00, N'BatrickTee', 0, 0, 1, 1),
(@CatApparel, N'Lisa Tee', N'Lisa Tee', 21.00, 100, 1, N'/Source/shop2-img/Apparel/lisa t/thumbnail/lisatee1.png', N'/Source/shop2-img/Apparel/lisa t/thumbnail/lisatee2.png', N'lisa-tee', 26.00, N'LisaTee', 0, 0, 1, 1),
(@CatApparel, N'Natural Habitat Crop Tee', N'Natural Habitat Crop Tee', 18.00, 100, 1, N'/Source/shop2-img/Apparel/natural habitat crop tee/thumbnail/natural-crop-tee-1.jpg', N'/Source/shop2-img/Apparel/natural habitat crop tee/thumbnail/natural-crop-tee-2.jpg', N'nh-tee', 23.00, N'NHTee', 0, 0, 1, 1),
(@CatApparel, N'Natural Habitat Fall Hoodie', N'Natural Habitat Fall Hoodie', 49.00, 100, 1, N'/Source/shop2-img/Apparel/natural habitat fall hoodie/thumbnail/hoodie1.png', N'/Source/shop2-img/Apparel/natural habitat fall hoodie/thumbnail/hoodie2.png', N'nh-fall-hoodie', 54.00, N'NHFallHoodie', 0, 0, 1, 1),
(@CatApparel, N'Natural Habitat Line Art Hoodie', N'Natural Habitat Line Art Hoodie', 46.00, 100, 1, N'/Source/shop2-img/Apparel/lineart hoodie/thumbnail/lineart1.png', N'/Source/shop2-img/Apparel/lineart hoodie/thumbnail/lineart2.png', N'nh-lineart-hoodie', 51.00, N'NHLineartHoodie', 0, 0, 1, 1),
(@CatApparel, N'Robert''s Pancake Tee', N'Robert''s Pancake Tee', 21.00, 100, 1, N'/Source/shop2-img/Apparel/robert t/thumbnail/roberttee1.jpg', N'/Source/shop2-img/Apparel/robert t/thumbnail/roberttee2.jpg', N'robert-tee', 26.00, N'RobertTee', 0, 0, 1, 1),
(@CatApparel, N'Summer Hoodie', N'Summer Hoodie', 42.00, 100, 1, N'/Source/shop2-img/Apparel/summer hoodie/thumbnail/summer-hoodie1.jpg', N'/Source/shop2-img/Apparel/summer hoodie/thumbnail/summer-hoodie2.jpg', N'summer-hoodie', 53.00, N'SummerHoodie', 0, 0, 1, 1);

-- ── Accessories (8 items) ──
INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, IsActive, ImagePath, HoverImagePath, Slug, OriginalPrice, PageSlug, IsFeatured, IsNew, IsSizeEnabled, IsSizeChartEnabled)
VALUES
(@CatAccessories, N'Albie Enamel Pin', N'Albie Enamel Pin', 6.00, 200, 1, N'/Source/shop2-img/Accessory/Albie Enamel/thumbnail/albie1.png', N'/Source/shop2-img/Accessory/Albie Enamel/thumbnail/albie2.png', N'albie-pin', 8.00, N'AlbiePin', 0, 0, 0, 0),
(@CatAccessories, N'Ashley Enamel Pin', N'Ashley Enamel Pin', 6.00, 200, 1, N'/Source/shop2-img/Accessory/Ashley Enamel/thumbnail/Ashley-1.jpg', N'/Source/shop2-img/Accessory/Ashley Enamel/thumbnail/Ashley-2.jpg', N'ashley-pin', 8.00, N'AshleyPin', 0, 0, 0, 0),
(@CatAccessories, N'Jason Enamel Pin', N'Jason Enamel Pin', 6.00, 200, 1, N'/Source/shop2-img/Accessory/Roger Enamel/thumbnail/roger1.png', N'/Source/shop2-img/Accessory/Roger Enamel/thumbnail/roger2.png', N'jason-pin', 8.00, N'JasonPin', 0, 0, 0, 0),
(@CatAccessories, N'Kevin Enamel Pin', N'Kevin Enamel Pin', 6.00, 200, 1, N'/Source/shop2-img/Accessory/Kevin Enamel/thumbnail/Kevin-1.jpg', N'/Source/shop2-img/Accessory/Kevin Enamel/thumbnail/Kevin-2.jpg', N'kevin-pin', 8.00, N'KevinPin', 0, 0, 0, 0),
(@CatAccessories, N'Lisa Enamel Pin', N'Lisa Enamel Pin', 6.00, 200, 1, N'/Source/shop2-img/Accessory/Lisa Enamel/thumbnail/lisa1.png', N'/Source/shop2-img/Accessory/Lisa Enamel/thumbnail/lisa2.png', N'lisa-pin', 8.00, N'LisaPin', 0, 0, 0, 0),
(@CatAccessories, N'Lizard Enamel Pin', N'Lizard Enamel Pin', 6.00, 200, 1, N'/Source/shop2-img/Accessory/Lizard Enamel/thumbnail/lizard-1.jpg', N'/Source/shop2-img/Accessory/Lizard Enamel/thumbnail/lizard-2.jpg', N'lizard-pin', 8.00, N'LizardPin', 0, 0, 0, 0),
(@CatAccessories, N'Kevin Backpack', N'Kevin Backpack', 42.00, 100, 1, N'/Source/shop2-img/Accessory/Kevin backpack/thumbnail/kevin1.png', N'/Source/shop2-img/Accessory/Kevin backpack/thumbnail/kevin2.png', N'kevin-backpack', NULL, N'KevinBackpack', 0, 0, 0, 0),
(@CatAccessories, N'Summer Tote Bag', N'Summer Tote Bag', 15.00, 100, 1, N'/Source/shop2-img/Accessory/summer tote bag/thumbnail/tote1.jpg', N'/Source/shop2-img/Accessory/summer tote bag/thumbnail/tote2.jpg', N'summer-tote-bag', NULL, N'SummerToteBag', 0, 0, 0, 0);

-- ── Stationery (6 items) ──
INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, IsActive, ImagePath, HoverImagePath, Slug, OriginalPrice, PageSlug, IsFeatured, IsNew, IsSizeEnabled, IsSizeChartEnabled)
VALUES
(@CatStationery, N'GWP BFCM Line Art Sticker', N'GWP BFCM Line Art Sticker', 8.00, 200, 1, N'/Source/shop2-img/stationery/line art sticker/thumbnail/lineartstickerimage.png', N'/Source/shop2-img/stationery/line art sticker/thumbnail/lineartstickerimage.png', N'line-art', NULL, N'LineArt', 0, 0, 0, 0),
(@CatStationery, N'Holiday Sticker Pack', N'Holiday Sticker Pack', 8.00, 200, 1, N'/Source/shop2-img/stationery/holiday sticker/thumbnail/stickers1-940x940.png', N'/Source/shop2-img/stationery/holiday sticker/thumbnail/stickers2-940x940.png', N'holiday-sticker', 9.00, N'HolidaySticker', 0, 0, 0, 0),
(@CatStationery, N'Natural Habitat Notebook', N'Natural Habitat Notebook', 23.00, 150, 1, N'/Source/shop2-img/stationery/notebook/thumbnail/book1-940x940.png', N'/Source/shop2-img/stationery/notebook/thumbnail/book2-940x940.png', N'nh-notebook', NULL, N'NHNotebook', 0, 0, 0, 0),
(@CatStationery, N'Natural Habitat Sticker Pack', N'Natural Habitat Sticker Pack', 8.00, 200, 1, N'/Source/shop2-img/stationery/natural habitat sticker pack/thumbnail/1-sticker-940x940.png', N'/Source/shop2-img/stationery/natural habitat sticker pack/thumbnail/2-sticker-940x940.png', N'nh-sticker', 9.00, N'NHSticker', 0, 0, 0, 0),
(@CatStationery, N'Spring Sticker Pack', N'Spring Sticker Pack', 8.00, 200, 1, N'/Source/shop2-img/stationery/Spring sticker pack/thumbnail/spring-ticket-pack-1.png', N'/Source/shop2-img/stationery/Spring sticker pack/thumbnail/spring-ticket-pack-2.png', N'spring-sticker', 9.00, N'SpringSticker', 0, 0, 0, 0),
(@CatStationery, N'Summer Sticker Pack', N'Summer Sticker Pack', 8.00, 200, 1, N'/Source/shop2-img/stationery/summer sticker pack/thumbnail/1-summer-940x940.png', N'/Source/shop2-img/stationery/summer sticker pack/thumbnail/2-summer-940x940.png', N'summer-sticker', 9.00, N'SummerSticker', 0, 0, 0, 0);

-- ── Bundles (3 items) ──
INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, IsActive, ImagePath, HoverImagePath, Slug, OriginalPrice, PageSlug, IsFeatured, IsNew, IsSizeEnabled, IsSizeChartEnabled)
VALUES
(@CatBundles, N'Robert & Brother Plush Bundle', N'Robert & Brother Plush Bundle', 38.00, 50, 1, N'/Source/shop2-img/Bundle/robert & brother/thumbnail/bundle.png', N'/Source/shop2-img/Bundle/robert & brother/robert/thumbnail/black_bird1.png', N'robert-bro-bundle', NULL, N'RobertBroBundle', 0, 0, 0, 0),
(@CatBundles, N'Spring Magnetic Plush Bundle', N'Spring Magnetic Plush Bundle', 52.00, 50, 1, N'/Source/shop2-img/Bundle/Spring Magnetic Plush Bundle/thumbnail/magnetic-plush-1.png', N'/Source/shop2-img/Bundle/Spring Magnetic Plush Bundle/thumbnail/magnetic-plush-2.png', N'spring-magnetic-plush', 57.00, N'SpringMagneticPlush', 0, 0, 0, 0),
(@CatBundles, N'Talking Mouth & Screaming Albie Plush Bundle', N'Talking Mouth & Screaming Albie Plush Bundle', 50.00, 50, 1, N'/Source/shop2-img/Bundle/Talking Mouth & Screaming Albie Plush Bundle/thumbnail/mouth-albie-1.png', N'/Source/shop2-img/Bundle/Talking Mouth & Screaming Albie Plush Bundle/thumbnail/mouth-albie-2.png', N'mouth-albie-bundle', 56.00, N'MouthAlbieBundle', 0, 0, 0, 0);

-- ── Games (1 item) ──
INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, IsActive, ImagePath, HoverImagePath, Slug, OriginalPrice, PageSlug, IsFeatured, IsNew, IsSizeEnabled, IsSizeChartEnabled)
VALUES
(@CatGames, N'Natural Habitat Board Game', N'Natural Habitat Board Game', 30.00, 75, 1, N'/Source/shop2-img/game/thumbnail/game1.png', N'/Source/shop2-img/game/thumbnail/game1.png', N'board-game', 35.00, N'BoardGame', 0, 1, 0, 0);

-- ── Gift Cards (1 item) ──
INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, IsActive, ImagePath, HoverImagePath, Slug, OriginalPrice, PageSlug, IsFeatured, IsNew, IsSizeEnabled, IsSizeChartEnabled)
VALUES
(@CatGiftCards, N'Natural Habitat Merch Digital Gift Card', N'Digital Gift Card', 7.44, 999, 1, N'/Source/shop2-img/gift card/GiftCardImage-1806x1806.png', N'/Source/shop2-img/gift card/GiftCardImage-1206x1206.png', N'gift-cards', NULL, N'GiftCards', 0, 0, 0, 0);

PRINT '✅ Shop2 Products successfully seeded!';
GO
