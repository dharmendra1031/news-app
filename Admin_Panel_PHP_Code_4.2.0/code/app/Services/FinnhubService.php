<?php

namespace App\Services;

use App\Models\Alerts;
use Carbon\Carbon;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\GuzzleException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class FinnhubService
{
    protected Client $client;
    protected string $baseUrl;

    protected const STOCK_TYPES = ['Common Stock', 'ETF', 'ADR', 'GDR', 'REIT'];

    /**
     * Types with no live Finnhub wiring yet - selectable in the UI but creation is blocked.
     */
    public const PENDING_TYPES = ['Crypto'];

    public function __construct()
    {
        $this->baseUrl = config('finnhub.base_url');
        $this->client = new Client(['base_uri' => $this->baseUrl . '/']);
    }

    protected function apiKey(): string
    {
        $key = getSettingMode('finnhub_api_key');

        if (empty($key)) {
            throw new RuntimeException('Finnhub API key is not configured. Set it in General Settings.');
        }

        return $key;
    }

    /**
     * Real-time quote: symbol, current_price, change, percent_change, previous_close, timestamp.
     */
    public function quote(string $symbol): array
    {
        try {
            $response = $this->client->get('quote', [
                'query' => [
                    'symbol' => $symbol,
                    'token'  => $this->apiKey(),
                ],
            ]);

        } catch (GuzzleException $e) {
            Log::error('Finnhub quote request failed', [
                'symbol'  => $symbol,
                'message' => $e->getMessage(),
            ]);
            throw new RuntimeException('Finnhub quote request failed: ' . $e->getMessage(), 0, $e);
        }

        $data = json_decode($response->getBody()->getContents(), true);
        // dd($data);

        return [
            'current_price'  => $data['c'] ?? null,
            'change'         => $data['d'] ?? null,
            'percent_change' => $data['dp'] ?? null,
            'previous_close' => $data['pc'] ?? null,
            'timestamp'      => $data['t'] ?? null,
        ];
    }

    /**
     * Stock symbol search via Finnhub, filtered to equity/ETF-like types.
     */
    public function search(string $query): array
    {
        try {
            $response = $this->client->get('search', [
                'query' => [
                    'q'     => $query,
                    'token' => $this->apiKey(),
                ],
            ]);
        } catch (GuzzleException $e) {
            Log::error('Finnhub search request failed', [
                'query'   => $query,
                'message' => $e->getMessage(),
            ]);
            throw new RuntimeException('Finnhub search request failed: ' . $e->getMessage(), 0, $e);
        }

        $data = json_decode($response->getBody()->getContents(), true);

        $formatted = [];
        foreach ($data['result'] ?? [] as $result) {
            if (!in_array($result['type'] ?? null, self::STOCK_TYPES, true)) {
                continue;
            }

            $formatted[] = [
                'symbol'   => $result['symbol'] ?? '',
                'name'     => $result['description'] ?? '',
                'exchange' => $result['displaySymbol'] ?? '',
                'type'     => $result['type'] ?? '',
            ];
        }

        return $formatted;
    }

    /**
     * Upcoming/recent IPOs (name, symbol, exchange, date, price range),
     * cached for 10 minutes. Withdrawn IPOs and entries with no symbol yet
     * assigned are dropped - both are unusable as an alert target.
     */
    public function ipoCalendar(?string $from = null, ?string $to = null): array
    {
        $from = $from ?? now()->toDateString();
        $to = $to ?? now()->addDays(30)->toDateString();

        return Cache::remember("finnhub_ipo_calendar_{$from}_{$to}", 600, function () use ($from, $to) {
            try {
                $response = $this->client->get('calendar/ipo', [
                    'query' => [
                        'from'  => $from,
                        'to'    => $to,
                        'token' => $this->apiKey(),
                    ],
                ]);
            } catch (GuzzleException $e) {
                Log::error('Finnhub IPO calendar request failed', [
                    'from'    => $from,
                    'to'      => $to,
                    'message' => $e->getMessage(),
                ]);
                throw new RuntimeException('Finnhub IPO calendar request failed: ' . $e->getMessage(), 0, $e);
            }

            $data = json_decode($response->getBody()->getContents(), true);

            $formatted = [];
            foreach ($data['ipoCalendar'] ?? [] as $ipo) {
                if (empty($ipo['symbol']) || ($ipo['status'] ?? null) === 'withdrawn') {
                    continue;
                }

                $formatted[] = [
                    'symbol'   => $ipo['symbol'],
                    'name'     => $ipo['name'] ?? '',
                    'exchange' => $ipo['exchange'] ?? '',
                    'date'     => $ipo['date'] ?? null,
                    'price'    => $ipo['price'] ?? null,
                    'status'   => $ipo['status'] ?? null,
                ];
            }

            return $formatted;
        });
    }

    /**
     * Curated forex pairs: label => Finnhub symbol.
     */
    public function forexOptions(): array
    {
        return config('finnhub.forex_pairs', []);
    }

    /**
     * Curated commodities: label => Finnhub symbol.
     */
    public function commodityOptions(): array
    {
        return config('finnhub.commodities', []);
    }

    /**
     * Alert-type dropdown options, flagging which ones are pending (not yet wired to live data).
     */
    public function alertTypeOptions(): array
    {
        return [
            ['value' => 'stock', 'label' => __('stock'), 'pending' => false],
            ['value' => 'commodity', 'label' => __('commodity'), 'pending' => false],
            ['value' => 'forex', 'label' => __('forex'), 'pending' => false],
            ['value' => 'IPO', 'label' => __('ipo'), 'pending' => false],
        ];
    }

    /**
     * Fetch a quote and normalize into the fields Alerts::create()/update() expect.
     */
    public function getQuote(string $symbol): array
    {
        $quote = $this->quote($symbol);

        $percentChange = $quote['percent_change'];
        $direction = null;
        if ($percentChange !== null) {
            $direction = $percentChange > 0 ? 'up' : ($percentChange < 0 ? 'down' : 'unchanged');
        }

        return [
            'current_price'   => $quote['current_price'],
            'currency'        => $this->currencyForSymbol($symbol),
            'percent_change'  => $percentChange,
            'direction'       => $direction,
            'last_updated_at' => $quote['timestamp']
                ? Carbon::createFromTimestamp($quote['timestamp'])->format('Y-m-d H:i:s')
                : now(),
        ];
    }

    /**
     * OANDA forex/commodity symbols encode the quote currency after the underscore
     * (e.g. OANDA:EUR_USD -> USD). Plain stock symbols default to USD.
     */
    protected function currencyForSymbol(string $symbol): string
    {
        if (str_contains($symbol, '_')) {
            return substr(strrchr($symbol, '_'), 1);
        }

        return 'USD';
    }

    /**
     * Only one alert may exist per type at a time.
     */
    public function hasAlertOfType(string $type): bool
    {
        return Alerts::where('alert_type', $type)->exists();
    }
}
