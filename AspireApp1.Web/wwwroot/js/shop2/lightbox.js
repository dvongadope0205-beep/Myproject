// Khai báo biến toàn cục để quản lý trạng thái
let nhImages = [];
let nhCurrentIndex = 0;
let nhMode = 'theater'; // 'theater' hoặc 'fullscreen'

document.addEventListener('DOMContentLoaded', function() {
    // 1. Thu thập danh sách ảnh từ các sản phẩm ngay khi trang tải xong
    const imageElements = document.querySelectorAll('.product__media-item .product__media img');
    nhImages = Array.from(imageElements).map(img => img.src);

    // 2. Hàm cập nhật nội dung Lightbox (Ảnh, số thứ tự, trạng thái nút)
    function nhUpdateLightbox() {
        const img = document.getElementById('nh-lb-img');
        const counter = document.getElementById('nh-lb-counter');
        const title = document.getElementById('nh-lb-title');
        const prevBtn = document.getElementById('nh-lb-prev');
        const nextBtn = document.getElementById('nh-lb-next');
        const theaterBtn = document.getElementById('nh-lb-theater-btn');
        const fsBtn = document.getElementById('nh-lb-fullscreen-btn');

        if (img) img.src = nhImages[nhCurrentIndex];
        if (counter) counter.textContent = (nhCurrentIndex + 1) + ' of ' + nhImages.length;
        if (title) title.textContent = 'Image ' + (nhCurrentIndex + 1);
        
        // Cập nhật trạng thái disable cho nút điều hướng
        if (prevBtn) prevBtn.disabled = (nhCurrentIndex === 0);
        if (nextBtn) nextBtn.disabled = (nhCurrentIndex === nhImages.length - 1);

        // Cập nhật trạng thái active cho các nút chế độ
        if (theaterBtn) theaterBtn.classList.toggle('active', nhMode === 'theater');
        if (fsBtn) fsBtn.classList.toggle('active', nhMode === 'fullscreen');
    }

    // 3. Hàm mở Lightbox
    function nhOpenLightbox(index) {
        nhCurrentIndex = index;
        nhMode = 'theater';
        const lb = document.getElementById('nh-lightbox');
        if (lb) {
            lb.style.display = 'flex';
            lb.classList.remove('fullscreen');
            nhUpdateLightbox();
            document.body.style.overflow = 'hidden'; // Chặn cuộn trang
        }
    }

    // 4. Hàm đóng Lightbox
    function nhCloseLightbox() {
        const lb = document.getElementById('nh-lightbox');
        if (lb) lb.style.display = 'none';
        document.body.style.overflow = ''; // Mở lại cuộn trang
        if (document.fullscreenElement) document.exitFullscreen();
    }

    // 5. Gán sự kiện click cho các ảnh sản phẩm trên trang
    document.querySelectorAll('.product__media-item').forEach((item, index) => {
        item.style.cursor = 'zoom-in';
        item.onclick = () => nhOpenLightbox(index);
    });

    // 6. Gán sự kiện cho các nút điều khiển (Kiểm tra Null để tránh lỗi)
    const closeBtn = document.getElementById('nh-lb-close');
    const backdrop = document.getElementById('nh-lb-backdrop');
    const prevBtn = document.getElementById('nh-lb-prev');
    const nextBtn = document.getElementById('nh-lb-next');
    const theaterBtn = document.getElementById('nh-lb-theater-btn');
    const fsBtn = document.getElementById('nh-lb-fullscreen-btn');

    if (closeBtn) closeBtn.onclick = nhCloseLightbox;
    if (backdrop) backdrop.onclick = nhCloseLightbox;

    if (prevBtn) {
        prevBtn.onclick = (e) => {
            e.stopPropagation(); // Ngăn sự kiện bị lặp
            if (nhCurrentIndex > 0) {
                nhCurrentIndex--;
                nhUpdateLightbox();
            }
        };
    }

    if (nextBtn) {
        nextBtn.onclick = (e) => {
            e.stopPropagation();
            if (nhCurrentIndex < nhImages.length - 1) {
                nhCurrentIndex++;
                nhUpdateLightbox();
            }
        };
    }

    if (theaterBtn) {
        theaterBtn.onclick = () => {
            if (nhMode === 'theater') {
                nhCloseLightbox();
            } else {
                nhMode = 'theater';
                const lb = document.getElementById('nh-lightbox');
                if (lb) lb.classList.remove('fullscreen');
                if (document.fullscreenElement) document.exitFullscreen();
                nhUpdateLightbox();
            }
        };
    }

    if (fsBtn) {
        fsBtn.onclick = () => {
            const lb = document.getElementById('nh-lightbox');
            if (nhMode === 'fullscreen') {
                nhMode = 'theater';
                if (lb) lb.classList.remove('fullscreen');
                if (document.fullscreenElement) document.exitFullscreen();
            } else {
                nhMode = 'fullscreen';
                if (lb) {
                    lb.classList.add('fullscreen');
                    lb.requestFullscreen?.();
                }
            }
            nhUpdateLightbox();
        };
    }

    // 7. Điều hướng bằng bàn phím
    document.addEventListener('keydown', (e) => {
        const lb = document.getElementById('nh-lightbox');
        if (!lb || lb.style.display === 'none') return;
        
        if (e.key === 'Escape') nhCloseLightbox();
        if (e.key === 'ArrowLeft' && nhCurrentIndex > 0) {
            nhCurrentIndex--; nhUpdateLightbox();
        }
        if (e.key === 'ArrowRight' && nhCurrentIndex < nhImages.length - 1) {
            nhCurrentIndex++; nhUpdateLightbox();
        }
    });
});