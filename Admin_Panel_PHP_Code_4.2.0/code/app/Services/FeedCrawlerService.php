<?php
namespace App\Services;

use App\Models\FeedItem;
use App\Models\RSS;
use Carbon\Carbon;
use Vedmant\FeedReader\Facades\FeedReader;
use Illuminate\Support\Facades\Log;

class FeedCrawlerService
{
    public function crawlAll(): void
    {
        RSS::where('status', true)->each(function (RSS $source) {
            $this->crawlSource($source);
        });
    }

    public function crawlSource(RSS $source): int
    {
        try {
            $feed = FeedReader::read($source->feed_url);

            if ($feed->error()) {
                Log::warning("Feed error for [{$source->feed_name}]: " . $feed->error());
                return 0;
            }

            $rows = [];
            $now  = Carbon::now('UTC')->toDateTimeString();

            foreach ($feed->get_items() as $item) {
                $guid = $item->get_id() ?: $item->get_permalink();

                if (!$guid) continue;

                $rows[] = [
                    'guid'          => $guid,
                    'rss_source_id' => $source->id,
                    'title'         => $item->get_title() ?? 'Untitled',
                    'url'           => $item->get_permalink(),
                    'description'   => $this->cleanDescription($item->get_description()),
                    'image_url'     => $this->extractImage($item),
                    'author'        => $this->extractAuthor($item),
                    'published_at'  => $this->parsePublishedAtUtc($item),
                    'fetched_at'    => $now,
                    'updated_at'    => $now,
                    'created_at'    => $now,
                ];
            }

            $count = count($rows);

            if ($count > 0) {
                // Single bulk upsert — matched on composite unique key (guid + rss_source_id)
                FeedItem::upsert(
                    $rows,
                    ['guid', 'rss_source_id'],                              // unique match columns
                    ['title', 'url', 'description', 'image_url', 'author', 'published_at', 'fetched_at', 'updated_at']
                );
            }

            $source->update(['last_fetched_at' => Carbon::now('UTC')]);
            Log::info("Crawled [{$source->feed_name}]: {$count} items processed.");

            return $count;

        } catch (\Throwable $e) {
            Log::error("Failed to crawl [{$source->feed_name}]: " . $e->getMessage());
            return 0;
        }
    }

    /**
     * Return the item's publish time as a UTC datetime string, or null if the date is missing.
     *
     * SimplePie normalizes every date to a Unix timestamp internally, so
     * get_date('U') is already timezone-agnostic. We only need to convert
     * when the stored value is not already UTC (e.g. the feed omitted a TZ
     * offset and PHP's strtotime assumed the server's local timezone).
     * Wrapping in Carbon::createFromTimestampUTC() handles that uniformly.
     */
    private function parsePublishedAtUtc($item): ?string
    {
        $ts = $item->get_date('U');

        if (!$ts) {
            return null;
        }

        return Carbon::createFromTimestampUTC((int) $ts)->toDateTimeString();
    }

    /**
     * Strip HTML tags and decode entities from a feed description.
     */
    private function cleanDescription(?string $description): ?string
    {
        if ($description === null || $description === '') {
            return null;
        }

        // Strip all HTML tags, then decode remaining HTML entities (e.g. &amp; &nbsp;)
        return trim(html_entity_decode(strip_tags($description), ENT_QUOTES | ENT_HTML5, 'UTF-8'));
    }

    /**
     * Try multiple strategies to extract an image from a feed item.
     */
    private function extractImage($item): ?string
    {
        // 1. media:content (NYT / Yahoo Media RSS — item-level, highest priority)
        $mediaContent = $item->get_item_tags(\SimplePie\SimplePie::NAMESPACE_MEDIARSS, 'content');
        if (!empty($mediaContent)) {
            foreach ($mediaContent as $mc) {
                $url = $mc['attribs']['']['url'] ?? null;
                if ($url) {
                    return $url;
                }
            }
        }

        // 2. media:thumbnail (item-level)
        $thumbnail = $item->get_thumbnail();
        if (!empty($thumbnail['url'])) {
            return $thumbnail['url'];
        }

        // 3. Enclosure (podcasts / standard RSS image attachment)
        $enclosure = $item->get_enclosure();
        if ($enclosure && str_starts_with((string) $enclosure->get_type(), 'image')) {
            return $enclosure->get_link();
        }

        // 4. Scrape first <img> from description as fallback
        $description = $item->get_description();
        if ($description) {
            preg_match('/<img[^>]+src=["\']([^"\']+)["\']/', $description, $matches);
            if (!empty($matches[1])) {
                return $matches[1];
            }
        }

        // 5. FINAL fallback -> channel/source image from the parent feed object
        $feed = $item->get_feed();
        if ($feed && method_exists($feed, 'get_image_url')) {
            $channelImage = $feed->get_image_url();
            if ($channelImage) {
                return $channelImage;
            }
        }

        return null;
    }

    /**
     * Try multiple strategies to extract an author from a feed item.
     *
     * Priority:
     *  1. Standard author tags: <author>, <dc:creator>, <atom:author>, <itunes:author>
     *  2. <media:credit role="author"> (MRSS / Yahoo Media RSS)
     *  3. <atom:source> authors
     *  4. Channel/feed title as last-resort fallback
     */
    private function extractAuthor($item): ?string
    {
        // 1. Standard RSS/Atom/DC/iTunes author tags (SimplePie handles all variants)
        $author = $item->get_author();
        if ($author && ($name = trim((string) $author->get_name())) !== '') {
            return $name;
        }

        // 2. <media:credit role="author" scheme="urn:ebu"> — MRSS extension
        $credits = $item->get_item_tags(\SimplePie\SimplePie::NAMESPACE_MEDIARSS, 'credit');
        if (!empty($credits)) {
            foreach ($credits as $credit) {
                $role = isset($credit['attribs']['']['role'])
                    ? strtolower(trim($credit['attribs']['']['role']))
                    : 'author';                 // default role per the spec is "author"
                if ($role === 'author' && !empty($credit['data'])) {
                    $name = trim(strip_tags($credit['data']));
                    if ($name !== '') {
                        return $name;
                    }
                }
            }
        }

        // 3. <atom:source> — inline source element carries its own author list
        $source = $item->get_source();
        if ($source) {
            $sourceAuthors = $source->get_authors();
            if (!empty($sourceAuthors)) {
                $name = trim((string) $sourceAuthors[0]->get_name());
                if ($name !== '') {
                    return $name;
                }
            }
        }

        // 4. Final fallback: use the channel/feed title
        $feed = $item->get_feed();
        if ($feed && method_exists($feed, 'get_title')) {
            $title = trim((string) $feed->get_title());
            if ($title !== '') {
                return $title;
            }
        }

        return null;
    }
}
