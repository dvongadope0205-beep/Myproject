        function initCartEffects() {
            if (window.__cartEffectsInitialized) return;
            window.__cartEffectsInitialized = true;

            const header = document.querySelector('.main-header');
            const cartTrigger = document.querySelector('.cart-trigger');
            const cartDrawer = document.querySelector('.cart-drawer');
            const cartCountEl = document.getElementById('cartCount');

            const openCart = () => {
                document.body.classList.add('cart-open');
                cartDrawer?.setAttribute('aria-hidden', 'false');
            };

            const closeCart = () => {
                document.body.classList.remove('cart-open');
                cartDrawer?.setAttribute('aria-hidden', 'true');
            };

            window.addEventListener('scroll', () => {
                if (window.scrollY > 30) {
                    header.classList.add('scrolled');
                } else {
                    header.classList.remove('scrolled');
                }
            });

            // === Cart Drawer ===
            cartTrigger?.addEventListener('click', openCart);
            cartTrigger?.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' || e.key === ' ') openCart();
            });

            document.querySelectorAll('[data-cart-close]').forEach(el => {
                el.addEventListener('click', closeCart);
            });

            document.addEventListener('keydown', (e) => {
                if (e.key === 'Escape') closeCart();
            });

            // === Embla Carousel (với Autoplay + Loop vô tận) ===
            const initUpsellCarousel = (root) => {
                const viewport = root.querySelector('[data-upsell-viewport]');
                if (!viewport) return;

                const prevBtn = root.querySelector('[data-upsell-prev]');
                const nextBtn = root.querySelector('[data-upsell-next]');

                // Cấu hình Embla Carousel với loop vô tận
                const options = {
                    loop: true,
                    align: 'center',    // Card luôn ở giữa
                    skipSnaps: false,
                    dragFree: true,
                    containScroll: false // Cho phép peek 2 bên
                };

                // Khởi tạo Embla với Autoplay plugin
                const embla = window.EmblaCarousel(viewport, options, [
                    window.EmblaCarouselAutoplay({
                        delay: 4000,                  // Tự động trượt sau 4s
                        stopOnInteraction: false,     // Tiếp tục khi người dùng click
                        stopOnMouseEnter: true        // Dừng khi hover chuột
                    })
                ]);

                // Navigation buttons
                prevBtn?.addEventListener('click', () => embla.scrollPrev());
                nextBtn?.addEventListener('click', () => embla.scrollNext());

                // Keyboard navigation
                viewport.addEventListener('keydown', (e) => {
                    if (e.key === 'ArrowLeft') embla.scrollPrev();
                    if (e.key === 'ArrowRight') embla.scrollNext();
                });

                // Responsive resize
                window.addEventListener('resize', () => embla.reInit());
            };

            // Đợi embla-carousel được tải từ CDN
            const checkEmblaLoaded = () => {
                if (typeof window.EmblaCarousel !== 'undefined' && typeof window.EmblaCarouselAutoplay !== 'undefined') {
                    document.querySelectorAll('[data-upsell-wrap]').forEach(initUpsellCarousel);
                } else {
                    setTimeout(checkEmblaLoaded, 100);
                }
            };
            checkEmblaLoaded();

            // === Quick Add: Quantity Controls (Event Delegation) ===
            document.addEventListener('click', (e) => {
                const btnMinus = e.target.closest('.quantity-button.qty-minus');
                const btnPlus = e.target.closest('.quantity-button.qty-plus');
                
                if (btnMinus) {
                    e.preventDefault(); e.stopPropagation();
                    const input = btnMinus.closest('.cart-quantity').querySelector('.quantity-input');
                    let val = parseInt(input.value) || 1;
                    if (val > 1) input.value = val - 1;
                } else if (btnPlus) {
                    e.preventDefault(); e.stopPropagation();
                    const input = btnPlus.closest('.cart-quantity').querySelector('.quantity-input');
                    let val = parseInt(input.value) || 1;
                    if (val < 99) input.value = val + 1;
                }
            });

            // Quantity Input keyboard focus/select & validation (Event Delegation)
            document.addEventListener('click', (e) => {
                const input = e.target.closest('.quantity-input');
                if (input) {
                    e.preventDefault(); e.stopPropagation();
                    input.focus();
                    input.select();
                }
            });

            document.addEventListener('change', (e) => {
                const input = e.target.closest('.quantity-input');
                if (input) {
                    let val = parseInt(input.value);
                    if (isNaN(val) || val < 1) input.value = 1;
                    if (val > 99) input.value = 99;
                }
            });

            document.addEventListener('keydown', (e) => {
                const input = e.target.closest('.quantity-input');
                if (input) {
                    e.stopPropagation();
                    if (e.key === 'Enter') {
                        e.preventDefault();
                        const addBtn = input.closest('form')?.querySelector('[type="submit"], .quick-add-submit');
                        if (addBtn) addBtn.click();
                    }
                }
            });

            // === Quick Add ADD Button Handler (Event Delegation) ===
            document.addEventListener('click', (e) => {
                const btn = e.target.closest('.quick-add-submit');
                if (!btn) return;
                e.preventDefault(); e.stopPropagation();

                // Thêm vào cart
                if (window.nhCart) {
                    const card = btn.closest('.card-wrapper');
                    const name = card?.querySelector('.card-heading-h5 a, .card-heading a')?.textContent?.trim() || 'Product';
                    const selectedVariant = card?.querySelector(
                        'input[type="radio"]:checked, select[name^="options"]'
                    )?.value || "";
                    const href = card?.querySelector('a')?.getAttribute('href') || window.location.pathname;
                    const priceEl = card?.querySelector('.good, .price-new, .price');
                    const gbp = priceEl ? parseFloat(priceEl.dataset.gbp || priceEl.textContent.replace(/[^0-9.]/g, '')) : 0;
                    const image = card?.querySelector('.card-media img')?.src || '';
                    const qty = parseInt(card?.querySelector('.quantity-input')?.value) || 1;
                    
                    const cart = window.nhCart.getCart();
                    const id = (name + selectedVariant).replace(/\s+/g, '-').toLowerCase();
                    const existing = cart.find(i => i.id === id);
                    if (existing) {
                        existing.qty += qty;
                    } else {
                        cart.push({ id, name, gbp, image, qty, variant: selectedVariant, href });
                    }
                    window.nhCart.saveCart(cart);
                    window.nhCart.renderCart();
                    window.nhCart.openCart(); // Mở giỏ hàng khi click ADD từ product card
                }

                // Visual effect
                const priceItem = btn.querySelector('.price-item');
                if (priceItem) priceItem.textContent = '✓ ADDED';
                btn.style.backgroundColor = '#6ab04c';
                btn.style.borderColor = '#6ab04c';
                setTimeout(() => {
                    if (priceItem) priceItem.textContent = 'ADD';
                    btn.style.backgroundColor = '';
                    btn.style.borderColor = '';
                }, 1200);
            });

            // === Add to Cart chính (product page) ===
            const mainForm = document.querySelector(
                '#product-form-template--26975595233570__main');
            const mainAddBtn = document.getElementById('btnadding');

            if (mainForm && mainAddBtn) {
                mainForm.addEventListener('submit', (e) => {
                    e.preventDefault();

                    // Lấy thông tin sản phẩm từ trang
                    const href  = window.location.pathname;
                    const name  = document.querySelector('.product-title h1, h1.title')?.textContent?.trim() || 'Product';
                    const priceEl = document.querySelector('span.price-sale, .price-new, .price-standard, .price');
                    const gbp   = priceEl ? parseFloat(priceEl.dataset.gbp || priceEl.textContent.replace(/[^0-9.]/g, '')) : 0;
                    const image = document.querySelector('.product__media img, .main-product-img')?.src || '';
                    const qty   = parseInt(document.querySelector('.quantity__input, .main-qty-input')?.value) || 1;
                    const checkedRadio = document.querySelector('variant-selects#variant-selects-template--26975595233570__main input:checked');
                    let selectedVariant = '';
                    if (checkedRadio) {
                        const labelEl = document.querySelector(`label[for="${checkedRadio.id}"]`);
                        if (labelEl) {
                            const clone = labelEl.cloneNode(true);
                            clone.querySelectorAll('.visually-hidden').forEach(el => el.remove());
                            selectedVariant = clone.textContent.trim();
                        } else {
                            selectedVariant = checkedRadio.value;
                        }
                    }

                    // Lưu vào cart
                    if (window.nhCart) {
                        const cart = window.nhCart.getCart();
                        const id = (name + (selectedVariant ? '-' + selectedVariant : '')).replace(/\s+/g, '-').toLowerCase();
                        const existing = cart.find(i => i.id === id);
                        if (existing) existing.qty += qty;
                        else cart.push({ id, name, gbp, image, qty, variant: selectedVariant, href });

                        window.nhCart.saveCart(cart);
                        window.nhCart.renderCart();
                        window.nhCart.openCart();

                        // Visual effect
                        const label = mainAddBtn.querySelector('.product-form__submit-label');
                        const originalText = label?.textContent;
                        if (label) label.textContent = '✓ Added!';
                        mainAddBtn.style.backgroundColor = '#6ab04c';
                        mainAddBtn.disabled = true;
                        setTimeout(() => {
                            if (label) label.textContent = originalText;
                            mainAddBtn.style.backgroundColor = '';
                            mainAddBtn.disabled = false;
                        }, 1500);
                    }
                });
            }
        }



