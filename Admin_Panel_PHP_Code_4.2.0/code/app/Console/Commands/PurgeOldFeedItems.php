<?php

namespace App\Console\Commands;

use App\Jobs\PurgeFeedSource;
use App\Models\FeedItem;
use App\Models\RSS;
use Illuminate\Console\Command;

class PurgeOldFeedItems extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'feeds:purge
                                {--days=30 : Delete items older than this many days}
                                {--keep=10 : Minimum items to keep per source regardless of age}
                                {--dry-run : Show what would be deleted without actually deleting}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Delete old feed items while keeping a minimum per source';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $days   = (int) $this->option('days');
        $keep   = (int) $this->option('keep');
        $dryRun = $this->option('dry-run');
        $cutoff = now()->subDays($days);

        $this->info("Purging feed items older than {$days} days (keeping min {$keep} per source)...");
        $this->info("Cutoff date: {$cutoff} " . date('d-m-Y H:i:s'));

        if ($dryRun) {
            $this->warn('DRY RUN — nothing will be deleted.');

            $totalWouldDelete = 0;
            RSS::where('status', 1)->each(function (RSS $source) use ($cutoff, $keep, &$totalWouldDelete) {
                $protectedIds = FeedItem::where('rss_source_id', $source->id)
                    ->orderBy('published_at', 'DESC')
                    ->limit($keep)
                    ->pluck('id');

                $count = FeedItem::where('rss_source_id', $source->id)
                    ->where('published_at', '<', $cutoff)
                    ->when($protectedIds->isNotEmpty(), fn($q) => $q->whereNotIn('id', $protectedIds))
                    ->count();

                if ($count > 0) {
                    $this->line("  [DRY] Source [{$source->feed_name}] → would delete {$count} items");
                    $totalWouldDelete += $count;
                }
            });

            $this->info("DRY RUN complete — would delete {$totalWouldDelete} items total.");
            return Command::SUCCESS;
        }

        $count = 0;
        // no status wise purge operation performed where('status', 1)->
        RSS::each(function (RSS $source) use ($days, $keep, &$count) {
            PurgeFeedSource::dispatch($source, $days, $keep);
            $count++;
        });

        $this->info("Dispatched {$count} purge jobs. " . date('d-m-Y H:i:s'));

        return Command::SUCCESS;
    }
}
