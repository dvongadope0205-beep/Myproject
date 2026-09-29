const ALL_PRODUCTS = [
  { id: '1231231', name: '1231231', href: '/Shop2/1231231', image: '/images/shop/a4e62e90-6b76-4c08-88ef-733b6a093425.png', hoverImage: '/images/shop/4057ebc4-2c21-4e40-9662-0d87d8509f55.jpg', price: 12312.00, compareAtPrice: null, variantId: 'product-8019', category: 'Plush', isSizeEnabled: true, isSizeChartEnabled: true, isFeatured: true, isNew: true },
  { id: '12312312', name: '12312312', href: '/Shop2/12312312', image: '/images/shop/3887788d-7713-481d-9cd9-39cd73f8e7a9.png', hoverImage: '/images/shop/f139a0e7-c5d1-4315-9b68-e0037dbe687d.jpg', price: 12312312.00, compareAtPrice: null, variantId: 'product-8018', category: 'Apparel', isSizeEnabled: true, isSizeChartEnabled: true, isFeatured: true, isNew: true },
  { id: 'albie-pin', name: 'Albie Enamel Pin', href: '/Shop2/albie-pin', image: '/Source/shop2-img/Accessory/Albie Enamel/thumbnail/albie1.png', hoverImage: '/Source/shop2-img/Accessory/Albie Enamel/thumbnail/albie2.png', price: 6.00, compareAtPrice: 8.00, variantId: 'product-5037', category: 'Accessories', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'ashley-pin', name: 'Ashley Enamel Pin', href: '/Shop2/ashley-pin', image: '/Source/shop2-img/Accessory/Ashley Enamel/thumbnail/Ashley-1.jpg', hoverImage: '/Source/shop2-img/Accessory/Ashley Enamel/thumbnail/Ashley-2.jpg', price: 6.00, compareAtPrice: 8.00, variantId: 'product-5038', category: 'Accessories', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'axolotl-tee', name: 'Axolotl Family Tee', href: '/Shop2/axolotl-tee', image: '/Source/shop2-img/Apparel/axolotl family tee/thumbnail/axolotl1.png', hoverImage: '/Source/shop2-img/Apparel/axolotl family tee/thumbnail/axolotl2.png', price: 21.00, compareAtPrice: 26.00, variantId: 'product-5027', category: 'Apparel', isSizeEnabled: true, isSizeChartEnabled: true, isFeatured: false, isNew: false },
  { id: 'batrick-crewneck', name: 'Batrick Crewneck', href: '/Shop2/batrick-crewneck', image: '/Source/shop2-img/Apparel/batrick crewneck/thumbnail/batrickcrewneck1.jpg', hoverImage: '/Source/shop2-img/Apparel/batrick crewneck/thumbnail/batrickcrewneck2.jpg', price: 35.00, compareAtPrice: 44.00, variantId: 'product-5028', category: 'Apparel', isSizeEnabled: true, isSizeChartEnabled: true, isFeatured: false, isNew: false },
  { id: 'batrick-hoodie', name: 'Batrick Hoodie', href: '/Shop2/batrick-hoodie', image: '/Source/shop2-img/Apparel/Batrick hoodie/thumbnail/battr_hoodie.png', hoverImage: '/Source/shop2-img/Apparel/Batrick hoodie/thumbnail/battr_hoodie.png', price: 42.00, compareAtPrice: 53.00, variantId: 'product-5029', category: 'Apparel', isSizeEnabled: true, isSizeChartEnabled: true, isFeatured: false, isNew: false },
  { id: 'batrick-plush', name: 'Batrick Plush With Sunglasses And Hawaiin Shirt', href: '/Shop2/batrick-plush', image: '/Source/shop2-img/plush/batrick hawaiin/thumbnail/batrick-hawaiin-thumbnail-1.png', hoverImage: '/Source/shop2-img/plush/batrick hawaiin/thumbnail/batrick-hawaiin-thumbnail-2.png', price: 21.00, compareAtPrice: 27.00, variantId: 'product-5016', category: 'Plush', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: true, isNew: false },
  { id: 'batrick-tee', name: 'Batrick The Bat Pocket Tee', href: '/Shop2/batrick-tee', image: '/Source/shop2-img/Apparel/batrick the bat pocket tee/thumbnail/pocket-tee1.png', hoverImage: '/Source/shop2-img/Apparel/batrick the bat pocket tee/thumbnail/pocket-tee2.png', price: 21.00, compareAtPrice: 26.00, variantId: 'product-5030', category: 'Apparel', isSizeEnabled: true, isSizeChartEnabled: true, isFeatured: false, isNew: false },
  { id: 'bro-plush', name: 'Brother Plush', href: '/Shop2/bro-plush', image: '/Source/shop2-img/Bundle/robert & brother/brother/thumbnail/Yellow_bird1.png', hoverImage: '/Source/shop2-img/Bundle/robert & brother/brother/thumbnail/Yellow_bird2.png', price: 12.00, compareAtPrice: null, variantId: 'product-5017', category: 'Plush', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: true, isNew: false },
  { id: 'chris-plush', name: 'Chris The Platypus Plush - Glows-In-The-Dark!', href: '/Shop2/chris-plush', image: '/Source/shop2-img/plush/chris the platypus/thumbnail/Chris_main1.png', hoverImage: '/Source/shop2-img/plush/chris the platypus/thumbnail/Chris_main2.png', price: 21.00, compareAtPrice: 26.00, variantId: 'product-5018', category: 'Plush', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: true, isNew: false },
  { id: 'emily-plush', name: 'Emily The Axolotl Plush With Detachable Limbs & Tail', href: '/Shop2/emily-plush', image: '/Source/shop2-img/Bundle/Spring Magnetic Plush Bundle/Emily/thumbnail/emily-1.png', hoverImage: '/Source/shop2-img/Bundle/Spring Magnetic Plush Bundle/Emily/thumbnail/emily-2.png', price: 23.00, compareAtPrice: 29.00, variantId: 'product-5019', category: 'Plush', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: true, isNew: false },
  { id: 'rat-plush', name: 'GPS Rat Plush - He Talks!', href: '/Shop2/rat-plush', image: '/Source/shop2-img/plush/GPS Rat/thumbnail/rat1.png', hoverImage: '/Source/shop2-img/plush/GPS Rat/thumbnail/rat2.png', price: 27.00, compareAtPrice: null, variantId: 'product-5020', category: 'Plush', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: true },
  { id: 'line-art', name: 'GWP BFCM Line Art Sticker', href: '/Shop2/line-art', image: '/Source/shop2-img/stationery/line art sticker/thumbnail/lineartstickerimage.png', hoverImage: '/Source/shop2-img/stationery/line art sticker/thumbnail/lineartstickerimage.png', price: 8.00, compareAtPrice: null, variantId: 'product-5045', category: 'Stationery', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'holiday-sticker', name: 'Holiday Sticker Pack', href: '/Shop2/holiday-sticker', image: '/Source/shop2-img/stationery/holiday sticker/thumbnail/stickers1-940x940.png', hoverImage: '/Source/shop2-img/stationery/holiday sticker/thumbnail/stickers2-940x940.png', price: 8.00, compareAtPrice: 9.00, variantId: 'product-5046', category: 'Stationery', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'jason-pin', name: 'Jason Enamel Pin', href: '/Shop2/jason-pin', image: '/Source/shop2-img/Accessory/Roger Enamel/thumbnail/roger1.png', hoverImage: '/Source/shop2-img/Accessory/Roger Enamel/thumbnail/roger2.png', price: 6.00, compareAtPrice: 8.00, variantId: 'product-5039', category: 'Accessories', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'jason-plush', name: 'Jason Plush With Handkerchief', href: '/Shop2/jason-plush', image: '/Source/shop2-img/plush/Jason Plush With Handkerchief/thumbnail/jason-thumbnail-1.jpg', hoverImage: '/Source/shop2-img/plush/Jason Plush With Handkerchief/thumbnail/jason-thumbnail-2.jpg', price: 21.00, compareAtPrice: 27.00, variantId: 'product-5021', category: 'Plush', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: true, isNew: false },
  { id: 'kevin-backpack', name: 'Kevin Backpack', href: '/Shop2/kevin-backpack', image: '/Source/shop2-img/Accessory/Kevin backpack/thumbnail/kevin1.png', hoverImage: '/Source/shop2-img/Accessory/Kevin backpack/thumbnail/kevin2.png', price: 42.00, compareAtPrice: null, variantId: 'product-5043', category: 'Accessories', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'kevin-pin', name: 'Kevin Enamel Pin', href: '/Shop2/kevin-pin', image: '/Source/shop2-img/Accessory/Kevin Enamel/thumbnail/Kevin-1.jpg', hoverImage: '/Source/shop2-img/Accessory/Kevin Enamel/thumbnail/Kevin-2.jpg', price: 6.00, compareAtPrice: 8.00, variantId: 'product-5040', category: 'Accessories', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'kevin-plush', name: 'Kevin the Otter Plush with Magnetic Rocks & Seashell', href: '/Shop2/kevin-plush', image: '/Source/shop2-img/Bundle/Spring Magnetic Plush Bundle/Kevin/thumbnail/Kevin-1.png', hoverImage: '/Source/shop2-img/Bundle/Spring Magnetic Plush Bundle/Kevin/thumbnail/Kevin-2.jpg', price: 23.00, compareAtPrice: 29.00, variantId: 'product-5022', category: 'Plush', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: true, isNew: false },
  { id: 'lisa-pin', name: 'Lisa Enamel Pin', href: '/Shop2/lisa-pin', image: '/Source/shop2-img/Accessory/Lisa Enamel/thumbnail/lisa1.png', hoverImage: '/Source/shop2-img/Accessory/Lisa Enamel/thumbnail/lisa2.png', price: 6.00, compareAtPrice: 8.00, variantId: 'product-5041', category: 'Accessories', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'lisa-plush', name: 'Lisa Plush With Balloon', href: '/Shop2/lisa-plush', image: '/Source/shop2-img/plush/Lisa/thumbnail/Lisa-1.png', hoverImage: '/Source/shop2-img/plush/Lisa/thumbnail/Lisa-2.png', price: 23.00, compareAtPrice: 29.00, variantId: 'product-5023', category: 'Plush', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: true, isNew: false },
  { id: 'lisa-tee', name: 'Lisa Tee', href: '/Shop2/lisa-tee', image: '/Source/shop2-img/Apparel/lisa t/thumbnail/lisatee1.png', hoverImage: '/Source/shop2-img/Apparel/lisa t/thumbnail/lisatee2.png', price: 21.00, compareAtPrice: 26.00, variantId: 'product-5031', category: 'Apparel', isSizeEnabled: true, isSizeChartEnabled: true, isFeatured: false, isNew: false },
  { id: 'lizard-pin', name: 'Lizard Enamel Pin', href: '/Shop2/lizard-pin', image: '/Source/shop2-img/Accessory/Lizard Enamel/thumbnail/lizard-1.jpg', hoverImage: '/Source/shop2-img/Accessory/Lizard Enamel/thumbnail/lizard-2.jpg', price: 6.00, compareAtPrice: 8.00, variantId: 'product-5042', category: 'Accessories', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'meme12', name: 'Meme12', href: '/Shop2/meme12', image: '/images/shop/5a48818c-d718-4a02-bd93-02d595ef7df7.jpg', hoverImage: '/images/shop/44eb4bc6-cbea-40e6-aa0d-edb64eddcee7.jpg', price: 123.00, compareAtPrice: null, variantId: 'product-7018', category: 'Apparel', isSizeEnabled: true, isSizeChartEnabled: true, isFeatured: false, isNew: false },
  { id: 'memee', name: 'Memee', href: '/Shop2/memee', image: '/images/shop/8d9ba4e2-063f-42ad-a0be-e3b5c32187f8.jpg', hoverImage: '/images/shop/5ea9c8a4-856d-4e84-9b28-47e66f93b4f6.jpg', price: 123.00, compareAtPrice: null, variantId: 'product-7017', category: 'Apparel', isSizeEnabled: true, isSizeChartEnabled: true, isFeatured: true, isNew: true },
  { id: 'board-game', name: 'Natural Habitat Board Game', href: '/Shop2/board-game', image: '/Source/shop2-img/game/thumbnail/game1.png', hoverImage: '/Source/shop2-img/game/thumbnail/game1.png', price: 30.00, compareAtPrice: 35.00, variantId: 'product-5054', category: 'Games', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: true },
  { id: 'nh-tee', name: 'Natural Habitat Crop Tee', href: '/Shop2/nh-tee', image: '/Source/shop2-img/Apparel/natural habitat crop tee/thumbnail/natural-crop-tee-1.jpg', hoverImage: '/Source/shop2-img/Apparel/natural habitat crop tee/thumbnail/natural-crop-tee-2.jpg', price: 18.00, compareAtPrice: 23.00, variantId: 'product-5032', category: 'Apparel', isSizeEnabled: true, isSizeChartEnabled: true, isFeatured: false, isNew: false },
  { id: 'nh-fall-hoodie', name: 'Natural Habitat Fall Hoodie', href: '/Shop2/nh-fall-hoodie', image: '/Source/shop2-img/Apparel/natural habitat fall hoodie/thumbnail/hoodie1.png', hoverImage: '/Source/shop2-img/Apparel/natural habitat fall hoodie/thumbnail/hoodie2.png', price: 49.00, compareAtPrice: 54.00, variantId: 'product-5033', category: 'Apparel', isSizeEnabled: true, isSizeChartEnabled: true, isFeatured: false, isNew: false },
  { id: 'nh-lineart-hoodie', name: 'Natural Habitat Line Art Hoodie', href: '/Shop2/nh-lineart-hoodie', image: '/Source/shop2-img/Apparel/lineart hoodie/thumbnail/lineart1.png', hoverImage: '/Source/shop2-img/Apparel/lineart hoodie/thumbnail/lineart2.png', price: 46.00, compareAtPrice: 51.00, variantId: 'product-5034', category: 'Apparel', isSizeEnabled: true, isSizeChartEnabled: true, isFeatured: false, isNew: false },
  { id: 'gift-cards', name: 'Natural Habitat Merch Digital Gift Card', href: '/Shop2/gift-cards', image: '/Source/shop2-img/gift card/GiftCardImage-1806x1806.png', hoverImage: '/Source/shop2-img/gift card/GiftCardImage-1206x1206.png', price: 7.44, compareAtPrice: null, variantId: 'product-5055', category: 'Gift Cards', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'nh-notebook', name: 'Natural Habitat Notebook', href: '/Shop2/nh-notebook', image: '/Source/shop2-img/stationery/notebook/thumbnail/book1-940x940.png', hoverImage: '/Source/shop2-img/stationery/notebook/thumbnail/book2-940x940.png', price: 23.00, compareAtPrice: null, variantId: 'product-5047', category: 'Stationery', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'nh-sticker', name: 'Natural Habitat Sticker Pack', href: '/Shop2/nh-sticker', image: '/Source/shop2-img/stationery/natural habitat sticker pack/thumbnail/1-sticker-940x940.png', hoverImage: '/Source/shop2-img/stationery/natural habitat sticker pack/thumbnail/2-sticker-940x940.png', price: 8.00, compareAtPrice: 9.00, variantId: 'product-5048', category: 'Stationery', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'robert-bro-bundle', name: 'Robert & Brother Plush Bundle', href: '/Shop2/robert-bro-bundle', image: '/Source/shop2-img/Bundle/robert & brother/thumbnail/bundle.png', hoverImage: '/Source/shop2-img/Bundle/robert & brother/robert/thumbnail/black_bird1.png', price: 38.00, compareAtPrice: null, variantId: 'product-5051', category: 'Bundles', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'robert-plush', name: 'Robert Plush', href: '/Shop2/robert-plush', image: '/Source/shop2-img/Bundle/robert & brother/robert/thumbnail/black_bird1.png', hoverImage: '/Source/shop2-img/Bundle/robert & brother/robert/thumbnail/black_bird2.png', price: 27.00, compareAtPrice: null, variantId: 'product-5024', category: 'Plush', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: true, isNew: false },
  { id: 'robert-tee', name: 'Robert\'s Pancake Tee', href: '/Shop2/robert-tee', image: '/Source/shop2-img/Apparel/robert t/thumbnail/roberttee1.jpg', hoverImage: '/Source/shop2-img/Apparel/robert t/thumbnail/roberttee2.jpg', price: 21.00, compareAtPrice: 26.00, variantId: 'product-5035', category: 'Apparel', isSizeEnabled: true, isSizeChartEnabled: true, isFeatured: false, isNew: false },
  { id: 'albie-plush', name: 'Screaming Albie Plush', href: '/Shop2/albie-plush', image: '/Source/shop2-img/Bundle/Talking Mouth & Screaming Albie Plush Bundle/Albie/thumbnail/Alb_1.png', hoverImage: '/Source/shop2-img/Bundle/Talking Mouth & Screaming Albie Plush Bundle/Albie/thumbnail/Alb_2.png', price: 21.00, compareAtPrice: 26.00, variantId: 'product-5025', category: 'Plush', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'spring-magnetic-plush', name: 'Spring Magnetic Plush Bundle', href: '/Shop2/spring-magnetic-plush', image: '/Source/shop2-img/Bundle/Spring Magnetic Plush Bundle/thumbnail/magnetic-plush-1.png', hoverImage: '/Source/shop2-img/Bundle/Spring Magnetic Plush Bundle/thumbnail/magnetic-plush-2.png', price: 52.00, compareAtPrice: 57.00, variantId: 'product-5052', category: 'Bundles', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'spring-sticker', name: 'Spring Sticker Pack', href: '/Shop2/spring-sticker', image: '/Source/shop2-img/stationery/Spring sticker pack/thumbnail/spring-ticket-pack-1.png', hoverImage: '/Source/shop2-img/stationery/Spring sticker pack/thumbnail/spring-ticket-pack-2.png', price: 8.00, compareAtPrice: 9.00, variantId: 'product-5049', category: 'Stationery', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'summer-hoodie', name: 'Summer Hoodie', href: '/Shop2/summer-hoodie', image: '/Source/shop2-img/Apparel/summer hoodie/thumbnail/summer-hoodie1.jpg', hoverImage: '/Source/shop2-img/Apparel/summer hoodie/thumbnail/summer-hoodie2.jpg', price: 42.00, compareAtPrice: 53.00, variantId: 'product-5036', category: 'Apparel', isSizeEnabled: true, isSizeChartEnabled: true, isFeatured: false, isNew: false },
  { id: 'summer-sticker', name: 'Summer Sticker Pack', href: '/Shop2/summer-sticker', image: '/Source/shop2-img/stationery/summer sticker pack/thumbnail/1-summer-940x940.png', hoverImage: '/Source/shop2-img/stationery/summer sticker pack/thumbnail/2-summer-940x940.png', price: 8.00, compareAtPrice: 9.00, variantId: 'product-5050', category: 'Stationery', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'summer-tote-bag', name: 'Summer Tote Bag', href: '/Shop2/summer-tote-bag', image: '/Source/shop2-img/Accessory/summer tote bag/thumbnail/tote1.jpg', hoverImage: '/Source/shop2-img/Accessory/summer tote bag/thumbnail/tote2.jpg', price: 15.00, compareAtPrice: null, variantId: 'product-5044', category: 'Accessories', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'mouth-albie-bundle', name: 'Talking Mouth & Screaming Albie Plush Bundle', href: '/Shop2/mouth-albie-bundle', image: '/Source/shop2-img/Bundle/Talking Mouth & Screaming Albie Plush Bundle/thumbnail/mouth-albie-1.png', hoverImage: '/Source/shop2-img/Bundle/Talking Mouth & Screaming Albie Plush Bundle/thumbnail/mouth-albie-2.png', price: 50.00, compareAtPrice: 56.00, variantId: 'product-5053', category: 'Bundles', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: false, isNew: false },
  { id: 'mouth-plush', name: 'Talking Mouth Plush', href: '/Shop2/mouth-plush', image: '/Source/shop2-img/Bundle/Talking Mouth & Screaming Albie Plush Bundle/Mouth/thumbnail/mouth1.png', hoverImage: '/Source/shop2-img/Bundle/Talking Mouth & Screaming Albie Plush Bundle/Mouth/thumbnail/mouth2.png', price: 24.00, compareAtPrice: 30.00, variantId: 'product-5026', category: 'Plush', isSizeEnabled: false, isSizeChartEnabled: false, isFeatured: true, isNew: false }
];

function renderShopProducts(filter) {
    const grid = document.querySelector('.product-grid');
    if (!grid) return;
    grid.innerHTML = '';

    let filtered = ALL_PRODUCTS;
    if (filter === 'featured') {
        filtered = ALL_PRODUCTS.filter(p => p.isFeatured);
    } else if (filter === 'new') {
        filtered = ALL_PRODUCTS.filter(p => p.isNew);
    } else if (filter && filter !== 'all') {
        filtered = ALL_PRODUCTS.filter(p => p.category.toLowerCase() === filter.toLowerCase());
    }

    filtered.forEach(p => {
        const hasVariantClass = p.isSizeEnabled 
            ? (p.isSizeChartEnabled ? 'has-variant-2' : 'has-variant') 
            : '';

        let priceHtml = '';
        if (p.compareAtPrice && p.compareAtPrice > p.price) {
            priceHtml = `<span class="evil">£${p.compareAtPrice.toFixed(2)}</span> <span class="good">£${p.price.toFixed(2)}</span>`;
        } else {
            priceHtml = `<span class="price">£${p.price.toFixed(2)}</span>`;
        }

        let variantHtml = '';
        if (p.isSizeEnabled) {
            variantHtml = `
                <div class="variant-selects" data-section="template-product-grid" id="variant-selects-${p.id}">
                  <div aria-label="Size" class="variant-row" data-option-position="1" role="group">
                    <div class="variant-values">
                      <input checked="" class="variant-option-input" data-option-position="1" id="Option-${p.id}-XS" name="options[Size]" type="radio" value="XS"/>
                      <label aria-disabled="false" class="variant-label" data-option-position="1" data-option-value="XS" for="Option-${p.id}-XS" title="XS">XS</label>
                      
                      <input class="variant-option-input" data-option-position="1" id="Option-${p.id}-S" name="options[Size]" type="radio" value="S"/>
                      <label aria-disabled="false" class="variant-label" data-option-position="1" data-option-value="S" for="Option-${p.id}-S" title="S">S</label>
                      
                      <input class="variant-option-input" data-option-position="1" id="Option-${p.id}-M" name="options[Size]" type="radio" value="M"/>
                      <label aria-disabled="false" class="variant-label" data-option-position="1" data-option-value="M" for="Option-${p.id}-M" title="M">M</label>
                      
                      <input class="variant-option-input" data-option-position="1" id="Option-${p.id}-L" name="options[Size]" type="radio" value="L"/>
                      <label aria-disabled="false" class="variant-label" data-option-position="1" data-option-value="L" for="Option-${p.id}-L" title="L">L</label>
                      
                      <input class="variant-option-input" data-option-position="1" id="Option-${p.id}-XL" name="options[Size]" type="radio" value="XL"/>
                      <label aria-disabled="false" class="variant-label" data-option-position="1" data-option-value="XL" for="Option-${p.id}-XL" title="XL">XL</label>
                      
                      <input class="variant-option-input" data-option-position="1" id="Option-${p.id}-2XL" name="options[Size]" type="radio" value="2XL"/>
                      <label aria-disabled="false" class="variant-label" data-option-position="1" data-option-value="2XL" for="Option-${p.id}-2XL" title="2XL">2XL</label>
                      
                      <input class="variant-option-input" data-option-position="1" id="Option-${p.id}-3XL" name="options[Size]" type="radio" value="3XL"/>
                      <label aria-disabled="false" class="variant-label" data-option-position="1" data-option-value="3XL" for="Option-${p.id}-3XL" title="3XL">3XL</label>
                      
                      <input class="variant-option-input" data-option-position="1" id="Option-${p.id}-4XL" name="options[Size]" type="radio" value="4XL"/>
                      <label aria-disabled="false" class="variant-label" data-option-position="1" data-option-value="4XL" for="Option-${p.id}-4XL" title="4XL">4XL</label>
                    </div>
                  </div>
                </div>`;
        } else {
            variantHtml = `<input class="product-variant-id" name="id" type="hidden" value="${p.variantId}"/>`;
        }

        const li = document.createElement('li');
        li.className = 'grid-item';
        li.id = 'Slide-template';
        li.innerHTML = `
            <div class="card-wrapper ${hasVariantClass}">
              <div class="card-product">
                <div class="card-inner-ratio">
                  <a class="product-card" href="${p.href}" style="text-decoration: none; color: inherit;">
                    <div class="card-media">
                      <img alt="${p.name}" class="product-img-primary" src="${p.image}"/>
                      <img alt="${p.name} Hover" src="${p.hoverImage}"/>
                    </div>
                  </a>
                  <div class="card-content">
                    <div class="card-information">
                      <h3 class="card-heading-h5">
                        <a class="full-unstyled-link" href="${p.href}">${p.name}</a>
                      </h3>
                    </div>
                  </div>
                </div>
                <div class="product-footer">
                  <div class="product-details">
                    <div class="product-footer-inner">
                      <div class="heading-rating">
                        <h3 class="card-heading-h5">
                          <a class="full-unstyled-link" href="${p.href}">${p.name}</a>
                        </h3>
                      </div>
                      <div class="labubu">
                        ${priceHtml}
                      </div>
                    </div>
                    <div class="quick-add-no-js">
                      <product-form data-section-id="template--26975595233570__related-products">
                        <form accept-charset="UTF-8" action="/cart/add" class="form" data-qa-form-init="true" data-type="add-to-cart-form" enctype="multipart/form-data" id="quick-add-template-${p.id}" method="post" novalidate="novalidate">
                          <input name="form_type" type="hidden" value="product"/>
                          <input name="utf8" type="hidden" value="✓"/>
                          ${variantHtml}
                          <div class="quick-add-actions">
                            <quantity-input class="cart-quantity">
                              <button class="quantity-button qty-minus" type="button">−</button>
                              <input class="quantity-input" max="99" min="1" type="number" value="1"/>
                              <button class="quantity-button qty-plus" type="button">+</button>
                            </quantity-input>
                            <button class="quick-add-submit" type="button">
                              <span class="price-item">ADD</span>
                            </button>
                          </div>
                        </form>
                      </product-form>
                    </div>
                  </div>
                </div>
              </div>
            </div>`;
        grid.appendChild(li);
    });
}
