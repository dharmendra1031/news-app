<?php

namespace App\Jobs;

use App\Models\FeedItem;
use App\Models\RSS;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class PurgeFeedSource implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public RSS $source,
        public int $days,
        public int $keep
    ) {}

    public function handle(): void
    {
        $cutoff = now()->subDays($this->days);

        $protectedIds = FeedItem::where('rss_source_id', $this->source->id)
            ->orderBy('published_at', 'DESC')
            ->limit($this->keep)
            ->pluck('id');

        $query = FeedItem::where('rss_source_id', $this->source->id)
            ->where('published_at', '<', $cutoff)
            ->when($protectedIds->isNotEmpty(), fn($q) => $q->whereNotIn('id', $protectedIds));

        $count = $query->count();

        if ($count === 0) {
            return;
        }

        $query->delete();

        Log::info("Feed purge: deleted {$count} items from source [{$this->source->feed_name}] (id: {$this->source->id})");
    }
}
