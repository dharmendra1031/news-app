<?php

namespace App\Jobs;

use App\Models\RSS;
use App\Services\FeedCrawlerService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ProcessFeedSource implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Create a new job instance.
     */
    public function __construct(public RSS $source)
    {
        //
    }

    /**
     * Execute the job.
     */
    public function handle(FeedCrawlerService $crawler): void
    {
        $crawler->crawlSource($this->source);
    }
}
