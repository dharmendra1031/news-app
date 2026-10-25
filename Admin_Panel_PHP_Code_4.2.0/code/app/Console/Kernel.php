<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;
use Illuminate\Support\Facades\Log;

class Kernel extends ConsoleKernel
{
    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        Log::info('Schedule run started');
        $schedule->command('feeds:crawl')
            ->hourly()
            ->withoutOverlapping()
            ->runInBackground()
            ->appendOutputTo(storage_path('logs/feed-crawler.log'));


        // Purge old items once daily at 2am (low traffic window)
        $schedule->command('feeds:purge --days=10 --keep=10')
            ->dailyAt('02:00')
            ->withoutOverlapping()
            ->appendOutputTo(storage_path('logs/feed-purge.log'));

        // Refresh market alert prices once daily and notify on direction flips
        $schedule->command('alerts:refresh')
            ->dailyAt('06:00')
            ->withoutOverlapping()
            ->appendOutputTo(storage_path('logs/alerts-refresh.log'));

        // Process queued jobs every minute (crawl + purge jobs dispatched above)
        $schedule->command('queue:work --stop-when-empty --queue=default --tries=3')
            ->everyMinute()
            ->withoutOverlapping()
            ->runInBackground()
            ->appendOutputTo(storage_path('logs/queue-worker.log'));
    }

    /**
     * Register the commands for the application.
     */
    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }

    protected $commands = [
        
    ];
}
