function initFeatures() {
  if (window.__featuresInitialized) return;
  window.__featuresInitialized = true;

  /* ============================================================
     CONSTANTS & HELPERS
     ============================================================ */
  const RATES = { GBP: 1, USD: 1.27, VND: 32000 };
  const SYMBOLS = { GBP: '£', USD: '$', VND: '₫' };
  const CART_KEY = 'nh_cart';
  const CURR_KEY = 'nh_currency';

  function getCart() { try { return JSON.parse(localStorage.getItem(CART_KEY)) || []; } catch (e) { return []; } }
  function saveCart(c) { localStorage.setItem(CART_KEY, JSON.stringify(c)); }
  function getCurrency() { return 'USD'; }
  function parseGBP(txt) { return parseFloat(String(txt).replace(/[^0-9.]/g, '')) || 0; }
  function formatPrice(gbp, code) {
    const val = gbp * 1.27; // Convert GBP to USD
    return '$' + val.toLocaleString(undefined, { 
        maximumFractionDigits: 2,
        minimumFractionDigits: 2
    });
  }

  /* Reference to existing openCart (from the original script) */
  function openCart() { document.body.classList.add('cart-open'); document.querySelector('.cart-drawer')?.setAttribute('aria-hidden', 'false'); }

  /* ============================================================
     1. CURRENCY — init dataset.gbp on every price element
     ============================================================ */
  function initPriceDatasets() {
    document.querySelectorAll('.price-new, .price-old, .price, .evil, .good, .price-regular span, .price-sale span, span.price-regular, span.price-sale, .price-standard').forEach(el => {
      if (!el.dataset.gbp) el.dataset.gbp = parseGBP(el.textContent);
    });
    document.querySelectorAll('.uPriceNow, .uPriceWas').forEach(el => {
      if (!el.dataset.gbp) {
        /* Detect if it looks like VND (> 500) */
        const raw = parseFloat(String(el.textContent).replace(/[^0-9.]/g, '')) || 0;
        el.dataset.gbp = raw > 500 ? (raw / RATES.VND) : raw;
      }
    });
  }

  function applyCurrency(code) {
    if (!RATES[code]) return;
    document.querySelectorAll('.price-new, .price-old, .price, .evil, .good, .price-regular span, .price-sale span, span.price-regular, span.price-sale, .price-standard').forEach(el => {
      el.textContent = formatPrice(parseFloat(el.dataset.gbp), code);
    });
    document.querySelectorAll('.uPriceNow, .uPriceWas').forEach(el => {
      el.textContent = formatPrice(parseFloat(el.dataset.gbp), code);
    });
    localStorage.setItem(CURR_KEY, code);
    renderCart();
  }

  /* Map disclosure link to currency code */
  function detectCurrency(txt) {
    const t = (txt || '').toLowerCase();
    if (t.includes('vnd') || t.includes('viet')) return 'VND';
    if (t.includes('usd') || t.includes('united states')) return 'USD';
    return 'GBP';
  }

  /* Toggle the country disclosure dropdown */
  const disclosureBtn = document.querySelector('.disclosure__button.localization-selector');
  const disclosureList = document.querySelector('.disclosure-list-wrapper.country-selector');
  const disclosureOverlay = document.querySelector('.country-selector-overlay');

  if (disclosureBtn && disclosureList) {
    disclosureBtn.addEventListener('click', function (e) {
      e.preventDefault();
      const isOpen = !disclosureList.hidden;
      disclosureList.hidden = isOpen;
      disclosureBtn.setAttribute('aria-expanded', String(!isOpen));
    });
    if (disclosureOverlay) {
      disclosureOverlay.addEventListener('click', () => {
        disclosureList.hidden = true;
        disclosureBtn.setAttribute('aria-expanded', 'false');
      });
    }
    const closeSmall = disclosureList.querySelector('button[aria-label="Close"]');
    if (closeSmall) {
      closeSmall.addEventListener('click', () => {
        disclosureList.hidden = true;
        disclosureBtn.setAttribute('aria-expanded', 'false');
      });
    }

    const searchInput = disclosureList.querySelector('input');
    if (searchInput) {
      searchInput.addEventListener('input', function (e) {
        const val = e.target.value.toLowerCase().trim();
        disclosureList.querySelectorAll('li').forEach(li => {
          const a = li.querySelector('a');
          if (a) {
            const name = a.querySelector('span:first-child');
            li.style.display = (name ? name.textContent : a.textContent).toLowerCase().includes(val) ? '' : 'none';
          }
        });
      });
      const form = searchInput.closest('form');
      if (form) form.addEventListener('submit', e => e.preventDefault());
    }

    if (!disclosureList.dataset.nhInit) {
      disclosureList.dataset.nhInit = '1';
      disclosureList.querySelectorAll('li').forEach(li => {
        const a = li.querySelector('a');
        if (!a || a.dataset.nhDone) return;
        a.dataset.nhDone = '1';

        const rawText = a.textContent.trim().replace(/GBP £|USD \$|VND ₫/g, '').trim();
        let curr = '', code = '';
        if (rawText === 'United Kingdom') { curr = 'GBP £'; code = 'GBP'; }
        else if (rawText === 'United States') { curr = 'USD $'; code = 'USD'; }
        else if (rawText === 'Vietnam') { curr = 'VND ₫'; code = 'VND'; }

        a.innerHTML = '';
        a.removeAttribute('style');
        a.className = 'nh-country-row';

        const nameSpan = document.createElement('span');
        nameSpan.textContent = rawText;
        a.appendChild(nameSpan);

        if (curr) {
          const currSpan = document.createElement('span');
          currSpan.className = 'nh-country-curr';
          currSpan.textContent = curr;
          a.appendChild(currSpan);
        }

        li.addEventListener('click', function (e) {
          e.preventDefault();
          disclosureList.hidden = true;
          disclosureBtn.setAttribute('aria-expanded', 'false');
          const btnSpan = disclosureBtn.querySelector('span');
          if (btnSpan) btnSpan.textContent = curr
            ? rawText + ' | ' + curr
            : rawText;
          if (code) applyCurrency(code);
        });
      });

      (function () {
        const btnSpan = disclosureBtn.querySelector('span');
        if (!btnSpan) return;
        const t = btnSpan.textContent.trim();
        const map = [
          ['United Kingdom', 'GBP £'],
          ['United States', 'USD $'],
          ['Vietnam', 'VND ₫'],
        ];
        for (const [name, sym] of map) {
          if (t.includes(name)) {
            btnSpan.textContent = name + ' | ' + sym;
            return;
          }
        }
      })();
    }
  }

  /* ============================================================
     2. CART — render + events
     ============================================================ */
  const wjItems = document.querySelector('.wjItems');
  const cartCountEl = document.getElementById('cartCount');
  const checkoutLabel = document.querySelector('.wjCheckoutLabel');
  const contentWrap = document.querySelector('.content[data-wj-body]');

  function renderCart() {
    const cart = getCart();
    const code = getCurrency();

    if (!cart.length) {
      if (wjItems) wjItems.innerHTML = '<div class="cart-empty">Your cart is empty.</div>';
      if (contentWrap) contentWrap.classList.add('isEmpty');
    } else {
      if (contentWrap) contentWrap.classList.remove('isEmpty');
      let html = '';
      cart.forEach(item => {
        const displayPrice = formatPrice(parseFloat(item.gbp), code);
        html += `
<div class="upsellRow" data-item-id="${item.id}"
  style="display:grid;width:100%;box-sizing:border-box;
  grid-template-columns:70px 1fr;
  grid-template-areas:'thumb details';
  border-radius:var(--uCardRadius);
  background:var(--upsellBlockBg);
  box-shadow:var(--upsellCardShadow,0 2px 6px rgba(0,0,0,.10));
  margin-bottom:10px;padding:10px;gap:0 10px;
  height:${item.variant ? '106px' : '96px'};overflow:hidden;align-items:stretch;">

  <a href="${item.href || '#'}"
    style="grid-area:thumb;width:70px;height:70px;border-radius:10px;
    overflow:hidden;background:#fff;display:block;flex-shrink:0;align-self:center;">
    <img src="${item.image}" alt="${item.name}" draggable="false"
      style="width:100%;height:100%;object-fit:contain;">
  </a>

  <div style="grid-area:details;display:flex;flex-direction:column;
    justify-content:space-between;min-width:0;height:100%;padding:4px 0;box-sizing:border-box;">

    <div style="display:flex;align-items:flex-start;gap:6px;min-width:0;">
      <div style="flex:1;min-width:0;">
        <span style="display:block;font-size:13px;font-weight:700;color:#492719;
        white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
          ${item.name}
        </span>
        ${item.variant
            ? `<span style="display:block;font-size:0.8rem;font-weight: 500; color:#848484;
              white-space:nowrap;overflow:hidden;text-overflow:ellipsis;line-height:1.2;">
              ${item.variant}</span>`
            : ''}
        <span style="display:block;font-size:0.9rem;font-weight:500;color:#492719;line-height: 1.2; margin-top: 2px">
          ${displayPrice}
        </span>
      </div>
      <button class="nh-item-delete" data-id="${item.id}"
        style="background:none;border:none;cursor:pointer;color:#492719;
        flex-shrink:0;padding:0;line-height:1;margin-top:1px;">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
          <path d="M21,4H17.9A5.009,5.009,0,0,0,13,0H11A5.009,5.009,0,0,0,6.1,4H3A1,1,0,0,0,3,6H4V19a5.006,5.006,0,0,0,5,5h6a5.006,5.006,0,0,0,5-5V6h1a1,1,0,0,0,0-2ZM11,2h2a3.006,3.006,0,0,1,2.829,2H8.171A3.006,3.006,0,0,1,11,2Zm7,17a3,3,0,0,1-3,3H9a3,3,0,0,1-3-3V6H18Z"/>
          <path d="M10,18a1,1,0,0,0,1-1V11a1,1,0,0,0-2,0v6A1,1,0,0,0,10,18Z"/>
          <path d="M14,18a1,1,0,0,0,1-1V11a1,1,0,0,0-2,0v6A1,1,0,0,0,14,18Z"/>
        </svg>
      </button>
    </div>

    <div style="display:flex;justify-content:flex-end;align-items:center;margin-top:auto;">
      <div style="display:inline-flex;align-items:center;gap:6px;
        background:#fff;border-radius:20px;padding:3px 5px;
        border:1px solid rgba(0,0,0,0.15);">
        <button class="nh-qty-btn" data-action="minus" data-id="${item.id}"
          style="background:none;border:none;cursor:pointer;color:#492719;
          width:20px;height:20px;display:flex;align-items:center;justify-content:center;padding:0;">
          <svg width="10" height="2" viewBox="0 0 10 2" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="0" y1="1" x2="10" y2="1"/></svg>
        </button>
        <span style="font-size:13px;color:#492719;min-width:16px;text-align:center;font-weight:400;">
          ${item.qty}
        </span>
        <button class="nh-qty-btn" data-action="plus" data-id="${item.id}"
          style="background:none;border:none;cursor:pointer;color:#492719;
          width:20px;height:20px;display:flex;align-items:center;justify-content:center;padding:0;">
          <svg width="10" height="10" viewBox="0 0 10 10" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="5" y1="0" x2="5" y2="10"/><line x1="0" y1="5" x2="10" y2="5"/></svg>
        </button>
      </div>
    </div>
  </div>
</div>`;
      });
      if (wjItems) wjItems.innerHTML = html;
    }

    /* Update cart count */
    const totalQty = cart.reduce((s, i) => s + i.qty, 0);
    if (cartCountEl) cartCountEl.textContent = totalQty;

    const cartIcon = document.querySelector('.nav-right .cart-trigger');
    if (cartIcon) {
      let badge = cartIcon.querySelector('.nh-cart-badge');
      if (totalQty > 0) {
        if (!badge) {
          badge = document.createElement('span');
          badge.className = 'nh-cart-badge';
          badge.style.cssText = 'position:absolute;top:-6px;right:-8px;' +
            'background:#e7963b;color:#fff;font-size:10px;font-weight:800;' +
            'min-width:18px;height:18px;border-radius:50%;display:flex;' +
            'align-items:center;justify-content:center;pointer-events:none;' +
            'box-shadow:0 1px 4px rgba(0,0,0,.25);font-family:inherit;';
          cartIcon.appendChild(badge);
        }
        badge.textContent = totalQty;
      } else if (badge) {
        badge.remove();
      }
    }

    /* Checkout label */
    const totalGBP = cart.reduce((s, i) => s + (parseFloat(i.gbp) * i.qty), 0);
    if (checkoutLabel) checkoutLabel.textContent = 'Checkout • ' + formatPrice(totalGBP, code);
  }

  /* Event delegation on .wjItems */
  if (wjItems) {
    wjItems.addEventListener('click', e => {
      const delBtn = e.target.closest('.nh-item-delete');
      const qtyBtn = e.target.closest('.nh-qty-btn');
      if (delBtn) {
        e.preventDefault(); e.stopPropagation();
        let cart = getCart().filter(i => i.id !== delBtn.dataset.id);
        saveCart(cart); renderCart();
      } else if (qtyBtn) {
        e.preventDefault(); e.stopPropagation();
        let cart = getCart();
        const item = cart.find(i => i.id === qtyBtn.dataset.id);
        if (item) {
          if (qtyBtn.dataset.action === 'plus') item.qty++;
          else { item.qty--; if (item.qty <= 0) cart = cart.filter(i => i.id !== item.id); }
          saveCart(cart); renderCart();
        }
      }
    });
  }

  /* Add to cart from product cards */
  document.querySelectorAll('.btn-add-cart').forEach(btn => {
    btn.addEventListener('click', function (e) {
      /* Don't prevent default — let existing listener run first for the "✓ ADDED" effect */
      const card = btn.closest('.product-card');
      if (!card) return;
      const name = card.querySelector('.product-name')?.textContent?.trim() || 'Product';
      const priceEl = card.querySelector('.price-new, .price, .good');
      const gbp = priceEl ? parseFloat(priceEl.dataset.gbp) : 0;
      const image = card.querySelector('.product-img-primary')?.src || '';
      const qty = parseInt(card.querySelector('.qty-input')?.value) || 1;
      const cart = getCart();
      const variantEl = card.querySelector('input[type="radio"]:checked, select[name^="options"]');
      const variant = variantEl?.value || '';
      const id = (name + variant).replace(/\s+/g, '-').toLowerCase();
      const existing = cart.find(i => i.id === id);
      if (existing) {
        existing.qty += qty;
      } else {
        const href = card.querySelector('a')?.getAttribute('href') || '';
        cart.push({ id, name, gbp, image, qty, variant, href });
      }
      saveCart(cart);
      renderCart();
      openCart();
    });
  });

  /* Upsell "Add" buttons */
  document.querySelectorAll('.uBtn[data-upsell-id]').forEach(btn => {
    btn.addEventListener('click', function () {
      const row = btn.closest('.upsellRow');
      if (!row) return;
      const name = row.querySelector('.uName')?.textContent?.trim() || 'Product';
      const priceEl = row.querySelector('.uPriceNow');
      const gbp = priceEl ? parseFloat(priceEl.dataset.gbp) : 0;
      const image = row.querySelector('.uThump img')?.src || '';
      const selectEl = row.querySelector('select');
      const variant = (selectEl?.options[selectEl?.selectedIndex]?.text?.trim() || '')
        .replace(/\s*variant sold out or unavailable\s*/gi, '').trim();        // ← đọc variant từ dropdown
      const cart = getCart();
      const id = (name + variant).replace(/\s+/g, '-').toLowerCase(); // ← id gồm cả variant
      const existing = cart.find(i => i.id === id);                    // ← match theo id, không chỉ name
      if (existing) {
        existing.qty += 1;
      } else {
        const foundProduct = typeof ALL_PRODUCTS !== 'undefined'
          ? ALL_PRODUCTS.find(p => p.name === name)
          : null;
        const href = foundProduct?.href || '';
        cart.push({ id, name, gbp, image, qty: 1, variant, href });
      }
      saveCart(cart);
      renderCart();
    });
  });

  /* ============================================================
     3. SEARCH — fullscreen overlay
     ============================================================ */
  /* Build product list from DOM */
  const NH_PRODUCTS = typeof ALL_PRODUCTS !== 'undefined' ? ALL_PRODUCTS : [];

  /* Các event mở/đóng search (giữ nguyên của bạn) */
  const navRight = document.querySelector('.nav-right');
  const searchIcon = navRight?.querySelectorAll('svg')[0];
  if (searchIcon) {
    searchIcon.id = 'nh-search-trigger';
    searchIcon.style.cursor = 'pointer';
    searchIcon.addEventListener('click', openSearch);
  }

  let searchDebounce = null;

  function openSearch() {
    if (document.getElementById('nh-search-overlay')) return;
    const overlay = document.createElement('div');
    overlay.id = 'nh-search-overlay';
    overlay.innerHTML = `
      <div id="nh-search-box">
        <div id="nh-search-input-wrap">
          <input id="nh-search-input" placeholder="Search" autocomplete="off">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#999" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        </div>
        <button id="nh-search-close">×</button>
        <div id="nh-search-results"></div>
      </div>`;
    document.body.appendChild(overlay);
    const input = document.getElementById('nh-search-input');
    setTimeout(() => input?.focus(), 50);

    /* BẮT SỰ KIỆN ENTER ĐỂ CHUYỂN SANG TRANG SEARCH MỚI */
    input.addEventListener('keypress', function (e) {
      if (e.key === 'Enter') {
        const query = input.value.trim();
        if (query) {
          window.location.href = `/Shopnew/search?q=${encodeURIComponent(query)}`;
        }
      }
    });

    // Close handlers (giữ nguyên của bạn)
    document.getElementById('nh-search-close').addEventListener('click', closeSearch);
    overlay.addEventListener('click', e => { if (e.target === overlay) closeSearch(); });

    input.addEventListener('input', () => {
      clearTimeout(searchDebounce);
      searchDebounce = setTimeout(() => doSearch(input.value.trim()), 150);
    });
  }

  function closeSearch() {
    document.getElementById('nh-search-overlay')?.remove();
    clearTimeout(searchDebounce);
  }

  document.addEventListener('keydown', e => { if (e.key === 'Escape') closeSearch(); });

  function doSearch(q) {
    const results = document.getElementById('nh-search-results');
    if (!results) return;
    if (!q) { results.innerHTML = ''; return; }

    const matches = NH_PRODUCTS
      .filter(p => p.name.toLowerCase().includes(q.toLowerCase()))
      .slice(0, 5);

    let productsHTML = '';
    matches.forEach(p => {
      productsHTML += `<a class="nh-result-item" href="${p.href}"><img src="${p.image}" width="48" height="48"><span>${p.name}</span></a>`;
    });

    // Nút Xem tất cả kết quả
    if (matches.length > 0) {
      productsHTML += `<a class="nh-view-all" href="/Shopnew/search?q=${encodeURIComponent(q)}" style="display:block; padding-top:10px; font-weight:bold; color:var(--primary-color, #142688);">View all results for "${q}" &rarr;</a>`;
    } else {
      productsHTML = '<p style="color:#999;font-size:13px">No products found.</p>';
    }

    const words = NH_PRODUCTS
      .map(p => p.name.split(' ')[0].toLowerCase())
      .filter((w, i, arr) => w.startsWith(q.toLowerCase()) && arr.indexOf(w) === i)
      .slice(0, 3);

    let suggestionsHTML = words.map(word => `<a class="nh-suggestion" href="/Shopnew/search?q=${encodeURIComponent(word)}">${word}</a>`).join('');
    if (!suggestionsHTML) suggestionsHTML = `<a class="nh-suggestion" href="/Shopnew/search?q=${encodeURIComponent(q)}">${q}</a>`;

    results.innerHTML = `
      <div id="nh-results-panel">
        <div id="nh-col-suggestions">
          <p class="nh-col-label">SUGGESTIONS</p>
          ${suggestionsHTML}
        </div>
        <div id="nh-col-products">
          <p class="nh-col-label">PRODUCTS</p>
          ${productsHTML}
        </div>
      </div>`;
  }

  /* ============================================================
     INIT — apply saved currency + render stored cart
     ============================================================ */
  initPriceDatasets();
  const saved = getCurrency();
  if (saved && saved !== 'GBP') applyCurrency(saved);
  renderCart();

  /* Set dynamic height for apparel cards hover animation */
  document.querySelectorAll('.product-card').forEach(card => {
    const qa = card.querySelector('.quick-add-controls');
    if (qa) {
      const h = qa.getBoundingClientRect().height || qa.offsetHeight;
      card.style.setProperty('--qa-height', h + 'px');
    }
  });
  // ============================================================
  //  AUTO-EXPAND PRODUCT FOOTER khi tên + giá quá dài
  // ============================================================
  function adjustCardFooters() {
    document.querySelectorAll('.card-wrapper').forEach(wrapper => {
      const footer = wrapper.querySelector('.product-footer');
      const inner  = wrapper.querySelector('.product-footer-inner');
      if (!footer || !inner) return;

      // Tạm thời tháo kẹp để đo chiều cao thật
      footer.style.height   = 'auto';
      footer.style.overflow = 'visible';
      const naturalH = inner.offsetHeight;
      // Gắn lại như cũ
      footer.style.height   = '';
      footer.style.overflow = '';

      if (naturalH > 40) {
        wrapper.classList.add('has-long-title');
      }
    });
  }
  window.nhCart = { saveCart, renderCart, getCart, openCart, formatPrice, getCurrency };
}

