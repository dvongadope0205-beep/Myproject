function changeImage(btn, src) {
    var container = btn.closest('[data-media-position]');
    if (!container) return;
    
    var pos = parseInt(container.getAttribute('data-media-position'), 10);
    var slides = document.querySelectorAll('.product__media-item');
    
    // Disable temporarily during programmatic scroll to avoid scroll bounce conflict
    window.isProgrammaticScroll = true;
    clearTimeout(window.scrollTimeout);

    // 1. Update large slide active class
    slides.forEach(function(li) { li.classList.remove('is-active'); });
    var targetSlide = slides[pos - 1];
    if (targetSlide) {
        targetSlide.classList.add('is-active');
        
        // Use scrollIntoView to scroll smoothly to target slide
        targetSlide.scrollIntoView({
            behavior: 'smooth',
            block: 'nearest',
            inline: 'start'
        });
    }

    // 2. Update active thumbnail borders
    document.querySelectorAll('.thumbnail-global-setting')
        .forEach(function(b) { b.classList.remove('is-active'); });
    btn.classList.add('is-active');

    // Re-enable scroll observer after smooth scroll completes
    window.scrollTimeout = setTimeout(function() {
        window.isProgrammaticScroll = false;
    }, 600);
}

function scrollThumbnails(direction) {
    var strip = document.getElementById('thumbnailStrip');
    if (strip) {
        var scrollAmount = strip.clientWidth / 2;
        strip.scrollBy({ left: direction * scrollAmount, behavior: 'smooth' });
    }
}

/* ═══════════ MOBILE SWIPE SYNCHRONIZATION ═══════════ */
document.addEventListener('DOMContentLoaded', function() {
    var slider = document.querySelector('.product__media-list');
    var slides = document.querySelectorAll('.product__media-item');
    var thumbnails = document.querySelectorAll('.thumbnail-container');

    if (slider && slides.length > 0 && thumbnails.length > 0) {
        window.isProgrammaticScroll = false;

        var observerOptions = {
            root: slider,
            rootMargin: '0px',
            threshold: 0.6 // Considered active when 60% of the slide is in view
        };

        var observer = new IntersectionObserver(function(entries) {
            if (window.isProgrammaticScroll) return; // Skip if triggered by clicking thumbnail

            entries.forEach(function(entry) {
                if (entry.isIntersecting) {
                    var activeSlide = entry.target;
                    
                    // Mark slide as active
                    slides.forEach(function(li) { li.classList.remove('is-active'); });
                    activeSlide.classList.add('is-active');

                    // Find matching index
                    var index = Array.from(slides).indexOf(activeSlide);
                    
                    // Update matching thumbnail
                    thumbnails.forEach(function(thumb, i) {
                        var btn = thumb.querySelector('.thumbnail-global-setting');
                        if (btn) {
                            if (i === index) {
                                btn.classList.add('is-active');
                                
                                // Scroll thumbnail strip horizontally to keep active thumbnail visible/centered
                                var strip = document.getElementById('thumbnailStrip');
                                if (strip) {
                                    strip.scrollTo({
                                        left: thumb.offsetLeft - strip.offsetLeft - (strip.clientWidth / 2) + (thumb.clientWidth / 2),
                                        behavior: 'smooth'
                                    });
                                }
                            } else {
                                btn.classList.remove('is-active');
                            }
                        }
                    });
                }
            });
        }, observerOptions);

        slides.forEach(function(slide) {
            observer.observe(slide);
        });
    }
});

// Accordion toggle helper
window.toggleAccordion = function(id) {
    var container = document.getElementById(id);
    if (!container) return;
    var details = container.querySelector('details');
    if (!details) return;
    
    var evt = window.event;
    if (evt) {
        evt.preventDefault();
        evt.stopPropagation();
    }
    
    if (details.hasAttribute('open')) {
        details.removeAttribute('open');
    } else {
        details.setAttribute('open', 'true');
    }
};