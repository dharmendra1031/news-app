<?php

return [

    'base_url' => 'https://finnhub.io/api/v1',

    'forex_pairs' => [
        'USD' => 'USD',
        'EUR/USD' => 'OANDA:EUR_USD',
        'GBP/USD' => 'OANDA:GBP_USD',
        'USD/JPY' => 'OANDA:USD_JPY',
        'USD/CHF' => 'OANDA:USD_CHF',
        'AUD/USD' => 'OANDA:AUD_USD',
        'USD/CAD' => 'OANDA:USD_CAD',
        'NZD/USD' => 'OANDA:NZD_USD',
        'USD/INR' => 'OANDA:USD_INR',
    ],

    'commodities' => [
        'Gold' => 'OANDA:XAU_USD',
        'Silver' => 'OANDA:XAG_USD',
        'Crude Oil (WTI)' => 'OANDA:WTICO_USD',
        'Brent Crude Oil' => 'OANDA:BCO_USD',
        'Natural Gas' => 'OANDA:NATGAS_USD',
    ],

];
