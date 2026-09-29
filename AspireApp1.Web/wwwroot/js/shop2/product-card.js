document.addEventListener('DOMContentLoaded', () => {
    // 1. Sửa lại Selector cho đúng với file plush.html của bạn
    // Chúng ta chọn .grid-item vì đây là thẻ <li> trực tiếp chiếm không gian trong Grid
    const products = document.querySelectorAll('.product-grid .grid-item');
    const itemsPerPage = 12; 
    const totalPages = Math.ceil(products.length / itemsPerPage);
    let currentPage = 1;

    const paginationContainer = document.getElementById('pagination-container');

    if (!products.length || totalPages <= 1) {
        if (paginationContainer) paginationContainer.style.display = 'none';
        return;
    }

    function renderPagination() {
        if (!paginationContainer) return;
        paginationContainer.innerHTML = ''; 

        // Nút mũi tên TRÁI (<)
        if (currentPage > 1) {
            const prevLink = document.createElement('a');
            prevLink.href = "javascript:void(0)"; // Tránh nhảy trang khi click
            prevLink.className = 'btn-prev';
            prevLink.textContent = '<';
            prevLink.onclick = () => {
                currentPage--;
                updateView();
            };
            paginationContainer.appendChild(prevLink);
        }

        // Các nút số
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

        // Nút mũi tên PHẢI (>)
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
            // Ẩn/Hiện thẻ <li> (grid-item) thay vì thẻ div bên trong
            if (index >= startIndex && index < endIndex) {
                product.style.display = 'list-item'; // Hoặc ''
            } else {
                product.style.display = 'none';
            }
        });

        renderPagination(); 

        // Cuộn mượt lên đầu danh sách sản phẩm khi đổi trang
        const grid = document.querySelector('.product-grid');
        if (grid) {
            window.scrollTo({
                top: grid.offsetTop - 100,
                behavior: 'smooth'
            });
        }
    }

    // 2. QUAN TRỌNG: Gọi hàm này ngay lập tức để ẩn các sản phẩm từ trang 2 trở đi khi vừa load trang
    updateView();
});