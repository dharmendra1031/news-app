<?php

namespace App\Console\Commands;

use App\Models\Alerts;
use App\Models\Settings;
use App\Services\TwelveDataService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use Throwable;

class RefreshAlertsCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'alerts:refresh';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Refresh live prices for active market alerts and notify users when an alert\'s direction flips';

    protected TwelveDataService $twelveDataService;

    public function __construct(TwelveDataService $twelveDataService)
    {
        parent::__construct();
        $this->twelveDataService = $twelveDataService;
    }

    /**
     * Execute the console command.
     * IPO alerts have no live quote and are skipped - only stock/commodity/forex/Crypto are refreshed.
     */
    public function handle(): int
    {
        $alerts = Alerts::where('status', true)
            ->where('alert_type', '!=', 'IPO')
            ->get();

        $this->info('Refreshing ' . $alerts->count() . ' active alert(s)... ' . date('d-m-Y H:i:s'));

        $flipped = [];

        foreach ($alerts as $alert) {
            $previousDirection = $alert->direction;

            try {
                $quote = $this->twelveDataService->getQuote($alert->symbol);
            } catch (Throwable $e) {
                Log::warning('alerts:refresh - quote fetch failed', [
                    'alert_id' => $alert->id,
                    'symbol'   => $alert->symbol,
                    'message'  => $e->getMessage(),
                ]);
                $this->warn("  [{$alert->symbol}] quote fetch failed: {$e->getMessage()}");
                continue;
            }

            $alert->update([
                'current_price'   => $quote['current_price'],
                'currency'        => $quote['currency'],
                'percent_change'  => $quote['percent_change'],
                'direction'       => $quote['direction'],
                'last_updated_at' => $quote['last_updated_at'],
            ]);

            if ($previousDirection !== null
                && $quote['direction'] !== null
                && $quote['direction'] !== $previousDirection) {
                $flipped[] = $alert;
            }
        }

        $this->info(count($flipped) . ' alert(s) flipped direction.');

        foreach ($flipped as $alert) {
            $this->notifyDirectionChange($alert);
        }

        return Command::SUCCESS;
    }

    /**
     * Broadcast a direction-flip notification to all users who haven't opted out
     * of the "alerts" notification type. Sent once per active language, since
     * send_notification() picks device tokens by language_id when none are given.
     */
    protected function notifyDirectionChange(Alerts $alert): void
    {
        $arrow = match ($alert->direction) {
            'up'   => '▲',
            'down' => '▼',
            default => '',
        };

        $sign = $alert->percent_change !== null && $alert->percent_change >= 0 ? '+' : '';

        $fcmMsg = [
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            'title'        => trim("{$alert->name} ({$alert->symbol}) is now {$alert->direction} {$arrow}"),
            'body'         => "Price: {$alert->current_price} {$alert->currency} ({$sign}{$alert->percent_change}%)",
            'alert_id'     => $alert->id,
            'alert_type'   => $alert->alert_type,
            'symbol'       => $alert->symbol,
        ];

        // $languageIds = Language::where('status', 1)->pluck('id');
        $defaultLanguage = Settings::where('type', 'default_language')->value('message') ?? 1;

        // foreach ($languageIds as $languageId) {
        send_notification($fcmMsg, $defaultLanguage, 0, [], config('notification_types.ALERTS'));
        // }
    }
}
