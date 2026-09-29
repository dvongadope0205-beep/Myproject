document.addEventListener('DOMContentLoaded', function () {

    // Xử lý từng nút trigger độc lập
    document.querySelectorAll('.wj-sizechart-btn').forEach(trigger => {

        // Tìm modal tương ứng: đổi "wj-open-sizechart-" → "wj-sizechart-modal-"
        const modalId = trigger.id.replace('wj-open-sizechart-', 'wj-sizechart-modal-');
        const modal   = document.getElementById(modalId);
        if (!modal) return;

        const closeBtn = modal.querySelector('.wj-sizechart-close');
        const tabs     = modal.querySelectorAll('.wj-sizechart-unit-toggle');
        const tables   = modal.querySelectorAll('.wj-sizechart-table');

        // Open / Close
        function openModal()  { modal.style.display = 'flex'; }
        function closeModal() { modal.style.display = 'none'; }

        trigger.addEventListener('click', openModal);
        closeBtn?.addEventListener('click', closeModal);
        modal.addEventListener('click', e => { if (e.target === modal) closeModal(); });

        // Init: bảng inches hiện, bảng cm ẩn
        tables.forEach((t, i) => { t.style.display = i === 0 ? '' : 'none'; });

        // Tab switch
        tabs.forEach((tab, i) => {
            tab.addEventListener('click', () => {
                tabs.forEach(t => t.classList.remove('active'));
                tab.classList.add('active');
                tables.forEach((t, j) => { t.style.display = j === i ? '' : 'none'; });
            });
        });
    });

    // ESC đóng tất cả modal đang mở
    document.addEventListener('keydown', e => {
        if (e.key === 'Escape') {
            document.querySelectorAll('.wj-sizechart-modal').forEach(m => {
                m.style.display = 'none';
            });
        }
    });
});