const header = document.getElementById('mainHeader');
const notificationBar = document.getElementById('notificationBar');

window.addEventListener('scroll', function () {
    if (window.scrollY > 48) { // Cuộn qua thanh thông báo
        header.classList.add('sticky');
    } else {
        header.classList.remove('sticky');
    }
});