<?php

namespace Database\Seeders;

use App\Models\AdSpaces;
use App\Models\BreakingNews;
use App\Models\Category;
use App\Models\FeaturedSections;
use App\Models\Language;
use App\Models\LiveStreaming;
use App\Models\News;
use App\Models\Enews;
use App\Models\Podcasts;
use App\Models\PodcastEpisodes;
use App\Models\RSS;
use App\Models\SubCategory;
use App\Models\Tag;
use Carbon\Carbon;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\File;
use App\Models\VideoShort;
use Illuminate\Support\Str;


class DummyDataSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $languageId = Language::first()->id;

        $categories = [
            ['name' => 'Technology', 'slug' => 'technology'],
            ['name' => 'Science', 'slug' => 'science'],
            ['name' => 'Business', 'slug' => 'business'],
            ['name' => 'Religion', 'slug' => 'religion'],
            ['name' => 'Health', 'slug' => 'health'],
            ['name' => 'Entertainment', 'slug' => 'entertainment'],
            ['name' => 'Sports', 'slug' => 'sports'],
            ['name' => 'Politics', 'slug' => 'politics'],
            ['name' => 'Education', 'slug' => 'education'],
            ['name' => 'Top News', 'slug' => 'top-news'],
        ];

        $categoryIds = [];
        $tagIds = [];

        foreach ($categories as $index => $data) {

            $categoryImage = copyDummyImage('category', $index);

            $category = Category::updateOrCreate(
                ['slug' => $data['slug']],
                [
                    'language_id' => $languageId,
                    'category_name' => $data['name'],
                    'slug' => $data['slug'],
                    'image' => $categoryImage,
                    'meta_title' => $data['name'],
                    'meta_description' => $data['name'],
                    'meta_keyword' => $data['name'],
                    'schema_markup' => $data['name'],
                ]
            );
            $categoryIds[] = $category->id;

            SubCategory::updateOrCreate(
                ['slug' => $data['slug']],
                [
                    'language_id' => $languageId,
                    'category_id' => $category->id,
                    'subcategory_name' => $data['name'],
                    'slug' => $data['slug'],
                ]
            );

            // Copy tag image
            $tagImage = copyDummyImage('tag_og_image', $index);

            $tag = Tag::updateOrCreate(
                ['slug' => $data['slug']],
                [
                    'language_id' => $languageId,
                    'tag_name' => $data['name'],
                    'slug' => $data['slug'],
                    'meta_title' => $data['name'],
                    'meta_description' => $data['name'],
                    'meta_keyword' => $data['name'],
                    'schema_markup' => $data['name'],
                    'og_image' => $tagImage,
                ]
            );
            $tagIds[] = $tag->id;
        }

        $newsData = [
            ['title' => 'How To Enter International Space Station (ISS) Virtually Via Google Maps Street View', 'slug' => 'how-to-enter-international-space-station-iss-virtually-via-google-maps-street-view', 'description' => 'Google Maps is a very good tool for finding your way and going places you have not explored so far. However, not many people know that you can actually get a street view of the International Space Station from Google Maps.'],

            ['title' => 'NASA Invites Media to NOAA’s Advanced Weather Satellite Launch', 'slug' => 'nasa-invites-media-to-noaa-s-advanced-weather-satellite-launch', 'description' => 'NASA is preparing to launch NOAA’s (National Oceanic and Atmospheric Administration) GOES-U (Geostationary Operational Environmental Satellite U), a mission to help improve weather observing and environmental monitoring capabilities on Earth, as well as advance space weather observations.'],

            ['title' => 'Rise in Spending Through Credit Cards, Debit Cards, UPI Indicate Pick-Up In Consumption: FinMin', 'slug' => 'rise-in-spending-through-credit-cards-debit-cards-upi-indicate-pick-up-in-consumption-finmin', 'description' => 'Spending through credit cards and debit cards in April jumps 77.8 per cent and 12.5 per cent to Rs 1.05 lakh crore and 3.49 lakh crore, respectively. The increase in spending, together with rising UPI-based payments, indicate a pick-up in consumption as the pandemic-induced restrictions recede and uncertainty reduces, the finance ministry said on Monday.

            “Value of UPI transactions processed through the National Payment Corporation of India (NPCI) stood at Rs 10.4 lakh crore during May 2022, the highest since UPI was launched in 2016, registering month-on-month growth of 5.9 per cent, while the volume of UPI transactions stood at 599 crore growing month-on-month at 7.4 per cent," the ministry said in the Monthly Economic Report for May 2022.'],

            ['title' => 'Tamil Nadu Woman Becomes First Indian To Get No Caste, No Religion Certificate After 9-Year-Long Battle', 'slug' => 'tamil-nadu-woman-becomes-first-indian-to-get-no-caste-no-religion-certificate-after-9-year-long-battle', 'description' => 'The caste system may have been legally abolished in 1950, but if you live in India, the box for you to fill in caste and religion is still present in a lot of forms. Some of these boxes on forms are also compulsory, and you do not always have the option of leaving them empty.

            The closest option you get is Choose not to say or Other as an answer to these boxes.

            A woman from Tamil Nadu, however, can now choose to not answer these on any forms as she officially has no caste, no religion.

            On February 5th, Sneha Parthibaraja, a 35-year-old lawyer from Vellore became the first person in the country to win the right to not have any caste or religion associated with her identity after a 9-year-old court battle.'],

            ['title' => 'International Yoga Day 2022: Practising These 8 Limbs of Yoga Can Help You Attain Enlightenment', 'slug' => 'international-yoga-day-2022-practising-these-8-limbs-of-yoga-can-help-you-attain-enlightenment', 'description' => 'Today, the world is observing International Day of Yoga 2022 to raise awareness about the health and well-being advantages of yoga. The International Yoga Day also educates about Yoga, which started thousands of years ago in India. It is a collection of physical, mental, and spiritual disciplines that have become popular as a way of life in the modern day. When we hear the word “yoga," we think of exercises that help us stretch or keep our bodies flexible. This western-inspired, transmogrified and neo form of yoga has made us forget our ancient roots in it.

            The word “yoga" originates from the Sanskrit root verb “yuj", which means “to unite with”. Yoga is the process through which we unite with Parabraḥma and discover the reality of our true self. Thus, it is said that Yoga is the path from jīva (individual) to Śiva (Parabraḥma). To achieve this unification with the higher reality, Guru Patanjali says one must be “Ishvara pranidhāna va", i.e., the practitioner of yoga must have steadfast devotion towards the gods. Bhagwan Shiva is believed to be the first Adi Yogi, or Yogi. It was passed down to his seven disciples, and they spread it throughout the whole world. But we don’t have any records for it as in the ancient period it was written on palm leaves, which we gradually lost over centuries and millennials.'],

            ['title' => 'Virat Kohli, Rohit Sharma move up in ICC T20 rankings', 'slug' => 'virat-kohli-rohit-sharma-move-up-in-icc-t20-rankings', 'description' => 'Dubai, Mar 24 (PTI) India captain Virat Kohli moved up a place to fourth in the ICC T20 rankings for batsmen, while his deputy Rohit Sharma climbed three spots to 14th in the latest list issued on Wednesday.

            Kohli, who slammed an unbeaten 80 off 52 balls coming in as an opener in the series against England, is now the highest ranked from India ahead of K L Rahul.

            Rohit 34-ball 64 in that match has helped him move up three places to 14th in the weekly update which took into account the three-match Afghanistan-Zimbabwe series in Abu Dhabi apart from the last two matches of the India-England series, the ICC stated.

            In other gains for India batsmen, Shreyas Iyer has moved up five places to a career-best 26th position while rookie Suryakumar Yadav and wicketkeeper-batsman Rishabh Pant too have made rapid progress.

            Yadav, who debuted in the second match of the series but could not garner any points as he did not get to bat, has pushed up from the bottom to 66th position after scores of 57 and 32 while Pant has moved up 11 places to 69th in the rankings.

            Seam bowler Bhuvneshwar Kumar, player of the match in the last game for his spell of two for 15, has moved up 21 places to 24th while Hardik Pandya has advanced 47 places to 78th.

            For England, Dawid Malan maintains a healthy lead at the top of the rankings after his 68 in the final match while Jos Buttler has inched up one place to 18th.'],

            ['title' => 'Modi@8: Scale and Sustainability are the Modi Mantra for India’s Successful Infra Story', 'slug' => 'modi-8-scale-and-sustainability-are-the-modi-mantra-for-india-s-successful-infra-story', 'description' => 'May 25, 2022. It is 5 am. Narendra Damodardas Modi lands at Palam Airforce Station fresh, despite two nights in plane and one night in Tokyo, holding 24 meetings in 41 hours. For the PM, it is work time again – first Cabinet meeting, next progress review of infrastructure projects, in between offering condolences to families of six tourists who died in a road accident in Odisha, and ending the day with a tweet on ‘I will be in Hyderabad and Chennai tomorrow.

            This is the ‘Modi way’.

            This week, Narendra Modi completed eight years as the Prime Minister and started on the ninth year with focused pursuit to build modern, top-quality, futuristic and sustainable infrastructure at a scale not achieved in the past. This article attempts to assess the Modi government’s performance in the infrastructure sector in these eight years. I start by sharing three stories – of Modi and I, Modi and Nilekani, and Modi and Modi.'],

            ['title' => 'Sensex, Nifty up amid rising US rate cut hopes; Zomato, Paytm shares gain', 'slug' => 'sensex-nifty-up-amid-rising-us-rate-cut-hopes-zomato-paytm-shares-gain', 'description' => 'Sensex, Nifty up amid rising US rate cut hopes; Zomato, Paytm shares gain'],

            ['title' => 'Can India be a global role model for climate-friendly energy growth?', 'slug' => 'can-india-be-a-global-role-model-for-climate-friendly-energy-growth', 'description' => 'India has entered discussions to join the International Energy Agency (IEA) as a full member — a move that would recognize the world’s most populous country as a key player in tackling global energy and climate challenges.

            If successful, India would become the first country from outside the Organisation for Economic Co-operation and Development (OECD) to join the highest ranks of the IEA. Its acceptance would formally recognize India’s role as an economic leader with tremendous potential as a buyer and seller of energy, a leading producer of renewable energy, and a model for other countries with emerging economies.

            “India kind of has an outsized role in the global energy dialogue right now, being an energy demand giant. IEA needs India to be at their table,” said Mohua Mukherjee, an independent senior energy expert working at the Oxford Institute for Energy Studies.

            For the last half-century, full membership in the IEA — an intergovernmental organization that promotes energy security and the world’s transition to clean energy — has been limited to the 31 members of the OECD. These are mostly high-income countries situated in the West.'],
            ['title' => 'The Impact of 5G Rollout in Rural India', 'slug' => 'impact-of-5g-rollout-in-rural-india', 'description' => 'With the introduction of 5G technology in India, rural areas are witnessing significant transformations in connectivity, healthcare, and education. This article explores the initial impact and future prospects of 5G-enabled services in villages.'],
            ['title' => 'How AI is Revolutionizing Indian Agriculture', 'slug' => 'ai-revolutionizing-indian-agriculture', 'description' => 'Artificial Intelligence-powered tools are now helping Indian farmers increase crop yields, predict weather patterns, and manage resources efficiently, marking a new era in agricultural productivity.'],
            ['title' => 'The Evolution of Renewable Energy in India', 'slug' => 'evolution-of-renewable-energy-in-india', 'description' => 'India has emerged as a leader in renewable energy adoption with exponential growth in solar and wind power generation, accelerating the nation towards a sustainable future.'],
            ['title' => 'India’s Startup Ecosystem Among World’s Fastest Growing', 'slug' => 'indias-startup-ecosystem-among-worlds-fastest-growing', 'description' => 'Home to thousands of new startups, India’s entrepreneurial landscape is now the third largest in the world, driving innovation in fintech, healthtech, and edtech.'],
            ['title' => 'Green Mobility: Electric Vehicles Gain Traction in Indian Cities', 'slug' => 'green-mobility-electric-vehicles-india', 'description' => 'Indian cities are witnessing a surge in electric vehicle adoption, supported by government incentives and growing consumer awareness about environmentally friendly transportation solutions.'],
            ['title' => 'The Rise of Esports Among India’s Youth', 'slug' => 'rise-of-esports-among-indians-youth', 'description' => 'Esports has become a mainstream pursuit for India’s younger generations, with increasing numbers of tournaments, professional gamers, and digital communities forming across the country.'],
            ['title' => 'Remote Work: Changing the Urban Landscape in India', 'slug' => 'remote-work-changing-urban-landscape-india', 'description' => 'The shift toward remote and hybrid work has led Indian companies to rethink office spaces, commute patterns, and talent acquisition, transforming traditional urban environments.'],
            ['title' => 'Water Conservation Efforts Bear Fruit in Maharashtra', 'slug' => 'water-conservation-efforts-maharashtra', 'description' => 'Successful community projects in Maharashtra demonstrate effective water conservation strategies, offering a model for sustainable water management in drought-prone regions.'],
            ['title' => 'Yoga and Mindfulness Practices Bring Calm to Busy Lives', 'slug' => 'yoga-mindfulness-practices-bring-calm', 'description' => 'Integrating yoga and mindfulness routines helps people cope with the pressures of urban living, improve mental well-being, and boost overall wellness across ages.'],
            ['title' => 'Indian Cinema Goes Global: A New Wave of Film Exports', 'slug' => 'indian-cinema-goes-global', 'description' => 'Bollywood and regional Indian movies are receiving unprecedented acclaim abroad, with Indian filmmakers collaborating on international co-productions and securing global box office success.'],
        ];

        foreach ($newsData as $index => $data) {
            $categoryId = $categoryIds[$index % count($categoryIds)]; // cycle through categories
            $randomTags = collect($tagIds)->shuffle()->take(2)->toArray();
            $tagString = implode(',', $randomTags); // "1,5" format

            $news = News::updateOrCreate(
                ['slug' => $data['slug']], // unique identifier
                [
                    'language_id' => $languageId,
                    'category_id' => $categoryId,
                    'tag_id' => $tagString,
                    'location_id' => 0,
                    'title' => $data['title'],
                    'slug' => $data['slug'],
                    'image' => copyDummyImage('news', $index),
                    'date' => Carbon::now()->format('Y-m-d H:i:s'),
                    'published_date' => Carbon::now()->format('Y-m-d'),
                    'content_type' => 'standard_post',
                    'description' => $data['title'],
                    'user_id' => 0,
                    'admin_id' => 0,
                    'status' => 1,
                    'is_clone' => 0,
                    'counter' => 0,
                    'meta_title' => $data['title'],
                    'meta_description' => $data['title'],
                    'is_comment' => 1,
                    'show_till' => '0000-00-00'
                ]
            );
            $newsIds[] = $news->id;
        }

        // Enews dummy data
        $eNewsData = [
            ['title' => 'How To Enter International Space Station (ISS) Virtually Via Google Maps Street View', 
            'slug' => 'how-to-enter-international-space-station-iss-virtually-via-google-maps-street-view', 
            'description' => 'Google Maps is a very good tool for finding your way and going places you have not explored so far.'],

            ['title' => 'NASA Invites Media to NOAA’s Advanced Weather Satellite Launch', 'slug' => 'nasa-invites-media-to-noaa-s-advanced-weather-satellite-launch', 'description' => 'NASA is preparing to launch NOAA’s (National Oceanic and Atmospheric Administration) GOES-U (Geostationary Operational Environmental Satellite U), a mission to help improve weather observing and environmental monitoring capabilities on Earth, as well as advance space weather observations.'],

        ];

        foreach ($eNewsData as $index => $data) {
            Enews::updateOrCreate(
                ['slug' => $data['slug']],
                [
                    'language_id'      => $languageId,
                    'title'            => $data['title'],
                    'slug'             => $data['slug'],
                    'description'      => $data['description'],
                    'thumbnail'        => copyDummyImage('enews', $index),
                    'attachment'       => copyDummyPdf($index),
                    'date'             => Carbon::now()->format('Y-m-d'),
                    'meta_title'       => $data['title'],
                    'meta_description' => $data['description'],
                    'meta_keyword'     => $data['title'],
                    'schema_markup'    => '',
                    'status'           => 1,
                ]
            );
        }

        $breakingNewsData = [
            ['title' => 'WhatsApp rolls out new features for Communities', 'slug' => 'whatsapp-rolls-out-new-features-for-communities', 'description' => 'WhatsApp is getting new features for Communities and their groups that will allow users to organise events and reply to admin announcements in Community Announcement Groups announced Meta chief Mark Zuckerberg on his WhatsApp Channel.

            Groups that are part of a WhatsApp community can now create events for their groups, facilitating both in-person and online gatherings.'],

            ['title' => 'Chat GPT and Future of AI', 'slug' => 'chat-gpt-and-future-of-ai', 'description' => 'ChatGPT is a conversational AI chatbot that is able to produce text for you based on any prompt you input, generating emails, essays, poems, raps, grocery lists, letters and much more.

            In addition to writing for you, it can chat with you about simple or complex topics such as "What are colors?" or "What is the meaning of life?" ChatGPT is also proficient in STEM and can write and debug code, and even solve complex math equations. The best part is that the service is completely free to the public right now because it is still in its research and feedback-collection phase.'],

            ['title' => 'In US Shocker, Senator Suggests Israel Should Be Allowed To Nuke Gaza', 'slug' => 'in-us-shocker-senator-suggests-israel-should-be-allowed-to-nuke-gaza', 'description' => 'In US Shocker, Senator Suggests Israel Should Be Allowed To Nuke Gaza'],

            ['title' => 'This Solar-Electric Car Has Over 1000 Km Range, Needs Charge Once in 7 Months', 'slug' => 'this-solar-electric-car-has-over-1000-km-range-needs-charge-once-in-7-months',  'description' => 'Electric cars are being unveiled every other day now but the major challenge remains their change. That too may be a thing of the past. Lightyear, a company developing solar electric cars, has revealed their first production-ready vehicle, the Lightyear 0. The vehicle uses both solar and electric energy to run the powertrain which, the company claims, has boosted the range of the vehicle beyond 1000 kilometres.

            “After six years of R&D, design, engineering, prototyping, and testing, this premier solar car is slated to go into production this fall,” read the official statement. “In 2016, we only had an idea; three years later, we had a prototype. Now, after six years of testing, iterating, re(designing), and countless obstacles, Lightyear 0 is proof that the impossible is actually possible,” said Lightyear CEO Lex Hoefsloot.'],

            ['title' => 'Does apple cider vinegar really have health super powers?', 'slug' => 'does-apple-cider-vinegar-really-have-health-super-powers', 'description' => 'Does apple cider vinegar really have health super powers?'],

            ['title' => 'Samsung Electronics To Showcase How Enhanced AI and Connectivity Enable Expansive Kitchen Experiences at CES 2024', 'slug' => 'samsung-electronics-to-showcase-how-enhanced-ai-and-connectivity-enable-expansive-kitchen-experiences-at-ces-2024', 'description' => 'Samsung Electronics Co., Ltd. today announced that it will use CES® 2024 to introduce Samsung’s newest kitchen products, applications, and features, which include artificial intelligence (AI) features and SmartThings connectivity, enabling an ecosystem that delivers new food and kitchen experiences with Samsung products. Notable products and features in the lineup include the 2024 Bespoke 4-Door Flex™ Refrigerator with AI Family Hub™ — which was Samsung’s first home Internet of Things (IoT) refrigerator launched in 2016 — now equipped with the all-new AI Vision Inside feature, the new Anyplace Induction Cooktop and enhancements to the Samsung Food service.'],

            ['title' => 'ICC 0:20 / 5:00 The Making of the ICC Cricket World Cup Trophy', 'slug' => 'icc-020-500-the-making-of-the-icc-cricket-world-cup-trophy', 'description' => 'ICC 0:20 / 5:00 The Making of the ICC Cricket World Cup Trophy'],

            ['title' => 'Supreme Court to urgently hear plea on ‘delay’ in voter turnout data publication on May 17', 'slug' => 'supreme-court-to-urgently-hear-plea-on-delay-in-voter-turnout-data-publication-on-may-17', 'description' => 'The Supreme Court is scheduled to urgently hear on May 17 an application alleging inordinate delay in the publication of voter turnout data of the first two phases of polling in the Lok Sabha elections.

            Mr. Bhushan had urged for an early hearing by the court in the background of the ongoing elections.

            Besides delay in publishing the voter-turnout details, the application said there was a sharp spike in figures from the initial voter turnout percentages released by the Election Commission (EC).

            Mr. Bhushan said both these developments, post polling in the initial phases, had raised concerns and public suspicion regarding the accuracy of the data.

            The plea has urged the court to direct the EC to disclose authenticated record of voter turnout by uploading on its website scanned legible copies of account of votes recorded at polling stations after each phase of voting in the on-going Lok Sabha elections. Rule 49S and Rule 56C(2) of the Conduct of Election Rules, 1961 require the presiding officer to prepare an account of votes recorded in form 17C (Part I) and the returning officer to record the number of votes in favour of each candidate.'],

            ['title' => 'The Future of OER in Higher Education', 'slug' => 'the-future-of-oer-in-higher-education', 'description' => 'The past few years have brought drastic changes to higher education, in both how students learn and how instructors teach. Whether due to increases in remote and hybrid learning during the COVID-19 pandemic or the growing prominence of generative artificial intelligence (GenAI), business educators have had to adapt to change quickly, often without much institutional support.

            Even through all this upheaval, textbooks have remained the most popular course material in higher education, according to a survey conducted by the research firm Bay View Analytics. However, increasingly instructors are replacing print materials such as hardcopy textbooks and homework handouts with digital options such as online textbooks and homework assistance platforms. Instructors also have embraced open educational resources (OER). Bay View’s data also show that the percentage of educators using OER as required course materials nearly doubled between the 2019–20 and 2022–23 academic years, from 15 percent to 29 percent.'],

            ['title' => 'Stay Ahead of the Curve - Breaking News on the Latest Developments in the World of Bitcoin.', 'slug' => 'stay-ahead-of-the-curve-breaking-news-on-the-latest-developments-in-the-world-of-bitcoin', 'description' => 'Stay informed and stay ahead of the game with our up-to-the-minute coverage on the latest Bitcoin news and developments, delivering comprehensive insights and analysis on the world leading cryptocurrency.'],
            // add 10 more breaking news data
            ['title' => 'NASA’s Artemis II Moon Mission Delayed to September 2025', 'slug' => 'nasa-artemis-ii-mission-delayed', 'description' => 'NASA has announced that the Artemis II crewed mission around the moon has been delayed to September 2025 due to safety reviews and technical challenges. This mission marks the next step in returning humans to lunar exploration.'],
            ['title' => 'India Passes Landmark Data Protection Bill', 'slug' => 'india-passes-landmark-data-protection-bill', 'description' => 'The Indian Parliament has passed the Digital Personal Data Protection Bill, aiming to regulate how companies collect and handle digital data, promising greater security and privacy for the country’s citizens.'],
            ['title' => 'Tesla Unveils Fully Self-Driving Robotaxi', 'slug' => 'tesla-unveils-fully-self-driving-robotaxi', 'description' => 'Elon Musk announced the launch of Tesla’s first fully autonomous robotaxi, marking a milestone in driverless technology and urban transportation.'],
            ['title' => 'China Successfully Tests Quantum Internet Satellite', 'slug' => 'china-successfully-tests-quantum-internet-satellite', 'description' => 'China has made significant advances in quantum technology, successfully launching a satellite capable of unhackable quantum communication, paving the way for a new era of internet security.'],
            ['title' => 'Apple Introduces Revolutionary Foldable iPhone', 'slug' => 'apple-introduces-foldable-iphone', 'description' => 'Apple officially revealed its first foldable iPhone at a global launch event, blending larger screen real estate with signature iOS innovation.'],
            ['title' => 'Euro 2024: France Crowned European Champions', 'slug' => 'france-crowned-euro-2024-champions', 'description' => 'France secured their third European Championship title by defeating Germany in a thrilling final, celebrated by fans across the globe.'],
            ['title' => 'United Nations Publishes Climate Action Roadmap for 2030', 'slug' => 'un-publishes-climate-action-roadmap-2030', 'description' => 'The United Nations has released a new roadmap outlining ambitious targets to mitigate climate change, urging countries to take decisive action by 2030 to keep global warming under control.'],
            ['title' => 'AI Breakthrough Predicts Protein Structures in Seconds', 'slug' => 'ai-breakthrough-protein-structure-prediction', 'description' => 'Researchers have announced a major breakthrough in artificial intelligence, with algorithms able to predict complex protein structures within seconds, promising to accelerate drug discovery.'],
            ['title' => 'Bitcoin Hits Record High Amid Market Surge', 'slug' => 'bitcoin-hits-record-high-2024', 'description' => 'Bitcoin’s value reached an all-time high, surpassing previous records as cryptocurrency adoption accelerates worldwide, signaling increased confidence from investors and institutions.'],
            ['title' => 'Japan Opens World’s First Automated Sushi Restaurant', 'slug' => 'japan-opens-automated-sushi-restaurant', 'description' => 'A Tokyo restaurant has debuted the world\'s first fully automated sushi-making experience, combining robotics and AI to revolutionize the dining sector.'],
        ];

        foreach ($breakingNewsData as $index => $data) {
            $categoryId = $categoryIds[$index % count($categoryIds)];
            $randomTags = collect($tagIds)->shuffle()->take(2)->toArray();
            $tagString = implode(',', $randomTags);

            BreakingNews::updateOrCreate(
                ['slug' => $data['slug']],
                [
                    'language_id' => $languageId,
                    'title' => $data['title'],
                    'slug' => $data['slug'],
                    'image' => copyDummyImage('breaking_news', $index),
                    'content_type' => 'standard_post',
                    'description' => $data['description'],
                    'meta_title' => $data['title'],
                    'meta_description' => $data['description'],
                ]
            );
        }

        $liveStreamingData = [
            ['title' => 'Technology'],
            ['title' => 'Science'],
            ['title' => 'Business'],
            ['title' => 'Religion'],
            ['title' => 'Health'],
        ];

        foreach ($liveStreamingData as $index => $data) {
            LiveStreaming::updateOrCreate(
                ['title' => $data['title']],
                [
                    'language_id' => $languageId,
                    'image' => copyDummyImage('liveStreaming', $index),
                    'type' => 'url_youtube',
                    'url' => 'https://www.youtube.com/watch?v=oIo-Wg-NCDo',
                    'meta_title' => $data['title'],
                    'meta_description' => $data['title'],
                    'meta_keyword' => $data['title'],
                    'schema_markup' => $data['title'],
                ]
            );
        }

        $rssFeeds = [
            ['feed_name' => 'Technology'],
            ['feed_name' => 'Science'],
            ['feed_name' => 'Business'],
            ['feed_name' => 'Religion'],
            ['feed_name' => 'Health'],
        ];

        foreach ($rssFeeds as $index => $data) {
            RSS::updateOrCreate(
                ['feed_name' => $data['feed_name']],
                [
                    'language_id' => $languageId,
                    'category_id' => $categoryIds[$index],
                    'tag_id' => $tagIds[$index],
                    'feed_url' => 'https://newsweb.wrteam.me',
                    'status' => 1,
                ]
            );
        }

        $featuredSectionsData = [
            [
                'title' => 'Technology',
                'slug' => 'technology',
                'short_description' => 'Technology',
                'news_type' => 'news',
                'filter_type' => 'custom',
                'news_ids' => $newsIds[0],
                'style_app' => 'style_1',
                'style_web' => 'style_1',
            ],
            [
                'title' => 'Science',
                'slug' => 'science',
                'short_description' => 'Science',
                'news_type' => 'news',
                'filter_type' => 'custom',
                'news_ids' => $newsIds[1],
                'style_app' => 'style_2',
                'style_web' => 'style_2',
            ],
            [
                'title' => 'Business',
                'slug' => 'business',
                'short_description' => 'Business',
                'news_type' => 'news',
                'filter_type' => 'custom',
                'news_ids' => $newsIds[2],
                'style_app' => 'style_3',
                'style_web' => 'style_3',
            ],
            [
                'title' => 'Religion',
                'slug' => 'religion',
                'short_description' => 'Religion',
                'news_type' => 'news',
                'filter_type' => 'most_viewed',
                'category_ids' => $categoryIds[3],
                'style_app' => 'style_4',
                'style_web' => 'style_4',
            ],
            [
                'title' => 'Health',
                'slug' => 'health',
                'short_description' => 'Health',
                'news_type' => 'news',
                'filter_type' => 'most_commented',
                'category_ids' => $categoryIds[4],
                'style_app' => 'style_5',
                'style_web' => 'style_5',
            ],
        ];

        $featuredSectionIds = [];

        foreach ($featuredSectionsData as $section) {
            $featured = FeaturedSections::updateOrCreate(
                ['slug' => $section['slug']],
                array_merge($section, [
                    'language_id' => $languageId,
                    'row_order' => 0,
                    'status' => 1,
                    'is_based_on_user_choice' => 0,
                    'meta_title' => $section['title'],
                    'meta_description' => $section['title'],
                    'meta_keyword' => $section['title'],
                    'schema_markup' => $section['title'],
                ])
            );

            $featuredSectionIds[] = $featured->id;
        }

       $webAds = [
            [
                'page' => 'home_page',
                'placement' => 'top',
            ],
            [
                'page' => 'home_page',
                'placement' => 'bottom',
            ],
        ];

        foreach ($webAds as $index => $ad) {

            AdSpaces::create([
                "language_id"            => 1,
                "platform"               => "web",
                "page"                   => $ad['page'],
                "placement"              => $ad['placement'],
                "ad_type"                => "banner_only",
                "ad_url"                 => "",
                "duration_days"          => 1,
                "ad_featured_section_id" => $featuredSectionIds[$index],
                "web_ad_image"           => copyAdspaceDummyImage('web', $index),
                "ad_image"               => "",
                "status"                 => 1,
                "start_date"             => now()->format('Y-m-d'),
                "end_date"               => now()->addDay()->format('Y-m-d'),
            ]);
        }
      $appAds = [
            [
                'page' => 'news_details_screen',
                'placement' => 'news_details_top',
            ],
            [
                'page' => 'news_details_screen',
                'placement' => 'news_details_top',
            ],
            [
                'page' => 'news_details_screen',
                'placement' => 'news_details_bottom',
            ],
        ];

        foreach ($appAds as $index => $ad) {

            AdSpaces::create([
                "language_id"            => 1,
                "platform"               => "app",
                "page"                   => $ad['page'],
                "placement"              => $ad['placement'],
                "ad_type"                => "external_link",
                "ad_url"                 => "https://newsweb.wrteam.me/en/video-news",
                "duration_days"          => 1,
                "ad_featured_section_id" => $featuredSectionIds[$index],
                "ad_image"               => copyAdspaceDummyImage('app', $index),
                "web_ad_image"           => "",
                "status"                 => 1,
                "start_date"             => now()->format('Y-m-d'),
                "end_date"               => now()->addDay()->format('Y-m-d'),
            ]);
        }
        $videoShorts = [
            [
                'title' => 'Funny Reel 1',
                'description' => 'Funny short video',
            ],
            [
                'title' => 'Gaming Clip 1',
                'description' => 'Gaming short video',
            ],
        ];

        foreach ($videoShorts as $index => $video) {

            VideoShort::updateOrCreate(
                [
                    'slug' => Str::slug($video['title']),
                ],
                [
                    "language_id"    => 1,
                    "category_id"    => 1,
                    "title"          => $video['title'],
                    "slug"           => Str::slug($video['title']),
                    "video_url"      => copyVideoShortsDummyVideo($index),
                    "description"    => $video['description'],
                    "published_date" => now(),
                    "status"         => 1,
                    "views_count"    => 0,
                    "shares_count"   => 0,
                ]
            );
        }

        // Podcasts: admin-created via the web panel, so no author owner -
        // podcasts.user_id has a real FK constraint against tbl_users, so
        // "no author" must be NULL here (unlike News's `user_id = 0` sentinel).
        $podcastsData = [
            ['title' => 'Global Affairs Today', 'slug' => 'global-affairs-today', 'description' => 'A closer look at the news and policy shaping the world.'],
            ['title' => 'Startup Stories', 'slug' => 'startup-stories', 'description' => 'Founders share the highs and lows of building something new.'],
        ];

        foreach ($podcastsData as $index => $data) {
            $podcast = Podcasts::updateOrCreate(
                ['slug' => $data['slug']],
                [
                    'user_id' => null,
                    'title' => $data['title'],
                    'description' => $data['description'],
                    'image' => copyDummyImage('podcasts', $index),
                    'draft' => false,
                    'status' => 1,
                    'published_at' => now()->subDays(count($podcastsData) - $index),
                ]
            );

            for ($episodeNo = 1; $episodeNo <= 3; $episodeNo++) {
                PodcastEpisodes::updateOrCreate(
                    [
                        'podcast_id' => $podcast->id,
                        'episode_no' => $episodeNo,
                    ],
                    [
                        'title' => $data['title'] . ' - Episode ' . $episodeNo,
                        'slug' => $data['slug'] . '-episode-' . $episodeNo,
                        'description' => 'Episode ' . $episodeNo . ' of ' . $data['title'] . '.',
                        'image' => copyDummyImage('episodes_images', $index + $episodeNo),
                        'source_type' => 'youtube_link',
                        'audio_url' => 'https://www.youtube.com/watch?v=oIo-Wg-NCDo',
                        'status' => 1,
                        'duration_seconds' => rand(600, 3600),
                        'draft' => false,
                        'published_at' => now()->subDays(3 - $episodeNo),
                    ]
                );
            }
        }

    }
}

function copyDummyImage(string $type, int $index): string
{
    $dummyIndex = ($index % 10) + 1;
    $fileName = "dummy-{$dummyIndex}.jpg";

    $source = public_path("images/dummy_images/{$fileName}");
    $destinationDir = public_path("storage/{$type}");
    $destination = "{$destinationDir}/{$fileName}";

    if (!File::exists($source)) {
        throw new \Exception("Missing dummy image: {$source}");
    }

    if (!File::exists($destination)) {
        File::ensureDirectoryExists($destinationDir);
        File::copy($source, $destination);
    }

    return "{$type}/{$fileName}";
}

    function copyAdspaceDummyImage(string $subType, int $index): string
    {
        $dummyIndex = ($index % 10) + 1;
        
        $fileName = "dummy-{$dummyIndex}.jpg";

        $originalFile = "dummy-{$dummyIndex}.jpg";

        $fileName = uniqid() . "-{$originalFile}";

        $source = public_path("images/dummy_images/adspace/{$subType}/{$originalFile}");

        $destinationDir = public_path("storage/ad_spaces");

        $destination = "{$destinationDir}/{$fileName}";

        if (!File::exists($source)) {
            throw new \Exception("Missing adspace dummy image: {$source}");
        }

        if (!File::exists($destination)) {
            File::ensureDirectoryExists($destinationDir);
            File::copy($source, $destination);
        }

        return "ad_spaces/{$fileName}";
    }

function copyDummyPdf(int $index): string
{
    $pdfs = array_values(array_filter(
        scandir(public_path('images/dummy_pdf')),
        fn($f) => str_ends_with($f, '.pdf')
    ));

    if (empty($pdfs)) {
        throw new \Exception('No dummy PDFs found in public/images/dummy_pdf');
    }

    $fileName = $pdfs[$index % count($pdfs)];
    $source   = public_path("images/dummy_pdf/{$fileName}");
    $destinationDir = public_path('storage/enews');
    $destination    = "{$destinationDir}/{$fileName}";

    if (!File::exists($destination)) {
        File::ensureDirectoryExists($destinationDir);
        File::copy($source, $destination);
    }

    return "enews/{$fileName}";
}

function copyVideoShortsDummyVideo( int $index): string
{
    $dummyIndex = ($index % 10) + 1;
    $fileName = "dummy-{$dummyIndex}.mp4";

    $source = public_path("videos/dummy_videos/videoshorts/{$fileName}");

    $destinationDir = public_path("storage/video_shorts");
    $destination = "{$destinationDir}/{$fileName}";

    if (!File::exists($source)) {
        throw new \Exception("Missing video shorts dummy video: {$source}");
    }

    if (!File::exists($destination)) {
        File::ensureDirectoryExists($destinationDir);
        File::copy($source, $destination);
    }

    return "video_shorts/{$fileName}";
}
