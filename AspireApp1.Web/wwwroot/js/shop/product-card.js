document.addEventListener('DOMContentLoaded', () => {
    function init() {
        if (typeof ALL_PRODUCTS === 'undefined') {
            setTimeout(init, 50);
            return;
        }
        renderGrid();
    }
    init();
});

function getCategoryName() {
    const featuredHeader = document.querySelector('.featured-header');
    const headerText = featuredHeader ? featuredHeader.textContent.trim().toLowerCase() : '';
    
    if (headerText.includes('apparel')) return 'Apparel';
    if (headerText.includes('accessories')) return 'Accessories';
    if (headerText.includes('plush')) return 'Plush';
    if (headerText.includes('stationery')) return 'Stationery';
    if (headerText.includes('bundle')) return 'Bundles';
    if (headerText.includes('game')) return 'Games';
    if (headerText.includes('gift card')) return 'Gift Cards';
    if (headerText.includes('new')) return 'New';
    
    // Fallback to title/pathname
    const pageTitle = document.title.toLowerCase();
    if (pageTitle.includes('apparel')) return 'Apparel';
    if (pageTitle.includes('accessories')) return 'Accessories';
    if (pageTitle.includes('plush')) return 'Plush';
    if (pageTitle.includes('stationery')) return 'Stationery';
    if (pageTitle.includes('bundle')) return 'Bundles';
    if (pageTitle.includes('game')) return 'Games';
    if (pageTitle.includes('gift card')) return 'Gift Cards';
    if (pageTitle.includes('new')) return 'New';

    return ''; // shop all
}

const formatPrice = (p) => {
    if (typeof p !== 'number') return `$${p}`;
    if (p % 1 === 0) return `$${p}`;
    return `$${p.toFixed(2)}`;
};

function generateProductHtml(product) {
    const isFull = ['batrick-crewneck', 'batrick-the-bat-pocket-tee', 'robert-s-pancake-tee', 'robert-tee'].includes(product.id);
    const isStandard = product.isSizeEnabled && !isFull;
    
    let wrapperClass = 'card-wrapper';
    let variantHtml = '';
    
    if (isFull || isStandard) {
        wrapperClass += isFull ? ' has-variant-2' : ' has-variant';
        const sizes = isFull ? 
            ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL', 'YXS', 'YS', 'YM', 'YL', 'YXL'] : 
            ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL'];
            
        let variantOptionsHtml = '';
        sizes.forEach((size, idx) => {
            const inputId = `Option-grid-${product.id}-${size}`;
            const checkedAttr = idx === 0 ? 'checked=""' : '';
            variantOptionsHtml += `
                <input ${checkedAttr} class="variant-option-input" data-option-position="1" id="${inputId}" name="options[Size]" type="radio" value="${size}"/>
                <label aria-disabled="false" class="variant-label" data-option-position="1" data-option-value="${size}" for="${inputId}" title="${size}">${size}</label>
            `;
        });
        
        variantHtml = `
            <div class="variant-selects" data-section="template-product-grid" id="variant-selects-${product.id}">
                <div aria-label="Size" class="variant-row" data-option-position="1" role="group">
                    <div class="variant-values">
                        ${variantOptionsHtml}
                    </div>
                </div>
            </div>
        `;
    }
    
    let priceHtml = '';
    if (product.compareAtPrice && product.compareAtPrice > product.price) {
        priceHtml = `
            <span class="evil">${formatPrice(product.compareAtPrice)}</span>
            <span class="good">${formatPrice(product.price)}</span>
        `;
    } else {
        priceHtml = `<span class="price">${formatPrice(product.price)}</span>`;
    }
    
    return `
<li class="grid-item" id="Slide-template" style="display: list-item;">
    <div class="${wrapperClass}">
        <div class="card-product">
            <div class="card-inner-ratio">
                <a class="product-card" href="${product.href}" style="text-decoration: none; color: inherit;">
                    <div class="card-media">
                        <img alt="${product.name}" class="product-img-primary" src="${product.image}"/>
                        <img alt="${product.name} Hover" src="${product.hoverImage}"/>
                    </div>
                </a>
                <div class="card-content">
                    <div class="card-information">
                        <h3 class="card-heading">
                            <a class="full-unstyled-link" href="${product.href}">${product.name}</a>
                        </h3>
                    </div>
                </div>
            </div>
            <div class="product-footer">
                <div class="product-details">
                    <div class="product-footer-inner">
                        <div class="heading-rating">
                            <h3 class="card-heading-h5">
                                <a class="full-unstyled-link" href="${product.href}">${product.name}</a>
                            </h3>
                        </div>
                        <div class="labubu">
                            ${priceHtml}
                        </div>
                    </div>
                    <div class="quick-add-no-js">
                        <product-form data-section-id="template-product-grid">
                            <form accept-charset="UTF-8" action="/cart/add" class="form" data-qa-form-init="true" data-type="add-to-cart-form" enctype="multipart/form-data" id="quick-add-form-${product.id}" method="post" novalidate="novalidate">
                                <input name="form_type" type="hidden" value="product"/>
                                <input name="utf8" type="hidden" value="✓"/>
                                ${variantHtml}
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
                    </div>
                </div>
            </div>
        </div>
    </div>
</li>
    `;
}

function renderGrid() {
    const gridEl = document.querySelector('.product-grid');
    if (!gridEl) return;
    
    const category = getCategoryName();
    let productsToRender = [];
    
    if (category) {
        productsToRender = ALL_PRODUCTS.filter(p => p.category && p.category.toLowerCase() === category.toLowerCase());
    } else {
        productsToRender = ALL_PRODUCTS;
    }
    
    if (productsToRender.length === 0) {
        gridEl.innerHTML = '<p style="text-align:center;grid-column:1/-1;padding:50px;color:#72441c;font-family:\'Fredoka\',sans-serif;font-size:18px;">No products found in this category.</p>';
        return;
    }
    
    gridEl.innerHTML = productsToRender.map(generateProductHtml).join('');
    
    // Initialize pagination
    initPagination(gridEl);
}

function initPagination(gridEl) {
    const products = gridEl.querySelectorAll('.grid-item');
    const itemsPerPage = 12; 
    const totalPages = Math.ceil(products.length / itemsPerPage);
    let currentPage = 1;

    const paginationContainer = document.getElementById('pagination-container');

    if (!products.length || totalPages <= 1) {
        if (paginationContainer) paginationContainer.style.display = 'none';
        products.forEach(p => p.style.display = 'list-item');
        return;
    }

    if (paginationContainer) paginationContainer.style.display = 'flex';

    function renderPagination() {
        if (!paginationContainer) return;
        paginationContainer.innerHTML = ''; 

        // Prev Link (<)
        if (currentPage > 1) {
            const prevLink = document.createElement('a');
            prevLink.href = "javascript:void(0)";
            prevLink.className = 'btn-prev';
            prevLink.textContent = '<';
            prevLink.onclick = () => {
                currentPage--;
                updateView();
            };
            paginationContainer.appendChild(prevLink);
        }

        // Page Links
        for (let i = 1; i <= totalPages; i++) {
            const pageLink = document.createElement('a');
            pageLink.href = "javascript:void(0)";
            pageLink.className = `page-num ${i === currentPage ? 'active' : ''}`;
            pageLink.textContent = i;
            pageLink.onclick = () => {
                if (i !== currentPage) {
                    currentPage = i;
                    updateView();
                }
            };
            paginationContainer.appendChild(pageLink);
        }

        // Next Link (>)
        if (currentPage < totalPages) {
            const nextLink = document.createElement('a');
            nextLink.href = "javascript:void(0)";
            nextLink.className = 'btn-next';
            nextLink.textContent = '>';
            nextLink.onclick = () => {
                currentPage++;
                updateView();
            };
            paginationContainer.appendChild(nextLink);
        }
    }

    function updateView() {
        const startIndex = (currentPage - 1) * itemsPerPage;
        const endIndex = startIndex + itemsPerPage;

        products.forEach((product, index) => {
            if (index >= startIndex && index < endIndex) {
                product.style.display = 'list-item';
            } else {
                product.style.display = 'none';
            }
        });

        renderPagination(); 

        window.scrollTo({
            top: gridEl.offsetTop - 100,
            behavior: 'smooth'
        });
    }

    updateView();
}