document.addEventListener('DOMContentLoaded', () => {
    const urlParams = new URLSearchParams(window.location.search);
    const query = urlParams.get('q');

    const titleEl        = document.getElementById('search-title');
    const countEl        = document.getElementById('search-product-count');
    const gridEl         = document.getElementById('search-results-grid');
    const searchInputEl  = document.getElementById('search-input');
    const searchClearBtn = document.getElementById('search-clear-btn');
    const suggestionsBox = document.getElementById('inline-search-suggestions');
    const sortSelect     = document.getElementById('SortBy');
    const filterBtn      = document.getElementById('filter-btn');
    const filterDropdown = document.getElementById('filter-dropdown');
    const checkboxes     = document.querySelectorAll('.availability-cb');
    const selectedCountEl = document.getElementById('filter-selected-count');
    const resetBtn       = document.getElementById('filter-reset');
    const countInStockEl  = document.getElementById('count-in-stock');
    const countOutStockEl = document.getElementById('count-out-stock');

    // Điền lại giá trị vào ô tìm kiếm
    if (searchInputEl && query) searchInputEl.value = query;

    if (!query) {
        if (titleEl) titleEl.textContent = 'Please enter a search term';
        if (countEl) countEl.textContent = '0 products';
        return;
    }

    if (titleEl) titleEl.textContent = `Search: "${query}"`;

    // ── Lấy dữ liệu ──────────────────────────────────────────────────────────
    // Dùng trực tiếp như search2 — không bọc typeof để tránh silent fail
    const allResults = ALL_PRODUCTS.filter(p =>
        p.name.toLowerCase().includes(query.toLowerCase())
    );

    if (countInStockEl)  countInStockEl.textContent  = allResults.length;
    if (countOutStockEl) countOutStockEl.textContent = 0;

    // ── Render ────────────────────────────────────────────────────────────────
    // ── Render ────────────────────────────────────────────────────────────────
    const APPAREL_STANDARD = ['axolotl-family-tee', 'batrick-hoodie', 'lisa-tee', 'natural-habitat-crop-tee', 'natural-habitat-fall-hoodie', 'natural-habitat-line-art-hoodie', 'summer-hoodie'];
    const APPAREL_FULL = ['batrick-crewneck', 'batrick-the-bat-pocket-tee', 'robert-s-pancake-tee'];

    function renderResults(products) {
        if (countEl) countEl.textContent = `${products.length} products`;
        if (!gridEl) return;

        if (products.length === 0) {
            gridEl.innerHTML = '<p style="text-align:center;grid-column:1/-1;padding:50px;">No products found.</p>';
            return;
        }

        let html = '';
        products.forEach(product => {
            const isFull = APPAREL_FULL.includes(product.id);
            const isStandard = (APPAREL_STANDARD.includes(product.id) || product.isSizeEnabled === true || product.isSizeEnabled === 'true') && !isFull;
            
            let wrapperClass = 'card-wrapper';
            let quickAddHtml = '';
            
            if (isStandard || isFull) {
                wrapperClass += isFull ? ' has-variant-2' : ' has-variant';
                
                const sizes = isFull ? 
                    ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL', 'YXS', 'YS', 'YM', 'YL', 'YXL'] : 
                    ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL'];
                
                let sizesHtml = '';
                sizes.forEach((size, idx) => {
                    const optionId = `Option-search-${product.id}-${size}`;
                    const isChecked = idx === 0 ? 'checked=""' : '';
                    sizesHtml += `
                      <input ${isChecked} class="variant-option-input" data-option-position="1" id="${optionId}" name="options[Size]" type="radio" value="${size}"/>
                      <label aria-disabled="false" class="variant-label" data-option-position="1" data-option-value="${size}" for="${optionId}" title="${size}">${size}</label>
                    `;
                });
                
                quickAddHtml = `
                  <div class="quick-add-no-js">
                    <product-form data-section-id="search-results">
                      <form accept-charset="UTF-8" action="/cart/add" class="form" data-qa-form-init="true" data-type="add-to-cart-form" enctype="multipart/form-data" id="quick-add-template-${product.id}" method="post" novalidate="novalidate">
                        <input name="form_type" type="hidden" value="product"/>
                        <input name="utf8" type="hidden" value="✓"/>
                        <div class="variant-selects" data-section="search-product-grid" id="variant-selects-search-${product.id}">
                          <div aria-label="Size" class="variant-row" data-option-position="1" role="group">
                            <div class="variant-values">
                              ${sizesHtml}
                            </div>
                          </div>
                        </div>
                        <input class="product-variant-id" name="id" type="hidden" value="${product.variantId || ''}"/>
                        <div class="quick-add-actions">
                          <quantity-input class="cart-quantity">
                            <button class="quantity-button qty-minus" type="button">-</button>
                            <input class="quantity-input" max="99" min="1" type="number" value="1"/>
                            <button class="quantity-button qty-plus" type="button">+</button>
                          </quantity-input>
                          <button class="quick-add-submit" type="button">
                            <span class="price-item">ADD</span>
                          </button>
                        </div>
                      </form>
                    </product-form>
                  </div>`;
            }

            html += `
              <li class="grid-item">
                <div class="${wrapperClass}">
                  <div class="card-product">
                    <div class="card-inner-ratio">
                      <a href="${product.href}" class="product-card" style="text-decoration:none;color:inherit;">
                        <div class="card-media">
                          <img class="product-img-primary" src="${product.image}" alt="${product.name}">
                          <img src="${product.hoverImage}" alt="${product.name} Hover">
                        </div>
                      </a>
                      <div class="card-content">
                        <div class="card-information">
                          <h3 class="card-heading">
                            <a href="${product.href}" class="full-unstyled-link">${product.name}</a>
                          </h3>
                        </div>
                      </div>
                    </div>
                    <div class="product-footer">
                      <div class="product-details">
                        <div class="product-footer-inner">
                          <div class="heading-rating">
                            <h3 class="card-heading-h5">
                              <a href="${product.href}" class="full-unstyled-link">${product.name}</a>
                            </h3>
                          </div>
                          <div class="labubu">
                            ${product.compareAtPrice ? `<span class="price-old uPriceWas" data-gbp="${product.compareAtPrice}">$${(product.compareAtPrice * 1.27).toFixed(2)}</span>` : ''}
                            <span class="price-new uPriceNow" data-gbp="${product.price}">$${(product.price * 1.27).toFixed(2)}</span>
                          </div>
                        </div>
                        ${quickAddHtml}
                      </div>
                    </div>
                  </div>
                </div>
              </li>`;
        });

        gridEl.innerHTML = html;

        document.querySelectorAll('.price-new, .price-old').forEach(el => {
            if (!el.dataset.gbp) el.dataset.gbp = parseFloat(String(el.textContent).replace(/[^0-9.]/g, '')) || 0;
        });
        if (typeof initPriceDatasets === 'function') initPriceDatasets();
    }

    renderResults(allResults);
    
    // ── Sort ──────────────────────────────────────────────────────────────────
    if (sortSelect) {
        sortSelect.addEventListener('change', () => {
            const val = sortSelect.value;
            let sorted = [...allResults];
            if      (val === 'price-asc')  sorted.sort((a, b) => a.price - b.price);
            else if (val === 'price-desc') sorted.sort((a, b) => b.price - a.price);
            else if (val === 'name-asc')   sorted.sort((a, b) => a.name.localeCompare(b.name));
            else if (val === 'name-desc')  sorted.sort((a, b) => b.name.localeCompare(a.name));
            renderResults(sorted);
        });
    }

    // ── Filter ────────────────────────────────────────────────────────────────
    if (filterBtn && filterDropdown) {
        filterBtn.addEventListener('click', e => {
            e.stopPropagation();
            filterDropdown.style.display = filterDropdown.style.display === 'block' ? 'none' : 'block';
        });
        filterDropdown.addEventListener('click', e => e.stopPropagation());
        document.addEventListener('click', () => { filterDropdown.style.display = 'none'; });
    }

    function applyFilters() {
        const selected = Array.from(checkboxes).filter(cb => cb.checked).map(cb => cb.value);
        if (selectedCountEl) selectedCountEl.textContent = `${selected.length} selected`;

        const newFiltered = selected.length === 0 || selected.includes('in-stock')
            ? [...allResults] : [];

        const val = sortSelect ? sortSelect.value : 'relevance';
        let sorted = [...newFiltered];
        if      (val === 'price-asc')  sorted.sort((a, b) => a.price - b.price);
        else if (val === 'price-desc') sorted.sort((a, b) => b.price - a.price);
        else if (val === 'name-asc')   sorted.sort((a, b) => a.name.localeCompare(b.name));
        else if (val === 'name-desc')  sorted.sort((a, b) => b.name.localeCompare(a.name));
        renderResults(sorted);
    }

    checkboxes.forEach(cb => cb.addEventListener('change', applyFilters));
    if (resetBtn) {
        resetBtn.addEventListener('click', e => {
            e.preventDefault();
            checkboxes.forEach(cb => cb.checked = false);
            applyFilters();
        });
    }

    // ── Inline suggestions ────────────────────────────────────────────────────
    if (searchInputEl && suggestionsBox) {
        const toggleClear = () => {
            if (searchClearBtn)
                searchClearBtn.style.display = searchInputEl.value.trim() ? 'block' : 'none';
        };

        searchInputEl.addEventListener('input', e => {
            toggleClear();
            const val = e.target.value.toLowerCase().trim();
            if (!val) { suggestionsBox.style.display = 'none'; return; }

            const matched = ALL_PRODUCTS.filter(p => p.name.toLowerCase().includes(val)).slice(0, 5);

            if (matched.length > 0) {
                suggestionsBox.innerHTML = matched.map(p => `
                    <a href="${p.href}" class="nh-result-item">
                      <img src="${p.image}" class="nh-result-img" alt="${p.name}">
                      <div class="nh-result-info">
                        <span class="nh-result-name">${p.name}</span>
                        <span class="nh-result-price">$${(p.price * 1.27).toFixed(2)}</span>
                      </div>
                    </a>`).join('')
                + `<a href="/Shopnew/search?q=${encodeURIComponent(val)}"
                       style="display:block;text-align:center;padding:10px;background:#f5f5f5;
                              color:#333;text-decoration:none;font-size:14px;font-weight:bold;
                              border-top:1px solid #eee;">
                     View all results for "${val}"
                   </a>`;
                suggestionsBox.style.display = 'block';
            } else {
                suggestionsBox.innerHTML = `<div style="padding:15px;text-align:center;color:#666;">No results found for "${val}"</div>`;
                suggestionsBox.style.display = 'block';
            }
        });

        searchInputEl.addEventListener('focus', () => {
            if (searchInputEl.value.trim() && suggestionsBox.innerHTML)
                suggestionsBox.style.display = 'block';
        });

        document.addEventListener('click', e => {
            if (!searchInputEl.contains(e.target) && !suggestionsBox.contains(e.target))
                suggestionsBox.style.display = 'none';
        });

        if (searchClearBtn) {
            searchClearBtn.addEventListener('click', () => {
                searchInputEl.value = '';
                toggleClear();
                suggestionsBox.style.display = 'none';
                searchInputEl.focus();
            });
        }

        toggleClear();
    }
});