<?php

namespace App\Services;

use App\Models\Alerts;
use Carbon\Carbon;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\GuzzleException;
use GuzzleHttp\Exception\RequestException;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * Twelve Data market data provider.
 *
 * Replaces MassiveService (removed) - Massive's key had zero access to any
 * live quote endpoint (stock, forex, or futures all 403'd). Twelve Data's
 * single /time_series endpoint (with previous_close=true) quotes stocks,
 * forex, commodities, and crypto alike - no per-asset-class endpoint
 * switching needed, just a different symbol format:
 *   - stock:     AAPL
 *   - forex:     EUR/USD
 *   - commodity: XAU/USD
 *   - crypto:    BTC/USD
 *
 * Reuses the `twelvedata_api_key` settings slot (migrated for the short-lived
 * Massive integration) to hold the Twelve Data key, per instruction not to
 * add another settings migration for this swap.
 */
class TwelveDataService
{
    protected Client $client;
    protected string $baseUrl;

    protected const STOCK_TYPES = ['Common Stock', 'ETF', 'ADR', 'REIT', 'Depositary Receipt'];

    /**
     * Types with no live wiring yet - selectable in the UI but creation is blocked.
     */
    public const PENDING_TYPES = [];

    public function __construct()
    {
        $this->baseUrl = config('twelvedata.base_url');
        $this->client = new Client(['base_uri' => $this->baseUrl . '/']);
    }

    protected function apiKey(): string
    {
        $key = getSettingMode('twelvedata_api_key');
        // dd($key);

        if (empty($key)) {
            throw new RuntimeException('Twelve Data API key is not configured. Set it in General Settings.');
        }

        return $key;
    }

    protected function get(string $path, array $query = []): array
    {
        try {
            $response = $this->client->get($path, [
                'query' => array_merge($query, ['apikey' => $this->apiKey()]),
            ]);
        } catch (GuzzleException $e) {
            $message = $e->getMessage();

            if ($e instanceof RequestException && $e->hasResponse()) {
                $body = json_decode($e->getResponse()->getBody()->getContents(), true);
                $message = $body['message'] ?? $message;
            }

            Log::error('TwelveData request failed', [
                'path'    => $path,
                'query'   => $query,
                'message' => $message,
            ]);
            throw new RuntimeException($message, 0, $e);
        }

        $data = json_decode($response->getBody()->getContents(), true) ?? [];

        if (($data['status'] ?? null) === 'error') {
            Log::error('TwelveData request failed', [
                'path'    => $path,
                'query'   => $query,
                'message' => $data['message'] ?? 'unknown error',
            ]);
            throw new RuntimeException($data['message'] ?? 'unknown error');
        }

        return $data;
    }

    /**
     * Stock symbol search, filtered to equity/ETF-like types.
     */
    public function search(string $query): array
    {
        $data = $this->get('symbol_search', [
            'symbol'     => $query,
            'outputsize' => 10,
        ]);

        $formatted = [];
        foreach ($data['data'] ?? [] as $result) {
            if (!in_array($result['instrument_type'] ?? null, self::STOCK_TYPES, true)) {
                continue;
            }

            $formatted[] = [
                'symbol'   => $result['symbol'] ?? '',
                'name'     => $result['instrument_name'] ?? '',
                'exchange' => $result['exchange'] ?? '',
                'type'     => $result['instrument_type'] ?? '',
            ];
        }

        return $formatted;
    }

    /**
     * Curated forex pairs: label => Twelve Data symbol (e.g. EUR/USD).
     */
    public function forexOptions(): array
    {
        return config('twelvedata.forex_pairs', []);
    }

    /**
     * Curated commodities: label => Twelve Data symbol (e.g. XAU/USD).
     */
    public function commodityOptions(): array
    {
        return config('twelvedata.commodities', []);
    }

    /**
     * Top cryptocurrencies: label => Twelve Data symbol (e.g. BTC/USD).
     */
    public function cryptoOptions(): array
    {
        return config('twelvedata.cryptos', []);
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
            ['value' => 'Crypto', 'label' => __('crypto'), 'pending' => false],
            ['value' => 'IPO', 'label' => __('ipo'), 'pending' => false],
        ];
    }

    /**
     * Fetch a quote and normalize into the fields Alerts::create()/update() expect.
     * One endpoint covers stock, forex, and commodity symbols alike.
     */
    public function getQuote(string $symbol): array
    {
        $data = $this->get('time_series', [
            'symbol'         => $symbol,
            'interval'       => '1min',
            'outputsize'     => 1,
            'previous_close' => 'true',
        ]);

        $value = $data['values'][0] ?? [];

        $currentPrice  = isset($value['close']) ? (float) $value['close'] : null;
        $previousClose = isset($value['previous_close']) ? (float) $value['previous_close'] : null;

        $percentChange = ($currentPrice !== null && !empty($previousClose))
            ? round((($currentPrice - $previousClose) / $previousClose) * 100, 4)
            : null;

        $direction = null;
        if ($percentChange !== null) {
            $direction = $percentChange > 0 ? 'up' : ($percentChange < 0 ? 'down' : 'unchanged');
        }

        return [
            'current_price'   => $currentPrice,
            'currency'        => $data['meta']['currency'] ?? $this->currencyForSymbol($symbol),
            'percent_change'  => $percentChange,
            'direction'       => $direction,
            'last_updated_at' => !empty($value['datetime'])
                ? Carbon::parse($value['datetime'])->format('Y-m-d H:i:s')
                : now(),
        ];
    }

    /**
     * Forex/commodity symbols encode the quote currency after the slash
     * (e.g. EUR/USD -> USD, XAU/USD -> USD). Plain stock symbols default to USD.
     */
    protected function currencyForSymbol(string $symbol): string
    {
        if (str_contains($symbol, '/')) {
            return substr($symbol, strpos($symbol, '/') + 1);
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
