// Xử lý bật/tắt Search Overlay
function openSearch() {
    document.getElementById("fullSearchOverlay").classList.add("active");
    // Tự động focus vào ô nhập liệu
    setTimeout(() => {
        document.getElementById("zooSearchInput").focus();
    }, 100);
}

function closeSearch() {
    document.getElementById("fullSearchOverlay").classList.remove("active");
}

function executeSearch() {
    const query = document.getElementById("zooSearchInput").value.trim();
    if (query) {
        alert("Thực hiện tìm kiếm cho: " + query);
    }
}

document.getElementById("zooSearchInput")?.addEventListener("keypress", function (e) {
    if (e.key === "Enter") {
        e.preventDefault();
        executeSearch();
    }
});

document.addEventListener('keydown', function (e) {
    if (e.key === "Escape") {
        closeSearch();
    }
});