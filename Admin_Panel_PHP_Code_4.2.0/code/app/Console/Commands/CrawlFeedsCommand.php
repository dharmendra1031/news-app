<?php

namespace App\Console\Commands;

use App\Jobs\ProcessFeedSource;
use App\Models\RSS;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class CrawlFeedsCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    // protected $signature = 'app:crawl-feeds-command';
    protected $signature = 'feeds:crawl {--source_id= : Crawl a specific source by ID}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Crawl all active RSS feed sources and store new items';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        // Log::info('Crawling feeds command started', ['command' => $this->signature]);

        if ($id = $this->option('source_id')) {
            $source = RSS::findOrFail($id);
            ProcessFeedSource::dispatch($source);
            $this->info("Dispatched crawl job for source [{$source->feed_name}].");
        } else {
            $this->info('Dispatching crawl jobs for all active feeds... ' . date('d-m-Y H:i:s'));
            $count = 0;
            RSS::where('status', true)->each(function (RSS $source) use (&$count) {
                ProcessFeedSource::dispatch($source);
                $count++;
            });
            $this->info("Dispatched {$count} crawl jobs. " . date('d-m-Y H:i:s'));
        }

        return Command::SUCCESS;
    }
}
