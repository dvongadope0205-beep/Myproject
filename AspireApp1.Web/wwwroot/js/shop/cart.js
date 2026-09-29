/* ═══════════════════════════════════════════
   CART PAGE — cart.js (Đã sửa lỗi NaN & Đồng bộ)
   Reads/writes localStorage "nh_cart" and "nh_order_note"
   ═══════════════════════════════════════════ */

(function () {
  'use strict';

  const CART_KEY = 'nh_cart';
  const NOTE_KEY = 'nh_order_note';

  /* ── DOM refs ── */
  const elEmpty       = document.getElementById('cart-empty');
  const elFilled      = document.getElementById('cart-filled');
  const elItemsList   = document.getElementById('cart-items-list');
  const elSubtotal    = document.getElementById('summary-subtotal');
  const elOrderNotes  = document.getElementById('order-notes');

  /* ══════════════════════════════════════════
     HELPERS
     ══════════════════════════════════════════ */
  function getCart() {
    try {
      return JSON.parse(localStorage.getItem(CART_KEY)) || [];
    } catch {
      return [];
    }
  }

  function saveCart(cart) {
    localStorage.setItem(CART_KEY, JSON.stringify(cart));
    // Kích hoạt sự kiện toàn cục để cập nhật các thành phần khác như Cart Drawer
    window.dispatchEvent(new CustomEvent('cart-updated'));
  }

  // HÀM TỰ ĐỘNG TẠO LINK (Đồng bộ với shopping-cart.js)
  function slugify(name) {
    return (name || '').toLowerCase()
        .trim()
        .replace(/[^\w\s-]/g, '')
        .replace(/[\s_-]+/g, '-')
        .replace(/^-+|-+$/g, '') + '.html';
  }

  // ĐỊNH DẠNG TIỀN TỆ ĐA QUỐC GIA (Đồng bộ với shopping-cart.js)
  function formatMoney(amount) {
    const rate = 1.27; // Convert GBP to USD
    const val = amount * rate;
    return '$' + val.toLocaleString(undefined, { 
        maximumFractionDigits: 2,
        minimumFractionDigits: 2
    });
  }

  /* ══════════════════════════════════════════
     RENDER
     ══════════════════════════════════════════ */
  function render() {
    const cart = getCart();

    if (cart.length === 0) {
      if (elEmpty) elEmpty.style.display = '';
      if (elFilled) elFilled.style.display = 'none';
      return;
    }

    if (elEmpty) elEmpty.style.display = 'none';
    if (elFilled) elFilled.style.display = '';

    /* Build item rows */
    let html = '';
    let subtotal = 0;

    cart.forEach(function (item, idx) {
      // Cơ chế Fallback phòng ngừa lỗi NaN tuyệt đối: Thử cả hai cấu trúc khóa gbp/price và qty/quantity
      const price = parseFloat(item.gbp) || parseFloat(item.price) || 0;
      const quantity = parseInt(item.qty) || parseInt(item.quantity) || 1;
      const lineTotal = price * quantity;
      subtotal += lineTotal;

      // Ưu tiên dùng item.href có sẵn, nếu không có thì tự tạo từ tên sản phẩm
      const itemLink = item.href || slugify(item.name);

      /* Price display */
      let priceHtml = '<span class="cart-item-price">' + formatMoney(price) + '</span>';
      if (item.compareAtPrice) {
        const comparePrice = parseFloat(item.compareAtPrice) || 0;
        if (comparePrice > 0) {
          priceHtml += ' <span class="cart-item-compare-price">' + formatMoney(comparePrice) + '</span>';
        }
      }

      html += '' +
        '<div class="cart-item" data-idx="' + idx + '">' +
          '<img class="cart-item-thumb" src="' + (item.image || '') + '" alt="' + (item.name || '') + '">' +
          '<div class="cart-item-details">' +
            '<a class="cart-item-name" href="' + itemLink + '">' + (item.name || 'Product') + '</a>' +
            (item.variant ? '<div class="item-variant" style="font-size:0.9rem; color:#919090; margin-top: 2px; font-weight: 500">Size: ' + item.variant + '</div>' : '') +
            '<div class="cart-item-price-row">' + priceHtml + '</div>' +
            '<div class="cart-item-qty-row">' +
              '<button class="qty-btn qty-minus" data-idx="' + idx + '" aria-label="Decrease quantity">−</button>' +
              '<input class="qty-input" type="number" min="1" value="' + quantity + '" data-idx="' + idx + '" aria-label="Quantity">' +
              '<button class="qty-btn qty-plus" data-idx="' + idx + '" aria-label="Increase quantity">+</button>' +
            '</div>' +
            '<div class="cart-item-line-total">Total: ' + formatMoney(lineTotal) + '</div>' +
          '</div>' +
          '<button class="cart-item-remove" data-idx="' + idx + '" aria-label="Remove item">Remove ✕</button>' +
        '</div>' +
        '<hr class="cart-item-hr">';
    });

    if (elItemsList) elItemsList.innerHTML = html;
    if (elSubtotal) elSubtotal.textContent = formatMoney(subtotal);

    /* Bind events for this render */
    bindItemEvents();
  }

  /* ══════════════════════════════════════════
     ITEM EVENTS (quantity ± , input, remove)
     ══════════════════════════════════════════ */
  function bindItemEvents() {
    if (!elItemsList) return;

    /* Minus buttons */
    elItemsList.querySelectorAll('.qty-minus').forEach(function (btn) {
      btn.addEventListener('click', function () {
        changeQty(Number(this.dataset.idx), -1);
      });
    });

    /* Plus buttons */
    elItemsList.querySelectorAll('.qty-plus').forEach(function (btn) {
      btn.addEventListener('click', function () {
        changeQty(Number(this.dataset.idx), 1);
      });
    });

    /* Direct input */
    elItemsList.querySelectorAll('.qty-input').forEach(function (input) {
      input.addEventListener('change', function () {
        var val = parseInt(this.value, 10);
        if (isNaN(val) || val < 1) val = 1;
        setQty(Number(this.dataset.idx), val);
      });
    });

    /* Remove buttons */
    elItemsList.querySelectorAll('.cart-item-remove').forEach(function (btn) {
      btn.addEventListener('click', function () {
        removeItem(Number(this.dataset.idx));
      });
    });
  }

  function changeQty(idx, delta) {
    var cart = getCart();
    if (!cart[idx]) return;
    var currentQty = parseInt(cart[idx].qty) || parseInt(cart[idx].quantity) || 1;
    var newQty = currentQty + delta;
    if (newQty < 1) newQty = 1;
    
    // Lưu đè cả 2 định dạng thuộc tính để tương thích hoàn toàn với mọi script khác trên website
    cart[idx].qty = newQty;
    cart[idx].quantity = newQty;
    
    saveCart(cart);
    render();
  }

  function setQty(idx, qty) {
    var cart = getCart();
    if (!cart[idx]) return;
    
    cart[idx].qty = qty;
    cart[idx].quantity = qty;
    
    saveCart(cart);
    render();
  }

  function removeItem(idx) {
    var cart = getCart();
    if (!cart[idx]) return;
    cart.splice(idx, 1);
    saveCart(cart);
    render();
  }

  /* ══════════════════════════════════════════
     ORDER NOTES — auto-expand + save
     ══════════════════════════════════════════ */
  function initNotes() {
    if (!elOrderNotes) return;
    /* Load saved note */
    var saved = localStorage.getItem(NOTE_KEY);
    if (saved) {
      elOrderNotes.value = saved;
      autoExpand(elOrderNotes);
    }

    elOrderNotes.addEventListener('input', function () {
      localStorage.setItem(NOTE_KEY, this.value);
      autoExpand(this);
    });
  }

  function autoExpand(el) {
    el.style.height = 'auto';
    el.style.height = el.scrollHeight + 'px';
  }

  /* ══════════════════════════════════════════
     INIT
     ══════════════════════════════════════════ */
  window.addEventListener('cart-updated', render);
  render();
  initNotes();
})();