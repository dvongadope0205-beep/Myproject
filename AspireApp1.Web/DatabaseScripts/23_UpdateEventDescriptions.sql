-- ============================================================
-- 23_UpdateEventDescriptions.sql
-- Cập nhật mô tả chi tiết (100-150 từ) cho tất cả Events
-- Chạy trên DB hiện tại — không DELETE, chỉ UPDATE
-- ============================================================

USE [ZooDatabase]
GO

-- Event 1: Spring Break Safari Event
UPDATE Events SET Description = N'Celebrate the arrival of spring with our spectacular Spring Break Safari Event! This exclusive access bundle includes standard zoo admission, unlimited zoo train rides through our scenic wildlife trails, and a special souvenir cup to commemorate your adventure. During this limited-time event, families can enjoy interactive keeper talks, a scavenger hunt throughout the park, face painting stations, and live wildlife demonstrations featuring our ambassador animals. Children will love the hands-on discovery stations where they can learn about animal tracks, feathers, and habitats. Our Safari Photo Booth lets you capture memories with life-sized animal cutouts. Gourmet food trucks and refreshment stands are positioned throughout the zoo grounds. This event sells out quickly every year — reserve your timed-entry tickets online to guarantee your spot for the ultimate spring wildlife adventure!'
WHERE Title LIKE '%Spring Break Safari%';

-- Event 2: ZooLights Winter Festival
UPDATE Events SET Description = N'Experience the magic of winter at our breathtaking ZooLights Winter Festival! Watch as the entire zoo transforms into a spectacular winter wonderland illuminated by over one million sparkling LED lights, featuring stunning light sculptures of your favorite animals crafted by world-class lighting designers. Stroll along glowing pathways lined with enchanting light tunnels and animated displays that bring the holiday spirit to life around every corner. Warm up with complimentary hot cocoa, fresh-baked cookies, and gourmet seasonal treats from our holiday food village. Enjoy live carolers performing classic holiday songs, a visit from Santa in his arctic-themed workshop, ice sculpture demonstrations by professional carvers, a snow play area for children, and a dazzling fireworks finale every Saturday evening. This beloved annual tradition is the perfect family outing to create lasting holiday memories together!'
WHERE Title LIKE '%ZooLights Winter%';

-- Event 3: Annual Conservation Gala
UPDATE Events SET Description = N'Join us for our most prestigious evening of the year — the Annual Conservation Gala! This elegant black-tie fundraising event brings together passionate wildlife advocates, philanthropists, distinguished community leaders, and conservation scientists for an unforgettable night dedicated to protecting endangered species worldwide. The evening begins with a sophisticated cocktail reception featuring live jazz music and gourmet hors d''oeuvres, followed by a five-course plated dinner prepared by our award-winning executive chef using locally sourced, sustainable ingredients. Throughout the evening, guests will enjoy a live and silent auction featuring exclusive wildlife experiences, luxury travel packages, original wildlife artwork, and rare collectibles. Keynote speakers include renowned conservation biologists sharing groundbreaking field research and success stories. Every dollar raised directly funds our global wildlife protection programs, habitat restoration initiatives, anti-poaching efforts, and breeding programs for critically endangered species.'
WHERE Title LIKE '%Conservation Gala%';

-- Event 4: Zookeeper Camp Ticket
UPDATE Events SET Description = N'Give your child the adventure of a lifetime with our immersive Zookeeper Camp! This week-long residential experience is specifically designed for aspiring young naturalists aged 10-14 who dream of working with exotic animals. Campers will shadow professional zookeepers through their daily routines, including preparing specialized diets in our nutrition center, assisting with wellness checks at the veterinary hospital, enrichment activities designed to stimulate natural behaviors, and behind-the-scenes habitat maintenance. Each day features interactive workshops covering animal behavior, conservation biology, wildlife photography, and career exploration in zoological sciences. Participants will have exclusive access to restricted areas of the zoo, including the quarantine nursery, the research laboratory, and the breeding center. Camp concludes with a graduation ceremony where each camper receives a personalized certificate, a zoo ambassador t-shirt, and a portfolio of their wildlife photography from the week.'
WHERE Title LIKE '%Zookeeper Camp%';

-- Event 5: Up-Close Animal Encounters Camp
UPDATE Events SET Description = N'Introduce your little explorers to the wonders of wildlife with our Up-Close Animal Encounters Camp! Designed especially for curious young minds aged 5-9, these magical half-day experiences create unforgettable connections between children and our beloved animal ambassadors. Each session is carefully structured with age-appropriate activities led by certified wildlife educators who specialize in early childhood nature education. Children will meet gentle reptiles like our radiated tortoises and bearded dragons, feed colorful parakeets in our walk-through aviary, watch playful otters during their training sessions, and touch real animal artifacts including feathers, shells, and shed skins. Creative art projects inspired by each animal encounter help reinforce learning through hands-on expression. Every camper receives a personalized animal adoption certificate, a camp journal filled with fun facts and coloring pages, and a special zoo explorer badge to wear proudly.'
WHERE Title LIKE '%Up-Close Animal%';

-- Event 6: Themed Ecosystem Camp
UPDATE Events SET Description = N'Embark on an extraordinary scientific journey through the world''s most fascinating ecosystems with our Themed Ecosystem Camp! This immersive week-long program is designed for adventurous learners aged 8-12 who are passionate about understanding how the natural world works. Each day explores a different biome represented within our zoo — from the steamy tropical rainforest pavilion and the arid African savanna to the mysterious nocturnal house and the frozen Antarctic exhibit. Campers will conduct hands-on science experiments measuring water quality, soil composition, and biodiversity indices while learning ecological concepts like food webs, symbiotic relationships, and adaptation. Interactive field journals document daily discoveries, habitat observations, and species identification. Special activities include building miniature ecosystem terrariums to take home, participating in a simulated wildlife census, meeting conservation researchers, and designing creative proposals for habitat preservation projects in their own communities.'
WHERE Title LIKE '%Themed Ecosystem%';

-- Event 7: Conservation Action Camp
UPDATE Events SET Description = N'Empower the next generation of environmental leaders with our flagship Conservation Action Camp! This intensive week-long program is designed for ambitious, environmentally conscious teenagers aged 12-16 who want to make a real difference in wildlife conservation. Participants will dive deep into advanced ecological concepts including population genetics, habitat fragmentation analysis, climate change impacts on biodiversity, and sustainable resource management strategies used by professional conservation organizations worldwide. Working alongside our research scientists and field conservationists, campers will analyze real wildlife monitoring data, operate GPS tracking equipment, set up camera traps, and contribute to ongoing citizen science projects. The program culminates in teams designing and presenting their own comprehensive eco-campaigns addressing real conservation challenges, with winning proposals receiving funding to implement their ideas in partnership with local conservation organizations. All participants receive professional development certificates recognized by leading environmental organizations.'
WHERE Title LIKE '%Conservation Action%';

GO

PRINT N'════════════════════════════════════════';
PRINT N'✅ 23_UpdateEventDescriptions.sql HOÀN TẤT';
PRINT N'   Đã cập nhật mô tả chi tiết 100-150 từ cho 7 Events';
PRINT N'════════════════════════════════════════';
GO
