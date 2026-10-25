<?php

namespace Database\Seeders;

use App\Models\Author;
use App\Models\Podcasts;
use App\Models\PodcastEpisodes;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\File;

class PodcastDummySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // A couple of dummy author users — some podcasts below are owned by
        // these (author-created via API), others by user_id 0 (admin-created
        // via the web panel), mirroring how News tells the two apart.
        $authorUsersData = [
            ['name' => 'Ravi Sharma', 'email' => 'ravi.sharma.podcast@example.com'],
            ['name' => 'Meera Nair', 'email' => 'meera.nair.podcast@example.com'],
        ];

        $authorUserIds = [];
        foreach ($authorUsersData as $data) {
            $user = User::updateOrCreate(
                ['email' => $data['email']],
                [
                    'name' => $data['name'],
                    'type' => 'email',
                    'status' => 1,
                    'date' => now()->format('Y-m-d'),
                    'is_author' => 1,
                ]
            );

            Author::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'bio' => 'Dummy podcast author account for ' . $data['name'],
                    'status' => 'approved',
                    'auto_approve' => true,
                ]
            );

            $authorUserIds[] = $user->id;
        }

        $podcastsData = [
            ['title' => 'Tech Talk Weekly', 'slug' => 'tech-talk-weekly', 'description' => 'A weekly dive into the latest in technology, gadgets, and software trends.'],
            ['title' => 'The Business Edge', 'slug' => 'the-business-edge', 'description' => 'Insights and interviews on business strategy, startups, and finance.'],
            ['title' => 'Health & Wellness Hour', 'slug' => 'health-and-wellness-hour', 'description' => 'Expert conversations on fitness, nutrition, and mental wellbeing.'],
            ['title' => 'Sports Roundup', 'slug' => 'sports-roundup', 'description' => 'Weekly recap and analysis of the biggest moments in sports.'],
            ['title' => 'Science Unplugged', 'slug' => 'science-unplugged', 'description' => 'Breaking down complex science topics into everyday, easy-to-follow conversations.'],
            ['title' => 'Culture Currents', 'slug' => 'culture-currents', 'description' => 'Exploring film, music, and the trends shaping culture today.'],
        ];

        foreach ($podcastsData as $index => $data) {
            // Alternate ownership: even index -> admin-created (no owner, unlike
            // News's `user_id = 0` sentinel — podcasts.user_id has a real FK
            // constraint against tbl_users, so "no author" must be NULL here),
            // odd index -> a dummy author user.
            $ownerId = $index % 2 === 0 ? null : $authorUserIds[intdiv($index, 2) % count($authorUserIds)];

            $podcast = Podcasts::updateOrCreate(
                ['slug' => $data['slug']],
                [
                    'user_id' => $ownerId,
                    'title' => $data['title'],
                    'description' => $data['description'],
                    'image' => copyPodcastDummyImage('podcasts', $index),
                    'draft' => false,
                    'status' => 1,
                    'published_at' => now()->subDays(count($podcastsData) - $index),
                ]
            );

            // 8 to 15 episodes per podcast.
            $episodeCount = rand(8, 15);

            for ($episodeNo = 1; $episodeNo <= $episodeCount; $episodeNo++) {
                PodcastEpisodes::updateOrCreate(
                    [
                        'podcast_id' => $podcast->id,
                        'episode_no' => $episodeNo,
                    ],
                    [
                        'title' => $data['title'] . ' - Episode ' . $episodeNo,
                        'slug' => $data['slug'] . '-episode-' . $episodeNo,
                        'description' => 'Episode ' . $episodeNo . ' of ' . $data['title'] . '.',
                        'image' => copyPodcastDummyImage('episodes_images', $index + $episodeNo),
                        'source_type' => 'youtube_link',
                        'audio_url' => 'https://www.youtube.com/watch?v=oIo-Wg-NCDo',
                        'status' => 1,
                        'duration_seconds' => rand(600, 3600),
                        'draft' => false,
                        'published_at' => now()->subDays($episodeCount - $episodeNo),
                    ]
                );
            }
        }
    }
}

function copyPodcastDummyImage(string $type, int $index): string
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
