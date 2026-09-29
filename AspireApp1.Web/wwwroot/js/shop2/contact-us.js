// ============================================================
// File: contact-us.js
// ============================================================

document.addEventListener('DOMContentLoaded', function() {
    if (typeof initCartEffects === 'function') initCartEffects();
    if (typeof initFeatures === 'function') initFeatures();
});

let selectedContactFiles = [];

// 1. Hàm Bật/Tắt khung hiển thị file
window.toggleFilePreview = function() {
    const previewList = document.getElementById('file-preview-list');
    if (previewList) {
        const isHidden = (previewList.style.display === 'none');
        previewList.style.display = isHidden ? 'flex' : 'none';
    }
};

// 2. Xử lý khi chọn file
window.handleFileSelect = function(event) {
    if (!event.target.files) return;
    const newFiles = Array.from(event.target.files);
    selectedContactFiles = [...selectedContactFiles, ...newFiles];
    
    // Khi vừa chọn file mới, tự động hiện khung preview để người dùng thấy
    const previewList = document.getElementById('file-preview-list');
    if (previewList) previewList.style.display = 'flex';
    
    updateFileUI();
};

// 3. Cập nhật giao diện
window.updateFileUI = function() {
    const toggleBtn = document.getElementById('copy-icon-toggle');
    const fileBadge = document.getElementById('file-count-badge');
    const previewList = document.getElementById('file-preview-list');
    
    if (!toggleBtn || !fileBadge || !previewList) return;

    // Hiển thị/Ẩn Icon Copy và Badge số lượng
    if (selectedContactFiles.length > 0) {
        fileBadge.textContent = selectedContactFiles.length;
        toggleBtn.style.display = 'flex';
    } else {
        toggleBtn.style.display = 'none';
        previewList.style.display = 'none'; // Ẩn luôn khung nếu không còn file
    }

    // Vẽ danh sách Thumbnail
    previewList.innerHTML = '';
    selectedContactFiles.forEach((file, index) => {
        const card = document.createElement('div');
        card.style.cssText = `
            position:relative; width:150px; height:130px;
            border-radius:8px; border:1px solid #ddd;
            background:#f9f9f9; overflow:hidden;
            display:flex; flex-direction:column;
            align-items:center; justify-content:center;
        `;

        const removeBtn = `
            <div style="position:absolute; top:4px; right:4px; 
                background:rgba(255,255,255,0.9); border-radius:50%;
                width:22px; height:22px; display:flex; align-items:center;
                justify-content:center; cursor:pointer; color:red;
                font-weight:bold; font-size:14px; box-shadow:0 1px 3px rgba(0,0,0,0.2);"
                onclick="removeContactFile(${index})">×</div>
        `;

        const nameBar = `
            <span style="position:absolute; bottom:0; left:0; right:0;
                background:rgba(0,0,0,0.6); color:#fff; padding:5px 6px;
                font-size:11px; overflow:hidden; text-overflow:ellipsis;
                white-space:nowrap; text-align:center;">
                ${file.name}
            </span>`;

        if (file.type.startsWith('image/')) {
            const url = URL.createObjectURL(file);
            card.innerHTML = `<img src="${url}" style="width:100%;height:100%;object-fit:cover;">${removeBtn}${nameBar}`;
        } else {
            card.innerHTML = `
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#888" stroke-width="1.5">
                    <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><polyline points="13 2 13 9 20 9"/>
                </svg>
                ${removeBtn}${nameBar}`;
        }
        previewList.appendChild(card);
    });
};

// 4. Xóa file
window.removeContactFile = function(index) {
    selectedContactFiles.splice(index, 1);
    updateFileUI();
    
    // Cập nhật lại input file để gửi form chính xác
    const fileInput = document.getElementById('ContactFormAttachment');
    if (fileInput) {
        const dataTransfer = new DataTransfer();
        selectedContactFiles.forEach(file => dataTransfer.items.add(file));
        fileInput.files = dataTransfer.files;
    }
};