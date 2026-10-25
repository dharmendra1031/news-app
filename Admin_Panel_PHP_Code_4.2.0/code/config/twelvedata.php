<?php

return [

    'base_url' => 'https://api.twelvedata.com',

    /**
     * Forex pairs: label => Twelve Data symbol (slash-delimited pair).
     */
    'forex_pairs' => [
        'EUR/USD' => 'EUR/USD',
        'GBP/USD' => 'GBP/USD',
        'USD/JPY' => 'USD/JPY',
        'USD/CHF' => 'USD/CHF',
        'AUD/USD' => 'AUD/USD',
        'USD/CAD' => 'USD/CAD',
        'NZD/USD' => 'NZD/USD',
        'USD/INR' => 'USD/INR',
    ],

    /**
     * Commodities: label => Twelve Data symbol. Natural Gas is intentionally
     * left out - Twelve Data's /commodities catalog doesn't list it at all.
     */
    'commodities' => [
        'Gold' => 'XAU/USD',
        'Silver' => 'XAG/USD',
        'Crude Oil (WTI)' => 'WTI/USD',
        'Brent Crude Oil' => 'XBR/USD',
    ],

    /**
     * Top cryptocurrencies by market cap: label => Twelve Data symbol.
     */
    'cryptos' => [
        'Bitcoin' => 'BTC/USD',
        'Ethereum' => 'ETH/USD',
        'Tether' => 'USDT/USD',
        'BNB' => 'BNB/USD',
        'Solana' => 'SOL/USD',
        'XRP' => 'XRP/USD',
        'USD Coin' => 'USDC/USD',
        'Dogecoin' => 'DOGE/USD',
        'Cardano' => 'ADA/USD',
        'TRON' => 'TRX/USD',
    ],

];
