(function(){
  'use strict';

  /* ─── CONSTANTS ─── */
  var RATES   = { GBP: 1.27, USD: 1.00 }; // Convert GBP to USD at 1.27 rate
  var SHIPPING_OPTIONS = [
    { label: 'Standard Shipping', price: 6.90 },
    { label: 'Priority Shipping', price: 15.00 }
  ];

  /* ─── HELPERS ─── */
  function getCart() { 
    try { 
      return JSON.parse(localStorage.getItem('nh_cart')) || []; 
    } catch(e) { 
      return []; 
    } 
  }

  function saveCart(cart) {
    localStorage.setItem('nh_cart', JSON.stringify(cart));
    // Trigger global event to sync with Layout's cart drawer
    window.dispatchEvent(new CustomEvent('cart-updated'));
  }

  function getSelectedCountry() {
    var countrySelect = document.getElementById('country');
    return countrySelect ? countrySelect.value : 'US';
  }

  function fmt(val) {
    return '$' + val.toFixed(2);
  }

  function conv(gbp) { 
    return gbp * RATES.GBP; 
  }

  /* ─── DOM ELEMENTS ─── */
  var countrySelect  = document.getElementById('country');
  var subtotalEl     = document.getElementById('summary-subtotal');
  var shippingCostEl = document.getElementById('summary-shipping');
  var totalEl        = document.getElementById('summary-total');
  var itemsEl        = document.getElementById('summary-items');
  var payBtn         = document.getElementById('pay-btn-bottom');

  // Create shipping options container dynamically inside summary card
  var shippingWrap = document.createElement('div');
  shippingWrap.id = 'shipping-options';
  shippingWrap.className = 'shipping-options-wrap';
  shippingWrap.style.marginTop = '15px';
  shippingWrap.style.marginBottom = '15px';
  
  var discountRow = document.querySelector('.discount-row');
  if (discountRow) {
    discountRow.parentNode.insertBefore(shippingWrap, discountRow);
  }

  /* ═══════ RENDER ITEMS ═══════ */
  function renderItems() {
    var cart = getCart();

    if (!itemsEl) return;
    if (!cart.length) { 
      itemsEl.innerHTML = '<p style="color:#999;font-size:14px;text-align:center;padding:24px 0">Your cart is empty.</p>'; 
      if (subtotalEl) subtotalEl.textContent = fmt(0);
      if (shippingCostEl) shippingCostEl.textContent = fmt(0);
      if (totalEl) totalEl.textContent = fmt(0);
      return; 
    }

    itemsEl.innerHTML = cart.map(function(it, idx) {
      var p = conv(parseFloat(it.gbp) || 0);
      var itemTotal = p * it.qty;
      return '<div class="summary-item" data-idx="' + idx + '">' +
        '<div class="item-thumb">' +
          '<img src="' + it.image + '" alt="' + it.name + '">' +
        '</div>' +
        '<div class="item-info">' +
          '<div class="item-name">' + it.name + '</div>' +
          (it.variant ? '<div class="item-variant">Size: ' + it.variant + '</div>' : '') +
          '<div class="item-qty-actions">' +
            '<button class="checkout-qty-btn checkout-qty-minus" data-idx="' + idx + '">−</button>' +
            '<input class="checkout-qty-input" type="number" min="1" max="99" value="' + it.qty + '" data-idx="' + idx + '">' +
            '<button class="checkout-qty-btn checkout-qty-plus" data-idx="' + idx + '">+</button>' +
            '<button class="checkout-item-remove" data-idx="' + idx + '">✕ Remove</button>' +
          '</div>' +
        '</div>' +
        '<div class="item-price">' + fmt(itemTotal) + '</div>' +
      '</div>';
    }).join('');
  }

  /* ═══════ RENDER SHIPPING OPTIONS ═══════ */
  function renderShipping() {
    if (!shippingWrap) return;

    shippingWrap.innerHTML = SHIPPING_OPTIONS.map(function(o, i) {
      return '<label class="shipping-option' + (i === 0 ? ' selected' : '') + '" style="display:flex; justify-content:space-between; padding:12px; border:2px solid #eee; border-radius:10px; margin-bottom:8px; cursor:pointer;">' +
        '<span>' +
          '<input type="radio" name="shipping" value="' + i + '"' + (i === 0 ? ' checked' : '') + ' style="margin-right:10px;" />' +
          '<span class="ship-label">' + o.label + '</span>' +
        '</span>' +
        '<span class="ship-price">' + fmt(o.price) + '</span>' +
      '</label>';
    }).join('');

    // Bind change listeners to shipping options
    var radios = shippingWrap.querySelectorAll('input[name=shipping]');
    radios.forEach(function(r) {
      r.addEventListener('change', function() {
        shippingWrap.querySelectorAll('.shipping-option').forEach(function(el) { 
          el.classList.remove('selected'); 
          el.style.borderColor = '#eee';
          el.style.background = '#fff';
        });
        var label = this.closest('.shipping-option');
        label.classList.add('selected');
        label.style.borderColor = '#72441c';
        label.style.background = '#faf6f0';
        updateTotals();
      });
    });

    // Style first option since it's checked by default
    var firstOption = shippingWrap.querySelector('.shipping-option.selected');
    if (firstOption) {
      firstOption.style.borderColor = '#72441c';
      firstOption.style.background = '#faf6f0';
    }
  }

  /* ═══════ UPDATE TOTALS ═══════ */
  function updateTotals() {
    var cart = getCart();

    var subUSD = 0;
    cart.forEach(function(it) { 
      subUSD += conv(parseFloat(it.gbp) || 0) * it.qty; 
    });

    var sel = shippingWrap ? shippingWrap.querySelector('input[name=shipping]:checked') : null;
    var idx = sel ? parseInt(sel.value) : 0;
    var ship = SHIPPING_OPTIONS[idx] ? SHIPPING_OPTIONS[idx].price : 0;

    var total = subUSD + ship;

    if (subtotalEl)     subtotalEl.textContent  = fmt(subUSD);
    if (shippingCostEl) shippingCostEl.textContent = fmt(ship);
    if (totalEl)        totalEl.textContent = fmt(total);

    renderItems();
  }

  /* ═══════ EVENT DELEGATION FOR ITEMS ═══════ */
  if (itemsEl) {
    itemsEl.addEventListener('click', function(e) {
      var target = e.target;
      var idx = parseInt(target.getAttribute('data-idx'), 10);
      if (isNaN(idx)) return;

      var cart = getCart();
      if (!cart[idx]) return;

      if (target.classList.contains('checkout-qty-minus')) {
        if (cart[idx].qty > 1) {
          cart[idx].qty--;
          cart[idx].quantity = cart[idx].qty;
          saveCart(cart);
          updateTotals();
        }
      } else if (target.classList.contains('checkout-qty-plus')) {
        if (cart[idx].qty < 99) {
          cart[idx].qty++;
          cart[idx].quantity = cart[idx].qty;
          saveCart(cart);
          updateTotals();
        }
      } else if (target.classList.contains('checkout-item-remove')) {
        cart.splice(idx, 1);
        saveCart(cart);
        updateTotals();
      }
    });

    itemsEl.addEventListener('change', function(e) {
      var target = e.target;
      if (target.classList.contains('checkout-qty-input')) {
        var idx = parseInt(target.getAttribute('data-idx'), 10);
        if (isNaN(idx)) return;

        var cart = getCart();
        if (!cart[idx]) return;

        var val = parseInt(target.value, 10);
        if (isNaN(val) || val < 1) val = 1;
        if (val > 99) val = 99;

        cart[idx].qty = val;
        cart[idx].quantity = val;
        saveCart(cart);
        updateTotals();
      }
    });
  }

  /* ═══════ COUNTRY CHANGE EVENT ═══════ */
  if (countrySelect) {
    countrySelect.addEventListener('change', function() {
      updateTotals();
    });
  }

  /* ─── DYNAMIC PREMIUM MODALS ─── */
  function showPremiumModal(title, contentHTML, buttons) {
    var existing = document.getElementById('nhs-premium-modal');
    if (existing) existing.remove();

    var overlay = document.createElement('div');
    overlay.id = 'nhs-premium-modal';
    overlay.className = 'premium-modal-overlay';

    if (!document.getElementById('nhs-premium-styles')) {
      var style = document.createElement('style');
      style.id = 'nhs-premium-styles';
      style.textContent = `
        .premium-modal-overlay {
          position: fixed;
          top: 0; left: 0; width: 100%; height: 100%;
          background: rgba(0, 0, 0, 0.6);
          backdrop-filter: blur(8px);
          display: flex; align-items: center; justify-content: center;
          z-index: 99999;
          opacity: 0; transition: opacity 0.3s ease;
        }
        .premium-modal-overlay.active { opacity: 1; }
        .premium-modal-card {
          background: #fff; border-radius: 16px;
          width: 90%; max-width: 480px; padding: 30px;
          box-shadow: 0 20px 40px rgba(0,0,0,0.25);
          transform: scale(0.9); transition: transform 0.3s ease;
          font-family: 'Fredoka', sans-serif; color: #492719;
          border: 2px solid rgb(114, 68, 28);
          position: relative;
        }
        .premium-modal-overlay.active .premium-modal-card { transform: scale(1); }
        .premium-modal-header {
          display: flex; align-items: center; justify-content: space-between;
          margin-bottom: 20px;
        }
        .premium-modal-title { font-size: 22px; font-weight: 600; color: rgb(114, 68, 28); }
        .premium-modal-close {
          background: none; border: none; font-size: 24px; cursor: pointer; color: #999;
          line-height: 1;
        }
        .premium-modal-close:hover { color: #333; }
        .premium-modal-body { font-size: 15px; line-height: 1.6; margin-bottom: 24px; color: #555; }
        .premium-modal-footer { display: flex; justify-content: flex-end; gap: 12px; }
        .premium-modal-btn {
          padding: 12px 24px; border-radius: 8px; font-size: 14px; font-weight: 600;
          cursor: pointer; transition: all 0.2s; font-family: 'Fredoka', sans-serif;
        }
        .premium-modal-btn-primary { background: rgb(114, 68, 28); color: #fff; border: none; }
        .premium-modal-btn-primary:hover { opacity: 0.9; transform: translateY(-1px); }
        .premium-modal-btn-secondary { background: #f5f5f5; color: #333; border: 1px solid #d9d9d9; }
        .premium-modal-btn-secondary:hover { background: #e8e8e8; }
        .validation-errors-list { list-style: none; padding: 0; margin: 15px 0 0; }
        .validation-errors-list li {
          position: relative; padding-left: 20px; margin-bottom: 8px; color: #d93838; font-size: 14px;
          text-align: left;
        }
        .validation-errors-list li::before {
          content: '•'; position: absolute; left: 5px; color: #d93838; font-size: 16px;
        }
        .success-checkmark {
          width: 80px; height: 80px; margin: 0 auto 20px;
          border-radius: 50%; background: #ebf7ee;
          display: flex; align-items: center; justify-content: center;
          color: #2e7d32; font-size: 40px;
        }
      `;
      document.head.appendChild(style);
    }

    var card = document.createElement('div');
    card.className = 'premium-modal-card';

    var header = document.createElement('div');
    header.className = 'premium-modal-header';
    
    var titleEl = document.createElement('span');
    titleEl.className = 'premium-modal-title';
    titleEl.textContent = title;
    
    var closeBtn = document.createElement('button');
    closeBtn.className = 'premium-modal-close';
    closeBtn.innerHTML = '×';
    closeBtn.onclick = function() {
      overlay.classList.remove('active');
      setTimeout(function() { overlay.remove(); }, 300);
    };

    header.appendChild(titleEl);
    header.appendChild(closeBtn);

    var body = document.createElement('div');
    body.className = 'premium-modal-body';
    body.innerHTML = contentHTML;

    var footer = document.createElement('div');
    footer.className = 'premium-modal-footer';

    buttons.forEach(function(btnSpec) {
      var btn = document.createElement('button');
      btn.className = 'premium-modal-btn ' + (btnSpec.primary ? 'premium-modal-btn-primary' : 'premium-modal-btn-secondary');
      btn.textContent = btnSpec.text;
      btn.onclick = function() {
        if (btnSpec.click) {
          btnSpec.click(overlay);
        } else {
          overlay.classList.remove('active');
          setTimeout(function() { overlay.remove(); }, 300);
        }
      };
      footer.appendChild(btn);
    });

    card.appendChild(header);
    card.appendChild(body);
    card.appendChild(footer);
    overlay.appendChild(card);
    document.body.appendChild(overlay);

    setTimeout(function() { overlay.classList.add('active'); }, 10);
    
    overlay.onclick = function(e) {
      if (e.target === overlay) {
        overlay.classList.remove('active');
        setTimeout(function() { overlay.remove(); }, 300);
      }
    };
  }

  /* ═══════ PAYMENT FLOW ═══════ */
  function submitOrderToServer(paymentMethod, paymentStatus, transactionRef, successCallback) {
    var cart = getCart();
    var subUSD = 0;
    var items = cart.map(function(it) {
      var p = conv(parseFloat(it.gbp) || 0);
      subUSD += p * it.qty;
      return {
        name: it.name + (it.variant ? ' (Size: ' + it.variant + ')' : ''),
        qty: it.qty,
        price: p
      };
    });

    var sel = shippingWrap ? shippingWrap.querySelector('input[name=shipping]:checked') : null;
    var idx = sel ? parseInt(sel.value) : 0;
    var ship = SHIPPING_OPTIONS[idx] ? SHIPPING_OPTIONS[idx].price : 0;
    var total = subUSD + ship;

    var orderData = {
      fullName: (document.getElementById('fullName')?.value || '').trim(),
      email: (document.getElementById('email')?.value || '').trim(),
      phone: (document.getElementById('phone')?.value || '').trim(),
      address: (document.getElementById('address')?.value || '').trim() + ', ' + 
               (document.getElementById('city')?.value || '').trim() + ', ' + 
               (document.getElementById('postcode')?.value || '').trim() + ', ' + 
               getSelectedCountry(),
      totalAmount: total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      transactionRef: transactionRef,
      items: items
    };

    fetch('/Shopnew/checkout?handler=PlaceOrder', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'RequestVerificationToken': document.querySelector('input[name="__RequestVerificationToken"]')?.value || ''
      },
      body: JSON.stringify(orderData)
    })
    .then(function(res) { return res.json(); })
    .then(function(result) {
      if (result.success) {
        successCallback(transactionRef, orderData.totalAmount, orderData.email, orderData.address, orderData.fullName);
      } else {
        alert("Error saving order: " + result.message);
      }
    })
    .catch(function(err) {
      alert("An error occurred while saving the order. Please try again.");
      console.error(err);
    });
  }

  function showSuccessModal(refId, totalVal, emailVal, addressVal, fullName) {
    var formattedTotal = fmt(totalVal);
    var isPending = refId.indexOf('CASH') === 0;

    var successHTML = '<div style="text-align:center;">' +
      '<div class="success-checkmark" style="background: ' + (isPending ? '#fff8e1' : '#ebf7ee') + '; color: ' + (isPending ? '#f57f17' : '#2e7d32') + ';">' + (isPending ? '⏳' : '✓') + '</div>' +
      '<h3 style="color: ' + (isPending ? '#f57f17' : '#2e7d32') + '; margin-bottom: 12px; font-size: 20px;">' + (isPending ? 'Order Placed (Pending Approval)' : 'Order Placed Successfully!') + '</h3>' +
      '<p>Thank you for shopping at Natural Habitat Store. Your order has been recorded.</p>' +
      '<div style="background: #f7f7f7; border-radius: 8px; padding: 15px; margin: 15px 0; font-size: 14px; text-align: left; line-height: 1.6; color:#492719;">' +
        '<strong>Order Reference:</strong> <span style="font-family: monospace; color: rgb(114,68,28); font-weight:700;">' + refId + '</span><br>' +
        '<strong>Total:</strong> ' + formattedTotal + '<br>' +
        '<strong>Confirmation Email:</strong> ' + emailVal + '<br>' +
        '<strong>Shipping Address:</strong> ' + addressVal + '<br>' +
        '<strong>Recipient:</strong> ' + fullName + '<br>' +
        '<strong>Payment Status:</strong> <span style="font-weight:700; color:' + (isPending ? '#f57f17' : '#2e7d32') + ';">' + (isPending ? 'Pending Approval' : 'Completed') + '</span>' +
      '</div>' +
      '<p style="font-size: 13px; color: #666;">' + (isPending ? 'Our admin will review your order shortly.' : 'We will send tracking details to your email shortly.') + '</p>' +
    '</div>';

    showPremiumModal("Order Confirmed", successHTML, [
      {
        text: "Back to Shop",
        primary: true,
        click: function(successOverlay) {
          // Clear cart
          localStorage.removeItem('nh_cart');
          window.dispatchEvent(new CustomEvent('cart-updated'));

          successOverlay.classList.remove('active');
          setTimeout(function() {
            successOverlay.remove();
            window.location.href = '/Shopnew';
          }, 300);
        }
      }
    ]);
  }

  function simulateQRCodePayment() {
    var refId = 'QR-' + Math.random().toString(36).substring(2, 10).toUpperCase();
    var cart = getCart();
    var subUSD = 0;
    cart.forEach(function(it) { 
      subUSD += conv(parseFloat(it.gbp) || 0) * it.qty; 
    });
    var sel = shippingWrap ? shippingWrap.querySelector('input[name=shipping]:checked') : null;
    var idx = sel ? parseInt(sel.value) : 0;
    var ship = SHIPPING_OPTIONS[idx] ? SHIPPING_OPTIONS[idx].price : 0;
    var totalAmount = subUSD + ship;

    var qrOverlay = document.createElement('div');
    qrOverlay.style.position = 'fixed';
    qrOverlay.style.top = '0';
    qrOverlay.style.left = '0';
    qrOverlay.style.width = '100%';
    qrOverlay.style.height = '100%';
    qrOverlay.style.background = 'rgba(0, 0, 0, 0.6)';
    qrOverlay.style.backdropFilter = 'blur(8px)';
    qrOverlay.style.display = 'flex';
    qrOverlay.style.alignItems = 'center';
    qrOverlay.style.justifyContent = 'center';
    qrOverlay.style.zIndex = '100000';
    qrOverlay.style.fontFamily = "'Fredoka', sans-serif";
    qrOverlay.style.color = '#492719';

    qrOverlay.innerHTML = `
      <div style="background: #fff; border: 2px solid #72441c; border-radius: 20px; width: 90%; max-width: 440px; padding: 30px; box-shadow: 0 20px 45px rgba(0,0,0,0.3); text-align: center; position: relative; box-sizing: border-box;">
        <div style="background: linear-gradient(135deg, #72441c, #ec993c); padding: 18px; border-radius: 12px; color: #fff; margin-bottom: 20px;">
          <h3 style="margin: 0; font-size: 20px; font-weight: 700;">📱 QR Code Payment</h3>
          <span style="font-size: 13px; opacity: 0.9;">Scan the QR code below to complete your order</span>
        </div>
        <div id="shopQrContainer" style="margin: 20px auto; width: 180px; height: 180px; display: flex; align-items: center; justify-content: center; background: #faf9f6; padding: 10px; border-radius: 12px; border: 1.5px dashed #ebd4bd;"></div>
        <div style="background: #faf6f0; border-radius: 10px; padding: 15px; margin: 15px 0; font-size: 14px; text-align: left; line-height: 1.6; border: 1px solid #ebd4bd;">
          <strong>Order Reference:</strong> <span style="font-family: monospace; color: #72441c; font-weight: 700;">` + refId + `</span><br>
          <strong>Total Amount:</strong> <span style="color: #ec993c; font-weight: 800; font-size: 16px;">` + fmt(totalAmount) + `</span><br>
          <strong>Status:</strong> <span style="color: #f57f17; font-weight: bold; animation: pulseText 1.5s infinite;">Waiting for scan...</span>
        </div>
        <div style="display: flex; align-items: center; justify-content: center; gap: 10px; padding: 10px; background: #fafaf9; border-radius: 8px; font-size: 13px; color: #666; margin-top: 15px;">
          <div style="width: 16px; height: 16px; border: 2.5px solid #ebd4bd; border-top: 2.5px solid #72441c; border-radius: 50%; animation: shopSpin 0.8s linear infinite;"></div>
          <span>Processing payment on secure network...</span>
        </div>
        <style>
          @keyframes shopSpin { to { transform: rotate(360deg); } }
          @keyframes pulseText { 0%, 100% { opacity: 1; } 50% { opacity: 0.6; } }
        </style>
      </div>
    `;
    document.body.appendChild(qrOverlay);

    // Generate QR Code dynamically
    setTimeout(function() {
      var container = document.getElementById('shopQrContainer');
      if (container) {
        var qrPayload = window.location.origin + '/ScanQR?r=' + encodeURIComponent(refId);
        new QRCode(container, {
          text: qrPayload,
          width: 180,
          height: 180,
          colorDark: '#72441c',
          colorLight: '#ffffff',
          correctLevel: QRCode.CorrectLevel.M
        });
      }
    }, 50);

    // Complete order after exactly 7 seconds
    setTimeout(function() {
      qrOverlay.remove();
      submitOrderToServer("QR Code", "Completed", refId, function(rId, totalVal, email, address, name) {
        alert("Payment Successful!");
        showSuccessModal(rId, totalVal, email, address, name);
      });
    }, 7000);
  }

  if (payBtn) {
    payBtn.addEventListener('click', function(e) {
      e.preventDefault();

      var errors = [];
      var fullName = (document.getElementById('fullName')?.value || '').trim();
      var emailVal = (document.getElementById('email')?.value || '').trim();
      var phoneVal = (document.getElementById('phone')?.value || '').trim();
      var addressVal = (document.getElementById('address')?.value || '').trim();
      var cityVal = (document.getElementById('city')?.value || '').trim();
      var postcodeVal = (document.getElementById('postcode')?.value || '').trim();

      // Form validation
      if (!fullName) errors.push("Full Name is required.");
      if (!emailVal) {
        errors.push("Email is required.");
      } else if (emailVal.indexOf('@') === -1 || emailVal.indexOf('.') === -1) {
        errors.push("Invalid Email format.");
      }
      if (!phoneVal) {
        errors.push("Phone Number is required.");
      } else if (phoneVal.replace(/[^0-9]/g, '').length < 8) {
        errors.push("Invalid Phone Number.");
      }
      if (!addressVal) errors.push("Shipping Address is required.");
      if (!cityVal) errors.push("City is required.");
      if (!postcodeVal) errors.push("ZIP / Postal Code is required.");

      var cart = getCart();
      if (!cart.length) errors.push("Your cart is empty.");

      if (errors.length > 0) {
        var errorsHTML = '<p style="margin-bottom: 10px; font-weight: 500;">Please fill out all required fields:</p>' +
          '<ul class="validation-errors-list">' +
            errors.map(function(err) { return '<li>' + err + '</li>'; }).join('') +
          '</ul>';
        
        showPremiumModal("Validation Errors", errorsHTML, [
          { text: "OK", primary: true }
        ]);
        return;
      }

      // Show Payment Selection Modal
      var selectPaymentHTML = `
        <div style="text-align: center; font-family: 'Fredoka', sans-serif;">
          <p style="font-size: 16px; margin-bottom: 20px; color: #492719;">Choose your preferred payment option to complete your purchase:</p>
          <div style="display: flex; flex-direction: column; gap: 15px; margin-top: 15px;">
            <button id="pay-cash-opt" style="display: flex; align-items: center; gap: 15px; width: 100%; padding: 15px; border: 2px solid #72441c; border-radius: 12px; background: #fff; cursor: pointer; text-align: left; transition: all 0.15s; outline:none;">
              <div style="font-size: 28px; color: #2e7d32; line-height: 1;">💵</div>
              <div>
                <strong style="display: block; font-size: 16px; color: #72441c; font-family: 'Fredoka', sans-serif;">Cash (Tiền mặt)</strong>
                <span style="font-size: 13px; color: #888; font-family: 'Fredoka', sans-serif;">Order will be saved as Pending until approved by Admin.</span>
              </div>
            </button>
            <button id="pay-qrcode-opt" style="display: flex; align-items: center; gap: 15px; width: 100%; padding: 15px; border: 2px solid #72441c; border-radius: 12px; background: #fff; cursor: pointer; text-align: left; transition: all 0.15s; outline:none;">
              <div style="font-size: 28px; color: #ec993c; line-height: 1;">📱</div>
              <div>
                <strong style="display: block; font-size: 16px; color: #72441c; font-family: 'Fredoka', sans-serif;">QR Code (Quét mã)</strong>
                <span style="font-size: 13px; color: #888; font-family: 'Fredoka', sans-serif;">Simulate 5s instant scanning and mark as Completed.</span>
              </div>
            </button>
          </div>
        </div>
      `;

      showPremiumModal("Select Payment Option", selectPaymentHTML, []);

      // Add click listeners inside selection modal
      var cashBtn = document.getElementById('pay-cash-opt');
      if (cashBtn) {
        cashBtn.addEventListener('click', function() {
          var modal = document.getElementById('nhs-premium-modal');
          if (modal) modal.remove();
          
          var refId = 'CASH-' + Math.random().toString(36).substring(2, 10).toUpperCase();
          submitOrderToServer("Cash", "Pending", refId, function(rId, totalVal, email, address, name) {
            showSuccessModal(rId, totalVal, email, address, name);
          });
        });
      }

      var qrcodeBtn = document.getElementById('pay-qrcode-opt');
      if (qrcodeBtn) {
        qrcodeBtn.addEventListener('click', function() {
          var modal = document.getElementById('nhs-premium-modal');
          if (modal) modal.remove();
          
          simulateQRCodePayment();
        });
      }
    });
  }

  /* ═══════ INIT ═══════ */
  renderShipping();
  updateTotals();

})();
