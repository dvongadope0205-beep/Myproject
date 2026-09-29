const animals = [
    {
        "name":  "Asian elephant",
        "type":  "MAMMALS",
        "img":  "/Source/Animals2/elephant/elephant.jpg",
        "desc":  "Asian elephants are the largest land animals in Asia, navigating their world with profound intelligence and deep-rooted family bonds.",
        "url":  "/Animals2/AsianElephant"
    },
    {
        "name":  "Asiatic lion",
        "type":  "MAMMALS",
        "img":  "/Source/Animals2/asiatic-lion/asiatic-lion.jpg",
        "desc":  "Once roaming across vast parts of northern Africa, the Middle East, and Asia, Asiatic lions are now found in just one place: India's Gir Forest.",
        "url":  "/Animals2/AsiaticLion"
    },
    {
        "name":  "Capybara",
        "type":  "MAMMALS",
        "img":  "/Source/Animals2/capybara/capybara.jpg",
        "desc":  "Often referred to as the giant guinea pig, the capybara is native to South America and holds the title of the world's largest rodent.",
        "url":  "/Animals2/CapybaraNew"
    },
    {
        "name":  "Cheetah",
        "type":  "MAMMALS",
        "img":  "/Source/Animals2/cheetah/cheetah.jpg",
        "desc":  "The cheetah is nature's sprinter. Clocking 0-70 mph in just 3 seconds, it's the fastest land animal on Earth.",
        "url":  "/Animals2/CheetahNew"
    },
    {
        "name":  "Chimpanzee",
        "type":  "PRIMATES",
        "img":  "/Source/Animals2/chimpanzee/chimpanzee.jpg",
        "desc":  "Sharing roughly 98% of our DNA, these highly intelligent apes are our closest living relatives and master tool users.",
        "url":  "/Animals2/ChimpanzeeNew"
    },
    {
        "name":  "Caribbean flamingo",
        "type":  "BIRDS",
        "img":  "/Source/Animals2/flamingo/flamingo.jpg",
        "desc":  "With their fabulous pink plumage, the Caribbean flamingo is the brightest and one of the largest of all flamingos.",
        "url":  "/Animals2/FlamingoNew"
    },
    {
        "name":  "Rodrigues Fruit Bat",
        "type":  "MAMMALS",
        "img":  "/Source/Animals2/fruit-bat/fruit-bat.jpg",
        "desc":  "For centuries, myths have hidden the truth about this fascinating and diverse order, which actually accounts for up to 20% of all mammal species on Earth",
        "url":  "/Animals2/FruitBat"
    },
    {
        "name":  "Great green macaw",
        "type":  "BIRDS",
        "img":  "/Source/Animals2/great-green-macaw/great-green-macaw.jpg",
        "desc":  "As one of the largest parrots in the wild, these colourful birds are famous for their distinctive loud screeches and tight wing-to-wing flights.",
        "url":  "/Animals2/GreatGreenMacaw"
    },
    {
        "name":  "Jaguar",
        "type":  "MAMMALS",
        "img":  "/Source/Animals2/jaguar/jaguar.jpg",
        "desc":  "Jaguars are the third largest of the big cats, possessing the most powerful bite of them all.",
        "url":  "/Animals2/Jaguar"
    },
    {
        "name":  "Komodo Dragon",
        "type":  "MAMMALS",
        "img":  "/Source/Animals2/komodo-dragon/komodo-dragon.jpg",
        "desc":  "As the largest and heaviest lizards on the planet, these ancient apex predators are legendary for their lethal venomous bite and serrated teeth.",
        "url":  "/Animals2/KomodoDragon"
    },
    {
        "name":  "Mandrill",
        "type":  "MAMMALS",
        "img":  "/Source/Animals2/mandrill/mandrill.jpg",
        "desc":  "As the largest monkeys in the world, these primates are famous for their vibrant faces and a fascinating array of teeth-based emotional expressions.",
        "url":  "/Animals2/MandrillNew"
    },
    {
        "name":  "Meerkat",
        "type":  "MAMMALS",
        "img":  "/Source/Animals2/meerkat/meerkat.jpg",
        "desc":  "Famed for their upright posture, meerkats are incredibly social animals. Fortunately, they are classified as Least Concern and do not currently face major threats in the wild.",
        "url":  "/Animals2/MeerkatNew"
    },
    {
        "name":  "Northern Giraffe",
        "type":  "MAMMALS",
        "img":  "/Source/Animals2/northern-giraffe/northern-giraffe.jpg",
        "desc":  "Growing up to 6 metres tall, these gentle giants are uniquely identified by their fingerprint-like coat patterns and unmarked lower legs.",
        "url":  "/Animals2/NorthernGiraffe"
    },
    {
        "name":  "Bornean orangutan",
        "type":  "PRIMATES",
        "img":  "/Source/Animals2/orangutan/orangutan.jpg",
        "desc":  "Sharing 97% of their DNA with humans, these exceptionally intelligent primates are among our closest living relatives on the planet.",
        "url":  "/Animals2/OrangutanNew"
    },
    {
        "name":  "Asian short-clawed otter",
        "type":  "MAMMALS",
        "img":  "/Source/Animals2/otter/otter.jpg",
        "desc":  "As the smallest of all otter species, these highly social mammals are famous for their partly webbed, dexterous paws.",
        "url":  "/Animals2/OtterNew"
    },
    {
        "name":  "Parson's Chameleon",
        "type":  "REPTILES",
        "img":  "/Source/Animals2/parson's-chameleon/parson-chameleon.jpg",
        "desc":  "As one of the world's largest chameleons, this remarkable reptile is famous for its ability to seamlessly change colour to match its surroundings.",
        "url":  "/Animals2/Parson'SChameleon"
    },
    {
        "name":  "Radiated tortoise",
        "type":  "REPTILES",
        "img":  "/Source/Animals2/radiated-tortoise/radiated-tortoise.jpg",
        "desc":  "Adorned with star-patterned shells, these beautiful reptiles are renowned for their staggering ability to live for over a century.",
        "url":  "/Animals2/RadiatedTortoise"
    },
    {
        "name":  "Rhinoceros Hornbill",
        "type":  "BIRDS",
        "img":  "/Source/Animals2/rhinoceros-hornbill/rhinoceros-hornbill.jpg",
        "desc":  "Revered by the native Iban people as the king of worldly birds, this intimidating rainforest giant is famous for its massive wingspan and spectacular casque.",
        "url":  "/Animals2/RhinocerosHornbill"
    },
    {
        "name":  "Greater one-horned rhino",
        "type":  "MAMMALS",
        "img":  "/Source/Animals2/rhino/rhino.jpg",
        "desc":  "Greater one-horned rhinos are the largest of all rhino species, easily distinguishable by their heavy, plate-like protective skin.",
        "url":  "/Animals2/RhinoNew"
    },
    {
        "name":  "Ring-tailed lemur",
        "type":  "PRIMATES",
        "img":  "/Source/Animals2/ring-tail-lemur/ring-tail-lemur.jpg",
        "desc":  "Instantly recognizable by their iconic stripy tails and bright orange eyes, these highly agile primates are famous for engaging in fierce, territorial stink fights.",
        "url":  "/Animals2/RingTailLemur"
    },
    {
        "name":  "Sun Bear",
        "type":  "MAMMALS",
        "img":  "/Source/Animals2/sun-bear/sun-bear.jpg",
        "desc":  "As the smallest of the eight bear species, they are affectionately known as 'honey bears' and rely on powerful jaws to tear open trees for food.",
        "url":  "/Animals2/SunBearNew"
    },
    {
        "name":  "Sunda Gharial",
        "type":  "REPTILES",
        "img":  "/Source/Animals2/sunda-gharial/sunda-gharial.jpg",
        "desc":  "Tracing their history back over 200 million years, these mysterious freshwater crocodilians rely exceptionally on learning rather than instinct to survive.",
        "url":  "/Animals2/SundaGharial"
    },
    {
        "name":  "Sumatran Tiger",
        "type":  "MAMMALS",
        "img":  "/Source/Animals2/tiger/tiger.jpg",
        "desc":  "As the smallest of the tiger subspecies, these majestic mammals are exceptional swimmers equipped with unique webbed paws.",
        "url":  "/Animals2/TigerNew"
    },
    {
        "name":  "Grévy's zebra",
        "type":  "MAMMALS",
        "img":  "/Source/Animals2/zebra/zebra.jpg",
        "desc":  "Grévy's zebras are the largest of all zebra species, carrying a masterfully woven pattern of lines unique to each individual.",
        "url":  "/Animals2/ZebraNew"
    }
];

const listContainer = document.getElementById("animalList");
const thumbContainer = document.getElementById("animalThumbnails");

listContainer.innerHTML = '';
thumbContainer.innerHTML = '';

// ── Build slide items ──
animals.forEach((animal, index) => {
    let itemHTML = `
        <div class="item ${index === 0 ? 'active' : ''}" data-url="${animal.url}">
            <img src="${animal.img}" alt="${animal.name}">
            <div class="content">
                <div class="author">${animal.type}</div>
                <div class="title">${animal.name}</div>
                <div class="des">${animal.desc}</div>
                <div class="buttons">
                    <a href="${animal.url}" class="btn-action btn-learn">Learn More</a>
                    <a href="/Tickets" class="btn-action btn-buy">Buy Tickets</a>
                </div>
            </div>
        </div>
    `;
    listContainer.innerHTML += itemHTML;
});

// ── Build stationary thumbnails ──
const trackEl = document.createElement('div');
trackEl.className = 'thumb-track';

function buildThumbHTML(animal, realIndex) {
    return `<div class="thumb-item" data-real-index="${realIndex}">
        <img src="${animal.img}" alt="Thumb ${realIndex}">
    </div>`;
}

let setHTML = '';
for (let i = 0; i < animals.length; i++) {
    setHTML += buildThumbHTML(animals[i], i);
}
trackEl.innerHTML = setHTML;
thumbContainer.appendChild(trackEl);

const items = document.querySelectorAll('.animal-carousel .list .item');
const allThumbs = document.querySelectorAll('.animal-carousel .thumbnail .thumb-item');
let currentIndex = 0;
const autoScrollTime = 5000;
let sliderInterval = null;

// ── Make the main image clickable ──
items.forEach(item => {
    item.style.cursor = 'pointer';
    item.addEventListener('click', (e) => {
        if (e.target.closest('.btn-action') || e.target.closest('a')) return;
        const url = item.getAttribute('data-url');
        if (url) window.location.href = url;
    });
});

// ── Highlight active thumbnails ──
function updateThumbHighlight() {
    allThumbs.forEach(t => {
        t.classList.toggle('active', parseInt(t.getAttribute('data-real-index')) === currentIndex);
    });

    // Scroll active thumbnail into view
    const activeThumb = allThumbs[currentIndex];
    if (activeThumb) {
        activeThumb.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
    }
}

// ── Show a specific slide ──
function showSlide(index) {
    items[currentIndex].classList.remove('active');
    currentIndex = ((index % animals.length) + animals.length) % animals.length;
    items[currentIndex].classList.add('active');
    updateThumbHighlight();
}

// ── Next slide ──
function nextSlide() {
    showSlide(currentIndex + 1);
}

// ── Autoplay controls ──
function startAutoPlay() {
    stopAutoPlay();
    sliderInterval = setInterval(nextSlide, autoScrollTime);
}

function stopAutoPlay() {
    if (sliderInterval) {
        clearInterval(sliderInterval);
        sliderInterval = null;
    }
}

// ── Handle manual actions (shows slide and resets 5s autoplay) ──
function handleManualAction(targetIndex) {
    showSlide(targetIndex);
    startAutoPlay();
}

// ── Thumbnail click handlers ──
allThumbs.forEach(thumb => {
    thumb.addEventListener('click', () => {
        const realIndex = parseInt(thumb.getAttribute('data-real-index'));
        handleManualAction(realIndex);
    });
});

// ── Next / Prev buttons click handlers ──
const nextBtn = document.getElementById('next');
const prevBtn = document.getElementById('prev');
if (nextBtn) {
    nextBtn.addEventListener('click', () => {
        handleManualAction(currentIndex + 1);
    });
}
if (prevBtn) {
    prevBtn.addEventListener('click', () => {
        handleManualAction(currentIndex - 1);
    });
}

// ── Style the thumb-track for centering ──
const styleSheet = document.createElement('style');
styleSheet.textContent = `
    .thumb-track {
        display: flex;
        gap: 15px;
        justify-content: flex-start;
        transition: transform 0.5s ease;
    }
    @media (min-width: 1800px) {
        .thumb-track {
            justify-content: center;
            width: 100%;
        }
    }
`;
document.head.appendChild(styleSheet);

// ── Touch/swipe support for mobile ──
let touchStartX = 0;
const carousel = document.querySelector('.animal-carousel');

carousel.addEventListener('touchstart', (e) => {
    touchStartX = e.changedTouches[0].screenX;
    stopAutoPlay();
}, { passive: true });

carousel.addEventListener('touchend', (e) => {
    const touchEndX = e.changedTouches[0].screenX;
    const diffX = touchStartX - touchEndX;
    if (Math.abs(diffX) > 50) {
        handleManualAction(diffX > 0 ? currentIndex + 1 : currentIndex - 1);
    } else {
        startAutoPlay();
    }
}, { passive: true });

// ── Initial state ──
showSlide(0);
// Start autoplay immediately on page load
startAutoPlay();
