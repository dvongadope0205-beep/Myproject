        function changeImage(btn, src) {
            // 1. Đổi ảnh to active
            const pos = btn.closest('[data-media-position]')
                        .getAttribute('data-media-position');
            document.querySelectorAll('.product__media-item')
                .forEach(li => li.classList.remove('is-active'));
            const slides = document.querySelectorAll('.product__media-item');
            if (slides[pos - 1]) slides[pos - 1].classList.add('is-active');

            // 2. Đổi viền thumbnail
            document.querySelectorAll('.thumbnail-global-setting')
                .forEach(b => b.classList.remove('is-active'));
            btn.classList.add('is-active');
        }

        function scrollThumbnails(direction) {
            const strip = document.getElementById('thumbnailStrip');
            if (strip) {
                const scrollAmount = strip.clientWidth / 2;
                strip.scrollBy({ left: direction * scrollAmount, behavior: 'smooth' });
            }
        }